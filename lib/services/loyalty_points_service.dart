import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LoyaltyTransaction {
  const LoyaltyTransaction({
    required this.label,
    required this.points,
    required this.createdAt,
    this.reservationId,
  });

  final String label;
  final int points;
  final DateTime createdAt;
  final String? reservationId;

  Map<String, dynamic> toJson() => {
        'label': label,
        'points': points,
        'createdAt': createdAt.toIso8601String(),
        if (reservationId != null) 'reservationId': reservationId,
      };

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      label: json['label']?.toString() ?? '',
      points: (json['points'] as num?)?.round() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      reservationId: json['reservationId']?.toString(),
    );
  }
}

/// Vizegoo Puan — her 10 TL harcamada 1 puan (Turna tarzı sadakat).
abstract final class LoyaltyPointsService {
  static const _balanceKey = 'vizegoo_loyalty_balance';
  static const _historyKey = 'vizegoo_loyalty_history';
  static const int pointsPerTenTL = 1;

  static int pointsForPurchase(int totalPriceTL) =>
      (totalPriceTL / 10).floor().clamp(0, 50000);

  static int tlValueOfPoints(int points) => points;

  static Future<int> balance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_balanceKey) ?? 0;
  }

  static Future<List<LoyaltyTransaction>> history() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? const [];
    return raw
        .map((s) {
          try {
            return LoyaltyTransaction.fromJson(
              jsonDecode(s) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<LoyaltyTransaction>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<int> earnFromBooking({
    required int totalPriceTL,
    required String reservationId,
    required String cityName,
  }) async {
    final earned = pointsForPurchase(totalPriceTL);
    if (earned <= 0) return 0;

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_balanceKey) ?? 0;
    await prefs.setInt(_balanceKey, current + earned);

    final tx = LoyaltyTransaction(
      label: '$cityName rezervasyonu',
      points: earned,
      createdAt: DateTime.now(),
      reservationId: reservationId,
    );
    final hist = await history();
    final updated = [tx, ...hist].take(50).toList();
    await prefs.setStringList(
      _historyKey,
      updated.map((e) => jsonEncode(e.toJson())).toList(),
    );
    return earned;
  }
}
