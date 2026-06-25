import '../data/bundled_destinations.dart';
import '../data/destination_spending_averages.dart';
import '../models/destination_score_model.dart';

/// Destinasyon puanları — yerel katalog + harcama ortalamalarından türetilir.
/// İleride: `GET /advisor/discovery` yanıtına `score_framework` alanı eklenebilir.
class DestinationScoreCatalog {
  DestinationScoreCatalog._();

  static DestinationScoreFramework forDestination({
    required String iata,
    required String country,
    double? costIndex,
    double? hotelRatingMin,
  }) {
    final meta = _metaFor(iata, costIndex: costIndex, hotelRatingMin: hotelRatingMin);
    final daily = DestinationSpendingAverages.forDestination(
      iata: iata,
      country: country,
      costIndex: costIndex,
    );

    final affordability = _affordabilityScore(daily.total, meta.costIndex);
    final transport = _transportScore(daily.transport);
    final stay = _stayScore(meta.hotelRating);
    final food = _foodScore(daily.food);
    final experience = _experienceScore(meta);
    final walkability = _walkabilityScore(iata);

    return DestinationScoreFramework(
      source: 'vizegoo_catalog',
      items: [
        DestinationScoreItem(
          title: 'Affordability',
          score: affordability,
          badgeLabel: _badgeFor(affordability, high: 'Budget-friendly', mid: 'Fair value', low: 'Premium'),
        ),
        DestinationScoreItem(
          title: 'Getting around',
          score: transport,
          badgeLabel: _badgeFor(transport, high: 'Excellent', mid: 'Very good', low: 'Plan ahead'),
        ),
        DestinationScoreItem(
          title: 'Stay quality',
          score: stay,
          badgeLabel: _badgeFor(stay, high: 'Excellent', mid: 'Very good', low: 'Mixed'),
        ),
        DestinationScoreItem(
          title: 'Food & drink',
          score: food,
          badgeLabel: _badgeFor(food, high: 'Outstanding', mid: 'Very good', low: 'Basic'),
        ),
        DestinationScoreItem(
          title: 'Overall experience',
          score: experience,
          badgeLabel: _badgeFor(experience, high: 'Excellent', mid: 'Very good', low: 'Good'),
        ),
        DestinationScoreItem(
          title: 'Walkability',
          score: walkability,
          badgeLabel: _badgeFor(walkability, high: 'Very walkable', mid: 'Walkable core', low: 'Car helpful'),
        ),
      ],
    );
  }

  static _Meta _metaFor(String iata, {double? costIndex, double? hotelRatingMin}) {
    for (final d in BundledDestinations.raw) {
      if ((d['iataCode'] as String).toUpperCase() == iata.toUpperCase()) {
        return _Meta(
          costIndex: costIndex ?? (d['costIndex'] as num?)?.toDouble() ?? 55,
          hotelRating: hotelRatingMin ?? (d['hotelRatingMin'] as num?)?.toDouble() ?? 7.2,
        );
      }
    }
    return _Meta(costIndex: costIndex ?? 55, hotelRating: hotelRatingMin ?? 7.2);
  }

  static double _affordabilityScore(int dailyTotal, double costIndex) {
    final base = 10 - (dailyTotal / 350).clamp(0, 6) - (costIndex / 25).clamp(0, 2.5);
    return base.clamp(5.5, 9.6).toDouble();
  }

  static double _transportScore(int transportDaily) {
    return (9.2 - transportDaily / 120).clamp(6.0, 9.4).toDouble();
  }

  static double _stayScore(double hotelRating) {
    return (hotelRating * 1.05).clamp(6.5, 9.5).toDouble();
  }

  static double _foodScore(int foodDaily) {
    return (8.8 - foodDaily / 400).clamp(6.2, 9.3).toDouble();
  }

  static double _experienceScore(_Meta meta) {
    return ((meta.hotelRating + (10 - meta.costIndex / 12)) / 2).clamp(6.8, 9.6).toDouble();
  }

  static double _walkabilityScore(String iata) {
    const high = {'AMS', 'BCN', 'CDG', 'FCO', 'ATH', 'LIS', 'PRG', 'BUD', 'IST'};
    const mid = {'BER', 'LHR', 'DXB', 'NRT', 'JFK', 'ADB', 'ESB'};
    final code = iata.toUpperCase();
    if (high.contains(code)) return 8.8;
    if (mid.contains(code)) return 7.6;
    return 6.9;
  }

  static String _badgeFor(double score, {required String high, required String mid, required String low}) {
    if (score >= 8.5) return high;
    if (score >= 7.5) return mid;
    return low;
  }
}

class _Meta {
  const _Meta({required this.costIndex, required this.hotelRating});
  final double costIndex;
  final double hotelRating;
}
