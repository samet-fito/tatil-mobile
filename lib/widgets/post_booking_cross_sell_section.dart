import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/booking_scope.dart';
import '../models/route_result_model.dart';
import '../models/search_category.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/custom_page_route.dart';
import '../utils/app_navigation.dart';
import '../utils/category_checkout_route.dart';
import '../utils/price_format.dart';
import '../screens/checkout_screen.dart';

/// Rezervasyon sonrası çapraz satış — uçuş→otel veya otel→uçuş.
class PostBookingCrossSellSection extends StatefulWidget {
  const PostBookingCrossSellSection({
    super.key,
    required this.route,
    required this.departureDate,
    required this.returnDate,
    required this.adults,
    required this.children,
    this.selectedFlight,
    this.selectedHotel,
    this.originIata = 'IST',
    this.isRoundTrip = true,
  });

  final RouteResultModel route;
  final DateTime departureDate;
  final DateTime returnDate;
  final int adults;
  final int children;
  final Map<String, dynamic>? selectedFlight;
  final Map<String, dynamic>? selectedHotel;
  final String originIata;
  final bool isRoundTrip;

  bool get suggestHotels =>
      selectedFlight != null && selectedHotel == null;
  bool get suggestFlights =>
      selectedHotel != null && selectedFlight == null;

  @override
  State<PostBookingCrossSellSection> createState() =>
      _PostBookingCrossSellSectionState();
}

class _PostBookingCrossSellSectionState extends State<PostBookingCrossSellSection> {
  List<Map<String, dynamic>> _offers = [];
  bool _loading = true;
  int _stayNights = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  ({DateTime checkIn, DateTime checkOut, int nights}) _stayDates() {
    if (!widget.isRoundTrip) {
      final checkIn = widget.departureDate;
      return (
        checkIn: checkIn,
        checkOut: checkIn.add(const Duration(days: 1)),
        nights: 1,
      );
    }

    var checkOut = widget.returnDate;
    if (!checkOut.isAfter(widget.departureDate)) {
      checkOut = widget.departureDate.add(const Duration(days: 3));
    }
    final nights =
        checkOut.difference(widget.departureDate).inDays.clamp(1, 14);
    return (
      checkIn: widget.departureDate,
      checkOut: checkOut,
      nights: nights,
    );
  }

  String _formatShortDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _load() async {
    if (!widget.suggestHotels && !widget.suggestFlights) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      if (widget.suggestHotels) {
        final stay = _stayDates();
        _stayNights = stay.nights;
        var hotels = await ApiService.searchHotels(
          cityName: widget.route.cityName,
          checkIn: stay.checkIn,
          returnDate: stay.checkOut,
          adults: widget.adults,
          destinationIata: widget.route.destinationIata,
          nights: stay.nights,
        );
        if (hotels.isEmpty && widget.isRoundTrip) {
          final extendedOut = stay.checkIn.add(const Duration(days: 5));
          hotels = await ApiService.searchHotels(
            cityName: widget.route.cityName,
            checkIn: stay.checkIn,
            returnDate: extendedOut,
            adults: widget.adults,
            destinationIata: widget.route.destinationIata,
            nights: 5,
          );
          if (hotels.isNotEmpty) _stayNights = 5;
        }
        hotels.sort(_compareHotelOffers);
        if (mounted) {
          setState(() {
            _offers = hotels.take(5).toList();
            _loading = false;
          });
        }
        return;
      }

      final flights = await ApiService.searchRealFlights(
        originIata: widget.originIata,
        destinationIata: widget.route.destinationIata,
        departureDate: widget.departureDate,
        returnDate: widget.returnDate.isAfter(widget.departureDate)
            ? widget.returnDate
            : widget.departureDate.add(const Duration(days: 3)),
        passengers: widget.adults + widget.children,
        isRoundTrip: true,
      );
      if (mounted) {
        setState(() {
          _offers = flights.take(5).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _compareHotelOffers(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aPromo = _isPromoHotel(a);
    final bPromo = _isPromoHotel(b);
    if (aPromo != bPromo) return aPromo ? -1 : 1;
    final pa = PriceFormat.hotelPerNightTL(a, nights: 1);
    final pb = PriceFormat.hotelPerNightTL(b, nights: 1);
    return pa.compareTo(pb);
  }

  bool _isPromoHotel(Map<String, dynamic> h) {
    if (h['promo'] == true || h['deal'] == true) return true;
    final discount = (h['discountPercent'] as num?)?.toInt() ?? 0;
    if (discount > 0) return true;
    final tags = h['tags'];
    if (tags is List &&
        tags.any((t) => t.toString().toLowerCase().contains('kampanya'))) {
      return true;
    }
    return false;
  }

  void _openHotelCheckout(Map<String, dynamic> hotel) {
    final stay = _stayDates();
    final hotelList = [hotel, ..._offers.where((h) => h != hotel)];
    final route = CategoryCheckoutRoute.build(
      destinationIata: widget.route.destinationIata,
      cityName: widget.route.cityName,
      country: widget.route.country,
      nights: stay.nights,
      passengers: widget.adults + widget.children,
      hotelTL: PriceFormat.hotelTotalTL(hotel, stay.nights),
    );
    pushAppRoute(
      context,
      CheckoutScreen(
        originIata: widget.originIata,
        route: route,
        flights: const [],
        hotels: hotelList,
        departureDate: stay.checkIn,
        returnDate: stay.checkOut,
        children: widget.children,
        adults: widget.adults,
        scope: BookingScope.hotelOnly,
        initialHotelIndex: 0,
      ),
    );
  }

  void _openHotelSearch() {
    AppNavigation.openExploreTab(context, category: SearchCategory.hotel);
  }

  void _openFlightCheckout(Map<String, dynamic> flight) {
    pushAppRoute(
      context,
      CheckoutScreen(
        originIata: widget.originIata,
        route: widget.route,
        flights: [flight, ..._offers.where((f) => f != flight)],
        hotels: widget.selectedHotel != null ? [widget.selectedHotel!] : const [],
        departureDate: widget.departureDate,
        returnDate: widget.returnDate,
        children: widget.children,
        adults: widget.adults,
        scope: widget.selectedHotel != null
            ? BookingScope.package
            : BookingScope.flightOnly,
        initialFlightIndex: 0,
        initialHotelIndex: widget.selectedHotel != null ? 0 : null,
        isRoundTrip: widget.isRoundTrip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.suggestHotels && !widget.suggestFlights) {
      return const SizedBox.shrink();
    }

    final title = widget.suggestHotels
        ? '${widget.route.cityName} otelleri'
        : '${widget.route.cityName} uçuşları';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.suggestHotels
                    ? CupertinoIcons.bed_double
                    : CupertinoIcons.airplane,
                color: AppTheme.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.suggestHotels
                ? widget.isRoundTrip
                    ? 'Gecelik fiyatlar · $_stayNights gece · '
                        '${_formatShortDate(widget.departureDate)} – '
                        '${_formatShortDate(_stayDates().checkOut)}'
                    : 'Gecelik fiyatlar · tek gece'
                : 'Seçtiğiniz tarihlerde uygun uçuşlar',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CupertinoActivityIndicator(),
              ),
            )
          else if (_offers.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Otel listesi yüklenemedi.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _load,
                  child: const Text('Tekrar dene'),
                ),
                if (widget.suggestHotels)
                  TextButton(
                    onPressed: _openHotelSearch,
                    child: const Text('Keşfet\'ten otel ara'),
                  ),
              ],
            )
          else
            ..._offers.take(3).map((offer) {
              if (widget.suggestHotels) {
                return _HotelOfferTile(
                  hotel: offer,
                  isPromo: _isPromoHotel(offer),
                  onTap: () => _openHotelCheckout(offer),
                );
              }
              return _FlightOfferTile(
                flight: offer,
                onTap: () => _openFlightCheckout(offer),
              );
            }),
        ],
      ),
    );
  }
}

class _HotelOfferTile extends StatelessWidget {
  const _HotelOfferTile({
    required this.hotel,
    required this.isPromo,
    required this.onTap,
  });

  final Map<String, dynamic> hotel;
  final bool isPromo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = hotel['name']?.toString() ?? 'Otel';
    final perNight = PriceFormat.hotelPerNightTL(hotel, nights: 1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isPromo ? AppTheme.orangeSoft : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isPromo)
                        Text(
                          'Kampanyalı',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.orange,
                          ),
                        ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${PriceFormat.format(perNight)}/gece',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.orange,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(CupertinoIcons.chevron_right, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlightOfferTile extends StatelessWidget {
  const _FlightOfferTile({required this.flight, required this.onTap});

  final Map<String, dynamic> flight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final airline = flight['airlineName'] ?? flight['airline'] ?? 'Uçuş';
    final price = PriceFormat.formatFlightPrice(flight, roundTrip: true) ?? '—';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    airline.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  price,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.orange,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(CupertinoIcons.chevron_right, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
