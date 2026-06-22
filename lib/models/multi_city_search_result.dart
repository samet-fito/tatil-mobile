import 'flight_leg.dart';
import '../utils/price_format.dart';

class MultiCityLegResult {
  const MultiCityLegResult({
    required this.leg,
    required this.flights,
    this.selectedFlightIndex = 0,
  });

  final FlightLeg leg;
  final List<Map<String, dynamic>> flights;
  final int selectedFlightIndex;

  Map<String, dynamic>? get selectedFlight =>
      flights.isNotEmpty ? flights[selectedFlightIndex.clamp(0, flights.length - 1)] : null;

  int get selectedPriceTL {
    final f = selectedFlight;
    if (f == null) return 0;
    return PriceFormat.flightTotalTL(f, roundTrip: false);
  }

  int get cheapestPriceTL {
    if (flights.isEmpty) return 0;
    var min = 999999999;
    for (final f in flights) {
      final p = PriceFormat.flightTotalTL(f, roundTrip: false);
      if (p < min) min = p;
    }
    return min == 999999999 ? 0 : min;
  }

  MultiCityLegResult copyWith({int? selectedFlightIndex}) => MultiCityLegResult(
        leg: leg,
        flights: flights,
        selectedFlightIndex: selectedFlightIndex ?? this.selectedFlightIndex,
      );
}

class MultiCitySearchResult {
  const MultiCitySearchResult({required this.legs});

  final List<MultiCityLegResult> legs;

  bool get hasAnyFlights => legs.any((l) => l.flights.isNotEmpty);

  int get totalSelectedTL =>
      legs.fold(0, (sum, l) => sum + l.selectedPriceTL);

  int get totalCheapestTL =>
      legs.fold(0, (sum, l) => sum + l.cheapestPriceTL);

  String get routeSummary =>
      legs.map((l) => l.leg.routeLabel).join(' · ');
}
