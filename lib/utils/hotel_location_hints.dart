/// Otel kartlarında gösterilecek konum ipuçları.
class HotelLocationHints {
  static String? forHotel(Map<String, dynamic> hotel, String cityName) {
    final hint = hotel['locationHint'] as String?;
    if (hint != null && hint.trim().isNotEmpty) return hint.trim();
    return forName(hotel['name'] as String? ?? '', cityName);
  }

  static String? forName(String hotelName, String cityName) {
    final name = hotelName.toLowerCase();
    final city = cityName.toLowerCase();

    if (city.contains('antalya') || city.contains('lara')) {
      if (name.contains('akra')) return 'Kaleiçi\'ne 10 dk';
      if (name.contains('rixos')) return 'Konyaaltı plajına yakın';
      if (name.contains('titanic') || name.contains('lara')) return 'Lara plajı önü';
      if (name.contains('kaleiçi') || name.contains('butik')) return 'Tarihi Kaleiçi içinde';
      return 'Sahil şeridine yakın';
    }
    if (city.contains('atina') || city.contains('athens')) {
      if (name.contains('bretagne') || name.contains('syntagma')) return 'Syntagma Meydanı\'na yakın';
      if (name.contains('plaka') || name.contains('pansiyon')) return 'Akropolis\'e yürüme mesafesi';
      if (name.contains('electra')) return 'Plaka mahallesinde';
      return 'Merkeze 15 dk';
    }
    if (city.contains('roma') || city.contains('rome')) {
      if (name.contains('hassler') || name.contains('spanish')) return 'İspanyol Merdivenleri\'ne yakın';
      if (name.contains('colosseum') || name.contains('kolezyum')) return 'Kolezyum\'a 5 dk yürüme';
      if (name.contains('navona')) return 'Piazza Navona\'ya yakın';
      return 'Tarihi merkeze yakın';
    }
    if (city.contains('budapeşte') || city.contains('budapest')) {
      if (name.contains('pulitzer') || name.contains('danube')) return 'Tuna kıyısında';
      if (name.contains('ruin') || name.contains('jewish')) return 'Büyük Sinagog\'a yakın';
      if (name.contains('chain') || name.contains('bridge')) return 'Zincir Köprü\'ye 5 dk';
      return 'Şehir merkezine yakın';
    }
    if (city.contains('dubai')) {
      if (name.contains('festival city')) return 'Festival City Mall\'a yakın';
      if (name.contains('downtown') || name.contains('address')) return 'Dubai Mall & Burj Khalifa bölgesi';
      if (name.contains('marina') || name.contains('jbr')) return 'Marina & JBR\'ye yakın';
      if (name.contains('emirates mall') || name.contains('barsha')) return 'Mall of the Emirates\'e yakın';
      if (name.contains('deira') || name.contains('city centre')) return 'Deira alışveriş bölgesi';
      return 'Dubai merkezine yakın';
    }
    if (city.contains('istanbul') || city.contains('İstanbul'.toLowerCase())) {
      if (name.contains('sultanahmet') || name.contains('four seasons')) {
        return 'Kapalıçarşı & Sultanahmet\'e yakın';
      }
      if (name.contains('taksim') || name.contains('gezi')) return 'İstiklal & Taksim\'e yakın';
      if (name.contains('zorlu') || name.contains('conrad')) return 'Zorlu Center\'a yakın';
      return 'Merkeze yakın';
    }
    return null;
  }
}
