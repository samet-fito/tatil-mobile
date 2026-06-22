import '../data/destination_interest_pois.dart';
import '../models/route_result_model.dart';
import '../utils/plan_price_anchor.dart';
import 'price_format.dart';

/// Plan rotası ile canlı uçuş+otel kombinasyonunu eşleştirir.
class LivePackageSelection {
  const LivePackageSelection({
    required this.flightIndex,
    required this.hotelIndex,
  });

  final int flightIndex;
  final int hotelIndex;
}

/// Plan rotasındaki otel/uçuş ile canlı API sonuçlarını eşleştirir.
class LiveOfferMatcher {
  LiveOfferMatcher._();

  static const _lowTierKeywords = [
    'student',
    'hostel',
    'dormitory',
    'dorm',
    'shared room',
    'öğrenci',
    'yurt',
  ];

  /// Plan gecelik fiyatının üst sınırı — otomatik seçim için.
  static const _maxAutoSelectRatio = 1.45;

  /// Uçuş + otel: plan eşleşmesi veya en ucuz kombinasyon.
  static LivePackageSelection bestPackageSelection({
    required List<Map<String, dynamic>> flights,
    required List<Map<String, dynamic>> hotels,
    required RouteResultModel route,
    bool preferCheapest = false,
    List<String> holidayTypes = const [],
  }) {
    if (flights.isEmpty && hotels.isEmpty) {
      return const LivePackageSelection(flightIndex: 0, hotelIndex: 0);
    }

    final hotelIndex = hotels.isEmpty
        ? 0
        : bestHotelIndex(
            hotels: hotels,
            planHotel: route.hotel,
            nights: route.nights,
            targetPerNightTL: PlanPriceAnchor.targetHotelPerNightTL(route),
            preferCheapest: preferCheapest,
            holidayTypes: holidayTypes,
            destinationIata: route.destinationIata,
            cityName: route.cityName,
          );

    final flightIndex = flights.isEmpty
        ? 0
        : bestFlightIndex(
            flights: flights,
            planFlight: route.flight,
            preferCheapest: preferCheapest,
          );

    return LivePackageSelection(
      flightIndex: flightIndex,
      hotelIndex: hotelIndex,
    );
  }

  static int bestHotelIndex({
    required List<Map<String, dynamic>> hotels,
    RouteHotelModel? planHotel,
    required int nights,
    int? targetPerNightTL,
    bool preferCheapest = false,
    List<String> holidayTypes = const [],
    String? destinationIata,
    String? cityName,
  }) {
    if (hotels.isEmpty) return 0;
    if (preferCheapest) {
      return _interestAwarePick(
        hotels,
        nights,
        baseIndex: _cheapestHotelIndex(hotels, nights),
        holidayTypes: holidayTypes,
        destinationIata: destinationIata,
        cityName: cityName,
      );
    }
    if (planHotel == null) {
      return _interestAwarePick(
        hotels,
        nights,
        baseIndex: _cheapestHotelIndex(hotels, nights),
        holidayTypes: holidayTypes,
        destinationIata: destinationIata,
        cityName: cityName,
      );
    }

    final planName = _normalize(planHotel.name);
    final target = targetPerNightTL ?? planHotel.pricePerNight.round();

    for (var i = 0; i < hotels.length; i++) {
      if (hotels[i]['source'] == 'route') continue;
      final liveName = _normalize(hotels[i]['name'] as String? ?? '');
      if (_namesMatch(planName, liveName) && !_isLowTierHotel(hotels[i], planHotel)) {
        return i;
      }
    }

    final viable = <int>[];
    for (var i = 0; i < hotels.length; i++) {
      if (!_isLowTierHotel(hotels[i], planHotel)) viable.add(i);
    }
    if (viable.isEmpty) viable.add(0);

    final withinBand = viable.where((i) {
      if (target <= 0) return true;
      final perNight = PriceFormat.hotelPerNightTL(hotels[i]);
      if (perNight <= 0) return false;
      return perNight / target <= _maxAutoSelectRatio;
    }).toList();

    final pool = withinBand.isNotEmpty ? withinBand : viable;
    final picked = _closestPriceIndex(hotels, pool, target, planName);
    return _interestAwarePick(
      hotels,
      nights,
      baseIndex: picked,
      holidayTypes: holidayTypes,
      destinationIata: destinationIata,
      cityName: cityName,
      candidatePool: pool,
    );
  }

  /// Tatil türüne uygun konumdaki otelleri aynı fiyat bandında öne al.
  static int _interestAwarePick(
    List<Map<String, dynamic>> hotels,
    int nights, {
    required int baseIndex,
    List<String> holidayTypes = const [],
    String? destinationIata,
    String? cityName,
    List<int>? candidatePool,
  }) {
    if (holidayTypes.isEmpty ||
        destinationIata == null ||
        destinationIata.isEmpty ||
        cityName == null) {
      return baseIndex;
    }

    final pool = candidatePool ??
        List<int>.generate(hotels.length, (i) => i);
    if (pool.isEmpty) return baseIndex;

    final basePrice = PriceFormat.hotelTotalTL(hotels[baseIndex], nights);
    final band = basePrice <= 0
        ? pool
        : pool.where((i) {
            final price = PriceFormat.hotelTotalTL(hotels[i], nights);
            if (price <= 0) return false;
            return price <= basePrice * 1.12;
          }).toList();
    final candidates = band.isNotEmpty ? band : pool;

    var best = baseIndex;
    var bestScore = DestinationInterestPois.hotelInterestScore(
      hotels[best],
      cityName,
      destinationIata,
      holidayTypes,
    );

    for (final i in candidates) {
      final score = DestinationInterestPois.hotelInterestScore(
        hotels[i],
        cityName,
        destinationIata,
        holidayTypes,
      );
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  static Map<String, dynamic>? bestHotel({
    required List<Map<String, dynamic>> hotels,
    RouteHotelModel? planHotel,
    required int nights,
    int? targetPerNightTL,
  }) {
    if (hotels.isEmpty) return null;
    return hotels[bestHotelIndex(
      hotels: hotels,
      planHotel: planHotel,
      nights: nights,
      targetPerNightTL: targetPerNightTL,
    )];
  }

  static List<Map<String, dynamic>> sortHotelsByPlanMatch({
    required List<Map<String, dynamic>> hotels,
    RouteHotelModel? planHotel,
    required int nights,
    int? targetPerNightTL,
    List<String> holidayTypes = const [],
    String? destinationIata,
    String? cityName,
  }) {
    if (hotels.length <= 1 || planHotel == null) return hotels;
    final target = targetPerNightTL ?? planHotel.pricePerNight.round();
    final planName = _normalize(planHotel.name);
    final indexed = hotels.asMap().entries.toList();
    indexed.sort((a, b) {
      final scoreA = _hotelSortKey(
        a.value,
        a.key,
        planHotel,
        planName,
        target,
        holidayTypes: holidayTypes,
        destinationIata: destinationIata,
        cityName: cityName,
      );
      final scoreB = _hotelSortKey(
        b.value,
        b.key,
        planHotel,
        planName,
        target,
        holidayTypes: holidayTypes,
        destinationIata: destinationIata,
        cityName: cityName,
      );
      return scoreA.compareTo(scoreB);
    });
    return indexed.map((e) => e.value).toList();
  }

  static int bestFlightIndex({
    required List<Map<String, dynamic>> flights,
    RouteFlightModel? planFlight,
    int? planFlightTL,
    bool preferCheapest = false,
  }) {
    if (flights.isEmpty) return 0;

    final viable = <int>[];
    for (var i = 0; i < flights.length; i++) {
      if (flights[i]['source'] == 'route') continue;
      if (PriceFormat.roundTripFlightTL(flights[i]) > 0) viable.add(i);
    }
    if (viable.isEmpty) return 0;

    if (preferCheapest) {
      return _pickBestFlightIndex(flights, viable);
    }

    if (planFlight != null) {
      final planAirline = _normalize(planFlight.airline);
      if (planAirline.isNotEmpty && planAirline != '--') {
        final airlineMatches = viable.where((i) {
          final airline = _normalize(
            flights[i]['airline'] as String? ??
                flights[i]['carrier'] as String? ??
                '',
          );
          return airline.isNotEmpty &&
              (airline.contains(planAirline) || planAirline.contains(airline));
        }).toList();
        if (airlineMatches.isNotEmpty) {
          return _pickBestFlightIndex(flights, airlineMatches);
        }
      }
    }

    return _pickBestFlightIndex(flights, viable);
  }

  /// Direkt uçuşları tercih eder; eşitlikte en ucuz.
  static int _pickBestFlightIndex(
    List<Map<String, dynamic>> flights,
    List<int> pool,
  ) {
    if (pool.isEmpty) return 0;

    final direct = pool.where((i) => _flightStopCount(flights[i]) == 0).toList();
    final candidates = direct.isNotEmpty ? direct : pool;

    var bestIndex = candidates.first;
    var bestPrice = PriceFormat.roundTripFlightTL(flights[bestIndex]);

    for (final i in candidates.skip(1)) {
      final price = PriceFormat.roundTripFlightTL(flights[i]);
      if (price <= 0) continue;

      final stops = _flightStopCount(flights[i]);
      final bestStops = _flightStopCount(flights[bestIndex]);

      if (price < bestPrice || (price == bestPrice && stops < bestStops)) {
        bestIndex = i;
        bestPrice = price;
      }
    }
    return bestIndex;
  }

  static int _flightStopCount(Map<String, dynamic> flight) {
    final stops = flight['stops'];
    if (stops is num) return stops.round().clamp(0, 9);
    return 0;
  }

  static Map<String, dynamic>? bestFlight({
    required List<Map<String, dynamic>> flights,
    RouteFlightModel? planFlight,
    int? planFlightTL,
  }) {
    if (flights.isEmpty) return null;
    return flights[bestFlightIndex(
      flights: flights,
      planFlight: planFlight,
      planFlightTL: planFlightTL,
    )];
  }

  /// Picker sıralaması — ucuz modda toplam gece fiyatına göre.
  static List<int> sortedHotelIndices({
    required List<Map<String, dynamic>> hotels,
    required int nights,
    RouteHotelModel? planHotel,
    int? targetPerNightTL,
    bool preferCheapest = false,
  }) {
    final indices = List<int>.generate(hotels.length, (i) => i);
    indices.sort((a, b) {
      if (preferCheapest) {
        return PriceFormat.hotelTotalTL(hotels[a], nights)
            .compareTo(PriceFormat.hotelTotalTL(hotels[b], nights));
      }
      if (planHotel == null) {
        return PriceFormat.hotelTotalTL(hotels[a], nights)
            .compareTo(PriceFormat.hotelTotalTL(hotels[b], nights));
      }
      final target = targetPerNightTL ?? planHotel.pricePerNight.round();
      final planName = _normalize(planHotel.name);
      final keyA = _hotelSortKey(hotels[a], a, planHotel, planName, target);
      final keyB = _hotelSortKey(hotels[b], b, planHotel, planName, target);
      return keyA.compareTo(keyB);
    });
    return indices;
  }

  /// Liste gösterimi: direkt uçuşlar önce, en ucuz üstte.
  static List<int> sortedFlightIndices(List<Map<String, dynamic>> flights) {
    if (flights.length <= 1) return [0];
    final indices = List<int>.generate(flights.length, (i) => i);
    indices.sort((a, b) {
      final stopsA = _flightStopCount(flights[a]);
      final stopsB = _flightStopCount(flights[b]);
      if (stopsA != stopsB) return stopsA.compareTo(stopsB);
      return PriceFormat.roundTripFlightTL(flights[a])
          .compareTo(PriceFormat.roundTripFlightTL(flights[b]));
    });
    return indices;
  }

  static List<Map<String, dynamic>> sortFlightsForDisplay(
    List<Map<String, dynamic>> flights,
  ) {
    if (flights.length <= 1) return flights;
    final indexed = flights.asMap().entries.toList();
    indexed.sort((a, b) {
      final stopsA = _flightStopCount(a.value);
      final stopsB = _flightStopCount(b.value);
      if (stopsA != stopsB) return stopsA.compareTo(stopsB);
      return PriceFormat.roundTripFlightTL(a.value)
          .compareTo(PriceFormat.roundTripFlightTL(b.value));
    });
    return indexed.map((e) => e.value).toList();
  }

  static int _closestPriceIndex(
    List<Map<String, dynamic>> hotels,
    List<int> pool,
    int targetPerNight,
    String planName,
  ) {
    var bestIndex = pool.first;
    var bestKey = double.infinity;

    for (final i in pool) {
      final perNight = PriceFormat.hotelPerNightTL(hotels[i]);
      if (perNight <= 0) continue;

      final priceDistance = targetPerNight > 0
          ? (perNight - targetPerNight).abs() / targetPerNight
          : perNight.toDouble();

      final liveName = _normalize(hotels[i]['name'] as String? ?? '');
      final nameBonus = _tokenOverlap(planName, liveName) * 0.08;
      final key = priceDistance - nameBonus;

      if (key < bestKey) {
        bestKey = key;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  static double _hotelSortKey(
    Map<String, dynamic> hotel,
    int index,
    RouteHotelModel plan,
    String planName,
    int targetPerNight, {
    List<String> holidayTypes = const [],
    String? destinationIata,
    String? cityName,
  }) {
    if (_isLowTierHotel(hotel, plan)) return double.infinity;
    final perNight = PriceFormat.hotelPerNightTL(hotel);
    if (perNight <= 0) return double.infinity;

    final priceDistance = targetPerNight > 0
        ? (perNight - targetPerNight).abs() / targetPerNight
        : perNight.toDouble();

    final liveName = _normalize(hotel['name'] as String? ?? '');
    final nameBonus = _namesMatch(planName, liveName) ? -0.15 : 0.0;

    var interestBonus = 0.0;
    if (holidayTypes.isNotEmpty &&
        destinationIata != null &&
        destinationIata.isNotEmpty &&
        cityName != null) {
      interestBonus = DestinationInterestPois.hotelInterestScore(
            hotel,
            cityName,
            destinationIata,
            holidayTypes,
          ) *
          -0.12;
    }

    return priceDistance + nameBonus + interestBonus;
  }

  static int _cheapestHotelIndex(List<Map<String, dynamic>> hotels, int nights) {
    var best = 0;
    var bestPrice = PriceFormat.hotelTotalTL(hotels[0], nights);
    for (var i = 1; i < hotels.length; i++) {
      final price = PriceFormat.hotelTotalTL(hotels[i], nights);
      if (price < bestPrice) {
        bestPrice = price;
        best = i;
      }
    }
    return best;
  }

  static int _cheapestFlightIndex(List<Map<String, dynamic>> flights) {
    var best = 0;
    var bestPrice = PriceFormat.roundTripFlightTL(flights[0]);
    for (var i = 1; i < flights.length; i++) {
      final price = PriceFormat.roundTripFlightTL(flights[i]);
      if (price < bestPrice) {
        bestPrice = price;
        best = i;
      }
    }
    return best;
  }

  static bool _isLowTierHotel(
    Map<String, dynamic> hotel,
    RouteHotelModel plan,
  ) {
    if (plan.starRating < 4 && plan.reviewScore < 8) return false;
    final liveName = _normalize(hotel['name'] as String? ?? '');
    return _lowTierKeywords.any(liveName.contains);
  }

  static bool _namesMatch(String planName, String liveName) {
    if (planName.isEmpty || liveName.isEmpty) return false;
    if (liveName.contains(planName) || planName.contains(liveName)) return true;

    final planTokens = _tokens(planName).where((t) => t.length > 2).toSet();
    final liveTokens = _tokens(liveName).where((t) => t.length > 2).toSet();
    if (planTokens.isEmpty || liveTokens.isEmpty) return false;

    final overlap = planTokens.intersection(liveTokens);
    return overlap.length >= 2 ||
        (overlap.isNotEmpty && overlap.length / planTokens.length >= 0.5);
  }

  static double _tokenOverlap(String a, String b) {
    final ta = _tokens(a).where((t) => t.length > 2).toSet();
    final tb = _tokens(b).where((t) => t.length > 2).toSet();
    if (ta.isEmpty || tb.isEmpty) return 0;
    return ta.intersection(tb).length / ta.length;
  }

  static Set<String> _tokens(String value) {
    return value
        .split(RegExp(r'[^a-z0-9]+'))
        .where((part) => part.isNotEmpty)
        .toSet();
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
