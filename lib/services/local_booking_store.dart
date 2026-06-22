import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/stored_booking_model.dart';

/// Misafir ve yedek rezervasyon kayıtları — cihazda saklanır.
class LocalBookingStore {
  LocalBookingStore._();

  static const _key = 'vizegoo_local_bookings';

  static Future<List<StoredBooking>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((s) {
          try {
            return StoredBooking.fromJson(
              jsonDecode(s) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<StoredBooking>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> save(StoredBooking booking) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await list();
    final merged = [
      booking,
      ...current.where((b) => b.reservationId != booking.reservationId),
    ];
    await prefs.setStringList(
      _key,
      merged.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  static Future<void> replaceAll(List<StoredBooking> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = List<StoredBooking>.from(bookings)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await prefs.setStringList(
      _key,
      sorted.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  static Future<StoredBooking?> find(String reservationId) async {
    final all = await list();
    for (final b in all) {
      if (b.reservationId == reservationId) return b;
    }
    return null;
  }
}
