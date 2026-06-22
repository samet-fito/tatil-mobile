import '../theme/custom_page_route.dart';
import 'checkout_screen.dart';
import 'flight_picker_screen.dart';
import 'hotel_picker_screen.dart';
import '../constants.dart';
import 'chat_screen.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/route_result_model.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../widgets/route_booking_summary.dart';
import '../widgets/expandable_live_selection_row.dart';
import '../widgets/partial_booking_options_sheet.dart';
import '../utils/selection_detail_resolver.dart';
import '../widgets/airport_transfer_card.dart';
import '../utils/live_offer_matcher.dart';
import '../utils/price_format.dart';
import '../utils/route_display_pricing.dart';
import '../utils/consumer_copy.dart';
import '../utils/flight_duration_format.dart';
import '../utils/flight_schedule_format.dart';
import '../widgets/holiday_type_match_hint.dart';
import '../widgets/hotel_visual_preview_card.dart';
import '../widgets/preview_mode_banner.dart';
import '../widgets/live_selection_skeleton.dart';
import '../models/booking_scope.dart';
import '../models/budget_package_offer.dart';
import '../utils/trip_locale.dart';
import '../services/trip_share_service.dart';
import '../services/smart_package_optimizer.dart';
import '../widgets/smart_package_insight_card.dart';
import 'price_watch_screen.dart';

class RouteDetailScreen extends StatefulWidget {
  final RouteResultModel route;
  final String originIata;
  final int children;
  final int totalPassengers;
  final DateTime departureDate;
  final DateTime returnDate;
  final BookingScope? checkoutScope;
  final bool autoOpenCheckout;
  final BudgetPackageOffer? budgetOffer;
  final bool preferCheapest;
  final int? userBudgetTL;
  final List<String> holidayTypes;

  const RouteDetailScreen({
    super.key,
    required this.route,
    required this.originIata,
    this.children = 0,
    this.totalPassengers = 1,
    required this.departureDate,
    required this.returnDate,
    this.checkoutScope,
    this.autoOpenCheckout = false,
    this.budgetOffer,
    this.preferCheapest = false,
    this.userBudgetTL,
    this.holidayTypes = const [],
  });

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  bool _showBudgetTips = false;
  bool _healthInsurance = false;
  bool _autoCheckoutAttempted = false;

List<Map<String, dynamic>> _realFlights = [];
bool _loadingFlights = true;
bool _flightsFromLive = false;

List<Map<String, dynamic>> _realHotels = [];
bool _loadingHotels = true;
bool _hotelsFromLive = false;

int _selectedFlightIndex = 0;
int _selectedHotelIndex = 0;
int _recommendedFlightIndex = 0;
int _recommendedHotelIndex = 0;
SmartPackageResult? _smartPackage;
bool _smartApplied = false;

Map<String, dynamic>? get _selectedFlight =>
    _realFlights.isNotEmpty ? _realFlights[_selectedFlightIndex] : null;

Map<String, dynamic>? get _selectedHotel =>
    _realHotels.isNotEmpty ? _realHotels[_selectedHotelIndex] : null;

void _computeRecommendation() {
  if (_realFlights.isEmpty && _realHotels.isEmpty) return;
  if (_realFlights.isNotEmpty && _realHotels.isNotEmpty) {
    _smartPackage = SmartPackageOptimizer.optimize(
      flights: _realFlights,
      hotels: _realHotels,
      route: widget.route,
      preferCheapest: widget.preferCheapest,
      holidayTypes: widget.holidayTypes,
    );
    _recommendedFlightIndex = _smartPackage!.flightIndex
        .clamp(0, _realFlights.length - 1);
    _recommendedHotelIndex = _smartPackage!.hotelIndex
        .clamp(0, _realHotels.length - 1);
    if (widget.budgetOffer?.isSmartOptimized == true && !_smartApplied) {
      _selectedFlightIndex = _recommendedFlightIndex;
      _selectedHotelIndex = _recommendedHotelIndex;
      _smartApplied = true;
    }
    return;
  }
  final selection = LiveOfferMatcher.bestPackageSelection(
    flights: _realFlights,
    hotels: _realHotels,
    route: widget.route,
    preferCheapest: widget.preferCheapest,
    holidayTypes: widget.holidayTypes,
  );
  if (_realFlights.isNotEmpty) {
    _recommendedFlightIndex =
        selection.flightIndex.clamp(0, _realFlights.length - 1);
  }
  if (_realHotels.isNotEmpty) {
    _recommendedHotelIndex =
        selection.hotelIndex.clamp(0, _realHotels.length - 1);
  }
}

void _applyDefaultSelection() {
  _computeRecommendation();
  _selectedFlightIndex = _recommendedFlightIndex;
  _selectedHotelIndex = _recommendedHotelIndex;
}

@override
void initState() {
  super.initState();
  final offer = widget.budgetOffer;
  if (offer != null && offer.hasLivePackage) {
    _applyPreloadedOffer(offer);
  } else {
    _loadPrices();
  }
}

void _applyPreloadedOffer(BudgetPackageOffer offer) {
  _realFlights = List<Map<String, dynamic>>.from(offer.liveFlights);
  _realHotels = List<Map<String, dynamic>>.from(offer.liveHotels);
  _flightsFromLive = offer.flightsFromLive;
  _hotelsFromLive = offer.hotelsFromLive;
  _computeRecommendation();
  if (widget.preferCheapest) {
    _selectedFlightIndex = _recommendedFlightIndex;
    _selectedHotelIndex = _recommendedHotelIndex;
  } else {
    _selectedFlightIndex =
        offer.liveFlightIndex.clamp(0, _realFlights.length - 1);
    _selectedHotelIndex =
        offer.liveHotelIndex.clamp(0, _realHotels.length - 1);
  }
  _loadingFlights = false;
  _loadingHotels = false;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      setState(() {});
      _maybeAutoOpenCheckout();
    }
  });
}

Future<void> _loadPrices() async {
  setState(() {
    _loadingFlights = true;
    _loadingHotels = true;
  });

  final dest = widget.route.destinationIata;
  List<Map<String, dynamic>> flights = [];
  List<Map<String, dynamic>> hotels = [];

  if (dest.isNotEmpty) {
    final travelers = widget.totalPassengers + widget.children;
    final results = await Future.wait([
      ApiService.searchRealFlights(
        originIata: widget.originIata,
        destinationIata: dest,
        departureDate: widget.departureDate,
        returnDate: widget.returnDate,
        passengers: travelers,
      ),
      ApiService.searchHotels(
        cityName: widget.route.cityName,
        checkIn: widget.departureDate,
        returnDate: widget.returnDate,
        adults: travelers,
        destinationIata: dest,
        planHotel: widget.route.hotel,
        nights: widget.route.nights,
        targetPerNightTL: RouteDisplayPricing.hotelPerNightTL(widget.route),
      ),
    ]);
    flights = results[0];
    hotels = results[1];
  }

  flights = LiveOfferMatcher.sortFlightsForDisplay(flights);
  hotels = LiveOfferMatcher.sortHotelsByPlanMatch(
    hotels: hotels,
    planHotel: widget.route.hotel,
    nights: widget.route.nights,
    targetPerNightTL: RouteDisplayPricing.hotelPerNightTL(widget.route),
    holidayTypes: widget.holidayTypes,
    destinationIata: widget.route.destinationIata,
    cityName: widget.route.cityName,
  );

  var flightsLive = flights.isNotEmpty;
  var hotelsLive = hotels.isNotEmpty;

  if (!mounted) return;
  setState(() {
    _realFlights = flights;
    _realHotels = hotels;
    _flightsFromLive = flightsLive;
    _hotelsFromLive = hotelsLive;
    _loadingFlights = false;
    _loadingHotels = false;
    _applyDefaultSelection();
  });
  _maybeAutoOpenCheckout();
}

  bool get _canCheckoutFlight =>
      !_loadingFlights &&
      _flightsFromLive &&
      _realFlights.isNotEmpty &&
      PriceFormat.hasRoundTripFlightPrice(_selectedFlight);

  bool get _canCheckoutHotel =>
      !_loadingHotels && _hotelsFromLive && _realHotels.isNotEmpty;

  bool get _canCheckoutPackage => _canCheckoutFlight && _canCheckoutHotel;

  void _maybeAutoOpenCheckout() {
    if (!widget.autoOpenCheckout ||
        widget.checkoutScope == null ||
        _autoCheckoutAttempted) {
      return;
    }
    _autoCheckoutAttempted = true;
    final scope = widget.checkoutScope!;
    final ready = switch (scope) {
      BookingScope.flightOnly => _canCheckoutFlight,
      BookingScope.hotelOnly => _canCheckoutHotel,
      BookingScope.package => _canCheckoutPackage,
    };
    if (!ready) {
      if (!mounted) return;
      final message = switch (scope) {
        BookingScope.flightOnly =>
          'Canlı uçuş fiyatı alınamadı. Detaydan tekrar deneyebilirsiniz.',
        BookingScope.hotelOnly =>
          'Canlı otel fiyatı alınamadı. Detaydan tekrar deneyebilirsiniz.',
        BookingScope.package =>
          'Canlı fiyatlar alınamadı. Lütfen tekrar deneyin.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.orange),
      );
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openCheckout(scope);
    });
  }

  void _openCheckout(BookingScope scope) {
    if (scope == BookingScope.package && !_canCheckoutPackage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uçuş ve otel fiyatları yükleniyor veya alınamadı.'),
          backgroundColor: AppTheme.orange,
        ),
      );
      return;
    }
    if (scope == BookingScope.flightOnly && !_canCheckoutFlight) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Canlı uçuş fiyatı alınamadı.'),
          backgroundColor: AppTheme.orange,
        ),
      );
      return;
    }
    if (scope == BookingScope.hotelOnly && !_canCheckoutHotel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Canlı otel fiyatı alınamadı.'),
          backgroundColor: AppTheme.orange,
        ),
      );
      return;
    }

    pushRouteResults(
      context,
      CheckoutScreen(
        originIata: widget.originIata,
        route: widget.route,
        flights: _realFlights,
        hotels: _realHotels,
        departureDate: widget.departureDate,
        returnDate: widget.returnDate,
        children: widget.children,
        adults: widget.totalPassengers,
        insuranceIncluded: _showInsurance && _healthInsurance,
        insuranceTotal: _insuranceTotal,
        scope: scope,
        initialFlightIndex: _selectedFlightIndex,
        initialHotelIndex: _selectedHotelIndex,
        preferCheapest: widget.preferCheapest,
        userBudgetTL: widget.userBudgetTL,
        holidayTypes: widget.holidayTypes,
      ),
    );
  }

  String _fmt(int price) => PriceFormat.format(price);

  int get _peopleCount => widget.totalPassengers + widget.children;

  bool get _showInsurance =>
      TripLocale.isInternational(country: widget.route.country);

  int get _insuranceTotal => AppConstants.insurancePrice * _peopleCount;

  int get _extrasTotal => _healthInsurance ? _insuranceTotal : 0;

  int get _liveHotelTL {
    final selected = _selectedHotel;
    if (selected == null) return 0;
    return PriceFormat.hotelTotalTL(selected, widget.route.nights);
  }

  int get _liveFlightTL {
    final selected = _selectedFlight;
    if (selected == null) return 0;
    return PriceFormat.roundTripFlightTL(selected);
  }

  int get _userBudgetTL => widget.userBudgetTL ?? 0;

  int get _recommendationPackageTL =>
      _liveFlightTL + _liveHotelTL + widget.route.estimatedCost.transfer;

  int get _remainingBudgetTL {
    final budget = _userBudgetTL;
    if (budget <= 0) return 0;
    final spent = _hasPrices ? _payableTotal : _recommendationPackageTL;
    final remaining = budget - spent;
    return remaining > 0 ? remaining : 0;
  }

  int get _budgetOverageTL {
    final budget = _userBudgetTL;
    if (budget <= 0) return 0;
    final spent = _hasPrices ? _payableTotal : _recommendationPackageTL;
    final over = spent - budget;
    return over > 0 ? over : 0;
  }

  bool get _showBudgetFootnote =>
      _hasPrices && widget.userBudgetTL != null && widget.userBudgetTL! > 0;

  bool get _hasPrices =>
      !_loadingFlights &&
      !_loadingHotels &&
      _flightsFromLive &&
      _hotelsFromLive &&
      _realFlights.isNotEmpty &&
      _realHotels.isNotEmpty &&
      PriceFormat.hasRoundTripFlightPrice(_selectedFlight);

  String get _priceSourceLabel => ConsumerCopy.priceSource(
        flightsLive: _flightsFromLive,
        hotelsLive: _hotelsFromLive,
        flightVerified: PriceFormat.hasRoundTripFlightPrice(_selectedFlight),
      );

  int get _payableTotal => _hasPrices
      ? PriceFormat.packagePayableTL(
          flightTL: _liveFlightTL,
          hotelTL: _liveHotelTL,
          transferTL: widget.route.estimatedCost.transfer,
          extrasTL: _extrasTotal,
        )
      : 0;

  @override
  Widget build(BuildContext context) {
    final route = widget.route;

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
            Text(route.cityName, style: TatilTheme.destination(fontSize: 18)),
            Text(
              '${route.country} · ${route.nights} gece',
              style: TatilTheme.hint,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.bell, color: AppTheme.orange),
            tooltip: 'Fiyat alarmı',
            onPressed: () => PriceWatchSheet.show(
              context,
              originIata: widget.originIata,
              destinationIata: widget.route.destinationIata,
              cityName: widget.route.cityName,
              country: widget.route.country,
              departureDate: widget.departureDate,
              returnDate: widget.returnDate,
              currentPriceTL: widget.budgetOffer?.displayTotalTL ??
                  _recommendationPackageTL,
              passengers: widget.totalPassengers,
              nights: widget.route.nights,
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.share, color: AppTheme.textMuted),
            tooltip: 'Paylaş',
            onPressed: () => TripShareService.shareRoute(
              cityName: widget.route.cityName,
              country: widget.route.country,
              nights: widget.route.nights,
              totalPriceTL: widget.budgetOffer?.displayTotalTL ??
                  _recommendationPackageTL,
              originCity: widget.originIata,
              hotelName: _selectedHotel?['name']?.toString(),
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.chat_bubble, color: AppTheme.teal),
            onPressed: () => pushAppRoute(
              context,
              ChatScreen(
                cityName: route.cityName,
                destinationIata: route.destinationIata,
                sessionId: widget.originIata,
                remainingBudget: 0,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ConsumerCopy.totalLabel,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _hasPrices ? _fmt(_payableTotal) : '—',
                      style: TatilTheme.priceDisplay(fontSize: 20),
                    ),
                    if (_showBudgetFootnote) ...[
                      const SizedBox(height: 2),
                      Text(
                        _budgetOverageTL > 0
                            ? 'Bütçe aşımı ${_fmt(_budgetOverageTL)}'
                            : 'Bütçeden geriye kalan ${_fmt(_remainingBudgetTL)}',
                        style: TatilTheme.hint.copyWith(
                          fontSize: 10,
                          color: _budgetOverageTL > 0 ? AppTheme.orange : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
               onTap: () {
  if (_loadingFlights || _loadingHotels) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Uçuş ve otel fiyatları yükleniyor, lütfen bekleyin…'),
        backgroundColor: AppTheme.teal,
      ),
    );
    return;
  }
  if (!_canCheckoutPackage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _realFlights.isEmpty && _realHotels.isEmpty
              ? 'Canlı uçuş ve otel fiyatı alınamadı. Lütfen tekrar deneyin.'
              : !_flightsFromLive
                  ? 'Canlı uçuş fiyatı alınamadı.'
                  : 'Canlı otel fiyatı alınamadı.',
        ),
        backgroundColor: AppTheme.orange,
      ),
    );
    return;
  }
  _openCheckout(BookingScope.package);
},
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.orange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('Rezervasyon Yap',
                        style: TextStyle(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PreviewModeBanner(compact: true),
            const SizedBox(height: 8),
            RouteBookingSummary(
              route: route,
              departureDate: widget.departureDate,
              returnDate: widget.returnDate,
              passengers: widget.totalPassengers,
              children: widget.children,
              liveFlights: _realFlights,
              liveHotels: _realHotels,
              loadingLive: _loadingFlights || _loadingHotels,
              extrasTL: _extrasTotal,
              priceSourceLabel: _priceSourceLabel,
              flightsFromLive: _flightsFromLive,
              hotelsFromLive: _hotelsFromLive,
              selectedFlight: _selectedFlight,
              selectedHotel: _selectedHotel,
              recommendationHint: widget.preferCheapest
                  ? 'En uygun paket önerimiz'
                  : 'Planınıza en yakın paket',
              userBudgetTL: widget.userBudgetTL,
            ),
            if (_smartPackage != null &&
                _smartPackage!.isOptimized &&
                _realFlights.isNotEmpty &&
                _realHotels.isNotEmpty) ...[
              const SizedBox(height: 12),
              SmartPackageInsightCard(
                savingsTL: _smartPackage!.savingsTL,
                insight: _smartPackage!.insight,
                totalTL: _smartPackage!.totalTL,
                applied: _smartApplied,
                onApply: _smartApplied
                    ? null
                    : () {
                        setState(() {
                          _selectedFlightIndex = _recommendedFlightIndex;
                          _selectedHotelIndex = _recommendedHotelIndex;
                          _smartApplied = true;
                        });
                      },
              ),
            ],
            const SizedBox(height: 12),
            _buildBookingHints(route.cityName),
            const SizedBox(height: 16),
            if (_showInsurance) ...[
              _buildOptionalExtras(),
              const SizedBox(height: 16),
            ],
            if (!route.isAffordable || route.alternativeSuggestion != null)
              _buildBudgetAccordion(),
            AirportTransferCard(
              iata: route.destinationIata.isNotEmpty ? route.destinationIata : 'AYT',
              cityName: route.cityName,
              hotelName: route.hotel?.name,
              routeTransfer: route.transfer,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Uçuş'),
            const SizedBox(height: 10),
            _buildSelectedFlightRow(),
            if (_canCheckoutFlight) ...[
              const SizedBox(height: 4),
              _partialPurchaseLink(
                label: 'Sadece uçuş biletini al',
                scope: BookingScope.flightOnly,
                amountTL: _liveFlightTL,
                detailLine:
                    '${widget.totalPassengers + widget.children} yolcu · gidiş-dönüş',
              ),
            ],
            const SizedBox(height: 20),
            _buildSectionTitle('Otel'),
            const SizedBox(height: 10),
            _buildSelectedHotelRow(),
            if (_canCheckoutHotel) ...[
              const SizedBox(height: 4),
              _partialPurchaseLink(
                label: 'Sadece otel rezervasyonu yap',
                scope: BookingScope.hotelOnly,
                amountTL: _liveHotelTL,
                detailLine: '${widget.route.nights} gece · 1 oda',
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingHints(String cityName) {
    final hasHolidayTypes = widget.holidayTypes.isNotEmpty;
    final message = hasHolidayTypes
        ? '${HolidayTypeMatchHint.message}. Rezervasyonu tamamladıktan sonra '
            '$cityName için kişiye özel rehber hazırlanır.'
        : 'Rezervasyonu tamamladıktan sonra $cityName için kişiye özel '
            'destinasyon rehberi hazırlanır.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(CupertinoIcons.gift, size: 18, color: AppTheme.teal),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TatilTheme.hint.copyWith(fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalExtras() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _extraToggle(
            icon: CupertinoIcons.heart_fill,
            iconColor: AppTheme.orange,
            title: 'Seyahat Sağlık Sigortası',
            subtitle: 'Acil tedavi ve iptal güvencesi · kişi başı',
            priceLabel: '+${_fmt(_insuranceTotal)}',
            value: _healthInsurance,
            onChanged: (v) => setState(() => _healthInsurance = v),
          ),
        ],
      ),
    );
  }

  Widget _extraToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String priceLabel,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  priceLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.orange,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppTheme.orange,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetAccordion() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.orangeSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showBudgetTips = !_showBudgetTips),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: AppTheme.orange, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Bütçeni esnet, bu rotayı yakala',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.orange)),
                  ),
                  Icon(
                      _showBudgetTips
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      color: AppTheme.orange,
                      size: 16),
                ],
              ),
            ),
          ),
          if (_showBudgetTips) ...[
            Divider(height: 1, color: AppTheme.orange.withValues(alpha: 0.25)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _tipRow('Çarşamba yerine Perşembe uçarsan uçak %12 ucuzluyor'),
                const SizedBox(height: 8),
                _tipRow('4 yıldızlı yerine butik otel seçersen 1.200 TL tasarruf edersin'),
                const SizedBox(height: 8),
                _tipRow('1 gece azaltırsan paket bütçene tam oturuyor'),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tipRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•', style: TextStyle(color: AppTheme.orange, fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, color: AppTheme.orange.withValues(alpha: 0.85), height: 1.4))),
      ],
    );
  }

  Widget _partialPurchaseLink({
    required String label,
    required BookingScope scope,
    required int amountTL,
    required String detailLine,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => showPartialBookingOptionsSheet(
          context,
          scope: scope,
          cityName: widget.route.cityName,
          amountTL: amountTL,
          detailLine: detailLine,
          onBuyOnly: () => _openCheckout(scope),
        ),
        child: Text(
          label,
          style: TatilTheme.hint.copyWith(
            color: AppTheme.teal,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _openFlightPicker() async {
    if (_realFlights.isEmpty) return;
    final picked = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => FlightPickerScreen(
          flights: _realFlights,
          selectedIndex: _selectedFlightIndex,
          recommendedIndex: _recommendedFlightIndex,
          originIata: widget.originIata,
          destinationCity: widget.route.cityName,
          departureDate: widget.departureDate,
          returnDate: widget.returnDate,
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedFlightIndex = picked);
    }
  }

  Future<void> _openHotelPicker() async {
    if (_realHotels.isEmpty) return;
    final picked = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => HotelPickerScreen(
          hotels: _realHotels,
          route: widget.route,
          selectedIndex: _selectedHotelIndex,
          recommendedIndex: _recommendedHotelIndex,
          departureDate: widget.departureDate,
          returnDate: widget.returnDate,
          preferCheapest: widget.preferCheapest,
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedHotelIndex = picked);
    }
  }

  Widget _buildSelectedFlightRow() {
    if (_loadingFlights) {
      return const LiveSelectionSkeleton();
    }
    if (_realFlights.isEmpty) {
      return _liveUnavailableCard(
        ConsumerCopy.flightUnavailableTitle,
        ConsumerCopy.flightUnavailableBody,
      );
    }
    final flight = _selectedFlight!;
    final stops = flight['stops'];
    final destIata = widget.route.destinationIata.isNotEmpty
        ? widget.route.destinationIata
        : widget.originIata;
    final timesLine = FlightScheduleFormat.roundTripTimesLine(
      flight,
      widget.departureDate,
      widget.returnDate,
    );
    final travelers = widget.totalPassengers + widget.children;
    final flightTL = PriceFormat.roundTripFlightTL(flight);
    final perPersonLabel = travelers > 0 && flightTL > 0
        ? '${PriceFormat.format((flightTL / travelers).round())}/kişi'
        : null;
    return ExpandableLiveSelectionRow(
      icon: CupertinoIcons.airplane,
      iconColor: AppTheme.teal,
      title: flight['airline']?.toString() ?? 'Uçuş',
      sourceIsLive:
          _flightsFromLive && PriceFormat.hasRoundTripFlightPrice(flight),
      subtitle: [
        if (timesLine.isNotEmpty) timesLine,
        '${widget.originIata} → $destIata',
        stops == 0 ? 'Direkt' : '$stops aktarma',
        FlightDurationFormat.label(flight['duration']),
        'Gidiş-dönüş',
        '${widget.departureDate.day}.${widget.departureDate.month} – '
            '${widget.returnDate.day}.${widget.returnDate.month}',
      ].join(' · '),
      priceLabel: PriceFormat.formatRoundTripFlightPrice(flight) ?? '',
      priceSecondaryLabel: perPersonLabel,
      onChange: _openFlightPicker,
      detailsTitle: 'Uçuş ve havalimanı ulaşım detayları',
      details: SelectionDetailResolver.flightDetails(
        flight: flight,
        originIata: widget.originIata,
        destinationIata: destIata,
        destinationCity: widget.route.cityName,
        hotel: _selectedHotel,
        departureDate: widget.departureDate,
        returnDate: widget.returnDate,
      ),
    );
  }

  Widget _buildSelectedHotelRow() {
    if (_loadingHotels) {
      return const LiveSelectionSkeleton(lines: 3);
    }
    if (_realHotels.isEmpty) {
      return _liveUnavailableCard(
        ConsumerCopy.hotelUnavailableTitle,
        ConsumerCopy.hotelUnavailableBody,
      );
    }
    final hotel = _selectedHotel!;
    return HotelVisualPreviewCard(
      hotel: hotel,
      cityName: widget.route.cityName,
      destinationIata: widget.route.destinationIata,
      checkIn: widget.departureDate,
      checkOut: widget.returnDate,
      nights: widget.route.nights,
      sourceIsLive: _hotelsFromLive,
      onChange: _openHotelPicker,
    );
  }

  Widget _liveUnavailableCard(String title, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.orangeSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.orange,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TatilTheme.sectionHeadline);
  }
}