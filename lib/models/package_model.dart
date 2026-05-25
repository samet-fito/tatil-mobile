class PackageModel {
  final String destinationId;
  final String cityName;
  final String iataCode;
  final String country;
  final String countryCode;
  final int score;
  final bool isAffordable;
  final int nights;
  final List<String> highlights;
  final FlightInfo flightInfo;
  final HotelInfo hotelInfo;
  final EstimatedCost estimatedCost;
  final BudgetBreakdown budgetBreakdown;

  PackageModel({
    required this.destinationId,
    required this.cityName,
    required this.iataCode,
    required this.country,
    required this.countryCode,
    required this.score,
    required this.isAffordable,
    required this.nights,
    required this.highlights,
    required this.flightInfo,
    required this.hotelInfo,
    required this.estimatedCost,
    required this.budgetBreakdown,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      destinationId: json['destinationId'] ?? '',
      cityName: json['cityName'] ?? '',
      iataCode: json['iataCode'] ?? '',
      country: json['country'] ?? '',
      countryCode: json['countryCode'] ?? '',
      score: json['score'] ?? 0,
      isAffordable: json['isAffordable'] ?? false,
      nights: json['nights'] ?? 0,
      highlights: List<String>.from(json['highlights'] ?? []),
      flightInfo: FlightInfo.fromJson(json['flightInfo'] ?? {}),
      hotelInfo: HotelInfo.fromJson(json['hotelInfo'] ?? {}),
      estimatedCost: EstimatedCost.fromJson(json['estimatedCost'] ?? {}),
      budgetBreakdown: BudgetBreakdown.fromJson(json['budgetBreakdown'] ?? {}),
    );
  }

  bool get isDomestic => country == 'Turkey';

  String get countryCodeFromCountry {
    const map = {
      'Turkey': 'TR', 'Italy': 'IT', 'Greece': 'GR',
      'Hungary': 'HU', 'UAE': 'AE', 'Spain': 'ES',
      'France': 'FR', 'Netherlands': 'NL',
    };
    return map[country] ?? 'IT';
  }
}

class FlightInfo {
  final String airline;
  final String duration;
  final int stops;
  final String departureTime;
  final String arrivalTime;

  FlightInfo({
    required this.airline,
    required this.duration,
    required this.stops,
    required this.departureTime,
    required this.arrivalTime,
  });

  factory FlightInfo.fromJson(Map<String, dynamic> json) {
    return FlightInfo(
      airline: json['airline'] ?? '--',
      duration: json['duration'] ?? '--',
      stops: json['stops'] ?? 0,
      departureTime: json['departureTime'] ?? '--',
      arrivalTime: json['arrivalTime'] ?? '--',
    );
  }
}

class HotelInfo {
  final String name;
  final int stars;
  final double rating;
  final int reviewCount;
  final List<String> amenities;

  HotelInfo({
    required this.name,
    required this.stars,
    required this.rating,
    required this.reviewCount,
    required this.amenities,
  });

  factory HotelInfo.fromJson(Map<String, dynamic> json) {
    return HotelInfo(
      name: json['name'] ?? '--',
      stars: json['stars'] ?? 3,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      amenities: List<String>.from(json['amenities'] ?? []),
    );
  }
}

class EstimatedCost {
  final int total;
  final int flight;
  final int hotel;
  final int living;
  final int remaining;

  EstimatedCost({
    required this.total,
    required this.flight,
    required this.hotel,
    required this.living,
    required this.remaining,
  });

  factory EstimatedCost.fromJson(Map<String, dynamic> json) {
    return EstimatedCost(
      total: (json['total'] ?? 0).toInt(),
      flight: (json['flight'] ?? 0).toInt(),
      hotel: (json['hotel'] ?? 0).toInt(),
      living: (json['living'] ?? 0).toInt(),
      remaining: (json['remaining'] ?? 0).toInt(),
    );
  }
}

class BudgetBreakdown {
  final String segment;
  final String segmentLabel;
  final BreakdownDetail transport;
  final BreakdownDetail accommodation;
  final BreakdownDetail pocketMoney;

  BudgetBreakdown({
    required this.segment,
    required this.segmentLabel,
    required this.transport,
    required this.accommodation,
    required this.pocketMoney,
  });

  factory BudgetBreakdown.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] ?? {};
    return BudgetBreakdown(
      segment: json['segment'] ?? 'standard',
      segmentLabel: json['segmentLabel'] ?? 'Standart',
      transport: BreakdownDetail.fromJson(breakdown['transport'] ?? {}),
      accommodation: BreakdownDetail.fromJson(breakdown['accommodation'] ?? {}),
      pocketMoney: BreakdownDetail.fromJson(breakdown['pocketMoney'] ?? {}),
    );
  }
}

class BreakdownDetail {
  final int total;
  final int percentage;
  final String label;

  BreakdownDetail({
    required this.total,
    required this.percentage,
    required this.label,
  });

  factory BreakdownDetail.fromJson(Map<String, dynamic> json) {
    return BreakdownDetail(
      total: (json['total'] ?? 0).toInt(),
      percentage: (json['percentage'] ?? 0).toInt(),
      label: json['label'] ?? '',
    );
  }
}