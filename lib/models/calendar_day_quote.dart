class CalendarDayQuote {
  const CalendarDayQuote({
    required this.departureDate,
    this.flightTL = 0,
    this.hotelTL = 0,
    this.loading = false,
    this.failed = false,
  });

  final DateTime departureDate;
  final int flightTL;
  final int hotelTL;
  final bool loading;
  final bool failed;

  int get packageTL => flightTL + hotelTL;

  bool get hasPrice => packageTL > 0;

  CalendarDayQuote copyWith({
    int? flightTL,
    int? hotelTL,
    bool? loading,
    bool? failed,
  }) {
    return CalendarDayQuote(
      departureDate: departureDate,
      flightTL: flightTL ?? this.flightTL,
      hotelTL: hotelTL ?? this.hotelTL,
      loading: loading ?? this.loading,
      failed: failed ?? this.failed,
    );
  }
}
