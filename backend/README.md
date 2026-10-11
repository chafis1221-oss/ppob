# Backend PPOB

Go `net/http` prototype Digiflazz Buyer. Frontend belum terhubung.

## Run

```bash
cd backend
DIGIFLAZZ_MOCK=true go run .
# production: DIGIFLAZZ_USERNAME=... DIGIFLAZZ_API_KEY=... DIGIFLAZZ_WEBHOOK_SECRET=... go run .
```

Config: `DIGIFLAZZ_BASE_URL` default `https://api.digiflazz.com/v1`; credentials wajib kecuali mock.

Internal JSON POST endpoints:

- `/api/price-list` — `cmd=prepaid` signature `md5(username+apiKey+pricelist)`
- `/api/balance` — `cmd=deposit` signature `md5(username+apiKey+depo)`
- `/api/prepaid` — topup; `/api/postpaid/inquiry` — `inq-pasca`; `/api/postpaid/payment` — `pay-pasca`; `/api/status` — `status-pasca`
- `/webhooks/digiflazz` — validates `X-Hub-Signature: sha1=<HMAC-SHA1(body, secret)>` when secret configured

All transaction endpoints require `ref_id`. In-memory idempotency returns the first response per ref ID; restart loses it. Mock mode avoids provider calls.

## Checks

```bash
gofmt -w .
go test ./...
go vet ./...
```

## Caveats

Prototype only: no persistent DB, authentication/rate limiting, webhook event persistence, retries, TLS termination, or production observability. Put behind authenticated internal network and HTTPS. Verify provider account mode, product fields, and webhook secret in Digiflazz dashboard before production.

## Official docs

- https://developer.digiflazz.com/api/buyer/daftar-harga/
- https://developer.digiflazz.com/api/buyer/cek-saldo/
- https://developer.digiflazz.com/api/buyer/topup/
- https://developer.digiflazz.com/api/buyer/cek-tagihan/
- https://developer.digiflazz.com/api/buyer/bayar-tagihan/
- https://developer.digiflazz.com/api/buyer/cek-status/
- https://developer.digiflazz.com/api/buyer/webhook/
