/// Yurtiçi / yurtdışı seyahat ayrımı.
abstract final class TripLocale {
  static bool isDomesticCountry(String? country) {
    if (country == null || country.trim().isEmpty) return false;
    final c = country.toLowerCase();
    return c.contains('türkiye') ||
        c.contains('turkey') ||
        c == 'tr' ||
        c == 'tur';
  }

  static bool isInternational({
    String? country,
    String? destinationCountry,
  }) {
    final c = destinationCountry ?? country;
    if (c == null || c.trim().isEmpty) return true;
    return !isDomesticCountry(c);
  }
}
