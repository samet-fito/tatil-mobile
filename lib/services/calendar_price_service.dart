import '../models/calendar_day_quote.dart';
import '../utils/price_format.dart';
import 'api_service.dart';

/// Gidiş tarihine göre uçuş + otel paket fiyatlarını takvim için yükler.
class CalendarPriceService {
  CalendarPriceService._();

  static final Map<String, CalendarDayQuote> _cache = {};
  static int _loadGeneration = 0;

  /// Takvim kapanınca veya arama başlayınca bekleyen yüklemeleri iptal eder.
  static void cancelPendingLoads() => _loadGeneration++;

  static const _maxDaysPerMonth = 12;
  static const _delayBetweenDays = Duration(milliseconds: 450);

  static String _cacheKey({
    required String origin,
    required String destination,
    required String city,
    required int nights,
    required int passengers,
    required DateTime departure,
  }) =>
      '$origin-$destination-$city-$nights-$passengers-${_dayKey(departure)}';

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static void clearCache() => _cache.clear();

  /// Ay içinde en fazla [_maxDaysPerMonth] gün — [focusDate] etrafında öncelikli.
  static Future<Map<DateTime, CalendarDayQuote>> loadMonth({
    required String originIata,
    required String destinationIata,
    required String destinationCity,
    required int nights,
    required int passengers,
    required DateTime month,
    DateTime? focusDate,
    void Function(DateTime day, CalendarDayQuote quote)? onDayUpdated,
  }) async {
    final gen = _loadGeneration;
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final today = DateTime.now();
    final focus = focusDate ?? first;

    final candidates = <DateTime>[];
    for (var d = 1; d <= last.day; d++) {
      final day = DateTime(month.year, month.month, d);
      if (day.isBefore(DateTime(today.year, today.month, today.day))) continue;
      candidates.add(day);
    }

    candidates.sort((a, b) {
      final da = a.difference(focus).inDays.abs();
      final db = b.difference(focus).inDays.abs();
      final cmp = da.compareTo(db);
      if (cmp != 0) return cmp;
      return a.compareTo(b);
    });

    final days = candidates.take(_maxDaysPerMonth).toList()
      ..sort((a, b) => a.compareTo(b));

    final results = <DateTime, CalendarDayQuote>{};
    for (final day in days) {
      results[day] = CalendarDayQuote(departureDate: day, loading: true);
    }

    if (gen != _loadGeneration) return results;

    final batchLoaded = await _loadMonthBatch(
      gen: gen,
      originIata: originIata,
      destinationIata: destinationIata,
      destinationCity: destinationCity,
      nights: nights,
      passengers: passengers,
      days: days,
      results: results,
      onDayUpdated: onDayUpdated,
    );

    if (batchLoaded || gen != _loadGeneration) return results;

    for (final day in days) {
      if (gen != _loadGeneration) break;
      await Future.delayed(_delayBetweenDays);

      final quote = await _quoteForDay(
        originIata: originIata,
        destinationIata: destinationIata,
        destinationCity: destinationCity,
        nights: nights,
        passengers: passengers,
        departure: day,
      );
      if (gen != _loadGeneration) break;

      results[day] = quote;
      onDayUpdated?.call(day, quote);
    }

    return results;
  }

  static Future<bool> _loadMonthBatch({
    required int gen,
    required String originIata,
    required String destinationIata,
    required String destinationCity,
    required int nights,
    required int passengers,
    required List<DateTime> days,
    required Map<DateTime, CalendarDayQuote> results,
    void Function(DateTime day, CalendarDayQuote quote)? onDayUpdated,
  }) async {
    final batch = await ApiService.fetchCalendarQuotes(
      originIata: originIata,
      destinationIata: destinationIata,
      destinationCity: destinationCity,
      departureDates: days,
      nights: nights,
      passengers: passengers,
    );

    if (batch.isEmpty || gen != _loadGeneration) return false;

    final byDate = <String, Map<String, dynamic>>{};
    for (final row in batch) {
      final dep = row['departureDate']?.toString();
      if (dep != null && dep.isNotEmpty) byDate[dep] = row;
    }

    if (byDate.isEmpty) return false;

    for (final day in days) {
      if (gen != _loadGeneration) return true;

      final row = byDate[_dayKey(day)];
      final quote = row != null
          ? _quoteFromBatchRow(day, row)
          : CalendarDayQuote(departureDate: day, failed: true);

      _cache[_cacheKey(
        origin: originIata,
        destination: destinationIata,
        city: destinationCity,
        nights: nights,
        passengers: passengers,
        departure: day,
      )] = quote;

      results[day] = quote;
      onDayUpdated?.call(day, quote);
    }

    return true;
  }

  static CalendarDayQuote _quoteFromBatchRow(
    DateTime day,
    Map<String, dynamic> row,
  ) {
    final flightTL = (row['flightTL'] as num?)?.round() ?? 0;
    final hotelTL = (row['hotelTL'] as num?)?.round() ?? 0;
    return CalendarDayQuote(
      departureDate: day,
      flightTL: flightTL,
      hotelTL: hotelTL,
      failed: flightTL == 0 && hotelTL == 0,
    );
  }

  static Future<CalendarDayQuote> _quoteForDay({
    required String originIata,
    required String destinationIata,
    required String destinationCity,
    required int nights,
    required int passengers,
    required DateTime departure,
  }) async {
    final key = _cacheKey(
      origin: originIata,
      destination: destinationIata,
      city: destinationCity,
      nights: nights,
      passengers: passengers,
      departure: departure,
    );
    final cached = _cache[key];
    if (cached != null && !cached.loading) return cached;

    final returnDate = departure.add(Duration(days: nights));
    try {
      final flightsFuture = ApiService.searchRealFlights(
        originIata: originIata,
        destinationIata: destinationIata,
        departureDate: departure,
        returnDate: returnDate,
        passengers: passengers,
      );
      final hotelsFuture = ApiService.searchHotels(
        cityName: destinationCity,
        checkIn: departure,
        returnDate: returnDate,
        adults: passengers,
        destinationIata: destinationIata,
        nights: nights,
      );

      final results = await Future.wait([flightsFuture, hotelsFuture]);
      final flights = results[0];
      final hotels = results[1];

      var flightTL = 0;
      if (flights.isNotEmpty) {
        flights.sort((a, b) {
          final pa = (a['totalAmountTL'] as num?)?.toInt() ?? 999999999;
          final pb = (b['totalAmountTL'] as num?)?.toInt() ?? 999999999;
          return pa.compareTo(pb);
        });
        flightTL = (flights.first['totalAmountTL'] as num?)?.toInt() ?? 0;
      }

      var hotelTL = 0;
      if (hotels.isNotEmpty) {
        hotels.sort((a, b) {
          final pa = PriceFormat.hotelTotalTL(a, nights);
          final pb = PriceFormat.hotelTotalTL(b, nights);
          return pa.compareTo(pb);
        });
        hotelTL = PriceFormat.hotelTotalTL(hotels.first, nights);
      }

      final quote = CalendarDayQuote(
        departureDate: departure,
        flightTL: flightTL,
        hotelTL: hotelTL,
        failed: flightTL == 0 && hotelTL == 0,
      );
      _cache[key] = quote;
      return quote;
    } catch (_) {
      final quote = CalendarDayQuote(
        departureDate: departure,
        failed: true,
      );
      _cache[key] = quote;
      return quote;
    }
  }

  static int displayPriceForDay({
    required DateTime day,
    required Map<DateTime, CalendarDayQuote> quotes,
    required int flexDays,
  }) {
    return _displayComponentForDay(
      day: day,
      quotes: quotes,
      flexDays: flexDays,
      pick: (q) => q.packageTL,
    );
  }

  static int displayFlightPriceForDay({
    required DateTime day,
    required Map<DateTime, CalendarDayQuote> quotes,
    required int flexDays,
  }) {
    return _displayComponentForDay(
      day: day,
      quotes: quotes,
      flexDays: flexDays,
      pick: (q) => q.flightTL,
    );
  }

  static int displayHotelPriceForDay({
    required DateTime day,
    required Map<DateTime, CalendarDayQuote> quotes,
    required int flexDays,
  }) {
    return _displayComponentForDay(
      day: day,
      quotes: quotes,
      flexDays: flexDays,
      pick: (q) => q.hotelTL,
    );
  }

  static int _displayComponentForDay({
    required DateTime day,
    required Map<DateTime, CalendarDayQuote> quotes,
    required int flexDays,
    required int Function(CalendarDayQuote q) pick,
  }) {
    if (flexDays == 0) {
      final q = quotes[_dayOnly(day)];
      if (q == null) return 0;
      return pick(q);
    }
    var min = 0;
    for (var offset = -flexDays; offset <= flexDays; offset++) {
      final d = DateTime(day.year, day.month, day.day + offset);
      final q = quotes[_dayOnly(d)];
      if (q == null) continue;
      final v = pick(q);
      if (v <= 0) continue;
      if (min == 0 || v < min) min = v;
    }
    return min;
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
