import 'package:share_plus/share_plus.dart';

import '../models/stored_booking_model.dart';
import '../utils/price_format.dart';

/// Rota ve seyahat kartı paylaşımı — WhatsApp, iMessage vb.
abstract final class TripShareService {
  static const _appLink = 'https://vizegoo.app';

  static Future<void> shareRoute({
    required String cityName,
    required String country,
    required int nights,
    required int totalPriceTL,
    required String originCity,
    String? hotelName,
  }) async {
    final hotelLine =
        hotelName != null && hotelName.isNotEmpty ? '\n🏨 $hotelName' : '';
    final text = '''
🌴 Vizegoo ile $cityName tatili

📍 $cityName, $country
✈️ $originCity · $nights gece
💰 ${PriceFormat.format(totalPriceTL)}$hotelLine

Planı incele: $_appLink
''';
    await Share.share(text.trim(), subject: '$cityName tatil planı');
  }

  static Future<void> shareBooking(StoredBooking booking) async {
    final flightLine = booking.hasFlight && booking.airline != null
        ? '\n✈️ ${booking.airline}'
        : '';
    final hotelLine = booking.hasHotel && booking.hotelName != null
        ? '\n🏨 ${booking.hotelName}'
        : '';
    final text = '''
🎫 Seyahat kartım — Vizegoo

📍 ${booking.cityName}, ${booking.country}
📅 ${_fmt(booking.departureDate)} – ${_fmt(booking.returnDate)}
🆔 ${booking.reservationId}$flightLine$hotelLine

Vizegoo ile planla: $_appLink
''';
    await Share.share(text.trim(), subject: '${booking.cityName} seyahatim');
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
