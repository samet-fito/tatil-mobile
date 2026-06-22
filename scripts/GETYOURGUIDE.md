# GetYourGuide Partner API — Vizegoo Entegrasyonu

## Genel bakış

Vizegoo aktivite akışı GetYourGuide **Partner API** üzerinden çalışır. Affiliate link programı değil; arama, detay, müsaitlik ve rezervasyon backend proxy ile yapılır.

| Katman | Dosya | Görev |
|--------|-------|-------|
| Backend servis | `travel-app/backend/src/services/getYourGuideService.js` | GYG REST çağrıları |
| Backend orchestration | `travel-app/backend/src/services/activityService.js` | GYG → mock fallback |
| Backend routes | `travel-app/backend/src/routes/activities.js` | HTTP uçları |
| Mobil API | `lib/services/api_service.dart` | `getActivities`, `bookActivity` |
| Mobil UI | `activity_experience_detail_screen.dart` | Müsaitlik + checkout |
| Checkout | `category_simple_checkout_screen.dart` | Ödeme → GYG book |

## Ortam değişkenleri (backend)

```env
GYG_ACCESS_TOKEN=your_partner_token
GYG_USE_SANDBOX=true          # test: api.gygtest.net
GYG_API_VERSION=1
GYG_CURRENCY=EUR
GYG_CONTENT_LANGUAGE=en
EUR_TO_TL=35
GYG_PRICE_MARGIN=1.08         # komisyon + kur marjı
```

Token yoksa backend otomatik **mock aktivite** döner; uygulama çalışmaya devam eder.

## API uçları

| Method | Path | Açıklama |
|--------|------|----------|
| GET | `/api/v1/activities?iata&city&departure&return` | Şehir aktiviteleri |
| GET | `/api/v1/activities/status` | GYG yapılandırma durumu |
| GET | `/api/v1/activities/tour/:tourId` | Tur detayı |
| GET | `/api/v1/activities/tour/:tourId/options?date=` | Tarih seçenekleri |
| POST | `/api/v1/activities/book` | Ödeme sonrası rezervasyon |

## Mobil akış

1. Kullanıcı destinasyon rehberinde aktiviteleri görür (`getCommissionActivities`).
2. GYG kaynaklı kartta `gygTourId` ve `imageUrl` gelir.
3. Detay ekranında tarih seçilince `getActivityTourOptions` ile `gygOptionId` alınır.
4. Checkout'ta `PaymentService.charge` → `ApiService.bookActivity` (GYG kaynaklıysa).
5. Başarı ekranında `gygBookingRef` gösterilir.

## Partner hesabı

1. https://partner.getyourguide.com/ üzerinden Partner API erişimi talep edin.
2. Sandbox token ile `GYG_USE_SANDBOX=true` ayarlayın.
3. Render/production `.env` dosyasına `GYG_ACCESS_TOKEN` ekleyin ve backend'i yeniden deploy edin.

## Test

```bash
# Backend (travel-app/backend)
curl "http://localhost:3001/api/v1/activities/status"
curl "http://localhost:3001/api/v1/activities?iata=ROM&city=Roma&departure=2026-07-10&return=2026-07-15"
```

## Notlar

- Fiyatlar EUR'dan TL'ye `EUR_TO_TL * GYG_PRICE_MARGIN` ile hesaplanır.
- Gerçek ödeme `AppExperience.paymentsEnabled = true` olunca aktif olur; şu an simülasyon modu.
- Booking için GYG'nin `category_id` değerleri tur bazında değişebilir; production'da `options` yanıtından alınmalıdır.
