const axios = require('axios');
const express = require('express');

const Omise = require('omise')({
  publicKey: 'pkey_test_65d9tv46ybfuu4dvand',
  secretKey: 'skey_test_65d9tv4kdphsp77mgyz'
});

const app = express();
app.use(express.json());

// Stripe setup
const Stripe = require('stripe');
const STRIPE_SECRET_KEY = 'STRIPE_SECRET_KEY_REMOVED';
const STRIPE_PUBLISHABLE_KEY = 'pk_test_51SI8SqH0YKCnZGn55sDwlKMz1XWL9zxKUQA30Pqg5gz218neg5hm0JQWCN8xPQ7AxXjNVPp81TQCtf0JvFaoIaEQ00wWp8DEP2';
const stripe = Stripe(STRIPE_SECRET_KEY);

// Expose publishable key for the client to use (test only; do not expose secret key)
app.get('/stripe-publishable-key', (req, res) => {
  res.json({ publishableKey: STRIPE_PUBLISHABLE_KEY });
});

// สร้าง PaymentIntent สำหรับบัตรเครดิต (Stripe)
app.post('/create-stripe-payment-intent', async (req, res) => {
  try {
    const { amount, currency } = req.body;
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
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
        Authorization: 'Basic ' + Buffer.from('skey_test_65d9tv4kdphsp77mgyz:').toString('base64')
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

app.listen(3000, '0.0.0.0', () => console.log('Opn Sandbox backend running on port 3000'));