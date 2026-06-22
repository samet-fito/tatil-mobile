import '../models/stored_booking_model.dart';
import '../utils/flight_schedule_format.dart';

/// Biniş kartında gösterilecek uçuş bilgileri.
class BoardingPassData {
  const BoardingPassData({
    required this.passengerName,
    required this.reservationRef,
    required this.originIata,
    required this.destinationIata,
    required this.originCity,
    required this.destinationCity,
    required this.departureTimeLabel,
    required this.arrivalTimeLabel,
    required this.flightNumber,
    required this.airline,
    required this.statusLabel,
    required this.terminal,
    required this.checkInCounters,
    required this.gate,
    required this.seat,
    required this.priorityLabel,
    required this.departsInLabel,
    required this.qrPayload,
    required this.detailsPending,
  });

  final String passengerName;
  final String reservationRef;
  final String originIata;
  final String destinationIata;
  final String originCity;
  final String destinationCity;
  final String departureTimeLabel;
  final String arrivalTimeLabel;
  final String flightNumber;
  final String airline;
  final String statusLabel;
  final String terminal;
  final String checkInCounters;
  final String gate;
  final String seat;
  final String priorityLabel;
  final String departsInLabel;
  final String qrPayload;
  final bool detailsPending;

  factory BoardingPassData.fromBooking(StoredBooking booking) {
    final hash = booking.reservationId.hashCode.abs();
    final depDt = FlightScheduleFormat.parseIso(booking.departureTime) ??
        DateTime(
          booking.departureDate.year,
          booking.departureDate.month,
          booking.departureDate.day,
          10,
          30,
        );
    final arrDt = FlightScheduleFormat.parseIso(booking.arrivalTime) ??
        depDt.add(const Duration(hours: 2, minutes: 15));

    final until = depDt.difference(DateTime.now());
    final departsIn = _formatCountdown(until);

    final airlineCode = booking.airlineCode ??
        _airlineCodeFromName(booking.airline ?? 'VG');
    final flightNo = booking.flightNumber ??
        '$airlineCode${(hash % 9000 + 1000)}';

    final pending = booking.gate == null || booking.gate!.isEmpty;
    final terminal = booking.terminal ?? 'T${(hash % 3) + 1}';
    final checkIn = booking.checkInCounters ?? '${45 + hash % 10}-${55 + hash % 10}';
    final gate = booking.gate ?? '${String.fromCharCode(65 + hash % 4)}${(hash % 28) + 1}';
    final seat = booking.seat ??
        '${10 + hash % 18}${['A', 'B', 'C', 'D', 'E', 'F'][hash % 6]}';

    return BoardingPassData(
      passengerName: booking.passengerName,
      reservationRef: booking.shortReservationRef,
      originIata: booking.originIata,
      destinationIata: booking.destinationIata,
      originCity: booking.originIata,
      destinationCity: booking.cityName,
      departureTimeLabel: FlightScheduleFormat.timeHm(booking.departureTime, depDt),
      arrivalTimeLabel: FlightScheduleFormat.timeHm(booking.arrivalTime, arrDt),
      flightNumber: flightNo,
      airline: booking.airline ?? 'Havayolu',
      statusLabel: until.isNegative ? 'Kalktı' : 'Zamanında',
      terminal: terminal,
      checkInCounters: checkIn,
      gate: gate,
      seat: seat,
      priorityLabel: booking.boardingPriority ?? 'Standart',
      departsInLabel: departsIn,
      qrPayload:
          'VIZEGOO|${booking.reservationId}|$flightNo|${booking.passengerName}',
      detailsPending: pending && until.inHours < 48,
    );
  }

  static String _formatCountdown(Duration d) {
    if (d.isNegative) return 'Uçuş tamamlandı';
    if (d.inDays >= 1) return '${d.inDays} gün sonra';
    if (d.inHours >= 1) return '${d.inHours} saat sonra';
    if (d.inMinutes >= 1) return '${d.inMinutes} dk sonra';
    return 'Yakında';
  }

  static String _airlineCodeFromName(String name) {
    final clean = name.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
    if (clean.length >= 2) return clean.substring(0, 2);
    return 'VG';
  }
}
