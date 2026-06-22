import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'loyalty_points_service.dart';

/// Arkadaş daveti — Turna Puan tarzı referral.
abstract final class ReferralService {
  static const _codeKey = 'vizegoo_my_referral_code';
  static const _redeemedKey = 'vizegoo_referral_redeemed';
  static const int bonusPoints = 100;

  static Future<String> myCode() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_codeKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final code = _generateCode();
    await prefs.setString(_codeKey, code);
    return code;
  }

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    final suffix = List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'VG$suffix';
  }

  static Future<bool> hasRedeemedReferral() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_redeemedKey) ?? false;
  }

  static Future<String?> redeemedCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('vizegoo_referral_used_code');
  }

  static Future<ReferralResult> redeemCode(String input) async {
    final code = input.trim().toUpperCase();
    if (code.length < 5) {
      return const ReferralResult(success: false, message: 'Geçersiz davet kodu');
    }

    final ownCode = await ReferralService.myCode();
    if (code == ownCode) {
      return const ReferralResult(
        success: false,
        message: 'Kendi kodunuzu kullanamazsınız',
      );
    }

    if (await hasRedeemedReferral()) {
      return const ReferralResult(
        success: false,
        message: 'Daha önce bir davet kodu kullandınız',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_redeemedKey, true);
    await prefs.setString('vizegoo_referral_used_code', code);

    await LoyaltyPointsService.earnFromBooking(
      totalPriceTL: bonusPoints * 10,
      reservationId: 'REF-$code',
      cityName: 'Arkadaş daveti',
    );

    return ReferralResult(
      success: true,
      message: '$bonusPoints Vizegoo Puan kazandınız!',
      pointsEarned: bonusPoints,
    );
  }

  static Future<String> shareMessage() async {
    final code = await myCode();
    return '''
Vizegoo ile tatil planla 🌴

Davet kodum: $code
İlk rezervasyonunda $bonusPoints puan kazan!

https://vizegoo.app
''';
  }
}

class ReferralResult {
  const ReferralResult({
    required this.success,
    required this.message,
    this.pointsEarned = 0,
  });

  final bool success;
  final String message;
  final int pointsEarned;
}
