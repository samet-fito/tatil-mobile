import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_background_pattern.dart';

/// Uygulama açılışında kısa marka ekranı.
class AppSplash extends StatelessWidget {
  const AppSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6600), Color(0xFFFF8533)],
              ),
            ),
          ),
          const LoginBackgroundPattern(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Vizegoo',
                  style: GoogleFonts.fredoka(
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Keşfet · Planla · Yola çık',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
