const cors = require("cors");
const express = require("express");
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const fs = require("fs");
const path = require("path");

const stripeFactory = require("stripe");
const cloudinaryLib = require("cloudinary").v2;

const readLocalRuntimeConfig = () => {
  try {
    const localPath = path.join(__dirname, "..", ".runtimeconfig.json");
    if (fs.existsSync(localPath)) {
      return JSON.parse(fs.readFileSync(localPath, "utf8"));
    }
  } catch (error) {
    logger.info(
        "Local .runtimeconfig.json could not be loaded.",
        {error: error.message},
    );
  }
  return {stripe: {}, cloudinary: {}};
};

const localRuntimeConfig = readLocalRuntimeConfig();
const localStripeConfig = localRuntimeConfig.stripe || {};
const localCloudinaryConfig = localRuntimeConfig.cloudinary || {};

let cachedConfig;
let loggedConfigSummary = false;
let warnedCloudinary = false;

const loadRuntimeConfig = () => {
  if (cachedConfig) {
    return cachedConfig;
  }

  const stripeSecretKey =
    process.env.STRIPE_SECRET_KEY || localStripeConfig.secret_key;
  const stripePublishableKey =
    process.env.STRIPE_PUBLISHABLE_KEY || localStripeConfig.publishable_key;
  const stripeWebhookSecret =
    process.env.STRIPE_WEBHOOK_SECRET || localStripeConfig.webhook_secret;

  const cloudinaryCloudName =
    process.env.CLOUDINARY_CLOUD_NAME || localCloudinaryConfig.cloud_name;
  const cloudinaryApiKey =
    process.env.CLOUDINARY_API_KEY || localCloudinaryConfig.api_key;
  const cloudinaryApiSecret =
    process.env.CLOUDINARY_API_SECRET || localCloudinaryConfig.api_secret;

  const stripe = stripeSecretKey ? stripeFactory(stripeSecretKey) : null;
  const cloudinary = cloudinaryLib;

  if (cloudinaryCloudName && cloudinaryApiKey && cloudinaryApiSecret) {
    cloudinary.config({
      cloud_name: cloudinaryCloudName,
      api_key: cloudinaryApiKey,
      api_secret: cloudinaryApiSecret,
    });
  } else if (!warnedCloudinary) {
    warnedCloudinary = true;
    logger.warn(
        "Cloudinary config incomplete; uploads will fail until configured.",
    );
  }

  if (!loggedConfigSummary) {
    loggedConfigSummary = true;
    logger.info("Runtime config summary", {
      hasStripeSecret: Boolean(stripeSecretKey),
      hasStripePublishable: Boolean(stripePublishableKey),
      hasStripeWebhook: Boolean(stripeWebhookSecret),
      hasCloudinaryName: Boolean(cloudinaryCloudName),
      hasCloudinaryKey: Boolean(cloudinaryApiKey),
      hasCloudinarySecret: Boolean(cloudinaryApiSecret),
    });
  }

  cachedConfig = {
    stripe,
    stripeSecretKey,
    stripePublishableKey,
    stripeWebhookSecret,
    cloudinary,
    cloudinaryCloudName,
    cloudinaryApiKey,
    cloudinaryApiSecret,
  };

  return cachedConfig;
};

const app = express();
app.use(cors({origin: true}));

const jsonParser = express.json({limit: "12mb"});
app.use((req, res, next) => {
  if (req.originalUrl === "/stripe-webhook") {
    return next();
  }
  return jsonParser(req, res, next);
});

app.get("/stripe-publishable-key", (_req, res) => {
  const {stripePublishableKey} = loadRuntimeConfig();
  if (!stripePublishableKey) {
    return res.status(503).json({error: "Stripe publishable key missing"});
  }
  res.json({publishableKey: stripePublishableKey});
});

app.post("/create-stripe-payment-intent", async (req, res) => {
  try {
    const {stripe} = loadRuntimeConfig();
    if (!stripe) {
      logger.error("Stripe secret key missing when creating PaymentIntent");
      return res.status(503).json({error: "Stripe is not configured"});
    }

    const {amount, currency} = req.body;
    if (!amount || !currency) {
      return res.status(400).json({error: "amount and currency are required"});
    }

    const amountSatang = Math.round(Number(amount) * 100);
    if (!Number.isFinite(amountSatang) || amountSatang <= 0) {
      return res.status(400).json({error: "Invalid amount"});
    }

    logger.info("Creating Stripe PaymentIntent", {amountSatang, currency});

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountSatang,
      currency,
      automatic_payment_methods: {enabled: true},
    });

    return res.json({clientSecret: paymentIntent.client_secret});
  } catch (error) {
    logger.error("Stripe PaymentIntent creation failed", {
      message: error.message,
      stack: error.stack,
    });
    return res.status(400).json({error: error.message});
  }
});

app.post("/upload-image", async (req, res) => {
  try {
    const {
      cloudinary,
      cloudinaryCloudName,
      cloudinaryApiKey,
      cloudinaryApiSecret,
    } = loadRuntimeConfig();
    if (!cloudinaryCloudName || !cloudinaryApiKey || !cloudinaryApiSecret) {
      return res.status(503).json({error: "Cloudinary is not configured"});
    }

    const {image, folder} = req.body || {};
    if (!image) {
      return res.status(400).json({error: "No image provided"});
    }

    const uploadOptions = {};
    if (folder) {
      uploadOptions.folder = folder;
    }

    const result = await cloudinary.uploader.upload(image, uploadOptions);
    return res.json({
      url: result.secure_url,
      public_id: result.public_id,
      raw: result,
    });
  } catch (error) {
    logger.error("Cloudinary upload failed", {
      message: error.message,
      stack: error.stack,
    });
    return res.status(500).json({error: error.message || "Upload failed"});
  }
});

app.post(
    "/stripe-webhook",
    express.raw({type: "application/json"}),
    (req, res) => {
      const {stripe, stripeWebhookSecret} = loadRuntimeConfig();
      if (!stripe || !stripeWebhookSecret) {
        logger.error("Stripe webhook called without required configuration");
        return res.status(503).send("Webhook not configured");
      }

      try {
        const signature = req.headers["stripe-signature"];
        const event = stripe.webhooks.constructEvent(
            req.body,
            signature,
            stripeWebhookSecret,
        );
        logger.info("Stripe webhook received", {type: event.type});
        return res.status(200).send("ok");
      } catch (error) {
        logger.error("Stripe webhook verification failed", {
          message: error.message,
          stack: error.stack,
        });
        return res.status(400).send(`Webhook Error: ${error.message}`);
      }
    },
);

exports.api = onRequest(
    {
      region: "asia-southeast1",
      invoker: "public",
      secrets: [
        "STRIPE_SECRET_KEY",
        "STRIPE_PUBLISHABLE_KEY",
        "STRIPE_WEBHOOK_SECRET",
        "CLOUDINARY_CLOUD_NAME",
        "CLOUDINARY_API_KEY",
        "CLOUDINARY_API_SECRET",
      ],
    },
    app,
);

