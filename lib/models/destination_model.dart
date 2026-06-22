class DestinationModel {
  final String iataCode;
  final String cityName;
  final String country;
  final double? costIndex;
  final double? hotelRatingMin;
  final double? distanceToCenterKm;

  const DestinationModel({
    required this.iataCode,
    required this.cityName,
    required this.country,
    this.costIndex,
    this.hotelRatingMin,
    this.distanceToCenterKm,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    return DestinationModel(
      iataCode: (json['iataCode'] as String? ?? '').toUpperCase(),
      cityName: json['cityName'] as String? ?? '',
      country: json['country'] as String? ?? '',
      costIndex: (json['costIndex'] as num?)?.toDouble(),
      hotelRatingMin: (json['hotelRatingMin'] as num?)?.toDouble(),
      distanceToCenterKm: (json['distanceToCenterKm'] as num?)?.toDouble(),
    );
  }
}

class CountryOption {
  final String country;
  final String labelTr;
  final String flag;
  final String? continent;
  final List<DestinationModel> cities;
  final double? avgCostIndex;

  const CountryOption({
    required this.country,
    required this.labelTr,
    required this.flag,
    required this.continent,
    required this.cities,
    this.avgCostIndex,
  });

  int get cityCount => cities.length;
}
