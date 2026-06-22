import '../models/route_result_model.dart';
import '../utils/consumer_copy.dart';
import '../utils/plan_price_anchor.dart';
import '../utils/route_display_pricing.dart';
import '../utils/price_format.dart';

/// Canlı paketin kullanıcı bütçesine göre durumu.
enum BudgetFitKind {
  /// Kullanıcı bütçe girmedi — bütçe rozeti gösterilmez.
  unscoped,

  /// Canlı uçuş+otel toplamı bütçe içinde.
  liveWithinBudget,

  /// Plan bütçeye sığıyor; canlı henüz yok veya bütçeyi aşıyor.
  planWithinBudget,

  /// Yalnızca plan tahmini (canlı API yanıt vermedi).
  planOnly,

  /// Plan ve canlı bütçeyi aşıyor.
  overBudget,
}

/// Gateway planı + canlı fiyat zenginleştirmesi + bütçe uyumu.
class BudgetPackageOffer {
  const BudgetPackageOffer({
    required this.route,
    required this.userBudgetTL,
    required this.planPackageTL,
    this.liveFlights = const [],
    this.liveHotels = const [],
    this.flightsFromLive = false,
    this.hotelsFromLive = false,
    this.liveFlightIndex = 0,
    this.liveHotelIndex = 0,
    this.livePackageTL,
    this.upgradeWarning,
    this.smartPackageSavingsTL,
    this.isSmartOptimized = false,
  });

  final RouteResultModel route;
  final int userBudgetTL;
  final int planPackageTL;
  final List<Map<String, dynamic>> liveFlights;
  final List<Map<String, dynamic>> liveHotels;
  final bool flightsFromLive;
  final bool hotelsFromLive;
  final int liveFlightIndex;
  final int liveHotelIndex;
  final int? livePackageTL;
  final String? upgradeWarning;
  final int? smartPackageSavingsTL;
  final bool isSmartOptimized;

  static const int minUserBudgetTL = 10000;

  bool get hasUserBudget => userBudgetTL >= minUserBudgetTL;

  bool get hasVerifiedRoundTripFlight =>
      PriceFormat.hasRoundTripFlightPrice(selectedFlight);

  bool get hasLivePackage =>
      flightsFromLive &&
      hotelsFromLive &&
      liveFlights.isNotEmpty &&
      liveHotels.isNotEmpty &&
      hasVerifiedRoundTripFlight &&
      livePackageTL != null &&
      livePackageTL! > 0;

  int get displayTotalTL {
    if (hasLivePackage) return livePackageTL!;
    final hotelTL = selectedHotel != null
        ? PriceFormat.hotelTotalTL(selectedHotel!, route.nights)
        : RouteDisplayPricing.hotelStayTotalTL(route);
    final transfer = route.estimatedCost.transfer;
    final flightTL = PriceFormat.roundTripFlightTL(selectedFlight);
    if (flightTL > 0) return flightTL + hotelTL + transfer;
    return hotelTL + transfer;
  }

  int get budgetGapTL {
    if (!hasUserBudget) return 0;
    final gap = displayTotalTL - userBudgetTL;
    return gap > 0 ? gap : 0;
  }

  bool get isWithinBudget =>
      !hasUserBudget || displayTotalTL <= userBudgetTL;

  BudgetFitKind get fitKind {
    if (!hasUserBudget) return BudgetFitKind.unscoped;
    if (hasLivePackage && livePackageTL! <= userBudgetTL) {
      return BudgetFitKind.liveWithinBudget;
    }
    if (planPackageTL <= userBudgetTL) {
      return hasLivePackage
          ? BudgetFitKind.planWithinBudget
          : BudgetFitKind.planOnly;
    }
    return BudgetFitKind.overBudget;
  }

  String get fitLabel =>
      ConsumerCopy.budgetFitLabel(fitKind, hasLive: hasLivePackage);

  Map<String, dynamic>? get selectedFlight =>
      liveFlights.isNotEmpty ? liveFlights[liveFlightIndex] : null;

  Map<String, dynamic>? get selectedHotel =>
      liveHotels.isNotEmpty ? liveHotels[liveHotelIndex] : null;

  static BudgetPackageOffer fromPlan({
    required RouteResultModel route,
    required int userBudgetTL,
    String? upgradeWarning,
  }) {
    return BudgetPackageOffer(
      route: route,
      userBudgetTL: userBudgetTL,
      planPackageTL: PlanPriceAnchor.planPackageTL(route),
      upgradeWarning: upgradeWarning,
    );
  }

  int liveFlightTL() => PriceFormat.roundTripFlightTL(selectedFlight);

  int liveHotelTL() {
    final hotel = selectedHotel;
    if (hotel == null) return 0;
    return PriceFormat.hotelTotalTL(hotel, route.nights);
  }
}
