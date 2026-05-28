import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_result_model.dart';
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
// ============================================================
  // SAĞLIK TURİZMİ
  // ============================================================
 static Future<List<Map<String, dynamic>>> getMedicalPackages({
  required String iata,
  required double budget,
}) async {
  try {
    final uri = Uri.parse(AppConstants.baseUrl + '/medical/packages')
        .replace(queryParameters: {
      'iata': iata,
      'budget': budget.toString(),
    });
    final response = await http.get(uri).timeout(AppConstants.receiveTimeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final packages = List<Map<String, dynamic>>.from(data['data'] ?? []);
      if (packages.isNotEmpty) return packages;
    }
  } catch (e) {}
  // Her zaman mock data döndür
  return _getMockMedicalPackages(iata);
}

  static Future<Map<String, dynamic>> saveMedicalBooking({
    required String sessionId,
    required String packageId,
    required String clinicId,
    required String travelDate,
    required int passengerCount,
    required double treatmentPriceTL,
    required double flightPriceTL,
    required double hotelPriceTL,
    required double totalPriceTL,
    required double commissionTL,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + '/medical/booking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionId,
          'packageId': packageId,
          'clinicId': clinicId,
          'travelDate': travelDate,
          'passengerCount': passengerCount,
          'treatmentPriceTL': treatmentPriceTL,
          'flightPriceTL': flightPriceTL,
          'hotelPriceTL': hotelPriceTL,
          'totalPriceTL': totalPriceTL,
          'commissionTL': commissionTL,
        }),
      ).timeout(AppConstants.receiveTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {}
    return {'success': false};
  }

  static List<Map<String, dynamic>> _getMockMedicalPackages(String iata) {
    return [
      {
        'id': 'med-001',
        'clinic_id': 'clinic-001',
        'treatment_type': 'hair_transplant',
        'treatment_name': 'FUE Hair Transplant (4000 Grafts)',
        'treatment_name_tr': 'FUE Saç Ekimi (4000 Greft)',
        'description': 'En son FUE tekniğiyle kalıcı saç ekimi.',
        'duration_treatment_days': 2,
        'duration_rest_days': 3,
        'price_tl': 45000,
        'price_eur': 1250,
        'includes': ['Konsültasyon', 'Operasyon', 'PRP', 'İlaçlar', 'VIP Transfer'],
        'success_rate': 97.5,
        'commission_rate': 0.22,
        'medical_clinics': {
          'id': 'clinic-001',
          'name': 'Antalya Hair & Aesthetic Center',
          'city_name': 'Antalya',
          'success_score': 9.4,
          'patient_count': 12500,
          'is_ministry_accredited': true,
          'is_jci_accredited': true,
          'specializations': ['Saç Ekimi', 'Diş Estetiği'],
          'languages': ['Türkçe', 'İngilizce', 'Almanca'],
          'commission_rate': 0.22,
        },
      },
      {
        'id': 'med-002',
        'clinic_id': 'clinic-002',
        'treatment_type': 'dental',
        'treatment_name': 'Full Mouth Dental Veneers',
        'treatment_name_tr': 'Tam Ağız Diş Kaplaması',
        'description': 'Zirkonyum kaplama ile mükemmel gülüş.',
        'duration_treatment_days': 3,
        'duration_rest_days': 2,
        'price_tl': 38000,
        'price_eur': 1050,
        'includes': ['Konsültasyon', 'Röntgen', 'Kaplama', 'VIP Transfer'],
        'success_rate': 98.2,
        'commission_rate': 0.20,
        'medical_clinics': {
          'id': 'clinic-002',
          'name': 'MedAntalya Clinic',
          'city_name': 'Antalya',
          'success_score': 9.2,
          'patient_count': 8900,
          'is_ministry_accredited': true,
          'is_jci_accredited': false,
          'specializations': ['Diş Estetiği', 'İmplant'],
          'languages': ['Türkçe', 'İngilizce'],
          'commission_rate': 0.20,
        },
      },
    ];
  }
// ============================================================
  // PYTHON ROTA MOTORU
  // ============================================================
  static Future<List<RouteResultModel>> searchRoutes({
  required String originIata,
  required DateTime departureDate,
  required DateTime returnDate,
  required double totalBudgetTL,
  required int passengers,
}) async {
  try {
    final response = await http.post(
      Uri.parse(AppConstants.pythonSearchEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'originIata': originIata,
        'departureDate': departureDate.toIso8601String().split('T')[0],
        'returnDate': returnDate.toIso8601String().split('T')[0],
        'totalBudgetTL': totalBudgetTL,
        'passengers': passengers,
      }),
    ).timeout(AppConstants.receiveTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final innerData = data['data'];
        List list = [];

        if (innerData is List) {
          list = innerData;
        } else if (innerData is Map) {
          if (innerData['packages'] != null) {
            list = innerData['packages'] as List;
          }
        }

        if (list.isNotEmpty) {
          return list
              .map((item) => RouteResultModel.fromJson(
                  item as Map<String, dynamic>))
              .toList();
        }
      }
    }
  } catch (e) {
    // Mock data döndür
  }
  return _getMockRouteResults(
    originIata,
    departureDate,
    returnDate,
    totalBudgetTL,
    passengers,
  );
}

  static List<RouteResultModel> _getMockRouteResults(
    String originIata,
    DateTime departureDate,
    DateTime returnDate,
    double budget,
    int passengers,
  ) {
    final nights = returnDate.difference(departureDate).inDays;
    final seg = budget < 25000 ? 'economic' : budget < 60000 ? 'standard' : 'premium';
    final segLabel = budget < 25000 ? 'Ekonomik' : budget < 60000 ? 'Standart' : 'Premium';

    Map<String, dynamic> breakdown(double b) => {
      'segment': seg,
      'segment_label': segLabel,
      'total_budget_tl': b,
      'flight_budget': (b * 0.25).toInt(),
      'hotel_budget': (b * 0.40).toInt(),
      'transfer_budget': (b * 0.05).toInt(),
      'pocket_money': (b * 0.30).toInt(),
      'flight_percentage': 25,
      'hotel_percentage': 40,
      'transfer_percentage': 5,
      'pocket_percentage': 30,
    };

    return [
      RouteResultModel.fromJson({
        'destination_iata': 'AYT',
        'city_name': 'Antalya',
        'country': 'Turkey',
        'nights': nights,
        'passengers': passengers,
        'score': 100.0,
        'is_affordable': true,
        'flight': {'airline': 'THY', 'duration': '1s 10dk', 'stops': 0, 'departure_time': '09:00', 'arrival_time': '10:10', 'price_tl': (budget * 0.08).toInt(), 'price_per_person_tl': (budget * 0.08 / passengers).toInt()},
        'hotel': {'id': 'h1', 'name': 'Kaleiçi Butik Otel', 'city': 'Antalya', 'hotel_type': 'boutique', 'star_rating': 4.0, 'review_score': 8.8, 'review_count': 342, 'price_per_night': (budget * 0.06).toInt(), 'total_price': (budget * 0.06 * nights).toInt(), 'features': ['WiFi', 'Kahvaltı', 'Klima'], 'is_partner': true},
        'transfer': {'id': 't1', 'company_name': 'Antalya VIP', 'vehicle_type': 'sedan', 'capacity': 4, 'route_from': 'Havalimanı', 'route_to': 'Merkez', 'price_fixed': (budget * 0.02).toInt(), 'duration_minutes': 30, 'features': ['Klima', 'WiFi']},
        'budget_breakdown': breakdown(budget),
        'estimated_cost': {'total': (budget * 0.50).toInt(), 'flight': (budget * 0.08).toInt(), 'hotel': (budget * 0.12).toInt(), 'transfer': (budget * 0.02).toInt(), 'pocket_money': (budget * 0.28).toInt(), 'remaining': (budget * 0.50).toInt()},
        'alternative_suggestion': null,
      }),
      RouteResultModel.fromJson({
        'destination_iata': 'ATH',
        'city_name': 'Atina',
        'country': 'Greece',
        'nights': nights,
        'passengers': passengers,
        'score': 88.0,
        'is_affordable': true,
        'flight': {'airline': 'Aegean', 'duration': '1s 55dk', 'stops': 0, 'departure_time': '13:20', 'arrival_time': '15:15', 'price_tl': (budget * 0.18).toInt(), 'price_per_person_tl': (budget * 0.18 / passengers).toInt()},
        'hotel': {'id': 'h2', 'name': 'Atina Plaka Pansiyon', 'city': 'Atina', 'hotel_type': 'pension', 'star_rating': 3.0, 'review_score': 8.4, 'review_count': 445, 'price_per_night': (budget * 0.05).toInt(), 'total_price': (budget * 0.05 * nights).toInt(), 'features': ['WiFi', 'Akropolis Manzarası'], 'is_partner': true},
        'transfer': {'id': 't2', 'company_name': 'Athens Transfer', 'vehicle_type': 'sedan', 'capacity': 4, 'route_from': 'Havalimanı', 'route_to': 'Plaka', 'price_fixed': (budget * 0.04).toInt(), 'duration_minutes': 40, 'features': ['Klima', 'WiFi']},
        'budget_breakdown': breakdown(budget),
        'estimated_cost': {'total': (budget * 0.77).toInt(), 'flight': (budget * 0.18).toInt(), 'hotel': (budget * 0.25).toInt(), 'transfer': (budget * 0.04).toInt(), 'pocket_money': (budget * 0.30).toInt(), 'remaining': (budget * 0.23).toInt()},
        'alternative_suggestion': null,
      }),
      RouteResultModel.fromJson({
        'destination_iata': 'BUD',
        'city_name': 'Budapeşte',
        'country': 'Hungary',
        'nights': nights,
        'passengers': passengers,
        'score': 45.0,
        'is_affordable': false,
        'flight': {'airline': 'Wizz Air', 'duration': '2s 20dk', 'stops': 0, 'departure_time': '09:00', 'arrival_time': '11:20', 'price_tl': (budget * 0.30).toInt(), 'price_per_person_tl': (budget * 0.30 / passengers).toInt()},
        'hotel': {'id': 'h3', 'name': 'Budapeşte Ruin Apart', 'city': 'Budapeşte', 'hotel_type': 'apart', 'star_rating': 3.0, 'review_score': 8.6, 'review_count': 523, 'price_per_night': (budget * 0.06).toInt(), 'total_price': (budget * 0.06 * nights).toInt(), 'features': ['WiFi', 'Mutfak'], 'is_partner': true},
        'transfer': null,
        'budget_breakdown': breakdown(budget),
        'estimated_cost': {'total': (budget * 1.06).toInt(), 'flight': (budget * 0.30).toInt(), 'hotel': (budget * 0.30).toInt(), 'transfer': 0, 'pocket_money': (budget * 0.30).toInt(), 'remaining': -(budget * 0.06).toInt()},
        'alternative_suggestion': 'Konaklama süresini ${nights - 2} geceye indirirsen bütçene uygun hale gelir.',
      }),
    ];
  }
// ============================================================
  // FLAŞ SAĞLIK PAKETLERİ
  // ============================================================
  static Future<List<Map<String, dynamic>>> getFlashDeals() async {
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('treatments')
          .select('*, clinics(name, city_name, rating)')
          .eq('is_flash_deal', true)
          .eq('is_active', true)
          .gt('flash_available_slots', 0)
          .order('flash_discount_percent', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }
}