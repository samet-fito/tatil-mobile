import '../catalog/catalog_data_source.dart';
import '../catalog/catalog_search_result.dart';
import '../data/bus_routes_catalog.dart';
import 'api_service.dart';

/// Otobüs arama — canlı API öncelikli, yerel katalog yedek.
abstract final class BusCatalogService {
  static List<String> get cities => BusRoutesCatalog.cities;

  static Future<CatalogSearchResult> search({
    required String fromCity,
    required String toCity,
    required DateTime date,
    required int passengers,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    String? apiError;
    List<Map<String, dynamic>> remote = [];

    try {
      remote = await ApiService.searchBusTrips(
        fromCity: fromCity,
        toCity: toCity,
        date: dateStr,
        passengers: passengers,
      );
    } catch (_) {
      apiError = 'Canlı otobüs API\'sine ulaşılamadı';
    }

    if (remote.isNotEmpty) {
      return CatalogSearchResult.success(
        remote,
        CatalogDataSource.liveApi,
        providerId: 'bus-gateway',
      );
    }

    final local = BusRoutesCatalog.search(
      fromCity: fromCity,
      toCity: toCity,
      date: date,
      passengers: passengers,
    );

    if (local.isNotEmpty) {
      return CatalogSearchResult.fallback(local, apiError: apiError);
    }

    if (apiError != null) {
      return CatalogSearchResult.failure(message: apiError);
    }

    return CatalogSearchResult(
      items: const [],
      source: CatalogDataSource.liveApi,
      status: CatalogSearchStatus.empty,
    );
  }
}
