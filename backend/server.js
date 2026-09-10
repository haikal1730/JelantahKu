import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import midtransClient from 'midtrans-client';
import { createClient } from '@supabase/supabase-js';

const app = express();
app.use(cors());
app.use(express.json({ limit: '1mb' }));

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } },
);

const isProduction = process.env.MIDTRANS_IS_PRODUCTION === 'true';
const snap = new midtransClient.Snap({
  isProduction,
  serverKey: process.env.MIDTRANS_SERVER_KEY,
});

function paymentStatus(notification) {
  const status = notification.transaction_status;
  if (status === 'settlement') return 'paid';
  if (status === 'capture') {
    return notification.fraud_status === 'deny' ? 'failed' : 'paid';
  }
  if (['deny', 'cancel', 'expire', 'failure'].includes(status)) return 'failed';
  return 'pending';
}

async function requireSupabaseUser(req, res, next) {
  try {
    const auth = req.headers.authorization || '';
    if (!auth.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Authorization Bearer diperlukan.' });
    }
    const token = auth.substring(7);
    const { data, error } = await supabaseAdmin.auth.getUser(token);
    if (error || !data.user) {
      return res.status(401).json({ message: 'Token Supabase tidak valid.' });
    }
    req.user = data.user;
    next();
  } catch (_) {
    return res.status(401).json({ message: 'Token Supabase tidak valid.' });
  }
}

app.get('/health', (_req, res) => res.json({
  ok: true,
  service: 'jelantahku-payment-api',
  backend: 'supabase',
  gateway: isProduction ? 'midtrans-production' : 'midtrans-sandbox',
}));

// Create one monthly Premium payment. The Supabase user ID is taken from the JWT,
// never from the request body, so a client cannot create a payment for another user.
app.post('/payments/subscription', requireSupabaseUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const amount = Number(req.body.amount ?? 25000);
    if (!Number.isInteger(amount) || amount !== 25000) {
      return res.status(400).json({ message: 'Nominal subscription tidak valid.' });
    }

    const orderId = `JELANTAH-${userId.slice(0, 8)}-${Date.now()}`;
    const name = String(
      req.user.user_metadata?.name ||
      req.user.user_metadata?.full_name ||
      'Pengguna',
    ).slice(0, 50);

    const parameter = {
      transaction_details: { order_id: orderId, gross_amount: amount },
      item_details: [{
        id: 'premium-monthly',
        price: amount,
        quantity: 1,
        name: 'JelantahKu Premium 1 Bulan',
      }],
      customer_details: {
        first_name: name,
        email: req.user.email || undefined,
      },
      expiry: { unit: 'minutes', duration: 30 },
    };

    const transaction = await snap.createTransaction(parameter);

    const { error } = await supabaseAdmin.from('payments').insert({
      order_id: orderId,
      user_id: userId,
      amount,
      status: 'pending',
      provider: 'midtrans',
      raw_response: transaction,
    });
    if (error) throw error;

    return res.json({
      orderId,
      status: 'pending',
      redirectUrl: transaction.redirect_url,
      token: transaction.token,
    });
  } catch (error) {
    console.error('create payment:', error);
    return res.status(502).json({ message: 'Gagal membuat transaksi gateway.' });
  }
});

// Payment status is read from our database. The app can poll this after the user
// returns from the Midtrans Sandbox page; webhook remains the source of truth.
app.get('/payments/subscription/:orderId', requireSupabaseUser, async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('payments')
      .select('order_id,user_id,amount,status,fraud_status,provider,created_at,updated_at,paid_at')
      .eq('order_id', req.params.orderId)
      .eq('user_id', req.user.id)
      .maybeSingle();
    if (error) throw error;
    if (!data) return res.status(404).json({ message: 'Pembayaran tidak ditemukan.' });
    return res.json(data);
  } catch (error) {
    console.error('payment status:', error);
    return res.status(500).json({ message: 'Gagal mengambil status pembayaran.' });
  }
});

// Midtrans sends the authoritative result here. Configure this URL in
// Midtrans Dashboard > Settings > Configuration > Payment Notification URL.
app.post('/payments/midtrans/webhook', async (req, res) => {
  try {
    const orderId = req.body?.order_id;

    if (!orderId) {
      return res.status(400).json({ message: 'order_id tidak ditemukan.' });
    }

    // Verify the transaction directly with Midtrans using the ORDER ID.
    // This avoids snap.transaction.notification(), which previously
    // returned a 404 while looking up the webhook transaction_id.
    const transaction = await snap.transaction.status(orderId);

    console.log('Midtrans verified:', {
      order_id: transaction.order_id,
      transaction_id: transaction.transaction_id,
      transaction_status: transaction.transaction_status,
      fraud_status: transaction.fraud_status,
      gross_amount: transaction.gross_amount,
    });

    const normalizedStatus = paymentStatus(transaction);

    const { data: payment, error: paymentError } = await supabaseAdmin
      .from('payments')
      .select('user_id,amount,status')
      .eq('order_id', orderId)
      .maybeSingle();
    if (paymentError) throw paymentError;
    if (!payment) return res.status(404).json({ message: 'Order ID tidak ditemukan.' });

    const paid = normalizedStatus === 'paid';

    const { error: updateError } = await supabaseAdmin
      .from('payments')
      .update({
        status: normalizedStatus,
        fraud_status: transaction.fraud_status || null,
        paid_at: paid ? new Date().toISOString() : null,
        raw_response: transaction,
      })
      .eq('order_id', orderId);
    if (updateError) throw updateError;

    if (paid && payment.status !== 'paid') {
      // Extend from the later of now/current expiry, so repeated successful
      // monthly payments do not shorten an existing Premium period.
      const { data: profile, error: profileReadError } = await supabaseAdmin
        .from('profiles')
        .select('subscription_expires_at')
        .eq('id', payment.user_id)
        .maybeSingle();
      if (profileReadError) throw profileReadError;

      const now = new Date();
      const currentExpiry = profile?.subscription_expires_at
        ? new Date(profile.subscription_expires_at)
        : null;
      const base = currentExpiry && currentExpiry > now ? currentExpiry : now;
      const expires = new Date(base);
      expires.setMonth(expires.getMonth() + 1);

      const { error: profileError } = await supabaseAdmin.from('profiles').update({
        subscription_active: true,
        subscription_expires_at: expires.toISOString(),
      }).eq('id', payment.user_id);
      if (profileError) throw profileError;

      console.log('Premium activated:', {
        user_id: payment.user_id,
        order_id: orderId,
        expires_at: expires.toISOString(),
      });
    }

    return res.json({ ok: true, order_id: orderId, status: normalizedStatus });
  } catch (error) {
    console.error('midtrans webhook:', error);
    return res.status(400).json({ message: 'Webhook tidak valid.' });
  }
});

const port = Number(process.env.PORT || 8080);
app.listen(port, () => console.log(`JelantahKu API listening on :${port}`));
