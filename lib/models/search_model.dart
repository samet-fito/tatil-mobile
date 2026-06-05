class SearchModel {
  String originIata;
  String originCity;
  String? continent;
  String? holidayType;
  DateTime departureDate;
  DateTime returnDate;
  double totalBudgetTL;
  int passengers;
  int children = 0;

  SearchModel({
    this.originIata = 'IST',
    this.originCity = 'İstanbul',
    this.continent,
    this.holidayType,
    DateTime? departureDate,
    DateTime? returnDate,
    this.totalBudgetTL = 30000,
    this.passengers = 1,
    this.children = 0,
  })  : departureDate = departureDate ?? DateTime.now().add(const Duration(days: 30)),
        returnDate = returnDate ?? DateTime.now().add(const Duration(days: 35));

  int get nights => returnDate.difference(departureDate).inDays;

  bool get isValid =>
      totalBudgetTL >= 10000 &&
      returnDate.isAfter(departureDate) &&
      nights >= 1 &&
      nights <= 30;

  String get budgetSegment {
    if (totalBudgetTL < 25000) return 'Ekonomik';
    if (totalBudgetTL < 60000) return 'Standart';
    return 'Premium';
  }

  double get budgetSliderMax {
    if (holidayType == 'health') return 500000;
    return 200000;
  }

  Map<String, dynamic> toJson() => {
        'originIata': originIata,
        'departureDate': departureDate.toIso8601String().split('T')[0],
        'returnDate': returnDate.toIso8601String().split('T')[0],
        'totalBudgetTL': totalBudgetTL,
        'passengers': passengers,
        'children': children,
        if (continent != null) 'continent': continent,
        if (holidayType != null) 'holidayType': holidayType,
      };

  SearchModel copyWith({
    String? originIata,
    String? originCity,
    String? continent,
    String? holidayType,
    DateTime? departureDate,
    DateTime? returnDate,
    double? totalBudgetTL,
    int? passengers,
    int? children,
  }) {
    return SearchModel(
      originIata: originIata ?? this.originIata,
      originCity: originCity ?? this.originCity,
      continent: continent ?? this.continent,
      holidayType: holidayType ?? this.holidayType,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      totalBudgetTL: totalBudgetTL ?? this.totalBudgetTL,
      passengers: passengers ?? this.passengers,
      children: children ?? this.children,
    );
  }
}