import '../data/bundled_destinations.dart';
import '../data/destination_spending_averages.dart';
import '../models/destination_score_model.dart';

/// Yerel harcama kartı — uçuş hariç tahmini maliyet (RouteVS tarzı).
class DestinationTripCostEstimator {
  DestinationTripCostEstimator._();

  static DestinationTripCostEstimate estimate({
    required String iata,
    required String country,
    required int nights,
    required int adults,
    int centralStayPerNight = 0,
  }) {
    final costIndex = _costIndex(iata);
    final daily = DestinationSpendingAverages.forDestination(
      iata: iata,
      country: country,
      costIndex: costIndex,
    );

    final dailyMin = (daily.total * 0.85).round();
    final dailyMax = (daily.total * 1.2).round();

    final stayBase = centralStayPerNight > 0
        ? centralStayPerNight
        : (daily.food * 1.15 + 1200).round();
    final stayMin = (stayBase * 0.88).round();
    final stayMax = (stayBase * 1.25).round();

    final tripMin = ((dailyMin * nights * adults) + (stayMin * nights)).round();
    final tripMax = ((dailyMax * nights * adults) + (stayMax * nights)).round();

    return DestinationTripCostEstimate(
      dailyPerPersonMin: dailyMin,
      dailyPerPersonMax: dailyMax,
      centralStayMin: stayMin,
      centralStayMax: stayMax,
      tripTotalMin: tripMin,
      tripTotalMax: tripMax,
      nights: nights,
      adults: adults,
    );
  }

  static double? _costIndex(String iata) {
    for (final d in BundledDestinations.raw) {
      if ((d['iataCode'] as String).toUpperCase() == iata.toUpperCase()) {
        return (d['costIndex'] as num?)?.toDouble();
      }
    }
    return null;
  }
}
