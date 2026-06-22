import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../catalog/catalog_search_result.dart';
import '../models/booking_scope.dart';
import '../models/flight_cabin_class.dart';
import '../models/search_category.dart';
import '../theme/app_theme.dart';
import '../theme/custom_page_route.dart';
import '../theme/tatil_theme.dart';
import '../utils/category_checkout_route.dart';
import '../utils/flight_schedule_format.dart';
import '../utils/price_format.dart';
import '../widgets/travel_state_view.dart';
import 'category_simple_checkout_screen.dart';
import 'checkout_screen.dart';
import '../widgets/preview_mode_banner.dart';
import '../models/multi_city_search_result.dart';
import '../services/multi_city_package_service.dart';

String _fmtDate(DateTime d) => '${d.day}.${d.month}.${d.year}';

String _fmtTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

// ─────────────────────────────────────────────────────────────────────────────
// Uçak
// ─────────────────────────────────────────────────────────────────────────────

class CategoryFlightResultsScreen extends StatelessWidget {
  const CategoryFlightResultsScreen({
    super.key,
    required this.flights,
    required this.originIata,
    required this.destinationCity,
    required this.destinationIata,
    required this.departureDate,
    required this.returnDate,
    required this.passengers,
    this.isRoundTrip = true,
    this.destinationCountry = '',
    this.directFlightsOnly = false,
    this.cabinClass = FlightCabinClass.economy,
    this.pendingCouponCode,
  });

  final List<Map<String, dynamic>> flights;
  final String originIata;
  final String destinationCity;
  final String destinationIata;
  final DateTime departureDate;
  final DateTime returnDate;
  final int passengers;
  final bool isRoundTrip;
  final String destinationCountry;
  final bool directFlightsOnly;
  final FlightCabinClass cabinClass;
  final String? pendingCouponCode;

  @override
  Widget build(BuildContext context) {
    var sorted = [...flights]
      ..sort((a, b) {
        final pa = (a['totalAmountTL'] as num?)?.toInt() ?? 999999999;
        final pb = (b['totalAmountTL'] as num?)?.toInt() ?? 999999999;
        return pa.compareTo(pb);
      });

    if (directFlightsOnly) {
      sorted = sorted
          .where((f) => ((f['stops'] as num?)?.toInt() ?? 0) == 0)
          .toList();
    }

    final cabinMult = cabinClass.priceMultiplier;

    return _CategoryResultsScaffold(
      category: SearchCategory.flight,
      title: 'Uçuş Sonuçları',
      subtitle: isRoundTrip
          ? '$originIata → $destinationIata · $destinationCity\n'
              '${_fmtDate(departureDate)} – ${_fmtDate(returnDate)} · $passengers yolcu · ${cabinClass.label}'
          : '$originIata → $destinationIata · $destinationCity\n'
              '${_fmtDate(departureDate)} · Tek yön · $passengers yolcu · ${cabinClass.label}',
      countLabel: directFlightsOnly
          ? '${sorted.length} direkt uçuş'
          : '${sorted.length} uçuş',
      isEmpty: sorted.isEmpty,
      emptyMessage: directFlightsOnly
          ? 'Bu tarihlerde direkt uçuş bulunamadı. Filtreyi kapatıp tekrar deneyin.'
          : 'Bu tarihler için uçuş bulunamadı.',
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: sorted.length,
        itemBuilder: (context, i) {
          final flight = sorted[i];
          final price = PriceFormat.formatFlightPrice(
                flight,
                roundTrip: isRoundTrip,
                cabinMultiplier: cabinMult,
              ) ??
              '—';
          final stops = flight['stops'] ?? 0;
          final stopLabel = stops == 0 ? 'Direkt' : '$stops aktarma';
          final times = isRoundTrip
              ? FlightScheduleFormat.roundTripTimesLine(
                  flight,
                  departureDate,
                  returnDate,
                )
              : FlightScheduleFormat.outboundTimesLine(flight, departureDate);
          final airline = flight['airlineName'] ?? flight['airline'] ?? 'Havayolu';

          return _ResultCard(
            title: airline.toString(),
            subtitle: times,
            badge: isRoundTrip ? stopLabel : 'Tek yön',
            price: price,
            actionLabel: 'Seç',
            onTap: () => _openFlightCheckout(
              context,
              flights: sorted,
              flightIndex: i,
              originIata: originIata,
              destinationCity: destinationCity,
              destinationIata: destinationIata,
              departureDate: departureDate,
              returnDate: returnDate,
              passengers: passengers,
              isRoundTrip: isRoundTrip,
              destinationCountry: destinationCountry,
              cabinClass: cabinClass,
              pendingCouponCode: pendingCouponCode,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Otel
// ─────────────────────────────────────────────────────────────────────────────

class CategoryHotelResultsScreen extends StatelessWidget {
  const CategoryHotelResultsScreen({
    super.key,
    required this.hotels,
    required this.cityName,
    required this.destinationIata,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.guests,
  });

  final List<Map<String, dynamic>> hotels;
  final String cityName;
  final String destinationIata;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final int guests;

  @override
  Widget build(BuildContext context) {
    final sorted = [...hotels]
      ..sort((a, b) {
        final pa = PriceFormat.hotelTotalTL(a, nights);
        final pb = PriceFormat.hotelTotalTL(b, nights);
        return pa.compareTo(pb);
      });

    return _CategoryResultsScaffold(
      category: SearchCategory.hotel,
      title: 'Otel Sonuçları',
      subtitle:
          '$cityName · $nights gece\n'
          '${_fmtDate(checkIn)} – ${_fmtDate(checkOut)} · $guests misafir',
      countLabel: '${sorted.length} otel',
      isEmpty: sorted.isEmpty,
      emptyMessage: 'Bu tarihler için otel bulunamadı.',
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: sorted.length,
        itemBuilder: (context, i) {
          final hotel = sorted[i];
          final name = hotel['name']?.toString() ?? 'Otel';
          final score = (hotel['reviewScore'] as num?)?.toDouble() ?? 0;
          final stars = hotel['stars'] ?? hotel['propertyClass'] ?? 0;
          final total = PriceFormat.hotelTotalTL(hotel, nights);
          final perNight = nights > 0 ? (total / nights).round() : total;

          final starCount = (stars as num).toInt().clamp(0, 5);
          final starLine = starCount > 0 ? '${'★' * starCount} · ' : '';

          return _ResultCard(
            title: name,
            subtitle: '${starLine}Puan $score · $nights gece',
            badge: 'Canlı fiyat',
            price: PriceFormat.format(total),
            trailing: Text(
              '${PriceFormat.format(perNight)}/gece',
              style: TatilTheme.hint.copyWith(fontSize: 11),
            ),
            actionLabel: 'Rezerve et',
            onTap: () => _openHotelCheckout(
              context,
              hotels: sorted,
              hotelIndex: i,
              cityName: cityName,
              destinationIata: destinationIata,
              checkIn: checkIn,
              checkOut: checkOut,
              nights: nights,
              guests: guests,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Otobüs
// ─────────────────────────────────────────────────────────────────────────────

class CategoryBusResultsScreen extends StatefulWidget {
  const CategoryBusResultsScreen({
    super.key,
    required this.initialResult,
    required this.fromCity,
    required this.toCity,
    required this.date,
    required this.passengers,
    required this.onSearchAgain,
  });

  final CatalogSearchResult initialResult;
  final String fromCity;
  final String toCity;
  final DateTime date;
  final int passengers;
  final Future<CatalogSearchResult> Function() onSearchAgain;

  @override
  State<CategoryBusResultsScreen> createState() =>
      _CategoryBusResultsScreenState();
}

class _CategoryBusResultsScreenState extends State<CategoryBusResultsScreen> {
  late CatalogSearchResult _result = widget.initialResult;
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    final next = await widget.onSearchAgain();
    if (mounted) {
      setState(() {
        _result = next;
        _refreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trips = _result.items;

    return _CategoryResultsScaffold(
      category: SearchCategory.bus,
      title: 'Otobüs Seferleri',
      subtitle:
          '${widget.fromCity} → ${widget.toCity} · ${_fmtDate(widget.date)}',
      countLabel: '${trips.length} sefer',
      result: _result,
      isRefreshing: _refreshing,
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: trips.length,
        itemBuilder: (context, i) {
          final trip = trips[i];
          final dep = trip['departureTime'] as DateTime;
          final duration = trip['durationMinutes'] as int;
          final hours = duration ~/ 60;
          final mins = duration % 60;

          return _ResultCard(
            title: trip['operator'] as String,
            subtitle:
                'Kalkış ${_fmtTime(dep)} · $hours sa ${mins > 0 ? '$mins dk' : ''}\n'
                '${trip['seatType']} · ${(trip['amenities'] as List).join(' · ')}',
            badge: 'Otobüs',
            price: PriceFormat.format(trip['priceTL'] as int),
            actionLabel: 'İncele',
            onTap: () => pushAppRoute(
              context,
              CategorySimpleCheckoutScreen(
                category: SearchCategory.bus,
                title: '${trip['operator']} · ${widget.fromCity} → ${widget.toCity}',
                subtitle:
                    'Kalkış ${_fmtTime(dep)} · ${_fmtDate(widget.date)}\n'
                    '${trip['seatType']}',
                priceTL: trip['priceTL'] as int,
                destinationCity: widget.toCity,
                passengers: trip['passengers'] as int? ?? widget.passengers,
                departureDate: widget.date,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transfer
// ─────────────────────────────────────────────────────────────────────────────

class CategoryTransferResultsScreen extends StatefulWidget {
  const CategoryTransferResultsScreen({
    super.key,
    required this.initialResult,
    required this.destinationCity,
    required this.fromLabel,
    required this.toLabel,
    required this.date,
    required this.passengers,
    required this.onSearchAgain,
  });

  final CatalogSearchResult initialResult;
  final String destinationCity;
  final String fromLabel;
  final String toLabel;
  final DateTime date;
  final int passengers;
  final Future<CatalogSearchResult> Function() onSearchAgain;

  @override
  State<CategoryTransferResultsScreen> createState() =>
      _CategoryTransferResultsScreenState();
}

class _CategoryTransferResultsScreenState
    extends State<CategoryTransferResultsScreen> {
  late CatalogSearchResult _result = widget.initialResult;
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    final next = await widget.onSearchAgain();
    if (mounted) {
      setState(() {
        _result = next;
        _refreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final transfers = _result.items;

    return _CategoryResultsScaffold(
      category: SearchCategory.transfer,
      title: 'Transfer Seçenekleri',
      subtitle:
          '${widget.destinationCity} · ${widget.fromLabel} → ${widget.toLabel}\n'
          '${_fmtDate(widget.date)} · ${widget.passengers} yolcu',
      countLabel: '${transfers.length} seçenek',
      result: _result,
      isRefreshing: _refreshing,
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: transfers.length,
        itemBuilder: (context, i) {
          final t = transfers[i];
          final includes = List<String>.from(t['includes'] ?? []);
          return _ResultCard(
            title: t['name'] as String,
            subtitle:
                '${t['fromLabel']} → ${t['toLabel']}\n'
                '${t['durationMinutes']} dk · max ${t['maxPassengers']} kişi\n'
                '${includes.join(' · ')}',
            badge: (t['vehicleType'] as String?) ?? 'transfer',
            price: PriceFormat.format((t['priceTL'] as num).toInt()),
            actionLabel: 'Rezerve et',
            onTap: () => pushAppRoute(
              context,
              CategorySimpleCheckoutScreen(
                category: SearchCategory.transfer,
                title: t['name'] as String,
                subtitle:
                    '${widget.destinationCity} · ${t['fromLabel']} → ${t['toLabel']}\n'
                    '${_fmtDate(widget.date)}',
                priceTL: (t['priceTL'] as num).toInt(),
                destinationCity: widget.destinationCity,
                passengers: widget.passengers,
                departureDate: widget.date,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Araç kiralama
// ─────────────────────────────────────────────────────────────────────────────

class CategoryCarRentalResultsScreen extends StatefulWidget {
  const CategoryCarRentalResultsScreen({
    super.key,
    required this.initialResult,
    required this.city,
    required this.pickup,
    required this.dropoff,
    required this.onSearchAgain,
  });

  final CatalogSearchResult initialResult;
  final String city;
  final DateTime pickup;
  final DateTime dropoff;
  final Future<CatalogSearchResult> Function() onSearchAgain;

  @override
  State<CategoryCarRentalResultsScreen> createState() =>
      _CategoryCarRentalResultsScreenState();
}

class _CategoryCarRentalResultsScreenState
    extends State<CategoryCarRentalResultsScreen> {
  late CatalogSearchResult _result = widget.initialResult;
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    final next = await widget.onSearchAgain();
    if (mounted) {
      setState(() {
        _result = next;
        _refreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cars = _result.items;
    final days = widget.dropoff.difference(widget.pickup).inDays.clamp(1, 30);

    return _CategoryResultsScaffold(
      category: SearchCategory.carRental,
      title: 'Araç Kiralama',
      subtitle:
          '${widget.city} · $days gün\n'
          '${_fmtDate(widget.pickup)} – ${_fmtDate(widget.dropoff)}',
      countLabel: '${cars.length} araç',
      result: _result,
      isRefreshing: _refreshing,
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: cars.length,
        itemBuilder: (context, i) {
          final car = cars[i];
          return _ResultCard(
            title: '${car['vehicleType']} · ${car['provider']}',
            subtitle:
                '${car['model']}\n'
                '${car['transmission']} · ${car['seats']} koltuk · ${car['bags']} bagaj\n'
                '${car['fuelPolicy']} · ${car['mileage']}',
            badge: 'Günlük',
            price: PriceFormat.format(car['totalPriceTL'] as int),
            trailing: Text(
              '${PriceFormat.format(car['dailyPriceTL'] as int)}/gün',
              style: TatilTheme.hint.copyWith(fontSize: 11),
            ),
            actionLabel: 'Kirala',
            onTap: () => pushAppRoute(
              context,
              CategorySimpleCheckoutScreen(
                category: SearchCategory.carRental,
                title: '${car['vehicleType']} · ${car['provider']}',
                subtitle:
                    '${car['model']}\n'
                    '${_fmtDate(widget.pickup)} – ${_fmtDate(widget.dropoff)} · ${widget.city}',
                priceTL: car['totalPriceTL'] as int,
                destinationCity: widget.city,
                departureDate: widget.pickup,
                returnDate: widget.dropoff,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared UI
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryResultsScaffold extends StatelessWidget {
  const _CategoryResultsScaffold({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.child,
    this.result,
    this.isEmpty = false,
    this.emptyMessage,
    this.isRefreshing = false,
    this.onRefresh,
  });

  final SearchCategory category;
  final String title;
  final String subtitle;
  final String countLabel;
  final Widget child;
  final CatalogSearchResult? result;
  final bool isEmpty;
  final String? emptyMessage;
  final bool isRefreshing;
  final Future<void> Function()? onRefresh;

  bool get _showEmpty {
    if (result != null) return result!.isEmpty;
    return isEmpty;
  }

  String get _emptyTitle {
    if (result?.isError == true) {
      return result!.errorMessage ?? 'Arama tamamlanamadı';
    }
    return emptyMessage ?? 'Sonuç bulunamadı';
  }

  String get _emptyMessage {
    if (result?.isError == true) {
      return 'Bağlantıyı kontrol edip yeniden deneyin veya arama kriterlerinizi düzenleyin.';
    }
    if (result?.isFallback == true) {
      return 'Canlı API yanıt vermedi; yedek katalog sonuçları da boş. '
          'Farklı tarih veya güzergâh deneyin.';
    }
    return 'Farklı tarih veya destinasyon deneyin. '
        'Arama kriterlerinizi düzenleyip tekrar arayabilirsiniz.';
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(category.icon, size: 18, color: AppTheme.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (onRefresh != null)
            IconButton(
              onPressed: isRefreshing ? null : onRefresh,
              icon: isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CupertinoActivityIndicator(radius: 9),
                    )
                  : const Icon(CupertinoIcons.arrow_clockwise, size: 20),
              color: AppTheme.orange,
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: PreviewModeBanner(compact: true),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(subtitle, style: TatilTheme.hint.copyWith(height: 1.4)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  countLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.teal,
                  ),
                ),
                if (result != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: result!.isFallback
                          ? AppTheme.orangeSoft
                          : AppTheme.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      result!.statusHint,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: result!.isFallback
                            ? AppTheme.orange
                            : AppTheme.teal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (result?.isFallback == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Canlı API şu an yanıt vermedi; gösterilen sonuçlar yedek katalogdan geliyor.',
                style: TatilTheme.hint.copyWith(
                  fontSize: 11,
                  color: AppTheme.orange,
                  height: 1.35,
                ),
              ),
            ),
          Expanded(
            child: _showEmpty
                ? TravelStateView(
                    icon: category.icon,
                    title: _emptyTitle,
                    message: _emptyMessage,
                    primaryLabel: onRefresh != null ? 'Yeniden dene' : 'Aramayı düzenle',
                    onPrimary: onRefresh ?? () => Navigator.pop(context),
                    secondaryLabel: onRefresh != null ? 'Aramayı düzenle' : null,
                    onSecondary:
                        onRefresh != null ? () => Navigator.pop(context) : null,
                  )
                : child,
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.price,
    required this.onTap,
    this.trailing,
    this.actionLabel = 'Seç',
  });

  final String title;
  final String subtitle;
  final String badge;
  final String price;
  final VoidCallback onTap;
  final Widget? trailing;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TatilTheme.hint.copyWith(fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.orangeSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.teal,
                      ),
                    ),
                    if (trailing != null) trailing!,
                    const SizedBox(height: 4),
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _openFlightCheckout(
  BuildContext context, {
  required List<Map<String, dynamic>> flights,
  required int flightIndex,
  required String originIata,
  required String destinationCity,
  required String destinationIata,
  required DateTime departureDate,
  required DateTime returnDate,
  required int passengers,
  bool isRoundTrip = true,
  String destinationCountry = '',
  FlightCabinClass cabinClass = FlightCabinClass.economy,
  String? pendingCouponCode,
}) {
  final nights = isRoundTrip
      ? returnDate.difference(departureDate).inDays.clamp(1, 30)
      : 1;
  final cabinMult = cabinClass.priceMultiplier;
  final route = CategoryCheckoutRoute.build(
    destinationIata: destinationIata,
    cityName: destinationCity,
    country: destinationCountry,
    nights: nights,
    passengers: passengers,
    flightTL: PriceFormat.flightTotalTL(
      flights[flightIndex],
      roundTrip: isRoundTrip,
      cabinMultiplier: cabinMult,
    ),
  );

  pushRouteResults(
    context,
    CheckoutScreen(
      originIata: originIata,
      route: route,
      flights: flights,
      hotels: const [],
      departureDate: departureDate,
      returnDate: isRoundTrip ? returnDate : departureDate,
      children: 0,
      adults: passengers,
      scope: BookingScope.flightOnly,
      initialFlightIndex: flightIndex,
      isRoundTrip: isRoundTrip,
      cabinClass: cabinClass,
      initialCouponCode: pendingCouponCode,
    ),
  );
}

void _openHotelCheckout(
  BuildContext context, {
  required List<Map<String, dynamic>> hotels,
  required int hotelIndex,
  required String cityName,
  required String destinationIata,
  required DateTime checkIn,
  required DateTime checkOut,
  required int nights,
  required int guests,
}) {
  final hotel = hotels[hotelIndex];
  final route = CategoryCheckoutRoute.build(
    destinationIata: destinationIata,
    cityName: cityName,
    nights: nights,
    passengers: guests,
    hotelTL: PriceFormat.hotelTotalTL(hotel, nights),
  );

  pushRouteResults(
    context,
    CheckoutScreen(
      originIata: 'IST',
      route: route,
      flights: const [],
      hotels: hotels,
      departureDate: checkIn,
      returnDate: checkOut,
      children: 0,
      adults: guests,
      scope: BookingScope.hotelOnly,
      initialHotelIndex: hotelIndex,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Çoklu uçuş
// ─────────────────────────────────────────────────────────────────────────────

class CategoryMultiCityResultsScreen extends StatefulWidget {
  const CategoryMultiCityResultsScreen({
    super.key,
    required this.result,
    required this.passengers,
    this.cabinClass = FlightCabinClass.economy,
    this.pendingCouponCode,
  });

  final MultiCitySearchResult result;
  final int passengers;
  final FlightCabinClass cabinClass;
  final String? pendingCouponCode;

  @override
  State<CategoryMultiCityResultsScreen> createState() =>
      _CategoryMultiCityResultsScreenState();
}

class _CategoryMultiCityResultsScreenState
    extends State<CategoryMultiCityResultsScreen> {
  late List<MultiCityLegResult> _legs;
  bool _loadingPackage = false;

  @override
  void initState() {
    super.initState();
    _legs = List<MultiCityLegResult>.from(widget.result.legs);
  }

  int get _totalTL => _legs.fold(0, (s, l) => s + l.selectedPriceTL);

  void _openCheckout() {
    if (_legs.any((l) => l.flights.isEmpty)) return;
    final last = _legs.last.leg;
    final combinedFlights = <Map<String, dynamic>>[];
    for (final leg in _legs) {
      final f = leg.selectedFlight;
      if (f != null) combinedFlights.add(f);
    }
    final route = CategoryCheckoutRoute.build(
      destinationIata: last.destinationIata,
      cityName: last.destinationCity,
      country: '',
      nights: 1,
      passengers: widget.passengers,
      flightTL: _totalTL,
    );

    pushRouteResults(
      context,
      CheckoutScreen(
        originIata: _legs.first.leg.originIata,
        route: route,
        flights: combinedFlights.isNotEmpty ? combinedFlights : const [],
        hotels: const [],
        departureDate: _legs.first.leg.departureDate,
        returnDate: last.departureDate,
        children: 0,
        adults: widget.passengers,
        scope: BookingScope.flightOnly,
        initialFlightIndex: 0,
        isRoundTrip: false,
        cabinClass: widget.cabinClass,
        initialCouponCode: widget.pendingCouponCode,
        multiCityLegs: _legs.map((l) => l.leg).toList(),
      ),
    );
  }

  Future<void> _openPackageCheckout() async {
    if (_legs.any((l) => l.flights.isEmpty) || _loadingPackage) return;
    setState(() => _loadingPackage = true);
    try {
      final offer = await MultiCityPackageService.buildPackage(
        selectedLegs: _legs,
        passengers: widget.passengers,
      );
      if (!mounted) return;
      if (offer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Son destinasyon için otel bulunamadı. Sadece uçuşla devam edebilirsiniz.',
            ),
          ),
        );
        return;
      }

      pushRouteResults(
        context,
        CheckoutScreen(
          originIata: offer.originIata,
          route: offer.route,
          flights: offer.flights,
          hotels: offer.hotels,
          departureDate: offer.departureDate,
          returnDate: offer.returnDate,
          children: 0,
          adults: widget.passengers,
          scope: BookingScope.package,
          initialFlightIndex: 0,
          initialHotelIndex: 0,
          isRoundTrip: false,
          cabinClass: widget.cabinClass,
          initialCouponCode: widget.pendingCouponCode,
          multiCityLegs: offer.legs,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingPackage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Çoklu Uçuş'),
        backgroundColor: AppTheme.bgPrimary,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: widget.result.hasAnyFlights
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                const PreviewModeBanner(compact: true),
                const SizedBox(height: 8),
                Text(
                  'Toplam ${PriceFormat.format(_totalTL)}',
                  style: TatilTheme.priceDisplay(fontSize: 22),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _legs.length; i++) ...[
                  _LegSection(
                    index: i + 1,
                    legResult: _legs[i],
                    onSelectFlight: (idx) {
                      setState(() {
                        _legs[i] = _legs[i].copyWith(selectedFlightIndex: idx);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            )
          : TravelStateView(
              icon: CupertinoIcons.airplane,
              title: 'Uçuş bulunamadı',
              message: 'Bacak tarihlerini veya güzergâhı değiştirip tekrar deneyin.',
              primaryLabel: 'Geri dön',
              onPrimary: () => Navigator.pop(context),
            ),
      bottomNavigationBar: widget.result.hasAnyFlights
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: _loadingPackage ? null : _openPackageCheckout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.teal,
                        side: const BorderSide(color: AppTheme.teal),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loadingPackage
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Paket tamamla (otel + transfer)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _openCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Sadece uçuş · ${PriceFormat.format(_totalTL)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _LegSection extends StatelessWidget {
  const _LegSection({
    required this.index,
    required this.legResult,
    required this.onSelectFlight,
  });

  final int index;
  final MultiCityLegResult legResult;
  final ValueChanged<int> onSelectFlight;

  @override
  Widget build(BuildContext context) {
    final leg = legResult.leg;
    final flights = legResult.flights;

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
          Text(
            'Bacak $index · ${leg.originCity} → ${leg.destinationCity}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            _fmtDate(leg.departureDate),
            style: TatilTheme.hint.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (flights.isEmpty)
            Text(
              'Bu bacak için uçuş yok',
              style: TatilTheme.hint.copyWith(fontSize: 12),
            )
          else
            ...List.generate(flights.length.clamp(0, 5), (i) {
              final f = flights[i];
              final selected = i == legResult.selectedFlightIndex;
              final price =
                  PriceFormat.formatFlightPrice(f, roundTrip: false) ?? '—';
              final airline = f['airlineName'] ?? f['airline'] ?? 'Havayolu';
              return GestureDetector(
                onTap: () => onSelectFlight(i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.teal.withValues(alpha: 0.1)
                        : AppTheme.bgTertiary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppTheme.teal : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? CupertinoIcons.check_mark_circled_solid
                            : CupertinoIcons.circle,
                        size: 18,
                        color: selected ? AppTheme.teal : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          airline.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color:
                              selected ? AppTheme.teal : AppTheme.textPrimary,
                        ),
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
}
