import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../data/bundled_destinations.dart';
import '../data/commission_activities.dart';
import '../models/route_result_model.dart';
import '../models/route_search_outcome.dart';
import '../models/search_model.dart';
import '../models/flight_leg.dart';
import '../models/multi_city_search_result.dart';
import '../utils/price_format.dart';
import '../utils/spending_estimate_builder.dart';
import '../models/spending_estimate_model.dart';
import '../utils/spending_estimate_normalizer.dart';
import '../utils/live_fx_rate.dart';
import '../utils/city_search_names.dart';
import '../utils/live_offer_matcher.dart';
import '../utils/flight_schedule_format.dart';
import 'route_search_service.dart';

class ApiService {
  // ============================================================
  // BAĞLANTI
  // ============================================================
  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse(AppConstants.healthEndpoint))
          .timeout(AppConstants.connectTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // ARAMA (Gateway — gerçek rota motoru)
  // ============================================================
  static Future<Map<String, dynamic>> _gatewaySearch(SearchModel model) async {
    try {
      final body = _gatewaySearchBody(model);

      final response = await http
          .post(
            Uri.parse(AppConstants.pythonSearchEndpoint),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(AppConstants.livePriceTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) return decoded;
        return {
          'success': false,
          'error': decoded['error'] ??
              {
                'message': 'Arama sunucusu geçerli sonuç döndürmedi.',
              },
        };
      }

      final isWakeUp = response.statusCode == 503 ||
          response.statusCode == 502 ||
          response.statusCode == 504;

      if (response.statusCode == 429) {
        String? serverMsg;
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final err = decoded['error'];
          if (err is Map) serverMsg = err['message']?.toString();
        } catch (_) {}
        return {
          'success': false,
          'error': {
            'code': 'RATE_LIMIT_EXCEEDED',
            'message': serverMsg ??
                'Çok fazla istek gönderildi. Bir dakika bekleyip tekrar deneyin.',
          },
        };
      }

      return {
        'success': false,
        'error': {
          'code': isWakeUp ? 'SERVICE_UNAVAILABLE' : 'HTTP_${response.statusCode}',
          'message': isWakeUp
              ? 'Arama sunucusu uyanıyor. Birkaç saniye sonra tekrar denenecek.'
              : 'Arama sunucusu yanıt vermedi (${response.statusCode}).',
        },
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': {'message': 'Sunucu zaman aşımına uğradı.', 'code': 'TIMEOUT'},
      };
    } catch (e) {
      return _connectionError(e);
    }
  }

  static Map<String, dynamic> _gatewaySearchBody(SearchModel model) {
    final body = <String, dynamic>{
      'originIata': model.originIata,
      'departureDate': _formatSearchDate(model.departureDate),
      'returnDate': _formatSearchDate(model.returnDate),
      'totalBudgetTL': model.gatewayBudgetTL,
      'passengers': model.passengers,
    };

    void putOptional(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is List && value.isEmpty) return;
      body[key] = value;
    }

    if (model.children > 0) putOptional('children', model.children);
    putOptional('continent', model.continent);
    putOptional('holidayType', model.holidayType);
    putOptional('holidayTypes', model.holidayTypes);
    putOptional('destinationIata', model.destinationIata);
    putOptional('destinationCountry', model.destinationCountry);

    return body;
  }

  static String _formatSearchDate(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.toIso8601String().split('T')[0];
  }

  static List<dynamic> _extractPackages(dynamic inner) {
    if (inner is List) return inner;
    if (inner is Map) {
      final packages = inner['packages'];
      if (packages is List) return packages;
    }
    return const [];
  }

  static RouteSearchOutcome _parseGatewayResult(Map<String, dynamic> result) {
    if (result['success'] != true) {
      final err = result['error'];
      final message = err is Map ? err['message'] as String? : null;
      final code = err is Map ? err['code'] as String? : null;
      final detail = err is Map ? err['detail'] as String? : null;
      final failure = code == 'TIMEOUT'
          ? RouteSearchFailure.timeout
          : code == 'RATE_LIMIT_EXCEEDED'
              ? RouteSearchFailure.rateLimited
              : code == 'SERVICE_UNAVAILABLE'
                  ? RouteSearchFailure.serverError
                  : _connectionFailureFrom(message, detail);
      return RouteSearchOutcome(
        routes: const [],
        failure: failure,
        message: message,
      );
    }

    final list = _extractPackages(result['data']);
    final routes = <RouteResultModel>[];
    var parseFailures = 0;

    for (final item in list) {
      if (item is! Map) continue;
      try {
        routes.add(RouteResultModel.fromJson(Map<String, dynamic>.from(item)));
      } catch (e, st) {
        parseFailures++;
        debugPrint('Route parse failed: $e\n$st');
      }
    }

    if (routes.isNotEmpty) {
      return RouteSearchOutcome(
        routes: routes,
        rawPackageCount: list.length,
        parseFailures: parseFailures,
      );
    }

    if (list.isNotEmpty && parseFailures > 0) {
      return RouteSearchOutcome(
        routes: const [],
        failure: RouteSearchFailure.parseError,
        rawPackageCount: list.length,
        parseFailures: parseFailures,
      );
    }

    return RouteSearchOutcome(
      routes: const [],
      failure: RouteSearchFailure.emptyPackages,
      rawPackageCount: list.length,
    );
  }

  static Future<void> _warmGateway() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await http
            .get(Uri.parse(AppConstants.gatewayHealthEndpoint))
            .timeout(const Duration(seconds: 12));
        if (response.statusCode == 200) return;
        if (response.statusCode == 503 ||
            response.statusCode == 502 ||
            response.statusCode == 504) {
          await Future.delayed(Duration(seconds: 2 + attempt * 2));
          continue;
        }
        return;
      } catch (_) {
        if (attempt < 2) {
          await Future.delayed(Duration(seconds: 2 + attempt * 2));
        }
      }
    }
  }

  static Future<void> warmGateway() async {
    await _warmGateway();
    unawaited(warmCatalogProviders());
  }

  /// Otobüs ve araç kiralama gateway uçlarını ısıtır.
  static Future<void> warmCatalogProviders() async {
    final now = DateTime.now();
    final date = now.toIso8601String().split('T')[0];
    final pickup = date;
    final dropoff =
        now.add(const Duration(days: 3)).toIso8601String().split('T')[0];

    await Future.wait([
      _pingCatalogEndpoint(
        AppConstants.busSearchEndpoint,
        {
          'from': 'İstanbul',
          'to': 'Ankara',
          'date': date,
          'passengers': '1',
        },
      ),
      _pingCatalogEndpoint(
        AppConstants.carRentalSearchEndpoint,
        {
          'city': 'Antalya',
          'pickup': pickup,
          'dropoff': dropoff,
        },
      ),
    ]);
  }

  static Future<void> _pingCatalogEndpoint(
    String endpoint,
    Map<String, String> query,
  ) async {
    try {
      final uri = Uri.parse(endpoint).replace(queryParameters: query);
      await http.get(uri).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Sessiz ısınma — arama sırasında yedek katalog devreye girer.
    }
  }

  static Future<RouteSearchOutcome> searchRoutesOutcomeForModel(
    SearchModel model,
  ) async {
    final result = await _gatewaySearch(model);
    return _parseGatewayResult(result);
  }

  static Future<RouteSearchOutcome> searchRoutesOutcome({
    required String originIata,
    required DateTime departureDate,
    required DateTime returnDate,
    required double totalBudgetTL,
    required int passengers,
    int children = 0,
    String? continent,
    String? holidayType,
    String? destinationIata,
    String? destinationCountry,
    List<String> holidayTypes = const [],
  }) async {
    final model = SearchModel(
      originIata: originIata,
      departureDate: departureDate,
      returnDate: returnDate,
      totalBudgetTL: totalBudgetTL,
      passengers: passengers,
      children: children,
      continent: continent,
      holidayType: holidayType,
      holidayTypes: holidayTypes,
      destinationIata: destinationIata,
      destinationCountry: destinationCountry,
    );
    return searchRoutesOutcomeForModel(model);
  }

  static Future<List<RouteResultModel>> searchRoutes({
    required String originIata,
    required DateTime departureDate,
    required DateTime returnDate,
    required double totalBudgetTL,
    required int passengers,
    int children = 0,
    String? continent,
    String? holidayType,
    String? destinationIata,
    String? destinationCountry,
    List<String> holidayTypes = const [],
  }) async {
    final outcome = await searchRoutesOutcome(
      originIata: originIata,
      departureDate: departureDate,
      returnDate: returnDate,
      totalBudgetTL: totalBudgetTL,
      passengers: passengers,
      children: children,
      continent: continent,
      holidayType: holidayType,
      destinationIata: destinationIata,
      destinationCountry: destinationCountry,
      holidayTypes: holidayTypes,
    );
    return outcome.routes;
  }

  /// Gateway araması — [RouteSearchService] üzerinden önbellek + retry.
  static Future<RouteSearchOutcome> searchRoutesWithRetry({
    required String originIata,
    required DateTime departureDate,
    required DateTime returnDate,
    required double totalBudgetTL,
    required int passengers,
    int children = 0,
    String? continent,
    String? holidayType,
    String? destinationIata,
    String? destinationCountry,
    List<String> holidayTypes = const [],
  }) {
    final model = SearchModel(
      originIata: originIata,
      departureDate: departureDate,
      returnDate: returnDate,
      totalBudgetTL: totalBudgetTL,
      passengers: passengers,
      children: children,
      continent: continent,
      holidayType: holidayType,
      holidayTypes: holidayTypes,
      destinationIata: destinationIata,
      destinationCountry: destinationCountry,
    );
    return RouteSearchService.search(model);
  }

  // ============================================================
  // DESTİNASYONLAR
  // ============================================================
  static Future<List<Map<String, dynamic>>> getDestinations() async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http
            .get(Uri.parse(AppConstants.destinationsEndpoint))
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success'] == true) {
            final list =
                List<Map<String, dynamic>>.from(data['data'] ?? []);
            if (list.isNotEmpty) return list;
          }
        }
      } catch (_) {
        if (attempt == 0) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    return List<Map<String, dynamic>>.from(BundledDestinations.raw);
  }

  static Future<Map<String, dynamic>?> getDestinationMeta(String iata) async {
    final list = await getDestinations();
    final code = iata.toUpperCase();
    for (final d in list) {
      if ((d['iataCode'] as String? ?? '').toUpperCase() == code) {
        return d;
      }
    }
    return null;
  }

  // ============================================================
  // AKTİVİTELER
  // ============================================================
  static Future<Map<String, dynamic>> getActivities({
    required String iata,
    required String city,
    required String departure,
    required String returnDate,
  }) async {
    try {
      final uri = Uri.parse(AppConstants.activitiesEndpoint).replace(
        queryParameters: {
          'iata': iata,
          'city': city,
          'departure': departure,
          'return': returnDate,
        },
      );
      final response =
          await http.get(uri).timeout(AppConstants.receiveTimeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'success': false};
    } catch (e) {
      return _connectionError(e);
    }
  }

  static Future<Map<String, dynamic>> getCommissionActivities({
    required String iata,
    required String cityName,
    required String departure,
    required String returnDate,
  }) async {
    final result = await getActivities(
      iata: iata,
      city: cityName,
      departure: departure,
      returnDate: returnDate,
    );
    if (result['success'] == true && result['data'] != null) {
      try {
        return {
          'success': true,
          'data': CommissionActivities.fromApiActivities(
            Map<String, dynamic>.from(result['data'] as Map),
            iata,
            cityName,
            tripStart: DateTime.tryParse(departure),
            tripEnd: DateTime.tryParse(returnDate),
          ),
        };
      } catch (e) {
        return {
          'success': false,
          'error': {'message': e.toString()},
        };
      }
    }
    return {
      'success': false,
      'error': {'message': 'Aktiviteler yüklenemedi.'},
    };
  }

  // ============================================================
  // OTOBÜS
  // ============================================================
  static Future<List<Map<String, dynamic>>> searchBusTrips({
    required String fromCity,
    required String toCity,
    required String date,
    required int passengers,
  }) async {
    try {
      final uri = Uri.parse(AppConstants.busSearchEndpoint).replace(
        queryParameters: {
          'from': fromCity,
          'to': toCity,
          'date': date,
          'passengers': '$passengers',
        },
      );
      final response =
          await http.get(uri).timeout(AppConstants.receiveTimeout);
      if (response.statusCode != 200) return [];
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) return [];
      final data = body['data'];
      if (data is! Map) return [];
      final trips = data['trips'];
      if (trips is! List) return [];
      return trips
          .whereType<Map>()
          .map((t) => _normalizeBusTrip(Map<String, dynamic>.from(t)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Map<String, dynamic> _normalizeBusTrip(Map<String, dynamic> trip) {
    final dep = trip['departureTime'];
    DateTime departureTime;
    if (dep is DateTime) {
      departureTime = dep;
    } else if (dep is String) {
      departureTime = DateTime.tryParse(dep) ?? DateTime.now();
    } else {
      departureTime = DateTime.now();
    }
    return {
      ...trip,
      'departureTime': departureTime,
      'durationMinutes': (trip['durationMinutes'] as num?)?.toInt() ?? 0,
      'priceTL': (trip['priceTL'] as num?)?.toInt() ?? 0,
      'pricePerPersonTL': (trip['pricePerPersonTL'] as num?)?.toInt() ?? 0,
      'passengers': (trip['passengers'] as num?)?.toInt() ?? 1,
      'amenities': List<String>.from(trip['amenities'] ?? const []),
      'source': trip['source'] ?? 'api',
    };
  }

  // ============================================================
  // ARAÇ KİRALAMA
  // ============================================================
  static Future<List<Map<String, dynamic>>> searchCarRentals({
    required String city,
    required String pickup,
    required String dropoff,
  }) async {
    try {
      final uri = Uri.parse(AppConstants.carRentalSearchEndpoint).replace(
        queryParameters: {
          'city': city,
          'pickup': pickup,
          'dropoff': dropoff,
        },
      );
      final response =
          await http.get(uri).timeout(AppConstants.receiveTimeout);
      if (response.statusCode != 200) return [];
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) return [];
      final data = body['data'];
      if (data is! Map) return [];
      final vehicles = data['vehicles'];
      if (vehicles is! List) return [];
      return vehicles
          .whereType<Map>()
          .map((v) => _normalizeCarRental(Map<String, dynamic>.from(v)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Map<String, dynamic> _normalizeCarRental(Map<String, dynamic> car) {
    DateTime parseDt(dynamic raw, DateTime fallback) {
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw) ?? fallback;
      return fallback;
    }

    final pickup = parseDt(car['pickup'], DateTime.now());
    final dropoff = parseDt(car['dropoff'], pickup.add(const Duration(days: 1)));

    return {
      ...car,
      'pickup': pickup,
      'dropoff': dropoff,
      'days': (car['days'] as num?)?.toInt() ?? 1,
      'dailyPriceTL': (car['dailyPriceTL'] as num?)?.toInt() ?? 0,
      'totalPriceTL': (car['totalPriceTL'] as num?)?.toInt() ?? 0,
      'seats': (car['seats'] as num?)?.toInt() ?? 5,
      'bags': (car['bags'] as num?)?.toInt() ?? 2,
      'source': car['source'] ?? 'api',
    };
  }

  static List<Map<String, dynamic>> activityItemsFromResponse(
    Map<String, dynamic>? result,
  ) {
    if (result == null || result['success'] != true) return [];
    final data = result['data'];
    if (data is! Map) return [];
    final acts = data['activities'];
    if (acts is! Map) return [];
    final within = List<Map<String, dynamic>>.from(acts['withinTrip'] ?? []);
    final nearby = List<Map<String, dynamic>>.from(acts['nearby'] ?? []);
    return [...within, ...nearby];
  }

  // ============================================================
  // VİZE
  // ============================================================
  static Future<Map<String, dynamic>> getVisaInfo(String countryCode) async {
    try {
      final uri = Uri.parse(AppConstants.visaEndpoint)
          .replace(queryParameters: {'countryCode': countryCode});
      final response =
          await http.get(uri).timeout(AppConstants.connectTimeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'success': false};
    } catch (e) {
      return _connectionError(e);
    }
  }

  // ============================================================
  // CHAT
  // ============================================================
  static Future<Map<String, dynamic>> sendChat({
    required String sessionId,
    required String cityName,
    required String destinationIata,
    required String message,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.chatEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'sessionId': sessionId,
              'cityName': cityName,
              'destinationIata': destinationIata,
              'message': message,
            }),
          )
          .timeout(AppConstants.connectTimeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'success': false};
    } catch (e) {
      return _connectionError(e);
    }
  }

  // ============================================================
  // UÇUŞ & OTEL (Duffel / Booking.com)
  // ============================================================

  /// Takvim için tek istekte çoklu gün fiyat özeti (uçuş + otel TL).
  static Future<List<Map<String, dynamic>>> fetchCalendarQuotes({
    required String originIata,
    required String destinationIata,
    required String destinationCity,
    required List<DateTime> departureDates,
    required int nights,
    required int passengers,
  }) async {
    if (departureDates.isEmpty) return const [];

    final dates = departureDates
        .map((d) => d.toIso8601String().split('T')[0])
        .toList();

    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.calendarQuotesEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'originIata': originIata,
              'destinationIata': destinationIata,
              'destinationCity': destinationCity,
              'nights': nights,
              'passengers': passengers,
              'dates': dates,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 429) return const [];

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
    } catch (_) {}
    return const [];
  }

  static Future<List<Map<String, dynamic>>> searchRealFlights({
    required String originIata,
    required String destinationIata,
    required DateTime departureDate,
    required DateTime returnDate,
    required int passengers,
    bool isRoundTrip = true,
    String cabinClass = 'economy',
  }) async {
    final effectiveReturn =
        isRoundTrip ? returnDate : departureDate;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse('${AppConstants.baseUrl}/flights/search'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'originIata': originIata,
                'destinationIata': destinationIata,
                'departureDate': departureDate.toIso8601String().split('T')[0],
                'returnDate': effectiveReturn.toIso8601String().split('T')[0],
                'passengers': passengers,
                'isRoundTrip': isRoundTrip,
                'cabinClass': cabinClass,
              }),
            )
            .timeout(AppConstants.livePriceTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success'] == true) {
            final list = List<Map<String, dynamic>>.from(data['data'] ?? []);
            if (list.isNotEmpty) {
              LiveFxRate.updateFromFlights(list);
              final normalized = list.map((f) {
                final copy = Map<String, dynamic>.from(f);
                copy['source'] = 'live';
                final tl = f['totalAmountTL'];
                if (tl != null) {
                  copy['totalAmountTL'] = (tl as num).round();
                }
                return copy;
              }).toList();
              return _enrichFlightsReturnTimes(normalized);
            }
          }
        }
      } catch (_) {
        if (attempt == 0) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    return [];
  }

  /// Çoklu uçuş — her bacak için tek yön arama.
  static Future<MultiCitySearchResult> searchMultiCityFlights({
    required List<FlightLeg> legs,
    required int passengers,
    String cabinClass = 'economy',
  }) async {
    final results = <MultiCityLegResult>[];
    for (final leg in legs) {
      final flights = await searchRealFlights(
        originIata: leg.originIata,
        destinationIata: leg.destinationIata,
        departureDate: leg.departureDate,
        returnDate: leg.departureDate,
        passengers: passengers,
        isRoundTrip: false,
        cabinClass: cabinClass,
      );
      var cheapestIdx = 0;
      if (flights.length > 1) {
        var minP = 999999999;
        for (var i = 0; i < flights.length; i++) {
          final p = PriceFormat.flightTotalTL(flights[i], roundTrip: false);
          if (p < minP) {
            minP = p;
            cheapestIdx = i;
          }
        }
      }
      results.add(
        MultiCityLegResult(
          leg: leg,
          flights: flights,
          selectedFlightIndex: cheapestIdx,
        ),
      );
    }
    return MultiCitySearchResult(legs: results);
  }

  /// Duffel teklif detayı — dönüş saatleri eksikse tamamlar.
  static Future<Map<String, dynamic>?> fetchFlightOffer(String offerId) async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.baseUrl}/flights/offer/$offerId'))
          .timeout(AppConstants.connectTimeout);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true || data['data'] == null) return null;
      return Map<String, dynamic>.from(data['data'] as Map);
    } catch (_) {
      return null;
    }
  }

  static const _returnFlightKeys = [
    'returnDepartureTime',
    'returnArrivalTime',
    'returnDuration',
    'returnStops',
    'returnOriginIata',
    'returnDestinationIata',
  ];

  static Future<List<Map<String, dynamic>>> _enrichFlightsReturnTimes(
    List<Map<String, dynamic>> flights,
  ) async {
    final needsEnrich = flights.any((f) => !FlightScheduleFormat.hasReturnTimes(f));
    if (!needsEnrich) return flights;

    return Future.wait(
      flights.map((flight) async {
        if (FlightScheduleFormat.hasReturnTimes(flight)) return flight;
        final id = flight['id']?.toString();
        if (id == null || id.isEmpty) return flight;

        final detailed = await fetchFlightOffer(id);
        if (detailed == null) return flight;

        final merged = Map<String, dynamic>.from(flight);
        for (final key in _returnFlightKeys) {
          final value = detailed[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            merged[key] = value;
          }
        }
        return merged;
      }),
    );
  }

  static Future<List<Map<String, dynamic>>> searchHotels({
    required String cityName,
    required DateTime checkIn,
    required DateTime returnDate,
    required int adults,
    String? destinationIata,
    RouteHotelModel? planHotel,
    int nights = 1,
    int? targetPerNightTL,
  }) async {
    final checkInStr = checkIn.toIso8601String().split('T')[0];
    final checkOutStr = returnDate.toIso8601String().split('T')[0];
    final candidates = CitySearchNames.hotelSearchCandidates(
      cityName,
      destinationIata ?? '',
    );

    for (final searchCity in candidates) {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final response = await http.get(
            Uri.parse(
              '${AppConstants.baseUrl}/hotels-search/search?cityName=${Uri.encodeComponent(searchCity)}&checkIn=$checkInStr&checkOut=$checkOutStr&adults=$adults',
            ),
          ).timeout(AppConstants.livePriceTimeout);

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            if (data['success'] == true) {
              final hotels = List<Map<String, dynamic>>.from(data['data'] ?? []);
              if (hotels.isNotEmpty) {
                final normalized = hotels.map((h) {
                  final n = _normalizeHotel(h, nights: nights);
                  n['source'] = 'live';
                  return n;
                }).toList();
                final nearPlan = _filterHotelsNearPlan(
                  hotels: normalized,
                  targetPerNightTL: targetPerNightTL,
                );
                return LiveOfferMatcher.sortHotelsByPlanMatch(
                  hotels: nearPlan,
                  planHotel: planHotel,
                  nights: nights,
                  targetPerNightTL: targetPerNightTL,
                );
              }
            }
          }
        } catch (_) {
          if (attempt == 0) await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    return [];
  }

  static Map<String, dynamic> _normalizeHotel(
    Map<String, dynamic> h, {
    int nights = 1,
  }) {
    final copy = Map<String, dynamic>.from(h);
    final stayNights = (h['nights'] as num?)?.toInt() ?? nights;
    final currency =
        (h['currency'] as String?)?.toUpperCase().replaceAll('€', 'EUR') ?? '';
    final priceScope = h['priceScope']?.toString();
    final perNightRaw = (h['pricePerNight'] as num?)?.toDouble();
    final totalRaw = (h['totalPrice'] as num?)?.toDouble();

    int toTl(double amount) {
      if (currency == 'EUR' || (currency.isEmpty && amount < 500)) {
        return (amount * LiveFxRate.eurToTl).round();
      }
      if (currency == 'USD') {
        return (amount * LiveFxRate.usdToTl).round();
      }
      if (currency == 'TRY' || currency == 'TL') {
        return amount.round();
      }
      return amount.round();
    }

    double? stayTotal;
    if (totalRaw != null && totalRaw > 0) {
      stayTotal = totalRaw;
    } else if (perNightRaw != null && perNightRaw > 0) {
      // Eski backend: grossPrice yalnızca pricePerNight olarak geliyordu (= konaklama toplamı)
      if (priceScope == 'stay' || stayNights > 1) {
        stayTotal = perNightRaw;
      }
    }

    if (stayTotal != null && stayTotal > 0) {
      final totalTl = toTl(stayTotal);
      final perNightTl =
          stayNights > 0 ? (totalTl / stayNights).round() : totalTl;
      copy['totalPrice'] = stayTotal;
      copy['totalPriceTL'] = totalTl;
      copy['pricePerNight'] =
          stayNights > 0 ? stayTotal / stayNights : stayTotal;
      copy['pricePerNightTL'] = perNightTl;
      copy['nights'] = stayNights;
      copy['priceScope'] = 'stay';
    } else if (perNightRaw != null && perNightRaw > 0) {
      copy['pricePerNightTL'] = toTl(perNightRaw);
    }

    copy['pricePerNightTL'] ??=
        PriceFormat.hotelPerNightTL(copy, nights: stayNights);
    copy['totalPriceTL'] ??= PriceFormat.hotelTotalTL(copy, stayNights);

    for (final key in ['latitude', 'longitude', 'address', 'photoUrl']) {
      if (h[key] != null) copy[key] = h[key];
    }
    return copy;
  }

  static List<Map<String, dynamic>> _filterHotelsNearPlan({
    required List<Map<String, dynamic>> hotels,
    int? targetPerNightTL,
    int minKeep = 5,
  }) {
    if (targetPerNightTL == null || targetPerNightTL <= 0 || hotels.length <= minKeep) {
      return hotels;
    }
    final maxPerNight = (targetPerNightTL * 2.2).round();
    final filtered = hotels
        .where((h) {
          final p = PriceFormat.hotelPerNightTL(h);
          return p > 0 && p <= maxPerNight;
        })
        .toList();
    return filtered.length >= minKeep ? filtered : hotels;
  }

  // ============================================================
  // REHBER (API + aktivite verisi)
  // ============================================================
  static Future<Map<String, dynamic>> getDestinationGuide({
    required String iata,
    required String cityName,
    required String country,
    required String departure,
    required String returnDate,
  }) async {
    final meta = await getDestinationMeta(iata);
    final activitiesResult = await getActivities(
      iata: iata,
      city: cityName,
      departure: departure,
      returnDate: returnDate,
    );

    final activities = activityItemsFromResponse(activitiesResult);
    final places = activities.map((a) {
      final priceTL = (a['priceTL'] as num?)?.toInt() ?? 0;
      return {
        'title': a['title'] ?? '',
        'subtitle': a['description'] ?? '',
        'price': priceTL > 0 ? PriceFormat.format(priceTL) : 'Ücretsiz',
        'emoji': '🎯',
      };
    }).toList();

    final smartTips = activities.take(4).map((a) {
      return {
        'type': 'activity',
        'text': '${a['title']}: ${a['description'] ?? ''}',
      };
    }).toList();

    return {
      'success': true,
      'data': {
        'essentialInfo': _essentialInfoFromMeta(meta, cityName, country),
        'smartTips': smartTips,
        'placesToVisit': places,
        'mustSee': places
            .take(3)
            .map((p) => {'text': p['title'], 'tip': p['subtitle']})
            .toList(),
        'rules': const [],
        'transport': const [],
        'tips': const [],
        'foodAndDrink': {
          'summary': meta?['costIndex'] != null
              ? '$cityName yaşam maliyeti endeksi: ${meta!['costIndex']}'
              : '$cityName için güncel fiyatlar API üzerinden yüklenir.',
          'items': const [],
        },
      },
    };
  }

  static List<Map<String, dynamic>> _essentialInfoFromMeta(
    Map<String, dynamic>? meta,
    String cityName,
    String country,
  ) {
    final items = <Map<String, dynamic>>[];
    if (meta != null) {
      final costLines = <String>[];
      if (meta['costIndex'] != null) {
        costLines.add('Yaşam maliyeti endeksi: ${meta['costIndex']}');
      }
      if (meta['hotelRatingMin'] != null) {
        costLines.add('Önerilen minimum otel puanı: ${meta['hotelRatingMin']}');
      }
      if (meta['distanceToCenterKm'] != null) {
        costLines.add('Havalimanından merkeze: ${meta['distanceToCenterKm']} km');
      }
      if (costLines.isNotEmpty) {
        items.add({
          'title': 'Destinasyon Özeti',
          'icon': '📍',
          'items': costLines,
        });
      }
    }
    items.add({
      'title': 'Genel',
      'icon': '📌',
      'items': [
        '$cityName, $country',
        'Fiyatlar Türk Lirası (TL) olarak gösterilir.',
        'Uçuş ve otel fiyatları canlı API kaynaklarından gelir.',
      ],
    });
    return items;
  }

  // ============================================================
  // HARCAMA TAHMİNİ (rota bütçesi + aktivite API)
  // ============================================================
  static Future<Map<String, dynamic>> getSpendingEstimates({
    required String iata,
    required String cityName,
    required String country,
    required int nights,
    required int passengers,
    int children = 0,
    String? hotelName,
    RouteResultModel? route,
    String? departure,
    String? returnDate,
  }) async {
    final n = nights.clamp(1, 365);

    List<Map<String, dynamic>> activityItems = [];
    if (departure != null && returnDate != null) {
      final act = await getActivities(
        iata: iata,
        city: cityName,
        departure: departure,
        returnDate: returnDate,
      );
      activityItems = activityItemsFromResponse(act);
    }

    final meta = await getDestinationMeta(iata);
    final costIndex = (meta?['costIndex'] as num?)?.toDouble();

    final est = SpendingEstimateBuilder.fromDestination(
      cityName: cityName,
      iata: iata,
      country: country,
      nights: n,
      passengers: passengers,
      children: children,
      costIndex: costIndex,
      activityItems: activityItems,
    );
    return _spendingMapFromEstimate(
      est,
      source: costIndex != null ? 'index' : 'averages',
      cityName: cityName,
      costIndex: costIndex,
    );
  }

  static Map<String, dynamic> _spendingMapFromEstimate(
    SpendingEstimate est, {
    required String source,
    required String cityName,
    double? costIndex,
  }) {
    return {
      'foodSummary': est.dailyFoodPerPersonTL > 0 || est.dailyTransportPerPersonTL > 0
          ? SpendingEstimateNormalizer.dailyBreakdownLine(
              est.dailyFoodPerPersonTL,
              est.dailyTransportPerPersonTL,
            )
          : est.foodSummary,
      'foodItems': est.foodItems,
      'dailyFoodPerPersonTL': est.dailyFoodPerPersonTL,
      'totalFoodTL': est.totalFoodTL,
      'dailyTransportPerPersonTL': est.dailyTransportPerPersonTL,
      'estimatedLocalTransportTL': est.estimatedLocalTransportTL,
      'effectivePeople': est.effectivePeople,
      'foodScopeLabel': costIndex != null
          ? '$cityName · maliyet endeksi ${costIndex.toStringAsFixed(1)}'
          : est.foodScopeLabel,
      'transportScopeLabel': est.transportScopeLabel,
      'attractions': est.attractions,
      'totalAttractionsTL': est.totalAttractionsTL,
      'localTransport': est.localTransport,
      'hotelRoutes': est.hotelRoutes,
      'grandTotalTL': est.grandTotalTL,
      'perPersonPerDayTL': est.perPersonPerDayTL,
      'disclaimer': est.disclaimer,
      'source': source,
    };
  }

  // ============================================================
  // SAĞLIK TURİZMİ
  // ============================================================
  static Future<List<Map<String, dynamic>>> getMedicalPackages({
    required String iata,
    required double budget,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/medical/packages')
          .replace(queryParameters: {
        'iata': iata,
        'budget': budget.toString(),
      });
      final response = await http.get(uri).timeout(AppConstants.receiveTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> saveMedicalBooking({
    required String sessionId,
    required String packageId,
    required String clinicId,
    required String travelDate,
    required int passengerCount,
    required double treatmentPriceTL,
    required double flightPriceTL,
    required double hotelPriceTL,
    required double totalPriceTL,
    required double commissionTL,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/medical/booking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionId,
          'packageId': packageId,
          'clinicId': clinicId,
          'travelDate': travelDate,
          'passengerCount': passengerCount,
          'treatmentPriceTL': treatmentPriceTL,
          'flightPriceTL': flightPriceTL,
          'hotelPriceTL': hotelPriceTL,
          'totalPriceTL': totalPriceTL,
          'commissionTL': commissionTL,
        }),
      ).timeout(AppConstants.receiveTimeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'success': false};
  }

  static Future<bool> registerClinic({
    required String name,
    required String specialty,
    required String cityName,
    required String contactEmail,
    required String contactPhone,
    required String website,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/clinics/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'specialty': specialty,
          'city_name': cityName,
          'contact_email': contactEmail,
          'contact_phone': contactPhone,
          'website': website,
          'address': address,
          'country': 'Turkey',
        }),
      ).timeout(AppConstants.receiveTimeout);
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // HATA
  // ============================================================
  static RouteSearchFailure _connectionFailureFrom(
    String? message,
    String? detail,
  ) {
    final haystack = '${message ?? ''} ${detail ?? ''}'.toLowerCase();
    if (haystack.contains('bağlanılamadı') ||
        haystack.contains('socketexception') ||
        haystack.contains('failed host lookup') ||
        haystack.contains('network is unreachable')) {
      return RouteSearchFailure.connection;
    }
    return RouteSearchFailure.serverError;
  }

  static Map<String, dynamic> _connectionError(dynamic error) {
    return {
      'success': false,
      'error': {
        'message':
            'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.',
        'detail': error.toString(),
      },
    };
  }
}
