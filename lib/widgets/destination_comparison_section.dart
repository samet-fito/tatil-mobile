import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../city_images.dart';
import '../models/destination_score_model.dart';
import '../screens/destination_comparison_detail_screen.dart';
import '../theme/app_theme.dart';
import '../theme/custom_page_route.dart';

class DestinationComparisonSection extends StatelessWidget {
  const DestinationComparisonSection({
    super.key,
    required this.guides,
    this.currentIata,
  });

  final List<DestinationComparisonGuide> guides;
  final String? currentIata;

  @override
  Widget build(BuildContext context) {
    if (guides.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.orange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'DECISION GUIDES',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppTheme.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Popüler destinasyon karşılaştırmaları',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.purpleDark,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Bir sonraki seyahatin için yan yana destinasyon önerileri.',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
        ),
        const SizedBox(height: 14),
        ...guides.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ComparisonCard(
                guide: g,
                highlight: currentIata != null &&
                    (g.leftIata == currentIata || g.rightIata == currentIata),
              ),
            )),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.guide, this.highlight = false});

  final DestinationComparisonGuide guide;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => pushAppRoute(
        context,
        DestinationComparisonDetailScreen(guide: guide),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight ? AppTheme.orange : AppTheme.orange.withValues(alpha: 0.45),
            width: highlight ? 2 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 140,
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(child: _halfImage(guide.leftIata)),
                      Expanded(child: _halfImage(guide.rightIata)),
                    ],
                  ),
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'VS',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppTheme.orange,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (guide.isPopular)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.flame_fill, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'POPÜLER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guide.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.purpleDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    guide.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Karşılaştırmayı gör',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.orange,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        CupertinoIcons.arrow_right,
                        size: 14,
                        color: AppTheme.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _halfImage(String iata) {
    final url = CityImages.networkUrl(iata);
    return CachedNetworkImage(
      imageUrl: url,
      height: 140,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppTheme.bgTertiary),
      errorWidget: (_, __, ___) => Container(color: AppTheme.purpleSoft),
    );
  }
}
