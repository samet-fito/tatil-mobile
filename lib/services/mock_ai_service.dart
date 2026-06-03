import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import '../constants.dart';

class MockAiService {
  static Future<MessageModel> getResponse(
    String cityName,
    String userMessage,
    double remainingBudget,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cityName': cityName,
          'userMessage': userMessage,
          'remainingBudget': remainingBudget,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['message'] != null) {
          return MessageModel.bot(data['message'] as String);
        }
      }
      return _fallback(cityName, userMessage, remainingBudget);
    } catch (e) {
      return _fallback(cityName, userMessage, remainingBudget);
    }
  }

  static MessageModel _fallback(
    String cityName,
    String userMessage,
    double remainingBudget,
  ) {
    final q = userMessage.toLowerCase();

    if (q.contains('ye') || q.contains('yemek') || q.contains('restoran')) {
      return MessageModel.bot(
        '$cityName\'da butce dostu yemek icin yerel pazarlari ve sokak lezzetlerini tercih et.',
        cards: _getFoodCards(cityName),
      );
    }
    if (q.contains('gez') || q.contains('yer') || q.contains('müze')) {
      return MessageModel.bot(
        '$cityName\'in tarihi ve kulturel zenginliklerini kesfet!',
        cards: _getPlaceCards(cityName),
      );
    }
    if (q.contains('acil') || q.contains('hastane') || q.contains('polis')) {
      return MessageModel.bot(_getEmergency(cityName));
    }
    if (q.contains('ulasim') || q.contains('metro') || q.contains('otobüs')) {
      return MessageModel.bot(_getTransport(cityName));
    }
    if (q.contains('para') || q.contains('doviz') || q.contains('euro')) {
      return MessageModel.bot(_getMoney(cityName));
    }
    return MessageModel.bot(
      '$cityName seyahatinde yardimci olmak icin burdayim! '
      'Yemek, ulasim, gezilecek yerler veya acil durum hakkinda sorabilirsin.',
    );
  }

  static List<CardData> _getFoodCards(String city) {
    final Map<String, List<CardData>> data = {
      'Antalya': [
        CardData(title: 'Selale Restaurant', subtitle: 'Duden Selalesi kenarinda', emoji: '🦞', price: '250-400 TL', budgetNote: 'Butce dostu', color: const Color(0xFF0EA5E9), actionLabel: 'Gidin'),
        CardData(title: 'Kaleici Piyaz', subtitle: 'Yerel lezzet', emoji: '🥗', price: '80-120 TL', budgetNote: 'Cok uygun', color: const Color(0xFF16A34A), actionLabel: 'Gidin'),
      ],
      'Atina': [
        CardData(title: 'Monastiraki Souvlaki', subtitle: 'Meshur Bairaktaris', emoji: '🥙', price: '8-12 EUR', budgetNote: 'Butce dostu', color: const Color(0xFF1D6B4E), actionLabel: 'Gidin'),
        CardData(title: 'Psiri Tavernalari', subtitle: 'Otantik Yunan', emoji: '🐟', price: '20-35 EUR', budgetNote: 'Orta segment', color: const Color(0xFF0EA5E9), actionLabel: 'Gidin'),
      ],
      'Roma': [
        CardData(title: 'Trastevere Trattoria', subtitle: 'Otantik Roma', emoji: '🍝', price: '15-25 EUR', budgetNote: 'Orta segment', color: const Color(0xFFD85A30), actionLabel: 'Gidin'),
        CardData(title: 'Campo de Fiori', subtitle: 'Sabah pazari', emoji: '🥪', price: '5-10 EUR', budgetNote: 'Cok uygun', color: const Color(0xFF16A34A), actionLabel: 'Gidin'),
      ],
      'Budapeşte': [
        CardData(title: 'Langos', subtitle: 'Geleneksel Macar', emoji: '🥞', price: '3-5 EUR', budgetNote: 'Cok uygun', color: const Color(0xFF16A34A), actionLabel: 'Gidin'),
        CardData(title: 'Ruin Barlarda Aksam', subtitle: 'Szimpla Kert', emoji: '🍺', price: '10-20 EUR', budgetNote: 'Butce dostu', color: const Color(0xFF7C3AED), actionLabel: 'Gidin'),
      ],
    };
    return data[city] ?? data['Antalya']!;
  }

  static List<CardData> _getPlaceCards(String city) {
    final Map<String, List<CardData>> data = {
      'Antalya': [
        CardData(title: 'Kaleici', subtitle: 'Tarihi liman', emoji: '🏛️', price: 'Ucretsiz', budgetNote: 'Butceye uygun', color: const Color(0xFFD85A30), actionLabel: 'Gidin'),
        CardData(title: 'Duden Selalesi', subtitle: 'Dogal park', emoji: '💧', price: '50 TL', budgetNote: 'Uygun', color: const Color(0xFF0EA5E9), actionLabel: 'Gidin'),
      ],
      'Atina': [
        CardData(title: 'Akropolis', subtitle: 'UNESCO Dunya Mirasi', emoji: '🏛️', price: '20 EUR', budgetNote: 'Sabah 8de git', color: const Color(0xFFD85A30), actionLabel: 'Gidin'),
        CardData(title: 'Plaka Semti', subtitle: 'Tarihi mahalle', emoji: '🏘️', price: 'Ucretsiz', budgetNote: 'Ucretsiz', color: const Color(0xFF7C3AED), actionLabel: 'Gidin'),
      ],
      'Roma': [
        CardData(title: 'Kolosseum', subtitle: 'MS 70-80', emoji: '🏟️', price: '16 EUR', budgetNote: 'Online bilet al', color: const Color(0xFFD85A30), actionLabel: 'Gidin'),
        CardData(title: 'Vatikan Muzeleri', subtitle: 'Sistine Sapeli', emoji: '🎨', price: '20 EUR', budgetNote: 'Onceden rezerve et', color: const Color(0xFF7C3AED), actionLabel: 'Gidin'),
      ],
      'Budapeşte': [
        CardData(title: 'Szechenyi Termal', subtitle: '1913ten beri', emoji: '♨️', price: '25 EUR', budgetNote: 'Hafta ici sakin', color: const Color(0xFF0EA5E9), actionLabel: 'Gidin'),
        CardData(title: 'Buda Kalesi', subtitle: 'UNESCO Mirasi', emoji: '🏰', price: 'Dis mekan ucretsiz', budgetNote: 'Ucretsiz', color: const Color(0xFFD85A30), actionLabel: 'Gidin'),
      ],
    };
    return data[city] ?? data['Antalya']!;
  }

  static String _getEmergency(String city) {
    final Map<String, String> data = {
      'Antalya': '📞 Acil: 112\n🏥 Antalya Egitim Hastanesi: +90 242 249 44 00\n🚔 Polis: 155',
      'Atina': '📞 Acil: 112\n🏥 Evangelismos: +30 213 204 1000\n🇹🇷 TC Atina Buyukelciligi: +30 210 724 5915',
      'Roma': '📞 Acil: 112\n🏥 Gemelli: +39 06 30151\n🇹🇷 TC Roma Buyukelciligi: +39 06 4469 4209',
      'Budapeşte': '📞 Acil: 112\n🏥 Semmelweis: +36 1 459 1500\n🇹🇷 TC Budapeşte: +36 1 273 0050',
    };
    return data[city] ?? '📞 Acil: 112';
  }

  static String _getTransport(String city) {
    final Map<String, String> data = {
      'Antalya': 'Antray ve AKBUS karti al. Gunluk kart 45 TL. Havalimanindan sehre 20 dakika, 15 TL.',
      'Atina': 'Metro gunluk bilet 4.50 EUR. Havalimanindan 1 saat, 6 EUR.',
      'Roma': '48 saatlik kart 7 EUR. Tramvay ve otobus kapsamli.',
      'Budapeşte': '24 saatlik kart 5 EUR. Havalimanindan 100E otobusu 30 dakika.',
    };
    return data[city] ?? 'Toplu tasima karti al.';
  }

  static String _getMoney(String city) {
    final Map<String, String> data = {
      'Antalya': 'Turk Lirasi gecerli. Doviz icin sehir merkezini tercih et.',
      'Atina': 'Euro gecerli. 1 EUR yaklasik 36 TL. Banka ATMlerini tercih et.',
      'Roma': 'Euro gecerli. Yerel pazarlar daha ucuz.',
      'Budapeşte': 'Forint gecerli. Kucuk yerler nakit istiyor.',
    };
    return data[city] ?? 'Yerel para birimini kullan.';
  }

  static List<String> getQuickReplies(String cityName) {
    return [
      'Butce dostu yemek',
      'Gorulecek yerler',
      'Ulasim nasil?',
      'Para birimi?',
      'Acil durum',
      'Hava nasil?',
    ];
  }
}