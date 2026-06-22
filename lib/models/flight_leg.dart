class FlightLeg {
  const FlightLeg({
    required this.originIata,
    required this.originCity,
    required this.destinationIata,
    required this.destinationCity,
    required this.departureDate,
  });

  final String originIata;
  final String originCity;
  final String destinationIata;
  final String destinationCity;
  final DateTime departureDate;

  String get routeLabel => '$originIata → $destinationIata';

  bool get isComplete =>
      originIata.isNotEmpty &&
      destinationIata.isNotEmpty &&
      originCity.isNotEmpty &&
      destinationCity.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'originIata': originIata,
        'originCity': originCity,
        'destinationIata': destinationIata,
        'destinationCity': destinationCity,
        'departureDate': departureDate.toIso8601String(),
      };

  factory FlightLeg.fromJson(Map<String, dynamic> json) {
    return FlightLeg(
      originIata: json['originIata']?.toString() ?? '',
      originCity: json['originCity']?.toString() ?? '',
      destinationIata: json['destinationIata']?.toString() ?? '',
      destinationCity: json['destinationCity']?.toString() ?? '',
      departureDate: DateTime.tryParse(json['departureDate']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  FlightLeg copyWith({
    String? originIata,
    String? originCity,
    String? destinationIata,
    String? destinationCity,
    DateTime? departureDate,
  }) {
    return FlightLeg(
      originIata: originIata ?? this.originIata,
      originCity: originCity ?? this.originCity,
      destinationIata: destinationIata ?? this.destinationIata,
      destinationCity: destinationCity ?? this.destinationCity,
      departureDate: departureDate ?? this.departureDate,
    );
  }
}
