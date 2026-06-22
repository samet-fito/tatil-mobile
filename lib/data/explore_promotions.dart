import '../models/search_category.dart';

/// Keşfet vitrini — kampanya ve bölgesel popüler rota fırsatları.
class ExploreCampaign {
  const ExploreCampaign({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.discountLabel,
    required this.category,
    this.daysLeft = 7,
    this.accentColor = 0xFFEA580C,
  });

  final String title;
  final String subtitle;
  final String code;
  final String discountLabel;
  final SearchCategory category;
  final int daysLeft;
  final int accentColor;
}

class ExploreQuickRoute {
  const ExploreQuickRoute({
    required this.label,
    required this.originIata,
    required this.originCity,
    required this.destinationIata,
    required this.destinationCity,
    required this.destinationCountry,
    required this.category,
    this.priceHint,
    this.badge,
  });

  final String label;
  final String originIata;
  final String originCity;
  final String destinationIata;
  final String destinationCity;
  final String destinationCountry;
  final SearchCategory category;
  final String? priceHint;
  final String? badge;
}

/// Popüler rota + son dakika birleşik kart — çıkış bölgesine göre filtrelenir.
class ExploreRegionalDeal {
  const ExploreRegionalDeal({
    required this.route,
    required this.priceLabel,
    required this.subtitle,
    required this.searchRank,
    this.hoursLeft,
    this.badge,
  });

  final ExploreQuickRoute route;
  final String priceLabel;
  final String subtitle;
  final int searchRank;
  final int? hoursLeft;
  final String? badge;

  bool get isUrgent => hoursLeft != null && hoursLeft! <= 48;
}

abstract final class ExplorePromotions {
  static const campaigns = [
    ExploreCampaign(
      title: 'Yaz tatili paketlerinde',
      subtitle: 'İlk rezervasyona özel',
      code: 'YAZ250',
      discountLabel: '250 TL indirim',
      category: SearchCategory.packageTour,
      daysLeft: 9,
    ),
    ExploreCampaign(
      title: 'Uçak biletlerinde',
      subtitle: 'Mobil uygulamaya özel',
      code: 'VIZE100',
      discountLabel: '100 TL indirim',
      category: SearchCategory.flight,
      daysLeft: 5,
      accentColor: 0xFF0D9488,
    ),
    ExploreCampaign(
      title: 'Aktivite rezervasyonunda',
      subtitle: 'Seçili turlarda geçerli',
      code: 'TUR50',
      discountLabel: '50 TL indirim',
      category: SearchCategory.activities,
      daysLeft: 12,
      accentColor: 0xFF7C3AED,
    ),
  ];

  static const _regionalDeals = [
  // ── İstanbul (IST) ──
    ExploreRegionalDeal(
      searchRank: 1,
      route: ExploreQuickRoute(
        label: 'İstanbul → Antalya',
        originIata: 'IST',
        originCity: 'İstanbul',
        destinationIata: 'AYT',
        destinationCity: 'Antalya',
        destinationCountry: 'Türkiye',
        category: SearchCategory.flight,
      ),
      priceLabel: '2.199 TL',
      subtitle: 'Yarın · direkt · en çok aranan',
      hoursLeft: 18,
      badge: 'Son dakika',
    ),
    ExploreRegionalDeal(
      searchRank: 2,
      route: ExploreQuickRoute(
        label: 'İstanbul → Ankara',
        originIata: 'IST',
        originCity: 'İstanbul',
        destinationIata: 'ESB',
        destinationCity: 'Ankara',
        destinationCountry: 'Türkiye',
        category: SearchCategory.flight,
      ),
      priceLabel: '~1.800 TL',
      subtitle: 'Günlük 120+ arama',
      badge: 'Popüler',
    ),
    ExploreRegionalDeal(
      searchRank: 3,
      route: ExploreQuickRoute(
        label: 'Antalya paket',
        originIata: 'IST',
        originCity: 'İstanbul',
        destinationIata: 'AYT',
        destinationCity: 'Antalya',
        destinationCountry: 'Türkiye',
        category: SearchCategory.packageTour,
      ),
      priceLabel: '18.900 TL',
      subtitle: 'Bu hafta sonu · 5 gece',
      hoursLeft: 36,
      badge: 'Paket',
    ),
    ExploreRegionalDeal(
      searchRank: 4,
      route: ExploreQuickRoute(
        label: 'İstanbul → İzmir',
        originIata: 'IST',
        originCity: 'İstanbul',
        destinationIata: 'ADB',
        destinationCity: 'İzmir',
        destinationCountry: 'Türkiye',
        category: SearchCategory.bus,
      ),
      priceLabel: '~450 TL',
      subtitle: 'Otobüs · her gün',
    ),
    ExploreRegionalDeal(
      searchRank: 5,
      route: ExploreQuickRoute(
        label: 'Kapadokya aktivite',
        originIata: 'IST',
        originCity: 'İstanbul',
        destinationIata: 'NAV',
        destinationCity: 'Kapadokya',
        destinationCountry: 'Türkiye',
        category: SearchCategory.activities,
      ),
      priceLabel: '750 TL\'den',
      subtitle: 'Balon & turlar',
      badge: 'Trend',
    ),
    // ── İzmir (ADB) ──
    ExploreRegionalDeal(
      searchRank: 1,
      route: ExploreQuickRoute(
        label: 'İzmir → İstanbul',
        originIata: 'ADB',
        originCity: 'İzmir',
        destinationIata: 'IST',
        destinationCity: 'İstanbul',
        destinationCountry: 'Türkiye',
        category: SearchCategory.flight,
      ),
      priceLabel: '1.650 TL',
      subtitle: '48 saat içinde · direkt',
      hoursLeft: 36,
      badge: 'Son dakika',
    ),
    ExploreRegionalDeal(
      searchRank: 2,
      route: ExploreQuickRoute(
        label: 'İzmir → Antalya',
        originIata: 'ADB',
        originCity: 'İzmir',
        destinationIata: 'AYT',
        destinationCity: 'Antalya',
        destinationCountry: 'Türkiye',
        category: SearchCategory.flight,
      ),
      priceLabel: '~2.100 TL',
      subtitle: 'Hafta sonu yoğun',
      badge: 'Popüler',
    ),
    ExploreRegionalDeal(
      searchRank: 3,
      route: ExploreQuickRoute(
        label: 'İzmir → Ankara',
        originIata: 'ADB',
        originCity: 'İzmir',
        destinationIata: 'ESB',
        destinationCity: 'Ankara',
        destinationCountry: 'Türkiye',
        category: SearchCategory.bus,
      ),
      priceLabel: '~380 TL',
      subtitle: 'Otobüs · sabah seferleri',
    ),
    // ── Antalya (AYT) ──
    ExploreRegionalDeal(
      searchRank: 1,
      route: ExploreQuickRoute(
        label: 'Antalya → İstanbul',
        originIata: 'AYT',
        originCity: 'Antalya',
        destinationIata: 'IST',
        destinationCity: 'İstanbul',
        destinationCountry: 'Türkiye',
        category: SearchCategory.flight,
      ),
      priceLabel: '2.050 TL',
      subtitle: 'Yarın · en çok aranan',
      hoursLeft: 22,
      badge: 'Son dakika',
    ),
    ExploreRegionalDeal(
      searchRank: 2,
      route: ExploreQuickRoute(
        label: 'Antalya aktivite',
        originIata: 'AYT',
        originCity: 'Antalya',
        destinationIata: 'AYT',
        destinationCity: 'Antalya',
        destinationCountry: 'Türkiye',
        category: SearchCategory.activities,
      ),
      priceLabel: '590 TL\'den',
      subtitle: 'Tekne & dalış turları',
      badge: 'Popüler',
    ),
    // ── Ankara (ESB) ──
    ExploreRegionalDeal(
      searchRank: 1,
      route: ExploreQuickRoute(
        label: 'Ankara → İstanbul',
        originIata: 'ESB',
        originCity: 'Ankara',
        destinationIata: 'IST',
        destinationCity: 'İstanbul',
        destinationCountry: 'Türkiye',
        category: SearchCategory.flight,
      ),
      priceLabel: '1.720 TL',
      subtitle: 'Günlük en yoğun rota',
      badge: 'Popüler',
    ),
    ExploreRegionalDeal(
      searchRank: 2,
      route: ExploreQuickRoute(
        label: 'Ankara → Antalya',
        originIata: 'ESB',
        originCity: 'Ankara',
        destinationIata: 'AYT',
        destinationCity: 'Antalya',
        destinationCountry: 'Türkiye',
        category: SearchCategory.flight,
      ),
      priceLabel: '~2.350 TL',
      subtitle: 'Hafta içi fırsat',
      hoursLeft: 40,
      badge: 'Son dakika',
    ),
    ExploreRegionalDeal(
      searchRank: 3,
      route: ExploreQuickRoute(
        label: 'Ankara paket',
        originIata: 'ESB',
        originCity: 'Ankara',
        destinationIata: 'AYT',
        destinationCity: 'Antalya',
        destinationCountry: 'Türkiye',
        category: SearchCategory.packageTour,
      ),
      priceLabel: '16.500 TL',
      subtitle: '4 gece · her şey dahil',
      badge: 'Paket',
    ),
    // ── Otel kategorisi ──
    ExploreRegionalDeal(
      searchRank: 1,
      route: ExploreQuickRoute(
        label: 'Antalya otelleri',
        originIata: 'IST',
        originCity: 'İstanbul',
        destinationIata: 'AYT',
        destinationCity: 'Antalya',
        destinationCountry: 'Türkiye',
        category: SearchCategory.hotel,
      ),
      priceLabel: '1.890 TL/gece',
      subtitle: 'Kampanyalı · %20 indirim',
      badge: 'Fırsat',
    ),
    ExploreRegionalDeal(
      searchRank: 2,
      route: ExploreQuickRoute(
        label: 'İstanbul şehir otelleri',
        originIata: 'IST',
        originCity: 'İstanbul',
        destinationIata: 'IST',
        destinationCity: 'İstanbul',
        destinationCountry: 'Türkiye',
        category: SearchCategory.hotel,
      ),
      priceLabel: '950 TL/gece',
      subtitle: 'Hafta içi konaklama',
    ),
    ExploreRegionalDeal(
      searchRank: 1,
      route: ExploreQuickRoute(
        label: 'İzmir konaklama',
        originIata: 'ADB',
        originCity: 'İzmir',
        destinationIata: 'ADB',
        destinationCity: 'İzmir',
        destinationCountry: 'Türkiye',
        category: SearchCategory.hotel,
      ),
      priceLabel: '780 TL/gece',
      subtitle: 'Alsancak & Kordon',
      badge: 'Popüler',
    ),
  ];

  /// Kategoriye uygun kampanyalar.
  static List<ExploreCampaign> campaignsFor(SearchCategory category) {
    final matched = campaigns.where((c) => c.category == category).toList();
    if (matched.isNotEmpty) return matched;
    if (category == SearchCategory.packageTour) {
      return campaigns
          .where((c) => c.category == SearchCategory.packageTour)
          .toList();
    }
    return campaigns.take(2).toList();
  }

  /// Kullanıcının çıkış noktası + arama kategorisine göre rotalar.
  static List<ExploreRegionalDeal> regionalDealsFor({
    required String originIata,
    required SearchCategory category,
    int limit = 6,
  }) {
    List<ExploreRegionalDeal> pick(String iata) {
      return _regionalDeals
          .where(
            (d) => d.route.originIata == iata && d.route.category == category,
          )
          .toList()
        ..sort((a, b) => a.searchRank.compareTo(b.searchRank));
    }

    var ranked = pick(originIata);
    if (ranked.isEmpty && category == SearchCategory.packageTour) {
      ranked = _regionalDeals
          .where(
            (d) =>
                d.route.originIata == originIata &&
                (d.route.category == SearchCategory.packageTour ||
                    d.route.category == SearchCategory.flight),
          )
          .toList()
        ..sort((a, b) => a.searchRank.compareTo(b.searchRank));
    }
    if (ranked.isEmpty) ranked = pick('IST');
    if (ranked.isEmpty) {
      ranked = _regionalDeals
          .where((d) => d.route.category == category)
          .toList()
        ..sort((a, b) => a.searchRank.compareTo(b.searchRank));
    }

    return ranked.take(limit).toList();
  }

  /// @deprecated Use [regionalDealsFor] with category.
  static List<ExploreRegionalDeal> regionalDealsForOrigin({
    required String originIata,
    int limit = 6,
  }) =>
      regionalDealsFor(originIata: originIata, category: SearchCategory.flight, limit: limit);

  static String? cityToOriginIata(String city) {
    final c = city.toLowerCase().trim();
    if (c.contains('istanbul')) return 'IST';
    if (c.contains('izmir')) return 'ADB';
    if (c.contains('antalya')) return 'AYT';
    if (c.contains('ankara')) return 'ESB';
    return null;
  }
}
