/// Destinasyon IATA → tatil türü etiketleri (gerçek turizm profili).
class DestinationVibes {
  static const _map = {
    'AYT': ['beach', 'family', 'wellness', 'budget'],
    'IST': ['city', 'culture', 'romantic', 'luxury', 'shopping'],
    'ATH': ['culture', 'beach', 'city', 'romantic'],
    'BCN': ['beach', 'culture', 'city', 'shopping'],
    'AMS': ['city', 'culture', 'romantic', 'shopping'],
    'BER': ['city', 'culture', 'budget', 'shopping'],
    'BUD': ['culture', 'city', 'wellness', 'budget'],
    'LIS': ['beach', 'culture', 'city', 'romantic'],
    'DXB': ['luxury', 'city', 'beach', 'family', 'shopping'],
    'DPS': ['beach', 'nature', 'wellness', 'romantic'],
    'JFK': ['city', 'culture', 'luxury'],
    'PAR': ['city', 'culture', 'romantic', 'luxury', 'shopping'],
    'ROM': ['culture', 'city', 'romantic', 'shopping'],
    'PRG': ['culture', 'city', 'budget'],
    'VIE': ['culture', 'city', 'wellness'],
    'MIL': ['culture', 'city', 'luxury', 'shopping'],
    'MAD': ['culture', 'city', 'budget', 'shopping'],
    'LON': ['city', 'culture', 'luxury', 'shopping'],
    'SGN': ['culture', 'city', 'budget', 'adventure'],
    'BKK': ['beach', 'culture', 'wellness', 'budget'],
    'TYO': ['city', 'culture', 'adventure'],
    'CAI': ['culture', 'city', 'adventure'],
    'RAK': ['culture', 'city', 'adventure', 'wellness'],
    'TBS': ['culture', 'nature', 'adventure', 'budget'],
    'TIV': ['beach', 'nature', 'adventure', 'budget'],
    'HER': ['beach', 'culture', 'family'],
    'CFU': ['beach', 'nature', 'family'],
    'RHO': ['beach', 'culture', 'family'],
    'BJV': ['beach', 'culture', 'wellness'],
    'DLM': ['beach', 'nature', 'adventure'],
    'GZP': ['beach', 'nature', 'adventure'],
    'ESB': ['city', 'culture', 'budget'],
    'ADB': ['beach', 'city', 'culture'],
  };

  static List<String> forIata(String iata, {String? vibeBadge}) {
    final code = iata.toUpperCase();
    final fromMap = _map[code];
    if (fromMap != null) return List<String>.from(fromMap);

    if (vibeBadge != null && vibeBadge.isNotEmpty) {
      return _parseBadge(vibeBadge);
    }
    return ['city'];
  }

  static List<String> _parseBadge(String badge) {
    final lower = badge.toLowerCase();
    final found = <String>[];
    const keywords = {
      'deniz': 'beach',
      'beach': 'beach',
      'kültür': 'culture',
      'culture': 'culture',
      'doğa': 'nature',
      'nature': 'nature',
      'şehir': 'city',
      'city': 'city',
      'lüks': 'luxury',
      'luxury': 'luxury',
      'aile': 'family',
      'family': 'family',
      'macera': 'adventure',
      'romantik': 'romantic',
      'spa': 'wellness',
      'wellness': 'wellness',
      'alışveriş': 'shopping',
      'shopping': 'shopping',
      'ucuz': 'budget',
      'budget': 'budget',
    };
    for (final e in keywords.entries) {
      if (lower.contains(e.key)) found.add(e.value);
    }
    return found.isEmpty ? ['city'] : found.toSet().toList();
  }

  static bool matchesAll(String iata, List<String> selected, {String? vibeBadge}) {
    if (selected.isEmpty) return true;
    final vibes = forIata(iata, vibeBadge: vibeBadge).toSet();
    return selected.every(vibes.contains);
  }
}
