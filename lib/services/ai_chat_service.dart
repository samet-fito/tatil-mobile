import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/message_model.dart';
import '../models/personalized_guide_model.dart';
import '../data/destination_interest_pois.dart';
import '../data/holiday_types.dart';
import '../services/guide_quality.dart';
import '../utils/traveler_group_profile.dart';

/// Yapay zeka sohbet — yalnızca backend `/ai/chat` ve `/chat` uç noktaları.
class AiChatService {
  static Future<MessageModel> getResponse({
    required String cityName,
    required String userMessage,
    required double remainingBudget,
    String? destinationIata,
    String? sessionId,
  }) async {
    final errors = <String>[];

    for (final endpoint in [
      '${AppConstants.baseUrl}/ai/chat',
      AppConstants.chatEndpoint,
    ]) {
      try {
        final body = endpoint.contains('/ai/chat')
            ? {
                'cityName': cityName,
                'userMessage': userMessage,
                'remainingBudget': remainingBudget,
              }
            : {
                'sessionId': sessionId ?? 'mobile-${cityName.hashCode}',
                'cityName': cityName,
                'destinationIata': destinationIata ?? '',
                'message': userMessage,
              };

        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(AppConstants.connectTimeout);

        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = _extractMessage(data);
        if (text != null && text.trim().isNotEmpty) {
          return MessageModel.bot(text.trim());
        }
      } catch (e) {
        errors.add(e.toString());
      }
    }

    return MessageModel.bot(
      'Şu an yanıt alınamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.',
    );
  }

  static String? _extractMessage(Map<String, dynamic> data) {
    if (data['message'] is String) return data['message'] as String;
    final nested = data['data'];
    if (nested is Map) {
      if (nested['message'] is String) return nested['message'] as String;
      if (nested['response'] is String) return nested['response'] as String;
    }
    return null;
  }

  static List<String> getQuickReplies(String cityName) => [
        'Bütçe dostu yemek',
        'Görülecek yerler',
        'Ulaşım nasıl?',
        'Acil durum',
        'Aktivite öner',
      ];

  /// Rezervasyon sonrası destinasyon rehberi — hava, kurallar, hayati uyarılar.
  static Future<PersonalizedGuide?> getPersonalizedTravelGuide({
    required String cityName,
    required String country,
    required int nights,
    required DateTime departureDate,
    required DateTime returnDate,
    required List<int> passengerAges,
    required int adults,
    required int children,
    String? hotelName,
    double remainingBudget = 0,
    String? weatherSummary,
    List<String> holidayTypes = const [],
    String? destinationIata,
  }) async {
    final group = TravelerGroupProfile.from(
      adults: adults,
      children: children,
      passengerAges: passengerAges,
    );

    final interestBlock = holidayTypes.isNotEmpty
        ? DestinationInterestPois.aiContext(
            iata: destinationIata ?? '',
            cityName: cityName,
            interests: holidayTypes,
          )
        : '';

    final interestLabels = holidayTypes.isNotEmpty
        ? HolidayTypes.labelsOf(holidayTypes).join(', ')
        : '';

    final depStr =
        '${departureDate.day}.${departureDate.month}.${departureDate.year}';
    final retStr =
        '${returnDate.day}.${returnDate.month}.${returnDate.year}';

    final weatherBlock = weatherSummary != null && weatherSummary.isNotEmpty
        ? '\nGerçek hava verisi (buna göre giyim/valiz öner):\n$weatherSummary\n'
        : '';

    final prompt = '''
Rezervasyonu tamamlayan bir gezgin için $cityName, $country destinasyonunda ${nights} gece kalacak.
${hotelName != null ? 'Konaklama: $hotelName.' : ''}
Seyahat tarihleri: $depStr — $retStr.
Genel tanıtım, maliyet endeksi, "API kaynağı" gibi boş cümleler YAZMA.

${group.aiContext}
${interestBlock.isNotEmpty ? '\n$interestBlock' : ''}

Yanıtını YALNIZCA aşağıdaki JSON formatında ver (başka metin ekleme):
{
  "headline": "kısa başlık — gruba ve tatil türüne özel",
  "subtitle": "1 cümle — grup + ${interestLabels.isNotEmpty ? interestLabels : 'seyahat'} özeti",
  "sections": [
    {
      "kind": "groupProfile",
      "emoji": "👥",
      "title": "Grubunuz için özet",
      "items": ["madde 1", "madde 2"]
    }
  ]
}

Tam ${holidayTypes.isNotEmpty ? 7 : 6} bölüm oluştur (kind alanını aynen kullan):
0. kind: "groupProfile" — 3-4 madde: grup tipi, tempo, size özel seyahat tarzı
${holidayTypes.isNotEmpty ? '1. kind: "interests" — 4-6 madde: seçilen tatil türlerine ($interestLabels) özel somut öneriler; alışveriş seçildiyse AVM/outlet isimleri ve indirim dönemleri; kültür seçildiyse müze/rota; deniz seçildiyse plaj/bölge' : ''}
${holidayTypes.isNotEmpty ? '2' : '1'}. kind: "mustDo" — 5-6 somut aktivite/rota (YAŞ ve grup + tatil türüne uygun)
${holidayTypes.isNotEmpty ? '3' : '2'}. kind: "strictRules" — yasal/kültürel KESKİN kurallar
${holidayTypes.isNotEmpty ? '4' : '3'}. kind: "lifeSavers" — hayat kurtaran uyarılar
${holidayTypes.isNotEmpty ? '5' : '4'}. kind: "packing" — valiz & ekipman
${holidayTypes.isNotEmpty ? '6' : '5'}. kind: "localTips" — ulaşım, bahşiş, yerel alışkanlıklar

Her madde en fazla 2 cümle, Türkçe, somut olsun.
$cityName'e özgü detay ver (jenerik Avrupa/Asya tavsiyesi yazma).
$weatherBlock''';

    for (var attempt = 0; attempt < 2; attempt++) {
      for (final endpoint in [
        '${AppConstants.baseUrl}/ai/chat',
        AppConstants.chatEndpoint,
      ]) {
        try {
          final body = endpoint.contains('/ai/chat')
              ? {
                  'cityName': cityName,
                  'userMessage': prompt,
                  'remainingBudget': remainingBudget,
                  'mode': 'guide',
                }
              : {
                  'sessionId': 'guide-${cityName.hashCode}',
                  'cityName': cityName,
                  'destinationIata': '',
                  'message': prompt,
                };

          final response = await http
              .post(
                Uri.parse(endpoint),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 45));

          if (response.statusCode != 200) continue;

          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success'] == false) continue;

          final text = _extractMessage(data);
          if (text == null || text.trim().isEmpty) continue;

          final parsed = _parseGuideJson(text);
          if (parsed != null &&
              !parsed.isEmpty &&
              GuideQuality.isAcceptable(parsed)) {
            return parsed;
          }
        } catch (_) {}
      }
      if (attempt == 0) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  static PersonalizedGuide? _parseGuideJson(String raw) {
    try {
      var text = raw.trim();
      final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
      final match = fence.firstMatch(text);
      if (match != null) text = match.group(1)!.trim();

      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        text = text.substring(start, end + 1);
      }

      final decoded = jsonDecode(text) as Map<String, dynamic>;
      final guide = PersonalizedGuide.fromJson(decoded);
      return GuideQuality.isAcceptable(guide) ? guide : null;
    } catch (_) {
      return null;
    }
  }

  /// En popüler turist aktiviteleri — online satış / komisyon kataloğu.
  static Future<Map<String, dynamic>?> getPopularActivitiesCatalog({
    required String cityName,
    required String country,
    required int nights,
    List<int> passengerAges = const [],
  }) async {
    final ageHint = passengerAges.isEmpty
        ? 'genel turist profili'
        : '${passengerAges.join(", ")} yaş';

    final prompt = '''
$cityName, $country için turistlerin EN ÇOK tercih ettiği 8 aktivite/tur listele.
Gezgin profili: $ageHint, $nights gece kalacak.
Online bilet satılabilir, gerçekçi fiyatlı aktiviteler seç (müze, tekne turu, rehberli gezi vb.).

Yanıtını YALNIZCA JSON olarak ver:
{
  "activities": [
    {
      "title": "Aktivite adı",
      "category": "tours|museums|adventure|events|food",
      "description": "1-2 cümle",
      "duration": "3 saat",
      "priceTL": 750,
      "rating": 4.8,
      "reviewCount": 2400,
      "popularityRank": 1,
      "highlights": ["Mobil bilet", "Ücretsiz iptal"]
    }
  ]
}

popularityRank 1 en popüler. priceTL gerçekçi TL fiyat olsun. Tam 8 aktivite.
''';

    for (final endpoint in [
      '${AppConstants.baseUrl}/ai/chat',
      AppConstants.chatEndpoint,
    ]) {
      try {
        final body = endpoint.contains('/ai/chat')
            ? {
                'cityName': cityName,
                'userMessage': prompt,
                'remainingBudget': 0,
              }
            : {
                'sessionId': 'activities-${cityName.hashCode}',
                'cityName': cityName,
                'destinationIata': '',
                'message': prompt,
              };

        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = _extractMessage(data);
        if (text == null || text.trim().isEmpty) continue;

        final parsed = _parseActivitiesJson(text);
        if (parsed != null && parsed.isNotEmpty) {
          return {'activities': parsed};
        }
      } catch (_) {}
    }
    return null;
  }

  /// Şehre özel güncel harcama limitleri (yeme-içme + ulaşım).
  static Future<Map<String, dynamic>?> getCitySpendingLimits({
    required String cityName,
    required String country,
    required int nights,
    required int passengers,
    int children = 0,
  }) async {
    final people = passengers + children;
    final prompt = '''
$cityName, $country için 2026 turist harcama ortalamalarını Türk Lirası (TL) ile ver.
$people kişi, $nights gece kalacak.

KURALLAR:
- dailyFoodPerPersonTL = SADECE günlük yeme-içme (ulaşım hariç)
- dailyTransportPerPersonTL = SADECE günlük yerel ulaşım
- foodItems fiyatları toplamı = dailyFoodPerPersonTL olmalı
- transportItems fiyatları toplamı = dailyTransportPerPersonTL olmalı
- foodSummary alanına rakam yazma; sadece kısa bağlam (ör. "orta segment taverna")
- perPersonPerDayTL gönderme; uygulama yemek+ulaşım toplar

Yanıtını YALNIZCA JSON olarak ver:
{
  "dailyFoodPerPersonTL": 850,
  "dailyTransportPerPersonTL": 280,
  "foodScopeLabel": "3 öğün orta segment restoran",
  "transportScopeLabel": "metro + taksi karışık",
  "foodSummary": "Orta segment restoran ve kafe ortalaması",
  "disclaimer": "2026 piyasa tahmini; gerçek harcama değişebilir",
  "foodItems": [
    {"name": "Kahvaltı", "priceTL": 350},
    {"name": "Öğle yemeği", "priceTL": 500}
  ],
  "transportItems": [
    {"name": "Günlük metro kartı", "priceTL": 120},
    {"name": "Taksi (kısa mesafe)", "priceTL": 160}
  ]
}

Gerçekçi, $cityName ve $country'e özgü güncel turist fiyatları kullan.
''';

    for (final endpoint in [
      '${AppConstants.baseUrl}/ai/chat',
      AppConstants.chatEndpoint,
    ]) {
      try {
        final body = endpoint.contains('/ai/chat')
            ? {
                'cityName': cityName,
                'userMessage': prompt,
                'remainingBudget': 0,
              }
            : {
                'sessionId': 'spending-${cityName.hashCode}',
                'cityName': cityName,
                'destinationIata': '',
                'message': prompt,
              };

        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = _extractMessage(data);
        if (text == null || text.trim().isEmpty) continue;

        final parsed = _parseSpendingJson(text);
        if (parsed != null) return parsed;
      } catch (_) {}
    }
    return null;
  }

  static Map<String, dynamic>? _parseSpendingJson(String raw) {
    try {
      var text = raw.trim();
      final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
      final match = fence.firstMatch(text);
      if (match != null) text = match.group(1)!.trim();

      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        text = text.substring(start, end + 1);
      }

      final decoded = jsonDecode(text) as Map<String, dynamic>;
      final food = (decoded['dailyFoodPerPersonTL'] as num?)?.toInt() ?? 0;
      final transport =
          (decoded['dailyTransportPerPersonTL'] as num?)?.toInt() ?? 0;
      if (food <= 0 && transport <= 0) return null;

      final foodFromItems = _sumItems(decoded['foodItems']);
      final transportFromItems = _sumItems(decoded['transportItems']);
      if (foodFromItems > 0) decoded['dailyFoodPerPersonTL'] = foodFromItems;
      if (transportFromItems > 0) {
        decoded['dailyTransportPerPersonTL'] = transportFromItems;
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static int _sumItems(dynamic items) {
    if (items is! List) return 0;
    var total = 0;
    for (final item in items) {
      if (item is! Map) continue;
      total += (item['priceTL'] as num?)?.round() ?? 0;
    }
    return total;
  }

  static List<Map<String, dynamic>>? _parseActivitiesJson(String raw) {
    try {
      var text = raw.trim();
      final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
      final match = fence.firstMatch(text);
      if (match != null) text = match.group(1)!.trim();

      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        text = text.substring(start, end + 1);
      }

      final decoded = jsonDecode(text) as Map<String, dynamic>;
      final list = decoded['activities'];
      if (list is! List || list.isEmpty) return null;
      return list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
