import '../data/holiday_types.dart';
import '../utils/hotel_location_hints.dart';

/// Destinasyon + tatil türüne göre öne çıkan noktalar (rota & AI rehber).
class InterestPoint {
  const InterestPoint({
    required this.interest,
    required this.name,
    required this.area,
    required this.note,
    this.discountHint,
    this.hotelKeywords = const [],
  });

  final String interest;
  final String name;
  final String area;
  final String note;
  final String? discountHint;
  final List<String> hotelKeywords;
}

class DestinationInterestPois {
  DestinationInterestPois._();

  static const _catalog = <String, List<InterestPoint>>{
    'DXB': [
      InterestPoint(
        interest: 'shopping',
        name: 'The Dubai Mall',
        area: 'Downtown',
        note: 'Dünyanın en büyük AVM\'lerinden; Fashion Avenue lüks markalar.',
        discountHint: 'Dubai Shopping Festival (Ocak) ve yaz sezon sonu indirimleri.',
        hotelKeywords: ['downtown', 'address', 'burj', 'khalifa', 'emaar'],
      ),
      InterestPoint(
        interest: 'shopping',
        name: 'Mall of the Emirates',
        area: 'Al Barsha',
        note: 'Ski Dubai + premium markalar.',
        discountHint: 'Mart ve yaz outlet haftalarında ek indirimler.',
        hotelKeywords: ['emirates', 'barsha', 'kempinski', 'sheraton'],
      ),
      InterestPoint(
        interest: 'shopping',
        name: 'Dubai Festival City Mall',
        area: 'Festival City',
        note: 'Outlet ve aile dostu alışveriş.',
        discountHint: 'Festival City outlet köşesinde sezon indirimleri.',
        hotelKeywords: ['festival city', 'intercontinental festival', 'crowne plaza festival'],
      ),
      InterestPoint(
        interest: 'shopping',
        name: 'Ibn Battuta Mall',
        area: 'Jebel Ali',
        note: 'Temalı AVM, orta segment markalar.',
        hotelKeywords: ['ibn battuta', 'jebel ali', 'discovery gardens'],
      ),
      InterestPoint(
        interest: 'culture',
        name: 'Al Fahidi Tarihi Bölgesi',
        area: 'Bur Dubai',
        note: 'Geleneksel mimari ve müzeler.',
        hotelKeywords: ['bur dubai', 'creek', 'fahidi'],
      ),
      InterestPoint(
        interest: 'beach',
        name: 'JBR Walk & Kite Beach',
        area: 'Marina',
        note: 'Plaj + sahil yürüyüşü.',
        hotelKeywords: ['marina', 'jbr', 'walk', 'address marina'],
      ),
    ],
    'IST': [
      InterestPoint(
        interest: 'shopping',
        name: 'İstinye Park',
        area: 'Sarıyer',
        note: 'Açık hava AVM, premium markalar.',
        discountHint: 'Sezon geçişlerinde %20-40 indirim kampanyaları.',
        hotelKeywords: ['istinye', 'sarıyer', 'mövenpick', 'radisson blu şişli'],
      ),
      InterestPoint(
        interest: 'shopping',
        name: 'Zorlu Center',
        area: 'Beşiktaş',
        note: 'Lüks butik + sinema.',
        hotelKeywords: ['zorlu', 'beşiktaş', 'conrad', 'raffles'],
      ),
      InterestPoint(
        interest: 'shopping',
        name: 'Kapalıçarşı & Grand Bazaar',
        area: 'Fatih',
        note: 'Tarihi çarşı, pazarlık kültürü.',
        hotelKeywords: ['sultanahmet', 'fatih', 'eminönü', 'grand hyatt', 'four seasons sultanahmet'],
      ),
      InterestPoint(
        interest: 'culture',
        name: 'Ayasofya & Topkapı',
        area: 'Sultanahmet',
        note: 'UNESCO mirası.',
        hotelKeywords: ['sultanahmet', 'old city', 'tarihi yarımada'],
      ),
    ],
    'ROM': [
      InterestPoint(
        interest: 'shopping',
        name: 'Via del Corso',
        area: 'Centro Storico',
        note: 'Ana alışveriş caddesi.',
        discountHint: 'Temmuz-ağustos ve ocak indirim sezonları (saldi).',
        hotelKeywords: ['corso', 'spanish steps', 'piazza di spagna', 'hassler'],
      ),
      InterestPoint(
        interest: 'shopping',
        name: 'Castel Romano Designer Outlet',
        area: 'Outskirts',
        note: 'Designer outlet.',
        discountHint: 'Outlet fiyatları yıl boyu %30-70 arası.',
        hotelKeywords: ['termini', 'repubblica', 'central'],
      ),
      InterestPoint(
        interest: 'culture',
        name: 'Kolezyum & Forum Romanum',
        area: 'Centro',
        note: 'Antik Roma kalbi.',
        hotelKeywords: ['colosseum', 'kolezyum', 'monti', 'celio'],
      ),
    ],
    'PAR': [
      InterestPoint(
        interest: 'shopping',
        name: 'Galeries Lafayette',
        area: 'Opéra',
        note: 'İkonik lüks department store.',
        discountHint: 'Soldes (Ocak & Temmuz) %30-70 indirim.',
        hotelKeywords: ['opéra', 'haussmann', 'grands boulevards'],
      ),
      InterestPoint(
        interest: 'shopping',
        name: 'La Vallée Village',
        area: 'Disneyland bölgesi',
        note: 'Lüks outlet köyü.',
        hotelKeywords: ['disney', 'marne', 'central paris'],
      ),
      InterestPoint(
        interest: 'culture',
        name: 'Louvre & Musée d\'Orsay',
        area: '1.-7. arrondissement',
        note: 'Dünya klasikleri.',
        hotelKeywords: ['louvre', 'marais', 'saint-germain'],
      ),
    ],
    'LON': [
      InterestPoint(
        interest: 'shopping',
        name: 'Oxford Street & Regent Street',
        area: 'West End',
        note: 'High street alışveriş.',
        discountHint: 'Boxing Day (26 Aralık) ve yaz indirimleri.',
        hotelKeywords: ['oxford', 'marble arch', 'soho', 'mayfair'],
      ),
      InterestPoint(
        interest: 'shopping',
        name: 'Westfield London',
        area: 'White City',
        note: 'Büyük modern AVM.',
        hotelKeywords: ['white city', 'shepherd', 'kensington'],
      ),
    ],
    'BCN': [
      InterestPoint(
        interest: 'shopping',
        name: 'Passeig de Gràcia',
        area: 'Eixample',
        note: 'Modernist vitrinler + lüks markalar.',
        hotelKeywords: ['gràcia', 'gracia', 'passeig', 'eixample'],
      ),
      InterestPoint(
        interest: 'culture',
        name: 'Sagrada Familia & Gothic Quarter',
        area: 'Centro',
        note: 'Gaudi + gotik mahalle.',
        hotelKeywords: ['gothic', 'gotik', 'sagrada', 'born'],
      ),
    ],
    'AYT': [
      InterestPoint(
        interest: 'beach',
        name: 'Konyaaltı & Lara Plajları',
        area: 'Antalya',
        note: 'Ana plaj şeritleri.',
        hotelKeywords: ['konyaaltı', 'lara', 'beach', 'plaj'],
      ),
      InterestPoint(
        interest: 'shopping',
        name: 'Terracity & MarkAntalya',
        area: 'Antalya merkez',
        note: 'Şehir AVM\'leri.',
        hotelKeywords: ['markantalya', 'terracity', 'muratpaşa', 'şirinyalı'],
      ),
    ],
  };

  static List<InterestPoint> forDestination(
    String iata,
    List<String> interests,
  ) {
    if (interests.isEmpty) return const [];
    final code = iata.toUpperCase();
    final all = _catalog[code] ?? const [];
    final wanted = interests.toSet();
    return all.where((p) => wanted.contains(p.interest)).toList();
  }

  static bool hasPoints(String iata, List<String> interests) =>
      forDestination(iata, interests).isNotEmpty;

  static double hotelInterestScore(
    Map<String, dynamic> hotel,
    String cityName,
    String iata,
    List<String> interests,
  ) {
    if (interests.isEmpty) return 0;
    final name = (hotel['name'] as String? ?? '').toLowerCase();
    final hint =
        (HotelLocationHints.forHotel(hotel, cityName) ?? '').toLowerCase();
    final area = (hotel['area'] as String? ?? '').toLowerCase();
    final combined = '$name $hint $area';
    var score = 0.0;

    for (final poi in forDestination(iata, interests)) {
      for (final kw in poi.hotelKeywords) {
        if (combined.contains(kw.toLowerCase())) score += 1.5;
      }
    }
    return score;
  }

  static String routeSummary(String iata, List<String> interests) {
    final pois = forDestination(iata, interests);
    if (pois.isEmpty) return '';
    final labels = HolidayTypes.labelsOf(interests);
    final names = pois.take(4).map((p) => p.name).join(', ');
    return '${labels.join(' · ')} odaklı rota: $names';
  }

  /// AI rehber prompt bloğu — indirim ipuçları dahil.
  static String aiContext({
    required String iata,
    required String cityName,
    required List<String> interests,
  }) {
    if (interests.isEmpty) return '';
    final pois = forDestination(iata, interests);
    final labels = HolidayTypes.labelsOf(interests);
    final buf = StringBuffer()
      ..writeln('Kullanıcının seçtiği tatil türleri: ${labels.join(', ')}.')
      ..writeln(
        'Rehberde bu türlere özel ayrı bir "interests" bölümü oluştur; '
        'genel tavsiye değil, seçilen türe özel somut öneriler ver.',
      );

    if (pois.isEmpty) {
      buf.writeln(
        '$cityName için seçilen türlerde bilinen popüler noktaları '
        've güncel indirim/kampanya dönemlerini AI bilginle tamamla.',
      );
      return buf.toString();
    }

    buf.writeln('$cityName rotasında öne çıkan noktalar:');
    for (final p in pois) {
      buf.write('- ${p.name} (${p.area}): ${p.note}');
      if (p.discountHint != null && p.discountHint!.isNotEmpty) {
        buf.write(' İndirim/kampanya: ${p.discountHint}');
      }
      buf.writeln();
    }
    buf.writeln(
      'Alışveriş seçildiyse AVM isimleri, outlet fırsatları ve indirim '
      'dönemlerini mutlaka interests bölümünde belirt.',
    );
    return buf.toString();
  }
}
