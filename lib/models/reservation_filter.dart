import 'search_category.dart';
import 'stored_booking_model.dart';

enum ReservationFilter {
  all,
  package,
  flight,
  hotel,
  bus,
  carRental,
  transfer,
  activities,
}

extension ReservationFilterMeta on ReservationFilter {
  String get label {
    switch (this) {
      case ReservationFilter.all:
        return 'Tümü';
      case ReservationFilter.package:
        return 'Paket';
      case ReservationFilter.flight:
        return 'Uçuş';
      case ReservationFilter.hotel:
        return 'Otel';
      case ReservationFilter.bus:
        return 'Otobüs';
      case ReservationFilter.carRental:
        return 'Araç';
      case ReservationFilter.transfer:
        return 'Transfer';
      case ReservationFilter.activities:
        return 'Aktivite';
    }
  }

  SearchCategory? get asSearchCategory {
    switch (this) {
      case ReservationFilter.bus:
        return SearchCategory.bus;
      case ReservationFilter.carRental:
        return SearchCategory.carRental;
      case ReservationFilter.transfer:
        return SearchCategory.transfer;
      case ReservationFilter.activities:
        return SearchCategory.activities;
      case ReservationFilter.flight:
        return SearchCategory.flight;
      case ReservationFilter.hotel:
        return SearchCategory.hotel;
      default:
        return null;
    }
  }
}

extension StoredBookingFilter on StoredBooking {
  bool matchesReservationFilter(ReservationFilter filter) {
    if (filter == ReservationFilter.all) return true;

    final pc = productCategory;
    if (pc != null && pc.isNotEmpty) {
      return pc == filter.name ||
          (filter == ReservationFilter.activities && pc == 'activities');
    }

    switch (filter) {
      case ReservationFilter.package:
        return bookingScope == 'package' || (hasFlight && hasHotel);
      case ReservationFilter.flight:
        return bookingScope == 'flightOnly' ||
            (hasFlight && !hasHotel && bookingScope != 'hotelOnly');
      case ReservationFilter.hotel:
        return bookingScope == 'hotelOnly' ||
            (hasHotel && !hasFlight && bookingScope != 'flightOnly');
      case ReservationFilter.bus:
      case ReservationFilter.carRental:
      case ReservationFilter.transfer:
      case ReservationFilter.activities:
        return false;
      case ReservationFilter.all:
        return true;
    }
  }
}
