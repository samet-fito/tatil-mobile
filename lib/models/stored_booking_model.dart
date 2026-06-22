import 'search_category.dart';

class StoredBooking {
  const StoredBooking({
    required this.reservationId,
    required this.cityName,
    required this.country,
    required this.destinationIata,
    required this.nights,
    required this.departureDate,
    required this.returnDate,
    required this.adults,
    required this.children,
    required this.totalPriceTL,
    required this.passengerName,
    required this.passengerEmail,
    this.passengerAges = const [],
    this.holidayTypes = const [],
    this.bookingScope = 'package',
    this.productCategory,
    this.productTitle,
    required this.createdAt,
    this.originIata = 'IST',
    this.airline,
    this.departureTime,
    this.arrivalTime,
    this.returnDepartureTime,
    this.returnArrivalTime,
    this.hotelName,
    this.hotelPhotoUrl,
    this.hotelLatitude,
    this.hotelLongitude,
    this.flightPriceTL = 0,
    this.hotelPriceTL = 0,
    this.flightNumber,
    this.airlineCode,
    this.terminal,
    this.checkInCounters,
    this.gate,
    this.seat,
    this.boardingPriority,
  });

  final String reservationId;
  final String cityName;
  final String country;
  final String destinationIata;
  final int nights;
  final DateTime departureDate;
  final DateTime returnDate;
  final int adults;
  final int children;
  final int totalPriceTL;
  final String passengerName;
  final String passengerEmail;
  final List<int> passengerAges;
  final List<String> holidayTypes;
  final String bookingScope;
  final String? productCategory;
  final String? productTitle;
  final DateTime createdAt;
  final String originIata;
  final String? airline;
  final String? departureTime;
  final String? arrivalTime;
  final String? returnDepartureTime;
  final String? returnArrivalTime;
  final String? hotelName;
  final String? hotelPhotoUrl;
  final double? hotelLatitude;
  final double? hotelLongitude;
  final int flightPriceTL;
  final int hotelPriceTL;
  final String? flightNumber;
  final String? airlineCode;
  final String? terminal;
  final String? checkInCounters;
  final String? gate;
  final String? seat;
  final String? boardingPriority;

  bool get hasFlight =>
      bookingScope != 'hotelOnly' &&
      (airline != null || departureTime != null);
  bool get hasHotel =>
      bookingScope != 'flightOnly' &&
      hotelName != null &&
      hotelName!.isNotEmpty;

  bool get isActivity => productCategory == 'activities';

  bool get isBus => productCategory == 'bus';

  bool get isTransfer => productCategory == 'transfer';

  bool get isCarRental => productCategory == 'carRental';

  bool get isStandaloneProduct =>
      isActivity || isBus || isTransfer || isCarRental;

  SearchCategory? get productSearchCategory {
    final pc = productCategory;
    if (pc == null || pc.isEmpty) return null;
    for (final c in SearchCategory.values) {
      if (c.name == pc) return c;
    }
    return null;
  }

  String get categoryLabel => productSearchCategory?.label ?? 'Rezervasyon';

  bool get isCategoryBooking =>
      productCategory != null &&
      productCategory!.isNotEmpty &&
      productCategory != 'packageTour';

  /// Liste / kart için yeterli alanlar dolu mu.
  bool get isDisplayReady =>
      cityName.trim().isNotEmpty && totalPriceTL > 0;

  /// İki kayıttan daha eksiksiz olanı seç (bulut senkron boş detay üstüne yazmasın).
  static StoredBooking preferRicher(StoredBooking a, StoredBooking b) {
    final scoreA = _richnessScore(a);
    final scoreB = _richnessScore(b);
    if (scoreA == scoreB) {
      return a.createdAt.isAfter(b.createdAt) ? a : b;
    }
    return scoreA > scoreB ? a : b;
  }

  static int _richnessScore(StoredBooking b) {
    var s = 0;
    if (b.cityName.trim().isNotEmpty) s += 4;
    if (b.totalPriceTL > 0) s += 4;
    if (b.passengerName.trim().isNotEmpty) s += 2;
    if (b.hasFlight) s += 1;
    if (b.hasHotel) s += 1;
    if (b.hotelPhotoUrl != null && b.hotelPhotoUrl!.isNotEmpty) s += 1;
    return s;
  }

  /// Kısa rezervasyon referansı (liste satırı).
  String get shortReservationRef {
    final id = reservationId;
    if (id.startsWith('VG-') && id.length > 12) {
      return 'VG-${id.substring(id.length - 8).toUpperCase()}';
    }
    return id;
  }

  String get listTitle {
    if (productTitle != null && productTitle!.trim().isNotEmpty) {
      return productTitle!.trim();
    }
    if (cityName.trim().isNotEmpty) return cityName.trim();
    if (destinationIata.trim().isNotEmpty) return destinationIata.trim();
    return 'Seyahat';
  }

  String get listSubtitle {
    if (isStandaloneProduct) {
      final dep =
          '${departureDate.day.toString().padLeft(2, '0')}.'
          '${departureDate.month.toString().padLeft(2, '0')}.'
          '${departureDate.year}';
      final ret =
          '${returnDate.day.toString().padLeft(2, '0')}.'
          '${returnDate.month.toString().padLeft(2, '0')}.'
          '${returnDate.year}';
      final parts = <String>[categoryLabel];
      if (cityName.trim().isNotEmpty) parts.add(cityName.trim());
      if (isCarRental && returnDate.isAfter(departureDate)) {
        parts.add('$dep – $ret');
      } else {
        parts.add(dep);
      }
      if (adults > 1) parts.add('$adults kişi');
      return parts.join(' · ');
    }
    final parts = <String>[];
    if (country.trim().isNotEmpty) parts.add(country.trim());
    parts.add('$nights gece');
    parts.add(
      '${departureDate.day.toString().padLeft(2, '0')}.'
      '${departureDate.month.toString().padLeft(2, '0')}.'
      '${departureDate.year} – '
      '${returnDate.day.toString().padLeft(2, '0')}.'
      '${returnDate.month.toString().padLeft(2, '0')}.'
      '${returnDate.year}',
    );
    return parts.join(' · ');
  }

  Map<String, dynamic> flightMap() => {
        'airline': airline,
        'departureTime': departureTime,
        'arrivalTime': arrivalTime,
        'returnDepartureTime': returnDepartureTime,
        'returnArrivalTime': returnArrivalTime,
      };

  Map<String, dynamic> hotelMap() => {
        'name': hotelName,
        'photoUrl': hotelPhotoUrl,
        'latitude': hotelLatitude,
        'longitude': hotelLongitude,
      };

  Map<String, dynamic> toJson() => {
        'reservationId': reservationId,
        'cityName': cityName,
        'country': country,
        'destinationIata': destinationIata,
        'nights': nights,
        'departureDate': departureDate.toIso8601String(),
        'returnDate': returnDate.toIso8601String(),
        'adults': adults,
        'children': children,
        'totalPriceTL': totalPriceTL,
        'passengerName': passengerName,
        'passengerEmail': passengerEmail,
        'passengerAges': passengerAges,
        'holidayTypes': holidayTypes,
        'bookingScope': bookingScope,
        'productCategory': productCategory,
        'productTitle': productTitle,
        'createdAt': createdAt.toIso8601String(),
        'originIata': originIata,
        'airline': airline,
        'departureTime': departureTime,
        'arrivalTime': arrivalTime,
        'returnDepartureTime': returnDepartureTime,
        'returnArrivalTime': returnArrivalTime,
        'hotelName': hotelName,
        'hotelPhotoUrl': hotelPhotoUrl,
        'hotelLatitude': hotelLatitude,
        'hotelLongitude': hotelLongitude,
        'flightPriceTL': flightPriceTL,
        'hotelPriceTL': hotelPriceTL,
        'flightNumber': flightNumber,
        'airlineCode': airlineCode,
        'terminal': terminal,
        'checkInCounters': checkInCounters,
        'gate': gate,
        'seat': seat,
        'boardingPriority': boardingPriority,
      };

  factory StoredBooking.fromJson(Map<String, dynamic> json) {
    return StoredBooking(
      reservationId: json['reservationId']?.toString() ?? '',
      cityName: json['cityName']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      destinationIata: json['destinationIata']?.toString() ?? '',
      nights: (json['nights'] as num?)?.toInt() ?? 1,
      departureDate: DateTime.tryParse(json['departureDate']?.toString() ?? '') ??
          DateTime.now(),
      returnDate: DateTime.tryParse(json['returnDate']?.toString() ?? '') ??
          DateTime.now(),
      adults: (json['adults'] as num?)?.toInt() ?? 1,
      children: (json['children'] as num?)?.toInt() ?? 0,
      totalPriceTL: (json['totalPriceTL'] as num?)?.toInt() ?? 0,
      passengerName: json['passengerName']?.toString() ?? '',
      passengerEmail: json['passengerEmail']?.toString() ?? '',
      passengerAges: (json['passengerAges'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      holidayTypes: (json['holidayTypes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      bookingScope: json['bookingScope']?.toString() ?? 'package',
      productCategory: json['productCategory']?.toString(),
      productTitle: json['productTitle']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      originIata: json['originIata']?.toString() ?? 'IST',
      airline: json['airline']?.toString(),
      departureTime: json['departureTime']?.toString(),
      arrivalTime: json['arrivalTime']?.toString(),
      returnDepartureTime: json['returnDepartureTime']?.toString(),
      returnArrivalTime: json['returnArrivalTime']?.toString(),
      hotelName: json['hotelName']?.toString(),
      hotelPhotoUrl: json['hotelPhotoUrl']?.toString(),
      hotelLatitude: (json['hotelLatitude'] as num?)?.toDouble(),
      hotelLongitude: (json['hotelLongitude'] as num?)?.toDouble(),
      flightPriceTL: (json['flightPriceTL'] as num?)?.toInt() ?? 0,
      hotelPriceTL: (json['hotelPriceTL'] as num?)?.toInt() ?? 0,
      flightNumber: json['flightNumber']?.toString(),
      airlineCode: json['airlineCode']?.toString(),
      terminal: json['terminal']?.toString(),
      checkInCounters: json['checkInCounters']?.toString(),
      gate: json['gate']?.toString(),
      seat: json['seat']?.toString(),
      boardingPriority: json['boardingPriority']?.toString(),
    );
  }

  factory StoredBooking.fromSupabaseRow(Map<String, dynamic> row) {
    final id = row['id'];
    final reservationId =
        id != null ? 'VG-$id' : row['reservationId']?.toString() ?? '';

    final rowScalars = _rowScalarsFromSupabase(row, reservationId);
    final detail = row['detail_json'] ?? row['detailJson'];

    if (detail is Map && detail.isNotEmpty) {
      final merged = _mergeBookingMaps(
        rowScalars,
        Map<String, dynamic>.from(detail),
      );
      merged['reservationId'] = reservationId;
      return StoredBooking.fromJson(merged);
    }

    return StoredBooking.fromJson(rowScalars);
  }

  static Map<String, dynamic> _rowScalarsFromSupabase(
    Map<String, dynamic> row,
    String reservationId,
  ) {
    String pick(String camel, String snake) =>
        row[camel]?.toString() ?? row[snake]?.toString() ?? '';

    int pickInt(String camel, String snake) =>
        (row[camel] as num?)?.toInt() ??
        (row[snake] as num?)?.toInt() ??
        0;

    final dep = pick('departureDate', 'departure_date');
    final ret = pick('returnDate', 'return_date');

    return {
      'reservationId': reservationId,
      'cityName': pick('cityName', 'city_name'),
      'country': row['country']?.toString() ?? '',
      'destinationIata': pick('destinationIata', 'destination_iata'),
      'nights': _nightsBetween(dep, ret),
      'departureDate': dep.isNotEmpty ? dep : DateTime.now().toIso8601String(),
      'returnDate': ret.isNotEmpty ? ret : DateTime.now().toIso8601String(),
      'adults': pickInt('adults', 'adults'),
      'children': pickInt('children', 'children'),
      'totalPriceTL': pickInt('totalPriceTL', 'total_price_tl'),
      'flightPriceTL': pickInt('flightPriceTL', 'flight_price_tl'),
      'hotelPriceTL': pickInt('hotelPriceTL', 'hotel_price_tl'),
      'passengerName': pick('passengerName', 'passenger_name'),
      'passengerEmail': pick('passengerEmail', 'passenger_email'),
      'bookingScope': pick('bookingScope', 'booking_scope').isNotEmpty
          ? pick('bookingScope', 'booking_scope')
          : 'package',
      'createdAt': row['created_at']?.toString() ??
          row['createdAt']?.toString() ??
          DateTime.now().toIso8601String(),
      'originIata': pick('originIata', 'origin_iata').isNotEmpty
          ? pick('originIata', 'origin_iata')
          : 'IST',
    };
  }

  static Map<String, dynamic> _mergeBookingMaps(
    Map<String, dynamic> rowScalars,
    Map<String, dynamic> detail,
  ) {
    final merged = Map<String, dynamic>.from(rowScalars);
    for (final entry in detail.entries) {
      if (_detailValueMeaningful(entry.key, entry.value)) {
        merged[entry.key] = entry.value;
      }
    }
    return merged;
  }

  static bool _detailValueMeaningful(String key, dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is num) {
      if (key == 'totalPriceTL' ||
          key == 'flightPriceTL' ||
          key == 'hotelPriceTL') {
        return value.toInt() > 0;
      }
      if (key == 'children') return true;
      if (key == 'adults') return value.toInt() > 0;
      if (key == 'nights') return value.toInt() > 0;
      return value.toInt() != 0;
    }
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  static int _nightsBetween(String? dep, String? ret) {
    final d = DateTime.tryParse(dep ?? '');
    final r = DateTime.tryParse(ret ?? '');
    if (d == null || r == null) return 1;
    return r.difference(d).inDays.clamp(1, 60);
  }
}
