import '../constants.dart';

/// Checkout özet adımı — opsiyonel yan gelir tahmini fiyatları (TL).
abstract final class CheckoutAncillaryPricing {
  static const int airportTransferTL = 1_200;
  static const int extraBaggageTL = 1_500;
  static const int rentCarPerDayTL = 850;

  static int rentCarTotal(int nights) =>
      rentCarPerDayTL * nights.clamp(1, 30);

  static int ticketProtectionTotal(int travelers) =>
      AppConstants.ticketProtectionPerPersonTL * travelers.clamp(1, 9);

  static int flexTicketTotal() => AppConstants.flexTicketPerBookingTL;
}
