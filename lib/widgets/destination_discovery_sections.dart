import 'package:flutter/material.dart';

import '../data/destination_comparison_catalog.dart';
import '../data/destination_score_catalog.dart';
import '../data/destination_trip_cost_estimator.dart';
import 'destination_comparison_section.dart';
import 'destination_experiences_section.dart';
import 'destination_places_section.dart';
import 'destination_score_framework.dart';
import 'destination_trip_cost_card.dart';
import 'vizegoo_trust_footer.dart';

export 'destination_comparison_section.dart';
export 'destination_experiences_section.dart';
export 'destination_places_section.dart';
export 'destination_score_framework.dart';
export 'destination_trip_cost_card.dart';

/// RouteVS + GetYourGuide + Viator tarzı destinasyon keşif bölümleri.
class DestinationDiscoverySections extends StatelessWidget {
  const DestinationDiscoverySections({
    super.key,
    required this.cityName,
    required this.country,
    required this.destinationIata,
    required this.nights,
    required this.adults,
    this.holidayTypes = const [],
    this.activitiesData,
    this.departureDate,
    this.returnDate,
    this.onViewAllActivities,
  });

  final String cityName;
  final String country;
  final String destinationIata;
  final int nights;
  final int adults;
  final List<String> holidayTypes;
  final Map<String, dynamic>? activitiesData;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final VoidCallback? onViewAllActivities;

  @override
  Widget build(BuildContext context) {
    final comparisons = DestinationComparisonCatalog.forIata(destinationIata);
    final scores = DestinationScoreCatalog.forDestination(
      iata: destinationIata,
      country: country,
    );
    final tripCost = DestinationTripCostEstimator.estimate(
      iata: destinationIata,
      country: country,
      nights: nights,
      adults: adults,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (comparisons.isNotEmpty) ...[
          DestinationComparisonSection(
            guides: comparisons,
            currentIata: destinationIata,
          ),
          const SizedBox(height: 24),
        ],
        DestinationScoreFrameworkSection(framework: scores),
        const SizedBox(height: 24),
        DestinationTripCostCard(estimate: tripCost),
        const SizedBox(height: 24),
        DestinationPlacesSection(
          cityName: cityName,
          iata: destinationIata,
          holidayTypes: holidayTypes,
          onViewTours: onViewAllActivities,
        ),
        if (activitiesData != null) ...[
          const SizedBox(height: 24),
          DestinationExperiencesSection(
            cityName: cityName,
            destinationIata: destinationIata,
            activitiesData: activitiesData!,
            departureDate: departureDate,
            returnDate: returnDate,
          ),
          const SizedBox(height: 8),
          if (onViewAllActivities != null)
            TextButton(
              onPressed: onViewAllActivities,
              child: const Text('Tüm aktiviteleri gör'),
            ),
        ],
        const SizedBox(height: 24),
        const VizegooTrustFooter(compact: true),
      ],
    );
  }
}
