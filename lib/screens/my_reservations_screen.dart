import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/reservation_filter.dart';
import '../models/search_category.dart';
import '../models/stored_booking_model.dart';
import '../services/travel_booking_service.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/app_navigation.dart';
import '../utils/flight_schedule_format.dart';
import '../utils/price_format.dart';
import '../widgets/travel_state_view.dart';
import 'reservation_detail_screen.dart';

/// Profil → Rezervasyonlarım
class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  List<StoredBooking> _bookings = [];
  bool _loading = true;
  ReservationFilter _filter = ReservationFilter.all;

  static const _filters = [
    ReservationFilter.all,
    ReservationFilter.package,
    ReservationFilter.flight,
    ReservationFilter.hotel,
    ReservationFilter.bus,
    ReservationFilter.carRental,
    ReservationFilter.transfer,
    ReservationFilter.activities,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await TravelBookingService.fetchBookings();
    if (!mounted) return;
    setState(() {
      _bookings = list;
      _loading = false;
    });
  }

  List<StoredBooking> get _visibleBookings =>
      _bookings.where((b) => b.matchesReservationFilter(_filter)).toList();

  IconData _iconFor(StoredBooking b) {
    final pc = b.productCategory;
    if (pc != null) {
      for (final c in SearchCategory.values) {
        if (c.name == pc) return c.icon;
      }
    }
    if (b.bookingScope == 'hotelOnly') return CupertinoIcons.house_fill;
    if (b.bookingScope == 'flightOnly') return CupertinoIcons.airplane;
    if (b.hasHotel && b.hasFlight) return CupertinoIcons.bag_fill;
    if (b.hasHotel) return CupertinoIcons.house_fill;
    return CupertinoIcons.airplane;
  }

  Color _iconColorFor(StoredBooking b) {
    final pc = b.productCategory;
    if (pc == 'bus' || pc == 'carRental' || pc == 'transfer') {
      return AppTheme.orange;
    }
    if (pc == 'activities') return AppTheme.accent;
    if (b.bookingScope == 'hotelOnly') return AppTheme.orange;
    if (b.hasHotel && b.hasFlight) return AppTheme.accent;
    return AppTheme.teal;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleBookings;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rezervasyonlarım',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : _bookings.isEmpty
              ? _emptyState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final f = _filters[index];
                          final selected = _filter == f;
                          return FilterChip(
                            label: Text(f.label),
                            selected: selected,
                            onSelected: (_) => setState(() => _filter = f),
                            selectedColor: AppTheme.orangeSoft,
                            checkmarkColor: AppTheme.orange,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w600,
                              color: selected
                                  ? AppTheme.orange
                                  : AppTheme.textSecondary,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? AppTheme.orange.withValues(alpha: 0.4)
                                  : AppTheme.border,
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? _filteredEmptyState()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: visible.length,
                                itemBuilder: (context, index) {
                                  final b = visible[index];
                                  final times = b.isStandaloneProduct
                                      ? ''
                                      : FlightScheduleFormat.roundTripTimesLine(
                                          b.flightMap(),
                                          b.departureDate,
                                          b.returnDate,
                                        );
                                  final priceLabel = b.totalPriceTL > 0
                                      ? PriceFormat.format(b.totalPriceTL)
                                      : '—';

                                  return GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ReservationDetailScreen(
                                            booking: b,
                                          ),
                                        ),
                                      );
                                      _load();
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bgSecondary,
                                        borderRadius: BorderRadius.circular(16),
                                        border:
                                            Border.all(color: AppTheme.border),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: _iconColorFor(b)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _iconFor(b),
                                              color: _iconColorFor(b),
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  b.listTitle,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                if (b.hotelName != null &&
                                                    b.hotelName!.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    b.hotelName!,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TatilTheme.hint
                                                        .copyWith(
                                                      fontSize: 12,
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 2),
                                                Text(
                                                  [
                                                    b.listSubtitle,
                                                    if (times.isNotEmpty) times,
                                                  ].join(' · '),
                                                  style: TatilTheme.hint
                                                      .copyWith(fontSize: 12),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  b.shortReservationRef,
                                                  style: TatilTheme.hint
                                                      .copyWith(
                                                    fontSize: 11,
                                                    color: AppTheme.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            priceLabel,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: b.totalPriceTL > 0
                                                  ? AppTheme.orange
                                                  : AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  void _goExplore({SearchCategory? category}) {
    AppNavigation.popToExplore(context, category: category);
  }

  Widget _emptyState() {
    return TravelStateView(
      icon: CupertinoIcons.doc_text,
      title: 'Henüz rezervasyon yok',
      message:
          'Tamamladığınız önizleme talepleri burada listelenir. '
          'Keşfet sekmesinden arama yaparak ilk rezervasyonunuzu oluşturabilirsiniz.',
      primaryLabel: 'Keşfet\'e dön',
      onPrimary: () => _goExplore(),
    );
  }

  Widget _filteredEmptyState() {
    final exploreCategory = _filter == ReservationFilter.activities
        ? SearchCategory.activities
        : null;
    return TravelStateView(
      icon: CupertinoIcons.slider_horizontal_3,
      title: '${_filter.label} için kayıt yok',
      message: 'Bu kategoride henüz rezervasyon bulunmuyor. '
          'Farklı bir filtre seçebilir veya Keşfet\'ten yeni arama yapabilirsiniz.',
      primaryLabel: 'Tümünü göster',
      onPrimary: () => setState(() => _filter = ReservationFilter.all),
      secondaryLabel: 'Keşfet\'e dön',
      onSecondary: () => _goExplore(category: exploreCategory),
    );
  }
}
