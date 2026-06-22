import 'package:flutter/material.dart';

/// Discovery ekrani — koyu kart + coral accent (#161C2A / #FF5A5F).
class VizegooDiscoveryTheme {
  VizegooDiscoveryTheme._();

  static const Color cardBg = Color(0xFF161C2A);
  static const Color cardBgElevated = Color(0xFF1E2638);
  static const Color accent = Color(0xFFFF5A5F);
  static const Color accentSoft = Color(0x1AFF5A5F);
  static const Color onDarkPrimary = Color(0xFFF3F4F6);
  static const Color onDarkMuted = Color(0xFF9CA3AF);
  static const Color screenBg = Color(0xFFF7F8FA);

  static BoxDecoration card({Color? border}) => BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border ?? accent.withValues(alpha: 0.35)),
      );

  static BoxDecoration eventCard() => BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: accent, width: 3),
          top: BorderSide(color: accent.withValues(alpha: 0.2)),
          right: BorderSide(color: accent.withValues(alpha: 0.2)),
          bottom: BorderSide(color: accent.withValues(alpha: 0.2)),
        ),
      );
}
