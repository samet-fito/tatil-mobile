import '../models/flight_leg.dart';
import '../models/multi_city_search_result.dart';
import '../models/route_result_model.dart';
import '../services/api_service.dart';
import '../utils/category_checkout_route.dart';

/// Çoklu uçuş + son destinasyonda otel paketi.
class MultiCityPackageOffer {
  const MultiCityPackageOffer({
    required this.route,
    required this.flights,
    required this.hotels,
    required this.departureDate,
    required this.returnDate,
    required this.legs,
    required this.flightTotalTL,
    required this.originIata,
  });

  final RouteResultModel route;
  final List<Map<String, dynamic>> flights;
  final List<Map<String, dynamic>> hotels;
  final DateTime departureDate;
  final DateTime returnDate;
  final List<FlightLeg> legs;
  final int flightTotalTL;
  final String originIata;
}

abstract final class MultiCityPackageService {
  static const defaultNightsAtDestination = 3;

  static Future<MultiCityPackageOffer?> buildPackage({
    required List<MultiCityLegResult> selectedLegs,
    required int passengers,
    int nightsAtDestination = defaultNightsAtDestination,
  }) async {
    if (selectedLegs.isEmpty ||
        selectedLegs.any((l) => l.flights.isEmpty || l.selectedFlight == null)) {
      return null;
    }

    final last = selectedLegs.last.leg;
    final checkIn = last.departureDate;
    final checkOut = checkIn.add(Duration(days: nightsAtDestination));

    final hotels = await ApiService.searchHotels(
      cityName: last.destinationCity,
      checkIn: checkIn,
      returnDate: checkOut,
      adults: passengers,
      destinationIata: last.destinationIata,
      nights: nightsAtDestination,
    );
    if (hotels.isEmpty) return null;

    final combinedFlights = <Map<String, dynamic>>[];
    for (final leg in selectedLegs) {
      final f = leg.selectedFlight;
      if (f != null) combinedFlights.add(f);
    }

    final flightTotal = selectedLegs.fold<int>(
      0,
      (sum, l) => sum + l.selectedPriceTL,
    );

    final legs = selectedLegs.map((l) => l.leg).toList();
    final route = CategoryCheckoutRoute.build(
      destinationIata: last.destinationIata,
      cityName: last.destinationCity,
      country: '',
      nights: nightsAtDestination,
      passengers: passengers,
      flightTL: flightTotal,
    );

    return MultiCityPackageOffer(
      route: route,
      flights: combinedFlights,
      hotels: hotels,
      departureDate: selectedLegs.first.leg.departureDate,
      returnDate: checkOut,
      legs: legs,
      flightTotalTL: flightTotal,
      originIata: selectedLegs.first.leg.originIata,
    );
  }
}
