import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';

/// Checkout fiyat güveni — gizli ücret yok mesajı.
class CheckoutTrustFooter extends StatelessWidget {
  const CheckoutTrustFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(
            CupertinoIcons.checkmark_shield,
            'Gösterilen toplamın dışında gizli ücret yok.',
          ),
          const SizedBox(height: 8),
          _row(
            CupertinoIcons.clock,
            'Fiyatlar canlı kaynaktan gelir; ödeme adımında son kez doğrulanır.',
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppTheme.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TatilTheme.hint.copyWith(
              fontSize: 12,
              height: 1.35,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
