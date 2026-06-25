import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/country_meta.dart';
import '../data/destination_vibes.dart';
import '../data/holiday_types.dart';
import '../data/explore_promotions.dart';
import '../models/flight_cabin_class.dart';
import '../models/flight_leg.dart';
import '../models/flight_trip_mode.dart';
import '../models/destination_model.dart';
import '../models/search_model.dart';
import '../services/api_service.dart';
import '../services/calendar_price_service.dart';
import '../services/budget_orchestrator.dart';
import '../theme/tatil_theme.dart';
import '../utils/destination_catalog.dart';
import '../utils/category_checkout_route.dart';
import '../utils/turkish_number_input.dart';
import '../utils/app_date_picker.dart';
import '../theme/custom_page_route.dart';
import '../city_images.dart';
import '../data/bundled_destinations.dart';
import '../widgets/destination_inspiration_hero.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/category_search_guide.dart';
import '../widgets/explore_discovery_strip.dart';
import '../models/date_flexibility.dart';
import '../widgets/flexible_travel_date_picker.dart';
import '../services/bus_catalog_service.dart';
import '../services/car_rental_catalog_service.dart';
import '../models/search_category.dart';
import '../services/transfer_catalog_service.dart';
import '../services/recent_destination_store.dart';
import '../data/commission_activities.dart';
import 'category_results_screens.dart';
import 'commission_activities_screen.dart';
import '../models/destination_filter_state.dart';
import '../widgets/destination_filter_panel.dart';
import '../widgets/vizegoo_trust_footer.dart';
import 'route_results_screen.dart';

/// Detaylı arama — kategori seçimine göre form ve sonuç akışı değişir.
class DetailedSearchScreen extends StatefulWidget {
  const DetailedSearchScreen({
    super.key,
    this.category = SearchCategory.packageTour,
    this.initialDestinationIata,
    this.initialDestinationCity,
    this.initialDestinationCountry,
    this.initialOriginIata,
    this.initialOriginCity,
    this.pendingCouponCode,
    this.onCampaignTap,
    this.onRegionalDealTap,
  });

  final SearchCategory category;
  final String? initialDestinationIata;
  final String? initialDestinationCity;
  final String? initialDestinationCountry;
  final String? initialOriginIata;
  final String? initialOriginCity;
  final String? pendingCouponCode;
  final void Function(ExploreCampaign campaign)? onCampaignTap;
  final void Function(ExploreRegionalDeal deal)? onRegionalDealTap;

  @override
  State<DetailedSearchScreen> createState() => _DetailedSearchScreenState();
}

class _DetailedSearchScreenState extends State<DetailedSearchScreen> {
  late SearchModel _model;
  late TextEditingController _budgetController;

  List<DestinationModel> _destinations = [];
  List<CountryOption> _countries = [];
  bool _loadingDestinations = true;
  bool _isSearching = false;
  String? _selectedContinent;
  final Set<String> _selectedHolidayTypes = {};
  bool _sortByCheapest = false;
  String _busFromCity = 'İstanbul';
  String _busToCity = 'Ankara';
  String _transferFrom = 'Havalimanı';
  String _transferTo = 'Otel / Şehir merkezi';
  bool _sameDropoff = true;
  String? _dropoffCity;
  final DestinationFilterState _destinationFilters = DestinationFilterState();

  final List<Map<String, String>> _origins = [
    {'iata': 'IST', 'city': 'İstanbul'},
    {'iata': 'AYT', 'city': 'Antalya'},
    {'iata': 'ESB', 'city': 'Ankara'},
    {'iata': 'ADB', 'city': 'İzmir'},
  ];

  final List<Map<String, dynamic>> _continents = [
    {'value': null, 'label': 'Tümü', 'emoji': '🌍'},
    {'value': 'domestic', 'label': 'Yurtiçi', 'emoji': '🇹🇷'},
    {'value': 'europe', 'label': 'Avrupa', 'emoji': '🏰'},
    {'value': 'asia', 'label': 'Asya', 'emoji': '🌏'},
    {'value': 'middleeast', 'label': 'Orta Doğu', 'emoji': '🕌'},
    {'value': 'america', 'label': 'Amerika', 'emoji': '🗽'},
    {'value': 'africa', 'label': 'Afrika', 'emoji': '🦁'},
    {'value': 'oceania', 'label': 'Okyanusya', 'emoji': '🦘'},
  ];

  @override
  void initState() {
    super.initState();
    _model = SearchModel(
      destinationIata: widget.initialDestinationIata,
      destinationCity: widget.initialDestinationCity,
      destinationCountry: widget.initialDestinationCountry,
      originIata: widget.initialOriginIata ?? 'IST',
      originCity: widget.initialOriginCity ?? 'İstanbul',
    );
    _budgetController = TextEditingController(
      text: _model.hasBudget
          ? formatTurkishInteger(_model.totalBudgetTL.toInt())
          : '',
    );
    _loadDestinations();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _destinationFilters.dispose();
    super.dispose();
  }

  Future<void> _loadDestinations() async {
    final bundled = DestinationCatalog.parseAll(BundledDestinations.raw);
    setState(() {
      _destinations = bundled;
      _countries = DestinationCatalog.countriesFrom(bundled);
      _loadingDestinations = true;
    });

    final raw = await ApiService.getDestinations();
    if (!mounted) return;
    final list = DestinationCatalog.parseAll(raw);
    setState(() {
      _destinations = list.isNotEmpty ? list : bundled;
      _countries = DestinationCatalog.countriesFrom(_destinations);
      _loadingDestinations = false;
      if (_model.destinationIata != null &&
          !_destinations.any((d) => d.iataCode == _model.destinationIata)) {
        _model = _model.copyWith(
          destinationIata: null,
          destinationCity: null,
        );
      }
    });
  }

  Future<void> _openDestinationPicker() async {
    if (_destinations.isEmpty) {
      _snack('Destinasyonlar yükleniyor, lütfen tekrar deneyin', error: true);
      return;
    }
    final picked = await showDestinationPickerSheet(
      context,
      destinations: _destinationPickerItems,
      selectedIata: _model.destinationIata,
    );
    if (!mounted || picked == null) return;

    if (picked.iataCode.isEmpty) {
      setState(() {
        _model = _model.copyWith(
          destinationIata: null,
          destinationCity: null,
        );
      });
      return;
    }

    _applyDestination(
      iata: picked.iataCode,
      cityName: picked.cityName,
      country: picked.country,
    );
  }

  List<DestinationModel> get _destinationPickerItems {
    final list = List<DestinationModel>.from(_destinations);
    list.sort((a, b) => a.cityName.compareTo(b.cityName));
    return list;
  }

  void _applyDestination({
    required String iata,
    required String cityName,
    String? country,
  }) {
    setState(() {
      _model = _model.copyWith(
        destinationIata: iata,
        destinationCity: cityName,
        destinationCountry:
            country ?? CategoryCheckoutRoute.countryForIata(iata),
      );
    });
    unawaited(
      RecentDestinationStore.record(
        iataCode: iata,
        cityName: cityName,
        country: country ?? '',
      ),
    );
  }

  void _applyDestinationFromSlide(DestinationInspirationSlide slide) {
    final match = _destinations.cast<DestinationModel?>().firstWhere(
          (d) => d?.iataCode == slide.iata,
          orElse: () => null,
        );
    _applyDestination(
      iata: slide.iata,
      cityName: slide.cityName,
      country: match?.country,
    );
  }

  List<DestinationModel> get _visibleCities {
    var cities = _destinations;
    if (_model.destinationCountry != null) {
      cities = DestinationCatalog.filterByCountry(
        cities,
        _model.destinationCountry,
      );
    }
    return DestinationCatalog.filterByContinent(cities, _selectedContinent);
  }

  int get _matchingCityCount {
    if (_selectedHolidayTypes.isEmpty) return _visibleCities.length;
    return _visibleCities
        .where((c) => DestinationVibes.matchesAll(
              c.iataCode,
              _selectedHolidayTypes.toList(),
            ))
        .length;
  }

  void _syncModel() {
    final budget = parseTurkishInteger(_budgetController.text);
    if (budget == null || budget <= 0) {
      _model = _model.copyWith(totalBudgetTL: 0);
    } else if (budget >= SearchModel.minBudgetTL) {
      _model = _model.copyWith(totalBudgetTL: budget.toDouble());
    }
    _model = _model.copyWith(
      holidayTypes: _selectedHolidayTypes.toList(),
      continent: _selectedContinent,
    );
  }

  Future<void> _search() async {
    _syncModel();
    switch (widget.category) {
      case SearchCategory.packageTour:
        await _searchPackageTour();
      case SearchCategory.flight:
        await _searchFlight();
      case SearchCategory.hotel:
        await _searchHotel();
      case SearchCategory.bus:
        await _searchBus();
      case SearchCategory.carRental:
        await _searchCarRental();
      case SearchCategory.transfer:
        await _searchTransfer();
      case SearchCategory.activities:
        await _searchActivities();
    }
  }

  bool _missingDestination() =>
      _model.destinationIata == null || _model.destinationCity == null;

  Future<void> _searchPackageTour() async {
    final parsed = parseTurkishInteger(_budgetController.text);
    if (parsed != null && parsed > 0 && parsed < SearchModel.minBudgetTL) {
      _snack(
        'Bütçe en az ${formatTurkishInteger(SearchModel.minBudgetTL)} TL olmalı veya boş bırakın',
        error: true,
      );
      return;
    }
    if (!_model.isValid) {
      _snack('Lütfen tarihleri kontrol edin', error: true);
      return;
    }
    if (_isSearching) return;

    CalendarPriceService.cancelPendingLoads();
    setState(() => _isSearching = true);
    final model = _model.copyWith(sortByCheapest: _sortByCheapest);

    try {
      final outcome = await BudgetOrchestrator.search(model, enrichLive: false);

      if (!mounted) return;

      if (!outcome.isSuccess) {
        _snack(outcome.userMessage, error: true);
        return;
      }

      pushRouteResults(
        context,
        RouteResultsScreen(
          searchModel: model,
          initialOutcome: outcome,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _searchFlight() async {
    if (_model.isMultiCity) {
      await _searchMultiCityFlight();
      return;
    }
    if (_missingDestination()) {
      _snack('Lütfen varış noktası seçin', error: true);
      return;
    }
    if (!_model.isValid) {
      _snack('Lütfen tarihleri kontrol edin', error: true);
      return;
    }
    if (_isSearching) return;

    CalendarPriceService.cancelPendingLoads();
    setState(() => _isSearching = true);
    try {
      final returnDate = _model.isRoundTrip
          ? _model.returnDate
          : _model.departureDate;
      final flights = await ApiService.searchRealFlights(
        originIata: _model.originIata,
        destinationIata: _model.destinationIata!,
        departureDate: _model.departureDate,
        returnDate: returnDate,
        passengers: _model.passengers,
        isRoundTrip: _model.isRoundTrip,
        cabinClass: _model.flightCabinClass.apiValue,
      );
      if (!mounted) return;
      if (flights.isEmpty) {
        _snack(
          'Uçuş sonucu bulunamadı. Backend Duffel anahtarını kontrol edin.',
          error: true,
        );
        return;
      }
      pushAppRoute(
        context,
        CategoryFlightResultsScreen(
          flights: flights,
          originIata: _model.originIata,
          destinationCity: _model.destinationCity!,
          destinationIata: _model.destinationIata!,
          departureDate: _model.departureDate,
          returnDate: returnDate,
          passengers: _model.passengers,
          isRoundTrip: _model.isRoundTrip,
          destinationCountry: _model.destinationCountry ?? '',
          directFlightsOnly: _model.directFlightsOnly,
          cabinClass: _model.flightCabinClass,
          pendingCouponCode: widget.pendingCouponCode,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _searchMultiCityFlight() async {
    if (!_model.isValid) {
      _snack('Çoklu uçuş bacaklarını ve tarihleri kontrol edin', error: true);
      return;
    }
    if (_isSearching) return;

    CalendarPriceService.cancelPendingLoads();
    setState(() => _isSearching = true);
    try {
      final result = await ApiService.searchMultiCityFlights(
        legs: _model.multiCityLegs,
        passengers: _model.passengers,
        cabinClass: _model.flightCabinClass.apiValue,
      );
      if (!mounted) return;
      pushAppRoute(
        context,
        CategoryMultiCityResultsScreen(
          result: result,
          passengers: _model.passengers,
          cabinClass: _model.flightCabinClass,
          pendingCouponCode: widget.pendingCouponCode,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  List<FlightLeg> _defaultMultiCityLegs() {
    final d1 = _model.departureDate;
    return [
      FlightLeg(
        originIata: _model.originIata,
        originCity: _model.originCity,
        destinationIata: 'FCO',
        destinationCity: 'Roma',
        departureDate: d1,
      ),
      FlightLeg(
        originIata: 'FCO',
        originCity: 'Roma',
        destinationIata: 'BCN',
        destinationCity: 'Barselona',
        departureDate: d1.add(const Duration(days: 3)),
      ),
    ];
  }

  void _setFlightTripMode(FlightTripMode mode) {
    setState(() {
      var legs = _model.multiCityLegs;
      if (mode == FlightTripMode.multiCity && legs.length < 2) {
        legs = _defaultMultiCityLegs();
      }

      var next = _model.copyWith(
        flightTripMode: mode,
        isRoundTrip: mode == FlightTripMode.roundTrip,
        multiCityLegs: legs,
        returnDate: mode == FlightTripMode.oneWay
            ? _model.departureDate
            : _model.returnDate,
      );

      if (_model.isMultiCity &&
          mode != FlightTripMode.multiCity &&
          legs.isNotEmpty) {
        final first = legs.first;
        if (first.originIata.isNotEmpty) {
          next = next.copyWith(
            originIata: first.originIata,
            originCity: first.originCity,
          );
        }
        if (first.destinationIata.isNotEmpty) {
          next = next.copyWith(
            destinationIata: first.destinationIata,
            destinationCity: first.destinationCity,
          );
        }
        next = next.copyWith(departureDate: first.departureDate);
        if (mode == FlightTripMode.roundTrip &&
            !next.returnDate.isAfter(next.departureDate)) {
          next = next.copyWith(
            returnDate: next.departureDate.add(const Duration(days: 7)),
          );
        }
      }

      _model = next;
    });
  }

  Future<void> _searchHotel() async {
    if (_missingDestination()) {
      _snack('Lütfen şehir seçin', error: true);
      return;
    }
    if (!_model.isValid) {
      _snack('Lütfen tarihleri kontrol edin', error: true);
      return;
    }
    if (_isSearching) return;

    CalendarPriceService.cancelPendingLoads();
    setState(() => _isSearching = true);
    try {
      final hotels = await ApiService.searchHotels(
        cityName: _model.destinationCity!,
        checkIn: _model.departureDate,
        returnDate: _model.returnDate,
        adults: _model.passengers,
        destinationIata: _model.destinationIata,
        nights: _model.nights,
      );
      if (!mounted) return;
      pushAppRoute(
        context,
        CategoryHotelResultsScreen(
          hotels: hotels,
          cityName: _model.destinationCity!,
          destinationIata: _model.destinationIata!,
          checkIn: _model.departureDate,
          checkOut: _model.returnDate,
          nights: _model.nights,
          guests: _model.passengers,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _searchBus() async {
    if (_busFromCity == _busToCity) {
      _snack('Kalkış ve varış şehri farklı olmalı', error: true);
      return;
    }
    if (_isSearching) return;

    setState(() => _isSearching = true);
    try {
      final result = await BusCatalogService.search(
        fromCity: _busFromCity,
        toCity: _busToCity,
        date: _model.departureDate,
        passengers: _model.passengers,
      );
      if (!mounted) return;
      pushAppRoute(
        context,
        CategoryBusResultsScreen(
          initialResult: result,
          fromCity: _busFromCity,
          toCity: _busToCity,
          date: _model.departureDate,
          passengers: _model.passengers,
          onSearchAgain: () => BusCatalogService.search(
            fromCity: _busFromCity,
            toCity: _busToCity,
            date: _model.departureDate,
            passengers: _model.passengers,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _searchCarRental() async {
    if (_missingDestination()) {
      _snack('Lütfen alış lokasyonu seçin', error: true);
      return;
    }
    if (!_model.isValid) {
      _snack('Lütfen tarihleri kontrol edin', error: true);
      return;
    }
    if (_isSearching) return;

    setState(() => _isSearching = true);
    try {
      final dropCity = _sameDropoff
          ? _model.destinationCity!
          : (_dropoffCity ?? _model.destinationCity!);
      final result = await CarRentalCatalogService.search(
        city: _model.destinationCity!,
        pickup: _model.departureDate,
        dropoff: _model.returnDate,
      );
      if (!mounted) return;
      pushAppRoute(
        context,
        CategoryCarRentalResultsScreen(
          initialResult: result,
          city: dropCity,
          pickup: _model.departureDate,
          dropoff: _model.returnDate,
          onSearchAgain: () => CarRentalCatalogService.search(
            city: _model.destinationCity!,
            pickup: _model.departureDate,
            dropoff: _model.returnDate,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _searchTransfer() async {
    if (_missingDestination()) {
      _snack('Lütfen destinasyon seçin', error: true);
      return;
    }
    if (_isSearching) return;

    setState(() => _isSearching = true);
    try {
      final result = await TransferCatalogService.search(
        destinationIata: _model.destinationIata!,
        destinationCity: _model.destinationCity!,
        fromLabel: _transferFrom,
        toLabel: _transferTo,
        passengers: _model.passengers,
      );
      if (!mounted) return;
      pushAppRoute(
        context,
        CategoryTransferResultsScreen(
          initialResult: result,
          destinationCity: _model.destinationCity!,
          fromLabel: _transferFrom,
          toLabel: _transferTo,
          date: _model.departureDate,
          passengers: _model.passengers,
          onSearchAgain: () => TransferCatalogService.search(
            destinationIata: _model.destinationIata!,
            destinationCity: _model.destinationCity!,
            fromLabel: _transferFrom,
            toLabel: _transferTo,
            passengers: _model.passengers,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _searchActivities() async {
    if (_missingDestination()) {
      _snack('Lütfen şehir seçin', error: true);
      return;
    }
    if (_isSearching) return;

    setState(() => _isSearching = true);
    try {
      final dep = _model.departureDate.toIso8601String().split('T')[0];
      final ret = _model.returnDate.toIso8601String().split('T')[0];
      final result = await ApiService.getCommissionActivities(
        iata: _model.destinationIata!,
        cityName: _model.destinationCity!,
        departure: dep,
        returnDate: ret,
      );
      if (!mounted) return;

      Map<String, dynamic>? data;
      if (result['success'] == true && result['data'] != null) {
        data = Map<String, dynamic>.from(result['data'] as Map);
      } else {
        data = _fallbackActivitiesData();
      }
      data['destinationIata'] = _model.destinationIata;
      data['eventDeparture'] = _model.departureDate.toIso8601String();
      data['eventReturn'] = _model.returnDate.toIso8601String();
      if (result['success'] != true) {
        data['source'] = 'ai';
      }

      pushAppRoute(
        context,
        CommissionActivitiesScreen(data: data),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Map<String, dynamic> _fallbackActivitiesData() {
    return CommissionActivities.fromAiActivities(
      [
        {
          'title': '${_model.destinationCity} Şehir Turu',
          'category': 'tours',
          'description': 'Rehberli yarım günlük şehir keşfi',
          'duration': '4 saat',
          'priceTL': 890,
          'rating': 4.8,
          'popularityRank': 1,
        },
        {
          'title': 'Müze & Kültür Bileti',
          'category': 'museums',
          'description': 'Öne çıkan müzeler için kombine giriş',
          'duration': '1 gün',
          'priceTL': 650,
          'rating': 4.6,
          'popularityRank': 2,
        },
        {
          'title': 'Gün batımı tekne turu',
          'category': 'adventure',
          'description': 'Fotoğraf molalı tekne deneyimi',
          'duration': '2 saat',
          'priceTL': 1200,
          'rating': 4.9,
          'popularityRank': 3,
        },
        {
          'title': 'Açık hava konseri',
          'category': 'events',
          'description': 'Seçilen tarih aralığında özel gösteri',
          'duration': '2 saat',
          'priceTL': 950,
          'rating': 4.7,
          'popularityRank': 4,
        },
      ],
      _model.destinationCity!,
      _model.destinationIata!,
      tripStart: _model.departureDate,
      tripEnd: _model.returnDate,
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : TatilTheme.orange,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatDate(DateTime d) {
    const months = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
        'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${d.day} ${months[d.month]}';
  }

  int get _advancedFilterCount {
    var n = _destinationFilters.activeCount;
    if (_model.destinationCountry != null) n++;
    if (widget.category != SearchCategory.packageTour) {
      if (_model.passengers != 1) n++;
      if (_model.children > 0) n++;
    }
    if (_model.minServiceRating != 7.5 || _model.maxServiceRating != 10.0) n++;
    return n;
  }

  void _applyDestinationFilters() {
    setState(() {
      _selectedContinent = _destinationFilters.primaryContinent();
      _selectedHolidayTypes
        ..clear()
        ..addAll(_destinationFilters.toHolidayTypes());
      _model = _model.copyWith(
        continent: _selectedContinent,
        holidayTypes: _selectedHolidayTypes.toList(),
      );
    });
  }

  void _openAdvancedFilters() {
    _destinationFilters.applyFrom(
      continent: _selectedContinent,
      holidayTypes: _selectedHolidayTypes,
    );
    DestinationFilterPanel.show(
      context,
      state: _destinationFilters,
      onApply: _applyDestinationFilters,
      onClear: _applyDestinationFilters,
      extraSections: [
        _buildCountrySelector(
          onChanged: (fn) {
            fn();
            if (mounted) setState(() {});
          },
        ),
        if (widget.category != SearchCategory.packageTour) ...[
          const SizedBox(height: 18),
          _buildPassengerSelector(
            onChanged: (fn) {
              fn();
              if (mounted) setState(() {});
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _card(_fieldsForCategory()),
                if (widget.pendingCouponCode != null &&
                    widget.pendingCouponCode!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _pendingCouponBanner(),
                ],
                if (widget.category.showAdvancedFilters) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openAdvancedFilters,
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: Text(
                      _advancedFilterCount > 0
                          ? 'Gelişmiş filtreler ($_advancedFilterCount)'
                          : 'Gelişmiş filtreler',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TatilTheme.orange,
                      side: const BorderSide(color: TatilTheme.orange),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
                if (widget.onCampaignTap != null && widget.onRegionalDealTap != null)
                  ExploreDiscoveryStrip(
                    category: widget.category,
                    originIata: _stripOriginIata,
                    originCity: _stripOriginCity,
                    onCampaignTap: widget.onCampaignTap!,
                    onRegionalDealTap: widget.onRegionalDealTap!,
                  ),
                if (widget.category.showInspirationHero) ...[
                  const SizedBox(height: 8),
                  DestinationInspirationHero(
                    onDestinationTap: _applyDestinationFromSlide,
                  ),
                ],
                if (widget.category.showSearchGuide) ...[
                  const SizedBox(height: 12),
                  CategorySearchGuide(category: widget.category),
                ],
                if (widget.category == SearchCategory.activities ||
                    widget.category == SearchCategory.packageTour) ...[
                  const SizedBox(height: 20),
                  const VizegooTrustFooter(compact: true),
                ],
              ],
            ),
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  String get _stripOriginIata {
    if (widget.category == SearchCategory.bus) {
      return ExplorePromotions.cityToOriginIata(_busFromCity) ?? 'IST';
    }
    return _model.originIata;
  }

  String get _stripOriginCity {
    if (widget.category == SearchCategory.bus) {
      return _busFromCity;
    }
    return _model.originCity;
  }

  List<Widget> _fieldsForCategory() {
    switch (widget.category) {
      case SearchCategory.flight:
        return [
          _buildFlightTripTypeSelector(),
          const SizedBox(height: 18),
          if (_model.isMultiCity)
            _buildMultiCityLegsEditor()
          else ...[
            _buildDestinationSelector(),
            const SizedBox(height: 18),
            _buildOriginSelector(),
            const SizedBox(height: 18),
            if (_model.isRoundTrip)
              _buildDateSelector()
            else
              _buildSimpleDateSelector(label: 'Gidiş tarihi'),
          ],
          const SizedBox(height: 18),
          _buildCabinClassSelector(),
          const SizedBox(height: 12),
          _buildDirectFlightsToggle(),
          const SizedBox(height: 18),
          _buildInlinePassengers(),
        ];
      case SearchCategory.hotel:
        return [
          _buildDestinationSelector(),
          const SizedBox(height: 18),
          _buildDateSelector(),
          const SizedBox(height: 18),
          _buildInlinePassengers(label: 'Misafir'),
        ];
      case SearchCategory.bus:
        return [
          _buildBusCitySelector(
            'Nereden?',
            _busFromCity,
            (v) => _busFromCity = v,
          ),
          const SizedBox(height: 8),
          Center(
            child: IconButton(
              tooltip: 'Şehirleri değiştir',
              onPressed: () {
                setState(() {
                  final tmp = _busFromCity;
                  _busFromCity = _busToCity;
                  _busToCity = tmp;
                });
              },
              icon: const Icon(Icons.swap_vert_rounded, color: TatilTheme.orange),
            ),
          ),
          const SizedBox(height: 4),
          _buildBusCitySelector(
            'Nereye?',
            _busToCity,
            (v) => _busToCity = v,
          ),
          const SizedBox(height: 18),
          _buildSimpleDateSelector(),
          const SizedBox(height: 18),
          _buildInlinePassengers(),
        ];
      case SearchCategory.packageTour:
        return [
          _buildDestinationSelector(),
          const SizedBox(height: 18),
          _buildOriginSelector(),
          const SizedBox(height: 18),
          _buildDateSelector(),
          const SizedBox(height: 18),
          _buildInlinePassengers(),
          const SizedBox(height: 12),
          _buildInlineChildren(),
          const SizedBox(height: 18),
          _buildBudgetInput(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Önce en ucuz rotalar',
                  style: TatilTheme.sectionLabel.copyWith(fontSize: 13),
                ),
              ),
              Switch.adaptive(
                value: _sortByCheapest,
                activeColor: TatilTheme.orange,
                onChanged: (value) => setState(() => _sortByCheapest = value),
              ),
            ],
          ),
        ];
      case SearchCategory.carRental:
        return [
          _buildDestinationSelector(label: 'Alış yeri'),
          const SizedBox(height: 18),
          _buildSameDropoffToggle(),
          if (!_sameDropoff) ...[
            const SizedBox(height: 18),
            _buildDropoffCitySelector(),
          ],
          const SizedBox(height: 18),
          _buildDateSelector(label: 'Alış / Teslim'),
        ];
      case SearchCategory.transfer:
        return [
          _buildDestinationSelector(label: 'Destinasyon'),
          const SizedBox(height: 18),
          _buildTransferPointSelector('Nereden?', _transferFrom, (v) => _transferFrom = v),
          const SizedBox(height: 18),
          _buildTransferPointSelector('Nereye?', _transferTo, (v) => _transferTo = v),
          const SizedBox(height: 18),
          _buildSimpleDateSelector(label: 'Tarih'),
          const SizedBox(height: 18),
          _buildInlinePassengers(),
        ];
      case SearchCategory.activities:
        return [
          _buildDestinationSelector(),
          const SizedBox(height: 18),
          _buildDateSelector(label: 'Tarih aralığı'),
        ];
    }
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: TatilTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _section(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TatilTheme.sectionLabel),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDestinationSelector({String label = 'Nereye?'}) {
    final label = _model.destinationCity ?? 'Herhangi bir yer';
    final subtitle = _model.destinationIata != null
        ? '${_model.destinationIata} · ${_model.destinationCountry ?? ''}'
        : '${_destinations.length} destinasyon';

    return _section(
      label,
      GestureDetector(
        onTap: _loadingDestinations ? null : _openDestinationPicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TatilTheme.border),
          ),
          child: Row(
            children: [
              if (_loadingDestinations)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TatilTheme.orange,
                  ),
                )
              else
                const Icon(Icons.location_on_outlined, color: TatilTheme.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TatilTheme.hint.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more, color: TatilTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOriginSelector() {
    return _section(
      'Nereden?',
      DropdownButtonFormField<String>(
        value: _model.originIata,
        decoration: _inputDecoration(),
        items: _origins
            .map((o) => DropdownMenuItem(
                  value: o['iata'],
                  child: Text('${o['iata']} · ${o['city']}'),
                ))
            .toList(),
        onChanged: (val) {
          if (val == null) return;
          final city = _origins.firstWhere((o) => o['iata'] == val)['city']!;
          setState(() => _model = _model.copyWith(originIata: val, originCity: city));
        },
      ),
    );
  }

  Widget _buildCabinClassSelector() {
    return _section(
      'Kabin sınıfı',
      DropdownButtonFormField<FlightCabinClass>(
        value: _model.flightCabinClass,
        decoration: _inputDecoration(),
        items: FlightCabinClass.values
            .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() => _model = _model.copyWith(flightCabinClass: v));
        },
      ),
    );
  }

  Widget _buildDirectFlightsToggle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Sadece direkt uçuşlar',
            style: TatilTheme.sectionLabel.copyWith(fontSize: 13),
          ),
        ),
        Switch.adaptive(
          value: _model.directFlightsOnly,
          activeTrackColor: TatilTheme.orange,
          onChanged: (v) =>
              setState(() => _model = _model.copyWith(directFlightsOnly: v)),
        ),
      ],
    );
  }

  Widget _pendingCouponBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: TatilTheme.orangeSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TatilTheme.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined, color: TatilTheme.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kupon ${widget.pendingCouponCode} ödeme adımında uygulanacak',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TatilTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightTripTypeSelector() {
    return _section(
      'Uçuş tipi',
      Row(
        children: [
          for (var i = 0; i < FlightTripMode.values.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _tripTypeChip(
                label: FlightTripMode.values[i].label,
                selected: _model.flightTripMode == FlightTripMode.values[i],
                onTap: () => _setFlightTripMode(FlightTripMode.values[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMultiCityLegsEditor() {
    return _section(
      'Uçuş bacakları',
      Column(
        children: [
          for (var i = 0; i < _model.multiCityLegs.length; i++) ...[
            _multiCityLegCard(i),
            if (i < _model.multiCityLegs.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          if (_model.multiCityLegs.length < 4)
            OutlinedButton.icon(
              onPressed: () {
                final last = _model.multiCityLegs.last;
                setState(() {
                  final next = [
                    ..._model.multiCityLegs,
                    FlightLeg(
                      originIata: last.destinationIata,
                      originCity: last.destinationCity,
                      destinationIata: '',
                      destinationCity: '',
                      departureDate:
                          last.departureDate.add(const Duration(days: 2)),
                    ),
                  ];
                  _model = _model.copyWith(multiCityLegs: next);
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Bacak ekle'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TatilTheme.orange,
                side: const BorderSide(color: TatilTheme.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _multiCityLegCard(int index) {
    final leg = _model.multiCityLegs[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TatilTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bacak ${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TatilTheme.textMuted,
                ),
              ),
              const Spacer(),
              if (_model.multiCityLegs.length > 2)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      final next = [..._model.multiCityLegs]..removeAt(index);
                      _model = _model.copyWith(multiCityLegs: next);
                    });
                  },
                  child: const Icon(Icons.close, size: 18, color: TatilTheme.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickLegDestination(index),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TatilTheme.border),
              ),
              child: Text(
                leg.destinationCity.isNotEmpty
                    ? '${leg.originCity} → ${leg.destinationCity}'
                    : 'Varış şehri seçin',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TatilTheme.textDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickLegDate(index),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TatilTheme.border),
              ),
              child: Text(
                '${leg.departureDate.day}.${leg.departureDate.month}.${leg.departureDate.year}',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLegDestination(int index) async {
    final picked = await showDestinationPickerSheet(
      context,
      destinations: _destinations,
    );
    if (picked == null || !mounted) return;
    setState(() {
      final legs = [..._model.multiCityLegs];
      legs[index] = legs[index].copyWith(
        destinationIata: picked.iataCode,
        destinationCity: picked.cityName,
      );
      for (var j = index + 1; j < legs.length; j++) {
        final prev = legs[j - 1];
        legs[j] = legs[j].copyWith(
          originIata: prev.destinationIata,
          originCity: prev.destinationCity,
        );
      }
      _model = _model.copyWith(multiCityLegs: legs);
    });
  }

  Future<void> _pickLegDate(int index) async {
    final leg = _model.multiCityLegs[index];
    final minDate = index > 0
        ? _model.multiCityLegs[index - 1].departureDate
        : DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initialDate: leg.departureDate.isBefore(minDate) ? minDate : leg.departureDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final legs = [..._model.multiCityLegs];
      legs[index] = legs[index].copyWith(departureDate: picked);
      _model = _model.copyWith(multiCityLegs: legs);
    });
  }

  Widget _tripTypeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? TatilTheme.orangeSoft : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? TatilTheme.orange : TatilTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? TatilTheme.orange : TatilTheme.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildInlinePassengers({String label = 'Yolcu'}) {
    return _section(
      label,
      Row(
        children: [
          Expanded(
            child: Text(
              'Yetişkin',
              style: TatilTheme.sectionLabel.copyWith(fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: _model.passengers > 1
                ? () => setState(() => _model = _model.copyWith(passengers: _model.passengers - 1))
                : null,
            icon: const Icon(CupertinoIcons.minus_circle),
            color: TatilTheme.orange,
          ),
          Text(
            '${_model.passengers}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          IconButton(
            onPressed: _model.passengers < 9
                ? () => setState(() => _model = _model.copyWith(passengers: _model.passengers + 1))
                : null,
            icon: const Icon(CupertinoIcons.plus_circle),
            color: TatilTheme.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInlineChildren() {
    return _section(
      'Çocuk',
      Row(
        children: [
          Expanded(
            child: Text(
              '0–11 yaş',
              style: TatilTheme.sectionLabel.copyWith(fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: _model.children > 0
                ? () => setState(() => _model = _model.copyWith(children: _model.children - 1))
                : null,
            icon: const Icon(CupertinoIcons.minus_circle),
            color: TatilTheme.orange,
          ),
          Text(
            '${_model.children}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          IconButton(
            onPressed: _model.children < 6
                ? () => setState(() => _model = _model.copyWith(children: _model.children + 1))
                : null,
            icon: const Icon(CupertinoIcons.plus_circle),
            color: TatilTheme.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildBusCitySelector(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return _section(
      label,
      DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: _inputDecoration(),
        items: BusCatalogService.cities
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() => onChanged(v));
        },
      ),
    );
  }

  Widget _buildTransferPointSelector(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    const options = [
      'Havalimanı',
      'Otel',
      'Şehir merkezi',
      'Liman',
      'Tren garı',
    ];
    return _section(
      label,
      DropdownButtonFormField<String>(
        value: options.contains(value) ? value : options.first,
        decoration: _inputDecoration(),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() => onChanged(v));
        },
      ),
    );
  }

  Widget _buildSameDropoffToggle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Aynı noktada teslim',
            style: TatilTheme.sectionLabel.copyWith(fontSize: 13),
          ),
        ),
        Switch.adaptive(
          value: _sameDropoff,
          activeColor: TatilTheme.orange,
          onChanged: (v) => setState(() => _sameDropoff = v),
        ),
      ],
    );
  }

  Widget _buildDropoffCitySelector() {
    return _section(
      'Teslim yeri',
      DropdownButtonFormField<String>(
        value: _dropoffCity ?? _model.destinationCity,
        decoration: _inputDecoration(hint: 'Şehir seçin'),
        items: BusCatalogService.cities
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _dropoffCity = v),
      ),
    );
  }

  Widget _buildSimpleDateSelector({String label = 'Tarih'}) {
    return _section(
      label,
      GestureDetector(
        onTap: () async {
          final picked = await showAppDatePicker(
            context,
            initialDate: _model.departureDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) {
            setState(() {
              _model = _model.copyWith(
                departureDate: picked,
                returnDate: picked.add(const Duration(days: 1)),
              );
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TatilTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(_model.departureDate),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.calendar_month, color: TatilTheme.orange.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountrySelector({void Function(VoidCallback)? onChanged}) {
    void touch(VoidCallback fn) {
      if (onChanged != null) {
        onChanged(fn);
      } else {
        setState(fn);
      }
    }

    return _section(
      'Ülke (hedef)',
      _loadingDestinations
          ? const LinearProgressIndicator(color: TatilTheme.orange)
          : DropdownButtonFormField<String?>(
              value: _model.destinationCountry,
              decoration: _inputDecoration(hint: 'Tüm ülkeler'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tüm ülkeler'),
                ),
                ..._countries.map(
                  (c) => DropdownMenuItem<String?>(
                    value: c.country,
                    child: Text('${c.flag} ${c.labelTr} (${c.cityCount} şehir)'),
                  ),
                ),
              ],
              onChanged: (val) {
                touch(() {
                  _model = _model.copyWith(
                    destinationCountry: val,
                    destinationIata: null,
                    destinationCity: null,
                  );
                });
              },
            ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TatilTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TatilTheme.border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildDateSelector({String label = 'Ne zaman?'}) {
    final flexLabel = _model.dateFlexibility == DateFlexibility.exact
        ? null
        : _model.dateFlexibility.labelTr;
    final spanBadge = widget.category.dateSpanBadgeLabel(
      nights: _model.nights,
      departure: _model.departureDate,
      returnDate: _model.returnDate,
    );

    return _section(
      label,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
        onTap: () async {
          final picked = await showFlexibleTravelDatePicker(
            context,
            initialDeparture: _model.departureDate,
            initialReturn: _model.returnDate,
            originIata: _model.originIata,
            destinationIata: _model.destinationIata,
            destinationCity: _model.destinationCity,
            passengers: _model.passengers,
            initialFlexibility: _model.dateFlexibility,
          );
          if (picked != null) {
            setState(() => _model = _model.copyWith(
                  departureDate: picked.departureDate,
                  returnDate: picked.returnDate,
                  dateFlexibility: picked.flexibility,
                ));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TatilTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.category.dateRangeStartLabel, style: TatilTheme.hint),
                    Text(
                      _formatDate(_model.departureDate),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (spanBadge != null)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: TatilTheme.orangeSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        spanBadge,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: TatilTheme.orange,
                        ),
                      ),
                    ),
                    if (flexLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        flexLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ],
                )
              else if (flexLabel != null)
                Text(
                  flexLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              if (spanBadge == null && flexLabel == null)
                const SizedBox(width: 48),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(widget.category.dateRangeEndLabel, style: TatilTheme.hint),
                    Text(
                      _formatDate(_model.returnDate),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.calendar_month, color: TatilTheme.orange.withValues(alpha: 0.8)),
            ],
          ),
        ),
          ),
          if (widget.category == SearchCategory.packageTour &&
              _model.destinationIata != null) ...[
            const SizedBox(height: 6),
            Text(
              'Takvime dokunun — gün gün fiyat grafiği ve en ucuz tarih',
              style: TatilTheme.hint.copyWith(
                fontSize: 11,
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPassengerSelector({void Function(VoidCallback)? onChanged}) {
    void touch(VoidCallback fn) {
      if (onChanged != null) {
        onChanged(fn);
      } else {
        setState(fn);
      }
    }

    return _section(
      'Kaç kişi?',
      Column(
        children: [
          _counterRow('Yetişkin', _model.passengers, 1, 9, (v) {
            touch(() => _model = _model.copyWith(passengers: v));
          }),
          const SizedBox(height: 12),
          _counterRow('Çocuk', _model.children, 0, 6, (v) {
            touch(() => _model = _model.copyWith(children: v));
          }),
        ],
      ),
    );
  }

  Widget _counterRow(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label, style: TatilTheme.sectionLabel.copyWith(fontSize: 13))),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(CupertinoIcons.minus_circle),
          color: TatilTheme.orange,
        ),
        Text('$value', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(CupertinoIcons.plus_circle),
          color: TatilTheme.orange,
        ),
      ],
    );
  }

  Widget _buildBudgetInput() {
    return _section(
      'Toplam bütçe (TL)',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              hint: 'Opsiyonel · örn. 30.000',
            ),
            onChanged: (_) => _syncModel(),
          ),
          const SizedBox(height: 6),
          Text(
            'Boş bırakırsanız bütçe sınırı olmadan keşfedersiniz.',
            style: TatilTheme.hint.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildContinentSelector({void Function(VoidCallback)? onChanged}) {
    void touch(VoidCallback fn) {
      if (onChanged != null) {
        onChanged(fn);
      } else {
        setState(fn);
      }
    }

    final regions = _destinations.isEmpty ? _continents : _dynamicRegions();
    return _section(
      'Bölge',
      SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: regions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final item = regions[i];
            final selected = _selectedContinent == item['value'];
            return _chip(
              label: '${item['emoji']} ${item['label']}',
              selected: selected,
              onTap: () {
                touch(() {
                  _selectedContinent = item['value'] as String?;
                  _model = _model.copyWith(
                    continent: item['value'] as String?,
                    destinationIata: null,
                    destinationCity: null,
                  );
                });
              },
            );
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _dynamicRegions() {
    final regions = <Map<String, dynamic>>[
      {'value': null, 'label': 'Tümü', 'emoji': '🌍'},
    ];
    final seen = <String>{};
    for (final d in _destinations) {
      final cont = CountryMeta.continent(d.country);
      if (cont == null || !seen.add(cont)) continue;
      final static = _continents.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c?['value'] == cont,
            orElse: () => null,
          );
      if (static != null) regions.add(static);
    }
    return regions;
  }

  Widget _buildFilterSection({void Function(VoidCallback)? onChanged}) {
    void touch(VoidCallback fn) {
      if (onChanged != null) {
        onChanged(fn);
      } else {
        setState(fn);
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TatilTheme.orange.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: TatilTheme.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filtrele',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: TatilTheme.textDark,
                ),
              ),
              const Spacer(),
              if (_selectedHolidayTypes.isNotEmpty)
                Text(
                  '$_matchingCityCount uygun destinasyon',
                  style: GoogleFonts.inter(fontSize: 11, color: TatilTheme.orange),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Birden fazla tatil türü seçebilirsiniz — örn. hem kültür hem deniz.',
            style: TatilTheme.hint.copyWith(height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HolidayTypes.options.map((item) {
              final value = item['value'] as String;
              final label = '${item['emoji']} ${item['label']}';
              final selected = _selectedHolidayTypes.contains(value);
              return _chip(
                label: label,
                selected: selected,
                onTap: () {
                  touch(() {
                    if (selected) {
                      _selectedHolidayTypes.remove(value);
                    } else {
                      _selectedHolidayTypes.add(value);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Hizmet puanı aralığı', style: TatilTheme.sectionLabel),
          const SizedBox(height: 4),
          Text(
            'Sosyal medya ve misafir etkileşimlerinden alınan otel/hizmet puanı',
            style: TatilTheme.hint.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _model.minServiceRating.toStringAsFixed(1),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              Text(
                _model.maxServiceRating.toStringAsFixed(1),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(_model.minServiceRating, _model.maxServiceRating),
            min: 5.0,
            max: 10.0,
            divisions: 10,
            activeColor: TatilTheme.orange,
            labels: RangeLabels(
              _model.minServiceRating.toStringAsFixed(1),
              _model.maxServiceRating.toStringAsFixed(1),
            ),
            onChanged: (v) {
              touch(() {
                _model = _model.copyWith(
                  minServiceRating: v.start,
                  maxServiceRating: v.end,
                );
              });
            },
          ),
          Wrap(
            spacing: 8,
            children: [
              _chip(
                label: '7.5 – 10',
                selected: _model.minServiceRating == 7.5 && _model.maxServiceRating == 10,
                onTap: () => touch(() => _model = _model.copyWith(
                      minServiceRating: 7.5,
                      maxServiceRating: 10.0,
                    )),
              ),
              _chip(
                label: '8.0 – 10',
                selected: _model.minServiceRating == 8.0 && _model.maxServiceRating == 10,
                onTap: () => touch(() => _model = _model.copyWith(
                      minServiceRating: 8.0,
                      maxServiceRating: 10.0,
                    )),
              ),
              _chip(
                label: '5.0 – 7.5',
                selected: _model.minServiceRating == 5.0 && _model.maxServiceRating == 7.5,
                onTap: () => touch(() => _model = _model.copyWith(
                      minServiceRating: 5.0,
                      maxServiceRating: 7.5,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? TatilTheme.orange : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? TatilTheme.orange : TatilTheme.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : TatilTheme.textMuted,
          ),
        ),
      ),
    );
  }

  List<String> _missingSearchHints() {
    switch (widget.category) {
      case SearchCategory.bus:
        if (_busFromCity == _busToCity) {
          return ['Kalkış ve varış şehri farklı olmalı'];
        }
        return [];
      case SearchCategory.transfer:
        final missing = <String>[];
        if (_missingDestination()) missing.add('destinasyon');
        return missing;
      case SearchCategory.flight:
      case SearchCategory.hotel:
      case SearchCategory.carRental:
      case SearchCategory.activities:
        if (_missingDestination()) return ['destinasyon'];
        if (!_model.isValid) return ['tarih'];
        return [];
      case SearchCategory.packageTour:
        return [];
    }
  }

  Widget _buildBottomActions() {
    final hints = _missingSearchHints();
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hints.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Devam etmek için: ${hints.join(' · ')}',
                  style: TatilTheme.hint.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF9A3412),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSearching ? null : _search,
              style: ElevatedButton.styleFrom(
                backgroundColor: TatilTheme.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSearching
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.category.searchButtonLabel,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
