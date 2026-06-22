import 'flight_schedule_format.dart';
import 'live_fx_rate.dart';

/// Uygulama genelinde fiyatların TL olarak gösterilmesi.
class PriceFormat {
  PriceFormat._();

  static double get eurToTl => LiveFxRate.eurToTl;
  static const double hufToTl = 0.09;

  static String format(int amount) => formatNum(amount);

  static String formatNum(num amount) {
    final n = amount.round();
    return '${n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  /// Takvim hücreleri için kısa fiyat (örn. 29k).
  static String formatCompact(int amount) {
    if (amount <= 0) return '—';
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
    }
    if (amount >= 1000) return '${(amount / 1000).round()}k';
    return amount.toString();
  }

  /// Otel gecelik fiyatı — API EUR/TRY alanlarına göre TL'ye çevirir.
  static int hotelPerNightTL(Map<String, dynamic> hotel, {int nights = 1}) {
    final direct = hotel['pricePerNightTL'];
    if (direct != null) {
      final v = (direct as num).round();
      if (v > 0) return v;
    }

    final stayNights = (hotel['nights'] as num?)?.toInt() ?? nights;

    final totalTl = hotel['totalPriceTL'];
    if (totalTl is num && totalTl > 0 && stayNights > 0) {
      return (totalTl.round() / stayNights).round();
    }

    final totalRaw = hotel['totalPrice'];
    if (totalRaw is num && totalRaw > 0 && stayNights > 0) {
      final currency =
          (hotel['currency'] as String?)?.toUpperCase().replaceAll('€', 'EUR') ??
              '';
      final total = currency == 'EUR' || (currency.isEmpty && totalRaw < 2500)
          ? (totalRaw * eurToTl).round()
          : totalRaw.round();
      if (total > 0) return (total / stayNights).round();
    }

    final currency =
        (hotel['currency'] as String?)?.toUpperCase().replaceAll('€', 'EUR') ??
            '';
    final p = (hotel['pricePerNight'] as num?)?.toDouble() ?? 0;

    if (p <= 0) return 0;

    final scope = hotel['priceScope']?.toString();
    if (stayNights > 1 &&
        hotel['totalPriceTL'] == null &&
        hotel['totalPrice'] == null &&
        (scope == 'stay' || scope == null)) {
      final stayTl = hotelTotalTL(hotel, stayNights);
      if (stayTl > 0) return (stayTl / stayNights).round();
    }

    if (currency == 'EUR') return (p * eurToTl).round();
    if (currency == 'USD') return (p * (eurToTl / 1.08)).round();
    if (currency == 'TRY' || currency == 'TL') return p.round();

    if (p < 500) return (p * eurToTl).round();
    return p.round();
  }

  /// Konaklama toplamı — API totalPrice / totalPriceTL öncelikli.
  static int hotelTotalTL(Map<String, dynamic> hotel, int nights) {
    final stayNights = (hotel['nights'] as num?)?.toInt() ?? nights;

    final totalTl = hotel['totalPriceTL'];
    if (totalTl is num) {
      final total = totalTl.round();
      if (total > 0) return total;
    }

    final totalRaw = hotel['totalPrice'];
    if (totalRaw is num) {
      final raw = totalRaw.toDouble();
      if (raw > 0) {
        final currency =
            (hotel['currency'] as String?)?.toUpperCase().replaceAll('€', 'EUR') ??
                '';
        if (currency == 'EUR' || (currency.isEmpty && raw < 2500)) {
          return (raw * eurToTl).round();
        }
        if (currency == 'TRY' || currency == 'TL') return raw.round();
        return raw.round();
      }
    }

    // priceScope=stay veya eski API: pricePerNight alanı konaklama toplamı olabilir
    final scope = hotel['priceScope']?.toString();
    final perNightField = (hotel['pricePerNight'] as num?)?.toDouble() ?? 0;
    if (perNightField > 0 && (scope == 'stay' || stayNights > 1)) {
      final currency =
          (hotel['currency'] as String?)?.toUpperCase().replaceAll('€', 'EUR') ??
              '';
      if (currency == 'EUR' || (currency.isEmpty && perNightField < 500)) {
        return (perNightField * eurToTl).round();
      }
      if (currency == 'TRY' || currency == 'TL') return perNightField.round();
      return perNightField.round();
    }

    return hotelPerNightTL(hotel, nights: stayNights) * stayNights;
  }

  static int flightTL(Map<String, dynamic> flight) =>
      (flight['totalAmountTL'] as num?)?.round() ?? 0;

  /// Duffel gidiş-dönüş teklifi: fiyat + dönüş saatleri birlikte olmalı.
  static bool hasRoundTripFlightPrice(Map<String, dynamic>? flight) {
    if (flight == null) return false;
    if (flightTL(flight) <= 0) return false;
    return FlightScheduleFormat.hasReturnTimes(flight);
  }

  static int roundTripFlightTL(Map<String, dynamic>? flight) {
    if (!hasRoundTripFlightPrice(flight)) return 0;
    return flightTL(flight!);
  }

  static String? formatRoundTripFlightPrice(Map<String, dynamic>? flight) {
    final tl = roundTripFlightTL(flight);
    if (tl <= 0) return null;
    return format(tl);
  }

  /// Tek yön uçuş — API tek yön alanı yoksa gidiş-dönüş fiyatından tahmini.
  static int oneWayFlightTL(Map<String, dynamic>? flight) {
    if (flight == null) return 0;
    final direct = flight['oneWayAmountTL'];
    if (direct is num && direct > 0) return direct.round();
    final base = flightTL(flight);
    if (base <= 0) return 0;
    return (base * 0.55).round();
  }

  static int flightTotalTL(
    Map<String, dynamic>? flight, {
    required bool roundTrip,
    double cabinMultiplier = 1.0,
  }) {
    final base =
        roundTrip ? roundTripFlightTL(flight) : oneWayFlightTL(flight);
    if (base <= 0) return 0;
    return (base * cabinMultiplier).round();
  }

  static String? formatFlightPrice(
    Map<String, dynamic>? flight, {
    required bool roundTrip,
    double cabinMultiplier = 1.0,
  }) {
    final tl = flightTotalTL(
      flight,
      roundTrip: roundTrip,
      cabinMultiplier: cabinMultiplier,
    );
    if (tl <= 0) return null;
    return format(tl);
  }

  static int hotelStarCount(Map<String, dynamic> hotel) {
    final raw = hotel['stars'] ?? hotel['starRating'];
    if (raw == null) return 0;
    return (raw as num).round().clamp(0, 5);
  }

  /// Otel puan/yıldız etiketi — API alan adları farklı olabilir.
  static String hotelRatingLine(Map<String, dynamic> hotel) {
    final parts = <String>[];
    final score = hotel['reviewScore'] ?? hotel['rating'];
    if (score is num && score > 0) {
      final s = score.toDouble();
      parts.add(s == s.roundToDouble() ? '${s.toInt()} puan' : '${s.toStringAsFixed(1)} puan');
    }
    final stars = hotelStarCount(hotel);
    if (stars > 0) parts.add('$stars yıldız');
    return parts.join(' · ');
  }

  static int cheapestFlightTL(List<Map<String, dynamic>> flights) {
    if (flights.isEmpty) return 0;
    final verified = flights
        .map(roundTripFlightTL)
        .where((tl) => tl > 0)
        .toList();
    if (verified.isEmpty) return 0;
    return verified.reduce((a, b) => a < b ? a : b);
  }

  static int cheapestHotelTotalTL(List<Map<String, dynamic>> hotels, int nights) {
    if (hotels.isEmpty) return 0;
    return hotels.map((h) => hotelTotalTL(h, nights)).reduce((a, b) => a < b ? a : b);
  }

  static int packagePayableTL({
    required int flightTL,
    required int hotelTL,
    int transferTL = 0,
    int extrasTL = 0,
  }) =>
      flightTL + hotelTL + transferTL + extrasTL;

  /// Metin içindeki € / HUF / EUR ifadelerini TL'ye çevirir (rehber metinleri için).
  static String localize(String text) {
    if (text.isEmpty) return text;
    final lower = text.toLowerCase();
    if (lower.contains('ücretsiz') ||
        lower.contains('ucretsiz') ||
        lower.contains('free')) {
      return text;
    }

    var result = text;

    result = result.replaceAllMapped(
      RegExp(r'(\d+(?:[.,]\d+)?)\s*([–\-])\s*(\d+(?:[.,]\d+)?)\s*€'),
      (m) {
        final lo = _parseNum(m.group(1)!) * eurToTl;
        final hi = _parseNum(m.group(3)!) * eurToTl;
        return '${formatNum(lo)}${m.group(2)!}${formatNum(hi)}';
      },
    );

    result = result.replaceAllMapped(
      RegExp(r'€\s*(\d+(?:[.,]\d+)?)\s*([–\-])\s*(\d+(?:[.,]\d+)?)'),
      (m) {
        final lo = _parseNum(m.group(1)!) * eurToTl;
        final hi = _parseNum(m.group(3)!) * eurToTl;
        return '${formatNum(lo)}${m.group(2)!}${formatNum(hi)}';
      },
    );

    result = result.replaceAllMapped(
      RegExp(r'(\d+(?:[.,]\d+)?)\s*€'),
      (m) => formatNum(_parseNum(m.group(1)!) * eurToTl),
    );

    result = result.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d{3})+)\s*([+]?)\s*HUF', caseSensitive: false),
      (m) {
        final huf = _parseHuf(m.group(1)!);
        final plus = m.group(2) ?? '';
        return '${formatNum(huf * hufToTl)}$plus';
      },
    );

    result = result.replaceAllMapped(
      RegExp(r'(\d+(?:[.,]\d+)?)\s*([–\-])\s*(\d+(?:\.\d{3})+)\s*HUF', caseSensitive: false),
      (m) {
        final lo = _parseHuf(m.group(1)!) * hufToTl;
        final hi = _parseHuf(m.group(3)!) * hufToTl;
        return '${formatNum(lo)}${m.group(2)!}${formatNum(hi)}';
      },
    );

    result = result.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d{3})+)\s*([–\-])\s*(\d+(?:\.\d{3})+)\s*HUF', caseSensitive: false),
      (m) {
        final lo = _parseHuf(m.group(1)!) * hufToTl;
        final hi = _parseHuf(m.group(3)!) * hufToTl;
        return '${formatNum(lo)}${m.group(2)!}${formatNum(hi)}';
      },
    );

    result = result.replaceAllMapped(
      RegExp(r'(\d+(?:[.,]\d+)?)\s*EUR', caseSensitive: false),
      (m) => formatNum(_parseNum(m.group(1)!) * eurToTl),
    );

    return result;
  }

  static double _parseNum(String raw) {
    final s = raw.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s) ?? 0;
  }

  static double _parseHuf(String raw) {
    final cleaned = raw.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0;
  }
}
