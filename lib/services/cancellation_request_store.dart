import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cancellation_request.dart';

/// İptal talepleri — cihazda saklanır; backend entegrasyonu hazır.
class CancellationRequestStore {
  CancellationRequestStore._();

  static const _key = 'vizegoo_cancellation_requests';

  static Future<List<CancellationRequest>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((s) {
          try {
            return CancellationRequest.fromJson(
              jsonDecode(s) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<CancellationRequest>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<CancellationRequest?> forReservation(String reservationId) async {
    final all = await list();
    for (final r in all) {
      if (r.reservationId == reservationId) return r;
    }
    return null;
  }

  static Future<CancellationRequest> submit({
    required String reservationId,
    required String cityName,
    required String reason,
    String note = '',
  }) async {
    final request = CancellationRequest(
      id: 'CR-${DateTime.now().millisecondsSinceEpoch}',
      reservationId: reservationId,
      cityName: cityName,
      reason: reason,
      createdAt: DateTime.now(),
      note: note,
    );
    final prefs = await SharedPreferences.getInstance();
    final current = await list();
    final merged = [
      request,
      ...current.where((r) => r.reservationId != reservationId),
    ];
    await prefs.setStringList(
      _key,
      merged.map((r) => jsonEncode(r.toJson())).toList(),
    );
    return request;
  }
}
