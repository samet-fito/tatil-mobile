import '../data/destination_spending_averages.dart';
import '../models/spending_estimate_model.dart';
import '../utils/price_format.dart';

/// Destinasyon ortalamalarından harcama tahmini üretir (bütçe planından bağımsız).
class SpendingEstimateBuilder {
  static SpendingEstimate fromDestination({
    required String cityName,
    required String iata,
    required String country,
    required int nights,
    required int passengers,
    int children = 0,
    double? costIndex,
    List<Map<String, dynamic>> activityItems = const [],
  }) {
    final people = passengers + (children * 0.6).round().clamp(0, passengers);
    final n = nights.clamp(1, 365);
    final daily = DestinationSpendingAverages.forDestination(
      iata: iata,
      country: country,
      costIndex: costIndex,
    );

    final dailyFood = daily.food;
    final dailyTransport = daily.transport;

    final attractions = activityItems.map((a) {
      final priceTL = (a['priceTL'] as num?)?.toInt() ?? 0;
      return {
        'title': a['title'] ?? '',
        'subtitle': a['description'] ?? '',
        'priceLabel': priceTL > 0 ? PriceFormat.format(priceTL) : 'Ücretsiz',
        'estimatedTL': priceTL,
        'emoji': '🎯',
        'tip': a['duration']?.toString() ?? '',
      };
    }).toList();

    final totalFood = dailyFood * n * people;
    final totalTransport = dailyTransport * n * people;
    final grandTotal = totalFood + totalTransport;
    final perDay = dailyFood + dailyTransport;

    final indexNote = costIndex != null && costIndex > 0
        ? ' · maliyet endeksi ${costIndex.toStringAsFixed(1)}'
        : '';

    return SpendingEstimate(
      foodSummary:
          '$cityName için günlük yeme-içme ve ulaşım ortalaması$indexNote.',
      foodItems: const [],
      dailyFoodPerPersonTL: dailyFood,
      totalFoodTL: totalFood,
      dailyTransportPerPersonTL: dailyTransport,
      estimatedLocalTransportTL: totalTransport,
      effectivePeople: people,
      foodScopeLabel: 'Kahvaltı + öğle + akşam yemeği ortalaması',
      transportScopeLabel: 'Toplu taşıma + kısa taksi payı',
      attractions: attractions,
      totalAttractionsTL: 0,
      localTransport: const [],
      hotelRoutes: const [],
      grandTotalTL: grandTotal,
      perPersonPerDayTL: perDay,
      disclaimer:
          '2026 piyasa ortalaması; gerçek harcama tercihlerinize göre değişebilir. Ödeme toplamına dahil değildir.',
      source: costIndex != null ? 'index' : 'averages',
    );
  }
}
