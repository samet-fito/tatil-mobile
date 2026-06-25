import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/destination_score_model.dart';
import '../theme/app_theme.dart';

class DestinationScoreFrameworkSection extends StatelessWidget {
  const DestinationScoreFrameworkSection({super.key, required this.framework});

  final DestinationScoreFramework framework;

  @override
  Widget build(BuildContext context) {
    if (framework.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score framework',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.purpleDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Konaklama, yemek, deneyim, yürünebilirlik, uygun fiyat ve ulaşım puanları.',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
        ),
        const SizedBox(height: 14),
        ...framework.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ScoreCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.item});

  final DestinationScoreItem item;

  Color get _barColor {
    if (item.score >= 8.5) return AppTheme.teal;
    if (item.score >= 7.5) return AppTheme.orange;
    return AppTheme.purple;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                item.score.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.purpleDark,
                ),
              ),
              Text(
                '/10',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _barColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  item.badgeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 6,
              backgroundColor: AppTheme.bgTertiary,
              color: _barColor,
            ),
          ),
        ],
      ),
    );
  }
}
