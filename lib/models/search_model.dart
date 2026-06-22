import 'date_flexibility.dart';
import 'flight_cabin_class.dart';
import 'flight_leg.dart';
import 'flight_trip_mode.dart';

class SearchModel {
  static const int minBudgetTL = 10000;

  /// Rota motoru min. 10.000 TL ister; kullanıcı bütçe girmezse keşif araması için gönderilir.
  static const int gatewayDefaultBudgetTL = 120000;

  String originIata;
  String originCity;
  String? continent;
  String? holidayType;
  List<String> holidayTypes;
  String? destinationIata;
  String? destinationCity;
  String? destinationCountry;
  DateTime departureDate;
  DateTime returnDate;
  double totalBudgetTL;
  int passengers;
  int children;
  bool showSpendingEstimates;
  double minServiceRating;
  double maxServiceRating;
  bool sortByCheapest;
  DateFlexibility dateFlexibility;
  bool isRoundTrip;
  FlightTripMode flightTripMode;
  List<FlightLeg> multiCityLegs;
  FlightCabinClass flightCabinClass;
  bool directFlightsOnly;

  SearchModel({
    this.originIata = 'IST',
    this.originCity = 'İstanbul',
    this.continent,
    this.holidayType,
    this.holidayTypes = const [],
    this.destinationIata,
    this.destinationCity,
    this.destinationCountry,
    DateTime? departureDate,
    DateTime? returnDate,
    this.totalBudgetTL = 0,
    this.passengers = 1,
    this.children = 0,
    this.showSpendingEstimates = false,
    this.minServiceRating = 7.5,
    this.maxServiceRating = 10.0,
    this.sortByCheapest = false,
    this.dateFlexibility = DateFlexibility.exact,
    this.isRoundTrip = true,
    this.flightTripMode = FlightTripMode.roundTrip,
    this.multiCityLegs = const [],
    this.flightCabinClass = FlightCabinClass.economy,
    this.directFlightsOnly = false,
  })  : departureDate = departureDate ?? DateTime.now().add(const Duration(days: 30)),
        returnDate = returnDate ?? DateTime.now().add(const Duration(days: 35));

  int get nights => isRoundTrip
      ? returnDate.difference(departureDate).inDays
      : 0;

  bool get hasBudget => totalBudgetTL >= minBudgetTL;

  /// Gateway / Python arama isteğine giden bütçe (kullanıcı arayüzündeki değil).
  int get gatewayBudgetTL =>
      hasBudget ? totalBudgetTL.round() : gatewayDefaultBudgetTL;

  bool get isMultiCity => flightTripMode == FlightTripMode.multiCity;

  bool get isValid {
    if (flightTripMode == FlightTripMode.multiCity) {
      if (multiCityLegs.length < 2) return false;
      if (!multiCityLegs.every((l) => l.isComplete)) return false;
      final today = DateTime.now();
      final min = DateTime(today.year, today.month, today.day);
      for (final leg in multiCityLegs) {
        final dep = DateTime(
          leg.departureDate.year,
          leg.departureDate.month,
          leg.departureDate.day,
        );
        if (dep.isBefore(min)) return false;
      }
      for (var i = 1; i < multiCityLegs.length; i++) {
        if (multiCityLegs[i]
            .departureDate
            .isBefore(multiCityLegs[i - 1].departureDate)) {
          return false;
        }
      }
      return true;
    }
    if (!isRoundTrip) {
      final today = DateTime.now();
      final dep = DateTime(departureDate.year, departureDate.month, departureDate.day);
      final min = DateTime(today.year, today.month, today.day);
      return !dep.isBefore(min);
    }
    return returnDate.isAfter(departureDate) &&
        returnDate.difference(departureDate).inDays >= 1 &&
        returnDate.difference(departureDate).inDays <= 30;
  }

  String get budgetSegment {
    if (!hasBudget) return 'Esnek';
    if (totalBudgetTL < 25000) return 'Ekonomik';
    if (totalBudgetTL < 60000) return 'Standart';
    return 'Premium';
  }

  double get budgetSliderMax {
    if (holidayType == 'health' || holidayTypes.contains('wellness')) {
      return 500000;
    }
    return 200000;
  }

  Map<String, dynamic> toJson() => {
        'originIata': originIata,
        'departureDate': departureDate.toIso8601String().split('T')[0],
        'returnDate': returnDate.toIso8601String().split('T')[0],
        'totalBudgetTL': totalBudgetTL,
        'passengers': passengers,
        'children': children,
        'showSpendingEstimates': showSpendingEstimates,
        if (continent != null) 'continent': continent,
        if (holidayType != null) 'holidayType': holidayType,
        if (holidayTypes.isNotEmpty) 'holidayTypes': holidayTypes,
        if (destinationIata != null) 'destinationIata': destinationIata,
        if (destinationCountry != null) 'destinationCountry': destinationCountry,
        'minServiceRating': minServiceRating,
        'maxServiceRating': maxServiceRating,
        'sortByCheapest': sortByCheapest,
        'dateFlexibility': dateFlexibility.name,
        'isRoundTrip': isRoundTrip,
        'flightTripMode': flightTripMode.name,
        if (multiCityLegs.isNotEmpty)
          'multiCityLegs': multiCityLegs.map((l) => l.toJson()).toList(),
        'flightCabinClass': flightCabinClass.apiValue,
        'directFlightsOnly': directFlightsOnly,
      };

  SearchModel copyWith({
    String? originIata,
    String? originCity,
    Object? continent = _unset,
    Object? holidayType = _unset,
    List<String>? holidayTypes,
    Object? destinationIata = _unset,
    Object? destinationCity = _unset,
    Object? destinationCountry = _unset,
    DateTime? departureDate,
    DateTime? returnDate,
    double? totalBudgetTL,
    int? passengers,
    int? children,
    bool? showSpendingEstimates,
    double? minServiceRating,
    double? maxServiceRating,
    bool? sortByCheapest,
    DateFlexibility? dateFlexibility,
    bool? isRoundTrip,
    FlightTripMode? flightTripMode,
    List<FlightLeg>? multiCityLegs,
    FlightCabinClass? flightCabinClass,
    bool? directFlightsOnly,
  }) {
    final mode = flightTripMode ??
        (isRoundTrip == null
            ? this.flightTripMode
            : (isRoundTrip ? FlightTripMode.roundTrip : FlightTripMode.oneWay));
  return SearchModel(
      originIata: originIata ?? this.originIata,
      originCity: originCity ?? this.originCity,
      continent: continent == _unset ? this.continent : continent as String?,
      holidayType:
          holidayType == _unset ? this.holidayType : holidayType as String?,
      holidayTypes: holidayTypes ?? this.holidayTypes,
      destinationIata: destinationIata == _unset
          ? this.destinationIata
          : destinationIata as String?,
      destinationCity: destinationCity == _unset
          ? this.destinationCity
          : destinationCity as String?,
      destinationCountry: destinationCountry == _unset
          ? this.destinationCountry
          : destinationCountry as String?,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      totalBudgetTL: totalBudgetTL ?? this.totalBudgetTL,
      passengers: passengers ?? this.passengers,
      children: children ?? this.children,
      showSpendingEstimates:
          showSpendingEstimates ?? this.showSpendingEstimates,
      minServiceRating: minServiceRating ?? this.minServiceRating,
      maxServiceRating: maxServiceRating ?? this.maxServiceRating,
      sortByCheapest: sortByCheapest ?? this.sortByCheapest,
      dateFlexibility: dateFlexibility ?? this.dateFlexibility,
      isRoundTrip: mode == FlightTripMode.roundTrip,
      flightTripMode: mode,
      multiCityLegs: multiCityLegs ?? this.multiCityLegs,
      flightCabinClass: flightCabinClass ?? this.flightCabinClass,
      directFlightsOnly: directFlightsOnly ?? this.directFlightsOnly,
    );
  }
}

const _unset = Object();
