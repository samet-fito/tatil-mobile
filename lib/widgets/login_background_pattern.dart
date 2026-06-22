import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Giriş ekranı arka planı — turuncu zemin, dağınık büyük seyahat ikonları.
///
/// Özel ikon kullanmak istersen PNG/SVG dosyalarını şuraya koy:
///   assets/icons/login/plane.png
/// Sonra [LoginBackgroundPattern.customAssetPaths] ile geçir.
class LoginBackgroundPattern extends StatelessWidget {
  final List<String>? customAssetPaths;

  const LoginBackgroundPattern({super.key, this.customAssetPaths});

  static const Color bgTop = Color(0xFFFF7710);
  static const Color bgBottom = Color(0xFFFF6600);
  static const Color frameGray = Color(0xFF9E9E9E);
  static const Color iconColor = Color(0xFFFFFFFF);

  static const List<IconData> defaultIcons = [
    Icons.flight,
    Icons.confirmation_number_outlined,
    Icons.card_travel_outlined,
    Icons.beach_access_outlined,
    Icons.local_bar_outlined,
    Icons.sports_volleyball_outlined,
    Icons.luggage_outlined,
    Icons.wb_sunny_outlined,
    Icons.camera_alt_outlined,
    Icons.map_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgTop, bgBottom],
            ),
          ),
        ),
        const Positioned.fill(child: _ScatteredIconsLayer()),
        CustomPaint(painter: _FrameBorderPainter()),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.05),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.08),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScatterItem {
  const _ScatterItem({
    required this.icon,
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
    required this.opacity,
  });

  final IconData icon;
  final double x;
  final double y;
  final double size;
  final double rotation;
  final double opacity;
}

class _ScatteredIconsLayer extends StatelessWidget {
  const _ScatteredIconsLayer();

  static const _seed = 20250612;
  static final List<_ScatterItem> _items = _buildItems();

  static List<_ScatterItem> _buildItems() {
    final rnd = math.Random(_seed);
    final icons = LoginBackgroundPattern.defaultIcons;

    return List.generate(24, (i) {
      return _ScatterItem(
        icon: icons[i % icons.length],
        x: rnd.nextDouble() * 1.42 - 0.21,
        y: rnd.nextDouble() * 1.28 - 0.14,
        size: 52 + rnd.nextDouble() * 56,
        rotation: rnd.nextDouble() * math.pi * 0.5 - math.pi * 0.25,
        opacity: 0.07 + rnd.nextDouble() * 0.11,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final item in _items)
              Positioned(
                left: item.x * w - item.size * 0.5,
                top: item.y * h - item.size * 0.5,
                child: Transform.rotate(
                  angle: item.rotation,
                  child: Icon(
                    item.icon,
                    size: item.size,
                    color: LoginBackgroundPattern.iconColor
                        .withValues(alpha: item.opacity),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FrameBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const inset = 14.0;
    const gap = 6.0;

    final outer = Paint()
      ..color = LoginBackgroundPattern.frameGray.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final inner = Paint()
      ..color = LoginBackgroundPattern.frameGray.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawRect(
      Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
      outer,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        inset + gap,
        inset + gap,
        size.width - (inset + gap) * 2,
        size.height - (inset + gap) * 2,
      ),
      inner,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
