class CityImages {
  static const Map<String, String> images = {
    'AYT': 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&q=80',
    'IST': 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800&q=80',
    'ATH': 'https://images.unsplash.com/photo-1603565816030-6b389eeb23cb?w=800&q=80',
    'FCO': 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80',
    'BUD': 'https://images.unsplash.com/photo-1551867633-194f125bddfa?w=800&q=80',
    'ADB': 'https://images.unsplash.com/photo-1597212720158-dcc6e0f03a36?w=800&q=80',
    'ESB': 'https://images.unsplash.com/photo-1589561253898-768105ca91a8?w=800&q=80',
    'BCN': 'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?w=800&q=80',
    'CDG': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80',
    'LHR': 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80',
    'DXB': 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800&q=80',
    'default': 'https://images.unsplash.com/photo-1488085061387-422e29b40080?w=800&q=80',
  };

  static String getImage(String iataCode) {
    return images[iataCode.toUpperCase()] ?? images['default']!;
  }

  static const Map<String, String> landmarks = {
    'AYT': 'Kaleiçi, Antalya',
    'IST': 'Sultanahmet, İstanbul',
    'ATH': 'Akropolis, Atina',
    'FCO': 'Kolezyum, Roma',
    'BUD': 'Parlamento, Budapeşte',
    'ADB': 'Saat Kulesi, İzmir',
    'ESB': 'Anıtkabir, Ankara',
    'BCN': 'Sagrada Familia, Barselona',
    'CDG': 'Eyfel Kulesi, Paris',
    'LHR': 'Big Ben, Londra',
    'DXB': 'Burj Khalifa, Dubai',
    'default': '',
  };

  static String getLandmark(String iataCode) {
    return landmarks[iataCode.toUpperCase()] ?? '';
  }
}