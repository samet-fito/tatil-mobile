import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';

/// Tatil türü eşleşmesi — kısa bilgi notu (detaylar ödeme sonrası rehberde).
class HolidayTypeMatchHint extends StatelessWidget {
  const HolidayTypeMatchHint({super.key});

  static const String message = 'Sizin seçtiğiniz tatil türüne en yakın rota';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              CupertinoIcons.checkmark_seal,
              size: 16,
              color: AppTheme.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TatilTheme.hint.copyWith(
                fontSize: 12,
                height: 1.4,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
