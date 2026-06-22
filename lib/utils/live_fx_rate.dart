import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';

/// Duffel uçuş yanıtlarından güncel EUR→TL kuru (backend totalAmountTL / totalAmount).
class LiveFxRate {
  LiveFxRate._();

  static double _eurToTl = 35.0;
  static DateTime? _updatedAt;

  static double get eurToTl => _eurToTl;

  /// EUR kuru üzerinden tahmini USD/TL (Big Mac endeksi vb.).
  static double get usdToTl => _eurToTl / 1.08;

  static DateTime? get updatedAt => _updatedAt;

  static bool get hasLiveRate => _updatedAt != null;

  static void updateFromFlight(Map<String, dynamic> flight) {
    final eur = (flight['totalAmount'] as num?)?.toDouble();
    final tl = (flight['totalAmountTL'] as num?)?.toDouble();
    if (eur == null || eur <= 0 || tl == null || tl <= 0) return;
    final rate = tl / eur;
    // Backend Duffel dönüşümü (~35); aşırı sapmaları reddet.
    if (rate < 28 || rate > 70) return;
    _eurToTl = rate;
    _updatedAt = DateTime.now();
  }

  static void updateFromFlights(List<Map<String, dynamic>> flights) {
    for (final f in flights) {
      updateFromFlight(f);
    }
  }

  /// Uygulama açılışında canlı kur almak için hafif uçuş sorgusu.
  static Future<void> prefetchFromApi() async {
    try {
      final dep = DateTime.now().add(const Duration(days: 45));
      final ret = dep.add(const Duration(days: 5));
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/flights/search'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'originIata': 'IST',
              'destinationIata': 'FCO',
              'departureDate': dep.toIso8601String().split('T').first,
              'returnDate': ret.toIso8601String().split('T').first,
              'passengers': 1,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return;
      final list = List<Map<String, dynamic>>.from(data['data'] ?? []);
      updateFromFlights(list);
    } catch (_) {}
  }
}
