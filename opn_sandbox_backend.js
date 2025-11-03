const axios = require('axios');
const express = require('express');
require('dotenv').config();

// const Omise = require('omise')({
//   publicKey: process.env.OMISE_PUBLIC_KEY,
//   secretKey: process.env.OMISE_SECRET_KEY
// });

const app = express();
app.use(express.json({ limit: '12mb' }));

// Stripe setup
const Stripe = require('stripe');
const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;
const STRIPE_PUBLISHABLE_KEY = process.env.STRIPE_PUBLISHABLE_KEY;
const stripe = Stripe(STRIPE_SECRET_KEY);

if (!STRIPE_SECRET_KEY || !STRIPE_SECRET_KEY.startsWith('sk_')) {
  console.warn('[Stripe] STRIPE_SECRET_KEY missing or not a secret key (should start with sk_)');
}
if (!STRIPE_PUBLISHABLE_KEY || !STRIPE_PUBLISHABLE_KEY.startsWith('pk_')) {
  console.warn('[Stripe] STRIPE_PUBLISHABLE_KEY missing or not a publishable key (should start with pk_)');
}
console.log('[Stripe] Using secret key prefix:', STRIPE_SECRET_KEY ? STRIPE_SECRET_KEY.slice(0, 7) : 'undefined');
console.log('[Stripe] Using publishable key prefix:', STRIPE_PUBLISHABLE_KEY ? STRIPE_PUBLISHABLE_KEY.slice(0, 7) : 'undefined');

// Cloudinary setup
const cloudinary = require('cloudinary').v2;
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'dcxltgxlw',
  api_key: process.env.CLOUDINARY_API_KEY || '977985198873474',
  api_secret: process.env.CLOUDINARY_API_SECRET || 'RKdZPo6DYm5Jz4W4QbMrKToWdPw',
});

// Expose publishable key for the client to use (test only; do not expose secret key)
app.get('/stripe-publishable-key', (req, res) => {
  res.json({ publishableKey: STRIPE_PUBLISHABLE_KEY });
});

// สร้าง PaymentIntent สำหรับบัตรเครดิต (Stripe)
app.post('/create-stripe-payment-intent', async (req, res) => {
  try {
  console.log('Received body:', req.body);
  const { amount, currency } = req.body;
  const amountSatang = Math.round(Number(amount) * 100);
  console.log('Amount for Stripe:', amountSatang);
  console.log('Received body:', req.body);
  console.log('Amount for Stripe:', amountSatang);
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountSatang,
      currency,
      automatic_payment_methods: { enabled: true },
    });
    res.json({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (e) {
    console.error('Stripe error:', e);
    res.status(400).json({ error: e.message });
  }
});

app.post('/create-promptpay', async (req, res) => {
  try {
    const { amount, orderId } = req.body;
    const charge = await Omise.charges.create({
      amount: Math.round(amount * 100), // หน่วยเป็นสตางค์
      currency: 'thb',
      source: { type: 'promptpay' },
      return_uri: 'https://your-app.com/payment-success?orderId=' + orderId
    });
    const qrUrl = charge.source.scannable_code.image.download_uri;
    // ดึงไฟล์ QR ด้วย Authorization
    const qrRes = await axios.get(qrUrl, {
      responseType: 'arraybuffer',
      headers: {
        Authorization: 'Basic ' + Buffer.from(process.env.OMISE_SECRET_KEY + ':').toString('base64')
      }
    });
    // Log ขนาดข้อมูลที่ได้จาก Omise
    console.log('qrUrl:', qrUrl);
    console.log('qrRes.data type:', typeof qrRes.data);
    console.log('qrRes.data length:', qrRes.data.length);
    const base64 = 'data:image/png;base64,' + Buffer.from(qrRes.data, 'binary').toString('base64');
    console.log('base64 length:', base64.length);
    // ตัด base64 string ให้ดูตัวอย่าง
    console.log('base64 preview:', base64.substring(0, 100));
    res.json({ qr: base64, chargeId: charge.id });
  } catch (e) {
    console.error('PromptPay error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Upload image to Cloudinary (accepts base64 data URI in JSON { image: 'data:image/png;base64,...', folder?: 'optional' })
app.post('/upload-image', async (req, res) => {
  try {
    const { image, folder } = req.body || {};
    if (!image) return res.status(400).json({ error: 'No image provided' });
    // Upload to Cloudinary; image can be a data URI or remote URL
    const uploadOptions = {};
    if (folder) uploadOptions.folder = folder;
    const result = await cloudinary.uploader.upload(image, uploadOptions);
    return res.json({ url: result.secure_url, public_id: result.public_id, raw: result });
  } catch (e) {
    console.error('Cloudinary upload error:', e);
    return res.status(500).json({ error: e.message || 'Upload failed' });
  }
});

app.listen(3000, '0.0.0.0', () => console.log('Opn Sandbox backend running on port 3000'));