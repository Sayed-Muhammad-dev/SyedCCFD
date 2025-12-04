# CCD Webhook Server (Option B)

This small Express server provides an HTTPS endpoint to receive transaction webhooks, write to Firestore, run simple fraud rules, create `flags` and `alerts`, and send FCM pushes to all of a user's device tokens.

## What it's used for
- Replace Firebase HTTPS Functions when billing cannot be enabled.
- Accept external HTTP webhooks at `/webhook/transactions`.
- Secure access via `x-api-key` header (`WEBHOOK_API_KEY`).
- Send push notifications via Firebase Cloud Messaging using `firebase-admin`.

## How it works
1. Caller POSTs a JSON payload to `/webhook/transactions` with header `x-api-key: <secret>`.
2. Server validates the key, normalizes timestamp to milliseconds, upserts `transactions/{txnId}`.
3. Runs rules (amount > 5000, odd hours, 5-min velocity). If suspicious:
   - Upsert `flags/{txnId}` and `alerts/{txnId}`.
   - Load `users/{userId}.fcmTokens` (string or array) and send FCM to each token.
   - On invalid tokens, remove them from the user's `fcmTokens`.

## Setup
1. Generate a Firebase service account JSON (Project Settings → Service accounts → Generate new private key). Do NOT commit it.
2. Create environment variables (Render/Railway/Fly.io/Vercel):
   - `WEBHOOK_API_KEY`: long random secret
   - `GOOGLE_SERVICE_ACCOUNT_JSON`: the entire JSON of the service account (as a single env var)
3. Deploy

## Local development
```bash
cd server
npm install
# Create .env in your host or export vars in shell
# WEBHOOK_API_KEY=... ; GOOGLE_SERVICE_ACCOUNT_JSON='{...}'
npm run dev
```

POST example (PowerShell):
```powershell
$body = @{
  txnId     = "txn_12345"
  userId    = "REPLACE_WITH_UID"
  amount    = 6001
  timestamp = [int][double]::Parse((Get-Date -UFormat %s)) * 1000
} | ConvertTo-Json

Invoke-RestMethod \
  -Method POST \
  -Uri "http://localhost:8080/webhook/transactions" \
  -Headers @{ "x-api-key" = "REPLACE_WITH_A_LONG_RANDOM_SECRET"; "Content-Type" = "application/json" } \
  -Body $body
```

## Deploy hints
- Render: add a Web Service, set `start` command to `node src/index.js`, and configure the two env vars.
- Railway/Fly.io: similar; ensure Node 18+ runtime.
- Vercel: use a Node serverless function or deploy as a separate service; set env vars in project settings.


