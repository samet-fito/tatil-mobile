import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TripReminder {
  const TripReminder({
    required this.reservationId,
    required this.cityName,
    required this.departureDate,
    required this.remindAt,
    this.checkIn = true,
    this.shown = false,
  });

  final String reservationId;
  final String cityName;
  final DateTime departureDate;
  final DateTime remindAt;
  final bool checkIn;
  final bool shown;

  Map<String, dynamic> toJson() => {
        'reservationId': reservationId,
        'cityName': cityName,
        'departureDate': departureDate.toIso8601String(),
        'remindAt': remindAt.toIso8601String(),
        'checkIn': checkIn,
        'shown': shown,
      };

  factory TripReminder.fromJson(Map<String, dynamic> json) {
    return TripReminder(
      reservationId: json['reservationId']?.toString() ?? '',
      cityName: json['cityName']?.toString() ?? '',
      departureDate: DateTime.tryParse(json['departureDate']?.toString() ?? '') ??
          DateTime.now(),
      remindAt: DateTime.tryParse(json['remindAt']?.toString() ?? '') ??
          DateTime.now(),
      checkIn: json['checkIn'] as bool? ?? true,
      shown: json['shown'] as bool? ?? false,
    );
  }

  TripReminder copyWith({bool? shown}) => TripReminder(
        reservationId: reservationId,
        cityName: cityName,
        departureDate: departureDate,
        remindAt: remindAt,
        checkIn: checkIn,
        shown: shown ?? this.shown,
      );
}

/// Uçuş öncesi check-in hatırlatıcıları (24 saat önce).
abstract final class TripReminderService {
  static const _key = 'vizegoo_trip_reminders';
  static const _enabledKey = 'vizegoo_reminders_enabled';

  static Future<bool> remindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  static Future<void> setRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  static Future<void> scheduleForBooking({
    required String reservationId,
    required String cityName,
    required DateTime departureDate,
    bool hasFlight = true,
  }) async {
    if (!hasFlight) return;
    if (!await remindersEnabled()) return;

    final remindAt = departureDate.subtract(const Duration(hours: 24));
    if (remindAt.isBefore(DateTime.now())) return;

    final reminder = TripReminder(
      reservationId: reservationId,
      cityName: cityName,
      departureDate: departureDate,
      remindAt: remindAt,
    );

    final prefs = await SharedPreferences.getInstance();
    final current = await _listRaw(prefs);
    final merged = [
      reminder,
      ...current.where((r) => r.reservationId != reservationId),
    ];
    await _saveRaw(prefs, merged);
  }

  /// Uygulama açılışında vadesi gelen hatırlatıcıları döner.
  static Future<TripReminder?> consumeDueReminder() async {
    if (!await remindersEnabled()) return null;
    final prefs = await SharedPreferences.getInstance();
    final all = await _listRaw(prefs);
    final now = DateTime.now();

    for (var i = 0; i < all.length; i++) {
      final r = all[i];
      if (!r.shown && !now.isBefore(r.remindAt)) {
        all[i] = r.copyWith(shown: true);
        await _saveRaw(prefs, all);
        return r;
      }
    }
    return null;
  }

  static Future<List<TripReminder>> _listRaw(SharedPreferences prefs) async {
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((s) {
          try {
            return TripReminder.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<TripReminder>()
        .toList();
  }

  static Future<void> _saveRaw(
    SharedPreferences prefs,
    List<TripReminder> list,
  ) async {
    await prefs.setStringList(
      _key,
      list.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }
}
