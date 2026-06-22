import 'package:flutter_test/flutter_test.dart';
import 'package:tatil_arama/utils/flight_schedule_format.dart';

void main() {
  test('roundTripTimesLine shows outbound and return hours', () {
    final line = FlightScheduleFormat.roundTripTimesLine(
      {
        'departureTime': '2026-07-16T11:36:00',
        'arrivalTime': '2026-07-16T17:13:00',
        'returnDepartureTime': '2026-07-21T14:20:00',
        'returnArrivalTime': '2026-07-21T20:05:00',
      },
      DateTime(2026, 7, 16),
      DateTime(2026, 7, 21),
    );

    expect(line, contains('Gidiş 11:36–17:13'));
    expect(line, contains('Dönüş 14:20–20:05'));
  });
}
