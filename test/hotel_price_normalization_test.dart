import 'package:flutter_test/flutter_test.dart';
import 'package:tatil_arama/utils/price_format.dart';

void main() {
  group('hotel stay total pricing', () {
    test('totalPriceTL is used directly without multiplying nights', () {
      final hotel = {
        'totalPriceTL': 17500,
        'pricePerNightTL': 3500,
        'nights': 5,
        'priceScope': 'stay',
        'currency': 'EUR',
      };

      expect(PriceFormat.hotelTotalTL(hotel, 5), 17500);
      expect(PriceFormat.hotelPerNightTL(hotel, nights: 5), 3500);
    });

    test('totalPrice EUR is stay total, not per night', () {
      final hotel = {
        'totalPrice': 500,
        'pricePerNight': 100,
        'nights': 5,
        'priceScope': 'stay',
        'currency': 'EUR',
      };

      expect(PriceFormat.hotelTotalTL(hotel, 5), 500 * 35);
      expect(PriceFormat.hotelPerNightTL(hotel, nights: 5), 100 * 35);
    });

    test('legacy API treats lone pricePerNight as stay total for multi-night', () {
      final hotel = {
        'pricePerNight': 500,
        'currency': 'EUR',
        'nights': 5,
      };

      expect(PriceFormat.hotelTotalTL(hotel, 5), 500 * 35);
      expect(PriceFormat.hotelPerNightTL(hotel, nights: 5), 100 * 35);
    });
  });
}
