/// Tatil türü seçenekleri — çoklu filtre için.
class HolidayTypes {
  static const options = [
    {'value': 'beach', 'label': 'Deniz', 'emoji': '🏖️'},
    {'value': 'culture', 'label': 'Kültür', 'emoji': '🏛️'},
    {'value': 'nature', 'label': 'Doğa', 'emoji': '🌿'},
    {'value': 'city', 'label': 'Şehir', 'emoji': '🏙️'},
    {'value': 'budget', 'label': 'Ucuz Tatil', 'emoji': '💸'},
    {'value': 'luxury', 'label': 'Lüks', 'emoji': '👑'},
    {'value': 'family', 'label': 'Aile', 'emoji': '👨‍👩‍👧'},
    {'value': 'adventure', 'label': 'Macera', 'emoji': '🧗'},
    {'value': 'romantic', 'label': 'Romantik', 'emoji': '💑'},
    {'value': 'shopping', 'label': 'Alışveriş', 'emoji': '🛍️'},
    {'value': 'wellness', 'label': 'Sağlık & Spa', 'emoji': '🧘'},
  ];

  static List<String> labelsOf(List<String> values) =>
      values.map(labelOf).toList();

  static String labelOf(String value) {
    for (final o in options) {
      if (o['value'] == value) return o['label'] as String;
    }
    return value;
  }
}
