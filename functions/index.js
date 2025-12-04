const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// HTTPS endpoint for bank webhook
exports.webhookTransactions = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');
    const apiKey = req.headers['x-api-key'];
    const expectedKey = (functions.config().webhook && functions.config().webhook.key) || process.env.WEBHOOK_API_KEY;
    if (!expectedKey || apiKey !== expectedKey) return res.status(401).send('Unauthorized');

    const txn = req.body;
    if (!txn || !txn.txnId || !txn.userId) return res.status(400).send('Invalid payload');

    // Normalize timestamp to millis
    const nowMillis = Date.now();
    const inputTs = txn.timestamp;
    let tsMillis = nowMillis;
    if (typeof inputTs === 'number') tsMillis = inputTs;
    if (inputTs && typeof inputTs === 'object' && typeof inputTs.seconds === 'number') {
      tsMillis = inputTs.seconds * 1000 + (inputTs.nanoseconds ? Math.floor(inputTs.nanoseconds / 1e6) : 0);
    }
    txn.timestamp = tsMillis;

    await admin.firestore().collection('transactions').doc(txn.txnId).set(txn, { merge: true });
    res.status(200).send('Transaction received');
  } catch (err) {
    console.error('webhook error', err);
    res.status(500).send('Internal Server Error');
  }
});

// Firestore trigger for fraud detection and FCM
exports.detectFraudAndAlert = functions.firestore
  .document('transactions/{txnId}')
  .onWrite(async (change, context) => {
    const txn = change.after.exists ? change.after.data() : null;
    if (!txn) return;
    const { amount, userId, txnId } = txn;
    let timestamp = txn.timestamp;
    // Normalize timestamp to millis
    if (timestamp && timestamp._seconds) {
      timestamp = timestamp._seconds * 1000;
    } else if (timestamp && timestamp.seconds) {
      timestamp = timestamp.seconds * 1000;
    }
    let suspicious = false, reasons = [];
    if (amount > 5000) { suspicious = true; reasons.push('Large amount'); }
    const hour = new Date(timestamp || Date.now()).getHours();
    if (hour < 6 || hour > 22) { suspicious = true; reasons.push('Odd hour'); }
    // Velocity check: last 5 min
    const sinceMillis = Date.now() - 5 * 60 * 1000;
    const recentTxns = await admin.firestore().collection('transactions')
      .where('userId', '==', userId)
      .where('timestamp', '>=', sinceMillis)
      .get();
    if (recentTxns.size > 3) { suspicious = true; reasons.push('High velocity'); }
    if (!suspicious) return;

    // De-duplicate flag/alert
    const flagRef = admin.firestore().collection('flags').doc(txnId);
    const alertRef = admin.firestore().collection('alerts').doc(txnId);
    await flagRef.set({
      userId, txnId, reasons, status: 'pending', createdAt: admin.firestore.FieldValue.serverTimestamp()
    }, {merge: true});
    await alertRef.set({
      userId, txnId, reasons, type: 'suspicious_transaction', status: 'unread', createdAt: admin.firestore.FieldValue.serverTimestamp()
    }, {merge: true});

    // FCM tokens
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    let tokens = userDoc.get('fcmTokens');
    if (!tokens) return;
    if (typeof tokens === 'string') tokens = [tokens];
    for (const token of tokens) {
      try {
        await admin.messaging().send({
          token,
          notification: { title: 'Fraud Alert', body: `Suspicious transaction: ${txnId}` },
          data: { alertId: txnId, txnId: txnId },
          android: { priority: 'high' },
          apns: { headers: { 'apns-priority': '10' } }
        });
      } catch (err) {
        if (
          err.code === 'messaging/registration-token-not-registered' ||
          err.code === 'messaging/invalid-registration-token'
        ) {
          await admin.firestore().collection('users').doc(userId)
            .update({ fcmTokens: admin.firestore.FieldValue.arrayRemove(token) });
        }
      }
    }
  });
