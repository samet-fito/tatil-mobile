import '../utils/checkout_ancillary_pricing.dart';

/// Araç kiralama kataloğu — günlük fiyatlar CheckoutAncillaryPricing ile uyumlu.
abstract final class CarRentalCatalog {
  static const _vehicleTypes = [
    {
      'id': 'economy',
      'name': 'Ekonomi',
      'model': 'Fiat Egea veya benzeri',
      'seats': 5,
      'bags': 2,
      'transmission': 'Manuel',
      'multiplier': 1.0,
    },
    {
      'id': 'compact',
      'name': 'Kompakt',
      'model': 'Renault Clio veya benzeri',
      'seats': 5,
      'bags': 2,
      'transmission': 'Otomatik',
      'multiplier': 1.15,
    },
    {
      'id': 'suv',
      'name': 'SUV',
      'model': 'Dacia Duster veya benzeri',
      'seats': 5,
      'bags': 4,
      'transmission': 'Otomatik',
      'multiplier': 1.45,
    },
    {
      'id': 'van',
      'name': 'Minivan',
      'model': 'Ford Tourneo veya benzeri',
      'seats': 7,
      'bags': 5,
      'transmission': 'Manuel',
      'multiplier': 1.65,
    },
  ];

  static const _providers = ['Avis', 'Europcar', 'Garenta', 'Sixt'];

  static List<Map<String, dynamic>> search({
    required String city,
    required DateTime pickup,
    required DateTime dropoff,
  }) {
    final days = dropoff.difference(pickup).inDays.clamp(1, 30);
    final seed = city.hashCode ^ pickup.day;

    return List.generate(_vehicleTypes.length, (i) {
      final type = _vehicleTypes[i];
      final multiplier = type['multiplier'] as double;
      final daily = (CheckoutAncillaryPricing.rentCarPerDayTL * multiplier).round();
      final total = daily * days;
      return {
        'id': 'car-${type['id']}-$city',
        'provider': _providers[i % _providers.length],
        'city': city,
        'vehicleType': type['name'],
        'model': type['model'],
        'seats': type['seats'],
        'bags': type['bags'],
        'transmission': type['transmission'],
        'pickup': pickup,
        'dropoff': dropoff,
        'days': days,
        'dailyPriceTL': daily,
        'totalPriceTL': total + (seed.abs() % 3) * 50,
        'fuelPolicy': 'Dolu al — dolu bırak',
        'mileage': 'Sınırsız km',
      };
    });
  }
}
