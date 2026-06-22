import '../models/route_result_model.dart';
import '../data/bundled_destinations.dart';

/// Kategori aramasından checkout'a giderken minimal rota özeti.
abstract final class CategoryCheckoutRoute {
  static String countryForIata(String iata) {
    for (final entry in BundledDestinations.raw) {
      if (entry['iataCode'] == iata) {
        return entry['country']?.toString() ?? '';
      }
    }
    return '';
  }

  static RouteResultModel build({
    required String destinationIata,
    required String cityName,
    String country = '',
    required int nights,
    required int passengers,
    int children = 0,
    int flightTL = 0,
    int hotelTL = 0,
    int transferTL = 0,
  }) {
    final total = flightTL + hotelTL + transferTL;
    return RouteResultModel(
      destinationIata: destinationIata,
      cityName: cityName,
      country: country.isNotEmpty ? country : countryForIata(destinationIata),
      nights: nights,
      passengers: passengers,
      children: children,
      score: 85,
      isAffordable: true,
      budgetBreakdown: RouteBudgetBreakdown(
        segment: 'category',
        segmentLabel: 'Kategori arama',
        totalBudgetTL: total.toDouble(),
        flightBudget: flightTL.toDouble(),
        hotelBudget: hotelTL.toDouble(),
        perNightHotelBudget: nights > 0 ? hotelTL / nights : hotelTL.toDouble(),
        transferBudget: transferTL.toDouble(),
        pocketMoney: 0,
        flightPercentage: 40,
        hotelPercentage: 50,
        transferPercentage: 10,
        pocketPercentage: 0,
      ),
      estimatedCost: RouteEstimatedCost(
        total: total,
        flight: flightTL,
        hotel: hotelTL,
        transfer: transferTL,
        pocketMoney: 0,
        remaining: 0,
      ),
    );
  }
}
