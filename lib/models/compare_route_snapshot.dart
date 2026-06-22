import '../models/budget_package_offer.dart';
import '../utils/route_display_pricing.dart';

/// Karşılaştırma için hafif rota özeti.
class CompareRouteSnapshot {
  const CompareRouteSnapshot({
    required this.destinationIata,
    required this.cityName,
    required this.country,
    required this.nights,
    required this.totalPriceTL,
    required this.flightPriceTL,
    required this.hotelPriceTL,
    required this.score,
    this.hotelName,
    this.airline,
  });

  final String destinationIata;
  final String cityName;
  final String country;
  final int nights;
  final int totalPriceTL;
  final int flightPriceTL;
  final int hotelPriceTL;
  final double score;
  final String? hotelName;
  final String? airline;

  factory CompareRouteSnapshot.fromOffer(BudgetPackageOffer offer) {
    final route = offer.route;
    final hotelName = offer.selectedHotel?['name']?.toString() ??
        route.hotel?.name;
    final airline = offer.selectedFlight?['airlineName']?.toString() ??
        offer.selectedFlight?['airline']?.toString() ??
        route.flight?.airline;

    return CompareRouteSnapshot(
      destinationIata: route.destinationIata,
      cityName: route.cityName,
      country: route.country,
      nights: route.nights,
      totalPriceTL: offer.displayTotalTL,
      flightPriceTL: RouteDisplayPricing.flightTL(route),
      hotelPriceTL: RouteDisplayPricing.hotelStayTotalTL(route),
      score: route.score,
      hotelName: hotelName,
      airline: airline,
    );
  }
}
