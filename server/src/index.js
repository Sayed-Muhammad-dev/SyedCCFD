import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import admin from 'firebase-admin';

// Initialize firebase-admin using a service account JSON from env
const serviceAccountJson = process.env.GOOGLE_SERVICE_ACCOUNT_JSON;
if (!serviceAccountJson) {
  console.error('Missing GOOGLE_SERVICE_ACCOUNT_JSON env var');
  process.exit(1);
}

const serviceAccount = JSON.parse(serviceAccountJson);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const app = express();
app.use(helmet());
app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));
app.use(morgan('combined'));

// Health check
app.get('/health', (req, res) => res.send('ok'));

// Get all transactions endpoint
app.get('/api/transactions', async (req, res) => {
  try {
    const apiKey = req.headers['x-api-key'];
    if (!process.env.WEBHOOK_API_KEY || apiKey !== process.env.WEBHOOK_API_KEY) {
      return res.status(401).send('Unauthorized');
    }

    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;
    const userId = req.query.userId; // Optional user filter

    let query = db.collection('transactions');
    
    // If userId is provided, filter by user
    if (userId) {
      query = query.where('userId', '==', userId);
    }
    
    const snapshot = await query
      .orderBy('timestamp', 'desc')
      .limit(limit)
      .offset(offset)
      .get();

    const transactions = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      transactions.push({
        id: doc.id,
        ...data,
        timestamp: data.timestamp || Date.now()
      });
    });

    res.json({
      success: true,
      data: transactions,
      total: transactions.length,
      limit,
      offset
    });
  } catch (err) {
    console.error('Error fetching transactions:', err);
    res.status(500).json({ success: false, error: 'Internal Server Error' });
  }
});

// Webhook endpoint for transactions
app.post('/webhook/transactions', async (req, res) => {
  try {
    const apiKey = req.headers['x-api-key'];
    if (!process.env.WEBHOOK_API_KEY || apiKey !== process.env.WEBHOOK_API_KEY) {
      return res.status(401).send('Unauthorized');
    }

    const txn = req.body || {};
    if (!txn.txnId || !txn.userId) return res.status(400).send('Invalid payload');

    // Normalize timestamp to millis
    const nowMillis = Date.now();
    const inputTs = txn.timestamp;
    let tsMillis = nowMillis;
    if (typeof inputTs === 'number') tsMillis = inputTs;
    if (inputTs && typeof inputTs === 'object' && typeof inputTs.seconds === 'number') {
      tsMillis = inputTs.seconds * 1000 + (inputTs.nanoseconds ? Math.floor(inputTs.nanoseconds / 1e6) : 0);
    }
    txn.timestamp = tsMillis;

    await db.collection('transactions').doc(txn.txnId).set(txn, { merge: true });

    // Simple fraud rules
    let suspicious = false; const reasons = [];
    if (txn.amount > 5000) { suspicious = true; reasons.push('Large amount'); }
    const hour = new Date(tsMillis).getHours();
    if (hour < 6 || hour > 22) { suspicious = true; reasons.push('Odd hour'); }
    // Check for test merchants
    const merchant = (txn.merchant || '').toLowerCase();
    if (merchant.includes('test') || merchant.includes('dummy')) { 
      suspicious = true; 
      reasons.push('Test merchant'); 
    }
    const sinceMillis = Date.now() - 5 * 60 * 1000;
    const recentTxns = await db.collection('transactions')
      .where('userId', '==', txn.userId)
      .where('timestamp', '>=', sinceMillis)
      .get();
    if (recentTxns.size > 3) { suspicious = true; reasons.push('High velocity'); }

    if (suspicious) {
      const flagRef = db.collection('flags').doc(txn.txnId);
      const alertRef = db.collection('alerts').doc(txn.txnId);
      await flagRef.set({
        userId: txn.userId,
        txnId: txn.txnId,
        transactionId: txn.txnId, // Add for compatibility with realtime check screen
        cardId: txn.cardId || txn.cardNumber,
        merchant: txn.merchant,
        amount: txn.amount,
        reasons,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      await alertRef.set({
        userId: txn.userId,
        txnId: txn.txnId,
        transactionId: txn.txnId,
        cardId: txn.cardId || txn.cardNumber,
        merchant: txn.merchant,
        amount: txn.amount,
        reasons,
        type: 'suspicious_transaction',
        status: 'unread',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      // Send FCM to all tokens
      const userDoc = await db.collection('users').doc(txn.userId).get();
      let tokens = userDoc.get('fcmTokens');
      if (typeof tokens === 'string') tokens = [tokens];
      if (Array.isArray(tokens)) {
        for (const token of tokens) {
          try {
            await admin.messaging().send({
              token,
              notification: { title: 'Fraud Alert', body: `Suspicious transaction: ${txn.txnId}` },
              data: { alertId: txn.txnId, txnId: txn.txnId },
              android: { priority: 'high' },
              apns: { headers: { 'apns-priority': '10' } }
            });
          } catch (err) {
            if (['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(err.code)) {
              await db.collection('users').doc(txn.userId)
                .update({ fcmTokens: admin.firestore.FieldValue.arrayRemove(token) });
            }
          }
        }
      }
    }

    res.send('OK');
  } catch (err) {
    console.error(err);
    res.status(500).send('Internal Server Error');
  }
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});


