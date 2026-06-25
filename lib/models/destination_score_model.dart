class DestinationScoreItem {
  const DestinationScoreItem({
    required this.title,
    required this.score,
    required this.badgeLabel,
  });

  final String title;
  final double score;
  final String badgeLabel;

  double get progress => (score / 10).clamp(0.0, 1.0);
}

class DestinationScoreFramework {
  const DestinationScoreFramework({
    required this.items,
    this.source = 'catalog',
  });

  final List<DestinationScoreItem> items;
  final String source;

  bool get isEmpty => items.isEmpty;
}

class DestinationComparisonGuide {
  const DestinationComparisonGuide({
    required this.leftIata,
    required this.leftCity,
    required this.rightIata,
    required this.rightCity,
    required this.title,
    required this.summary,
    this.isPopular = false,
    this.year = 2026,
  });

  final String leftIata;
  final String leftCity;
  final String rightIata;
  final String rightCity;
  final String title;
  final String summary;
  final bool isPopular;
  final int year;
}

class DestinationTripCostEstimate {
  const DestinationTripCostEstimate({
    required this.dailyPerPersonMin,
    required this.dailyPerPersonMax,
    required this.centralStayMin,
    required this.centralStayMax,
    required this.tripTotalMin,
    required this.tripTotalMax,
    required this.nights,
    required this.adults,
  });

  final int dailyPerPersonMin;
  final int dailyPerPersonMax;
  final int centralStayMin;
  final int centralStayMax;
  final int tripTotalMin;
  final int tripTotalMax;
  final int nights;
  final int adults;
}
