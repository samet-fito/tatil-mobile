/// Destinasyon görselleri — yerel asset öncelikli, ağ yedeği.
///
/// Dosya ekleme: `assets/images/destinations/{iata}.jpg` (küçük harf)
/// Örn: Barselona → `assets/images/destinations/bcn.jpg`
/// Sonra: `flutter pub get` (klasör zaten pubspec'te tanımlı)
class CityImages {
  CityImages._();

  static const String destinationsFolder = 'assets/images/destinations';
  static const String legacyAntalyaAsset = 'assets/images/antalya.jpg';

  static const Map<String, String> _network = {
    'IST':
        'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Hagia_Sophia_Mars_2013.jpg&width=960',
    'ATH':
        'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Acropolis_of_Athens_01361.JPG&width=960',
    'FCO':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Colosseo_2020.jpg/960px-Colosseo_2020.jpg',
    'BUD':
        'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Sz%C3%A9chenyi_Chain_Bridge_in_Budapest_at_night.jpg&width=960',
    'ADB':
        'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Clock_tower%2C_Izmir%2C_Turkey.jpg&width=960',
    'ESB': 'https://picsum.photos/seed/vizegoo-ankara/900/600',
    'BCN': 'https://picsum.photos/seed/vizegoo-barcelona/900/600',
    'CDG': 'https://picsum.photos/seed/vizegoo-paris/900/600',
    'LHR': 'https://picsum.photos/seed/vizegoo-london/900/600',
    'DXB': 'https://picsum.photos/seed/vizegoo-dubai/900/600',
    'AMS': 'https://picsum.photos/seed/vizegoo-amsterdam/900/600',
    'BER': 'https://picsum.photos/seed/vizegoo-berlin/900/600',
    'LIS': 'https://picsum.photos/seed/vizegoo-lisbon/900/600',
    'JFK': 'https://picsum.photos/seed/vizegoo-nyc/900/600',
    'NRT': 'https://picsum.photos/seed/vizegoo-tokyo/900/600',
    'DPS': 'https://picsum.photos/seed/vizegoo-bali/900/600',
    'HKT': 'https://picsum.photos/seed/vizegoo-phuket/900/600',
    'default': 'https://picsum.photos/seed/vizegoo-travel/900/600',
  };

  static const Map<String, String> landmarks = {
    'IST': 'Ayasofya, İstanbul',
    'AYT': 'Kaleiçi & Marina, Antalya',
    'ESB': 'Anıtkabir, Ankara',
    'ADB': 'Saat Kulesi, İzmir',
    'ATH': 'Akropolis, Atina',
    'FCO': 'Kolezyum, Roma',
    'BCN': 'Sagrada Família, Barselona',
    'CDG': 'Eyfel Kulesi, Paris',
    'LHR': 'Big Ben, Londra',
    'DXB': 'Burj Khalifa, Dubai',
    'AMS': 'Kanallar, Amsterdam',
    'BER': 'Brandenburg Kapısı, Berlin',
    'BUD': 'Chain Bridge, Budapeşte',
    'LIS': 'Belém Kulesi, Lizbon',
    'JFK': 'Manhattan, New York',
    'NRT': 'Shibuya, Tokyo',
    'DPS': 'Ubud, Bali',
    'HKT': 'Phi Phi, Phuket',
    'default': '',
  };

  /// Yerel dosya yolu — [DestinationHeroImage] önce bunu dener.
  static String assetPath(String iataCode) {
    final code = iataCode.isEmpty ? 'default' : iataCode.toUpperCase();
    if (code == 'default') {
      return '$destinationsFolder/default.jpg';
    }
    return '$destinationsFolder/${code.toLowerCase()}.jpg';
  }

  static String networkUrl(String iataCode) {
    final code = iataCode.isEmpty ? 'default' : iataCode.toUpperCase();
    return _network[code] ?? _network['default']!;
  }

  /// Geriye dönük uyumluluk.
  static String getImage(String iataCode) => networkUrl(iataCode);

  static bool isAssetImage(String iataCode) {
    final code = iataCode.toUpperCase();
    return code == 'AYT';
  }

  static String getLandmark(String iataCode) {
    if (iataCode.isEmpty) return '';
    return landmarks[iataCode.toUpperCase()] ?? landmarks['default']!;
  }

  static const List<DestinationInspirationSlide> localInspirationSlides = [
    DestinationInspirationSlide(
      iata: 'BCN',
      cityName: 'Barselona',
      tagline: 'Akdeniz ruhu, mimari harikalar',
    ),
    DestinationInspirationSlide(
      iata: 'FCO',
      cityName: 'Roma',
      tagline: 'Tarih ve lezzet bir arada',
    ),
    DestinationInspirationSlide(
      iata: 'ATH',
      cityName: 'Atina',
      tagline: 'Antik çağın izinde',
    ),
    DestinationInspirationSlide(
      iata: 'AYT',
      cityName: 'Antalya',
      tagline: 'Turkuaz koylar, güneş',
    ),
  ];

  static const List<DestinationImageBrief> downloadChecklist = [
    DestinationImageBrief('IST', 'İstanbul', 'Türkiye', 'Ayasofya veya Boğaz'),
    DestinationImageBrief('AYT', 'Antalya', 'Türkiye', 'Kaleiçi / marina'),
    DestinationImageBrief('ESB', 'Ankara', 'Türkiye', 'Anıtkabir'),
    DestinationImageBrief('ADB', 'İzmir', 'Türkiye', 'Saat Kulesi'),
    DestinationImageBrief('BCN', 'Barselona', 'İspanya', 'Sagrada Família'),
    DestinationImageBrief('FCO', 'Roma', 'İtalya', 'Kolezyum'),
    DestinationImageBrief('ATH', 'Atina', 'Yunanistan', 'Akropolis'),
    DestinationImageBrief('CDG', 'Paris', 'Fransa', 'Eyfel Kulesi'),
    DestinationImageBrief('AMS', 'Amsterdam', 'Hollanda', 'Kanallar'),
    DestinationImageBrief('LIS', 'Lizbon', 'Portekiz', 'Belém / tramvay'),
    DestinationImageBrief('BER', 'Berlin', 'Almanya', 'Brandenburg Kapısı'),
    DestinationImageBrief('BUD', 'Budapeşte', 'Macaristan', 'Parlamento'),
    DestinationImageBrief('DXB', 'Dubai', 'BAE', 'Burj Khalifa'),
    DestinationImageBrief('JFK', 'New York', 'ABD', 'Manhattan skyline'),
    DestinationImageBrief('NRT', 'Tokyo', 'Japonya', 'Shibuya veya Senso-ji'),
    DestinationImageBrief('DPS', 'Bali', 'Endonezya', 'Tegallalang / tapınak'),
    DestinationImageBrief('HKT', 'Phuket', 'Tayland', 'Turkuaz koy'),
    DestinationImageBrief('default', 'Genel hero', '—', 'Seyahat / dünya (ana ekran)'),
  ];
}

class DestinationInspirationSlide {
  final String iata;
  final String cityName;
  final String tagline;

  const DestinationInspirationSlide({
    required this.iata,
    required this.cityName,
    required this.tagline,
  });

  String get asset => CityImages.assetPath(iata);
  String get landmark => CityImages.getLandmark(iata);
}

class DestinationImageBrief {
  final String iata;
  final String city;
  final String country;
  final String subject;

  const DestinationImageBrief(this.iata, this.city, this.country, this.subject);
}
