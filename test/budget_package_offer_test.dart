import 'package:flutter_test/flutter_test.dart';
import 'package:tatil_arama/models/budget_package_offer.dart';
import 'package:tatil_arama/models/route_result_model.dart';

RouteResultModel _route({
  required String iata,
  required int flight,
  required int hotel,
  double score = 80,
}) {
  return RouteResultModel(
    destinationIata: iata,
    cityName: iata,
    country: 'TR',
    nights: 5,
    passengers: 1,
    score: score,
    isAffordable: true,
    budgetBreakdown: RouteBudgetBreakdown.fromNodeJson(
      {'segment': 'standard', 'segmentLabel': 'Standart', 'totalBudgetTL': 120000},
      {
        'transport': {'total': 24000, 'percentage': 20},
        'accommodation': {'total': 60000, 'perNightBudget': 12000, 'percentage': 50},
        'pocketMoney': {'total': 36000, 'percentage': 30},
      },
    ),
    estimatedCost: RouteEstimatedCost.fromNodeJson({
      'total': flight + hotel,
      'flight': flight,
      'hotel': hotel,
      'living': 0,
      'remaining': 0,
    }),
    flight: RouteFlightModel.fromNodeJson(
      {'airline': 'THY', 'duration': '1s', 'stops': 0},
      {'flight': flight},
    ),
    hotel: RouteHotelModel.fromNodeJson(
      {'name': 'Test Hotel', 'rating': 8.5, 'reviewCount': 100, 'stars': 4},
      {'hotel': hotel},
      5,
    ),
  );
}

BudgetPackageOffer _offer({
  required RouteResultModel route,
  required int budget,
  int? livePackageTL,
}) {
  return BudgetPackageOffer(
    route: route,
    userBudgetTL: budget,
    planPackageTL: route.estimatedCost.flight + route.estimatedCost.hotel,
    liveFlights: livePackageTL != null ? const [{'totalAmountTL': 2000}] : const [],
    liveHotels: livePackageTL != null ? const [{'pricePerNightTL': 8000}] : const [],
    flightsFromLive: livePackageTL != null,
    hotelsFromLive: livePackageTL != null,
    livePackageTL: livePackageTL,
  );
}

void main() {
  test('BudgetPackageOffer fitKind respects live vs plan budget', () {
    final route = _route(iata: 'AYT', flight: 1800, hotel: 38000);
    final within = _offer(route: route, budget: 60000, livePackageTL: 52000);
    expect(within.fitKind, BudgetFitKind.liveWithinBudget);
    expect(within.isWithinBudget, isTrue);

    final overLive = _offer(route: route, budget: 40000, livePackageTL: 52000);
    expect(overLive.fitKind, BudgetFitKind.planWithinBudget);

    final planOnly = BudgetPackageOffer.fromPlan(route: route, userBudgetTL: 50000);
    expect(planOnly.fitKind, BudgetFitKind.planOnly);
  });

  test('BudgetPackageOffer without user budget is unscoped', () {
    final route = _route(iata: 'FCO', flight: 5000, hotel: 35000);
    final unscoped = _offer(route: route, budget: 0, livePackageTL: 42000);
    expect(unscoped.fitKind, BudgetFitKind.unscoped);
    expect(unscoped.budgetGapTL, 0);
    expect(unscoped.fitLabel, isEmpty);
  });
}
