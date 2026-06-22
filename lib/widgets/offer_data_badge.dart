import '../utils/consumer_copy.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Canlı teklif / kısmen canlı / plan önerisi rozeti.
class OfferDataBadge extends StatelessWidget {
  const OfferDataBadge({
    super.key,
    required this.kind,
    this.compact = false,
    this.onDark = false,
  });

  final OfferDataKind kind;
  final bool compact;
  final bool onDark;

  factory OfferDataBadge.fromFlags({
    required bool flightsLive,
    required bool hotelsLive,
    required bool flightVerified,
    bool compact = false,
    bool onDark = false,
  }) {
    return OfferDataBadge(
      kind: ConsumerCopy.offerDataKind(
        flightsLive: flightsLive,
        hotelsLive: hotelsLive,
        flightVerified: flightVerified,
      ),
      compact: compact,
      onDark: onDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ConsumerCopy.offerDataColors(kind, onDark: onDark);
    final label = ConsumerCopy.offerDataLabel(kind);
    final icon = ConsumerCopy.offerDataIcon(kind);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 11, color: colors.foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
              color: colors.foreground,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek satır kaynak etiketi — uçuş/otel satırları.
class OfferSourceChip extends StatelessWidget {
  const OfferSourceChip({super.key, required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isLive
            ? AppTheme.teal.withValues(alpha: 0.1)
            : AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isLive ? 'Canlı API' : 'Plan tahmini',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: isLive ? AppTheme.teal : AppTheme.textMuted,
        ),
      ),
    );
  }
}
