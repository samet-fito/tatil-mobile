import 'package:intl/intl.dart';

/// Aktivite / etkinlik tarih bilgisi.
class ActivityScheduleInfo {
  const ActivityScheduleInfo({
    required this.isDaily,
    this.eventDate,
  });

  final bool isDaily;
  final DateTime? eventDate;

  String get dateLabel {
    if (isDaily) return 'Her gün';
    if (eventDate == null) return 'Her gün';
    return DateFormat('d MMM yyyy', 'tr_TR').format(eventDate!);
  }
}

class ActivityScheduleUtils {
  ActivityScheduleUtils._();

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static ActivityScheduleInfo scheduleFor(
    Map<String, dynamic> activity, {
    required DateTime tripStart,
    required DateTime tripEnd,
    required int index,
  }) {
    final start = _dayOnly(tripStart);
    final end = _dayOnly(tripEnd);

    final rawDaily = activity['isDaily'] ?? activity['daily'];
    if (rawDaily == true) {
      return const ActivityScheduleInfo(isDaily: true);
    }

    final rawDate = activity['eventDate'] ??
        activity['event_date'] ??
        activity['date'] ??
        activity['when'];
    if (rawDate is String && rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        return ActivityScheduleInfo(isDaily: false, eventDate: _dayOnly(parsed));
      }
    }

    final category = activity['category'] as String? ?? 'tours';
    if (category != 'events') {
      return const ActivityScheduleInfo(isDaily: true);
    }

    final span = end.difference(start).inDays;
    final offset = span > 0 ? index % (span + 1) : 0;
    return ActivityScheduleInfo(
      isDaily: false,
      eventDate: start.add(Duration(days: offset)),
    );
  }

  static bool isWithinTrip({
    required ActivityScheduleInfo schedule,
    required DateTime tripStart,
    required DateTime tripEnd,
  }) {
    if (schedule.isDaily) return true;
    final event = schedule.eventDate;
    if (event == null) return true;
    final start = _dayOnly(tripStart);
    final end = _dayOnly(tripEnd);
    final day = _dayOnly(event);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  static Map<String, dynamic> enrichActivity(
    Map<String, dynamic> activity, {
    required DateTime tripStart,
    required DateTime tripEnd,
    required int index,
  }) {
    final schedule = scheduleFor(
      activity,
      tripStart: tripStart,
      tripEnd: tripEnd,
      index: index,
    );
    return {
      ...activity,
      'isDaily': schedule.isDaily,
      if (schedule.eventDate != null)
        'eventDate': schedule.eventDate!.toIso8601String(),
      'scheduleLabel': schedule.dateLabel,
    };
  }

  static DateTime? parseEventDate(Map<String, dynamic> activity) {
    final raw = activity['eventDate'] as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}
