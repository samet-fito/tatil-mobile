import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_model.dart';

class ApiService {
  // Mac'in IP adresini buraya yaz (terminalde `ifconfig | grep inet` ile bulabilirsin)
  static const String _baseUrl = 'http://localhost:3001/api/v1';

  static Future<Map<String, dynamic>> searchPackages(SearchModel model) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(model.toJson()),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Bağlantı hatası - mock data kullan
    }

    // Mock data (backend bağlantısı olmadığında)
    return _getMockData(model);
  }

  static Map<String, dynamic> _getMockData(SearchModel model) {
    return {
      'success': true,
      'data': {
        'packages': [
          {
            'destinationId': 'dest-001',
            'cityName': 'Antalya',
            'iataCode': 'AYT',
            'country': 'Turkey',
            'countryCode': 'TR',
            'score': 81,
            'isAffordable': true,
            'nights': model.nights,
            'highlights': ['Akdeniz', 'Plajlar', 'Antik Kentler'],
            'flightInfo': {
              'airline': 'THY',
              'duration': '1s 10dk',
              'stops': 0,
              'departureTime': '08:30',
              'arrivalTime': '09:40',
            },
            'hotelInfo': {
              'name': 'Akra Hotels',
              'stars': 5,
              'rating': 8.6,
              'reviewCount': 2841,
              'amenities': ['Havuz', 'Spa', 'Plaj', 'WiFi'],
            },
            'estimatedCost': {
              'total': (model.totalBudgetTL * 0.45).toInt(),
              'flight': (model.totalBudgetTL * 0.08).toInt(),
              'hotel': (model.totalBudgetTL * 0.25).toInt(),
              'living': (model.totalBudgetTL * 0.12).toInt(),
              'remaining': (model.totalBudgetTL * 0.55).toInt(),
            },
            'budgetBreakdown': {
              'segment': 'standard',
              'segmentLabel': 'Standart',
              'breakdown': {
                'transport': {'total': (model.totalBudgetTL * 0.25).toInt(), 'percentage': 25, 'label': 'Ulaşım'},
                'accommodation': {'total': (model.totalBudgetTL * 0.40).toInt(), 'percentage': 40, 'label': 'Konaklama'},
                'pocketMoney': {'total': (model.totalBudgetTL * 0.35).toInt(), 'percentage': 35, 'label': 'Harçlık'},
              },
            },
          },
          {
            'destinationId': 'dest-002',
            'cityName': 'Atina',
            'iataCode': 'ATH',
            'country': 'Greece',
            'countryCode': 'GR',
            'score': 78,
            'isAffordable': true,
            'nights': model.nights,
            'highlights': ['Akropolis', 'Antika', 'Deniz'],
            'flightInfo': {
              'airline': 'Aegean',
              'duration': '1s 55dk',
              'stops': 0,
              'departureTime': '13:20',
              'arrivalTime': '15:15',
            },
            'hotelInfo': {
              'name': 'Hotel Grande Bretagne',
              'stars': 5,
              'rating': 9.1,
              'reviewCount': 3678,
              'amenities': ['Akropolis Manzarası', 'Spa', 'WiFi'],
            },
            'estimatedCost': {
              'total': (model.totalBudgetTL * 0.85).toInt(),
              'flight': (model.totalBudgetTL * 0.18).toInt(),
              'hotel': (model.totalBudgetTL * 0.42).toInt(),
              'living': (model.totalBudgetTL * 0.25).toInt(),
              'remaining': (model.totalBudgetTL * 0.15).toInt(),
            },
            'budgetBreakdown': {
              'segment': 'standard',
              'segmentLabel': 'Standart',
              'breakdown': {
                'transport': {'total': (model.totalBudgetTL * 0.25).toInt(), 'percentage': 25, 'label': 'Ulaşım'},
                'accommodation': {'total': (model.totalBudgetTL * 0.40).toInt(), 'percentage': 40, 'label': 'Konaklama'},
                'pocketMoney': {'total': (model.totalBudgetTL * 0.35).toInt(), 'percentage': 35, 'label': 'Harçlık'},
              },
            },
          },
          {
            'destinationId': 'dest-003',
            'cityName': 'Roma',
            'iataCode': 'FCO',
            'country': 'Italy',
            'countryCode': 'IT',
            'score': 74,
            'isAffordable': true,
            'nights': model.nights,
            'highlights': ['Colosseum', 'Vatikan', 'İtalyan Mutfağı'],
            'flightInfo': {
              'airline': 'Turkish Airlines',
              'duration': '2s 50dk',
              'stops': 0,
              'departureTime': '07:45',
              'arrivalTime': '10:35',
            },
            'hotelInfo': {
              'name': 'Hassler Roma',
              'stars': 5,
              'rating': 9.3,
              'reviewCount': 2156,
              'amenities': ['Manzara', 'Restoran', 'Spa', 'WiFi'],
            },
            'estimatedCost': {
              'total': (model.totalBudgetTL * 0.92).toInt(),
              'flight': (model.totalBudgetTL * 0.22).toInt(),
              'hotel': (model.totalBudgetTL * 0.45).toInt(),
              'living': (model.totalBudgetTL * 0.25).toInt(),
              'remaining': (model.totalBudgetTL * 0.08).toInt(),
            },
            'budgetBreakdown': {
              'segment': 'standard',
              'segmentLabel': 'Standart',
              'breakdown': {
                'transport': {'total': (model.totalBudgetTL * 0.25).toInt(), 'percentage': 25, 'label': 'Ulaşım'},
                'accommodation': {'total': (model.totalBudgetTL * 0.40).toInt(), 'percentage': 40, 'label': 'Konaklama'},
                'pocketMoney': {'total': (model.totalBudgetTL * 0.35).toInt(), 'percentage': 35, 'label': 'Harçlık'},
              },
            },
          },
        ],
        'meta': {
          'dataSource': 'mock',
          'processingTimeMs': 150,
          'cacheHit': false,
        },
      },
    };
  }

  static Future<Map<String, dynamic>> getActivities({
    required String iata,
    required String city,
    required String departure,
    required String returnDate,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/activities?iata=$iata&city=${Uri.encodeComponent(city)}&departure=$departure&return=$returnDate',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {}
    return {'success': false};
  }

  static Future<Map<String, dynamic>> getVisaInfo(String countryCode) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/visa?countryCode=$countryCode'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {}
    return {'success': false};
  }

  static Future<Map<String, dynamic>> sendChat({
    required String sessionId,
    required String cityName,
    required String destinationIata,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionId,
          'cityName': cityName,
          'destinationIata': destinationIata,
          'message': message,
        }),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {}
    return {'success': false};
  }
}