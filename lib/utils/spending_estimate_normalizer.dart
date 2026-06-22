/// AI harcama JSON'unu tutarlı sayılara çevirir.
class SpendingEstimateNormalizer {
  SpendingEstimateNormalizer._();

  static int sumItemPrices(List<dynamic>? items) {
    if (items == null || items.isEmpty) return 0;
    var total = 0;
    for (final item in items) {
      if (item is! Map) continue;
      total += _asInt(item['priceTL']);
    }
    return total;
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  static String fmtTL(int value) =>
      '${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';

  static String dailyBreakdownLine(int dailyFood, int dailyTransport) =>
      'Yemek ~${fmtTL(dailyFood)} + Ulaşım ~${fmtTL(dailyTransport)}/kişi·gün';

  /// AI yanıtını normalize eder: kalem toplamları ile günlük tutarları eşleştirir.
  static Map<String, dynamic> normalizeAiPayload(
    Map<String, dynamic> aiData, {
    required String cityName,
    required int nights,
    required int people,
  }) {
    var dailyFood = _asInt(aiData['dailyFoodPerPersonTL']);
    var dailyTransport = _asInt(aiData['dailyTransportPerPersonTL']);

    final foodFromItems = sumItemPrices(aiData['foodItems'] as List?);
    final transportFromItems = sumItemPrices(aiData['transportItems'] as List?);
    if (foodFromItems > 0) dailyFood = foodFromItems;
    if (transportFromItems > 0) dailyTransport = transportFromItems;

    dailyFood = dailyFood.clamp(0, 999999);
    dailyTransport = dailyTransport.clamp(0, 999999);

    final perDay = dailyFood + dailyTransport;
    final totalFood = dailyFood * nights * people;
    final totalTransport = dailyTransport * nights * people;

    final foodScope = (aiData['foodScopeLabel'] as String? ?? '').trim();
    final transportScope = (aiData['transportScopeLabel'] as String? ?? '').trim();
    final aiNarrative = (aiData['foodSummary'] as String? ?? '').trim();
    final aiDisclaimer = (aiData['disclaimer'] as String? ?? '').trim();

    final scopeParts = <String>[
      if (foodScope.isNotEmpty) foodScope,
      if (transportScope.isNotEmpty) transportScope,
    ];

    final disclaimerParts = <String>[
      if (scopeParts.isNotEmpty) scopeParts.join(' · '),
      if (aiDisclaimer.isNotEmpty) aiDisclaimer,
      'Tutarlar kişi başı günlük yemek + yerel ulaşım toplamıdır (2026 TL tahmini).',
    ];

    return {
      'foodSummary': dailyBreakdownLine(dailyFood, dailyTransport),
      'foodItems': List<Map<String, dynamic>>.from(aiData['foodItems'] ?? []),
      'dailyFoodPerPersonTL': dailyFood,
      'totalFoodTL': totalFood,
      'dailyTransportPerPersonTL': dailyTransport,
      'estimatedLocalTransportTL': totalTransport,
      'effectivePeople': people,
      'foodScopeLabel': foodScope.isNotEmpty
          ? foodScope
          : (aiNarrative.isNotEmpty ? aiNarrative : 'Günlük yeme-içme ortalaması'),
      'transportScopeLabel':
          transportScope.isNotEmpty ? transportScope : 'Günlük yerel ulaşım payı',
      'attractions': const [],
      'totalAttractionsTL': 0,
      'localTransport': List<Map<String, dynamic>>.from(
        aiData['transportItems'] ?? [],
      ),
      'hotelRoutes': const [],
      'grandTotalTL': totalFood + totalTransport,
      'perPersonPerDayTL': perDay,
      'disclaimer': disclaimerParts.join(' '),
      'source': 'ai',
    };
  }
}
