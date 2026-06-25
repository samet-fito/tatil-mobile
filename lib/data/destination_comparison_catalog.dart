import '../models/destination_score_model.dart';

/// Popüler destinasyon karşılaştırma rehberleri (RouteVS tarzı).
class DestinationComparisonCatalog {
  DestinationComparisonCatalog._();

  static const _all = [
    DestinationComparisonGuide(
      leftIata: 'CDG',
      leftCity: 'Paris',
      rightIata: 'FCO',
      rightCity: 'Roma',
      title: 'Paris vs Roma: Sıradaki seyahatin için hangisi?',
      summary:
          'Paris, müze yoğunluğu ve şehir içi ulaşımda öne çıkarken Roma tarih, yemek ve açık hava atmosferi sunar.',
      isPopular: true,
    ),
    DestinationComparisonGuide(
      leftIata: 'BCN',
      leftCity: 'Barselona',
      rightIata: 'LIS',
      rightCity: 'Lizbon',
      title: 'Barselona vs Lizbon: Sahil ve kültür karşılaştırması',
      summary:
          'Barselona daha canlı gece hayatı ve mimari sunarken Lizbon daha uygun fiyatlı ve yürünebilir bir Avrupa kaçamağıdır.',
      isPopular: true,
    ),
    DestinationComparisonGuide(
      leftIata: 'AMS',
      leftCity: 'Amsterdam',
      rightIata: 'PRG',
      rightCity: 'Prag',
      title: 'Amsterdam vs Prag: Kısa kaçamak rehberi',
      summary:
          'Amsterdam kanal ve müze ağırlıklı; Prag ise orta Avrupa bütçesiyle tarih ve gece yaşamını birleştirir.',
    ),
    DestinationComparisonGuide(
      leftIata: 'ATH',
      leftCity: 'Atina',
      rightIata: 'BCN',
      rightCity: 'Barselona',
      title: 'Atina vs Barselona: Akdeniz rotası',
      summary:
          'Atina antik tarih ve adalar için ideal başlangıç; Barselona ise plaj + şehir kombinasyonu arayanlara uyar.',
    ),
    DestinationComparisonGuide(
      leftIata: 'IST',
      leftCity: 'İstanbul',
      rightIata: 'AYT',
      rightCity: 'Antalya',
      title: 'İstanbul vs Antalya: Türkiye içi tatil seçimi',
      summary:
          'İstanbul kültür ve gastronomi; Antalya deniz, resort ve aile tatili için daha uygun.',
      isPopular: true,
    ),
    DestinationComparisonGuide(
      leftIata: 'DXB',
      leftCity: 'Dubai',
      rightIata: 'BKK',
      rightCity: 'Bangkok',
      title: 'Dubai vs Bangkok: Uzun menzil karşılaştırması',
      summary:
          'Dubai lüks alışveriş ve modern mimari; Bangkok sokak yemeği, tapınaklar ve daha düşük yerel maliyet sunar.',
    ),
  ];

  static List<DestinationComparisonGuide> forIata(String iata) {
    final code = iata.toUpperCase();
    return _all
        .where((g) => g.leftIata == code || g.rightIata == code)
        .toList();
  }

  static List<DestinationComparisonGuide> popular({int limit = 4}) =>
      _all.where((g) => g.isPopular).take(limit).toList();
}
