import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/hotel_location_hints.dart';
import '../utils/price_format.dart';
import 'destination_hero_image.dart';
import 'hotel_experience_sheet.dart';
import 'offer_data_badge.dart';

/// Otel bölümü — görsel önizleme kartı, dokununca detay sayfası açılır.
class HotelVisualPreviewCard extends StatelessWidget {
  const HotelVisualPreviewCard({
    super.key,
    required this.hotel,
    required this.cityName,
    required this.destinationIata,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.sourceIsLive,
    this.onChange,
  });

  final Map<String, dynamic> hotel;
  final String cityName;
  final String destinationIata;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final bool sourceIsLive;
  final VoidCallback? onChange;

  String _date(DateTime d) => '${d.day}.${d.month}.${d.year}';

  String? get _photoUrl {
    final url = hotel['photoUrl']?.toString().trim();
    if (url != null && url.isNotEmpty && url.startsWith('http')) return url;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final name = hotel['name']?.toString() ?? 'Otel';
    final rating = PriceFormat.hotelRatingLine(hotel);
    final hint = HotelLocationHints.forHotel(hotel, cityName);
    final perNight = PriceFormat.hotelPerNightTL(hotel);
    final total = PriceFormat.hotelTotalTL(hotel, nights);

    return GestureDetector(
      onTap: () => showHotelExperienceSheet(
        context,
        hotel: hotel,
        cityName: cityName,
        destinationIata: destinationIata,
        checkIn: checkIn,
        checkOut: checkOut,
        nights: nights,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_photoUrl != null)
                    CachedNetworkImage(
                      imageUrl: _photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => DestinationHeroImage(
                        iataCode: destinationIata,
                      ),
                    )
                  else
                    DestinationHeroImage(iataCode: destinationIata),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: OfferSourceChip(isLive: sourceIsLive),
                  ),
                  if (onChange != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: TextButton(
                        onPressed: onChange,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.92),
                          foregroundColor: AppTheme.orange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Değiştir',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        if (hint != null)
                          Text(
                            hint,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giriş ${_date(checkIn)} · Çıkış ${_date(checkOut)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            '$nights gece',
                            if (rating.isNotEmpty) rating,
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.photo_on_rectangle,
                              size: 13,
                              color: AppTheme.teal.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Görseller & mesafe haritası',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.teal.withValues(alpha: 0.95),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              CupertinoIcons.chevron_right,
                              size: 12,
                              color: AppTheme.teal,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        PriceFormat.format(total),
                        style: TatilTheme.priceDisplay(
                          fontSize: 15,
                          color: AppTheme.orange,
                        ),
                      ),
                      Text(
                        '${PriceFormat.format(perNight)}/gece',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
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
}
