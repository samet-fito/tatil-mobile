import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/destination_score_model.dart';
import '../theme/app_theme.dart';
import '../utils/price_format.dart';

class DestinationTripCostCard extends StatelessWidget {
  const DestinationTripCostCard({super.key, required this.estimate});

  final DestinationTripCostEstimate estimate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Typical on-the-ground trip cost',
            style: GoogleFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.purpleDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Yerel maliyetler; uçuşlar kalkış şehrinize göre değişir.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.35),
          ),
          const SizedBox(height: 14),
          _costTile(
            icon: CupertinoIcons.cart,
            label: 'GÜNLÜK / KİŞİ',
            value:
                '${PriceFormat.format(estimate.dailyPerPersonMin)} – ${PriceFormat.format(estimate.dailyPerPersonMax)}',
            bg: AppTheme.bgTertiary,
          ),
          const SizedBox(height: 8),
          _costTile(
            icon: CupertinoIcons.bed_double,
            label: 'MERKEZİ KONAKLAMA / GECE',
            value:
                '${PriceFormat.format(estimate.centralStayMin)} – ${PriceFormat.format(estimate.centralStayMax)}',
            bg: AppTheme.bgTertiary,
          ),
          const SizedBox(height: 8),
          _costTile(
            icon: CupertinoIcons.map,
            label:
                '${estimate.nights} GECE TOPLAM (${estimate.adults} YETİŞKİN)',
            value:
                '${PriceFormat.format(estimate.tripTotalMin)} – ${PriceFormat.format(estimate.tripTotalMax)}',
            bg: AppTheme.orangeSoft,
            note: 'Uçuş dahil değil',
            highlight: true,
          ),
          const SizedBox(height: 12),
          Text(
            'Tahmini yerel harcama. Tam paket için Vizegoo aramasıyla uçuş dahil karşılaştırın.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted.withValues(alpha: 0.95),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _costTile({
    required IconData icon,
    required String label,
    required String value,
    required Color bg,
    String? note,
    bool highlight = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: AppTheme.orange.withValues(alpha: 0.25))
            : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.orange, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: highlight ? 20 : 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.purpleDark,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(
              note,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
