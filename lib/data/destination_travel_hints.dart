import '../models/personalized_guide_model.dart';
import '../data/holiday_types.dart';
import '../utils/traveler_group_profile.dart';

/// AI başarısız olduğunda kullanılan destinasyon bazlı pratik rehber.
class DestinationTravelHints {
  DestinationTravelHints._();

  static PersonalizedGuide build({
    required String iata,
    required String cityName,
    required String country,
    required int nights,
    required int travelers,
    TravelerGroupProfile? groupProfile,
    List<String> holidayTypes = const [],
  }) {
    final key = iata.toUpperCase();
    final builder = _byIata[key] ?? _generic;
    var guide = builder(cityName, country, nights, travelers);
    guide = _personalizeFallback(
      guide,
      cityName: cityName,
      groupProfile: groupProfile,
      holidayTypes: holidayTypes,
    );
    return guide;
  }

  static PersonalizedGuide _personalizeFallback(
    PersonalizedGuide guide, {
    required String cityName,
    TravelerGroupProfile? groupProfile,
    List<String> holidayTypes = const [],
  }) {
    if (groupProfile == null && holidayTypes.isEmpty) return guide;

    final interestLabel = holidayTypes.isNotEmpty
        ? HolidayTypes.labelsOf(holidayTypes).join(', ')
        : null;

    final headline = groupProfile != null
        ? '${groupProfile.groupType.label} için $cityName rehberi'
        : guide.headline;

    final subtitleParts = <String>[];
    if (groupProfile != null) subtitleParts.add(groupProfile.summaryLabel);
    if (interestLabel != null) subtitleParts.add(interestLabel);
    if (subtitleParts.isEmpty) return guide.copyWith(headline: headline);

    return guide.copyWith(
      headline: headline,
      subtitle: subtitleParts.join(' · '),
    );
  }

  static final Map<String, PersonalizedGuide Function(
    String city,
    String country,
    int nights,
    int travelers,
  )> _byIata = {
    'DXB': _dubai,
    'AYT': _antalya,
    'IST': _istanbul,
    'SAW': _istanbul,
    'FCO': _rome,
    'ATH': _athens,
    'CDG': _paris,
    'LHR': _london,
  };

  static PersonalizedGuide _dubai(
    String city,
    String country,
    int nights,
    int travelers,
  ) {
    return PersonalizedGuide(
      headline: '$city\'da ne yapmalısın?',
      subtitle: '$nights gece · $travelers kişi · BAE pratik rehberi',
      sections: [
        _section(GuideSectionKind.mustDo, [
          'Burj Khalifa ve Dubai Fountain akşam gösterisi — biletleri önceden alın, gün batımı slotu ideal.',
          'Al Fahidi (Eski Dubai) + Abra ile Dubai Creek geçişi — geleneksel mahalle ve baharat çarşısı.',
          'Çöl safarisi (dune bashing + gün batımı) — 4x4 tur, genelde akşam yemeği dahil.',
          'Dubai Marina yürüyüşü veya tekne turu — akşam saatleri serinler.',
          'The View at The Palm veya JBR sahil — Palm Jumeirah manzarası.',
        ]),
        _section(GuideSectionKind.strictRules, [
          'Yapma: Kamusal alanda (sokak, plaj, AVM koridoru) alkol tüketmeyin — sadece lisanslı bar/restoran.',
          'Yapma: AVM, metro ve cami girişlerinde omuz-diz örtülü giyinin; şort ve askılı bluz reddedilebilir.',
          'Yapma: İzinsiz kadınları, polis ve askeri alanları fotoğraflamayın.',
          'Yapma: Ramazan ayında gündüz halka açık yerlerde yeme-içme (turist bölgeleri daha toleranslı olsa da dikkat).',
        ]),
        _section(GuideSectionKind.lifeSavers, [
          'Çöl safarisinde wrap-around gözlük ve ağız-burun buff/maske şart — kum ciddi göz ve solunum sorununa yol açar.',
          'Temmuz–Ağustos 45°C+ olabilir; suyu 15–20 dk\'da bir için, 11:00–15:00 arası açık alan turu planlamayın.',
          'Taksi yerine Uber/Careem kullanın; "turist taksi" ve sahte tur satıcılarına dikkat.',
          'Acil numara: 999 (polis/ambulans/itfaiye).',
        ]),
        _section(GuideSectionKind.packing, [
          'SPF 50+ güneş kremi, şapka, hafif uzun kollu (güneş + klimali mekânlar).',
          'Omuz örtüsü (şal) — cami ve bazı AVM girişleri için.',
          'Tip G priz adaptörü (İngiliz tipi).',
          'Çöl turu için kapalı ayakkabı; plaj için terlik ayrı.',
        ]),
        _section(GuideSectionKind.localTips, [
          'Metro hızlı ve ucuz; Gold Class bileti kalabalıkta rahatlık sağlar.',
          'Cuma öğleden sonra bazı dükkanlar kısa süre kapalı olabilir.',
          'Bahşiş zorunlu değil; iyi hizmet için %10 yaygın.',
          'Havalimanı–merkez: Metro kırmızı hat veya resmi transfer; kapıda "cheap taxi" tekliflerine güvenmeyin.',
        ]),
      ],
    );
  }

  static PersonalizedGuide _antalya(
    String city,
    String country,
    int nights,
    int travelers,
  ) {
    return PersonalizedGuide(
      headline: '$city\'da ne yapmalısın?',
      subtitle: '$nights gece · $travelers kişi · Akdeniz rehberi',
      sections: [
        _section(GuideSectionKind.mustDo, [
          'Kaleiçi ve Hadrian Kapısı — dar sokaklar, tarihi liman.',
          'Düden veya Kurşunlu şelalesi — yarım günü ayırın.',
          'Tekne turu (Kekova / yanartaş veya koy turu) — sezon Mayıs–Ekim ideal.',
          'Antalya Müzesi — bölge arkeolojisi için zengin koleksiyon.',
        ]),
        _section(GuideSectionKind.strictRules, [
          'Yapma: Özel plajlarda dışarıdan yiyecek-içecek sokmayın (işletme kuralı).',
          'Yapma: Antik alanlarda tırmanma ve taş alma — para cezası var.',
        ]),
        _section(GuideSectionKind.lifeSavers, [
          'Temmuz–Ağustos öğle sıcağında plajda güneş çarpması riski — SPF, şapka, su.',
          'Deniz ürünü restoranlarında fiyatı önceden sorun; liman çevresinde turist menüsü tuzakları olabilir.',
          'Acil: 112.',
        ]),
        _section(GuideSectionKind.packing, [
          'Mayo, havlu, su geçirmez telefon kılıfı.',
          'Akşam Kaleiçi için hafif ceket (deniz esintisi).',
          'Rahat yürüyüş ayakkabısı — Kaleiçi taşlı yokuşlar.',
        ]),
        _section(GuideSectionKind.localTips, [
          'Tramvay hattı havalimanı–merkez arasında pratik.',
          'Pazarlık kapalı pazarlarda (Örnekkoy vb.) normal; AVM\'de değil.',
          'Bayram dönemlerinde plaj ve oteller çok kalabalık — erken rezervasyon.',
        ]),
      ],
    );
  }

  static PersonalizedGuide _istanbul(
    String city,
    String country,
    int nights,
    int travelers,
  ) {
    return PersonalizedGuide(
      headline: 'İstanbul\'da ne yapmalısın?',
      subtitle: '$nights gece · $travelers kişi',
      sections: [
        _section(GuideSectionKind.mustDo, [
          'Sultanahmet: Ayasofya, Sultanahmet Camii, Yerebatan — sabah erken gidin.',
          'Galata Kulesi + Karaköy–Galata yürüyüşü.',
          'Boğaz turu veya Kadıköy–Beşiktaş vapur hattı.',
          'Grand Bazaar ve Mısır Çarşısı — pazarlık yapın.',
        ]),
        _section(GuideSectionKind.strictRules, [
          'Yapma: Cami ziyaretinde başörtüsü (kadın), diz altı kapalı (herkes); namaz saatinde turistik gezinti sınırlı olabilir.',
          'Yapma: Taksim/İstiklal\'de izinsiz yüzünüze rozet/çiçek takıp bahşiş isteyenlere izin vermeyin.',
        ]),
        _section(GuideSectionKind.lifeSavers, [
          'Taksimetre açık olmayan taksiye binmeyin; BiTaksi/uber tercih edin.',
          'Turistik restoranlarda "balık seçimi" fiyat tuzağı — menü fiyatını önceden sorun.',
          'Acil: 112.',
        ]),
        _section(GuideSectionKind.packing, [
          'Rahat yürüyüş ayakkabısı — tepe yokuşları çok.',
          'Hafif yağmurluk veya katmanlı giyim (hava hızlı değişir).',
          'Cami ziyareti için omuz örtüsü.',
        ]),
        _section(GuideSectionKind.localTips, [
          'Istanbulkart ile metro/tramvay/vapur tek kart.',
          'Kahvaltı için Beşiktaş/Kadıköy civarı yerel mekânlar.',
          'Cuma namazı öncesi Sultanahmet çok kalabalık.',
        ]),
      ],
    );
  }

  static PersonalizedGuide _rome(
    String city,
    String country,
    int nights,
    int travelers,
  ) =>
      _europeanTemplate(city, 'İtalya', nights, travelers, mustDo: [
        'Colosseum + Roman Forum — bileti online alın, sabah slotu.',
        'Vatican Museums & Sistine Chapel — Cuma hariç sabah erken.',
        'Trastevere akşam yemeği — yerel trattoria.',
        'Fontana di Trevi ve Pantheon — yürüyüş rotası.',
      ], rules: [
        'Yapma: Tarihi yapılara oturmayın veya madeni para atma alanları dışında suya atmayın — ceza var.',
        'Yapma: Restoranlarda oturmadan önce "coperto" (servis) ücretini sorun.',
      ], life: [
        'Kapkaç ve turist bölgelerinde cüzdan/telefon görünür tutmayın.',
        'Sıcak yaz günlerinde su şişesi doldurma noktaları (nasoni) ücretsiz.',
      ]);

  static PersonalizedGuide _athens(
    String city,
    String country,
    int nights,
    int travelers,
  ) =>
      _europeanTemplate(city, 'Yunanistan', nights, travelers, mustDo: [
        'Akropolis ve Akropolis Müzesi — sabah erken, güneşten korunun.',
        'Plaka ve Monastiraki — yürüyüş ve taverna.',
        'Lycabettus tepesi gün batımı.',
      ], rules: [
        'Yapma: Akropolis\'te tripod ve büyük çanta kısıtlaması — hafif gidin.',
      ], life: [
        'Metro çok pratik; greve günlerini kontrol edin.',
        'Adalar feribotu için önceden bilet ( yaz sezonu ).',
      ]);

  static PersonalizedGuide _paris(
    String city,
    String country,
    int nights,
    int travelers,
  ) =>
      _europeanTemplate(city, 'Fransa', nights, travelers, mustDo: [
        'Louvre veya Musée d\'Orsay — gün başına bir müze yeter.',
        'Eiffel akşam ışık gösterisi — Champ de Mars\'tan ücretsiz.',
        'Montmartre + Sacré-Cœur — sabah kalabalıksız.',
      ], rules: [
        'Yapma: Metro\'da bilet doğrulamadan binmeyin — yüksek ceza.',
      ], life: [
        'Kapkaç: metro kapıları ve turist noktalarında çantayı önde taşıyın.',
        'Restoranlarda "service compris" fişte yazıyor mu kontrol edin.',
      ]);

  static PersonalizedGuide _london(
    String city,
    String country,
    int nights,
    int travelers,
  ) =>
      _europeanTemplate(city, 'İngiltere', nights, travelers, mustDo: [
        'British Museum veya Tate Modern — ücretsiz ana koleksiyon.',
        'Westminster + Thames yürüyüşü.',
        'Borough Market veya Camden — yemek ve sokak turu.',
      ], rules: [
        'Yapma: Sol şerit (yürüyen merdiven, yaya) — Londra\'da soldan yürüyün.',
      ], life: [
        'Oyster/contactless ile ulaşım; black cab taksimetre zorunlu.',
        'Hava değişken — yağmurluk her zaman.',
      ]);

  static PersonalizedGuide _europeanTemplate(
    String city,
    String country,
    int nights,
    int travelers, {
    required List<String> mustDo,
    required List<String> rules,
    required List<String> life,
  }) {
    return PersonalizedGuide(
      headline: '$city\'da ne yapmalısın?',
      subtitle: '$nights gece · $travelers kişi · $country',
      sections: [
        _section(GuideSectionKind.mustDo, mustDo),
        _section(GuideSectionKind.strictRules, rules),
        _section(GuideSectionKind.lifeSavers, life),
        _section(GuideSectionKind.packing, [
          'Rahat yürüyüş ayakkabısı — günde 15–20 bin adım normal.',
          'Katmanlı giyim; hafif yağmurluk veya şemsiye.',
          'AB prizi için adaptör (Tip C/F; İngiltere Tip G).',
        ]),
        _section(GuideSectionKind.localTips, [
          'Müze ve popüler mekân biletlerini online alın — kuyruk saatler kazandırır.',
          'Acil AB numarası: 112.',
        ]),
      ],
    );
  }

  static PersonalizedGuide _generic(
    String city,
    String country,
    int nights,
    int travelers,
  ) {
    return PersonalizedGuide(
      headline: '$city\'da ne yapmalısın?',
      subtitle: '$nights gece · $travelers kişi · pratik rehber',
      sections: [
        _section(GuideSectionKind.mustDo, [
          '$city merkez yürüyüş turu — ilk gün şehir planını çıkarın.',
          'Yerel pazar veya food hall — bölge mutfağını deneyin.',
          'Şehir müzesi veya en popüler tarihi nokta — 1 yarım gün ayırın.',
        ]),
        _section(GuideSectionKind.strictRules, [
          'Yapma: Turist bölgelerinde pasaport ve değerli eşyayı görünür bırakmayın.',
          'Yerel kültür ve dini mekânlarda giyim kurallarına uyun (omuz-diz kapalı).',
        ]),
        _section(GuideSectionKind.lifeSavers, [
          'Resmi taksi veya uygulama tabanlı ulaşım kullanın; sokakta "özel tur" tekliflerine dikkat.',
          'Seyahat sigortası ve pasaport fotokopisi (bulutta) bulundurun.',
          'Acil numarayı varışta kaydedin (çoğu ülkede 112).',
        ]),
        _section(GuideSectionKind.packing, [
          'Rahat ayakkabı, günlük sırt çantası, powerbank.',
          'Mevsime göre katmanlı giyim ve yağmurluk.',
        ]),
        _section(GuideSectionKind.localTips, [
          'Popüler restoran ve aktiviteleri önceden rezerve edin.',
          'Yerel SIM veya eSIM ile harita ve acil iletişim açık tutun.',
        ]),
      ],
    );
  }

  static PersonalizedGuideSection _section(
    GuideSectionKind kind,
    List<String> items,
  ) {
    return PersonalizedGuideSection(
      emoji: kind.defaultEmoji,
      title: kind.defaultTitle,
      kind: kind,
      items: items,
    );
  }
}
