class PriceWatch {
  const PriceWatch({
    required this.id,
    required this.originIata,
    required this.destinationIata,
    required this.cityName,
    required this.country,
    required this.departureDate,
    required this.returnDate,
    required this.targetPriceTL,
    required this.lastSeenPriceTL,
    required this.createdAt,
    this.passengers = 1,
    this.nights = 5,
  });

  final String id;
  final String originIata;
  final String destinationIata;
  final String cityName;
  final String country;
  final DateTime departureDate;
  final DateTime returnDate;
  final int targetPriceTL;
  final int lastSeenPriceTL;
  final DateTime createdAt;
  final int passengers;
  final int nights;

  bool get isTargetMet => lastSeenPriceTL > 0 && lastSeenPriceTL <= targetPriceTL;

  String get routeLabel => '$originIata → $destinationIata';

  Map<String, dynamic> toJson() => {
        'id': id,
        'originIata': originIata,
        'destinationIata': destinationIata,
        'cityName': cityName,
        'country': country,
        'departureDate': departureDate.toIso8601String(),
        'returnDate': returnDate.toIso8601String(),
        'targetPriceTL': targetPriceTL,
        'lastSeenPriceTL': lastSeenPriceTL,
        'createdAt': createdAt.toIso8601String(),
        'passengers': passengers,
        'nights': nights,
      };

  factory PriceWatch.fromJson(Map<String, dynamic> json) {
    return PriceWatch(
      id: json['id']?.toString() ?? '',
      originIata: json['originIata']?.toString() ?? 'IST',
      destinationIata: json['destinationIata']?.toString() ?? '',
      cityName: json['cityName']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      departureDate: DateTime.tryParse(json['departureDate']?.toString() ?? '') ??
          DateTime.now(),
      returnDate: DateTime.tryParse(json['returnDate']?.toString() ?? '') ??
          DateTime.now(),
      targetPriceTL: (json['targetPriceTL'] as num?)?.round() ?? 0,
      lastSeenPriceTL: (json['lastSeenPriceTL'] as num?)?.round() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      passengers: (json['passengers'] as num?)?.round() ?? 1,
      nights: (json['nights'] as num?)?.round() ?? 5,
    );
  }

  PriceWatch copyWith({int? lastSeenPriceTL}) => PriceWatch(
        id: id,
        originIata: originIata,
        destinationIata: destinationIata,
        cityName: cityName,
        country: country,
        departureDate: departureDate,
        returnDate: returnDate,
        targetPriceTL: targetPriceTL,
        lastSeenPriceTL: lastSeenPriceTL ?? this.lastSeenPriceTL,
        createdAt: createdAt,
        passengers: passengers,
        nights: nights,
      );
}
