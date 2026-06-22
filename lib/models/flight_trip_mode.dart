/// Uçak arama tipi — Turna tarzı gidiş-dönüş / tek yön / çoklu.
enum FlightTripMode {
  roundTrip,
  oneWay,
  multiCity,
}

extension FlightTripModeMeta on FlightTripMode {
  String get label {
    switch (this) {
      case FlightTripMode.roundTrip:
        return 'Gidiş-dönüş';
      case FlightTripMode.oneWay:
        return 'Tek yön';
      case FlightTripMode.multiCity:
        return 'Çoklu uçuş';
    }
  }
}
