import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Proje geneli turuncu tema — login ve ana sayfa ile uyumlu.
class AppTheme {
  AppTheme._();

  // Turuncu palet
  static const Color orange = Color(0xFFFF6600);
  static const Color orangeLight = Color(0xFFFF7710);
  static const Color orangeSoft = Color(0xFFFFF0E6);

  // Yüzeyler
  static const Color bgPrimary = Color(0xFFFFF8F4);
  static const Color bgSecondary = Color(0xFFFFFFFF);
  static const Color bgTertiary = Color(0xFFF9F9F9);

  // Yükleme ekranı (koyu)
  static const Color loadingBg = Color(0xFF0B0F19);
  static const Color loadingGlobe = Color(0xFF151B2B);
  static const Color loadingContinent = Color(0xFF243044);
  static const Color loadingText = Color(0xFFF3F4F6);
  static const Color loadingMuted = Color(0xFF9CA3AF);

  // Vurgu (accent = turuncu)
  static const Color accent = orange;
  static const Color accentLight = orangeSoft;

  // Sağlık modu
  static const Color teal = Color(0xFF00A896);
  static const Color tealLight = Color(0x1A00A896);
  static const Color health = teal;
  static const Color healthLight = tealLight;

  // Metin
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF6B7280);

  // Uyumluluk
  static const Color primary = orange;
  static const Color background = bgPrimary;
  static const Color cardBg = bgSecondary;
  static const Color border = Color(0xFFE8E8E8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: orange,
        secondary: teal,
        surface: bgSecondary,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: bgPrimary,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgPrimary,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: bgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return orange;
          return Colors.white;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: orange, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      dividerColor: border,
      sliderTheme: SliderThemeData(
        activeTrackColor: orange,
        inactiveTrackColor: orangeSoft,
        thumbColor: orange,
        overlayColor: orangeSoft,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: orange),
    );
  }
}
