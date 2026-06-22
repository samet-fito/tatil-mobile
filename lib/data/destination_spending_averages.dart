/// Şehir bazlı gerçekçi günlük yeme-içme + yerel ulaşım ortalamaları (TL / kişi / gün).
/// Kullanıcının arama bütçesinden bağımsızdır.
class DestinationSpendingAverages {
  DestinationSpendingAverages._();

  static const _defaultDaily = _Daily(food: 950, transport: 280);

  static const _byIata = {
    'AYT': _Daily(food: 680, transport: 180),
    'IST': _Daily(food: 720, transport: 200),
    'ESB': _Daily(food: 620, transport: 170),
    'ADB': _Daily(food: 650, transport: 175),
    'AMS': _Daily(food: 1850, transport: 420),
    'FCO': _Daily(food: 1450, transport: 380),
    'CDG': _Daily(food: 1600, transport: 400),
    'BCN': _Daily(food: 1350, transport: 340),
    'ATH': _Daily(food: 1200, transport: 300),
    'BER': _Daily(food: 1400, transport: 360),
    'LIS': _Daily(food: 1100, transport: 280),
    'BUD': _Daily(food: 900, transport: 240),
    'PRG': _Daily(food: 950, transport: 250),
    'VIE': _Daily(food: 1300, transport: 330),
    'DXB': _Daily(food: 1500, transport: 350),
    'LHR': _Daily(food: 1700, transport: 450),
    'JFK': _Daily(food: 2100, transport: 480),
    'NRT': _Daily(food: 1600, transport: 380),
    'BKK': _Daily(food: 750, transport: 200),
    'HKT': _Daily(food: 820, transport: 220),
    'DPS': _Daily(food: 700, transport: 180),
  };

  static const _byCountry = {
    'Turkey': _Daily(food: 700, transport: 190),
    'Netherlands': _Daily(food: 1850, transport: 420),
    'Italy': _Daily(food: 1450, transport: 380),
    'France': _Daily(food: 1600, transport: 400),
    'Spain': _Daily(food: 1350, transport: 340),
    'Greece': _Daily(food: 1200, transport: 300),
    'Germany': _Daily(food: 1400, transport: 360),
    'Portugal': _Daily(food: 1100, transport: 280),
    'Hungary': _Daily(food: 900, transport: 240),
    'United Kingdom': _Daily(food: 1700, transport: 450),
    'United States': _Daily(food: 2100, transport: 480),
    'Japan': _Daily(food: 1600, transport: 380),
    'Thailand': _Daily(food: 780, transport: 210),
    'Indonesia': _Daily(food: 700, transport: 180),
    'United Arab Emirates': _Daily(food: 1500, transport: 350),
  };

  static _Daily forDestination({
    required String iata,
    required String country,
    double? costIndex,
  }) {
    if (costIndex != null && costIndex > 0) {
      return _Daily(
        food: (costIndex * 22).round().clamp(400, 3500),
        transport: (costIndex * 7).round().clamp(120, 900),
      );
    }

    final code = iata.toUpperCase();
    return _byIata[code] ?? _byCountry[country] ?? _defaultDaily;
  }
}

class _Daily {
  const _Daily({required this.food, required this.transport});

  final int food;
  final int transport;

  int get total => food + transport;
}
