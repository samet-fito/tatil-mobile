import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../screens/destination_guide_screen.dart';

/// Checkout özet adımında rehber teaser — tam içerik ödeme sonrası açılır.
class CheckoutGuidePreviewCard extends StatelessWidget {
  const CheckoutGuidePreviewCard({
    super.key,
    required this.cityName,
    required this.country,
    required this.destinationIata,
    required this.departureDate,
    required this.returnDate,
    required this.nights,
    required this.adults,
    required this.children,
    this.hotelName,
  });

  final String cityName;
  final String country;
  final String destinationIata;
  final DateTime departureDate;
  final DateTime returnDate;
  final int nights;
  final int adults;
  final int children;
  final String? hotelName;

  void _openTeaser(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationGuideScreen(
          cityName: cityName,
          country: country,
          destinationIata: destinationIata,
          departureDate: departureDate,
          returnDate: returnDate,
          nights: nights,
          adults: adults,
          children: children,
          hotelName: hotelName,
          previewMode: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openTeaser(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.teal.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.book, color: AppTheme.teal, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$cityName\'da ne yapmalısın?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ödeme sonrası · hava, kurallar, hayati uyarılar, ipuçları',
                    style: TatilTheme.hint.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: AppTheme.teal),
          ],
        ),
      ),
    );
  }
}
