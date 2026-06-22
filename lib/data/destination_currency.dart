/// 14+ destinasyon yerel para birimi — advisor & kur metni.
class DestinationCurrency {
  DestinationCurrency._();

  static const Map<String, String> _byIata = {
    'FCO': 'EUR', 'BCN': 'EUR', 'CDG': 'EUR', 'AMS': 'EUR', 'BER': 'EUR',
    'LIS': 'EUR', 'BUD': 'EUR', 'ATH': 'EUR',
    'LHR': 'GBP',
    'DXB': 'AED',
    'JFK': 'USD',
    'NRT': 'JPY',
    'DPS': 'IDR',
    'HKT': 'THB',
    'IST': 'TRY', 'AYT': 'TRY', 'ADB': 'TRY', 'ESB': 'TRY', 'SAW': 'TRY',
  };

  static String forIata(String iata) =>
      _byIata[iata.toUpperCase()] ?? 'EUR';
}
