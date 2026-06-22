import 'package:flutter_test/flutter_test.dart';
import 'package:tatil_arama/models/route_result_model.dart';
import 'package:tatil_arama/utils/live_offer_matcher.dart';
import 'package:tatil_arama/utils/price_format.dart';

void main() {
  final planHotel = RouteHotelModel(
    id: '',
    name: 'Hotel Arts Barcelona',
    city: 'Barcelona',
    hotelType: 'hotel',
    starRating: 5,
    reviewScore: 9.0,
    reviewCount: 1000,
    pricePerNight: 20395,
    totalPrice: 101975,
    features: const [],
    isPartner: false,
  );

  final liveHotels = [
    {
      'name': 'BLAU Student Housing - Students Only',
      'pricePerNightTL': 30162,
      'rating': 8.6,
      'stars': 2,
    },
    {
      'name': 'Hotel Arts Barcelona',
      'pricePerNightTL': 21000,
      'rating': 9.1,
      'stars': 5,
    },
    {
      'name': 'Budget Hostel BCN',
      'pricePerNightTL': 8000,
      'rating': 7.0,
      'stars': 1,
    },
  ];

  test('preferCheapest picks cheapest hotel total', () {
    final index = LiveOfferMatcher.bestHotelIndex(
      hotels: liveHotels,
      planHotel: planHotel,
      nights: 5,
      targetPerNightTL: 20395,
      preferCheapest: true,
    );
    expect(liveHotels[index]['name'], 'Budget Hostel BCN');
  });

  test('prefers plan hotel name over cheapest student housing', () {
    final index = LiveOfferMatcher.bestHotelIndex(
      hotels: liveHotels,
      planHotel: planHotel,
      nights: 5,
      targetPerNightTL: 20395,
    );
    expect(liveHotels[index]['name'], contains('Hotel Arts'));
  });

  test('penalizes student housing when no exact name match', () {
    final hotels = [
      liveHotels[0],
      {
        'name': 'Grand Marina Hotel',
        'pricePerNightTL': 19500,
        'rating': 8.8,
        'stars': 4,
      },
    ];
    final index = LiveOfferMatcher.bestHotelIndex(
      hotels: hotels,
      planHotel: planHotel,
      nights: 5,
      targetPerNightTL: 20395,
    );
    expect(hotels[index]['name'], 'Grand Marina Hotel');
    expect(
      PriceFormat.hotelTotalTL(hotels[index], 5),
      greaterThan(PriceFormat.hotelTotalTL(hotels[0], 5) == 0 ? 0 : 0),
    );
  });

  test('Antalya — plan fiyatına yakın otel, pahalı havalimanı oteline tercih', () {
    final akraPlan = RouteHotelModel(
      id: '',
      name: 'Akra Hotels',
      city: 'Antalya',
      hotelType: 'hotel',
      starRating: 5,
      reviewScore: 8.6,
      reviewCount: 500,
      pricePerNight: 7200,
      totalPrice: 36000,
      features: const [],
      isPartner: false,
    );

    final antalyaLive = [
      {
        'name': 'C Suites Antalia Airport',
        'pricePerNightTL': 16312,
        'rating': 8.4,
        'stars': 4,
      },
      {
        'name': 'Coastline Orange Hotel',
        'pricePerNightTL': 15655,
        'rating': 9.1,
        'stars': 4,
      },
      {
        'name': 'Sunrise Resort Hotel',
        'pricePerNightTL': 7800,
        'rating': 8.2,
        'stars': 4,
      },
      {
        'name': 'Budget Hostel Antalya',
        'pricePerNightTL': 1200,
        'rating': 7.0,
        'stars': 1,
      },
    ];

    final index = LiveOfferMatcher.bestHotelIndex(
      hotels: antalyaLive,
      planHotel: akraPlan,
      nights: 5,
      targetPerNightTL: 7200,
    );

    expect(antalyaLive[index]['name'], 'Sunrise Resort Hotel');
    expect(
      PriceFormat.hotelPerNightTL(antalyaLive[index]),
      lessThan(9000),
    );
  });

  test('prefers cheapest direct flight when airline not in live list', () {
    final planFlight = RouteFlightModel(
      airline: 'Alitalia',
      duration: '2s 50dk',
      stops: 0,
      departureTime: '07:45',
      arrivalTime: '10:35',
      priceTL: 8299,
      pricePerPersonTL: 8299,
    );
    final flights = [
      {'airline': 'Duffel Airways', 'totalAmountTL': 4291, 'stops': 0},
      {'airline': 'Iberia', 'totalAmountTL': 4416, 'stops': 0},
      {'airline': 'Lufthansa', 'totalAmountTL': 6369, 'stops': 1},
    ];
    final index = LiveOfferMatcher.bestFlightIndex(
      flights: flights,
      planFlight: planFlight,
    );
    expect(flights[index]['airline'], 'Duffel Airways');
    expect(PriceFormat.flightTL(flights[index]), 4291);
  });

  test('flight without airline match prefers cheapest direct', () {
    final planFlight = RouteFlightModel(
      airline: 'THY',
      duration: '1s 10dk',
      stops: 0,
      departureTime: '08:00',
      arrivalTime: '09:10',
      priceTL: 1795,
      pricePerPersonTL: 1795,
    );
    final flights = [
      {'airline': 'Duffel Airways', 'totalAmountTL': 2260, 'stops': 0},
      {'airline': 'Budget Air', 'totalAmountTL': 8900, 'stops': 1},
    ];
    final index = LiveOfferMatcher.bestFlightIndex(
      flights: flights,
      planFlight: planFlight,
    );
    expect(flights[index]['airline'], 'Duffel Airways');
    expect(PriceFormat.flightTL(flights[index]), 2260);
  });

  test('matches flight by airline name', () {
    final planFlight = RouteFlightModel(
      airline: 'Vueling',
      duration: '3s 45dk',
      stops: 0,
      departureTime: '08:00',
      arrivalTime: '12:00',
      priceTL: 9941,
      pricePerPersonTL: 9941,
    );
    final flights = [
      {'airline': 'Ryanair', 'totalAmountTL': 4000},
      {'airline': 'Vueling', 'totalAmountTL': 5277},
    ];
    final index = LiveOfferMatcher.bestFlightIndex(
      flights: flights,
      planFlight: planFlight,
    );
    expect(flights[index]['airline'], 'Vueling');
  });
}
