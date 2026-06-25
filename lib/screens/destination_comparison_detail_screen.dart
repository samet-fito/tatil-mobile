import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/destination_score_catalog.dart';
import '../city_images.dart';
import '../models/destination_score_model.dart';
import '../theme/app_theme.dart';
import '../widgets/destination_score_framework.dart';

class DestinationComparisonDetailScreen extends StatelessWidget {
  const DestinationComparisonDetailScreen({super.key, required this.guide});

  final DestinationComparisonGuide guide;

  @override
  Widget build(BuildContext context) {
    final leftScores = DestinationScoreCatalog.forDestination(
      iata: guide.leftIata,
      country: '',
    );
    final rightScores = DestinationScoreCatalog.forDestination(
      iata: guide.rightIata,
      country: '',
    );

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('${guide.leftCity} vs ${guide.rightCity}'),
        backgroundColor: AppTheme.bgPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Expanded(
                  child: Image.network(
                    CityImages.networkUrl(guide.leftIata),
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Image.network(
                    CityImages.networkUrl(guide.rightIata),
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            guide.title,
            style: GoogleFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.purpleDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            guide.summary,
            style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 24),
          Text(
            guide.leftCity,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          DestinationScoreFrameworkSection(framework: leftScores),
          const SizedBox(height: 20),
          Text(
            guide.rightCity,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          DestinationScoreFrameworkSection(framework: rightScores),
        ],
      ),
    );
  }
}
