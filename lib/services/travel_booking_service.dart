import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants.dart';
import '../models/route_result_model.dart';
import '../models/booking_scope.dart';
import '../models/search_category.dart';
import '../models/stored_booking_model.dart';
import 'auth_service.dart';
import 'local_booking_store.dart';
import 'loyalty_points_service.dart';
import 'trip_reminder_service.dart';

/// Tatil rezervasyonunu backend + Supabase + yerel depoya kaydeder.
class TravelBookingService {
  TravelBookingService._();

  static bool _supabaseTravelTableMissing = false;

  static final _cloudIdPattern = RegExp(
    r'^VG-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static String cloudReservationId(String uuid) => 'VG-$uuid';

  static bool isCloudReservationId(String id) => _cloudIdPattern.hasMatch(id);

  /// Giriş / uygulama açılışı — yerel rezervasyonları buluta taşır.
  static Future<int> syncLocalBookingsToCloud() async {
    if (_supabaseTravelTableMissing) return 0;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return 0;

    final local = await LocalBookingStore.list();
    var synced = 0;

    for (final booking in local) {
      if (isCloudReservationId(booking.reservationId)) continue;

      try {
        Map<String, dynamic>? existing;
        try {
          existing = await Supabase.instance.client
              .from('travel_bookings')
              .select('id')
              .eq('local_ref', booking.reservationId)
              .maybeSingle();
        } on PostgrestException catch (e) {
          if (!_isMissingDetailColumns(e)) rethrow;
          existing = null;
        }

        if (existing != null && existing['id'] != null) {
          final cloudId = cloudReservationId(existing['id'].toString());
          await LocalBookingStore.save(
            _bookingWithId(booking, cloudId),
          );
          synced++;
          continue;
        }

        final row = _supabaseRowFromStored(booking, userId);
        Map<String, dynamic>? result;
        try {
          result = await Supabase.instance.client
              .from('travel_bookings')
              .insert(row)
              .select('id')
              .maybeSingle();
        } on PostgrestException catch (e) {
          if (_isMissingDetailColumns(e)) {
            final slim = Map<String, dynamic>.from(row)
              ..remove('detail_json')
              ..remove('local_ref');
            result = await Supabase.instance.client
                .from('travel_bookings')
                .insert(slim)
                .select('id')
                .maybeSingle();
          } else {
            rethrow;
          }
        }

        if (result != null && result['id'] != null) {
          final cloudId = cloudReservationId(result['id'].toString());
          await LocalBookingStore.save(_bookingWithId(booking, cloudId));
          synced++;
        }
      } on PostgrestException catch (e) {
        if (_isMissingTravelTable(e)) {
          _supabaseTravelTableMissing = true;
          break;
        }
      } catch (_) {}
    }

    return synced;
  }

  static StoredBooking _bookingWithId(StoredBooking booking, String id) {
    return StoredBooking(
      reservationId: id,
      cityName: booking.cityName,
      country: booking.country,
      destinationIata: booking.destinationIata,
      nights: booking.nights,
      departureDate: booking.departureDate,
      returnDate: booking.returnDate,
      adults: booking.adults,
      children: booking.children,
      totalPriceTL: booking.totalPriceTL,
      passengerName: booking.passengerName,
      passengerEmail: booking.passengerEmail,
      passengerAges: booking.passengerAges,
      holidayTypes: booking.holidayTypes,
      bookingScope: booking.bookingScope,
      createdAt: booking.createdAt,
      originIata: booking.originIata,
      airline: booking.airline,
      departureTime: booking.departureTime,
      arrivalTime: booking.arrivalTime,
      returnDepartureTime: booking.returnDepartureTime,
      returnArrivalTime: booking.returnArrivalTime,
      hotelName: booking.hotelName,
      hotelPhotoUrl: booking.hotelPhotoUrl,
      hotelLatitude: booking.hotelLatitude,
      hotelLongitude: booking.hotelLongitude,
      flightPriceTL: booking.flightPriceTL,
      hotelPriceTL: booking.hotelPriceTL,
    );
  }

  static Future<Map<String, dynamic>?> _trySupabaseInsert({
    required Map<String, dynamic> payload,
    required List<Map<String, String>> passengers,
    required StoredBooking? detailSnapshot,
    String? localRef,
  }) async {
    if (_supabaseTravelTableMissing) return null;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final row = {
        ..._supabaseRow(payload, passengers, userId),
        if (localRef != null) 'local_ref': localRef,
        'detail_json': detailSnapshot?.toJson() ?? {},
      };

      try {
        return await _insertSupabaseRow(row);
      } on PostgrestException catch (e) {
        if (_isMissingDetailColumns(e)) {
          final slim = Map<String, dynamic>.from(row)
            ..remove('detail_json')
            ..remove('local_ref');
          return await _insertSupabaseRow(slim);
        }
        rethrow;
      }
    } on PostgrestException catch (e) {
      if (_isMissingTravelTable(e)) {
        _supabaseTravelTableMissing = true;
      }
    } catch (_) {}
    return null;
  }

  static bool _isMissingTravelTable(PostgrestException e) {
    final msg = e.message.toLowerCase();
    return e.code == 'PGRST205' ||
        msg.contains('travel_bookings') ||
        msg.contains('schema cache');
  }

  static bool _isMissingDetailColumns(PostgrestException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('detail_json') ||
        msg.contains('local_ref') ||
        msg.contains('column') && msg.contains('does not exist');
  }

  static Future<Map<String, dynamic>?> _insertSupabaseRow(
    Map<String, dynamic> row,
  ) async {
    final result = await Supabase.instance.client
        .from('travel_bookings')
        .insert(row)
        .select('id')
        .maybeSingle();

    if (result != null && result['id'] != null) {
      return {
        'success': true,
        'reservationId': cloudReservationId(result['id'].toString()),
        'source': 'supabase',
      };
    }
    return null;
  }

  static Map<String, dynamic> _supabaseRow(
    Map<String, dynamic> payload,
    List<Map<String, String>> passengers,
    String userId,
  ) {
    return {
      'user_id': userId,
      'origin_iata': payload['originIata'],
      'destination_iata': payload['destinationIata'],
      'city_name': payload['cityName'],
      'country': payload['country'],
      'departure_date': payload['departureDate'],
      'return_date': payload['returnDate'],
      'adults': payload['adults'],
      'children': payload['children'],
      'total_price_tl': payload['totalPriceTL'],
      'flight_price_tl': payload['flightPriceTL'],
      'hotel_price_tl': payload['hotelPriceTL'],
      'transfer_price_tl': payload['transferPriceTL'],
      'extras_price_tl': payload['extrasPriceTL'],
      'insurance_included': payload['insuranceIncluded'],
      'booking_scope': payload['bookingScope'],
      'passenger_name': payload['passengerName'],
      'passenger_email': payload['passengerEmail'],
      'payment_method': payload['paymentMethod'],
      'passengers': passengers,
      'flight_offer_id': payload['flightOfferId']?.toString(),
      'hotel_id': payload['hotelId']?.toString(),
      'flight_source': payload['flightSource'],
      'hotel_source': payload['hotelSource'],
      'status': 'confirmed',
    };
  }

  static Map<String, dynamic> _supabaseRowFromStored(
    StoredBooking booking,
    String userId,
  ) {
    return {
      'user_id': userId,
      'local_ref': booking.reservationId,
      'origin_iata': booking.originIata,
      'destination_iata': booking.destinationIata,
      'city_name': booking.cityName,
      'country': booking.country,
      'departure_date': booking.departureDate.toIso8601String().split('T').first,
      'return_date': booking.returnDate.toIso8601String().split('T').first,
      'adults': booking.adults,
      'children': booking.children,
      'total_price_tl': booking.totalPriceTL,
      'flight_price_tl': booking.flightPriceTL,
      'hotel_price_tl': booking.hotelPriceTL,
      'insurance_included': false,
      'booking_scope': booking.bookingScope,
      'passenger_name': booking.passengerName,
      'passenger_email': booking.passengerEmail,
      'passengers': <Map<String, String>>[],
      'status': 'confirmed',
      'detail_json': booking.toJson(),
      'created_at': booking.createdAt.toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> saveBooking({
    required String originIata,
    required RouteResultModel route,
    required Map<String, dynamic> selectedFlight,
    required Map<String, dynamic> selectedHotel,
    required DateTime departureDate,
    required DateTime returnDate,
    required int adults,
    required int children,
    required int totalPriceTL,
    required int flightPriceTL,
    required int hotelPriceTL,
    required int transferPriceTL,
    required int extrasPriceTL,
    required String passengerName,
    required String passengerEmail,
    required String paymentMethod,
    required List<Map<String, String>> passengers,
    bool insuranceIncluded = false,
    BookingScope bookingScope = BookingScope.package,
    List<int> passengerAges = const [],
    List<String> holidayTypes = const [],
  }) async {
    final payload = {
      'originIata': originIata,
      'destinationIata': route.destinationIata,
      'cityName': route.cityName,
      'country': route.country,
      'departureDate': departureDate.toIso8601String().split('T').first,
      'returnDate': returnDate.toIso8601String().split('T').first,
      'adults': adults,
      'children': children,
      'totalPriceTL': totalPriceTL,
      'flightPriceTL': flightPriceTL,
      'hotelPriceTL': hotelPriceTL,
      'transferPriceTL': transferPriceTL,
      'extrasPriceTL': extrasPriceTL,
      'insuranceIncluded': insuranceIncluded,
      'bookingScope': bookingScope.name,
      'passengerName': passengerName,
      'passengerEmail': passengerEmail,
      'paymentMethod': paymentMethod,
      'passengers': passengers,
      'flightOfferId': selectedFlight['id'],
      'hotelId': selectedHotel['id'],
      'flightSource': selectedFlight['source'] ?? 'live',
      'hotelSource': selectedHotel['source'] ?? 'live',
    };

    final localFallbackId = _newLocalReservationId();
    final detailDraft = StoredBooking(
      reservationId: localFallbackId,
      cityName: route.cityName,
      country: route.country,
      destinationIata: route.destinationIata,
      nights: route.nights,
      departureDate: departureDate,
      returnDate: returnDate,
      adults: adults,
      children: children,
      totalPriceTL: totalPriceTL,
      passengerName: passengerName,
      passengerEmail: passengerEmail,
      passengerAges: passengerAges,
      holidayTypes: holidayTypes,
      bookingScope: bookingScope.name,
      createdAt: DateTime.now(),
      originIata: originIata,
      airline: selectedFlight['airline']?.toString(),
      departureTime: selectedFlight['departureTime']?.toString(),
      arrivalTime: selectedFlight['arrivalTime']?.toString(),
      returnDepartureTime: selectedFlight['returnDepartureTime']?.toString(),
      returnArrivalTime: selectedFlight['returnArrivalTime']?.toString(),
      airlineCode: selectedFlight['airlineCode']?.toString(),
      flightNumber: selectedFlight['flightNumber']?.toString(),
      hotelName: selectedHotel['name']?.toString(),
      hotelPhotoUrl: selectedHotel['photoUrl']?.toString(),
      hotelLatitude: (selectedHotel['latitude'] as num?)?.toDouble(),
      hotelLongitude: (selectedHotel['longitude'] as num?)?.toDouble(),
      flightPriceTL: flightPriceTL,
      hotelPriceTL: hotelPriceTL,
    );

    Map<String, dynamic>? saved;

    // 1) Giriş yapmış kullanıcı → önce Supabase (kalıcı bulut)
    if (AuthService.isLoggedIn) {
      saved = await _trySupabaseInsert(
        payload: payload,
        passengers: passengers,
        detailSnapshot: detailDraft,
        localRef: localFallbackId,
      );
    }

    // 2) Backend API (varsa)
    if (saved == null) {
      for (final path in const [
        '/travel/booking',
        '/bookings/travel',
        '/reservations',
      ]) {
        try {
          final response = await http
              .post(
                Uri.parse('${AppConstants.baseUrl}$path'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(payload),
              )
              .timeout(AppConstants.receiveTimeout);

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            if (data['success'] == true) {
              final id = data['data']?['reservationId'] ??
                  data['data']?['id'] ??
                  data['reservationId'];
              if (id != null) {
                saved = {
                  'success': true,
                  'reservationId': id.toString(),
                  'source': 'api',
                };
                break;
              }
            }
          }
        } catch (_) {}
      }
    }

    saved ??= {
      'success': true,
      'reservationId': localFallbackId,
      'source': 'local',
    };

    final finalId = saved['reservationId'] as String;
    final booking = _bookingWithId(detailDraft, finalId);

    await LocalBookingStore.save(booking);
    await _postBookingHooks(booking);

    return saved;
  }

  static Future<void> _postBookingHooks(StoredBooking booking) async {
    await LoyaltyPointsService.earnFromBooking(
      totalPriceTL: booking.totalPriceTL,
      reservationId: booking.reservationId,
      cityName: booking.cityName,
    );
    if (booking.hasFlight) {
      await TripReminderService.scheduleForBooking(
        reservationId: booking.reservationId,
        cityName: booking.cityName,
        departureDate: booking.departureDate,
      );
    }
  }

  static String _newLocalReservationId() {
    final stamp = DateTime.now();
    return 'VG-${stamp.year}${stamp.month.toString().padLeft(2, '0')}${stamp.day.toString().padLeft(2, '0')}-${stamp.millisecondsSinceEpoch % 1000000}';
  }

  static Future<List<StoredBooking>> fetchBookings() async {
    final local = await LocalBookingStore.list();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return local;

    try {
      final rows = await Supabase.instance.client
          .from('travel_bookings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final remote = (rows as List)
          .whereType<Map>()
          .map((r) => StoredBooking.fromSupabaseRow(
                _normalizeSupabaseRow(Map<String, dynamic>.from(r)),
              ))
          .toList();

      final byId = <String, StoredBooking>{};
      for (final b in local) {
        byId[b.reservationId] = b;
      }
      for (final b in remote) {
        final existing = byId[b.reservationId];
        byId[b.reservationId] = existing != null
            ? StoredBooking.preferRicher(existing, b)
            : b;
      }

      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      await LocalBookingStore.replaceAll(merged);
      unawaited(_backfillCloudDetails(merged));
      return merged;
    } on PostgrestException catch (e) {
      if (_isMissingTravelTable(e)) _supabaseTravelTableMissing = true;
      return local;
    } catch (_) {
      return local;
    }
  }

  static Map<String, dynamic> _normalizeSupabaseRow(Map<String, dynamic> row) {
    String? pick(String camel, String snake) =>
        row[camel]?.toString() ?? row[snake]?.toString();

    int pickInt(String camel, String snake) =>
        (row[camel] as num?)?.toInt() ??
        (row[snake] as num?)?.toInt() ??
        0;

    return {
      ...row,
      'id': row['id'],
      'detail_json': row['detail_json'] ?? row['detailJson'],
      'cityName': pick('cityName', 'city_name'),
      'country': row['country'],
      'destinationIata': pick('destinationIata', 'destination_iata'),
      'originIata': pick('originIata', 'origin_iata'),
      'departureDate': pick('departureDate', 'departure_date'),
      'returnDate': pick('returnDate', 'return_date'),
      'totalPriceTL': pickInt('totalPriceTL', 'total_price_tl'),
      'flightPriceTL': pickInt('flightPriceTL', 'flight_price_tl'),
      'hotelPriceTL': pickInt('hotelPriceTL', 'hotel_price_tl'),
      'passengerName': pick('passengerName', 'passenger_name'),
      'passengerEmail': pick('passengerEmail', 'passenger_email'),
      'bookingScope': pick('bookingScope', 'booking_scope'),
    };
  }

  /// Yereldeki tam snapshot'ı bulutta eksik kalan satırlara yazar.
  static Future<void> _backfillCloudDetails(List<StoredBooking> bookings) async {
    if (_supabaseTravelTableMissing) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    for (final booking in bookings) {
      if (!isCloudReservationId(booking.reservationId) ||
          !booking.isDisplayReady) {
        continue;
      }
      final uuid = booking.reservationId.replaceFirst('VG-', '');
      try {
        await Supabase.instance.client.from('travel_bookings').update({
          'detail_json': booking.toJson(),
          'city_name': booking.cityName,
          'country': booking.country,
          'destination_iata': booking.destinationIata,
          'total_price_tl': booking.totalPriceTL,
          'flight_price_tl': booking.flightPriceTL,
          'hotel_price_tl': booking.hotelPriceTL,
          'passenger_name': booking.passengerName,
          'passenger_email': booking.passengerEmail,
        }).eq('id', uuid).eq('user_id', userId);
      } on PostgrestException catch (e) {
        if (_isMissingDetailColumns(e)) {
          try {
            await Supabase.instance.client.from('travel_bookings').update({
              'city_name': booking.cityName,
              'country': booking.country,
              'destination_iata': booking.destinationIata,
              'total_price_tl': booking.totalPriceTL,
              'flight_price_tl': booking.flightPriceTL,
              'hotel_price_tl': booking.hotelPriceTL,
              'passenger_name': booking.passengerName,
              'passenger_email': booking.passengerEmail,
            }).eq('id', uuid).eq('user_id', userId);
          } catch (_) {}
        }
      } catch (_) {}
    }
  }

  /// Tek ürün kategori rezervasyonu (otobüs, araç, transfer).
  static Future<StoredBooking> saveCategoryBooking({
    required SearchCategory category,
    required String reservationId,
    required String title,
    required String destinationCity,
    required int totalPriceTL,
    required String passengerName,
    required String passengerEmail,
    String destinationIata = '',
    DateTime? departureDate,
    DateTime? returnDate,
    int passengers = 1,
  }) async {
    final dep = departureDate ?? DateTime.now();
    final ret = returnDate ?? dep.add(const Duration(days: 1));
    final nights = ret.difference(dep).inDays.clamp(1, 30);

    final booking = StoredBooking(
      reservationId: reservationId,
      cityName: destinationCity,
      country: '',
      destinationIata: destinationIata.isNotEmpty
          ? destinationIata
          : (destinationCity.length >= 3
              ? destinationCity.substring(0, 3).toUpperCase()
              : 'TR'),
      nights: nights,
      departureDate: dep,
      returnDate: ret,
      adults: passengers,
      children: 0,
      totalPriceTL: totalPriceTL,
      passengerName: passengerName,
      passengerEmail: passengerEmail,
      bookingScope: 'categoryOnly',
      productCategory: category.name,
      productTitle: title,
      createdAt: DateTime.now(),
    );

    await LocalBookingStore.save(booking);
    await _postBookingHooks(booking);
    if (AuthService.isLoggedIn) {
      unawaited(syncLocalBookingsToCloud());
    }
    return booking;
  }
}
