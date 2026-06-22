import '../catalog/catalog_data_source.dart';
import '../catalog/catalog_search_result.dart';
import 'admin_service.dart';

/// Transfer arama — Supabase partner katalog + yerel yedek.
abstract final class TransferCatalogService {
  static const _fallback = [
    {
      'name': 'Havalimanı VIP Transfer',
      'vehicleType': 'sedan',
      'fromLabel': 'Havalimanı',
      'toLabel': 'Otel / Şehir merkezi',
      'priceTL': 1200,
      'durationMinutes': 35,
      'maxPassengers': 3,
      'includes': ['Karşılama tabelası', 'Bekleme süresi', 'Bagaj yardımı'],
    },
    {
      'name': 'Paylaşımlı Shuttle',
      'vehicleType': 'van',
      'fromLabel': 'Havalimanı',
      'toLabel': 'Popüler oteller',
      'priceTL': 450,
      'durationMinutes': 55,
      'maxPassengers': 8,
      'includes': ['Sabit saatler', 'Ekonomik', 'Wi-Fi'],
    },
    {
      'name': 'Özel Minivan',
      'vehicleType': 'minivan',
      'fromLabel': 'Havalimanı',
      'toLabel': 'Herhangi bir adres',
      'priceTL': 1850,
      'durationMinutes': 40,
      'maxPassengers': 6,
      'includes': ['7/24', 'Çocuk koltuğu talebi', 'Geniş bagaj'],
    },
  ];

  static Future<CatalogSearchResult> search({
    required String destinationIata,
    required String destinationCity,
    String fromLabel = 'Havalimanı',
    String toLabel = 'Otel / Şehir merkezi',
    int passengers = 1,
  }) async {
    String? remoteError;
    List<Map<String, dynamic>> matched = [];

    try {
      final remote = await AdminService.getTransfers();
      final active = remote.where((t) => t['is_active'] != false).toList();

      matched = active
          .where((t) {
            final iata = (t['destination_iata'] as String?)?.toUpperCase();
            if (iata != null && iata.isNotEmpty) {
              return iata == destinationIata.toUpperCase();
            }
            final city = (t['destination_city'] as String?)?.toLowerCase() ?? '';
            return city.isNotEmpty &&
                destinationCity.toLowerCase().contains(city);
          })
          .map((t) => _fromRemote(t, destinationCity, passengers))
          .toList();
    } catch (_) {
      remoteError = 'Partner transfer kataloğu yüklenemedi';
    }

    if (matched.isNotEmpty) {
      return CatalogSearchResult.success(
        matched,
        CatalogDataSource.supabase,
        providerId: 'transfer-supabase',
      );
    }

    final local = _fallback
        .map((t) {
          final price = (t['priceTL'] as int) * (passengers > 3 ? 2 : 1);
          return {
            ...t,
            'id': 'transfer-fallback-${t['name']}',
            'destinationCity': destinationCity,
            'destinationIata': destinationIata,
            'fromLabel': fromLabel,
            'toLabel': toLabel,
            'passengers': passengers,
            'priceTL': price,
            'source': 'catalog',
          };
        })
        .toList();

    if (local.isNotEmpty) {
      return CatalogSearchResult.fallback(
        local,
        apiError: remoteError,
      );
    }

    return CatalogSearchResult.failure(
      message: remoteError ?? 'Transfer bulunamadı',
    );
  }

  static Map<String, dynamic> _fromRemote(
    Map<String, dynamic> t,
    String city,
    int passengers,
  ) {
    final base = (t['price_tl'] as num?)?.toInt() ??
        (t['priceTL'] as num?)?.toInt() ??
        1200;
    return {
      'id': t['id']?.toString() ?? 'transfer-${t['name']}',
      'name': t['name'] ?? 'Transfer',
      'vehicleType': t['vehicle_type'] ?? t['vehicleType'] ?? 'sedan',
      'fromLabel': t['from_label'] ?? t['fromLabel'] ?? 'Havalimanı',
      'toLabel': t['to_label'] ?? t['toLabel'] ?? 'Otel',
      'destinationCity': city,
      'destinationIata': t['destination_iata'] ?? t['destinationIata'],
      'priceTL': base * (passengers > 4 ? 2 : 1),
      'durationMinutes': (t['duration_minutes'] as num?)?.toInt() ?? 40,
      'maxPassengers': (t['max_passengers'] as num?)?.toInt() ?? 4,
      'includes': List<String>.from(
        t['includes'] ?? ['Özel transfer', 'Sürücü beklemesi'],
      ),
      'passengers': passengers,
      'source': 'supabase',
    };
  }
}
