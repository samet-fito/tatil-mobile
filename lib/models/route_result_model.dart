class RouteResultModel {
  final String destinationIata;
  final String cityName;
  final String country;
  final int nights;
  final int passengers;
  final int children;
  final double score;
  final bool isAffordable;
  final RouteFlightModel? flight;
  final RouteHotelModel? hotel;
  final RouteTransferModel? transfer;
  final RouteBudgetBreakdown budgetBreakdown;
  final RouteEstimatedCost estimatedCost;
  final String? alternativeSuggestion;

  RouteResultModel({
    required this.destinationIata,
    required this.cityName,
    required this.country,
    required this.nights,
    required this.passengers,
    this.children = 0,
    required this.score,
    required this.isAffordable,
    this.flight,
    this.hotel,
    this.transfer,
    required this.budgetBreakdown,
    required this.estimatedCost,
    this.alternativeSuggestion,
  });

  bool get isBestChoice => score >= 95;
  bool get hasWarning => !isAffordable || alternativeSuggestion != null;

  factory RouteResultModel.fromJson(Map<String, dynamic> json) {
    // Python motoru formatı (destination_iata)
    if (json.containsKey('destination_iata')) {
      return RouteResultModel(
        destinationIata: json['destination_iata'] ?? '',
        cityName: json['city_name'] ?? '',
        country: json['country'] ?? '',
        nights: json['nights'] ?? 0,
        passengers: json["passengers"] ?? 1,
        children: json["children"] ?? 0,
        score: (json['score'] ?? 0).toDouble(),
        isAffordable: json['is_affordable'] ?? false,
        flight: json['flight'] != null
            ? RouteFlightModel.fromJson(json['flight'])
            : null,
        hotel: json['hotel'] != null
            ? RouteHotelModel.fromJson(json['hotel'])
            : null,
        transfer: json['transfer'] != null
            ? RouteTransferModel.fromJson(json['transfer'])
            : null,
        budgetBreakdown: RouteBudgetBreakdown.fromJson(
            json['budget_breakdown'] ?? {}),
        estimatedCost: RouteEstimatedCost.fromJson(
            json['estimated_cost'] ?? {}),
        alternativeSuggestion: json['alternative_suggestion'],
      );
    }

    // Node.js fallback formatı (cityName, iataCode)
    final bd = json['budgetBreakdown'] ?? {};
    final breakdown = bd['breakdown'] ?? {};
    final cost = json['estimatedCost'] ?? {};
    final nights = json['nights'] ?? 1;

    return RouteResultModel(
      destinationIata: json['iataCode'] ?? '',
      cityName: json['cityName'] ?? '',
      country: json['country'] ?? '',
      nights: nights,
      passengers: json['passengers'] ?? 1,
      score: (json['score'] ?? 0).toDouble(),
      isAffordable: json['isAffordable'] ?? false,
      flight: json['flightInfo'] != null
          ? RouteFlightModel.fromNodeJson(json['flightInfo'], cost)
          : null,
      hotel: json['hotelInfo'] != null
          ? RouteHotelModel.fromNodeJson(json['hotelInfo'], cost, nights)
          : null,
      transfer: null,
      budgetBreakdown: RouteBudgetBreakdown.fromNodeJson(bd, breakdown),
      estimatedCost: RouteEstimatedCost.fromNodeJson(cost),
      alternativeSuggestion: null,
    );
  }
}

class RouteFlightModel {
  final String airline;
  final String duration;
  final int stops;
  final String departureTime;
  final String arrivalTime;
  final double priceTL;
  final double pricePerPersonTL;

  RouteFlightModel({
    required this.airline,
    required this.duration,
    required this.stops,
    required this.departureTime,
    required this.arrivalTime,
    required this.priceTL,
    required this.pricePerPersonTL,
  });

  factory RouteFlightModel.fromJson(Map<String, dynamic> json) {
    return RouteFlightModel(
      airline: json['airline'] ?? '--',
      duration: json['duration'] ?? '--',
      stops: json['stops'] ?? 0,
      departureTime: json['departure_time'] ?? '--',
      arrivalTime: json['arrival_time'] ?? '--',
      priceTL: (json['price_tl'] ?? 0).toDouble(),
      pricePerPersonTL: (json['price_per_person_tl'] ?? 0).toDouble(),
    );
  }

  factory RouteFlightModel.fromNodeJson(
      Map<String, dynamic> json, Map cost) {
    return RouteFlightModel(
      airline: json['airline'] ?? '--',
      duration: json['duration'] ?? '--',
      stops: json['stops'] ?? 0,
      departureTime: json['departureTime'] ?? '--',
      arrivalTime: json['arrivalTime'] ?? '--',
      priceTL: (cost['flight'] ?? 0).toDouble(),
      pricePerPersonTL: (cost['flight'] ?? 0).toDouble(),
    );
  }
}

class RouteHotelModel {
  final String id;
  final String name;
  final String city;
  final String hotelType;
  final double starRating;
  final double reviewScore;
  final int reviewCount;
  final double pricePerNight;
  final double totalPrice;
  final List<String> features;
  final bool isPartner;
  final double commissionRate;

  RouteHotelModel({
    required this.id,
    required this.name,
    required this.city,
    required this.hotelType,
    required this.starRating,
    required this.reviewScore,
    required this.reviewCount,
    required this.pricePerNight,
    required this.totalPrice,
    required this.features,
    required this.isPartner,
    this.commissionRate = 0.12,
  });

  factory RouteHotelModel.fromJson(Map<String, dynamic> json) {
    return RouteHotelModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '--',
      city: json['city'] ?? '--',
      hotelType: json['hotel_type'] ?? 'hotel',
      starRating: (json['star_rating'] ?? 3).toDouble(),
      reviewScore: (json['review_score'] ?? 7).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      pricePerNight: (json['price_per_night'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      features: List<String>.from(json['features'] ?? []),
      isPartner: json['is_partner'] ?? false,
      commissionRate: (json['commission_rate'] ?? 0.12).toDouble(),
    );
  }

  factory RouteHotelModel.fromNodeJson(
      Map<String, dynamic> json, Map cost, int nights) {
    final hotelCost = (cost['hotel'] ?? 0).toDouble();
    return RouteHotelModel(
      id: '',
      name: json['name'] ?? '--',
      city: '',
      hotelType: 'hotel',
      starRating: (json['stars'] ?? 3).toDouble(),
      reviewScore: (json['rating'] ?? 7).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      pricePerNight: nights > 0 ? hotelCost / nights : hotelCost,
      totalPrice: hotelCost,
      features: List<String>.from(json['amenities'] ?? []),
      isPartner: false,
      commissionRate: 0.12,
    );
  }
}

class RouteTransferModel {
  final String id;
  final String? companyName;
  final String vehicleType;
  final int capacity;
  final String routeFrom;
  final String routeTo;
  final double priceFixed;
  final int? durationMinutes;
  final List<String> features;

  RouteTransferModel({
    required this.id,
    this.companyName,
    required this.vehicleType,
    required this.capacity,
    required this.routeFrom,
    required this.routeTo,
    required this.priceFixed,
    this.durationMinutes,
    required this.features,
  });

  factory RouteTransferModel.fromJson(Map<String, dynamic> json) {
    return RouteTransferModel(
      id: json['id'] ?? '',
      companyName: json['company_name'],
      vehicleType: json['vehicle_type'] ?? 'sedan',
      capacity: json['capacity'] ?? 4,
      routeFrom: json['route_from'] ?? '--',
      routeTo: json['route_to'] ?? '--',
      priceFixed: (json['price_fixed'] ?? 0).toDouble(),
      durationMinutes: json['duration_minutes'],
      features: List<String>.from(json['features'] ?? []),
    );
  }
}

class RouteBudgetBreakdown {
  final String segment;
  final String segmentLabel;
  final double totalBudgetTL;
  final double flightBudget;
  final double hotelBudget;
  final double transferBudget;
  final double pocketMoney;
  final int flightPercentage;
  final int hotelPercentage;
  final int transferPercentage;
  final int pocketPercentage;

  RouteBudgetBreakdown({
    required this.segment,
    required this.segmentLabel,
    required this.totalBudgetTL,
    required this.flightBudget,
    required this.hotelBudget,
    required this.transferBudget,
    required this.pocketMoney,
    required this.flightPercentage,
    required this.hotelPercentage,
    required this.transferPercentage,
    required this.pocketPercentage,
  });

  factory RouteBudgetBreakdown.fromJson(Map<String, dynamic> json) {
    return RouteBudgetBreakdown(
      segment: json['segment'] ?? 'standard',
      segmentLabel: json['segment_label'] ?? 'Standart',
      totalBudgetTL: (json['total_budget_tl'] ?? 0).toDouble(),
      flightBudget: (json['flight_budget'] ?? 0).toDouble(),
      hotelBudget: (json['hotel_budget'] ?? 0).toDouble(),
      transferBudget: (json['transfer_budget'] ?? 0).toDouble(),
      pocketMoney: (json['pocket_money'] ?? 0).toDouble(),
      flightPercentage: json['flight_percentage'] ?? 25,
      hotelPercentage: json['hotel_percentage'] ?? 40,
      transferPercentage: json['transfer_percentage'] ?? 5,
      pocketPercentage: json['pocket_percentage'] ?? 30,
    );
  }

  factory RouteBudgetBreakdown.fromNodeJson(
      Map<String, dynamic> bd, Map<String, dynamic> breakdown) {
    final transport = breakdown['transport'] ?? {};
    final accommodation = breakdown['accommodation'] ?? {};
    final pocket = breakdown['pocketMoney'] ?? {};
    return RouteBudgetBreakdown(
      segment: bd['segment'] ?? 'standard',
      segmentLabel: bd['segmentLabel'] ?? 'Standart',
      totalBudgetTL: (bd['totalBudgetTL'] ?? 0).toDouble(),
      flightBudget: (transport['total'] ?? 0).toDouble(),
      hotelBudget: (accommodation['total'] ?? 0).toDouble(),
      transferBudget: 0,
      pocketMoney: (pocket['total'] ?? 0).toDouble(),
      flightPercentage: transport['percentage'] ?? 25,
      hotelPercentage: accommodation['percentage'] ?? 40,
      transferPercentage: 5,
      pocketPercentage: pocket['percentage'] ?? 30,
    );
  }
}

class RouteEstimatedCost {
  final int total;
  final int flight;
  final int hotel;
  final int transfer;
  final int pocketMoney;
  final int remaining;

  RouteEstimatedCost({
    required this.total,
    required this.flight,
    required this.hotel,
    required this.transfer,
    required this.pocketMoney,
    required this.remaining,
  });

  factory RouteEstimatedCost.fromJson(Map<String, dynamic> json) {
    return RouteEstimatedCost(
      total: (json['total'] ?? 0).toInt(),
      flight: (json['flight'] ?? 0).toInt(),
      hotel: (json['hotel'] ?? 0).toInt(),
      transfer: (json['transfer'] ?? 0).toInt(),
      pocketMoney: (json['pocket_money'] ?? 0).toInt(),
      remaining: (json['remaining'] ?? 0).toInt(),
    );
  }

  factory RouteEstimatedCost.fromNodeJson(Map<String, dynamic> json) {
    return RouteEstimatedCost(
      total: (json['total'] ?? 0).toInt(),
      flight: (json['flight'] ?? 0).toInt(),
      hotel: (json['hotel'] ?? 0).toInt(),
      transfer: 0,
      pocketMoney: (json['living'] ?? json['pocket_money'] ?? 0).toInt(),
      remaining: (json['remaining'] ?? 0).toInt(),
    );
  }
}