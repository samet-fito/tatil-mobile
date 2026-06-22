import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/route_result_model.dart';
import '../services/api_service.dart';
import '../services/travel_document_service.dart';
import '../data/commission_activities.dart';
import '../theme/app_theme.dart';
import '../utils/app_navigation.dart';
import '../utils/price_format.dart';
import '../widgets/post_booking_cross_sell_section.dart';
import '../services/local_booking_store.dart';
import '../services/travel_guide_service.dart';
import '../utils/traveler_group_profile.dart';
import '../theme/custom_page_route.dart';
import 'commission_activities_screen.dart';
import 'destination_guide_screen.dart';
import 'reservation_detail_screen.dart';

class BookingSuccessScreen extends StatefulWidget {
  final RouteResultModel route;
  final Map<String, dynamic>? selectedFlight;
  final Map<String, dynamic>? selectedHotel;
  final DateTime departureDate;
  final DateTime returnDate;
  final int adults;
  final int children;
  final int totalPrice;
  final String passengerName;
  final String passengerEmail;
  final String reservationId;
  final List<int> passengerAges;
  final bool insuranceAlreadyPaid;
  final List<String> holidayTypes;
  final String originIata;
  final bool isRoundTrip;

  const BookingSuccessScreen({
    super.key,
    required this.route,
    this.selectedFlight,
    this.selectedHotel,
    required this.departureDate,
    required this.returnDate,
    required this.adults,
    required this.children,
    required this.totalPrice,
    required this.passengerName,
    required this.passengerEmail,
    required this.reservationId,
    this.passengerAges = const [],
    this.insuranceAlreadyPaid = false,
    this.holidayTypes = const [],
    this.originIata = 'IST',
    this.isRoundTrip = true,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> {
  Map<String, dynamic>? _activitiesData;
  bool _activitiesLoading = true;
  bool _guideLoading = true;
  bool _guideReady = false;

  TravelerGroupProfile get _groupProfile => TravelerGroupProfile.from(
        adults: widget.adults,
        children: widget.children,
        passengerAges: widget.passengerAges,
      );



  @override
  void initState() {
    super.initState();
    _loadActivities();
    _prefetchTravelGuide();
  }

  Future<void> _prefetchTravelGuide() async {
    try {
      await TravelGuideService.prefetch(
        reservationId: widget.reservationId,
        cityName: widget.route.cityName,
        country: widget.route.country,
        destinationIata: widget.route.destinationIata,
        departureDate: widget.departureDate,
        returnDate: widget.returnDate,
        nights: widget.route.nights,
        adults: widget.adults,
        children: widget.children,
        passengerAges: widget.passengerAges,
        hotelName: widget.selectedHotel?['name']?.toString(),
        holidayTypes: widget.holidayTypes,
      );
      final ready = await TravelGuideService.isCached(widget.reservationId);
      if (!mounted) return;
      setState(() {
        _guideLoading = false;
        _guideReady = ready;
      });
      if (ready) {
        // Rehber hazır — kullanıcı karttan açsın (otomatik yönlendirme yok).
      }
    } catch (_) {
      if (mounted) setState(() => _guideLoading = false);
    }
  }

  void _openDestinationGuide({bool autoPresented = false}) {
    pushAppRoute(
      context,
      DestinationGuideScreen(
        cityName: widget.route.cityName,
        country: widget.route.country,
        destinationIata: widget.route.destinationIata,
        departureDate: widget.departureDate,
        returnDate: widget.returnDate,
        nights: widget.route.nights,
        adults: widget.adults,
        children: widget.children,
        passengerAges: widget.passengerAges,
        hotelName: widget.selectedHotel?['name']?.toString(),
        reservationId: widget.reservationId,
        groupProfileLabel: _groupProfile.summaryLabel,
        holidayTypes: widget.holidayTypes,
      ),
    );
  }


  Future<void> _loadActivities() async {
    setState(() => _activitiesLoading = true);
    final dep = widget.departureDate.toIso8601String().split('T')[0];
    final ret = widget.returnDate.toIso8601String().split('T')[0];
    final iata = widget.route.destinationIata;
    final city = widget.route.cityName;

    Map<String, dynamic>? catalog;

    try {
      final apiResult = await ApiService.getCommissionActivities(
        iata: iata,
        cityName: city,
        departure: dep,
        returnDate: ret,
      );
      if (apiResult['success'] == true && apiResult['data'] != null) {
        catalog = apiResult['data'] as Map<String, dynamic>;
      }
    } catch (_) {}

    if (catalog == null) {
      if (!mounted) return;
      setState(() => _activitiesLoading = false);
      return;
    }

    if (!mounted) return;
    setState(() {
      _activitiesData = catalog;
      _activitiesLoading = false;
    });
  }

  void _openActivitiesCatalog() {
    final data = _activitiesData;
    if (data == null) return;
    pushAppRoute(
      context,
      CommissionActivitiesScreen(data: data),
    );
  }

  String _fmt(int price) => PriceFormat.format(price);

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  void _goHome() {
    AppNavigation.openExploreTab(context);
  }


  void _openEticket() {
    final flight = widget.selectedFlight;
    final airline = flight?['airline'] ?? flight?['owner']?['name'] ?? '--';
    TravelDocumentService.showDocumentOptions(
      context,
      title: 'E-Bilet',
      fileName: 'vizegoo-ebilet-${widget.reservationId}.html',
      webViewerUrl: TravelDocumentService.eticketViewerUrl(widget.reservationId),
      htmlBody: TravelDocumentService.buildEticketHtml(
        reservationId: widget.reservationId,
        passengerName: widget.passengerName,
        airline: airline.toString(),
        departure: _formatDate(widget.departureDate),
        returnDate: _formatDate(widget.returnDate),
        adults: widget.adults,
        children: widget.children,
      ),
    );
  }

  void _openVoucher() {
    final hotel = widget.selectedHotel;
    final hotelName = hotel?['name'] ?? widget.route.hotel?.name ?? '--';
    TravelDocumentService.showDocumentOptions(
      context,
      title: 'Otel Voucher',
      fileName: 'vizegoo-voucher-${widget.reservationId}.html',
      webViewerUrl: TravelDocumentService.voucherViewerUrl(widget.reservationId),
      htmlBody: TravelDocumentService.buildVoucherHtml(
        reservationId: widget.reservationId,
        passengerName: widget.passengerName,
        hotelName: hotelName.toString(),
        checkIn: _formatDate(widget.departureDate),
        checkOut: _formatDate(widget.returnDate),
        nights: widget.route.nights,
      ),
    );
  }

  void _bookActivity(Map<String, dynamic> activity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${activity['title']} — online rezervasyonunuz işleme alındı.',
        ),
        backgroundColor: AppTheme.orange,
      ),
    );
  }

  Future<void> _openTripCard() async {
    final stored = await LocalBookingStore.find(widget.reservationId);
    if (!mounted) return;
    if (stored != null) {
      pushAppRoute(context, ReservationDetailScreen(booking: stored));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seyahat kartı yüklenemedi. Profil → Rezervasyonlarım\'dan deneyin.'),
        backgroundColor: AppTheme.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F5F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: AppTheme.textPrimary),
          onPressed: _goHome,
        ),
        title: Text(
          'Rezervasyon Tamamlandı',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUnifiedSuccessCard(),
                  const SizedBox(height: 16),
                  PostBookingCrossSellSection(
                    route: widget.route,
                    departureDate: widget.departureDate,
                    returnDate: widget.returnDate,
                    adults: widget.adults,
                    children: widget.children,
                    selectedFlight: widget.selectedFlight,
                    selectedHotel: widget.selectedHotel,
                    originIata: widget.originIata,
                    isRoundTrip: widget.isRoundTrip,
                  ),
                  const SizedBox(height: 14),
                  _buildCompactGuideRow(),
                  const SizedBox(height: 16),
                  _buildActivitiesCatalogSection(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildUnifiedSuccessCard() {
    final flight = widget.selectedFlight;
    final hotel = widget.selectedHotel;
    final hasFlight = flight != null;
    final hasHotel = hotel != null;
    final airline = flight?['airline'] ?? flight?['owner']?['name'];
    final hotelName = hotel?['name'] ?? widget.route.hotel?.name;
    final flightPrice = hasFlight ? PriceFormat.flightTotalTL(flight, roundTrip: widget.isRoundTrip) : 0;
    final hotelPrice = hasHotel
        ? PriceFormat.hotelTotalTL(hotel, widget.route.nights)
        : 0;
    final dateLine = widget.isRoundTrip
        ? '${_formatDate(widget.departureDate)} – ${_formatDate(widget.returnDate)}'
        : _formatDate(widget.departureDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E4E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rezervasyon onaylandı',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        widget.reservationId,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E4E9)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.route.cityName,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (widget.route.country.isNotEmpty) widget.route.country,
                    dateLine,
                    '${widget.adults + widget.children} yolcu',
                    if (!widget.isRoundTrip && hasFlight) 'Tek yön',
                  ].join(' · '),
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
                if (hasFlight) ...[
                  const SizedBox(height: 14),
                  _compactProductRow(
                    icon: CupertinoIcons.airplane,
                    label: airline?.toString() ?? 'Uçuş',
                    price: flightPrice > 0 ? _fmt(flightPrice) : null,
                    docLabel: 'E-Bilet',
                    onDoc: _openEticket,
                  ),
                ],
                if (hasHotel) ...[
                  const SizedBox(height: 10),
                  _compactProductRow(
                    icon: CupertinoIcons.house_fill,
                    label: hotelName?.toString() ?? 'Otel',
                    price: hotelPrice > 0 ? _fmt(hotelPrice) : null,
                    docLabel: 'Voucher',
                    onDoc: _openVoucher,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Toplam ödenen',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  _fmt(widget.totalPrice),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactProductRow({
    required IconData icon,
    required String label,
    String? price,
    required String docLabel,
    required VoidCallback onDoc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              GestureDetector(
                onTap: onDoc,
                child: Text(
                  docLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (price != null)
          Text(
            price,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
      ],
    );
  }

  Widget _buildCompactGuideRow() {
    return GestureDetector(
      onTap: _guideReady ? () => _openDestinationGuide() : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E4E9)),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.book_fill,
              size: 18,
              color: _guideReady ? AppTheme.teal : AppTheme.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _guideReady
                    ? '${widget.route.cityName}\'da ne yapmalısın?'
                    : '${widget.route.cityName} rehberi hazırlanıyor…',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (_guideLoading)
              const CupertinoActivityIndicator(radius: 8)
            else
              const Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: AppTheme.textMuted,
              ),
          ],
        ),
      ),
    );
  }







  Widget _buildActivitiesCatalogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktivite Kataloğu',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.route.cityName} — turistlerin en çok tercih ettiği deneyimler',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            if (_activitiesData != null)
              TextButton(
                onPressed: _openActivitiesCatalog,
                child: Text(
                  'Tümü',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.orange,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_activitiesLoading)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E4E9)),
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(color: AppTheme.orange, strokeWidth: 2),
                const SizedBox(height: 12),
                Text(
                  'Popüler aktiviteler hazırlanıyor…',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                ),
              ],
            ),
          )
        else if (_activitiesData == null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E4E9)),
            ),
            child: Column(
              children: [
                Text(
                  'Aktiviteler yüklenemedi.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                ),
                TextButton(onPressed: _loadActivities, child: const Text('Tekrar Dene')),
              ],
            ),
          )
        else
          ...CommissionActivities.flatActivities(_activitiesData!)
              .take(2)
              .toList()
              .asMap()
              .entries
              .map((e) => _activityCatalogItem(e.value, e.key + 1)),
      ],
    );
  }

  Widget _activityCatalogItem(Map<String, dynamic> act, int rank) {
    final price = (act['priceTL'] as num?)?.toInt() ?? 0;
    final rating = (act['rating'] as num?)?.toDouble() ?? 0;
    final reviews = act['reviewCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E4E9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3 ? AppTheme.orangeSoft : const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#$rank',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: rank <= 3 ? AppTheme.orange : AppTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    act['title'] as String? ?? 'Aktivite',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    act['summary'] as String? ?? act['description'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        act['duration'] as String? ?? '—',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      const SizedBox(width: 10),
                      const Icon(CupertinoIcons.star_fill, size: 11, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 2),
                      Text(
                        '$rating ($reviews)',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (price > 0)
                  Text(
                    PriceFormat.format(price),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.orange,
                    ),
                  ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _bookActivity(act),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Satın Al',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          border: Border(top: BorderSide(color: AppTheme.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: _openTripCard,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Seyahat kartını aç',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: _goHome,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(vertical: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppTheme.textSecondary,
              ),
              child: Text(
                'Keşfet\'e dön',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
