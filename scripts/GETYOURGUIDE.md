# GetYourGuide — Vizegoo Entegrasyonu

## Aktif mod: Affiliate (deep link)

API token onayı gelene kadar aktiviteler **GetYourGuide partner linkleri** ile açılır.
Rezervasyon harici tarayıcıda tamamlanır (komisyon takibi için GYG’nin önerdiği yöntem).

### Kurulum

1. [partner.getyourguide.com](https://partner.getyourguide.com/) → **Account Details** → **Partner ID** kopyalayın
2. `lib/config/gyg_affiliate_config.dart` dosyasına yapıştırın:

```dart
static const String partnerId = 'SIZIN_PARTNER_ID';
static const bool useAffiliateLinks = true;
```

3. Uygulamayı yeniden derleyin

### Link formatları

| Amaç | URL |
|------|-----|
| Şehir araması | `getyourguide.com/s/?partner_id=…&q=Paris, France&cmp=vizegoo` |
| Tur / aktivite | `gygUrl` varsa partner_id eklenir; yoksa başlık + şehir araması |

### Kod

| Dosya | Görev |
|-------|-------|
| `lib/config/gyg_affiliate_config.dart` | Partner ID, kampanya |
| `lib/services/gyg_affiliate_service.dart` | Link üretimi + tarayıcıda açma |

---

## Gelecek mod: Partner API (Masterbill)

API onayı sonrası:

```dart
static const bool useAffiliateLinks = false;
```

Backend’e `GYG_ACCESS_TOKEN` ekleyin. Detay: backend `getYourGuideService.js`.

---

## Partner API başvuru mesajı (İngilizce)

```
Hello,

We are building Vizegoo, a mobile travel planning app (iOS/Android) that helps 
users discover destinations and book tours and activities.

We have already integrated GetYourGuide affiliate deep links in our app. We would 
like to request access to the Partner API (Masterbill) so we can offer in-app 
search, availability, and booking with Vizegoo as the merchant of record.

Our technical stack is ready:
- Backend proxy (Node.js) for tour search, options, and booking
- Flutter mobile client with checkout flow

Could you please advise on:
1. Sandbox API access and token provisioning
2. Masterbill eligibility and next steps for our application

App: Vizegoo (mobile travel & activities)
Contact: [your email]

Thank you,
Muhammed Samed
```
