import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import 'offer_data_badge.dart';

/// Seçili uçuş/otel satırı — yalnızca özet + Değiştir (before.click).
class LiveSelectionRow extends StatelessWidget {
  const LiveSelectionRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    this.priceSecondaryLabel,
    this.loading = false,
    this.onChange,
    this.sourceIsLive = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String priceLabel;
  final String? priceSecondaryLabel;
  final bool loading;
  final VoidCallback? onChange;
  final bool sourceIsLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: AppTheme.orange),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onChange != null)
                      TextButton(
                        onPressed: onChange,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.only(left: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Değiştir',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.orange,
                          ),
                        ),
                      ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                if (!loading) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: OfferSourceChip(isLive: sourceIsLive),
                  ),
                ],
                if (priceLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            priceLabel,
                            style: TatilTheme.priceDisplay(
                              fontSize: 15,
                              color: iconColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (priceSecondaryLabel != null &&
                            priceSecondaryLabel!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            priceSecondaryLabel!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
