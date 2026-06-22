import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/route_result_model.dart';
import '../widgets/destination_hero_image.dart';
import '../utils/route_display_pricing.dart';
import '../city_images.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../models/budget_package_offer.dart';
import '../utils/consumer_copy.dart';
import '../utils/route_recommendation_line.dart';
import '../widgets/offer_data_badge.dart';

/// Rota sonuç kartı — before.click: destinasyon fotoğrafı, puan, fiyat odaklı.
class RouteResultCard extends StatelessWidget {
  final RouteResultModel route;
  final int rank;
  final VoidCallback onTap;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final String? upgradeWarning;
  final double? serviceScore;
  final BudgetPackageOffer? budgetOffer;
  final List<String> holidayTypes;
  final bool isInCompare;
  final VoidCallback? onCompareToggle;
  final VoidCallback? onPriceWatch;

  const RouteResultCard({
    super.key,
    required this.route,
    required this.rank,
    required this.onTap,
    this.departureDate,
    this.returnDate,
    this.upgradeWarning,
    this.serviceScore,
    this.budgetOffer,
    this.holidayTypes = const [],
    this.isInCompare = false,
    this.onCompareToggle,
    this.onPriceWatch,
  });

  String _monthName(int month) {
    const months = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
        'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return months[month];
  }

  String _fmt(int price) {
    return '${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )} TL';
  }

  double get _displayScore =>
      serviceScore ?? route.hotel?.reviewScore ?? route.score / 10.0;

  int get _packageTotal => RouteDisplayPricing.packageTL(route);

  int get _displayTotal => budgetOffer?.displayTotalTL ?? _packageTotal;

  bool get _flightsLive =>
      budgetOffer?.flightsFromLive == true &&
      (budgetOffer?.hasVerifiedRoundTripFlight ?? false);

  bool get _hotelsLive => budgetOffer?.hotelsFromLive ?? false;

  OfferDataKind get _offerKind => ConsumerCopy.offerDataKind(
        flightsLive: budgetOffer?.flightsFromLive ?? false,
        hotelsLive: _hotelsLive,
        flightVerified: budgetOffer?.hasVerifiedRoundTripFlight ?? false,
      );

  String? get _liveHotelPhotoUrl {
    final url = budgetOffer?.selectedHotel?['photoUrl']?.toString().trim();
    if (url != null && url.isNotEmpty && url.startsWith('http')) return url;
    return null;
  }

  double get _liveHotelScore {
    final live = budgetOffer?.selectedHotel?['reviewScore'];
    if (live is num && live > 0) return live.toDouble();
    return _displayScore;
  }

  Color get _fitColor {
    if (budgetOffer != null && !budgetOffer!.hasUserBudget) {
      return AppTheme.textPrimary;
    }
    switch (budgetOffer?.fitKind) {
      case BudgetFitKind.liveWithinBudget:
        return AppTheme.teal;
      case BudgetFitKind.planWithinBudget:
      case BudgetFitKind.planOnly:
      case BudgetFitKind.unscoped:
        return AppTheme.textPrimary;
      case BudgetFitKind.overBudget:
        return Colors.red.shade700;
      case null:
        return route.isAffordable
            ? AppTheme.textPrimary
            : Colors.red.shade700;
    }
  }

  Color get _fitBadgeColor {
    switch (budgetOffer?.fitKind) {
      case BudgetFitKind.liveWithinBudget:
        return AppTheme.teal;
      case BudgetFitKind.overBudget:
        return AppTheme.orange;
      case BudgetFitKind.planWithinBudget:
      case BudgetFitKind.planOnly:
        return AppTheme.orange;
      case BudgetFitKind.unscoped:
      case null:
        return AppTheme.textMuted;
    }
  }

  Color get _fitBadgeBackground {
    switch (budgetOffer?.fitKind) {
      case BudgetFitKind.liveWithinBudget:
        return AppTheme.teal.withValues(alpha: 0.12);
      case BudgetFitKind.overBudget:
        return AppTheme.orangeSoft;
      case BudgetFitKind.planWithinBudget:
      case BudgetFitKind.planOnly:
        return AppTheme.orangeSoft;
      case BudgetFitKind.unscoped:
      case null:
        return AppTheme.bgTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: route.isBestChoice
                ? AppTheme.accent.withValues(alpha: 0.45)
                : AppTheme.border,
            width: route.isBestChoice ? 1.5 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeroImage(),
            _buildBody(context),
            if (route.alternativeSuggestion != null) _buildSuggestion(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    final landmark = CityImages.getLandmark(route.destinationIata);
    final liveHotelName = budgetOffer?.selectedHotel?['name']?.toString();
    final subtitle = _liveHotelPhotoUrl != null &&
            liveHotelName != null &&
            liveHotelName.isNotEmpty
        ? liveHotelName
        : landmark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 168,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DestinationHeroImage(
              iataCode: route.destinationIata,
              imageUrl: _liveHotelPhotoUrl,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0.25, 0.62, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OfferDataBadge(
                    kind: _offerKind,
                    compact: true,
                    onDark: true,
                  ),
                  if (budgetOffer?.isSmartOptimized == true) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.sparkles,
                            size: 12,
                            color: AppTheme.teal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            budgetOffer!.smartPackageSavingsTL != null &&
                                    budgetOffer!.smartPackageSavingsTL! > 0
                                ? 'Akıllı paket · ${budgetOffer!.smartPackageSavingsTL} TL'
                                : 'Akıllı paket',
                            style: const TextStyle(
                              color: AppTheme.teal,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (route.isBestChoice) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'En iyi seçim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _scorePill(_liveHotelScore),
            ),
            if (onPriceWatch != null || onCompareToggle != null)
              Positioned(
                top: 12,
                right: 56,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onPriceWatch != null)
                      _heroAction(
                        icon: CupertinoIcons.bell,
                        onTap: onPriceWatch!,
                      ),
                    if (onCompareToggle != null) ...[
                      const SizedBox(width: 6),
                      _heroAction(
                        icon: isInCompare
                            ? CupertinoIcons.checkmark_square_fill
                            : CupertinoIcons.square,
                        onTap: onCompareToggle!,
                        active: isInCompare,
                      ),
                    ],
                  ],
                ),
              ),
            Positioned(
              left: 16,
              bottom: 14,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.cityName,
                    style: TatilTheme.destination(fontSize: 26, color: Colors.white),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                      ),
                    ),
                  if (departureDate != null && returnDate != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${departureDate!.day} ${_monthName(departureDate!.month)} – '
                      '${returnDate!.day} ${_monthName(returnDate!.month)} · ${route.nights} gece',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scorePill(double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.star_fill, size: 12, color: AppTheme.accent),
          const SizedBox(width: 4),
          Text(
            score.toStringAsFixed(1),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTripSummary(),
          const SizedBox(height: 10),
          _buildWhyThisRoute(),
          const SizedBox(height: 14),
          _buildRecommendationPrice(),
          if (upgradeWarning != null) ...[
            const SizedBox(height: 10),
            Text(
              upgradeWarning!,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.orange.withValues(alpha: 0.95),
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildTripSummary() {
    final liveFlight = budgetOffer?.selectedFlight;
    final liveHotel = budgetOffer?.selectedHotel;
    final flight = route.flight;
    final hotel = route.hotel;

    if (liveFlight == null &&
        flight == null &&
        liveHotel == null &&
        (hotel == null || hotel.name.isEmpty || hotel.name == '--')) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (liveFlight != null || flight != null)
          _summaryLine(
            label: liveFlight?['airline']?.toString() ??
                '${flight!.airline} · ${flight.duration}',
            isLive: liveFlight != null && _flightsLive,
          ),
        if (liveHotel != null ||
            (hotel != null && hotel.name.isNotEmpty && hotel.name != '--')) ...[
          if (liveFlight != null || flight != null) const SizedBox(height: 6),
          _summaryLine(
            label: liveHotel?['name']?.toString() ?? hotel!.name,
            isLive: liveHotel != null && _hotelsLive,
          ),
        ],
      ],
    );
  }

  Widget _summaryLine({required String label, required bool isLive}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isLive ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.sparkles,
          size: 13,
          color: isLive ? AppTheme.teal : AppTheme.textMuted,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhyThisRoute() {
    final line = RouteRecommendationLine.build(
      route: route,
      offer: budgetOffer,
      holidayTypes: holidayTypes,
      rank: rank,
      serviceScore: _displayScore,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          CupertinoIcons.lightbulb_fill,
          size: 14,
          color: AppTheme.teal,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            line,
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationPrice() {
    final priceNote = ConsumerCopy.offerDataLabel(_offerKind);
    final priceHint = ConsumerCopy.offerDataHint(
      flightsLive: budgetOffer?.flightsFromLive ?? false,
      hotelsLive: _hotelsLive,
      flightVerified: budgetOffer?.hasVerifiedRoundTripFlight ?? false,
    );
    final showFitBadge = budgetOffer != null &&
        budgetOffer!.hasUserBudget &&
        budgetOffer!.fitLabel.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showFitBadge) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _fitBadgeBackground,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              budgetOffer!.fitLabel,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _fitBadgeColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          _fmt(_displayTotal),
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _fitColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$priceNote · uçak + otel · ${route.nights} gece',
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          priceHint,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppTheme.textMuted,
            height: 1.35,
          ),
        ),
        if (budgetOffer != null &&
            budgetOffer!.hasUserBudget &&
            budgetOffer!.budgetGapTL > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Bütçeden +${_fmt(budgetOffer!.budgetGapTL)}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Öneri paket · detayda uçuş ve oteli ayrı da alabilirsiniz',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textMuted,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppTheme.accent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'İncele',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestion() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F0E),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              size: 15, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              route.alternativeSuggestion!,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroAction({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.teal.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
