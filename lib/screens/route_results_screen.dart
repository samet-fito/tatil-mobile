
import 'route_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/route_result_model.dart';
import '../models/search_model.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../widgets/route_result_card.dart';
import '../widgets/social_icon_buttons.dart';
import '../services/budget_orchestrator.dart';
import '../services/calendar_price_service.dart';
import '../models/budget_package_offer.dart';
import '../models/budget_search_outcome.dart';
import '../services/auth_service.dart';
import '../data/country_meta.dart';
import '../theme/custom_page_route.dart';
import '../utils/route_filter_engine.dart';
import '../widgets/loading_screen.dart';
import '../widgets/travel_state_view.dart';
import '../utils/consumer_copy.dart';
import '../city_images.dart';
import '../models/booking_scope.dart';
import '../widgets/flexible_travel_date_picker.dart';
import '../widgets/preview_mode_banner.dart';
import '../models/compare_route_snapshot.dart';
import '../screens/route_compare_screen.dart';
import '../screens/price_watch_screen.dart';
import '../services/price_watch_store.dart';

class RouteResultsScreen extends StatefulWidget {
  final SearchModel searchModel;
  final List<RouteResultModel>? initialRoutes;
  final BudgetSearchOutcome? initialOutcome;

  const RouteResultsScreen({
    super.key,
    required this.searchModel,
    this.initialRoutes,
    this.initialOutcome,
  });

  @override
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends State<RouteResultsScreen> {
  late SearchModel _searchModel;
  List<BudgetPackageOffer> _offers = [];
  bool _isLoading = true;
  bool _enrichingLive = false;
  String? _error;
  String? _filterBanner;
  int _liveEnrichedCount = 0;
  final List<CompareRouteSnapshot> _compareList = [];
  static const _maxCompare = 3;

  List<RouteResultModel> get _routes =>
      _offers.map((o) => o.route).toList();

  @override
  void initState() {
    super.initState();
    _searchModel = widget.searchModel;
    final outcome = widget.initialOutcome;
    if (outcome != null && outcome.isSuccess) {
      _isLoading = false;
      _applyOutcome(outcome);
      _startLiveEnrichIfNeeded();
      return;
    }

    final preloaded = widget.initialRoutes;
    if (preloaded != null && preloaded.isNotEmpty) {
      _isLoading = false;
      _applyOutcome(
        BudgetSearchOutcome(
          offers: preloaded
              .map(
                (route) => BudgetPackageOffer.fromPlan(
                  route: route,
                  userBudgetTL: _searchModel.hasBudget
                      ? _searchModel.totalBudgetTL.round()
                      : 0,
                ),
              )
              .toList(),
        ),
      );
      _startLiveEnrichIfNeeded();
    } else {
      _loadRoutes();
    }
  }

  void _startLiveEnrichIfNeeded() {
    if (_offers.isEmpty || _offers.every((o) => o.hasLivePackage)) return;
    _enrichLiveInBackground();
  }

  Future<void> _enrichLiveInBackground() async {
    if (_enrichingLive) return;
    setState(() => _enrichingLive = true);

    try {
      final updated = await BudgetOrchestrator.enrichOffersProgressively(
        model: _searchModel,
        offers: _offers,
        onUpdate: (offers) {
          if (!mounted) return;
          setState(() {
            _offers = offers;
            _liveEnrichedCount =
                offers.where((o) => o.hasLivePackage).length;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _offers = updated;
        _liveEnrichedCount =
            updated.where((o) => o.hasLivePackage).length;
        _enrichingLive = false;
      });
    } catch (_) {
      if (mounted) setState(() => _enrichingLive = false);
    }
  }

  void _applyOutcome(BudgetSearchOutcome outcome) {
    setState(() {
      _offers = outcome.offers;
      _filterBanner = outcome.bannerMessage;
      _liveEnrichedCount = outcome.liveEnrichedCount;
      _isLoading = false;
      _error = null;
    });
  }

  Future<void> _loadRoutes({bool forceNetwork = false}) async {
    CalendarPriceService.cancelPendingLoads();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final outcome = await BudgetOrchestrator.search(
        _searchModel,
        forceNetwork: forceNetwork,
        enrichLive: false,
      );

      if (!outcome.isSuccess) {
        if (mounted) {
          setState(() {
            _error = outcome.userMessage;
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        _applyOutcome(outcome);
        _startLiveEnrichIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Rotalar yüklenemedi.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatPrice(double price) {
    return '${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  static const _monthShort = [
    '',
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  String _fmtShortDate(DateTime d) =>
      '${d.day} ${_monthShort[d.month]}';

  String get _dateRangeLabel =>
      '${_fmtShortDate(_searchModel.departureDate)} – '
      '${_fmtShortDate(_searchModel.returnDate)} · '
      '${_searchModel.nights} gece';

  ({String iata, String city})? get _calendarDestination {
    final iata = _searchModel.destinationIata;
    final city = _searchModel.destinationCity;
    if (iata != null &&
        city != null &&
        iata.isNotEmpty &&
        city.isNotEmpty) {
      return (iata: iata, city: city);
    }
    if (_offers.isNotEmpty) {
      final route = _offers.first.route;
      return (iata: route.destinationIata, city: route.cityName);
    }
    return null;
  }

  Future<void> _openFlexibleDates() async {
    final dest = _calendarDestination;
    if (dest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Takvim fiyatları için önce rota listesi yüklenmeli.'),
        ),
      );
      return;
    }

    final picked = await showFlexibleTravelDatePicker(
      context,
      initialDeparture: _searchModel.departureDate,
      initialReturn: _searchModel.returnDate,
      originIata: _searchModel.originIata,
      destinationIata: dest.iata,
      destinationCity: dest.city,
      passengers: _searchModel.passengers,
      initialFlexibility: _searchModel.dateFlexibility,
      referenceCityLabel: _searchModel.destinationCity == null ? dest.city : null,
    );
    if (picked == null || !mounted) return;

    final unchanged = _sameDay(picked.departureDate, _searchModel.departureDate) &&
        _sameDay(picked.returnDate, _searchModel.returnDate) &&
        picked.flexibility == _searchModel.dateFlexibility;
    if (unchanged) return;

    setState(() {
      _searchModel = _searchModel.copyWith(
        departureDate: picked.departureDate,
        returnDate: picked.returnDate,
        dateFlexibility: picked.flexibility,
        destinationIata: _searchModel.destinationIata ?? dest.iata,
        destinationCity: _searchModel.destinationCity ?? dest.city,
      );
    });
    _loadRoutes(forceNetwork: true);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _openRouteDetail(
    BudgetPackageOffer offer, {
    BookingScope? checkoutScope,
  }) {
    pushAppRoute(
      context,
      RouteDetailScreen(
        route: offer.route,
        originIata: _searchModel.originIata,
        departureDate: _searchModel.departureDate,
        returnDate: _searchModel.returnDate,
        children: _searchModel.children,
        totalPassengers: _searchModel.passengers,
        checkoutScope: checkoutScope,
        autoOpenCheckout: checkoutScope != null,
        budgetOffer: offer.hasLivePackage ? offer : null,
        preferCheapest: _searchModel.sortByCheapest,
        userBudgetTL: _searchModel.hasBudget
            ? _searchModel.totalBudgetTL.round()
            : null,
        holidayTypes: _searchModel.holidayTypes,
      ),
    );
  }

  void _toggleCompare(BudgetPackageOffer offer) {
    final iata = offer.route.destinationIata;
    final existing = _compareList.indexWhere((r) => r.destinationIata == iata);
    setState(() {
      if (existing >= 0) {
        _compareList.removeAt(existing);
      } else if (_compareList.length < _maxCompare) {
        _compareList.add(CompareRouteSnapshot.fromOffer(offer));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('En fazla $_maxCompare rota karşılaştırabilirsiniz'),
            backgroundColor: AppTheme.orange,
          ),
        );
      }
    });
  }

  bool _isInCompare(String iata) =>
      _compareList.any((r) => r.destinationIata == iata);

  void _openCompare() {
    if (_compareList.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Karşılaştırmak için en az 2 rota seçin'),
          backgroundColor: AppTheme.orange,
        ),
      );
      return;
    }
    pushAppRoute(
      context,
      RouteCompareScreen(routes: List.unmodifiable(_compareList)),
    );
  }

  Future<void> _createPriceWatch(BudgetPackageOffer offer) async {
    await PriceWatchSheet.show(
      context,
      originIata: _searchModel.originIata,
      destinationIata: offer.route.destinationIata,
      cityName: offer.route.cityName,
      country: offer.route.country,
      departureDate: _searchModel.departureDate,
      returnDate: _searchModel.returnDate,
      currentPriceTL: offer.displayTotalTL,
      passengers: _searchModel.passengers,
      nights: offer.route.nights,
    );
    await PriceWatchStore.updateLastSeen(
      destinationIata: offer.route.destinationIata,
      priceTL: offer.displayTotalTL,
    );
  }

  bool get _isGuest => !AuthService.isLoggedIn;

  String get _searchHeadline {
    final destCity = _searchModel.destinationCity;
    if (destCity != null && destCity.isNotEmpty) return destCity;
    final destCountry = _searchModel.destinationCountry;
    if (destCountry != null && destCountry.isNotEmpty) {
      return CountryMeta.labelTr(destCountry);
    }
    return 'Rotalar';
  }

  String get _searchSubtitle {
    final parts = <String>[_searchModel.originCity, _dateRangeLabel];
    if (_searchModel.destinationCity == null &&
        _searchModel.destinationCountry == null) {
      parts.insert(1, 'Her yer');
    }
    if (_searchModel.hasBudget) {
      parts.add(_formatPrice(_searchModel.totalBudgetTL));
    }
    return parts.join(' · ');
  }

  String get _heroIata {
    final dest = _searchModel.destinationIata;
    if (dest != null && dest.isNotEmpty) return dest.toUpperCase();
    final slides = CityImages.localInspirationSlides;
    if (slides.isEmpty) return 'default';
    return slides[DateTime.now().minute % slides.length].iata;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingScreen(
        phase: LoadingPhase.routes,
        destinationIata: _searchModel.destinationIata,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _searchHeadline,
              style: TatilTheme.screenHeadline(fontSize: 18),
            ),
            Text(
              _searchSubtitle,
              style: TatilTheme.hint,
            ),
          ],
        ),
        actions: [
          if (_compareList.isNotEmpty)
            TextButton(
              onPressed: _openCompare,
              child: Text(
                'Karşılaştır (${_compareList.length})',
                style: const TextStyle(
                  color: AppTheme.teal,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(CupertinoIcons.bell, color: AppTheme.orange),
            tooltip: 'Fiyat alarmlarım',
            onPressed: () => pushAppRoute(context, const PriceWatchScreen()),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.calendar, color: AppTheme.teal),
            tooltip: 'Esnek tarih ve fiyatlar',
            onPressed: _openFlexibleDates,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, color: AppTheme.textMuted),
            onPressed: () => _loadRoutes(forceNetwork: true),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _compareList.isNotEmpty
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  border: Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_compareList.length}/$_maxCompare rota seçildi',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _compareList.clear()),
                      child: const Text('Temizle'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _openCompare,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Karşılaştır'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return TravelStateView(
        iataCode: _heroIata,
        icon: CupertinoIcons.exclamationmark_circle,
        title: 'Rotalar yüklenemedi',
        message: _error!,
        primaryLabel: 'Tekrar dene',
        onPrimary: () => _loadRoutes(forceNetwork: true),
        secondaryLabel: 'Aramayı düzenle',
        onSecondary: () => Navigator.pop(context),
      );
    }

    if (_routes.isEmpty) {
      return TravelStateView(
        iataCode: _heroIata,
        icon: CupertinoIcons.map,
        title: 'Bu bütçeye uygun rota yok',
        message:
            'Tarihleri genişletmeyi veya bütçeyi biraz artırmayı deneyin. '
            'Farklı bir destinasyon da yeni fırsatlar açabilir.',
        primaryLabel: 'Bütçeyi değiştir',
        onPrimary: () => Navigator.pop(context),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: PreviewModeBanner(compact: true),
        ),
        // Özet bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_routes.length} rota bulundu',
                    style: TatilTheme.sectionLabel.copyWith(fontSize: 13),
                  ),
                  if (_enrichingLive)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ConsumerCopy.liveEnriching,
                          style: TatilTheme.hint.copyWith(fontSize: 11),
                        ),
                      ],
                    )
                  else if (_liveEnrichedCount > 0)
                    Text(
                      ConsumerCopy.liveEnrichedCount(_liveEnrichedCount),
                      style: TatilTheme.hint.copyWith(
                        color: AppTheme.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _openFlexibleDates,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flight, size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      const Icon(Icons.hotel_rounded, size: 16, color: AppTheme.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _dateRangeLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'Takvim',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.teal,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: AppTheme.teal,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_filterBanner != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.orangeSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.orange.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppTheme.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _filterBanner!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.orange,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Misafir uyarısı
        if (_isGuest && _routes.length > 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: AppTheme.accent.withOpacity(0.08),
            child: Row(
              children: [
                const Icon(CupertinoIcons.lock_fill,
                    size: 14, color: AppTheme.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_routes.length - 3} rota kilitli. Tüm rotaları görmek için giriş yap.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showLoginSheet(),
                  child: const Text(
                    'Giriş Yap',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

// Rota listesi
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadRoutes(forceNetwork: true),
            color: AppTheme.accent,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: _routes.length,
              itemBuilder: (context, index) {
                final isLocked = _isGuest && index >= 3;

                if (isLocked) {
                  return _buildLockedCard(_routes[index]);
                }

                final offer = _offers[index];
                return RouteResultCard(
                  route: offer.route,
                  rank: index + 1,
                  budgetOffer: offer,
                  holidayTypes: _searchModel.holidayTypes,
                  departureDate: _searchModel.departureDate,
                  returnDate: _searchModel.returnDate,
                  upgradeWarning: offer.upgradeWarning,
                  serviceScore: RouteFilterEngine.serviceScore(offer.route),
                  isInCompare: _isInCompare(offer.route.destinationIata),
                  onCompareToggle: () => _toggleCompare(offer),
                  onPriceWatch: () => _createPriceWatch(offer),
                  onTap: () => _openRouteDetail(offer),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // KİLİTLİ KART (FOMO)
  // ============================================================
  Widget _buildLockedCard(RouteResultModel route) {
    return GestureDetector(
      onTap: _showLoginSheet,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Bulanık içerik
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.bgTertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppTheme.bgTertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 100,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.bgTertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),

              // Blur overlay
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgPrimary.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              // Kilit ikonu ve mesaj
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: AppTheme.accent.withOpacity(0.3)),
                      ),
                      child: const Icon(
                        CupertinoIcons.lock_fill,
                        color: AppTheme.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Fırsat Rota Kilitli',
                      style: TatilTheme.screenHeadline(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tek tıkla giriş yap ve kilidi aç',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            32, 24, 32, MediaQuery.of(context).padding.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Fırsat rotaların\nseni bekliyor',
              style: TatilTheme.screenHeadline(fontSize: 26),
            ),
            const SizedBox(height: 8),
            Text(
              '${_routes.length - 3} kilitli rota daha var. Giriş yap, tümünü gör.',
              style: TatilTheme.bodyMuted,
            ),
            const SizedBox(height: 28),
            Center(
              child: SocialIconButtons(
                onGoogle: () async {
                  Navigator.pop(ctx);
                  final success = await AuthService.signInWithGoogle();
                  if (!mounted) return;
                  if (success) {
                    setState(() {});
                    await _loadRoutes(forceNetwork: true);
                  }
                },
                onFacebook: () async {
                  Navigator.pop(ctx);
                  final success = await AuthService.signInWithFacebook();
                  if (!mounted) return;
                  if (success) {
                    setState(() {});
                    await _loadRoutes(forceNetwork: true);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const Text(
                  'Şimdi değil',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}