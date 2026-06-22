import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/advisor_events_catalog.dart';
import '../data/advisor_fallback_catalog.dart';
import '../constants.dart';
import '../models/smart_travel_advisor_model.dart';
import '../utils/live_fx_rate.dart';
import '../data/destination_currency.dart';

/// Python / Node advisor endpoint — dinamik seyahat danışmanı.
class SmartTravelAdvisorService {
  SmartTravelAdvisorService._();

  static Future<SmartTravelAdvisorResponse?> fetchDiscovery({
    required String destinationIata,
    required String cityName,
    required String country,
    required DateTime departureDate,
    required DateTime returnDate,
    required int nights,
    required int adults,
    required int children,
    List<int> passengerAges = const [],
  }) async {
    final localCurrency = DestinationCurrency.forIata(destinationIata);
    final fxRate = _fxRateFor(localCurrency);

    final body = {
      'destinationIata': destinationIata.toUpperCase(),
      'cityName': cityName,
      'country': country,
      'departureDate': _fmt(departureDate),
      'returnDate': _fmt(returnDate),
      'nights': nights,
      'adults': adults,
      'children': children,
      'passengerAges': passengerAges,
      'localCurrency': localCurrency,
      'fxRateTl': fxRate,
    };

    try {
      final remote = await _fetchRemote(
        body: body,
        destinationIata: destinationIata,
      );
      if (remote != null) return remote;
    } catch (_) {}

    return AdvisorFallbackCatalog.build(
      destinationIata: destinationIata,
      cityName: cityName,
      country: country,
      departureDate: departureDate,
      nights: nights,
      adults: adults,
      children: children,
      passengerAges: passengerAges,
      fxRateTl: fxRate,
    );
  }

  static Future<SmartTravelAdvisorResponse?> _fetchRemote({
    required Map<String, dynamic> body,
    required String destinationIata,
  }) async {
    final response = await http
        .post(
          Uri.parse(AppConstants.advisorDiscoveryEndpoint),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 22));

    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['success'] != true) return null;

    final data = decoded['data'];
    if (data is! Map) return null;

    final map = Map<String, dynamic>.from(data);
    final meta = decoded['meta'];
    if (meta is Map && meta['source'] != null) {
      map['_source'] = meta['source'];
    }

    final advisor = SmartTravelAdvisorResponse.fromJson(map);
    if (advisor.isEmpty) return null;
    return _withEventFallback(advisor, destinationIata);
  }

  static SmartTravelAdvisorResponse _withEventFallback(
    SmartTravelAdvisorResponse advisor,
    String iata,
  ) {
    if (advisor.liveEventsAffiliate.isNotEmpty) return advisor;
    final fallback = AdvisorEventsCatalog.forIata(iata);
    if (fallback.isEmpty) return advisor;
    return SmartTravelAdvisorResponse(
      groupAnalysis: advisor.groupAnalysis,
      weatherForecast: advisor.weatherForecast,
      goldenRules: advisor.goldenRules,
      liveEventsAffiliate: fallback,
      currencyConverter: advisor.currencyConverter,
      source: advisor.source,
    );
  }

  static double _fxRateFor(String currency) {
    switch (currency) {
      case 'EUR':
        return LiveFxRate.eurToTl;
      case 'USD':
        return LiveFxRate.usdToTl;
      case 'GBP':
        return LiveFxRate.eurToTl * 1.17;
      case 'TRY':
        return 1;
      default:
        return LiveFxRate.eurToTl;
    }
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
