/// Meşhur noktalar — otel mesafe haritası.
class FamousLandmark {
  const FamousLandmark({
    required this.lat,
    required this.lng,
    required this.name,
    this.emoji = '📍',
  });

  final double lat;
  final double lng;
  final String name;
  final String emoji;
}

class DestinationLandmarks {
  DestinationLandmarks._();

  static List<FamousLandmark> forIata(String iata) {
    switch (iata.toUpperCase()) {
      case 'DXB':
        return const [
          FamousLandmark(
            lat: 25.1972,
            lng: 55.2744,
            name: 'Burj Khalifa',
            emoji: '🏙️',
          ),
          FamousLandmark(
            lat: 25.1180,
            lng: 55.2006,
            name: 'Mall of the Emirates',
            emoji: '🛍️',
          ),
          FamousLandmark(
            lat: 25.0764,
            lng: 55.1328,
            name: 'Dubai Marina',
            emoji: '🌊',
          ),
          FamousLandmark(
            lat: 25.0452,
            lng: 55.1180,
            name: 'Ibn Battuta Mall',
            emoji: '🏬',
          ),
        ];
      case 'IST':
        return const [
          FamousLandmark(
            lat: 41.0086,
            lng: 28.9802,
            name: 'Sultanahmet',
            emoji: '🕌',
          ),
          FamousLandmark(
            lat: 41.0369,
            lng: 28.9850,
            name: 'Taksim',
            emoji: '🎭',
          ),
          FamousLandmark(
            lat: 41.0256,
            lng: 28.9744,
            name: 'Galata Kulesi',
            emoji: '🗼',
          ),
        ];
      case 'AYT':
        return const [
          FamousLandmark(
            lat: 36.8841,
            lng: 30.7056,
            name: 'Kaleiçi',
            emoji: '🏛️',
          ),
          FamousLandmark(
            lat: 36.8500,
            lng: 30.8500,
            name: 'Lara Plajı',
            emoji: '🏖️',
          ),
        ];
      case 'FCO':
        return const [
          FamousLandmark(
            lat: 41.8902,
            lng: 12.4922,
            name: 'Kolezyum',
            emoji: '🏟️',
          ),
          FamousLandmark(
            lat: 41.9029,
            lng: 12.4534,
            name: 'Vatikan',
            emoji: '⛪',
          ),
        ];
      case 'ATH':
        return const [
          FamousLandmark(
            lat: 37.9715,
            lng: 23.7267,
            name: 'Syntagma',
            emoji: '🏛️',
          ),
          FamousLandmark(
            lat: 37.9719,
            lng: 23.7267,
            name: 'Akropolis',
            emoji: '🏛️',
          ),
        ];
      default:
        return const [];
    }
  }
}
