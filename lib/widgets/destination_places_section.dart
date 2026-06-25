import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/destination_landmarks.dart';
import '../data/destination_interest_pois.dart';
import '../theme/app_theme.dart';
import '../utils/activity_listing_enrichment.dart';

class DestinationPlacesSection extends StatelessWidget {
  const DestinationPlacesSection({
    super.key,
    required this.cityName,
    required this.iata,
    this.holidayTypes = const [],
    this.onViewTours,
  });

  final String cityName;
  final String iata;
  final List<String> holidayTypes;
  final VoidCallback? onViewTours;

  @override
  Widget build(BuildContext context) {
    final places = _places();
    if (places.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.orangeSoft,
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Text(
            '✨ Yerel sinyaller',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.orange,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$cityName\'da mutlaka görülecekler',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.purpleDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'En yüksek puanlı simge yapılar, restoranlar ve deneyimler · Vizegoo partner verisi',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.35),
        ),
        const SizedBox(height: 14),
        ...places.take(4).map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _PlaceCard(place: p, onViewTours: onViewTours),
            )),
      ],
    );
  }

  List<_PlaceItem> _places() {
    final items = <_PlaceItem>[];
    final landmarks = DestinationLandmarks.forIata(iata);
    for (var i = 0; i < landmarks.length; i++) {
      final l = landmarks[i];
      items.add(_PlaceItem(
        name: l.name,
        categoryLabel: '${l.emoji} Simge yapı',
        categoryStyle: _PlaceCategoryStyle.landmark,
        rating: 4.3 + (i % 3) * 0.2,
        reviews: 1200 + i * 800,
        imageUrl: ActivityListingEnrichment.enrich(
          {},
          index: i,
          cityName: cityName,
          categoryId: 'museums',
        )['imageUrl'] as String?,
      ));
    }

    final pois = DestinationInterestPois.forDestination(
      iata,
      holidayTypes.isNotEmpty
          ? holidayTypes
          : const ['culture', 'shopping', 'beach'],
    );
    for (var i = 0; i < pois.length && items.length < 6; i++) {
      final p = pois[i];
      items.add(_PlaceItem(
        name: p.name,
        categoryLabel: p.interest == 'shopping' ? '🛍️ Alışveriş' : '🍴 Yeme-içme',
        categoryStyle: p.interest == 'shopping'
            ? _PlaceCategoryStyle.shopping
            : _PlaceCategoryStyle.food,
        rating: 4.4 + (i % 2) * 0.15,
        reviews: 600 + i * 400,
        imageUrl: ActivityListingEnrichment.enrich(
          {},
          index: i + 2,
          cityName: cityName,
          categoryId: p.interest == 'shopping' ? 'tours' : 'food',
        )['imageUrl'] as String?,
      ));
    }
    return items;
  }
}

enum _PlaceCategoryStyle { landmark, food, shopping }

class _PlaceItem {
  const _PlaceItem({
    required this.name,
    required this.categoryLabel,
    required this.categoryStyle,
    required this.rating,
    required this.reviews,
    this.imageUrl,
  });

  final String name;
  final String categoryLabel;
  final _PlaceCategoryStyle categoryStyle;
  final double rating;
  final int reviews;
  final String? imageUrl;
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, this.onViewTours});

  final _PlaceItem place;
  final VoidCallback? onViewTours;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: place.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: place.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(color: AppTheme.purpleSoft),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    place.categoryLabel,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      final filled = i < place.rating.floor();
                      return Icon(
                        filled ? Icons.star : Icons.star_border,
                        size: 14,
                        color: AppTheme.orange,
                      );
                    }),
                    const SizedBox(width: 6),
                    Text(
                      '${place.rating.toStringAsFixed(1)} (${_formatReviews(place.reviews)})',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onViewTours,
                  child: Row(
                    children: [
                      Text(
                        'Bilet ve turları gör',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.orange,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        CupertinoIcons.arrow_up_right_square,
                        size: 16,
                        color: AppTheme.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatReviews(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return '$n';
  }
}
