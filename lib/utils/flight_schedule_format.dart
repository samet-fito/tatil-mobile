/// Gidiş-dönüş uçuş saatlerini okunabilir metne çevirir.
class FlightScheduleFormat {
  FlightScheduleFormat._();

  static const _months = [
    '',
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  static bool hasTime(dynamic raw) {
    if (raw == null) return false;
    final text = raw.toString().trim();
    return text.isNotEmpty && text != '--';
  }

  static DateTime? _parse(dynamic raw) {
    if (!hasTime(raw)) return null;
    return DateTime.tryParse(raw.toString().trim());
  }

  static DateTime? parseIso(dynamic raw) => _parse(raw);

  static String timeHm(dynamic raw, DateTime fallbackDate) {
    final dt = _parse(raw) ?? fallbackDate;
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String dateTimeLabel(dynamic raw, DateTime fallbackDate) {
    final dt = _parse(raw);
    if (dt == null) {
      return '${fallbackDate.day} ${_months[fallbackDate.month]} · saat netleşecek';
    }
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${_months[local.month]} $hh:$mm';
  }

  static String legRange({
    required dynamic departureRaw,
    required dynamic arrivalRaw,
    required DateTime fallbackDate,
    required String label,
  }) {
    if (!hasTime(departureRaw) && !hasTime(arrivalRaw)) return '';
    final dep = timeHm(departureRaw, fallbackDate);
    final arr = timeHm(arrivalRaw, fallbackDate);
    return '$label $dep–$arr';
  }

  static String roundTripTimesLine(
    Map<String, dynamic> flight,
    DateTime departureDate,
    DateTime returnDate,
  ) {
    final outbound = legRange(
      departureRaw: flight['departureTime'],
      arrivalRaw: flight['arrivalTime'],
      fallbackDate: departureDate,
      label: 'Gidiş',
    );
    final inbound = legRange(
      departureRaw: flight['returnDepartureTime'],
      arrivalRaw: flight['returnArrivalTime'],
      fallbackDate: returnDate,
      label: 'Dönüş',
    );

    if (outbound.isEmpty && inbound.isEmpty) return '';
    if (inbound.isEmpty) return outbound;
    if (outbound.isEmpty) return inbound;
    return '$outbound · $inbound';
  }

  static String outboundTimesLine(
    Map<String, dynamic> flight,
    DateTime departureDate,
  ) {
    return legRange(
      departureRaw: flight['departureTime'],
      arrivalRaw: flight['arrivalTime'],
      fallbackDate: departureDate,
      label: 'Gidiş',
    );
  }

  static bool hasReturnTimes(Map<String, dynamic> flight) =>
      hasTime(flight['returnDepartureTime']) &&
      hasTime(flight['returnArrivalTime']);
}
