import '../models/budget_package_offer.dart';
import '../models/budget_search_outcome.dart';
import '../models/route_result_model.dart';
import '../models/search_model.dart';
import '../utils/consumer_copy.dart';
import '../utils/live_offer_matcher.dart';
import '../utils/plan_price_anchor.dart';
import '../utils/price_format.dart';
import '../utils/route_display_pricing.dart';
import '../utils/route_filter_engine.dart';
import 'api_service.dart';
import 'route_search_service.dart';
import 'smart_package_optimizer.dart';

/// Bütçe merkezli arama — gateway planı + canlı uçuş/otel zenginleştirmesi.
class BudgetOrchestrator {
  BudgetOrchestrator._();

  static const _maxEnrichRoutes = 6;
  static const _enrichConcurrency = 4;
  static const _liveTimeout = Duration(seconds: 35);

  /// [enrichLive] false ise gateway planları hemen döner; canlı fiyatlar sonra yüklenebilir.
  static Future<BudgetSearchOutcome> search(
    SearchModel model, {
    bool forceNetwork = false,
    bool enrichLive = true,
  }) async {
    final planOutcome = await _searchPlans(model, forceNetwork: forceNetwork);
    if (!planOutcome.isSuccess) return planOutcome;

    if (!enrichLive) return planOutcome;

    final enriched = await enrichOffersProgressively(
      model: model,
      offers: planOutcome.offers,
    );

    return BudgetSearchOutcome(
      offers: enriched,
      bannerMessage: _composeBanner(
        filterBanner: planOutcome.bannerMessage,
        offers: enriched,
        budgetTL: model.totalBudgetTL.round(),
      ),
      liveEnrichedCount:
          enriched.where((o) => o.hasLivePackage).length,
    );
  }

  /// Plan rotalarını canlı uçuş/otel ile günceller; her grup sonrası [onUpdate] çağrılır.
  static Future<List<BudgetPackageOffer>> enrichOffersProgressively({
    required SearchModel model,
    required List<BudgetPackageOffer> offers,
    void Function(List<BudgetPackageOffer> offers)? onUpdate,
  }) async {
    final list = List<BudgetPackageOffer>.from(offers);
    final indices = <int>[];
    for (var i = 0; i < list.length && indices.length < _maxEnrichRoutes; i++) {
      if (!list[i].hasLivePackage) indices.add(i);
    }
    if (indices.isEmpty) return list;

    final warnings = {
      for (final o in list)
        o.route.destinationIata.toUpperCase(): o.upgradeWarning,
    };

    for (var i = 0; i < indices.length; i += _enrichConcurrency) {
      final chunk = indices.skip(i).take(_enrichConcurrency).toList();
      final results = await Future.wait(
        chunk.map(
          (idx) => _enrichRoute(
            model: model,
            route: list[idx].route,
            upgradeWarning: warnings[list[idx].route.destinationIata.toUpperCase()],
          ),
        ),
      );
      for (var j = 0; j < chunk.length; j++) {
        list[chunk[j]] = results[j];
      }
      onUpdate?.call(List<BudgetPackageOffer>.from(list));
    }

    return _sortOffers(
      list,
      sortByCheapest: model.sortByCheapest,
    );
  }

  static Future<BudgetSearchOutcome> _searchPlans(
    SearchModel model, {
    bool forceNetwork = false,
  }) async {
    final gatewayOutcome = await RouteSearchService.searchWithCacheFallback(
      model,
      forceNetwork: forceNetwork,
    );

    if (!gatewayOutcome.isSuccess) {
      return BudgetSearchOutcome(
        offers: const [],
        failure: gatewayOutcome.failure,
        message: gatewayOutcome.userMessage,
      );
    }

    var routes = gatewayOutcome.routes;

    final destIata = model.destinationIata?.toUpperCase();
    final destCountry = model.destinationCountry;
    if (destIata != null && destIata.isNotEmpty) {
      final filtered = routes
          .where((r) => r.destinationIata.toUpperCase() == destIata)
          .toList();
      if (filtered.isNotEmpty) routes = filtered;
    } else if (destCountry != null && destCountry.isNotEmpty) {
      final filtered = routes.where((r) => r.country == destCountry).toList();
      if (filtered.isNotEmpty) routes = filtered;
    }

    final filtered = RouteFilterEngine.apply(
      routes: routes,
      budgetTL: model.totalBudgetTL,
      holidayTypes: model.holidayTypes,
      minRating: model.minServiceRating,
      maxRating: model.maxServiceRating,
      sortByCheapest: model.sortByCheapest,
    );

    final ranked = filtered.routes.isNotEmpty
        ? filtered.routes
        : routes.map((route) => RankedRoute(route: route)).toList();

    final planOffers = ranked
        .map(
          (r) => BudgetPackageOffer.fromPlan(
            route: r.route,
            userBudgetTL: model.totalBudgetTL.round(),
            upgradeWarning: r.upgradeWarning,
          ),
        )
        .toList();

    final offers = _sortOffers(
      planOffers,
      sortByCheapest: model.sortByCheapest,
    );

    return BudgetSearchOutcome(
      offers: offers,
      bannerMessage: filtered.bannerMessage,
      liveEnrichedCount: 0,
    );
  }

  static Future<BudgetPackageOffer> _enrichRoute({
    required SearchModel model,
    required RouteResultModel route,
    String? upgradeWarning,
  }) async {
    final budgetTL = model.totalBudgetTL.round();
    final planTL = PlanPriceAnchor.planPackageTL(route);

    if (route.destinationIata.isEmpty) {
      return BudgetPackageOffer.fromPlan(
        route: route,
        userBudgetTL: budgetTL,
        upgradeWarning: upgradeWarning,
      );
    }

    final travelers = model.passengers + model.children;

    try {
      final results = await Future.wait([
        ApiService.searchRealFlights(
          originIata: model.originIata,
          destinationIata: route.destinationIata,
          departureDate: model.departureDate,
          returnDate: model.returnDate,
          passengers: travelers,
        ),
        ApiService.searchHotels(
          cityName: route.cityName,
          checkIn: model.departureDate,
          returnDate: model.returnDate,
          adults: travelers,
          destinationIata: route.destinationIata,
          planHotel: route.hotel,
          nights: route.nights,
          targetPerNightTL: RouteDisplayPricing.hotelPerNightTL(route),
        ),
      ]).timeout(_liveTimeout);

      final flights = LiveOfferMatcher.sortFlightsForDisplay(
        List<Map<String, dynamic>>.from(results[0]),
      );
      final hotels = List<Map<String, dynamic>>.from(results[1]);

      final verifiedFlights = flights
          .where(PriceFormat.hasRoundTripFlightPrice)
          .toList();

      if (verifiedFlights.isEmpty || hotels.isEmpty) {
        return BudgetPackageOffer.fromPlan(
          route: route,
          userBudgetTL: budgetTL,
          upgradeWarning: upgradeWarning,
        );
      }

      final selection = SmartPackageOptimizer.optimize(
        flights: verifiedFlights,
        hotels: hotels,
        route: route,
        preferCheapest: model.sortByCheapest,
        holidayTypes: model.holidayTypes,
      );

      final flightIndex =
          selection.flightIndex.clamp(0, verifiedFlights.length - 1);
      final hotelIndex = selection.hotelIndex.clamp(0, hotels.length - 1);

      final liveTL = selection.totalTL > 0
          ? selection.totalTL
          : PriceFormat.packagePayableTL(
              flightTL: PriceFormat.roundTripFlightTL(verifiedFlights[flightIndex]),
              hotelTL: PriceFormat.hotelTotalTL(hotels[hotelIndex], route.nights),
              transferTL: route.estimatedCost.transfer,
            );

      return BudgetPackageOffer(
        route: route,
        userBudgetTL: budgetTL,
        planPackageTL: planTL,
        liveFlights: verifiedFlights,
        liveHotels: hotels,
        flightsFromLive: true,
        hotelsFromLive: true,
        liveFlightIndex: flightIndex,
        liveHotelIndex: hotelIndex,
        livePackageTL: liveTL,
        upgradeWarning: upgradeWarning,
        smartPackageSavingsTL:
            selection.savingsTL > 0 ? selection.savingsTL : null,
        isSmartOptimized: selection.isOptimized,
      );
    } catch (_) {
      return BudgetPackageOffer.fromPlan(
        route: route,
        userBudgetTL: budgetTL,
        upgradeWarning: upgradeWarning,
      );
    }
  }

  static List<BudgetPackageOffer> _sortOffers(
    List<BudgetPackageOffer> offers, {
    required bool sortByCheapest,
  }) {
    final list = offers.toList();
    list.sort((a, b) {
      final fit = _fitRank(a.fitKind).compareTo(_fitRank(b.fitKind));
      if (fit != 0) return fit;

      if (sortByCheapest) {
        final price = a.displayTotalTL.compareTo(b.displayTotalTL);
        if (price != 0) return price;
      }

      final afford = (b.route.isAffordable ? 1 : 0) - (a.route.isAffordable ? 1 : 0);
      if (afford != 0) return afford;

      return b.route.score.compareTo(a.route.score);
    });
    return list;
  }

  static int _fitRank(BudgetFitKind kind) {
    switch (kind) {
      case BudgetFitKind.unscoped:
        return 1;
      case BudgetFitKind.liveWithinBudget:
        return 0;
      case BudgetFitKind.planWithinBudget:
        return 1;
      case BudgetFitKind.planOnly:
        return 2;
      case BudgetFitKind.overBudget:
        return 3;
    }
  }

  static String? _composeBanner({
    required String? filterBanner,
    required List<BudgetPackageOffer> offers,
    required int budgetTL,
  }) {
    final parts = <String>[];
    if (filterBanner != null && filterBanner.isNotEmpty) {
      parts.add(filterBanner);
    }

    if (budgetTL < BudgetPackageOffer.minUserBudgetTL) {
      if (parts.isEmpty) return null;
      return parts.join(' ');
    }

    final liveWithin =
        offers.where((o) => o.fitKind == BudgetFitKind.liveWithinBudget).length;
    final liveCount = offers.where((o) => o.hasLivePackage).length;

    if (liveCount > 0 && liveWithin == 0) {
      parts.add(ConsumerCopy.orchestratorLiveHigher(budgetTL));
    } else if (liveWithin > 0) {
      parts.add(ConsumerCopy.orchestratorLiveWithin(liveWithin));
    }

    if (parts.isEmpty) return null;
    return parts.join(' ');
  }
}
