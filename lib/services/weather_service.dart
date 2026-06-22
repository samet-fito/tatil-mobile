import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/destination_geo.dart';
import '../models/personalized_guide_model.dart';

/// Open-Meteo ile seyahat tarihlerine göre hava özeti.
class WeatherService {
  WeatherService._();

  static const _forecastBase = 'https://api.open-meteo.com/v1/forecast';
  static const _geocodeBase = 'https://geocoding-api.open-meteo.com/v1/search';

  static Future<TripWeatherSummary?> getTripWeather({
    required String cityName,
    required String destinationIata,
    required DateTime departureDate,
    required DateTime returnDate,
  }) async {
    final coords = await _resolveCoords(cityName, destinationIata);
    if (coords == null) return null;

    final start = _dateOnly(departureDate);
    final end = _dateOnly(returnDate);
    if (end.isBefore(start)) return null;

    try {
      final uri = Uri.parse(_forecastBase).replace(queryParameters: {
        'latitude': coords.lat.toString(),
        'longitude': coords.lng.toString(),
        'daily':
            'temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode',
        'timezone': 'auto',
        'start_date': _fmt(start),
        'end_date': _fmt(end),
      });

      final response =
          await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>?;
      if (daily == null) return null;

      final dates = (daily['time'] as List?)?.cast<String>() ?? [];
      final highs =
          (daily['temperature_2m_max'] as List?)?.cast<num>() ?? const [];
      final lows =
          (daily['temperature_2m_min'] as List?)?.cast<num>() ?? const [];
      final precip =
          (daily['precipitation_sum'] as List?)?.cast<num>() ?? const [];
      final codes =
          (daily['weathercode'] as List?)?.cast<num>() ?? const [];

      if (dates.isEmpty || highs.isEmpty) return null;

      final days = <TripWeatherDay>[];
      var highSum = 0.0;
      var lowSum = 0.0;
      var rainDays = 0;

      for (var i = 0; i < dates.length; i++) {
        final high = (i < highs.length ? highs[i] : highs.last).toDouble();
        final low = (i < lows.length ? lows[i] : lows.last).toDouble();
        final rain = (i < precip.length ? precip[i] : 0).toDouble();
        final code = (i < codes.length ? codes[i] : 0).toInt();
        if (rain >= 1) rainDays++;

        highSum += high;
        lowSum += low;

        days.add(
          TripWeatherDay(
            date: DateTime.parse(dates[i]),
            highC: high,
            lowC: low,
            precipMm: rain.clamp(0, 999).toDouble(),
            label: _weatherLabel(code),
          ),
        );
      }

      final avgHigh = highSum / days.length;
      final avgLow = lowSum / days.length;
      final minHigh = days.map((d) => d.highC).reduce((a, b) => a < b ? a : b);
      final maxHigh = days.map((d) => d.highC).reduce((a, b) => a > b ? a : b);

      final summaryLine =
          '${minHigh.round()}–${maxHigh.round()}°C ortalama, '
          '${rainDays > 0 ? '$rainDays gün yağış ihtimali' : 'yağış beklenmiyor'}';

      final clothingHint = _clothingHint(avgHigh, avgLow, rainDays > 0);

      return TripWeatherSummary(
        summaryLine: summaryLine,
        clothingHint: clothingHint,
        days: days,
        avgHighC: avgHigh,
        avgLowC: avgLow,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<({double lat, double lng})?> _resolveCoords(
    String cityName,
    String destinationIata,
  ) async {
    final geo = DestinationGeo.forIata(destinationIata);
    if (geo != null) {
      return (lat: geo.cityCenter.lat, lng: geo.cityCenter.lng);
    }

    try {
      final uri = Uri.parse(_geocodeBase).replace(queryParameters: {
        'name': cityName,
        'count': '1',
        'language': 'tr',
        'format': 'json',
      });
      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final lat = (first['latitude'] as num?)?.toDouble();
      final lng = (first['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return (lat: lat, lng: lng);
    } catch (_) {
      return null;
    }
  }

  static String _weatherLabel(int code) {
    if (code == 0) return 'Açık';
    if (code <= 3) return 'Parçalı bulutlu';
    if (code <= 48) return 'Sisli';
    if (code <= 67) return 'Yağmurlu';
    if (code <= 77) return 'Karlı';
    if (code <= 82) return 'Sağanak';
    if (code <= 99) return 'Fırtınalı';
    return 'Değişken';
  }

  static String _clothingHint(double avgHigh, double avgLow, bool rain) {
    if (avgHigh >= 32) {
      return rain
          ? 'Hafif, nefes alan kıyafet + yağmurluk/şemsiye; güneş kremi şart.'
          : 'Hafif pamuklu kıyafet, şapka, güneş gözlüğü ve SPF 50+ kullanın.';
    }
    if (avgHigh >= 22) {
      return rain
          ? 'Katmanlı giyinin; hafif ceket ve yağmurluk yeterli.'
          : 'Gündüz hafif, akşam ince ceket yeterli.';
    }
    if (avgHigh >= 12) {
      return 'Katmanlı giyim; ince mont veya ceket önerilir.';
    }
    return 'Sıcak mont, katmanlı giyim ve eldiven düşünün.';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
