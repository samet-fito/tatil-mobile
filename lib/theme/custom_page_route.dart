import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Varsayılan sayfa geçişi: sağdan sola kayma + hafif fade (350ms).
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  CustomPageRoute({required Widget page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
              reverseCurve: Curves.easeInOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.85, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Rota sonuçları ekranı: alttan yukarı + uçak ikonu soldan sağa (600ms).
class RouteResultsPageRoute<T> extends PageRouteBuilder<T> {
  RouteResultsPageRoute({required Widget page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
              reverseCurve: Curves.easeInOutCubic,
            );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: curved,
                      builder: (context, _) {
                        final t = curved.value;
                        final planeOpacity = (1 - t).clamp(0.0, 1.0);
                        if (planeOpacity <= 0) return const SizedBox.shrink();
                        return Stack(
                          children: [
                            Positioned(
                              left: MediaQuery.sizeOf(context).width * (-0.08 + 1.08 * t),
                              top: MediaQuery.sizeOf(context).height * (0.22 - 0.06 * t),
                              child: Opacity(
                                opacity: planeOpacity,
                                child: Transform.rotate(
                                  angle: 0.05,
                                  child: Icon(
                                    Icons.flight,
                                    color: AppTheme.orange.withValues(alpha: 0.95),
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
}

/// Tüm [Navigator.push] çağrıları için yardımcı.
Future<T?> pushAppRoute<T>(BuildContext context, Widget page) {
  return Navigator.push<T>(context, CustomPageRoute<T>(page: page));
}

/// Alttan yukarı + uçak ikonu (600ms) — rota sonuçları ve rota detayı.
Future<T?> pushRouteResults<T>(BuildContext context, Widget page) {
  return Navigator.push<T>(context, RouteResultsPageRoute<T>(page: page));
}

/// [pushRouteResults] ile aynı geçiş.
Future<T?> pushSlideUpRoute<T>(BuildContext context, Widget page) =>
    pushRouteResults<T>(context, page);
