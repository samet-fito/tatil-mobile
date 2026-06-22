import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/destination_model.dart';

/// Son aranan destinasyonlar — cihazda saklanır (max 8).
abstract final class RecentDestinationStore {
  static const _key = 'recent_destinations_v1';
  static const _maxItems = 8;

  static Future<List<DestinationModel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null || raw.isEmpty) return [];

    final list = <DestinationModel>[];
    for (final entry in raw) {
      try {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        final model = DestinationModel(
          iataCode: map['iataCode'] as String? ?? '',
          cityName: map['cityName'] as String? ?? '',
          country: map['country'] as String? ?? '',
        );
        if (model.iataCode.isNotEmpty && model.cityName.isNotEmpty) {
          list.add(model);
        }
      } catch (_) {
        // skip corrupt entry
      }
    }
    return list;
  }

  static Future<void> record({
    required String iataCode,
    required String cityName,
    String country = '',
  }) async {
    if (iataCode.isEmpty || cityName.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final existing = await load();
    final next = [
      DestinationModel(
        iataCode: iataCode.toUpperCase(),
        cityName: cityName,
        country: country,
      ),
      ...existing.where((d) => d.iataCode.toUpperCase() != iataCode.toUpperCase()),
    ].take(_maxItems).toList();

    await prefs.setStringList(
      _key,
      next
          .map(
            (d) => jsonEncode({
              'iataCode': d.iataCode,
              'cityName': d.cityName,
              'country': d.country,
            }),
          )
          .toList(),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
