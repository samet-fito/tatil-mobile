import '../catalog/catalog_data_source.dart';
import '../catalog/catalog_search_result.dart';
import '../data/car_rental_catalog.dart';
import 'api_service.dart';

/// Araç kiralama arama — canlı API öncelikli, yerel katalog yedek.
abstract final class CarRentalCatalogService {
  static Future<CatalogSearchResult> search({
    required String city,
    required DateTime pickup,
    required DateTime dropoff,
  }) async {
    final pickupStr = pickup.toIso8601String().split('T')[0];
    final dropoffStr = dropoff.toIso8601String().split('T')[0];
    String? apiError;
    List<Map<String, dynamic>> remote = [];

    try {
      remote = await ApiService.searchCarRentals(
        city: city,
        pickup: pickupStr,
        dropoff: dropoffStr,
      );
    } catch (_) {
      apiError = 'Canlı araç kiralama API\'sine ulaşılamadı';
    }

    if (remote.isNotEmpty) {
      return CatalogSearchResult.success(
        remote,
        CatalogDataSource.liveApi,
        providerId: 'car-rental-gateway',
      );
    }

    final local = CarRentalCatalog.search(
      city: city,
      pickup: pickup,
      dropoff: dropoff,
    );

    if (local.isNotEmpty) {
      return CatalogSearchResult.fallback(local, apiError: apiError);
    }

    if (apiError != null) {
      return CatalogSearchResult.failure(message: apiError);
    }

    return const CatalogSearchResult(
      items: [],
      source: CatalogDataSource.liveApi,
      status: CatalogSearchStatus.empty,
    );
  }
}
