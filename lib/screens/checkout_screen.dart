import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../models/route_result_model.dart';
import '../utils/hotel_location_hints.dart';
import '../utils/live_offer_matcher.dart';
import '../utils/price_format.dart';
import '../utils/plan_price_anchor.dart';
import '../utils/consumer_copy.dart';
import '../utils/flight_duration_format.dart';
import '../utils/flight_schedule_format.dart';
import '../utils/passenger_age.dart';
import '../services/travel_booking_service.dart';
import '../models/booking_scope.dart';
import '../models/flight_cabin_class.dart';
import '../models/search_category.dart';
import 'booking_success_screen.dart';
import 'flight_picker_screen.dart';
import 'hotel_picker_screen.dart';
import '../config/app_experience.dart';
import '../constants.dart';
import '../utils/checkout_ancillary_pricing.dart';
import '../utils/installment_plans.dart';
import '../widgets/checkout_ancillary_row.dart';
import '../widgets/checkout_coupon_section.dart';
import '../services/payment_service.dart';
import '../widgets/payment_3d_secure_sheet.dart';
import '../widgets/checkout_trust_footer.dart';
import '../widgets/live_selection_row.dart';
import '../widgets/offer_data_badge.dart';
import '../widgets/checkout_auth_sheet.dart';
import '../widgets/partial_booking_options_sheet.dart';
import '../utils/trip_locale.dart';
import '../models/flight_leg.dart';

class CheckoutScreen extends StatefulWidget {
  final String originIata;
  final RouteResultModel route;
  final List<Map<String, dynamic>> flights;
  final List<Map<String, dynamic>> hotels;
  final DateTime departureDate;
  final DateTime returnDate;
  final int children;
  final int adults;
  final bool insuranceIncluded;
  final int insuranceTotal;
  final BookingScope scope;
  final int? initialFlightIndex;
  final int? initialHotelIndex;
  final bool preferCheapest;
  final int? userBudgetTL;
  final List<String> holidayTypes;
  final bool isRoundTrip;
  final FlightCabinClass cabinClass;
  final String? initialCouponCode;
  final List<FlightLeg>? multiCityLegs;

  const CheckoutScreen({
    super.key,
    required this.originIata,
    required this.route,
    required this.flights,
    required this.hotels,
    required this.departureDate,
    required this.returnDate,
    required this.children,
    required this.adults,
    this.insuranceIncluded = false,
    this.insuranceTotal = 0,
    this.scope = BookingScope.package,
    this.initialFlightIndex,
    this.initialHotelIndex,
    this.preferCheapest = false,
    this.userBudgetTL,
    this.holidayTypes = const [],
    this.isRoundTrip = true,
    this.cabinClass = FlightCabinClass.economy,
    this.initialCouponCode,
    this.multiCityLegs,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final List<CheckoutFlowStep> _flow;
  int _stepIndex = 0;
  int _selectedFlightIndex = 0;
  int _selectedHotelIndex = 0;
  int _recommendedFlightIndex = 0;
  int _recommendedHotelIndex = 0;
  final _cardCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  List<Map<String, TextEditingController>> _passengerControllers = [];
  late List<String> _genders;
  late List<String> _nationalities;
  String _paymentMethod = 'credit';
  int? _installmentMonths;

  late bool _insuranceSelected;
  bool _airportTransferSelected = false;
  bool _rentCarSelected = false;
  bool _extraBaggageSelected = false;
  bool _ticketProtectionSelected = false;
  bool _flexTicketSelected = false;
  int _couponDiscountTL = 0;
  String? _appliedCouponCode;

  static const _genderOptions = ['Erkek', 'Kadın'];
  static const _nationalityOptions = [
    'Türkiye', 'Almanya', 'İngiltere', 'Fransa', 'İtalya', 'Yunanistan', 'ABD', 'Diğer',
  ];
  static const _paymentMethods = [
    {'id': 'credit', 'label': 'Kredi Kartı', 'icon': CupertinoIcons.creditcard},
    {'id': 'debit', 'label': 'Banka Kartı', 'icon': CupertinoIcons.money_dollar_circle},
    {'id': 'installment', 'label': 'Taksitli Ödeme', 'icon': CupertinoIcons.calendar},
    {'id': 'transfer', 'label': 'Havale / EFT', 'icon': CupertinoIcons.building_2_fill},
    {'id': 'mobile', 'label': 'Apple Pay / Google Pay', 'icon': CupertinoIcons.device_phone_portrait},
  ];

@override
void initState() {
    super.initState();
    _flow = checkoutFlowFor(widget.scope);
    final total = widget.adults + widget.children;
    _genders = List.filled(total, 'Erkek');
    _nationalities = List.filled(total, 'Türkiye');
    _passengerControllers = List.generate(
      total,
      (_) => {
        'name': TextEditingController(),
        'surname': TextEditingController(),
        'birthDate': TextEditingController(),
        'documentNumber': TextEditingController(),
        'passportExpiry': TextEditingController(),
        'email': TextEditingController(),
        'phone': TextEditingController(),
      },
    );
    final packageSelection = LiveOfferMatcher.bestPackageSelection(
      flights: widget.flights,
      hotels: widget.hotels,
      route: widget.route,
      preferCheapest: widget.preferCheapest,
    );
    _recommendedFlightIndex = widget.flights.isEmpty
        ? 0
        : packageSelection.flightIndex.clamp(0, widget.flights.length - 1);
    _recommendedHotelIndex = widget.hotels.isEmpty
        ? 0
        : packageSelection.hotelIndex.clamp(0, widget.hotels.length - 1);
    _selectedFlightIndex = widget.initialFlightIndex ?? _recommendedFlightIndex;
    _selectedHotelIndex = widget.initialHotelIndex ?? _recommendedHotelIndex;
    _insuranceSelected = widget.insuranceIncluded && _showInsurance;

    if (widget.scope == BookingScope.package &&
        PlanPriceAnchor.isHotelOutOfBand(_selectedHotel, widget.route)) {
      final hotelStep = _flow.indexOf(CheckoutFlowStep.hotel);
      if (hotelStep >= 0) _stepIndex = hotelStep;
    }
  }

  bool _isProcessing = false;
  String _countryCode = '+90';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+90', 'flag': '🇹🇷', 'name': 'Turkiye'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'ABD'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'Ingiltere'},
    {'code': '+49', 'flag': '🇩🇪', 'name': 'Almanya'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'Fransa'},
    {'code': '+39', 'flag': '🇮🇹', 'name': 'Italya'},
    {'code': '+34', 'flag': '🇪🇸', 'name': 'Ispanya'},
    {'code': '+31', 'flag': '🇳🇱', 'name': 'Hollanda'},
    {'code': '+7', 'flag': '🇷🇺', 'name': 'Rusya'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'BAE'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'Suudi Arabistan'},
    {'code': '+81', 'flag': '🇯🇵', 'name': 'Japonya'},
    {'code': '+86', 'flag': '🇨🇳', 'name': 'Cin'},
    {'code': '+91', 'flag': '🇮🇳', 'name': 'Hindistan'},
    {'code': '+61', 'flag': '🇦🇺', 'name': 'Avustralya'},
    {'code': '+55', 'flag': '🇧🇷', 'name': 'Brezilya'},
    {'code': '+30', 'flag': '🇬🇷', 'name': 'Yunanistan'},
    {'code': '+36', 'flag': '🇭🇺', 'name': 'Macaristan'},
  ];

  Map<String, dynamic>? get _selectedFlight =>
      widget.flights.isNotEmpty ? widget.flights[_selectedFlightIndex] : null;

  Map<String, dynamic>? get _selectedHotel =>
      widget.hotels.isNotEmpty ? widget.hotels[_selectedHotelIndex] : null;

  int get _flightPriceTL => PriceFormat.flightTotalTL(
        _selectedFlight,
        roundTrip: widget.isRoundTrip,
        cabinMultiplier: widget.cabinClass.priceMultiplier,
      );

  String? get _flightPriceLabel => PriceFormat.formatFlightPrice(
        _selectedFlight,
        roundTrip: widget.isRoundTrip,
      );

  String get _tripTypeLabel =>
      widget.isRoundTrip ? 'Gidiş-dönüş' : 'Tek yön';

  String _flightTimesLine(Map<String, dynamic> flight) {
    if (widget.isRoundTrip) {
      return FlightScheduleFormat.roundTripTimesLine(
        flight,
        widget.departureDate,
        widget.returnDate,
      );
    }
    return FlightScheduleFormat.outboundTimesLine(
      flight,
      widget.departureDate,
    );
  }

  int get _hotelPriceTL {
    if (_selectedHotel == null) return 0;
    return PriceFormat.hotelTotalTL(_selectedHotel!, widget.route.nights);
  }

  int get _bundledTransferTL =>
      widget.scope == BookingScope.package ? widget.route.estimatedCost.transfer : 0;

  int get _optionalTransferTL =>
      _airportTransferSelected && _bundledTransferTL <= 0
          ? CheckoutAncillaryPricing.airportTransferTL
          : 0;

  int get _transferTL => _bundledTransferTL + _optionalTransferTL;

  int get _insurancePriceTL =>
      AppConstants.insurancePrice * (widget.adults + widget.children);

  int get _insuranceTL => _insuranceSelected ? _insurancePriceTL : 0;

  int get _rentCarTL => _rentCarSelected
      ? CheckoutAncillaryPricing.rentCarTotal(widget.route.nights)
      : 0;

  int get _extraBaggageTL =>
      _extraBaggageSelected ? CheckoutAncillaryPricing.extraBaggageTL : 0;

  int get _ticketProtectionPriceTL =>
      CheckoutAncillaryPricing.ticketProtectionTotal(
        widget.adults + widget.children,
      );

  int get _ticketProtectionTL =>
      _ticketProtectionSelected ? _ticketProtectionPriceTL : 0;

  int get _flexTicketTL =>
      _flexTicketSelected ? CheckoutAncillaryPricing.flexTicketTotal() : 0;

  SearchCategory? get _checkoutCategory {
    switch (widget.scope) {
      case BookingScope.flightOnly:
        return SearchCategory.flight;
      case BookingScope.hotelOnly:
        return SearchCategory.hotel;
      case BookingScope.package:
        return SearchCategory.packageTour;
    }
  }

  bool get _showTicketProtection => widget.scope != BookingScope.hotelOnly;

  bool get _showFlexTicket =>
      widget.scope == BookingScope.flightOnly ||
      widget.scope == BookingScope.package;

  int get _ancillariesTL =>
      _insuranceTL +
      _rentCarTL +
      _extraBaggageTL +
      _ticketProtectionTL +
      _flexTicketTL;

  int get _packageCoreTL {
    switch (widget.scope) {
      case BookingScope.flightOnly:
        return _flightPriceTL;
      case BookingScope.hotelOnly:
        return _hotelPriceTL;
      case BookingScope.package:
        return _flightPriceTL + _hotelPriceTL + _bundledTransferTL;
    }
  }

  int get _resolvedUserBudgetTL {
    if (widget.userBudgetTL != null && widget.userBudgetTL! > 0) {
      return widget.userBudgetTL!;
    }
    return 0;
  }

  int get _remainingBudgetTL {
    final budget = _resolvedUserBudgetTL;
    if (budget <= 0) return 0;
    final remaining = budget - _totalPrice;
    return remaining > 0 ? remaining : 0;
  }

  int get _budgetOverageTL {
    final budget = _resolvedUserBudgetTL;
    if (budget <= 0) return 0;
    final over = _totalPrice - budget;
    return over > 0 ? over : 0;
  }

  bool get _showBudgetInsight => _resolvedUserBudgetTL > 0;

  bool get _isDomestic =>
      TripLocale.isDomesticCountry(widget.route.country);

  bool get _showInsurance => !_isDomestic;

  bool get _showOptionalTransfer =>
      widget.scope == BookingScope.package && _bundledTransferTL <= 0;

  bool get _showRentCar => !_isDomestic && widget.scope != BookingScope.flightOnly;

  bool get _showExtraBaggage => widget.scope != BookingScope.hotelOnly;

  bool get _rentCarRecommended {
    final city = widget.route.cityName.toLowerCase();
    final country = widget.route.country.toLowerCase();
    return country.contains('bae') ||
        country.contains('uae') ||
        city.contains('dubai') ||
        city.contains('dub');
  }

  CheckoutFlowStep get _currentStep => _flow[_stepIndex];

  int get _preCouponTotal {
    return switch (widget.scope) {
      BookingScope.flightOnly =>
        _flightPriceTL + _insuranceTL + _extraBaggageTL + _ticketProtectionTL + _flexTicketTL,
      BookingScope.hotelOnly => _hotelPriceTL + _insuranceTL + _rentCarTL,
      BookingScope.package =>
        _packageCoreTL + _optionalTransferTL + _ancillariesTL,
    };
  }

  int get _totalPrice {
    final discounted = _preCouponTotal - _couponDiscountTL;
    return discounted > 0 ? discounted : 0;
  }

  String _fmt(int price) => PriceFormat.format(price);

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  void dispose() {
    for (final ctrl in _passengerControllers) {
      for (final c in ctrl.values) {
        c.dispose();
      }
    }
    _cardCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _cardNameCtrl.dispose();
    super.dispose();
  }

  void _setStepIndex(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _stepIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textPrimary),
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            if (_stepIndex > 0) {
              _setStepIndex(_stepIndex - 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          checkoutStepTitle(_currentStep),
          style: TatilTheme.screenHeadline(fontSize: 17),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: _buildCurrentStepContent(),
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case CheckoutFlowStep.flight:
        return _buildFlightSelection();
      case CheckoutFlowStep.hotel:
        return _buildHotelSelection();
      case CheckoutFlowStep.summary:
        return _buildSummary();
      case CheckoutFlowStep.passenger:
        return _buildPassengerForm();
      case CheckoutFlowStep.payment:
        return _buildPaymentForm();
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.bgSecondary,
      child: Row(
        children: _flow.asMap().entries.map((e) {
          final i = e.key;
          final step = e.value;
          final label = checkoutStepLabel(step);
          final isActive = _stepIndex >= i;
          final isCurrent = _stepIndex == i;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.accent : AppTheme.bgTertiary,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isCurrent ? AppTheme.accent : Colors.transparent),
                        ),
                        child: Center(
                          child: isActive && !isCurrent
                              ? const Icon(CupertinoIcons.checkmark, color: Colors.white, size: 12)
                              : Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? Colors.white : AppTheme.textMuted)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(label, style: TextStyle(fontSize: 9, color: isActive ? AppTheme.accent : AppTheme.textMuted)),
                    ],
                  ),
                ),
                if (i < _flow.length - 1)
                  Container(width: 16, height: 1, color: _stepIndex > i ? AppTheme.accent : AppTheme.border),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _openFlightPicker() async {
    if (widget.flights.isEmpty) return;
    final picked = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => FlightPickerScreen(
          flights: widget.flights,
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
    if (widget.hotels.isEmpty) return;
    final picked = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => HotelPickerScreen(
          hotels: widget.hotels,
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

  Widget _partialScopeLink({
    required String label,
    required VoidCallback onTap,
  }) {
    return Center(
      child: TextButton(
        onPressed: onTap,
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

  void _openPartialScope(BookingScope scope) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          originIata: widget.originIata,
          route: widget.route,
          flights: widget.flights,
          hotels: widget.hotels,
          departureDate: widget.departureDate,
          returnDate: widget.returnDate,
          children: widget.children,
          adults: widget.adults,
          insuranceIncluded: _insuranceSelected,
          insuranceTotal: _insurancePriceTL,
          scope: scope,
          initialFlightIndex: _selectedFlightIndex,
          initialHotelIndex: _selectedHotelIndex,
          preferCheapest: widget.preferCheapest,
          userBudgetTL: widget.userBudgetTL,
          isRoundTrip: widget.isRoundTrip,
          cabinClass: widget.cabinClass,
          initialCouponCode: widget.initialCouponCode,
        ),
      ),
    );
  }

  // ============================================================
  // ADIM 1: UCUS SEC
  // ============================================================
  Widget _buildFlightSelection() {
    if (widget.flights.isEmpty) {
      return const Center(
        child: Text('Uçuş bulunamadı.', style: TextStyle(color: AppTheme.textMuted)),
      );
    }
    final flight = _selectedFlight!;
    final stops = flight['stops'];
    final timesLine = _flightTimesLine(flight);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.preferCheapest
              ? 'En uygun uçuş önerimiz. İsterseniz değiştirebilirsiniz.'
              : 'Planınıza en yakın uçuş. İsterseniz değiştirebilirsiniz.',
          style: TatilTheme.hint.copyWith(height: 1.4),
        ),
        const SizedBox(height: 16),
        LiveSelectionRow(
          icon: CupertinoIcons.airplane,
          iconColor: AppTheme.teal,
          title: flight['airline']?.toString() ?? 'Uçuş',
          subtitle: [
            if (timesLine.isNotEmpty) timesLine,
            '${widget.originIata} → ${widget.route.cityName}',
            stops == 0 ? 'Direkt' : '$stops aktarma',
            FlightDurationFormat.label(flight['duration']),
            _tripTypeLabel,
            widget.isRoundTrip
                ? '${_formatDate(widget.departureDate)} – ${_formatDate(widget.returnDate)}'
                : _formatDate(widget.departureDate),
          ].join(' · '),
          priceLabel: _flightPriceLabel ?? '',
          onChange: _openFlightPicker,
        ),
        if (widget.scope == BookingScope.package && _flightPriceTL > 0) ...[
          const SizedBox(height: 8),
          _partialScopeLink(
            label: 'Sadece uçuş biletini al',
            onTap: () => showPartialBookingOptionsSheet(
              context,
              scope: BookingScope.flightOnly,
              cityName: widget.route.cityName,
              amountTL: _flightPriceTL,
              detailLine:
                  '${widget.adults + widget.children} yolcu · ${_tripTypeLabel.toLowerCase()}',
              onBuyOnly: () => _openPartialScope(BookingScope.flightOnly),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // ADIM 2: OTEL SEC
  // ============================================================
  Widget _buildHotelSelection() {
    if (widget.hotels.isEmpty) {
      return const Center(
        child: Text('Otel bulunamadı.', style: TextStyle(color: AppTheme.textMuted)),
      );
    }
    final hotel = _selectedHotel!;
    final perNight = PriceFormat.hotelPerNightTL(hotel);
    final total = PriceFormat.hotelTotalTL(hotel, widget.route.nights);
    final rating = PriceFormat.hotelRatingLine(hotel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.preferCheapest
              ? 'En uygun otel önerimiz. İsterseniz değiştirebilirsiniz.'
              : 'Planınıza en yakın otel. İsterseniz değiştirebilirsiniz.',
          style: TatilTheme.hint.copyWith(height: 1.4),
        ),
        const SizedBox(height: 16),
        LiveSelectionRow(
          icon: CupertinoIcons.house_fill,
          iconColor: AppTheme.orange,
          title: hotel['name']?.toString() ?? 'Otel',
          subtitle: [
            '${widget.route.nights} gece',
            if (rating.isNotEmpty) rating,
            HotelLocationHints.forHotel(hotel, widget.route.cityName),
          ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
          priceLabel: _fmt(total),
          priceSecondaryLabel: '${_fmt(perNight)}/gece',
          onChange: _openHotelPicker,
        ),
        if (widget.scope == BookingScope.package) ...[
          const SizedBox(height: 8),
          _partialScopeLink(
            label: 'Sadece otel rezervasyonu yap',
            onTap: () => showPartialBookingOptionsSheet(
              context,
              scope: BookingScope.hotelOnly,
              cityName: widget.route.cityName,
              amountTL: _hotelPriceTL,
              detailLine: '${widget.route.nights} gece · 1 oda',
              onBuyOnly: () => _openPartialScope(BookingScope.hotelOnly),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // ADIM 3: OZET
  // ============================================================
  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummarySelectionsCard(),
        if (_hasSummaryExtras) ...[
          const SizedBox(height: 18),
          Text(
            'İsteğe bağlı',
            style: TatilTheme.sectionLabel.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          ..._buildSummaryExtras(),
        ],
        const SizedBox(height: 16),
        CheckoutCouponSection(
          key: ValueKey('coupon_${widget.scope.name}_$_preCouponTotal'),
          checkoutCategory: _checkoutCategory,
          subtotalTL: _preCouponTotal,
          initialCode: widget.initialCouponCode,
          onApplied: (result) {
            if (!mounted) return;
            setState(() {
              _couponDiscountTL = result?.discountTL ?? 0;
              _appliedCouponCode = result?.code;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildPriceBreakdownCard(),
        const SizedBox(height: 12),
        const CheckoutTrustFooter(),
      ],
    );
  }

  bool get _hasSummaryExtras =>
      _showTicketProtection ||
      _showInsurance ||
      _showOptionalTransfer ||
      _showExtraBaggage ||
      _showRentCar ||
      _showFlexTicket;

  List<Widget> _buildSummaryExtras() {
    return [
      if (_showTicketProtection)
        CheckoutAncillaryRow(
          icon: CupertinoIcons.shield_fill,
          iconColor: AppTheme.orange,
          title: 'Bilet koruması',
          subtitle: 'İptal · %90 iade',
          priceLabel: '+${_fmt(_ticketProtectionPriceTL)}',
          value: _ticketProtectionSelected,
          recommended: true,
          onChanged: (v) => setState(() => _ticketProtectionSelected = v),
        ),
      if (_showInsurance)
        CheckoutAncillaryRow(
          icon: CupertinoIcons.heart_fill,
          iconColor: AppTheme.orange,
          title: 'Seyahat sigortası',
          subtitle: 'Kişi başı',
          priceLabel: '+${_fmt(_insurancePriceTL)}',
          value: _insuranceSelected,
          onChanged: (v) => setState(() => _insuranceSelected = v),
        ),
      if (_showOptionalTransfer)
        CheckoutAncillaryRow(
          icon: CupertinoIcons.car_detailed,
          iconColor: AppTheme.teal,
          title: 'Havalimanı transferi',
          subtitle: 'Kapıdan kapıya',
          priceLabel: '+${_fmt(CheckoutAncillaryPricing.airportTransferTL)}',
          value: _airportTransferSelected,
          onChanged: (v) => setState(() => _airportTransferSelected = v),
        ),
      if (_showExtraBaggage)
        CheckoutAncillaryRow(
          icon: CupertinoIcons.bag,
          iconColor: AppTheme.teal,
          title: 'Ek bagaj',
          subtitle: '+23 kg',
          priceLabel: '+${_fmt(CheckoutAncillaryPricing.extraBaggageTL)}',
          value: _extraBaggageSelected,
          onChanged: (v) => setState(() => _extraBaggageSelected = v),
        ),
      if (_showRentCar)
        CheckoutAncillaryRow(
          icon: CupertinoIcons.car,
          iconColor: AppTheme.accent,
          title: 'Rent a car',
          subtitle: '${widget.route.nights} gün',
          priceLabel:
              '+${_fmt(CheckoutAncillaryPricing.rentCarTotal(widget.route.nights))}',
          value: _rentCarSelected,
          recommended: _rentCarRecommended,
          onChanged: (v) => setState(() => _rentCarSelected = v),
        ),
      if (_showFlexTicket)
        CheckoutAncillaryRow(
          icon: CupertinoIcons.arrow_2_circlepath,
          iconColor: AppTheme.teal,
          title: 'Esnek bilet',
          subtitle: 'Tarih değişikliği',
          priceLabel: '+${_fmt(CheckoutAncillaryPricing.flexTicketTotal())}',
          value: _flexTicketSelected,
          onChanged: (v) => setState(() => _flexTicketSelected = v),
        ),
    ];
  }

  String _formatSummaryDateTime(dynamic raw, DateTime fallback) {
    final dt = FlightScheduleFormat.parseIso(raw) ?? fallback.toLocal();
    final local = dt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year} $hh:$min';
  }

  String _travelersSummaryLabel() {
    final parts = <String>[];
    if (widget.adults > 0) {
      parts.add('${widget.adults} Yetişkin');
    }
    if (widget.children > 0) {
      parts.add('${widget.children} Çocuk');
    }
    return parts.isEmpty ? '1 Yetişkin' : parts.join(', ');
  }

  List<String> _flightSummaryLines(Map<String, dynamic> flight) {
    final stops = (flight['stops'] as num?)?.toInt() ?? 0;
    final stopLabel = stops == 0 ? 'Direkt' : '$stops aktarma';
    final lines = <String>[
      '${widget.originIata} - ${widget.route.cityName}',
      _travelersSummaryLabel(),
      stopLabel,
      'Gidiş: ${_formatSummaryDateTime(flight['departureTime'], widget.departureDate)}',
      'Varış: ${_formatSummaryDateTime(flight['arrivalTime'], widget.departureDate)}',
    ];
    if (widget.isRoundTrip && FlightScheduleFormat.hasReturnTimes(flight)) {
      lines.add(
        'Dönüş: ${_formatSummaryDateTime(flight['returnDepartureTime'], widget.returnDate)}',
      );
      lines.add(
        'Dönüş varış: ${_formatSummaryDateTime(flight['returnArrivalTime'], widget.returnDate)}',
      );
    }
    return lines;
  }

  Widget _buildFlightSummaryCard(Map<String, dynamic> flight) {
    final airline = flight['airline']?.toString() ?? 'Uçuş';
    final lines = _flightSummaryLines(flight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(CupertinoIcons.airplane, size: 18, color: AppTheme.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                airline,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (_flightPriceTL > 0)
              Text(
                _fmt(_flightPriceTL),
                style: TatilTheme.priceDisplay(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Text(
              line,
              style: TatilTheme.hint.copyWith(fontSize: 12, height: 1.35),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySelectionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          if (widget.scope != BookingScope.hotelOnly && _selectedFlight != null)
            _buildFlightSummaryCard(_selectedFlight!),
          if (widget.scope != BookingScope.hotelOnly &&
              widget.scope != BookingScope.flightOnly &&
              _selectedFlight != null &&
              _selectedHotel != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.6)),
            ),
          if (widget.scope != BookingScope.flightOnly && _selectedHotel != null)
            _summaryCompactRow(
              icon: CupertinoIcons.house_fill,
              label: _selectedHotel!['name']?.toString() ?? 'Otel',
              detail: _hotelSummarySubtitle(_selectedHotel!),
              price: _hotelPriceTL > 0 ? _fmt(_hotelPriceTL) : null,
            ),
          if (_bundledTransferTL > 0)
            _summaryCompactRow(
              icon: CupertinoIcons.car_detailed,
              label: 'Transfer',
              detail: 'Pakete dahil',
              price: _fmt(_bundledTransferTL),
            ),
        ],
      ),
    );
  }

  Widget _summaryCompactRow({
    required IconData icon,
    required String label,
    required String detail,
    String? price,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: TatilTheme.hint.copyWith(fontSize: 12, height: 1.35),
                  ),
              ],
            ),
          ),
          if (price != null)
            Text(
              price,
              style: TatilTheme.priceDisplay(fontSize: 14, color: AppTheme.textPrimary),
            ),
        ],
      ),
    );
  }





  Widget _buildPriceBreakdownCard() {
    final hasAncillaries =
        _optionalTransferTL + _ancillariesTL > 0;
    final travelers = widget.adults + widget.children;
    final flightVerified = _selectedFlight != null &&
        PriceFormat.hasRoundTripFlightPrice(_selectedFlight!);
    final flightsLive = _selectedFlight?['source']?.toString() == 'live';
    final hotelsLive = _selectedHotel?['source']?.toString() == 'live';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.scope == BookingScope.package &&
              (flightsLive || hotelsLive)) ...[
            OfferDataBadge.fromFlags(
              flightsLive: flightsLive,
              hotelsLive: hotelsLive,
              flightVerified: flightVerified,
            ),
            const SizedBox(height: 12),
          ],
          if (widget.scope != BookingScope.hotelOnly && _flightPriceTL > 0)
            _priceRow(
              widget.isRoundTrip ? 'Uçuş (gidiş-dönüş)' : 'Uçuş (tek yön)',
              _fmt(_flightPriceTL),
              note: flightVerified
                  ? (widget.isRoundTrip
                      ? 'Doğrulanmış gidiş-dönüş fiyatı'
                      : 'Tek yön bilet tutarı')
                  : null,
            ),
          if (widget.scope != BookingScope.flightOnly)
            _priceRow('Otel (${widget.route.nights} gece)', _fmt(_hotelPriceTL)),
          if (_bundledTransferTL > 0)
            _priceRow('Transfer (pakette)', _fmt(_bundledTransferTL)),
          if (_optionalTransferTL > 0)
            _priceRow('Havalimanı transferi', _fmt(_optionalTransferTL)),
          if (_rentCarTL > 0)
            _priceRow('Rent a car', _fmt(_rentCarTL)),
          if (_extraBaggageTL > 0)
            _priceRow('Ek bagaj', _fmt(_extraBaggageTL)),
          if (_insuranceTL > 0)
            _priceRow(
              'Seyahat sağlık sigortası',
              _fmt(_insuranceTL),
              note: travelers > 0
                  ? '${_fmt((_insurancePriceTL / travelers).round())}/kişi · acil tedavi ve iptal güvencesi'
                  : 'Acil tedavi ve iptal güvencesi',
            ),
          if (_ticketProtectionTL > 0)
            _priceRow('Bilet koruma', _fmt(_ticketProtectionTL)),
          if (_flexTicketTL > 0)
            _priceRow('Esnek bilet', _fmt(_flexTicketTL)),
          if (_couponDiscountTL > 0)
            _priceRow(
              'İndirim${_appliedCouponCode != null ? ' (${_appliedCouponCode!})' : ''}',
              '−${_fmt(_couponDiscountTL)}',
            ),
          if (hasAncillaries) ...[
            const Divider(height: 16),
            _priceRow('Ana paket', _fmt(_packageCoreTL)),
            _priceRow('Seçilen ekstralar', _fmt(_optionalTransferTL + _ancillariesTL)),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ödeyeceğiniz toplam',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                _fmt(_totalPrice),
                style: TatilTheme.priceDisplay(color: AppTheme.accent, fontSize: 20),
              ),
            ],
          ),
          if (_showBudgetInsight) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _budgetOverageTL > 0 ? 'Bütçe aşımı' : 'Bütçeden geriye kalan',
                  style: TatilTheme.hint.copyWith(fontSize: 12),
                ),
                Text(
                  _fmt(_budgetOverageTL > 0 ? _budgetOverageTL : _remainingBudgetTL),
                  style: TatilTheme.hint.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _budgetOverageTL > 0 ? AppTheme.orange : AppTheme.teal,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {String? note}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          if (note != null && note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                note,
                style: TatilTheme.hint.copyWith(fontSize: 10, height: 1.35),
              ),
            ),
        ],
      ),
    );
  }

  String _hotelSummarySubtitle(Map<String, dynamic> hotel) {
    final hint = HotelLocationHints.forHotel(hotel, widget.route.cityName);
    final rating = PriceFormat.hotelRatingLine(hotel);
    final parts = <String>[
      '${widget.route.nights} gece',
      if (rating.isNotEmpty) rating,
      if (hint != null) '($hint)',
    ];
    return parts.join(' · ');
  }

  // ============================================================
  // ADIM 4: YOLCU
  // ============================================================
  Widget _buildPassengerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
          ),
          child: const Row(children: [
            Icon(CupertinoIcons.person_2, color: AppTheme.accent, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Uçak bileti ve otel voucher için pasaport bilgilerinizi eksiksiz girin.',
              style: TextStyle(fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.w500),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        ...List.generate(widget.adults, (i) => _buildPassengerBlock(i, isChild: false)),
        if (widget.children > 0)
          ...List.generate(widget.children, (i) => _buildPassengerBlock(widget.adults + i, isChild: true)),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.teal.withOpacity(0.2)),
          ),
          child: const Row(children: [
            Icon(CupertinoIcons.info_circle, color: AppTheme.teal, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Bilet isim değişikliği ücret gerektirebilir. Pasaportunuzdaki ismi kullanın.',
              style: TextStyle(fontSize: 12, color: AppTheme.teal),
            )),
          ]),
        ),
      ],
    );
  }

  Widget _buildPassengerBlock(int index, {required bool isChild}) {
    final ctrl = _passengerControllers[index];
    final label = isChild ? 'Çocuk ${index - widget.adults + 1}' : 'Yetişkin ${index + 1}';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            if (isChild) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
                child: const Text('2–11 yaş', style: TextStyle(fontSize: 10, color: AppTheme.teal, fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field(ctrl['name']!, 'Ad (Pasaporttaki)', 'Adınız')),
            const SizedBox(width: 12),
            Expanded(child: _field(ctrl['surname']!, 'Soyad (Pasaporttaki)', 'Soyadınız')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(ctrl['birthDate']!, 'Doğum Tarihi', 'GG.AA.YYYY')),
            const SizedBox(width: 12),
            Expanded(child: _genderDropdown(index)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _nationalityDropdown(index)),
            const SizedBox(width: 12),
            Expanded(child: _field(ctrl['documentNumber']!, 'TC / Pasaport No', 'A12345678')),
          ]),
          const SizedBox(height: 12),
          _field(ctrl['passportExpiry']!, 'Pasaport Son Kullanma', 'GG.AA.YYYY'),
          if (!isChild) ...[
            const SizedBox(height: 12),
            _field(ctrl['email']!, 'E-posta', 'email@example.com', isEmail: true),
            const SizedBox(height: 12),
            _buildPhoneField(ctrl['phone']!),
          ],
        ],
      ),
    );
  }

  Widget _genderDropdown(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cinsiyet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgTertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _genders[index],
              isExpanded: true,
              dropdownColor: AppTheme.bgSecondary,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _genders[index] = v ?? 'Erkek'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _nationalityDropdown(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Uyruk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgTertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _nationalities[index],
              isExpanded: true,
              dropdownColor: AppTheme.bgSecondary,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              items: _nationalityOptions.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
              onChanged: (v) => setState(() => _nationalities[index] = v ?? 'Türkiye'),
            ),
          ),
        ),
      ],
    );
  }

  bool _validatePassengers() {
    for (var i = 0; i < _passengerControllers.length; i++) {
      final ctrl = _passengerControllers[i];
      final isChild = i >= widget.adults;
      final required = ['name', 'surname', 'birthDate', 'documentNumber', 'passportExpiry'];
      if (!isChild) required.addAll(['email', 'phone']);
      for (final key in required) {
        if (ctrl[key]!.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${isChild ? "Çocuk" : "Yetişkin"} ${isChild ? i - widget.adults + 1 : i + 1}: Tüm alanları doldurun.')),
          );
          return false;
        }
      }
      if (!isChild && !ctrl['email']!.text.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçerli bir e-posta adresi girin.')),
        );
        return false;
      }
    }
    return true;
  }

  bool _validatePayment() {
    if (_paymentMethod == 'transfer' || _paymentMethod == 'mobile') return true;
    if (_cardCtrl.text.replaceAll(' ', '').length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçerli bir kart numarası girin.')));
      return false;
    }
    if (_expiryCtrl.text.length < 4 || _cvvCtrl.text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kart son kullanma ve CVV bilgilerini girin.')));
      return false;
    }
    if (_cardNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kart üzerindeki ismi girin.')));
      return false;
    }
    if (_paymentMethod == 'installment' && _installmentMonths == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Taksit sayısı seçin.')));
      return false;
    }
    return true;
  }

  // ============================================================
  // ADIM 5: ODEME
  // ============================================================
  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ödeme Yöntemi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ..._paymentMethods.map((m) {
          final id = m['id'] as String;
          final isSelected = _paymentMethod == id;
          return GestureDetector(
            onTap: () => setState(() {
              _paymentMethod = id;
              if (id != 'installment') {
                _installmentMonths = null;
              } else {
                _installmentMonths ??=
                    InstallmentPlans.recommendedFor(_totalPrice)?.months ?? 6;
              }
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accent.withOpacity(0.08) : AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.border, width: isSelected ? 2 : 1),
              ),
              child: Row(children: [
                Icon(m['icon'] as IconData, color: isSelected ? AppTheme.accent : AppTheme.textMuted, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(m['label'] as String,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? AppTheme.accent : AppTheme.textPrimary))),
                if (isSelected) const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.accent, size: 20),
              ]),
            ),
          );
        }),
        const SizedBox(height: 16),
        if (_paymentMethod == 'credit' || _paymentMethod == 'debit') _buildCardForm(),
        if (_paymentMethod == 'installment') ...[
          _buildCardForm(),
          const SizedBox(height: 12),
          _buildInstallmentPicker(),
        ],
        if (_paymentMethod == 'transfer') _buildTransferInfo(),
        if (_paymentMethod == 'mobile') _buildMobilePayInfo(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.bgSecondary, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
          child: Column(children: [
            if (_flightPriceTL > 0) _priceRow('Uçuş', _fmt(_flightPriceTL)),
            _priceRow('Otel', _fmt(_hotelPriceTL)),
            if (_paymentMethod == 'installment' && _installmentMonths != null) ...[
              _priceRow(
                'Taksit',
                '$_installmentMonths ay × ${_fmt(InstallmentPlans.monthlyAmountTL(_totalPrice, _installmentMonths!))}',
              ),
            ],
            const Divider(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Toplam', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text(_fmt(_totalPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.accent)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        const Row(children: [
          Icon(CupertinoIcons.lock_shield, color: AppTheme.teal, size: 16),
          SizedBox(width: 8),
          Text('256-bit SSL ile güvenli ödeme', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ]),
      ],
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgSecondary, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          _paymentMethod == 'debit' ? 'Banka Kartı Bilgileri' : 'Kart Bilgileri',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 16),
        _field(_cardNameCtrl, 'Kart Üzerindeki İsim', 'AD SOYAD'),
        const SizedBox(height: 12),
        _field(_cardCtrl, 'Kart Numarası', '0000 0000 0000 0000', isCard: true),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field(_expiryCtrl, 'Son Kullanma', 'AA/YY')),
          const SizedBox(width: 12),
          Expanded(child: _field(_cvvCtrl, 'CVV', '***')),
        ]),
      ]),
    );
  }

  Widget _buildInstallmentPicker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Taksit seçenekleri',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toplam ${_fmt(_totalPrice)} · kartınıza göre kampanyalar değişebilir',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          ...InstallmentPlans.options.map((opt) {
            final selected = _installmentMonths == opt.months;
            final monthly =
                InstallmentPlans.monthlyAmountTL(_totalPrice, opt.months);
            return GestureDetector(
              onTap: () => setState(() => _installmentMonths = opt.months),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.accent.withValues(alpha: 0.1)
                      : AppTheme.bgTertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppTheme.accent : AppTheme.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${opt.months} taksit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? AppTheme.accent
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              if (opt.badge != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: opt.interestFree
                                        ? AppTheme.teal.withValues(alpha: 0.15)
                                        : AppTheme.orangeSoft,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    opt.badge!,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: opt.interestFree
                                          ? AppTheme.teal
                                          : AppTheme.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_fmt(monthly)} / ay',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: AppTheme.accent,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransferInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(CupertinoIcons.building_2_fill, color: AppTheme.teal, size: 18),
            SizedBox(width: 8),
            Text('Havale / EFT Bilgileri', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ]),
          const SizedBox(height: 12),
          _transferRow('Banka', 'Vizegoo Turizm A.Ş.'),
          _transferRow('IBAN', 'TR33 0006 1005 1978 6457 8413 26'),
          _transferRow('Açıklama', 'VG-${widget.route.cityName.toUpperCase()}'),
          const SizedBox(height: 8),
          Text(
            'Ödemeniz onaylandıktan sonra rezervasyonunuz kesinleşir. Tutar: ${_fmt(_totalPrice)}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _transferRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildMobilePayInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.device_phone_portrait, size: 40, color: AppTheme.accent.withOpacity(0.8)),
          const SizedBox(height: 12),
          const Text('Mobil Ödeme', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(
            'Ödemeyi tamamlamak için cihazınızdaki Apple Pay veya Google Pay uygulamasına yönlendirileceksiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(TextEditingController phoneCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Telefon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        Row(children: [
          GestureDetector(
            onTap: _showCountryCodePicker,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: AppTheme.bgTertiary, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
              child: Row(children: [
                Text(_countryCodes.firstWhere((c) => c['code'] == _countryCode, orElse: () => _countryCodes[0])['flag']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(_countryCode, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_down, size: 12, color: AppTheme.textMuted),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: '5xx xxx xx xx',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.bgTertiary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppTheme.bgSecondary, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Ulke Kodu Sec', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: _countryCodes.length,
              itemBuilder: (ctx, i) {
                final country = _countryCodes[i];
                final isSelected = country['code'] == _countryCode;
                return GestureDetector(
                  onTap: () { setState(() => _countryCode = country['code']!); Navigator.pop(ctx); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: isSelected ? AppTheme.accent.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Text(country['flag']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(country['name']!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14))),
                      Text(country['code']!, style: TextStyle(color: isSelected ? AppTheme.accent : AppTheme.textMuted, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, {bool isEmail = false, bool isPhone = false, bool isCard = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: isEmail ? TextInputType.emailAddress : isPhone ? TextInputType.phone : isCard ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.bgTertiary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  String _nextButtonLabel() {
    if (_currentStep == CheckoutFlowStep.payment) {
      return AppExperience.paymentsEnabled
          ? 'Ödemeyi tamamla'
          : AppExperience.completeFlowLabel;
    }
    switch (_currentStep) {
      case CheckoutFlowStep.flight:
        return widget.scope == BookingScope.package ? 'Otele geç →' : 'Özete geç →';
      case CheckoutFlowStep.hotel:
        return 'Özete geç →';
      case CheckoutFlowStep.summary:
        return 'Yolcu bilgileri →';
      case CheckoutFlowStep.passenger:
        return AppExperience.paymentsEnabled
            ? 'Ödemeye geç →'
            : '${AppExperience.completeFlowLabel} →';
      case CheckoutFlowStep.payment:
        return AppExperience.paymentsEnabled
            ? 'Ödemeyi tamamla'
            : AppExperience.completeFlowLabel;
    }
  }

  bool _selectionReadyForPayment() {
    switch (widget.scope) {
      case BookingScope.flightOnly:
        return _selectedFlight != null;
      case BookingScope.hotelOnly:
        return _selectedHotel != null;
      case BookingScope.package:
        return _selectedFlight != null && _selectedHotel != null;
    }
  }

  Widget _buildBottomButton() {
    final showLiveTotal = _currentStep == CheckoutFlowStep.flight ||
        _currentStep == CheckoutFlowStep.hotel ||
        _currentStep == CheckoutFlowStep.summary;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: AppTheme.bgSecondary, border: Border(top: BorderSide(color: AppTheme.border))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLiveTotal && _totalPrice > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentStep == CheckoutFlowStep.hotel
                      ? ConsumerCopy.payableTotal
                      : ConsumerCopy.totalLabel,
                  style: TatilTheme.sectionLabel.copyWith(fontSize: 13),
                ),
                Text(
                  _fmt(_totalPrice),
                  style: TatilTheme.priceDisplay(color: AppTheme.accent, fontSize: 18),
                ),
              ],
            ),
            if (_showBudgetInsight && _currentStep == CheckoutFlowStep.summary) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _budgetOverageTL > 0 ? 'Bütçe aşımı' : 'Bütçeden geriye kalan',
                    style: TatilTheme.hint,
                  ),
                  Text(
                    _fmt(_budgetOverageTL > 0 ? _budgetOverageTL : _remainingBudgetTL),
                    style: TatilTheme.hint,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
          ],
          GestureDetector(
        onTap: _isProcessing ? null : _onPrimaryAction,
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: _isProcessing ? AppTheme.orange.withValues(alpha: 0.6) : AppTheme.orange,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text(_nextButtonLabel(), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPrimaryAction() async {
    if (_currentStep == CheckoutFlowStep.passenger && !_validatePassengers()) {
      return;
    }

    final isLastStep = _stepIndex >= _flow.length - 1;
    if (!isLastStep) {
      _setStepIndex(_stepIndex + 1);
      return;
    }

    if (_currentStep == CheckoutFlowStep.payment && !_validatePayment()) return;
    if (!_selectionReadyForPayment()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seçim bulunamadı. Lütfen önceki adımlara dönün.'),
          backgroundColor: AppTheme.orange,
        ),
      );
      return;
    }
    await CheckoutAuthSheet.show(
      context,
      cityName: widget.route.cityName,
      totalPrice: _totalPrice,
      onSuccess: _processPayment,
    );
  }

  Future<void> _processPayment() async {
    if (_isProcessing || !mounted) return;

    if (AppExperience.runPaymentSimulation || AppExperience.paymentsEnabled) {
      if (AppExperience.runPaymentSimulation) {
        final secureOk = await Payment3DSecureSheet.show(
          context,
          amountTL: _totalPrice,
          merchantName: 'Vizegoo Seyahat',
        );
        if (!secureOk || !mounted) return;
      }

      setState(() => _isProcessing = true);
      final digits = _cardCtrl.text.replaceAll(' ', '');
      final cardLast4 = digits.length >= 4 ? digits.substring(digits.length - 4) : null;
      final payment = await PaymentService.charge(
        amountTL: _totalPrice,
        reservationRef: widget.route.cityName,
        paymentMethod: _paymentMethod,
        installmentMonths: _installmentMonths,
        cardLast4: cardLast4,
        skipGateway: !AppExperience.paymentsEnabled,
      );
      if (!mounted) return;
      if (!payment.success) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              payment.errorMessage ?? 'Ödeme tamamlanamadı.',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
    } else {
      setState(() => _isProcessing = true);
    }

    final passengers = _passengerControllers.map((c) => {
      'name': c['name']!.text.trim(),
      'surname': c['surname']!.text.trim(),
      'birthDate': c['birthDate']!.text.trim(),
      'documentNumber': c['documentNumber']!.text.trim(),
      'email': c['email']!.text.trim(),
      'phone': c['phone']!.text.trim(),
    }).toList();
    final primary = _passengerControllers.first;
    final ages = <int>[];
    for (var i = 0; i < _passengerControllers.length; i++) {
      final birth = _passengerControllers[i]['birthDate']?.text.trim() ?? '';
      final parsed = PassengerAge.fromBirthDateString(birth);
      ages.add(parsed ?? (i < widget.adults ? 30 : 8));
    }
    Map<String, dynamic> result;
    try {
      result = await TravelBookingService.saveBooking(
        originIata: widget.originIata,
        route: widget.route,
        selectedFlight: _selectedFlight ?? const {'id': 'skipped', 'airline': '—'},
        selectedHotel: _selectedHotel ?? const {'id': 'skipped', 'name': '—'},
        departureDate: widget.departureDate,
        returnDate: widget.returnDate,
        adults: widget.adults,
        children: widget.children,
        totalPriceTL: _totalPrice,
        flightPriceTL: widget.scope == BookingScope.hotelOnly ? 0 : _flightPriceTL,
        hotelPriceTL: widget.scope == BookingScope.flightOnly ? 0 : _hotelPriceTL,
        transferPriceTL: _transferTL,
        extrasPriceTL: _ancillariesTL,
        passengerName:
            '${primary['name']!.text.trim()} ${primary['surname']!.text.trim()}'
                .trim(),
        passengerEmail: primary['email']!.text.trim(),
        paymentMethod: _paymentMethod,
        passengers: passengers,
        insuranceIncluded: _insuranceSelected,
        bookingScope: widget.scope,
        passengerAges: ages,
        holidayTypes: widget.holidayTypes,
      );
    } catch (_) {
      result = {'success': false};
    }
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (result['success'] == true) {
      _showSuccess(result['reservationId'] as String);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error']?.toString() ??
                'Rezervasyon kaydedilemedi. Lütfen tekrar deneyin.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showSuccess(String reservationId) {
    final primary = _passengerControllers.isNotEmpty
        ? _passengerControllers.first
        : null;
    final passengerName = primary != null
        ? '${primary['name']!.text.trim()} ${primary['surname']!.text.trim()}'
            .trim()
        : 'Misafir';
    final passengerEmail = primary?['email']?.text.trim() ?? '';

    final ages = <int>[];
    for (var i = 0; i < _passengerControllers.length; i++) {
      final birth = _passengerControllers[i]['birthDate']?.text.trim() ?? '';
      final parsed = PassengerAge.fromBirthDateString(birth);
      ages.add(parsed ?? (i < widget.adults ? 30 : 8));
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (ctx) => BookingSuccessScreen(
          route: widget.route,
          selectedFlight: _selectedFlight,
          selectedHotel: _selectedHotel,
          departureDate: widget.departureDate,
          returnDate: widget.returnDate,
          adults: widget.adults,
          children: widget.children,
          totalPrice: _totalPrice,
          passengerName: passengerName.isNotEmpty ? passengerName : 'Misafir',
          passengerEmail: passengerEmail,
          reservationId: reservationId,
          passengerAges: ages,
          insuranceAlreadyPaid: _insuranceSelected,
          holidayTypes: widget.holidayTypes,
          originIata: widget.originIata,
          isRoundTrip: widget.isRoundTrip,
        ),
      ),
      (route) => route.isFirst,
    );
  }
}
