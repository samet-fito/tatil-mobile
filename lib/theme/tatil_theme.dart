import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// AppTheme ile aynı palet — ekran bileşenleri için kısayol.
class TatilTheme {
  TatilTheme._();

  static const orange = AppTheme.orange;
  static const orangeLight = AppTheme.orangeLight;
  static const orangeSoft = AppTheme.orangeSoft;
  static const bgSoft = AppTheme.bgPrimary;
  static const bgTertiary = AppTheme.bgTertiary;
  static const cardWhite = AppTheme.bgSecondary;
  static const textDark = AppTheme.textPrimary;
  static const textMuted = AppTheme.textMuted;
  static const border = AppTheme.border;
  static const teal = AppTheme.teal;

  /// Hero / görsel üzeri — beyaz Fredoka (carousel, login splash).
  static TextStyle get title => GoogleFonts.fredoka(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.1,
      );

  static TextStyle get subtitle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.92),
      );

  /// Açık zemin — destinasyon adı (AppBar, kart hero, özet).
  static TextStyle destination({double fontSize = 22, Color? color}) =>
      GoogleFonts.fredoka(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color ?? textDark,
        height: 1.1,
        letterSpacing: -0.3,
      );

  /// Ekran başlığı — AppBar, modal.
  static TextStyle screenHeadline({double fontSize = 20, Color? color}) =>
      GoogleFonts.fredoka(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color ?? textDark,
        height: 1.15,
        letterSpacing: -0.3,
      );

  /// Bölüm başlığı — detay / checkout.
  static TextStyle get sectionHeadline => GoogleFonts.fredoka(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textDark,
        height: 1.2,
        letterSpacing: -0.2,
      );

  /// Büyük fiyat vurgusu.
  static TextStyle priceDisplay({Color color = textDark, double fontSize = 24}) =>
      GoogleFonts.fredoka(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.05,
      );

  static TextStyle get sectionLabel => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
      );

  static TextStyle get bodyMuted => GoogleFonts.inter(
        fontSize: 13,
        color: textMuted,
      );

  static TextStyle get hint => GoogleFonts.inter(
        fontSize: 12,
        color: textMuted,
      );

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      );
}
