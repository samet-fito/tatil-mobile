import '../utils/spending_estimate_normalizer.dart';

/// Tahmini harcama limitleri — güncel ortalama veriler.
class SpendingEstimate {
  final String foodSummary;
  final List<Map<String, dynamic>> foodItems;
  final int dailyFoodPerPersonTL;
  final int totalFoodTL;
  final int dailyTransportPerPersonTL;
  final int estimatedLocalTransportTL;
  final int effectivePeople;
  final String foodScopeLabel;
  final String transportScopeLabel;
  final List<Map<String, dynamic>> attractions;
  final int totalAttractionsTL;
  final List<Map<String, dynamic>> localTransport;
  final List<Map<String, dynamic>> hotelRoutes;
  final int grandTotalTL;
  final int perPersonPerDayTL;
  final String disclaimer;
  final String source;

  const SpendingEstimate({
    required this.foodSummary,
    required this.foodItems,
    required this.dailyFoodPerPersonTL,
    required this.totalFoodTL,
    required this.dailyTransportPerPersonTL,
    required this.estimatedLocalTransportTL,
    required this.effectivePeople,
    required this.foodScopeLabel,
    required this.transportScopeLabel,
    required this.attractions,
    required this.totalAttractionsTL,
    required this.localTransport,
    required this.hotelRoutes,
    required this.grandTotalTL,
    required this.perPersonPerDayTL,
    required this.disclaimer,
    this.source = 'route',
  });

  bool get isAiSource => source == 'ai';

  bool get isLiveSource =>
      source == 'activities' ||
      source == 'route' ||
      source == 'index' ||
      source == 'averages';

  String get sourceBadge => switch (source) {
        'activities' => 'Canlı API',
        'route' => 'Rota bütçesi',
        'index' => 'Destinasyon endeksi',
        'averages' => 'Şehir ortalaması',
        'ai' => 'AI tahmini',
        _ => 'Tahmin',
      };

  /// Tutarlı günlük döküm metni (yemek + ulaşım).
  String get dailyBreakdownLine => SpendingEstimateNormalizer.dailyBreakdownLine(
        dailyFoodPerPersonTL,
        dailyTransportPerPersonTL,
      );

  String get aiDailyHint => '✨ AI · $dailyBreakdownLine';

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? fallback;
  }

  factory SpendingEstimate.fromJson(Map<String, dynamic> json) {
    final dailyFood = _asInt(json['dailyFoodPerPersonTL']);
    final dailyTransport = _asInt(json['dailyTransportPerPersonTL']);
    final perDay = _asInt(json['perPersonPerDayTL']);
    final normalizedPerDay =
        perDay > 0 ? perDay : (dailyFood + dailyTransport).clamp(0, 999999);

    return SpendingEstimate(
      foodSummary: json['foodSummary'] as String? ??
          SpendingEstimateNormalizer.dailyBreakdownLine(
            dailyFood,
            dailyTransport,
          ),
      foodItems: List<Map<String, dynamic>>.from(json['foodItems'] ?? []),
      dailyFoodPerPersonTL: dailyFood,
      totalFoodTL: _asInt(json['totalFoodTL']),
      dailyTransportPerPersonTL: dailyTransport,
      estimatedLocalTransportTL: _asInt(json['estimatedLocalTransportTL']),
      effectivePeople: _asInt(json['effectivePeople'], 1),
      foodScopeLabel: json['foodScopeLabel'] as String? ?? 'kahvaltı + öğle yemeği',
      transportScopeLabel:
          json['transportScopeLabel'] as String? ?? 'toplu taşıma + taksi payı',
      attractions: List<Map<String, dynamic>>.from(json['attractions'] ?? []),
      totalAttractionsTL: _asInt(json['totalAttractionsTL']),
      localTransport: List<Map<String, dynamic>>.from(json['localTransport'] ?? []),
      hotelRoutes: List<Map<String, dynamic>>.from(json['hotelRoutes'] ?? []),
      grandTotalTL: _asInt(json['grandTotalTL']),
      perPersonPerDayTL: normalizedPerDay,
      disclaimer: json['disclaimer'] as String? ?? '',
      source: json['source'] as String? ?? 'route',
    );
  }
}
