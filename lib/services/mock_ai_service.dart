import 'package:flutter/material.dart';
import '../models/message_model.dart';

class MockAiService {
  static const Map<String, Map<String, dynamic>> _cityData = {
    'Antalya': {
      'theme': 'beach',
      'food': [
        CardData(
          title: 'Şelale Restaurant',
          subtitle: 'Düden Şelalesi kenarında, deniz ürünleri',
          emoji: '🦞',
          price: '250-400 TL/kişi',
          budgetNote: 'Bütçe dostu',
          color: Color(0xFF0EA5E9),
        ),
        CardData(
          title: 'Kaleiçi Sokaklarında Piyaz',
          subtitle: 'Yerel lezzet, tarihi çarşı içi',
          emoji: '🥗',
          price: '80-120 TL/kişi',
          budgetNote: '✅ Çok uygun',
          color: Color(0xFF16A34A),
        ),
      ],
      'places': [
        CardData(
          title: 'Kaleiçi',
          subtitle: 'Tarihi liman bölgesi, Roma dönemi kalıntıları',
          emoji: '🏛️',
          price: 'Ücretsiz',
          budgetNote: '✅ Bütçeye uygun',
          color: Color(0xFFD85A30),
        ),
        CardData(
          title: 'Düden Şelalesi',
          subtitle: 'Doğal park, piknik alanları',
          emoji: '💧',
          price: '50 TL giriş',
          budgetNote: '✅ Uygun',
          color: Color(0xFF0EA5E9),
        ),
      ],
      'emergency': '📞 Acil: 112\n🏥 Antalya Eğitim Hastanesi: +90 242 249 44 00\n🚔 Polis: 155\n🇹🇷 Yurt içi, konsolosluk gerekmez',
      'transport': 'Antalya\'da şehir içi ulaşım için Antray (tramvay) ve AKBUS kartı al. Günlük kart 45 TL. Havalimanından şehre AntRay ile 20 dakika, 15 TL.',
      'money': 'Türk Lirası (TL) geçerli. ATM her yerde mevcut. Döviz için şehir merkezindeki büroları tercih et, havalimanından kaçın.',
      'weather': 'Yaz aylarında 35-40°C. Bol su iç, güneş kremi şart. Sabah erken veya akşam aktiviteleri planla.',
    },
    'Atina': {
      'theme': 'culture',
      'food': [
        CardData(
          title: 'Monastiraki\'de Souvlaki',
          subtitle: 'Meşhur Bairaktaris, 1879\'dan beri',
          emoji: '🥙',
          price: '8-12 €/kişi',
          budgetNote: '✅ Bütçe dostu',
          color: Color(0xFF1D6B4E),
        ),
        CardData(
          title: 'Psiri Bölgesi Tavernaları',
          subtitle: 'Otantik Yunan mutfağı, yerel atmosfer',
          emoji: '🐟',
          price: '20-35 €/kişi',
          budgetNote: 'Orta segment',
          color: Color(0xFF0EA5E9),
        ),
      ],
      'places': [
        CardData(
          title: 'Akropolis',
          subtitle: 'MÖ 5. yüzyıl, UNESCO Dünya Mirası',
          emoji: '🏛️',
          price: '20 € giriş',
          budgetNote: 'Sabah 8\'de git, kalabalık az',
          color: Color(0xFFD85A30),
        ),
        CardData(
          title: 'Plaka Semti',
          subtitle: 'Tarihi mahalle, kafeler ve butik dükkanlar',
          emoji: '🏘️',
          price: 'Ücretsiz gezmek',
          budgetNote: '✅ Ücretsiz',
          color: Color(0xFF7C3AED),
        ),
      ],
      'emergency': '📞 Acil: 112\n🏥 Evangelismos Hastanesi: +30 213 204 1000\n🚔 Polis: 100\n🇹🇷 TC Atina Büyükelçiliği: +30 210 724 5915',
      'transport': 'Atina Metro\'su çok gelişmiş. Günlük bilet 4.50 €. Havalimanından Metro X95 ile 1 saat, 6 €. Taksi için Uber veya Beat uygulaması güvenli.',
      'money': 'Euro (€) geçerli. 1 € ≈ 36 TL. ATM\'lerde Euronet komisyon alır, banka ATM\'lerini tercih et. Kart her yerde geçerli.',
      'weather': 'Yaz 30-35°C, kuru sıcak. Akropolis için erken sabah git. Bol su taşı.',
    },
    'Roma': {
      'theme': 'culture',
      'food': [
        CardData(
          title: 'Trastevere\'de Trattoria',
          subtitle: 'Otantik Roma mutfağı, turistik değil',
          emoji: '🍝',
          price: '15-25 €/kişi',
          budgetNote: 'Orta segment',
          color: Color(0xFFD85A30),
        ),
        CardData(
          title: 'Campo de Fiori Pazarı',
          subtitle: 'Sabah pazarı, taze ürünler ve street food',
          emoji: '🥪',
          price: '5-10 €/kişi',
          budgetNote: '✅ Çok uygun',
          color: Color(0xFF16A34A),
        ),
      ],
      'places': [
        CardData(
          title: 'Kolosseum',
          subtitle: 'MS 70-80, gladyatör arenası',
          emoji: '🏟️',
          price: '16 € giriş',
          budgetNote: 'Online bilet al, kuyruk yok',
          color: Color(0xFFD85A30),
        ),
        CardData(
          title: 'Vatikan Müzeleri',
          subtitle: 'Sistine Şapeli dahil, saatler sürer',
          emoji: '🎨',
          price: '20 € giriş',
          budgetNote: 'Mutlaka önceden rezerve et',
          color: Color(0xFF7C3AED),
        ),
      ],
      'emergency': '📞 Acil: 112\n🏥 Gemelli Hastanesi: +39 06 30151\n🚔 Polis: 113\n🇹🇷 TC Roma Büyükelçiliği: +39 06 4469 4209',
      'transport': 'Roma\'da Metro az gelişmiş ama tramvay ve otobüs kapsamlı. 48 saatlik kart 7 €. Taksiye dikkat, saygın şirket seç. Çoğu yer yürüme mesafesinde.',
      'money': 'Euro (€) geçerli. Turistik bölgelerde fahiş fiyat olabilir. Campo de Fiori gibi yerel pazarları tercih et.',
      'weather': 'Yaz 28-33°C. Öğle saatlerinde müze içlerinde dinlen. Çeşmelerden ücretsiz içme suyu içebilirsin.',
    },
    'Budapeşte': {
      'theme': 'city',
      'food': [
        CardData(
          title: 'Büyük Pazar\'da Lángos',
          subtitle: 'Geleneksel Macar street food',
          emoji: '🥞',
          price: '3-5 €/kişi',
          budgetNote: '✅ Çok uygun',
          color: Color(0xFF16A34A),
        ),
        CardData(
          title: 'Ruin Bar\'larda Akşam',
          subtitle: 'Szimpla Kert, dünyanın en ünlü ruin barı',
          emoji: '🍺',
          price: '10-20 €/akşam',
          budgetNote: 'Bütçe dostu',
          color: Color(0xFF7C3AED),
        ),
      ],
      'places': [
        CardData(
          title: 'Széchenyi Termal Banyosu',
          subtitle: '1913\'ten beri, açık ve kapalı havuzlar',
          emoji: '♨️',
          price: '25 € giriş',
          budgetNote: 'Hafta içi daha sakin',
          color: Color(0xFF0EA5E9),
        ),
        CardData(
          title: 'Buda Kalesi',
          subtitle: 'UNESCO Mirası, panoramik Tuna manzarası',
          emoji: '🏰',
          price: 'Dış mekan ücretsiz',
          budgetNote: '✅ Ücretsiz',
          color: Color(0xFFD85A30),
        ),
      ],
      'emergency': '📞 Acil: 112\n🏥 Semmelweis Üniversite Hastanesi: +36 1 459 1500\n🚔 Polis: 107\n🇹🇷 TC Budapeşte Büyükelçiliği: +36 1 273 0050',
      'transport': 'Budapeşte toplu taşıması mükemmel. 24 saatlik kart 5 €. Metro, tramvay ve otobüs entegre. Havalimanından 100E otobüsü ile 30 dakika, 1.5 €.',
      'money': 'Forint (HUF) geçerli. 1 TL ≈ 11 HUF. Kart her yerde geçerli ama küçük yerler nakit istiyor. ATM\'den Forint çek.',
      'weather': 'Yaz 25-30°C, Avrupa\'nın en ılımlı başkentlerinden. Tuna kenarı akşamları serin olabilir, ince bir ceket al.',
    },
  };

  static Future<MessageModel> getResponse(
    String cityName,
    String userMessage,
    double remainingBudget,
  ) async {
    // Gerçekçi gecikme simülasyonu
    await Future.delayed(
      Duration(milliseconds: 800 + (DateTime.now().millisecond % 600)),
    );

    final city = _cityData[cityName];
    final q = userMessage.toLowerCase();

    if (city == null) {
      return MessageModel.bot(
        '$cityName için henüz detaylı bilgim yok, ama genel seyahat sorularını yanıtlayabilirim! '
        'Yemek, ulaşım veya acil durum hakkında sorabilirsin.',
      );
    }

    // Yemek soruları
    if (q.contains('ye') || q.contains('yemek') || q.contains('restoran') ||
        q.contains('nerede') || q.contains('bütçe dostu') || q.contains('ucuz')) {
      return MessageModel.bot(
        '$cityName\'da bütçene uygun harika seçenekler var! '
        'Kalan bütçen (${remainingBudget.toInt()} TL) için önerilerim:',
        cards: List<CardData>.from(city['food'] as List),
      );
    }

    // Gezilecek yerler
    if (q.contains('gez') || q.contains('görülecek') || q.contains('yer') ||
        q.contains('müze') || q.contains('tarihi') || q.contains('ne yapayım')) {
      return MessageModel.bot(
        '$cityName\'da mutlaka görmen gereken yerler bunlar. '
        'Sabah erken git, hem kalabalıktan kaçarsın hem fotoğraflar harika çıkar!',
        cards: List<CardData>.from(city['places'] as List),
      );
    }

    // Acil durum
    if (q.contains('acil') || q.contains('hastane') || q.contains('polis') ||
        q.contains('yardım') || q.contains('kaybol')) {
      return MessageModel.bot(city['emergency'] as String);
    }

    // Ulaşım
    if (q.contains('ulaşım') || q.contains('metro') || q.contains('otobüs') ||
        q.contains('taksi') || q.contains('havalimanı') || q.contains('nasıl gidilir')) {
      return MessageModel.bot(city['transport'] as String);
    }

    // Para/döviz
    if (q.contains('para') || q.contains('döviz') || q.contains('euro') ||
        q.contains('atm') || q.contains('kur') || q.contains('ödeme')) {
      return MessageModel.bot(city['money'] as String);
    }

    // Hava durumu
    if (q.contains('hava') || q.contains('sıcak') || q.contains('soğuk') ||
        q.contains('ne giysem') || q.contains('iklim')) {
      return MessageModel.bot(city['weather'] as String);
    }

    // Yakınımda ne var
    if (q.contains('yakın') || q.contains('etraf') || q.contains('çevre')) {
      return MessageModel.bot(
        '$cityName\'da bulunduğun konuma göre en yakın noktalar değişir. '
        'Ama şu iki yer her zaman popüler:',
        cards: [
          (city['places'] as List<CardData>).first,
          (city['food'] as List<CardData>).first,
        ],
      );
    }

    // Genel cevap
    final tips = {
      'Antalya': 'Kaleiçi\'nde akşam yürüyüşü yap, Köprülü Kanyon\'da rafting dene!',
      'Atina': 'Akropolis\'i sabah 8\'de ziyaret et, Plaka\'da kaybol!',
      'Roma': 'Trastevere\'de gece yürüyüşü yap, Trevi\'ye gece git!',
      'Budapeşte': 'Széchenyi\'de termal ban, akşam Tuna turu yap!',
    };

    return MessageModel.bot(
      '${tips[cityName] ?? "$cityName harika bir seçim!"}\n\n'
      'Yemek 🍽️, gezilecek yerler 🏛️, ulaşım 🚌, para 💰 veya acil durum 🚨 '
      'hakkında soru sorabilirsin!',
    );
  }

  static List<String> getQuickReplies(String cityName) {
    return [
      '🍽️ Bütçe dostu yemek',
      '🏛️ Görülecek yerler',
      '🚌 Ulaşım nasıl?',
      '💰 Para birimi?',
      '🚨 Acil durum',
      '🌤️ Hava nasıl?',
      '📍 Yakınımda ne var?',
    ];
  }
}