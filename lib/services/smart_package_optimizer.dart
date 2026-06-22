import '../models/route_result_model.dart';
import '../utils/live_offer_matcher.dart';
import '../utils/price_format.dart';

/// Akıllı paket v2 — uçuş × otel kombinasyonlarında en iyi fiyat/kalite dengesi.
class SmartPackageResult {
  const SmartPackageResult({
    required this.flightIndex,
    required this.hotelIndex,
    required this.totalTL,
    this.savingsTL = 0,
    this.isOptimized = false,
    this.insight = '',
  });

  final int flightIndex;
  final int hotelIndex;
  final int totalTL;
  final int savingsTL;
  final bool isOptimized;
  final String insight;
}

abstract final class SmartPackageOptimizer {
  static const _maxCandidates = 5;

  static SmartPackageResult optimize({
    required List<Map<String, dynamic>> flights,
    required List<Map<String, dynamic>> hotels,
    required RouteResultModel route,
    bool preferCheapest = false,
    List<String> holidayTypes = const [],
  }) {
    if (flights.isEmpty || hotels.isEmpty) {
      return const SmartPackageResult(
        flightIndex: 0,
        hotelIndex: 0,
        totalTL: 0,
      );
    }

    final baseline = LiveOfferMatcher.bestPackageSelection(
      flights: flights,
      hotels: hotels,
      route: route,
      preferCheapest: preferCheapest,
      holidayTypes: holidayTypes,
    );

    final baseFlightIdx =
        baseline.flightIndex.clamp(0, flights.length - 1);
    final baseHotelIdx = baseline.hotelIndex.clamp(0, hotels.length - 1);
    final baselineTL = _packageTL(
      flights[baseFlightIdx],
      hotels[baseHotelIdx],
      route,
    );

    final flightIndices = _topFlightIndices(flights, preferCheapest);
    final hotelIndices = _topHotelIndices(
      hotels,
      route,
      preferCheapest,
      holidayTypes,
    );

    var bestFlight = baseFlightIdx;
    var bestHotel = baseHotelIdx;
    var bestTL = baselineTL;
    var bestScore = -999999999;
    String insight = '';

    for (final fi in flightIndices) {
      for (final hi in hotelIndices) {
        final total = _packageTL(flights[fi], hotels[hi], route);
        final score = _scoreCombo(
          totalTL: total,
          flight: flights[fi],
          hotel: hotels[hi],
          preferCheapest: preferCheapest,
        );
        if (score > bestScore) {
          bestScore = score;
          bestFlight = fi;
          bestHotel = hi;
          bestTL = total;
        }
      }
    }

    final savings = baselineTL > bestTL ? baselineTL - bestTL : 0;
    final optimized = savings >= 500 ||
        (bestFlight != baseFlightIdx || bestHotel != baseHotelIdx);

    if (optimized) {
      if (savings >= 500) {
        insight = 'Standart seçime göre yaklaşık $savings TL tasarruf';
      } else {
        insight = 'Daha iyi otel/uçuş dengesi için önerildi';
      }
    }

    return SmartPackageResult(
      flightIndex: bestFlight,
      hotelIndex: bestHotel,
      totalTL: bestTL,
      savingsTL: savings,
      isOptimized: optimized,
      insight: insight,
    );
  }

  static int _packageTL(
    Map<String, dynamic> flight,
    Map<String, dynamic> hotel,
    RouteResultModel route,
  ) {
    return PriceFormat.packagePayableTL(
      flightTL: PriceFormat.roundTripFlightTL(flight),
      hotelTL: PriceFormat.hotelTotalTL(hotel, route.nights),
      transferTL: route.estimatedCost.transfer,
    );
  }

  static List<int> _topFlightIndices(
    List<Map<String, dynamic>> flights,
    bool preferCheapest,
  ) {
    final indices = List<int>.generate(flights.length, (i) => i);
    indices.sort((a, b) {
      final pa = PriceFormat.roundTripFlightTL(flights[a]);
      final pb = PriceFormat.roundTripFlightTL(flights[b]);
      return preferCheapest ? pa.compareTo(pb) : pb.compareTo(pa);
    });
    return indices.take(_maxCandidates).toList();
  }

  static List<int> _topHotelIndices(
    List<Map<String, dynamic>> hotels,
    RouteResultModel route,
    bool preferCheapest,
    List<String> holidayTypes,
  ) {
    final indices = List<int>.generate(hotels.length, (i) => i);
    indices.sort((a, b) {
      if (preferCheapest) {
        final pa = PriceFormat.hotelTotalTL(hotels[a], route.nights);
        final pb = PriceFormat.hotelTotalTL(hotels[b], route.nights);
        return pa.compareTo(pb);
      }
      final sa = LiveOfferMatcher.bestHotelIndex(
        hotels: hotels,
        planHotel: route.hotel,
        nights: route.nights,
        holidayTypes: holidayTypes,
        destinationIata: route.destinationIata,
        cityName: route.cityName,
      );
      // Re-rank by distance from best hotel index heuristic
      return (a == sa ? 0 : 1).compareTo(b == sa ? 0 : 1);
    });
    return indices.take(_maxCandidates).toList();
  }

  static int _scoreCombo({
    required int totalTL,
    required Map<String, dynamic> flight,
    required Map<String, dynamic> hotel,
    required bool preferCheapest,
  }) {
    final stops = (flight['stops'] as num?)?.toInt() ?? 0;
    final rating = (hotel['reviewScore'] as num?)?.toDouble() ?? 7.0;
    final priceWeight = preferCheapest ? 2.0 : 1.2;
    return (-totalTL * priceWeight).round() +
        (rating * 800).round() -
        (stops * 400);
  }
}
