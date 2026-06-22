/// Destinasyon havalimanı + şehir merkezi koordinatları (mesafe / ulaşım tahmini).
class GeoPoint {
  const GeoPoint({
    required this.lat,
    required this.lng,
    required this.label,
  });

  final double lat;
  final double lng;
  final String label;
}

class DestinationGeo {
  const DestinationGeo({
    required this.iata,
    required this.airportName,
    required this.airportAddress,
    required this.airport,
    required this.cityCenter,
    required this.cityCenterLabel,
    this.metroLine,
  });

  final String iata;
  final String airportName;
  final String airportAddress;
  final GeoPoint airport;
  final GeoPoint cityCenter;
  final String cityCenterLabel;
  final String? metroLine;

  static DestinationGeo? forIata(String? iata) {
    if (iata == null || iata.isEmpty) return null;
    return byIata[iata.toUpperCase()];
  }

  static const Map<String, DestinationGeo> byIata = {
    'FCO': DestinationGeo(
      iata: 'FCO',
      airportName: 'Roma Fiumicino',
      airportAddress: 'Via dell\' Aeroporto di Fiumicino 320, 00054 Fiumicino RM, İtalya',
      airport: GeoPoint(lat: 41.8003, lng: 12.2389, label: 'FCO'),
      cityCenter: GeoPoint(lat: 41.9028, lng: 12.4964, label: 'Roma merkez'),
      cityCenterLabel: 'Pantheon / Roma merkez',
      metroLine: 'Leonardo Express → Termini',
    ),
    'IST': DestinationGeo(
      iata: 'IST',
      airportName: 'İstanbul Havalimanı',
      airportAddress: 'Tayakadın, Terminal Caddesi, Arnavutköy, İstanbul',
      airport: GeoPoint(lat: 41.2753, lng: 28.7519, label: 'IST'),
      cityCenter: GeoPoint(lat: 41.0082, lng: 28.9784, label: 'Sultanahmet'),
      cityCenterLabel: 'Sultanahmet / tarihi yarımada',
      metroLine: 'M11 havalimanı metrosu',
    ),
    'AYT': DestinationGeo(
      iata: 'AYT',
      airportName: 'Antalya Havalimanı',
      airportAddress: 'Yeşilköy, Muratpaşa, Antalya',
      airport: GeoPoint(lat: 36.8987, lng: 30.8005, label: 'AYT'),
      cityCenter: GeoPoint(lat: 36.8841, lng: 30.7056, label: 'Kaleiçi'),
      cityCenterLabel: 'Kaleiçi / marina',
    ),
    'ATH': DestinationGeo(
      iata: 'ATH',
      airportName: 'Atina Eleftherios Venizelos',
      airportAddress: 'Attica, Spata Artemida 190 04, Yunanistan',
      airport: GeoPoint(lat: 37.9364, lng: 23.9445, label: 'ATH'),
      cityCenter: GeoPoint(lat: 37.9715, lng: 23.7267, label: 'Syntagma'),
      cityCenterLabel: 'Syntagma / Akropolis bölgesi',
      metroLine: 'Metro Line 3 (M3)',
    ),
    'DXB': DestinationGeo(
      iata: 'DXB',
      airportName: 'Dubai International',
      airportAddress: 'Dubai International Airport, Dubai, BAE',
      airport: GeoPoint(lat: 25.2532, lng: 55.3657, label: 'DXB'),
      cityCenter: GeoPoint(lat: 25.1972, lng: 55.2744, label: 'Burj Khalifa'),
      cityCenterLabel: 'Downtown / Burj Khalifa',
      metroLine: 'Metro Red Line',
    ),
    'BCN': DestinationGeo(
      iata: 'BCN',
      airportName: 'Barcelona El Prat',
      airportAddress: '08820 El Prat de Llobregat, Barcelona, İspanya',
      airport: GeoPoint(lat: 41.2974, lng: 2.0833, label: 'BCN'),
      cityCenter: GeoPoint(lat: 41.3874, lng: 2.1686, label: 'Plaça Catalunya'),
      cityCenterLabel: 'Plaça Catalunya / Gotik',
      metroLine: 'Aerobús / L9 Sud',
    ),
    'CDG': DestinationGeo(
      iata: 'CDG',
      airportName: 'Paris Charles de Gaulle',
      airportAddress: '95700 Roissy-en-France, Fransa',
      airport: GeoPoint(lat: 49.0097, lng: 2.5479, label: 'CDG'),
      cityCenter: GeoPoint(lat: 48.8566, lng: 2.3522, label: 'Paris merkez'),
      cityCenterLabel: 'Louvre / şehir merkezi',
      metroLine: 'RER B',
    ),
  };
}
