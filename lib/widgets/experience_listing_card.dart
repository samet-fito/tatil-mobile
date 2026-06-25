import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/activity_image.dart';
import '../utils/price_format.dart';

/// GetYourGuide tarzı yatay tur & deneyim listeleme kartı.
class ExperienceListingCard extends StatelessWidget {
  const ExperienceListingCard({
    super.key,
    required this.title,
    required this.duration,
    required this.priceTL,
    this.activityId = 'activity',
    this.category = 'tours',
    this.subtitle,
    this.imageUrl,
    this.rating = 0,
    this.reviewCount = 0,
    this.socialProofLabel,
    this.socialProofStyle = SocialProofStyle.navy,
    this.originalPriceTL,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onTap,
  });

  final String title;
  final String duration;
  final int priceTL;
  final String activityId;
  final String category;
  final String? subtitle;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final String? socialProofLabel;
  final SocialProofStyle socialProofStyle;
  final int? originalPriceTL;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imageBlock(),
              const SizedBox(width: 12),
              Expanded(child: _contentBlock()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageBlock() {
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ActivityNetworkImage(
              imageUrl: imageUrl,
              activityId: activityId,
              category: category,
              width: 108,
              height: 108,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onFavoriteToggle,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isFavorite
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  size: 16,
                  color: isFavorite ? AppTheme.fuchsia : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (socialProofLabel != null && socialProofLabel!.isNotEmpty) ...[
          _socialBadge(),
          const SizedBox(height: 6),
        ],
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: AppTheme.textPrimary,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          duration,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (rating > 0) ...[
              Text(
                rating.toStringAsFixed(1).replaceAll('.', ','),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.star, size: 14, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 2),
              Text(
                '($reviewCount)',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Başlangıç fiyatı',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
                if (originalPriceTL != null && originalPriceTL! > priceTL) ...[
                  Text(
                    PriceFormat.format(originalPriceTL!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
                Text(
                  PriceFormat.format(priceTL),
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.fuchsia,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _socialBadge() {
    final bg = switch (socialProofStyle) {
      SocialProofStyle.purple => AppTheme.purple,
      SocialProofStyle.navy => AppTheme.navyBadge,
      SocialProofStyle.orange => AppTheme.orange,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        socialProofLabel!,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

enum SocialProofStyle { purple, navy, orange }
