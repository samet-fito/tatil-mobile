# Backend deploy (Render)

Mobil uygulama production modunda `https://tatil-backend.onrender.com` adresini kullanır (`lib/constants.dart` → `isProduction = true`).

## Ön koşullar

- Backend repo: `travel-app/backend`
- Render servisi: `tatil-backend`
- Ortam değişkenleri: `.env` örneğine göre (`SUPABASE_*`, `PYTHON_API_URL`, vb.)

## Yeni uç noktalar (bu sürüm)

| Method | Path | Açıklama |
|--------|------|----------|
| POST | `/api/v1/support/chat` | Canlı destek sohbeti |
| POST | `/api/v1/payments/charge` | Ödeme stub (önizleme) |

## Deploy adımları

```bash
cd /path/to/travel-app/backend
git add backend/src/routes/support.js backend/src/routes/payments.js backend/src/services/supportService.js backend/src/server.js
git commit -m "Add support chat and payment preview endpoints"
git push origin main
```

Render otomatik deploy başlatır. Bittiğinde:

```bash
curl -s https://tatil-backend.onrender.com/health
curl -s -X POST https://tatil-backend.onrender.com/api/v1/support/chat \
  -H 'Content-Type: application/json' \
  -d '{"message":"Rezervasyonlarım nerede?"}'
```

Beklenen: `health` → `{"status":"ok",...}`; support → `success: true` ve Türkçe yanıt.

## Mobil doğrulama

1. `AppConstants.isProduction = true` olduğundan emin olun.
2. Uygulamada Profil → **Canlı Destek** veya Yardım & Destek → **Canlı destek chat**.
3. Çoklu uçuş sonuçlarında **Paket tamamla** ile otel + uçuş checkout akışını deneyin.

## Sorun giderme

- **502 / timeout:** Render free tier uykuya geçmiş olabilir; ilk istek 30–60 sn sürebilir.
- **CORS:** Mobil native isteklerde CORS sorunu olmaz; web build için `server.js` CORS ayarlarını kontrol edin.
## Python AI motoru

Uçuş/otel araması Node üzerinden; AI danışman için ayrı Python servisi:

```bash
# Render'da tatil-python-engine servisi oluşturun
# scripts/DEPLOY_PYTHON.md (travel-app repo)
```

Backend ortam değişkeni:

```
PYTHON_API_URL=https://tatil-python-engine.onrender.com
```
