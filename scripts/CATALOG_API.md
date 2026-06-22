# Katalog API (Otobüs & Araç Kiralama)

Mobil uygulama kategori aramalarını `CatalogSearchResult` üzerinden yönetir:

| Katman | Dosya | Açıklama |
|--------|-------|----------|
| Model | `lib/catalog/catalog_search_result.dart` | Ortak sonuç + kaynak (liveApi / localCatalog / affiliate) |
| Sağlayıcı ID | `lib/catalog/catalog_provider_registry.dart` | API ve affiliate slotları |
| Otobüs | `lib/services/bus_catalog_service.dart` | API → yedek `BusRoutesCatalog` |
| Araç | `lib/services/car_rental_catalog_service.dart` | API → yedek `CarRentalCatalog` |
| Transfer | `lib/services/transfer_catalog_service.dart` | Supabase → yerel katalog |

## Backend uçları (Render)

Production base: `https://tatil-backend.onrender.com/api/v1`

- `GET /bus/search?from=İstanbul&to=Ankara&date=2026-07-15&passengers=1`
- `GET /bus/cities`
- `GET /car-rental/search?city=Antalya&pickup=2026-07-15&dropoff=2026-07-18`

Yanıt formatı:

```json
{
  "success": true,
  "data": {
    "trips": [ ... ]
  }
}
```

```json
{
  "success": true,
  "data": {
    "vehicles": [ ... ]
  }
}
```

## Deploy

Backend repo: `travel-app/backend`

```bash
cd travel-app/backend
git add src/routes/bus.js src/routes/carRental.js src/services/
git commit -m "Add bus and car rental catalog endpoints"
git push origin main
```

Render otomatik deploy sonrası mobil uygulama `AppConstants.isProduction = true` ile bu uçları kullanır.

## Affiliate ekleme (ileride)

1. `CatalogProviderRegistry` içine yeni `affiliate-*` ID ekleyin
2. İlgili `*CatalogService.search` içinde sırayı tanımlayın: `liveApi → affiliate → localCatalog`
3. Sonuç ekranı `_CategoryResultsScaffold` kaynak rozetini otomatik gösterir

Akışı bozmamak için mevcut servis imzalarını değiştirmeyin; yalnızca `CatalogSearchResult` döndürün.
