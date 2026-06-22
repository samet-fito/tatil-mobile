import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/price_watch.dart';

abstract final class PriceWatchStore {
  static const _key = 'vizegoo_price_watches';

  static Future<List<PriceWatch>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((s) {
          try {
            return PriceWatch.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<PriceWatch>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<PriceWatch> add({
    required String originIata,
    required String destinationIata,
    required String cityName,
    required String country,
    required DateTime departureDate,
    required DateTime returnDate,
    required int targetPriceTL,
    required int currentPriceTL,
    int passengers = 1,
    int nights = 5,
  }) async {
    final watch = PriceWatch(
      id: 'PW-${DateTime.now().millisecondsSinceEpoch}',
      originIata: originIata,
      destinationIata: destinationIata,
      cityName: cityName,
      country: country,
      departureDate: departureDate,
      returnDate: returnDate,
      targetPriceTL: targetPriceTL,
      lastSeenPriceTL: currentPriceTL,
      createdAt: DateTime.now(),
      passengers: passengers,
      nights: nights,
    );

    final prefs = await SharedPreferences.getInstance();
    final current = await list();
    final merged = [
      watch,
      ...current.where((w) => w.destinationIata != destinationIata),
    ].take(20).toList();
    await prefs.setStringList(
      _key,
      merged.map((w) => jsonEncode(w.toJson())).toList(),
    );
    return watch;
  }

  static Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await list();
    await prefs.setStringList(
      _key,
      current
          .where((w) => w.id != id)
          .map((w) => jsonEncode(w.toJson()))
          .toList(),
    );
  }

  static Future<void> updateLastSeen({
    required String destinationIata,
    required int priceTL,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await list();
    var changed = false;
    final updated = current.map((w) {
      if (w.destinationIata == destinationIata) {
        changed = true;
        return w.copyWith(lastSeenPriceTL: priceTL);
      }
      return w;
    }).toList();
    if (!changed) return;
    await prefs.setStringList(
      _key,
      updated.map((w) => jsonEncode(w.toJson())).toList(),
    );
  }
}
