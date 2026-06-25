import 'package:flutter/foundation.dart';

/// Keşfet / destinasyon arama — 3 katmanlı filtre state'i.
class DestinationFilterState extends ChangeNotifier {
  final Set<String> regions = {};
  final Set<String> travelStyles = {};
  final Set<String> costTiers = {};

  static const regionOptions = [
    ('europe', 'Europe'),
    ('asia', 'Asia'),
    ('north_america', 'North America'),
    ('caribbean', 'Caribbean'),
    ('south_america', 'South America'),
    ('middle_east', 'Middle East'),
    ('africa', 'Africa'),
    ('oceania', 'Oceania'),
  ];

  static const travelStyleOptions = [
    ('budget', 'Budget'),
    ('couples', 'Couples'),
    ('family', 'Family'),
    ('food', 'Food'),
    ('culture', 'Culture'),
    ('beach', 'Beach'),
    ('luxury', 'Luxury'),
  ];

  static const costOptions = [
    ('budget', 'Budget'),
    ('mid_range', 'Mid-range'),
    ('premium', 'Premium'),
    ('luxury', 'Luxury'),
  ];

  int get activeCount => regions.length + travelStyles.length + costTiers.length;

  bool get hasActiveFilters => activeCount > 0;

  void toggleRegion(String id) {
    if (regions.contains(id)) {
      regions.remove(id);
    } else {
      regions.add(id);
    }
    notifyListeners();
  }

  void toggleTravelStyle(String id) {
    if (travelStyles.contains(id)) {
      travelStyles.remove(id);
    } else {
      travelStyles.add(id);
    }
    notifyListeners();
  }

  void toggleCost(String id) {
    if (costTiers.contains(id)) {
      costTiers.remove(id);
    } else {
      costTiers.add(id);
    }
    notifyListeners();
  }

  void clearAll() {
    regions.clear();
    travelStyles.clear();
    costTiers.clear();
    notifyListeners();
  }

  void applyFrom({
    String? continent,
    Iterable<String> holidayTypes = const [],
    Iterable<String> costs = const [],
  }) {
    regions
      ..clear()
      ..addAll(_continentToRegions(continent));
    travelStyles
      ..clear()
      ..addAll(_holidayTypesToStyles(holidayTypes));
    costTiers
      ..clear()
      ..addAll(costs);
    notifyListeners();
  }

  /// SearchModel / CountryMeta ile uyumlu tek bölge.
  String? primaryContinent() {
    if (regions.isEmpty) return null;
    return _regionToContinent(regions.first);
  }

  List<String> toHolidayTypes() {
    return travelStyles.map(_styleToHolidayType).whereType<String>().toList();
  }

  /// Aktivite fiyatı (TRY) — seçili bütçe katmanlarına uyuyor mu?
  bool matchesActivityPrice(int priceTL) {
    if (costTiers.isEmpty) return true;
    for (final tier in costTiers) {
      if (_priceInTier(priceTL, tier)) return true;
    }
    return false;
  }

  /// Aktivite kategorisi — seyahat stiline uyuyor mu?
  bool matchesActivityCategory(String? categoryId) {
    if (travelStyles.isEmpty) return true;
    final cat = (categoryId ?? '').toLowerCase();
    for (final style in travelStyles) {
      if (_categoryMatchesStyle(cat, style)) return true;
    }
    return false;
  }

  static String? _regionToContinent(String region) {
    const map = {
      'europe': 'europe',
      'asia': 'asia',
      'north_america': 'americas',
      'caribbean': 'americas',
      'south_america': 'americas',
      'middle_east': 'middle_east',
      'africa': 'africa',
      'oceania': 'oceania',
    };
    return map[region];
  }

  static Set<String> _continentToRegions(String? continent) {
    if (continent == null) return {};
    const reverse = {
      'europe': 'europe',
      'asia': 'asia',
      'americas': 'north_america',
      'middle_east': 'middle_east',
      'africa': 'africa',
      'oceania': 'oceania',
      'domestic': 'europe',
    };
    final r = reverse[continent];
    return r == null ? {} : {r};
  }

  static String? _styleToHolidayType(String style) {
    const map = {
      'budget': 'budget',
      'couples': 'romantic',
      'family': 'family',
      'food': 'shopping',
      'culture': 'culture',
      'beach': 'beach',
      'luxury': 'luxury',
    };
    return map[style];
  }

  static Set<String> _holidayTypesToStyles(Iterable<String> types) {
    const reverse = {
      'budget': 'budget',
      'romantic': 'couples',
      'family': 'family',
      'shopping': 'food',
      'culture': 'culture',
      'beach': 'beach',
      'luxury': 'luxury',
    };
    return types.map((t) => reverse[t]).whereType<String>().toSet();
  }

  static bool _priceInTier(int price, String tier) {
    switch (tier) {
      case 'budget':
        return price < 800;
      case 'mid_range':
        return price >= 800 && price < 2000;
      case 'premium':
        return price >= 2000 && price < 5000;
      case 'luxury':
        return price >= 5000;
      default:
        return true;
    }
  }

  static bool _categoryMatchesStyle(String category, String style) {
    const map = {
      'budget': {'tours', 'museums'},
      'couples': {'tours', 'food', 'events'},
      'family': {'tours', 'adventure', 'museums'},
      'food': {'food'},
      'culture': {'museums', 'tours'},
      'beach': {'adventure', 'tours'},
      'luxury': {'tours', 'food', 'events'},
    };
    final allowed = map[style];
    if (allowed == null) return true;
    return allowed.contains(category);
  }
}
