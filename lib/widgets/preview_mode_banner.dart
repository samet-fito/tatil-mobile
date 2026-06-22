import 'package:flutter/material.dart';
import '../config/app_experience.dart';
import '../theme/tatil_theme.dart';

/// Önizleme modu bilgi şeridi — ödeme henüz aktif değilken gösterilir.
class PreviewModeBanner extends StatelessWidget {
  const PreviewModeBanner({
    super.key,
    this.compact = false,
    this.message,
  });

  final bool compact;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (AppExperience.paymentsEnabled) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TatilTheme.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: compact ? 16 : 18,
            color: TatilTheme.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ?? AppExperience.previewBannerText,
              style: TatilTheme.hint.copyWith(
                fontSize: compact ? 11 : 12,
                height: 1.35,
                color: const Color(0xFF9A3412),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
