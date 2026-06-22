import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/price_format.dart';

/// Akıllı paket v2 önerisi — tasarruf ve seçim gerekçesi.
class SmartPackageInsightCard extends StatelessWidget {
  const SmartPackageInsightCard({
    super.key,
    required this.savingsTL,
    required this.insight,
    required this.totalTL,
    this.onApply,
    this.applied = false,
  });

  final int savingsTL;
  final String insight;
  final int totalTL;
  final VoidCallback? onApply;
  final bool applied;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.teal.withValues(alpha: 0.12),
            AppTheme.accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  color: AppTheme.teal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Akıllı Paket v2',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (applied)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Uygulandı',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.teal,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            PriceFormat.format(totalTL),
            style: TatilTheme.priceDisplay(fontSize: 24),
          ),
          if (savingsTL > 0) ...[
            const SizedBox(height: 4),
            Text(
              '≈ ${PriceFormat.format(savingsTL)} tasarruf',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.teal,
              ),
            ),
          ],
          if (insight.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              insight,
              style: TatilTheme.hint.copyWith(fontSize: 12, height: 1.4),
            ),
          ],
          if (onApply != null && !applied) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Önerilen paketi uygula',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
