const cors = require("cors");
const express = require("express");
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const functions = require("firebase-functions");
const fs = require("fs");
const path = require("path");

// Load Firebase runtime config with local environment fallback.
let config = {stripe: {}, cloudinary: {}};
try {
  const runtimeConfig = functions.config();
  if (runtimeConfig && Object.keys(runtimeConfig).length > 0) {
    config = runtimeConfig;
  }
} catch (error) {
  logger.warn(
      "functions.config() unavailable; attempting local config fallback.",
      {error: error.message},
  );
}

try {
  const localPath = path.join(__dirname, "..", ".runtimeconfig.json");
  if (fs.existsSync(localPath)) {
    const localConfig = JSON.parse(fs.readFileSync(localPath, "utf8"));
    config = {
      ...config,
      ...localConfig,
      stripe: {
        ...(config.stripe || {}),
        ...(localConfig.stripe || {}),
      },
      cloudinary: {
        ...(config.cloudinary || {}),
        ...(localConfig.cloudinary || {}),
      },
    };
  }
} catch (error) {
  logger.info(
      "Local .runtimeconfig.json could not be loaded.",
      {error: error.message},
  );
}

const getConfig = (group, key, envKey) => {
  if (Object.prototype.hasOwnProperty.call(process.env, envKey)) {
    return process.env[envKey];
  }
  if (
    config[group] &&
    Object.prototype.hasOwnProperty.call(config[group], key)
  ) {
    return config[group][key];
  }
  return undefined;
};

const STRIPE_SECRET_KEY = getConfig(
    "stripe",
    "secret_key",
    "STRIPE_SECRET_KEY",
);
const STRIPE_PUBLISHABLE_KEY = getConfig(
    "stripe",
    "publishable_key",
    "STRIPE_PUBLISHABLE_KEY",
);
const STRIPE_WEBHOOK_SECRET = getConfig(
    "stripe",
    "webhook_secret",
    "STRIPE_WEBHOOK_SECRET",
);

const CLOUDINARY_CLOUD_NAME = getConfig(
    "cloudinary",
    "cloud_name",
    "CLOUDINARY_CLOUD_NAME",
);
const CLOUDINARY_API_KEY = getConfig(
    "cloudinary",
    "api_key",
    "CLOUDINARY_API_KEY",
);
const CLOUDINARY_API_SECRET = getConfig(
    "cloudinary",
    "api_secret",
    "CLOUDINARY_API_SECRET",
);

if (!CLOUDINARY_CLOUD_NAME || !CLOUDINARY_API_KEY || !CLOUDINARY_API_SECRET) {
  logger.warn(
      "Cloudinary config incomplete; uploads will fail until configured.",
  );
}
const stripe = STRIPE_SECRET_KEY ? require("stripe")(STRIPE_SECRET_KEY) : null;

const cloudinary = require("cloudinary").v2;
if (CLOUDINARY_CLOUD_NAME && CLOUDINARY_API_KEY && CLOUDINARY_API_SECRET) {
  cloudinary.config({
    cloud_name: CLOUDINARY_CLOUD_NAME,
    api_key: CLOUDINARY_API_KEY,
    api_secret: CLOUDINARY_API_SECRET,
  });
}

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
  if (!STRIPE_PUBLISHABLE_KEY) {
    return res.status(503).json({error: "Stripe publishable key missing"});
  }
  res.json({publishableKey: STRIPE_PUBLISHABLE_KEY});
});

app.post("/create-stripe-payment-intent", async (req, res) => {
  try {
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
    if (
      !CLOUDINARY_CLOUD_NAME ||
      !CLOUDINARY_API_KEY ||
      !CLOUDINARY_API_SECRET
    ) {
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
      if (!stripe || !STRIPE_WEBHOOK_SECRET) {
        logger.error("Stripe webhook called without required configuration");
        return res.status(503).send("Webhook not configured");
      }

      try {
        const signature = req.headers["stripe-signature"];
        const event = stripe.webhooks.constructEvent(
            req.body,
            signature,
            STRIPE_WEBHOOK_SECRET,
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

exports.api = onRequest({region: "asia-southeast1"}, app);

