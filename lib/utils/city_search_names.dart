/// Otel arama API'si için şehir adı eşlemesi (Booking.com İngilizce ad).
class CitySearchNames {
  static const _byIata = {
    'ATH': 'Athens',
    'AYT': 'Antalya',
    'IST': 'Istanbul',
    'SAW': 'Istanbul',
    'ESB': 'Ankara',
    'ADB': 'Izmir',
    'FCO': 'Rome',
    'ROM': 'Rome',
    'BCN': 'Barcelona',
    'PAR': 'Paris',
    'CDG': 'Paris',
    'LON': 'London',
    'LHR': 'London',
    'BUD': 'Budapest',
    'PRG': 'Prague',
    'VIE': 'Vienna',
    'AMS': 'Amsterdam',
    'DXB': 'Dubai',
    'BER': 'Berlin',
    'MUC': 'Munich',
    'ZRH': 'Zurich',
    'LIS': 'Lisbon',
    'MAD': 'Madrid',
    'NAP': 'Naples',
    'HER': 'Heraklion',
    'SKG': 'Thessaloniki',
  };

  static const _byTurkish = {
    'Atina': 'Athens',
    'Athens': 'Athens',
    'Antalya': 'Antalya',
    'İstanbul': 'Istanbul',
    'Istanbul': 'Istanbul',
    'Ankara': 'Ankara',
    'İzmir': 'Izmir',
    'Izmir': 'Izmir',
    'Roma': 'Rome',
    'Rome': 'Rome',
    'Budapeşte': 'Budapest',
    'Budapest': 'Budapest',
    'Barselona': 'Barcelona',
    'Barcelona': 'Barcelona',
    'Paris': 'Paris',
    'Londra': 'London',
    'London': 'London',
    'Prag': 'Prague',
    'Viyana': 'Vienna',
    'Amsterdam': 'Amsterdam',
    'Dubai': 'Dubai',
    'Berlin': 'Berlin',
  };

  static String forHotels(String cityName, String iata) {
    final code = iata.toUpperCase();
    if (_byIata.containsKey(code)) return _byIata[code]!;
    if (_byTurkish.containsKey(cityName)) return _byTurkish[cityName]!;
    return cityName;
  }

  /// Birden fazla ad dene (API boş dönerse).
  static List<String> hotelSearchCandidates(String cityName, String iata) {
    final seen = <String>{};
    final list = <String>[];
    void add(String s) {
      if (s.isNotEmpty && seen.add(s)) list.add(s);
    }
    add(forHotels(cityName, iata));
    add(cityName);
    add(iata.toUpperCase());
    return list;
  }
}
