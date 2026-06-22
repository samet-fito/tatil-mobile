import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/route_result_model.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/live_offer_matcher.dart';
import '../utils/route_display_pricing.dart';
import '../utils/price_format.dart';
import '../utils/plan_price_anchor.dart';
import '../utils/consumer_copy.dart';
import 'live_selection_skeleton.dart';
import 'offer_data_badge.dart';

/// Rota detay üstü — canlı uçuş + otel + net ödenecek tutar özeti.
class RouteBookingSummary extends StatelessWidget {
  const RouteBookingSummary({
    super.key,
    required this.route,
    required this.departureDate,
    required this.returnDate,
    required this.passengers,
    this.children = 0,
    this.liveFlights = const [],
    this.liveHotels = const [],
    this.loadingLive = false,
    this.extrasTL = 0,
    this.priceSourceLabel = 'Güncel fiyat',
    this.flightsFromLive = false,
    this.hotelsFromLive = false,
    this.selectedFlight,
    this.selectedHotel,
    this.recommendationHint,
    this.userBudgetTL,
  });

  final RouteResultModel route;
  final DateTime departureDate;
  final DateTime returnDate;
  final int passengers;
  final int children;
  final List<Map<String, dynamic>> liveFlights;
  final List<Map<String, dynamic>> liveHotels;
  final bool loadingLive;
  final int extrasTL;
  final String priceSourceLabel;
  final bool flightsFromLive;
  final bool hotelsFromLive;
  final Map<String, dynamic>? selectedFlight;
  final Map<String, dynamic>? selectedHotel;
  final String? recommendationHint;
  final int? userBudgetTL;

  String _date(DateTime d) => '${d.day}.${d.month}.${d.year}';

  bool get _hasPrices =>
      !loadingLive &&
      flightsFromLive &&
      hotelsFromLive &&
      liveFlights.isNotEmpty &&
      liveHotels.isNotEmpty;

  Map<String, dynamic>? get _matchedFlight =>
      selectedFlight ??
      LiveOfferMatcher.bestFlight(
        flights: liveFlights,
        planFlight: route.flight,
        planFlightTL: PlanPriceAnchor.planFlightTL(route),
      );

  Map<String, dynamic>? get _matchedHotel =>
      selectedHotel ??
      LiveOfferMatcher.bestHotel(
        hotels: liveHotels,
        planHotel: route.hotel,
        nights: route.nights,
        targetPerNightTL: RouteDisplayPricing.hotelPerNightTL(route),
      );

  int get _flightTL => _hasPrices && _matchedFlight != null
      ? PriceFormat.roundTripFlightTL(_matchedFlight!)
      : 0;

  int get _hotelTL => _hasPrices && _matchedHotel != null
      ? PriceFormat.hotelTotalTL(_matchedHotel!, route.nights)
      : 0;

  int get _transferTL => route.estimatedCost.transfer;

  int get _payableTL => PriceFormat.packagePayableTL(
        flightTL: _flightTL,
        hotelTL: _hotelTL,
        transferTL: _transferTL,
        extrasTL: extrasTL,
      );

  int get _recommendationPackageTL =>
      _flightTL + _hotelTL + _transferTL + extrasTL;

  int get _resolvedUserBudgetTL {
    if (userBudgetTL != null && userBudgetTL! > 0) return userBudgetTL!;
    return 0;
  }

  int get _remainingBudgetTL {
    final budget = _resolvedUserBudgetTL;
    if (budget <= 0) return 0;
    final remaining = budget - _recommendationPackageTL;
    return remaining > 0 ? remaining : 0;
  }

  int get _budgetOverageTL {
    final budget = _resolvedUserBudgetTL;
    if (budget <= 0) return 0;
    final over = _recommendationPackageTL - budget;
    return over > 0 ? over : 0;
  }

  bool get _showBudgetInsight => _hasPrices && _resolvedUserBudgetTL > 0;

  String _priceFootnote() {
    final kind = ConsumerCopy.offerDataKind(
      flightsLive: flightsFromLive &&
          PriceFormat.hasRoundTripFlightPrice(_matchedFlight),
      hotelsLive: hotelsFromLive,
      flightVerified: PriceFormat.hasRoundTripFlightPrice(_matchedFlight),
    );
    final base =
        '${ConsumerCopy.offerDataLabel(kind)} · uçuş + otel${_transferTL > 0 ? ' + transfer' : ''}${extrasTL > 0 ? ' + sigorta' : ''}';
    if (_showBudgetInsight) {
      if (_budgetOverageTL > 0) {
        return 'Bütçe aşımı ${PriceFormat.format(_budgetOverageTL)} · $base';
      }
      return 'Bütçeden geriye kalan ${PriceFormat.format(_remainingBudgetTL)} · $base';
    }
    return base;
  }

  OfferDataKind get _offerKind => ConsumerCopy.offerDataKind(
        flightsLive: flightsFromLive,
        hotelsLive: hotelsFromLive,
        flightVerified: PriceFormat.hasRoundTripFlightPrice(_matchedFlight),
      );

  @override
  Widget build(BuildContext context) {
    final people =
        children > 0 ? '$passengers yetişkin, $children çocuk' : '$passengers kişi';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.orange.withValues(alpha: 0.08),
            AppTheme.bgSecondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.orange.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route.cityName, style: TatilTheme.destination(fontSize: 20)),
                if (recommendationHint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    recommendationHint!,
                    style: TatilTheme.hint.copyWith(
                      color: AppTheme.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(CupertinoIcons.doc_text, color: AppTheme.orange, size: 16),
                    const SizedBox(width: 6),
                    Text('Rezervasyon özeti', style: TatilTheme.sectionLabel.copyWith(fontSize: 13)),
                    const Spacer(),
                    if (!loadingLive)
                      OfferDataBadge(kind: _offerKind, compact: true),
                  ],
                ),
                if (!loadingLive && _hasPrices) ...[
                  const SizedBox(height: 6),
                  Text(
                    ConsumerCopy.offerDataHint(
                      flightsLive: flightsFromLive,
                      hotelsLive: hotelsFromLive,
                      flightVerified:
                          PriceFormat.hasRoundTripFlightPrice(_matchedFlight),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_showBudgetInsight)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.teal.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppTheme.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _budgetOverageTL > 0
                            ? ConsumerCopy.recommendationOverBudgetInsight(
                                recommendationFormatted:
                                    PriceFormat.format(_recommendationPackageTL),
                                overFormatted: PriceFormat.format(_budgetOverageTL),
                              )
                            : ConsumerCopy.recommendationBudgetInsight(
                                remainingFormatted:
                                    PriceFormat.format(_remainingBudgetTL),
                                recommendationFormatted:
                                    PriceFormat.format(_recommendationPackageTL),
                              ),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.teal,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (loadingLive)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: RouteBookingSummarySkeleton(),
            )
          else if (!_hasPrices)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Fiyat bilgisi yükleniyor veya alınamadı.',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
              ),
            )
          else ...[
            _row(
              icon: CupertinoIcons.airplane,
              title: _matchedFlight!['airline'] as String? ?? 'Uçuş',
              subtitle: '${_date(departureDate)} → ${_date(returnDate)}',
              price: PriceFormat.formatRoundTripFlightPrice(_matchedFlight) ?? '',
            ),
            _row(
              icon: CupertinoIcons.house_fill,
              title: _matchedHotel!['name'] as String? ?? 'Otel',
              subtitle: '${_date(departureDate)} → ${_date(returnDate)}',
              price: PriceFormat.format(_hotelTL),
            ),
            if (_transferTL > 0)
              _row(
                icon: CupertinoIcons.car_detailed,
                title: 'Havalimanı transferi',
                subtitle: 'Pakete dahil',
                price: PriceFormat.format(_transferTL),
              ),
            if (extrasTL > 0)
              _row(
                icon: CupertinoIcons.heart_fill,
                title: 'Seyahat sağlık sigortası',
                subtitle: people,
                price: PriceFormat.format(extrasTL),
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.orange,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ConsumerCopy.payableTotal,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Text(
                    loadingLive
                        ? '—'
                        : _hasPrices
                            ? PriceFormat.format(_payableTL)
                            : '—',
                    style: TatilTheme.priceDisplay(color: Colors.white, fontSize: 26),
                  ),
                  if (_hasPrices)
                    Text(
                      _priceFootnote(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    required String subtitle,
    required String price,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.orangeSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                  ),
              ],
            ),
          ),
          if (price.isNotEmpty)
            Text(
              price,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
