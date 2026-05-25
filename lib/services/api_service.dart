import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/search_model.dart';

class ApiService {
  // ============================================================
  // BAĞLANTI KONTROLÜ
  // ============================================================
  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse(AppConstants.healthEndpoint))
          .timeout(AppConstants.connectTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // PAKET ARAMA
  // ============================================================
  static Future<Map<String, dynamic>> searchPackages(SearchModel model) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.searchEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(model.toJson()),
          )
          .timeout(AppConstants.receiveTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'error': {'message': 'Sunucu hatası: ${response.statusCode}'},
      };
    } catch (e) {
      return _handleError(e, _getMockSearchData(model));
    }
  }

  // ============================================================
  // AKTİVİTELER
  // ============================================================
  static Future<Map<String, dynamic>> getActivities({
    required String iata,
    required String city,
    required String departure,
    required String returnDate,
  }) async {
    try {
      final uri = Uri.parse(AppConstants.activitiesEndpoint).replace(
        queryParameters: {
          'iata': iata,
          'city': city,
          'departure': departure,
          'return': returnDate,
        },
      );
      final response =
          await http.get(uri).timeout(AppConstants.receiveTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false};
    } catch (e) {
      return _handleError(e, {'success': false});
    }
  }

  // ============================================================
  // VİZE BİLGİSİ
  // ============================================================
  static Future<Map<String, dynamic>> getVisaInfo(String countryCode) async {
    try {
      final uri = Uri.parse(AppConstants.visaEndpoint)
          .replace(queryParameters: {'countryCode': countryCode});
      final response =
          await http.get(uri).timeout(AppConstants.connectTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false};
    } catch (e) {
      return _handleError(e, {'success': false});
    }
  }

  // ============================================================
  // AI CHAT
  // ============================================================
  static Future<Map<String, dynamic>> sendChat({
    required String sessionId,
    required String cityName,
    required String destinationIata,
    required String message,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.chatEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'sessionId': sessionId,
              'cityName': cityName,
              'destinationIata': destinationIata,
              'message': message,
            }),
          )
          .timeout(AppConstants.connectTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false};
    } catch (e) {
      return _handleError(e, {'success': false});
    }
  }

  // ============================================================
  // HATA YÖNETİMİ
  // ============================================================
  static Map<String, dynamic> _handleError(
    dynamic error,
    Map<String, dynamic> fallback,
  ) {
    final message = error.toString();

    // Bağlantı hatası → mock data ile devam et
    if (message.contains('SocketException') ||
        message.contains('TimeoutException') ||
        message.contains('Connection refused') ||
        message.contains('NetworkException')) {
      return fallback;
    }

    return {
      'success': false,
      'error': {'message': 'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.'},
    };
  }

  // ============================================================
  // MOCK DATA (Backend kapalıyken)
  // ============================================================
  static Map<String, dynamic> _getMockSearchData(SearchModel model) {
    return {
      'success': true,
      'data': {
        'packages': [
          _mockPackage(
            id: 'dest-001',
            city: 'Antalya',
            iata: 'AYT',
            country: 'Turkey',
            score: 81,
            highlights: ['Akdeniz', 'Plajlar', 'Antik Kentler'],
            airline: 'THY',
            duration: '1s 10dk',
            hotelName: 'Akra Hotels',
            rating: 8.6,
            budget: model.totalBudgetTL,
            nights: model.nights,
            flightRatio: 0.08,
            hotelRatio: 0.25,
          ),
          _mockPackage(
            id: 'dest-002',
            city: 'Atina',
            iata: 'ATH',
            country: 'Greece',
            score: 78,
            highlights: ['Akropolis', 'Antika', 'Deniz'],
            airline: 'Aegean',
            duration: '1s 55dk',
            hotelName: 'Hotel Grande Bretagne',
            rating: 9.1,
            budget: model.totalBudgetTL,
            nights: model.nights,
            flightRatio: 0.18,
            hotelRatio: 0.42,
          ),
          _mockPackage(
            id: 'dest-003',
            city: 'Roma',
            iata: 'FCO',
            country: 'Italy',
            score: 74,
            highlights: ['Colosseum', 'Vatikan', 'İtalyan Mutfağı'],
            airline: 'THY',
            duration: '2s 50dk',
            hotelName: 'Hassler Roma',
            rating: 9.3,
            budget: model.totalBudgetTL,
            nights: model.nights,
            flightRatio: 0.22,
            hotelRatio: 0.45,
          ),
          _mockPackage(
            id: 'dest-004',
            city: 'Budapeşte',
            iata: 'BUD',
            country: 'Hungary',
            score: 76,
            highlights: ['Termal Banyolar', 'Ruin Barlar', 'Tuna Nehri'],
            airline: 'Wizz Air',
            duration: '2s 20dk',
            hotelName: 'Pulitzer Budapest',
            rating: 8.9,
            budget: model.totalBudgetTL,
            nights: model.nights,
            flightRatio: 0.15,
            hotelRatio: 0.38,
          ),
        ],
        'meta': {
          'dataSource': 'mock',
          'processingTimeMs': 120,
          'cacheHit': false,
        },
      },
    };
  }

  static Map<String, dynamic> _mockPackage({
    required String id,
    required String city,
    required String iata,
    required String country,
    required int score,
    required List<String> highlights,
    required String airline,
    required String duration,
    required String hotelName,
    required double rating,
    required double budget,
    required int nights,
    required double flightRatio,
    required double hotelRatio,
  }) {
    final flight = (budget * flightRatio).toInt();
    final hotel = (budget * hotelRatio).toInt();
    final living = (budget * 0.25).toInt();
    final total = flight + hotel + living;
    final remaining = (budget - total).toInt();
    final seg = budget < 25000 ? 'economic' : budget < 60000 ? 'standard' : 'premium';
    final segLabel = budget < 25000 ? 'Ekonomik' : budget < 60000 ? 'Standart' : 'Premium';

    return {
      'destinationId': id,
      'cityName': city,
      'iataCode': iata,
      'country': country,
      'countryCode': '',
      'score': score,
      'isAffordable': remaining > 0,
      'nights': nights,
      'highlights': highlights,
      'flightInfo': {
        'airline': airline,
        'duration': duration,
        'stops': 0,
        'departureTime': '09:00',
        'arrivalTime': '11:30',
      },
      'hotelInfo': {
        'name': hotelName,
        'stars': 5,
        'rating': rating,
        'reviewCount': 1500,
        'amenities': ['WiFi', 'Havuz', 'Spa'],
      },
      'estimatedCost': {
        'total': total,
        'flight': flight,
        'hotel': hotel,
        'living': living,
        'remaining': remaining,
      },
      'budgetBreakdown': {
        'segment': seg,
        'segmentLabel': segLabel,
        'breakdown': {
          'transport': {'total': (budget * 0.25).toInt(), 'percentage': 25, 'label': 'Ulaşım'},
          'accommodation': {'total': (budget * 0.40).toInt(), 'percentage': 40, 'label': 'Konaklama'},
          'pocketMoney': {'total': (budget * 0.35).toInt(), 'percentage': 35, 'label': 'Harçlık'},
        },
      },
    };
  }
}