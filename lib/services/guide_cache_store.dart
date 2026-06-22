import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/personalized_guide_model.dart';

/// Rezervasyon bazlı seyahat rehberi önbelleği — offline erişim.
class GuideCacheStore {
  GuideCacheStore._();

  static const _cacheVersion = 3;

  static String _key(String reservationId) =>
      'vizegoo_guide_v${_cacheVersion}_$reservationId';

  static Future<PersonalizedGuide?> get(String reservationId) async {
    if (reservationId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(reservationId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final guide = PersonalizedGuide.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (guide.isEmpty) return null;
      return guide;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String reservationId, PersonalizedGuide guide) async {
    if (reservationId.isEmpty || guide.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(reservationId), jsonEncode(guide.toJson()));
  }
}
