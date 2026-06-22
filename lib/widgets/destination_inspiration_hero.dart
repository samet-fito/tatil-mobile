import 'dart:async';

import 'package:flutter/material.dart';
import '../city_images.dart';
import '../theme/tatil_theme.dart';

/// Ana ekran — yerel destinasyon görselleriyle dönen hero (before.click: destination-first).
class DestinationInspirationHero extends StatefulWidget {
  const DestinationInspirationHero({
    super.key,
    this.onDestinationTap,
  });

  final ValueChanged<DestinationInspirationSlide>? onDestinationTap;

  @override
  State<DestinationInspirationHero> createState() =>
      _DestinationInspirationHeroState();
}

class _DestinationInspirationHeroState extends State<DestinationInspirationHero> {
  final _pageController = PageController();
  Timer? _timer;
  int _index = 0;

  List<DestinationInspirationSlide> get _slides =>
      CityImages.localInspirationSlides;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _next());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (!mounted || _slides.length <= 1) return;
    final next = (_index + 1) % _slides.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onSlideTap(DestinationInspirationSlide slide) {
    widget.onDestinationTap?.call(slide);
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final slide = _slides[i];
                return GestureDetector(
                  onTap: () => _onSlideTap(slide),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        slide.asset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.55),
                              Colors.black.withValues(alpha: 0.82),
                            ],
                            stops: const [0.2, 0.65, 1.0],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slide.cityName,
                              style: TatilTheme.title
                                  .copyWith(fontSize: 28, letterSpacing: -0.5),
                            ),
                            if (slide.landmark.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                slide.landmark,
                                style: TatilTheme.subtitle.copyWith(fontSize: 12),
                              ),
                            ],
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    slide.tagline,
                                    style: TatilTheme.subtitle,
                                  ),
                                ),
                                if (widget.onDestinationTap != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: TatilTheme.orange,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      'Seç',
                                      style: TatilTheme.subtitle.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_slides.length > 1)
              Positioned(
                bottom: 12,
                right: 14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.only(left: 5),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
