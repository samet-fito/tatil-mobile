import '../models/route_result_model.dart';
import 'price_format.dart';

/// Rota kartında gösterilecek plan fiyatları — gecelik otel × gece sayısı.
class RouteDisplayPricing {
  RouteDisplayPricing._();

  static int flightTL(RouteResultModel route) => route.estimatedCost.flight;

  static int hotelStayTotalTL(RouteResultModel route) {
    final nights = route.nights.clamp(1, 365);
    final raw = route.estimatedCost.hotel;
    if (raw <= 0) return 0;

    final modelTotal = route.hotel?.totalPrice ?? 0;
    if (modelTotal > 0) return modelTotal.round();

    return RouteEstimatedCost.normalizeHotelStayTotal(
      rawHotel: raw,
      nights: nights,
      hotelBudget: route.budgetBreakdown.hotelBudget,
      perNightHotelBudget: route.budgetBreakdown.perNightHotelBudget,
    );
  }

  static int packageTL(RouteResultModel route) =>
      flightTL(route) + hotelStayTotalTL(route);

  /// Tahmini uçuş hariç — yalnızca doğrulanmış gidiş-dönüş fiyatı eklenir.
  static int displayPackageTL(
    RouteResultModel route, {
    Map<String, dynamic>? liveFlight,
    int? liveHotelTL,
  }) {
    final hotel = liveHotelTL ?? hotelStayTotalTL(route);
    final transfer = route.estimatedCost.transfer;
    final flight = PriceFormat.roundTripFlightTL(liveFlight);
    return flight + hotel + transfer;
  }

  static int hotelPerNightTL(RouteResultModel route) {
    final nights = route.nights.clamp(1, 365);
    final total = hotelStayTotalTL(route);
    return nights > 0 ? (total / nights).round() : total;
  }

  static String hotelPriceHint(RouteResultModel route) {
    final pricePart =
        '${route.nights} gece · ${PriceFormat.format(hotelPerNightTL(route))}/gece toplam';
    final name = route.hotel?.name;
    if (name != null && name.isNotEmpty && name != '--') {
      return '$name · $pricePart';
    }
    return pricePart;
  }
}
