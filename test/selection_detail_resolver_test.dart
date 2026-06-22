import 'package:flutter_test/flutter_test.dart';
import 'package:tatil_arama/utils/selection_detail_resolver.dart';

void main() {
  test('haversineKm computes Rome airport to center roughly', () {
    final km = SelectionDetailResolver.haversineKm(
      lat1: 41.8003,
      lng1: 12.2389,
      lat2: 41.9028,
      lng2: 12.4964,
    );
    expect(km, inInclusiveRange(22, 35));
  });

  test('hotelDetails includes maps link when coordinates exist', () {
    final lines = SelectionDetailResolver.hotelDetails(
      hotel: {
        'name': 'Hotel Test',
        'latitude': 41.89,
        'longitude': 12.49,
      },
      cityName: 'Roma',
      destinationIata: 'FCO',
    );
    expect(lines.any((l) => l.actionLabel == 'Haritada aç'), isTrue);
    expect(lines.any((l) => l.label.contains('Pantheon')), isTrue);
    final address = lines.firstWhere((l) => l.label == 'Adres');
    expect(address.value, contains('Roma'));
    expect(address.value, contains('tam konum haritada'));
  });

  test('flightDetails formats times, airports and duration', () {
    final lines = SelectionDetailResolver.flightDetails(
      flight: {
        'departureTime': '2026-07-16T11:36:00',
        'arrivalTime': '2026-07-16T17:13:00',
        'returnDepartureTime': '2026-07-21T14:20:00',
        'returnArrivalTime': '2026-07-21T20:05:00',
        'returnDuration': 'PT4H45M',
        'returnStops': 0,
        'duration': 'PT4H37M',
        'stops': 0,
      },
      originIata: 'IST',
      destinationIata: 'DXB',
      destinationCity: 'Dubai',
      hotel: {
        'latitude': 25.11,
        'longitude': 55.20,
      },
      departureDate: DateTime(2026, 7, 16),
      returnDate: DateTime(2026, 7, 21),
    );

    final dep = lines.firstWhere((l) => l.label == 'Gidiş kalkış');
    expect(dep.value, contains('11:36'));
    expect(dep.value, contains('İstanbul Havalimanı · IST'));

    final retDep = lines.firstWhere((l) => l.label == 'Dönüş kalkış');
    expect(retDep.value, contains('14:20'));
    expect(retDep.value, contains('Dubai International · DXB'));

    final retArr = lines.firstWhere((l) => l.label == 'Dönüş varış');
    expect(retArr.value, contains('20:05'));
    expect(retArr.value, contains('İstanbul Havalimanı · IST'));

    final returnType = lines.firstWhere((l) => l.label == 'Dönüş uçuşu');
    expect(returnType.value, contains('4s 45dk'));

    final type = lines.firstWhere((l) => l.label == 'Gidiş uçuşu');
    expect(type.value, contains('4s 37dk'));
  });

  test('hotelDetails has no generic disclaimer note', () {
    final lines = SelectionDetailResolver.hotelDetails(
      hotel: {
        'name': 'Citymax Hotel Al Barsha at the Mall',
        'latitude': 25.11,
        'longitude': 55.20,
      },
      cityName: 'Dubai',
      destinationIata: 'DXB',
    );
    expect(lines.any((l) => l.label == 'Not'), isFalse);
    final address = lines.firstWhere((l) => l.label == 'Adres');
    expect(address.value, contains('Al Barsha'));
    expect(address.value, contains('Dubai'));
  });
}
