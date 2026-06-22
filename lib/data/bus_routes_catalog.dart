/// Şehirler arası otobüs sefer kataloğu (canlı API entegrasyonu öncesi).
abstract final class BusRoutesCatalog {
  static const cities = [
    'İstanbul',
    'Ankara',
    'İzmir',
    'Antalya',
    'Bursa',
    'Adana',
    'Gaziantep',
    'Konya',
    'Trabzon',
    'Muğla',
  ];

  static const _operators = [
    'Kamil Koç',
    'Pamukkale',
    'Metro Turizm',
    'Ulusoy',
    'Varan',
  ];

  static List<Map<String, dynamic>> search({
    required String fromCity,
    required String toCity,
    required DateTime date,
    required int passengers,
  }) {
    if (fromCity == toCity) return [];

    final seed = fromCity.hashCode ^ toCity.hashCode ^ date.day;
    final basePrice = 280 + (seed.abs() % 420);
    final durationMin = 240 + (seed.abs() % 360);

    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < 5; i++) {
      final hour = 6 + i * 3 + (seed.abs() % 2);
      final dep = DateTime(date.year, date.month, date.day, hour.clamp(6, 22));
      final price = basePrice + i * 45 + (passengers > 1 ? 0 : 0);
      results.add({
        'id': 'bus-$fromCity-$toCity-$i',
        'operator': _operators[i % _operators.length],
        'fromCity': fromCity,
        'toCity': toCity,
        'departureTime': dep,
        'durationMinutes': durationMin + i * 15,
        'priceTL': price * passengers,
        'pricePerPersonTL': price,
        'passengers': passengers,
        'amenities': i.isEven
            ? ['Wi-Fi', 'USB', 'İkram']
            : ['USB', 'TV', 'Koltuk ekranı'],
        'seatType': i < 2 ? '2+1' : '2+2',
      });
    }

    results.sort(
      (a, b) => (a['pricePerPersonTL'] as int).compareTo(b['pricePerPersonTL'] as int),
    );
    return results;
  }
}
