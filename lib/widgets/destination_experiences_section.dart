import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/commission_activities.dart';
import '../services/activity_favorites_store.dart';
import '../theme/app_theme.dart';
import '../theme/custom_page_route.dart';
import '../utils/activity_listing_enrichment.dart';
import '../utils/activity_image.dart';
import '../utils/price_format.dart';
import '../screens/activity_experience_detail_screen.dart';

/// Viator tarzı büyük deneyim kartları — uygulama içi ödeme akışına bağlı.
class DestinationExperiencesSection extends StatelessWidget {
  const DestinationExperiencesSection({
    super.key,
    required this.cityName,
    required this.destinationIata,
    required this.activitiesData,
    this.departureDate,
    this.returnDate,
  });

  final String cityName;
  final String destinationIata;
  final Map<String, dynamic> activitiesData;
  final DateTime? departureDate;
  final DateTime? returnDate;

  @override
  Widget build(BuildContext context) {
    final flat = CommissionActivities.flatActivities(activitiesData);
    if (flat.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$cityName\'da öne çıkan deneyimler',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.purpleDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'GetYourGuide partner seçkisi — detaylar uygulama içinde',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 14),
        ...flat.take(6).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final raw = entry.value;
          final act = ActivityListingEnrichment.enrich(
            raw,
            index: i,
            cityName: cityName,
            categoryId: raw['category'] as String? ?? 'tours',
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ExperienceCard(
              activity: act,
              cityName: cityName,
              destinationIata: destinationIata,
              departureDate: departureDate,
              returnDate: returnDate,
              showOffer: i.isEven,
            ),
          );
        }),
      ],
    );
  }
}

class _ExperienceCard extends StatefulWidget {
  const _ExperienceCard({
    required this.activity,
    required this.cityName,
    required this.destinationIata,
    this.departureDate,
    this.returnDate,
    this.showOffer = false,
  });

  final Map<String, dynamic> activity;
  final String cityName;
  final String destinationIata;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final bool showOffer;

  @override
  State<_ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<_ExperienceCard> {
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    await ActivityFavoritesStore.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _favorite = ActivityFavoritesStore.instance.isFavorite(
        ActivityFavoritesStore.activityId(widget.activity, widget.cityName),
      );
    });
  }

  Future<void> _toggleFavorite() async {
    final id = ActivityFavoritesStore.activityId(widget.activity, widget.cityName);
    final on = await ActivityFavoritesStore.instance.toggle(id);
    if (!mounted) return;
    setState(() => _favorite = on);
  }

  void _openDetail() {
    pushAppRoute(
      context,
      ActivityExperienceDetailScreen(
        activity: widget.activity,
        cityName: widget.cityName,
        destinationIata: widget.destinationIata,
        categoryId: widget.activity['category'] as String? ?? 'tours',
        eventDate: widget.departureDate,
        returnDate: widget.returnDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.activity;
    final price = (act['priceTL'] as num?)?.toInt() ?? 0;
    final rating = (act['rating'] as num?)?.toDouble() ?? 0;
    final reviews = (act['reviewCount'] as num?)?.toInt() ?? 0;
    final imageUrl = act['imageUrl'] as String?;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openDetail,
        child: Container(
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
                height: 180,
                width: double.infinity,
                child: ActivityNetworkImage(
                  imageUrl: imageUrl,
                  activityId: act['id'] as String? ?? 'exp',
                  category: act['category'] as String? ?? 'tours',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              if (widget.showOffer)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.fuchsiaSoft,
                      border: Border.all(color: AppTheme.fuchsia.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Özel fırsat',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.fuchsiaDark,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _toggleFavorite,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _favorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                      size: 18,
                      color: _favorite ? AppTheme.fuchsia : AppTheme.textPrimary,
                    ),
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
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppTheme.teal),
                    const SizedBox(width: 4),
                    Text(
                      '${rating.toStringAsFixed(1)} ($reviews)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  act['title'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(CupertinoIcons.location_solid, size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.cityName,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(CupertinoIcons.checkmark_seal, size: 12, color: AppTheme.teal),
                    SizedBox(width: 4),
                    Text(
                      'Ücretsiz iptal (24 saat)',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${PriceFormat.format(price)}’den başlayan',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.fuchsia,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _openDetail,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.textPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Detayları gör',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}
