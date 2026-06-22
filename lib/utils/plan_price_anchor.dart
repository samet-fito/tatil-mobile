import '../models/route_result_model.dart';
import 'price_format.dart';
import 'route_display_pricing.dart';

/// Kart / detay / checkout arasında plan tahmini fiyat hizası.
class PlanPriceAnchor {
  PlanPriceAnchor._();

  static const maxHotelRatio = 1.45;

  static int planPackageTL(RouteResultModel route) =>
      RouteDisplayPricing.packageTL(route);

  static int planFlightTL(RouteResultModel route) => route.estimatedCost.flight;

  static int planHotelTL(RouteResultModel route) =>
      RouteDisplayPricing.hotelStayTotalTL(route);

  static int targetHotelPerNightTL(RouteResultModel route) =>
      RouteDisplayPricing.hotelPerNightTL(route);

  static String planFlightLabel(RouteResultModel route) =>
      route.flight?.airline ?? 'Uçuş';

  static String planHotelLabel(RouteResultModel route) =>
      route.hotel?.name ?? 'Otel';

  static bool isHotelOutOfBand(
    Map<String, dynamic>? hotel,
    RouteResultModel route,
  ) {
    if (hotel == null) return false;
    final target = targetHotelPerNightTL(route);
    if (target <= 0) return false;
    final live = PriceFormat.hotelPerNightTL(hotel);
    if (live <= 0) return false;
    return live / target > maxHotelRatio;
  }

  static int planPayableTL(RouteResultModel route, {int extrasTL = 0}) =>
      planPackageTL(route) + extrasTL;
}
