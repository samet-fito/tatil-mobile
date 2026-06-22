import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/booking_scope.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/price_format.dart';

/// Uçak / otel fiyat chip'ine dokununca — tek ürün veya tam paket seçimi.
Future<void> showPartialBookingOptionsSheet(
  BuildContext context, {
  required BookingScope scope,
  required String cityName,
  required int amountTL,
  required String detailLine,
  required VoidCallback onBuyOnly,
  VoidCallback? onViewFullPackage,
}) {
  final isFlight = scope == BookingScope.flightOnly;
  final accent = isFlight ? AppTheme.teal : AppTheme.orange;
  final icon = isFlight ? CupertinoIcons.airplane : CupertinoIcons.house_fill;
  final productLabel = isFlight ? 'Uçak bileti' : 'Otel konaklaması';
  final ctaLabel = isFlight
      ? 'Sadece uçak biletini al'
      : 'Sadece otel rezervasyonu yap';

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(ctx).padding.bottom + 16,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productLabel,
                            style: TatilTheme.sectionHeadline.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cityName,
                            style: TatilTheme.bodyMuted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            PriceFormat.format(amountTL),
                            style: TatilTheme.priceDisplay(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            detailLine,
                            style: TatilTheme.hint,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  isFlight
                      ? 'Uçuşu ayrı satın al; otel ve transfer olmadan devam et.'
                      : 'Konaklamayı ayrı rezerve et; uçuş olmadan devam et.',
                  style: TatilTheme.hint.copyWith(height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      onBuyOnly();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Center(
                        child: Text(
                          ctaLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (onViewFullPackage != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onViewFullPackage();
                    },
                    child: Text(
                      'Tam paketi incele (uçak + otel)',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
