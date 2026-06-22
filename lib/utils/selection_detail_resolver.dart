import 'dart:math' as math;

import '../data/destination_geo.dart';
import '../utils/checkout_ancillary_pricing.dart';
import '../utils/flight_schedule_format.dart';
import '../utils/flight_duration_format.dart';
import '../utils/hotel_location_hints.dart';
import '../utils/price_format.dart';

/// Detay paneli satırı — bilgi amaçlı, satış yok.
class SelectionDetailLine {
  const SelectionDetailLine({
    required this.icon,
    required this.label,
    required this.value,
    this.actionLabel,
    this.actionUrl,
  });

  final String icon;
  final String label;
  final String value;
  final String? actionLabel;
  final String? actionUrl;
}

class SelectionDetailResolver {
  SelectionDetailResolver._();

  static const _months = [
    '',
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  static double haversineKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * math.pi / 180;

  static String _formatFlightDateTime(dynamic raw, DateTime fallbackDate) =>
      FlightScheduleFormat.dateTimeLabel(raw, fallbackDate);

  static String _airportLabel(DestinationGeo? geo, String iata) {
    if (geo == null) return iata;
    final name = geo.airportName.trim();
    if (name.toUpperCase().contains('($iata)')) return name;
    return '$name · $iata';
  }

  static String _formatDuration(dynamic raw) => FlightDurationFormat.label(raw);

  static String _formatDurationMinutes(int minutes) {
    if (minutes < 60) return '~$minutes dk';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '~$h sa';
    return '~$h sa $m dk';
  }

  static int _driveMinutes(double km) => (km / 45 * 60).clamp(12, 120).round();

  static List<SelectionDetailLine> flightDetails({
    required Map<String, dynamic> flight,
    required String originIata,
    required String destinationIata,
    required String destinationCity,
    required Map<String, dynamic>? hotel,
    required DateTime departureDate,
    required DateTime returnDate,
  }) {
    final destGeo = DestinationGeo.forIata(destinationIata);
    final originGeo = DestinationGeo.forIata(originIata);

    final dep = _formatFlightDateTime(flight['departureTime'], departureDate);
    final arr = _formatFlightDateTime(flight['arrivalTime'], departureDate);
    final retDep = _formatFlightDateTime(
      flight['returnDepartureTime'],
      returnDate,
    );
    final retArr = _formatFlightDateTime(
      flight['returnArrivalTime'],
      returnDate,
    );
    final stops = flight['stops'] ?? 0;
    final returnStops = flight['returnStops'];
    final duration = _formatDuration(flight['duration']);
    final returnDuration = _formatDuration(flight['returnDuration']);

    final originLabel = _airportLabel(originGeo, originIata);
    final destLabel = _airportLabel(destGeo, destinationIata);
    final returnOriginIata =
        flight['returnOriginIata']?.toString() ?? destinationIata;
    final returnDestIata =
        flight['returnDestinationIata']?.toString() ?? originIata;
    final returnOriginGeo = DestinationGeo.forIata(returnOriginIata);
    final returnDestGeo = DestinationGeo.forIata(returnDestIata);
    final returnOriginLabel = _airportLabel(returnOriginGeo, returnOriginIata);
    final returnDestLabel = _airportLabel(returnDestGeo, returnDestIata);

    final lines = <SelectionDetailLine>[
      SelectionDetailLine(
        icon: '🛫',
        label: 'Gidiş kalkış',
        value: '$dep · $originLabel',
      ),
      SelectionDetailLine(
        icon: '🛬',
        label: 'Gidiş varış',
        value: '$arr · $destLabel',
      ),
      SelectionDetailLine(
        icon: '✈️',
        label: 'Gidiş uçuşu',
        value: stops == 0
            ? 'Direkt · $duration'
            : '$stops aktarma · $duration',
      ),
      SelectionDetailLine(
        icon: '🛫',
        label: 'Dönüş kalkış',
        value: '$retDep · $returnOriginLabel',
      ),
      SelectionDetailLine(
        icon: '🛬',
        label: 'Dönüş varış',
        value: '$retArr · $returnDestLabel',
      ),
      if (FlightScheduleFormat.hasReturnTimes(flight))
        SelectionDetailLine(
          icon: '↩️',
          label: 'Dönüş uçuşu',
          value: returnStops == 0
              ? 'Direkt · $returnDuration'
              : '${returnStops ?? 0} aktarma · $returnDuration',
        ),
      SelectionDetailLine(
        icon: '📅',
        label: 'Tarihler',
        value:
            '${departureDate.day} ${_months[departureDate.month]} – '
            '${returnDate.day} ${_months[returnDate.month]} ${returnDate.year} · gidiş-dönüş',
      ),
    ];

    lines.addAll(
      airportToHotelTransport(
        destinationIata: destinationIata,
        hotel: hotel,
      ),
    );

    return lines;
  }

  static List<SelectionDetailLine> hotelDetails({
    required Map<String, dynamic> hotel,
    required String cityName,
    required String destinationIata,
  }) {
    final geo = DestinationGeo.forIata(destinationIata);
    final lat = (hotel['latitude'] as num?)?.toDouble();
    final lng = (hotel['longitude'] as num?)?.toDouble();
    final hint = HotelLocationHints.forHotel(hotel, cityName);

    final address = _hotelAddress(hotel, cityName, geo, lat, lng);
    final mapsQuery = lat != null && lng != null
        ? '$lat,$lng'
        : Uri.encodeComponent('$address, $cityName');

    final lines = <SelectionDetailLine>[
      SelectionDetailLine(
        icon: '📍',
        label: 'Adres',
        value: address,
        actionLabel: lat != null && lng != null ? 'Haritada aç' : null,
        actionUrl: 'https://www.google.com/maps/search/?api=1&query=$mapsQuery',
      ),
    ];

    if (geo != null && lat != null && lng != null) {
      final toCenter = haversineKm(
        lat1: lat,
        lng1: lng,
        lat2: geo.cityCenter.lat,
        lng2: geo.cityCenter.lng,
      );
      lines.add(
        SelectionDetailLine(
          icon: '🏛️',
          label: geo.cityCenterLabel,
          value:
              '${toCenter.toStringAsFixed(1)} km · ${_formatDurationMinutes(_driveMinutes(toCenter))} (tahmini)',
        ),
      );

      final toAirport = haversineKm(
        lat1: lat,
        lng1: lng,
        lat2: geo.airport.lat,
        lng2: geo.airport.lng,
      );
      lines.add(
        SelectionDetailLine(
          icon: '🛫',
          label: geo.airportName.replaceAll(RegExp(r'\s*\([A-Z]{3}\)$'), ''),
          value:
              '${toAirport.toStringAsFixed(1)} km · ${_formatDurationMinutes(_driveMinutes(toAirport))} (tahmini)',
        ),
      );
    } else if (hint != null) {
      lines.add(
        SelectionDetailLine(
          icon: '🏛️',
          label: 'Konum',
          value: hint,
        ),
      );
    }

    return lines;
  }

  static List<SelectionDetailLine> airportToHotelTransport({
    required String destinationIata,
    required Map<String, dynamic>? hotel,
  }) {
    final geo = DestinationGeo.forIata(destinationIata);
    if (geo == null) return const [];

    double? distanceKm;
    if (hotel != null) {
      final lat = (hotel['latitude'] as num?)?.toDouble();
      final lng = (hotel['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        distanceKm = haversineKm(
          lat1: geo.airport.lat,
          lng1: geo.airport.lng,
          lat2: lat,
          lng2: lng,
        );
      }
    }
    distanceKm ??= haversineKm(
      lat1: geo.airport.lat,
      lng1: geo.airport.lng,
      lat2: geo.cityCenter.lat,
      lng2: geo.cityCenter.lng,
    );

    final driveMin = _driveMinutes(distanceKm);
    final taxiPerKm = _taxiPerKm(destinationIata);
    final taxiEstimate = (120 + distanceKm * taxiPerKm).round();
    final transferEstimate = CheckoutAncillaryPricing.airportTransferTL;

    final lines = <SelectionDetailLine>[
      SelectionDetailLine(
        icon: '📏',
        label: 'Havalimanı → otel mesafe',
        value:
            '${distanceKm.toStringAsFixed(1)} km · ${_formatDurationMinutes(driveMin)} (tahmini)',
      ),
      SelectionDetailLine(
        icon: '🚕',
        label: 'Taksi / ride-hail',
        value:
            'Ortalama ${PriceFormat.format(taxiEstimate)} · ${_formatDurationMinutes(driveMin)}',
      ),
    ];

    if (geo.metroLine != null) {
      final metro = _metroEstimate(destinationIata, distanceKm);
      lines.add(
        SelectionDetailLine(
          icon: '🚇',
          label: geo.metroLine!,
          value:
              'Ortalama ${PriceFormat.format(metro)} · ${_formatDurationMinutes(driveMin + 15)}',
        ),
      );
    }

    lines.add(
      SelectionDetailLine(
        icon: '🚐',
        label: 'Özel transfer (referans)',
        value:
            'Ortalama ${PriceFormat.format(transferEstimate)} · kapıdan kapıya · checkout\'ta eklenebilir',
      ),
    );

    return lines;
  }

  static String _hotelAddress(
    Map<String, dynamic> hotel,
    String cityName,
    DestinationGeo? geo,
    double? lat,
    double? lng,
  ) {
    final direct = hotel['address']?.toString().trim();
    if (direct != null && direct.isNotEmpty && direct.length > 12) {
      return direct;
    }

    final name = hotel['name']?.toString().trim() ?? 'Otel';
    if (lat != null && lng != null) {
      final district = _districtFromHotelName(name);
      final country = _countryFromGeo(geo);
      final parts = <String>[
        if (district.isNotEmpty) district,
        cityName,
        if (country.isNotEmpty) country,
      ];
      return '${parts.join(', ')} · tam konum haritada';
    }

    return '$name, $cityName';
  }

  static String _districtFromHotelName(String name) {
    final lower = name.toLowerCase();
    const patterns = {
      'al barsha': 'Al Barsha',
      'marina': 'Dubai Marina',
      'jumeirah': 'Jumeirah',
      'kaleiçi': 'Kaleiçi',
      'taksim': 'Taksim',
      'sultanahmet': 'Sultanahmet',
      'barcelona': 'Eixample',
      'monti': 'Monti',
      'trastevere': 'Trastevere',
    };
    for (final entry in patterns.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return '';
  }

  static String _countryFromGeo(DestinationGeo? geo) {
    if (geo == null) return '';
    final addr = geo.airportAddress;
    if (addr.contains('BAE')) return 'BAE';
    if (addr.contains('İtalya')) return 'İtalya';
    if (addr.contains('İspanya')) return 'İspanya';
    if (addr.contains('Fransa')) return 'Fransa';
    if (addr.contains('Yunanistan')) return 'Yunanistan';
    if (addr.contains('İstanbul') || addr.contains('Antalya')) return 'Türkiye';
    return '';
  }

  static double _taxiPerKm(String iata) {
    switch (iata.toUpperCase()) {
      case 'DXB':
        return 8;
      case 'IST':
      case 'AYT':
        return 14;
      case 'FCO':
      case 'ATH':
      case 'BCN':
      case 'CDG':
        return 18;
      default:
        return 16;
    }
  }

  static int _metroEstimate(String iata, double km) {
    switch (iata.toUpperCase()) {
      case 'FCO':
        return 280;
      case 'ATH':
        return 220;
      case 'DXB':
        return 180;
      case 'BCN':
        return 240;
      case 'CDG':
        return 320;
      case 'IST':
        return 160;
      default:
        return (80 + km * 6).round();
    }
  }
}
