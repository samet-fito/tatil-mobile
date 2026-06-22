import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/spending_estimate_model.dart';
import '../theme/tatil_theme.dart';

/// Kompakt tahmini harcama — yeme-içme + ulaşım ortalamaları.
class SpendingEstimatePanel extends StatelessWidget {
  const SpendingEstimatePanel({
    super.key,
    required this.estimate,
    this.compact = false,
  });

  final SpendingEstimate estimate;
  final bool compact;

  String _fmt(int v) =>
      '${v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompactSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _summaryBanner(),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: TatilTheme.orangeSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 15, color: TatilTheme.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  estimate.disclaimer.isNotEmpty
                      ? estimate.disclaimer
                      : 'Bu tahminler ödeme toplamına dahil değildir; tatilde harcama bütçeniz içindir.',
                  style: _hintStyle().copyWith(color: TatilTheme.orange, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TatilTheme.orange.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'Tahmini harcama',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TatilTheme.textDark,
                ),
              ),
              if (estimate.isLiveSource) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: TatilTheme.orangeSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '📡 ${estimate.sourceBadge}',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: TatilTheme.orange,
                    ),
                  ),
                ),
              ] else if (estimate.isAiSource) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: TatilTheme.orangeSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '✨ AI',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: TatilTheme.orange,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                _fmt(estimate.grandTotalTL),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: TatilTheme.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            estimate.isLiveSource || estimate.isAiSource
                ? estimate.dailyBreakdownLine
                : 'Yeme-içme ~${_fmt(estimate.dailyFoodPerPersonTL)}/kişi/gün · '
                    'Ulaşım ~${_fmt(estimate.dailyTransportPerPersonTL)}/kişi/gün',
            style: _hintStyle(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (estimate.isAiSource && estimate.foodScopeLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              estimate.foodScopeLabel,
              style: _hintStyle().copyWith(fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TatilTheme.orange.withValues(alpha: 0.12),
            TatilTheme.orangeSoft,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TatilTheme.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tatilde harcama bütçesi (ödeme dışı)',
                  style: GoogleFonts.inter(fontSize: 12, color: TatilTheme.textMuted),
                ),
                if (estimate.isLiveSource || estimate.isAiSource) ...[
                  const SizedBox(height: 2),
                  Text(
                    estimate.dailyBreakdownLine,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: TatilTheme.orange,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                Text(
                  _fmt(estimate.grandTotalTL),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: TatilTheme.orange,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Kişi / gün', style: _hintStyle()),
              Text(
                _fmt(estimate.perPersonPerDayTL),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: TatilTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _hintStyle() => GoogleFonts.inter(
        fontSize: 11,
        color: TatilTheme.textMuted,
        height: 1.35,
      );
}
