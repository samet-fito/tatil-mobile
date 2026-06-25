/// GetYourGuide partner seçkisi — uygulama içi gezinti için zengin aktivite kataloğu.
abstract final class GygActivityCatalog {
  static final _byCity = <String, List<Map<String, dynamic>>>{
    'Amsterdam': _amsterdam,
    'Paris': _paris,
    'Roma': _roma,
    'Barselona': _barcelona,
    'Barcelona': _barcelona,
    'Atina': _athens,
    'Budapeşte': _budapest,
    'Lizbon': _lisbon,
    'Lisbon': _lisbon,
    'Dubai': _dubai,
    'Londra': _london,
    'London': _london,
    'Berlin': _berlin,
    'Antalya': _antalya,
    'İstanbul': _istanbul,
    'Istanbul': _istanbul,
  };

  static const _byIata = <String, String>{
    'AMS': 'Amsterdam',
    'CDG': 'Paris',
    'ORY': 'Paris',
    'FCO': 'Roma',
    'BCN': 'Barcelona',
    'ATH': 'Atina',
    'BUD': 'Budapeşte',
    'LIS': 'Lizbon',
    'DXB': 'Dubai',
    'LHR': 'Londra',
    'BER': 'Berlin',
    'AYT': 'Antalya',
    'IST': 'İstanbul',
    'SAW': 'İstanbul',
  };

  /// Şehir veya IATA için katalog aktiviteleri; yoksa `null`.
  static List<Map<String, dynamic>>? forCity(String cityName, String iata) {
    final direct = _byCity[cityName];
    if (direct != null) return List<Map<String, dynamic>>.from(direct);

    final viaIata = _byIata[iata.toUpperCase()];
    if (viaIata != null) {
      final list = _byCity[viaIata];
      if (list != null) return List<Map<String, dynamic>>.from(list);
    }

    for (final entry in _byCity.entries) {
      if (entry.key.toLowerCase() == cityName.toLowerCase()) {
        return List<Map<String, dynamic>>.from(entry.value);
      }
    }
    return null;
  }

  static Map<String, dynamic> _act({
    required String id,
    required String category,
    required String title,
    required String description,
    required String detail,
    required String duration,
    required double rating,
    required int reviewCount,
    required int priceTL,
    required String imageUrl,
    required List<String> highlights,
    String inclusions = '',
    String exclusions = '',
    String cancellationPolicy = 'Deneyimden 24 saat öncesine kadar ücretsiz iptal',
    String? gygSearchQuery,
  }) {
    return {
      'id': id,
      'category': category,
      'source': 'catalog',
      'title': title,
      'description': description,
      'detail': detail,
      'duration': duration,
      'rating': rating,
      'reviewCount': reviewCount,
      'priceTL': priceTL,
      'imageUrl': imageUrl,
      'highlights': highlights,
      'inclusions': inclusions,
      'exclusions': exclusions,
      'cancellationPolicy': cancellationPolicy,
      'freeCancellation': true,
      'isPartner': true,
      'commissionRate': 0.08,
      if (gygSearchQuery != null) 'gygSearchQuery': gygSearchQuery,
    };
  }

  static final _amsterdam = [
    _act(
      id: 'ams-canal',
      category: 'tours',
      title: 'Amsterdam Kanal Tekne Turu',
      description: 'UNESCO kanallarında rehberli tekne gezisi',
      detail:
          'Amsterdam\'ın ikonik kanallarında 75 dakikalık rehberli tekne turu. '
          '17. yüzyıl evleri, köprüler ve şehrin hikayesini dinleyin. '
          'Sesli rehber Türkçe dahil birçok dilde mevcuttur.',
      duration: '1,5 saat',
      rating: 4.8,
      reviewCount: 12400,
      priceTL: 950,
      imageUrl:
          'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800',
      highlights: ['UNESCO kanalları', 'Sesli rehber', 'Anında onay'],
      inclusions: 'Tekne turu, sesli rehber',
      gygSearchQuery: 'Amsterdam canal cruise',
    ),
    _act(
      id: 'ams-rijks',
      category: 'museums',
      title: 'Rijksmuseum Giriş Bileti',
      description: 'Rembrandt ve Hollanda Altın Çağı başyapıtları',
      detail:
          'Hollanda\'nın en önemli sanat müzesinde Rembrandt\'ın Gece Devriyesi '
          've Vermeer eserlerini görün. Mobil bilet ile kuyruk beklemeden giriş.',
      duration: '2–3 saat',
      rating: 4.9,
      reviewCount: 8900,
      priceTL: 1100,
      imageUrl:
          'https://images.unsplash.com/photo-1564399579883-451a5d44ec08?w=800',
      highlights: ['Rembrandt', 'Mobil bilet', 'Kuyruk atlama'],
      gygSearchQuery: 'Rijksmuseum ticket Amsterdam',
    ),
    _act(
      id: 'ams-anne',
      category: 'museums',
      title: 'Anne Frank Evi & Müze Turu',
      description: 'Tarihi müze ve Yahudi mahallesi yürüyüşü',
      detail:
          'Anne Frank\'ın saklandığı evi ziyaret edin ve rehber eşliğinde '
          'Jodenbuurt mahallesinin tarihini keşfedin.',
      duration: '2 saat',
      rating: 4.7,
      reviewCount: 5600,
      priceTL: 1350,
      imageUrl:
          'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
      highlights: ['Rehberli tur', 'Tarihi mahalle', 'Mobil bilet'],
      gygSearchQuery: 'Anne Frank House Amsterdam',
    ),
    _act(
      id: 'ams-bike',
      category: 'tours',
      title: 'Amsterdam Bisiklet Şehir Turu',
      description: 'Yerel rehberle bisikletli keşif',
      detail:
          'Amsterdam\'ı bir yerel gibi bisikletle gezin. Jordaan, Vondelpark '
          've gizli köşeleri keşfedin. Bisiklet ve rehber dahil.',
      duration: '3 saat',
      rating: 4.6,
      reviewCount: 3200,
      priceTL: 780,
      imageUrl:
          'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800',
      highlights: ['Bisiklet dahil', 'Küçük grup', 'Yerel rehber'],
      gygSearchQuery: 'Amsterdam bike tour',
    ),
    _act(
      id: 'ams-food',
      category: 'food',
      title: 'Amsterdam Yemek & Peynir Tadım Turu',
      description: 'Hollanda peyniri, haring ve sokak lezzetleri',
      detail:
          'Albert Cuyp pazarı ve yerel mekanlarda Hollanda mutfağını tadın. '
          'Gouda, stroopwafel ve taze haring dahil.',
      duration: '3 saat',
      rating: 4.8,
      reviewCount: 2100,
      priceTL: 1200,
      imageUrl:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      highlights: ['Yerel tadımlar', 'Rehberli', 'Küçük grup'],
      gygSearchQuery: 'Amsterdam food tour',
    ),
  ];

  static final _paris = [
    _act(
      id: 'par-eiffel',
      category: 'tours',
      title: 'Eiffel Kulesi Üst Kat Bileti',
      description: 'Asansörle zirveye çıkış, şehir manzarası',
      detail: 'Eiffel Kulesi\'nin en üst katına asansörle çıkın. Paris\'in '
          '360° panoramik manzarasını deneyimleyin.',
      duration: '2 saat',
      rating: 4.7,
      reviewCount: 22000,
      priceTL: 1450,
      imageUrl:
          'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800',
      highlights: ['Zirve erişimi', 'Mobil bilet', 'Manzara'],
      gygSearchQuery: 'Eiffel Tower ticket Paris',
    ),
    _act(
      id: 'par-louvre',
      category: 'museums',
      title: 'Louvre Müzesi Giriş Bileti',
      description: 'Mona Lisa ve dünya sanat hazineleri',
      detail: 'Dünyanın en büyük sanat müzelerinden Louvre\'da Mona Lisa, '
          'Venüs de Milo ve binlerce eseri görün.',
      duration: '3 saat',
      rating: 4.8,
      reviewCount: 18500,
      priceTL: 1280,
      imageUrl:
          'https://images.unsplash.com/photo-1564399579883-451a5d44ec08?w=800',
      highlights: ['Mona Lisa', 'Kuyruk atlama', 'Mobil bilet'],
      gygSearchQuery: 'Louvre Museum ticket',
    ),
    _act(
      id: 'par-seine',
      category: 'tours',
      title: 'Seine Nehri Akşam Tekne Turu',
      description: 'Işıklı Paris ve akşam yemeği seçeneği',
      detail: 'Seine\'de akşam tekne turu ile aydınlatılmış Paris\'i izleyin. '
          'İsteğe bağlı akşam yemeği menüsü.',
      duration: '2,5 saat',
      rating: 4.6,
      reviewCount: 9800,
      priceTL: 1100,
      imageUrl:
          'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=800',
      highlights: ['Akşam turu', 'Manzara', 'Romantik'],
      gygSearchQuery: 'Seine river cruise Paris',
    ),
    _act(
      id: 'par-versailles',
      category: 'museums',
      title: 'Versailles Sarayı Günübirlik Tur',
      description: 'Saray, bahçeler ve Aynalı Salon',
      detail: 'Versailles\'a gidiş-dönüş transfer ve rehberli saray turu. '
          'Bahçeler ve Marie Antoinette köyü dahil.',
      duration: '7 saat',
      rating: 4.7,
      reviewCount: 7200,
      priceTL: 2200,
      imageUrl:
          'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=800',
      highlights: ['Transfer dahil', 'Rehberli', 'Bahçeler'],
      gygSearchQuery: 'Versailles day trip Paris',
    ),
  ];

  static final _roma = [
    _act(
      id: 'rom-colosseum',
      category: 'museums',
      title: 'Kolosseum & Forum Romanum Bileti',
      description: 'Öncelikli giriş ve arena katı',
      detail: 'Kolosseum, Forum Romanum ve Palatine Tepesi için öncelikli '
          'giriş bileti. Arena katına özel erişim seçeneği.',
      duration: '3 saat',
      rating: 4.9,
      reviewCount: 28000,
      priceTL: 1850,
      imageUrl:
          'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800',
      highlights: ['Öncelikli giriş', 'Arena erişimi', 'Mobil bilet'],
      gygSearchQuery: 'Colosseum ticket Rome',
    ),
    _act(
      id: 'rom-vatican',
      category: 'museums',
      title: 'Vatikan Müzesi & Sistine Şapeli',
      description: 'Rehberli öncelikli giriş turu',
      detail: 'Vatikan Müzeleri ve Michelangelo\'nun Sistine Şapeli\'ni '
          'rehber eşliğinde ziyaret edin.',
      duration: '3 saat',
      rating: 4.9,
      reviewCount: 21000,
      priceTL: 2400,
      imageUrl:
          'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
      highlights: ['Sistine Şapeli', 'Rehberli', 'Kuyruk atlama'],
      gygSearchQuery: 'Vatican Museums ticket',
    ),
    _act(
      id: 'rom-food',
      category: 'food',
      title: 'Roma Trastevere Yemek Turu',
      description: 'Pizza, pasta ve gelato tadımları',
      detail: 'Trastevere\'nin dar sokaklarında yerel lezzetleri keşfedin. '
          '5 duraklı tadım turu.',
      duration: '3,5 saat',
      rating: 4.8,
      reviewCount: 4500,
      priceTL: 1350,
      imageUrl:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      highlights: ['Yerel lezzetler', 'Küçük grup', 'Rehberli'],
      gygSearchQuery: 'Rome food tour Trastevere',
    ),
    _act(
      id: 'rom-city',
      category: 'tours',
      title: 'Roma Gece Işıkları Turu',
      description: 'Fontana di Trevi ve Pantheon akşam turu',
      detail: 'Roma\'nın en ünlü anıtlarını akşam ışıkları altında görün. '
          'Yürüyüş turu, rehber dahil.',
      duration: '2 saat',
      rating: 4.7,
      reviewCount: 3800,
      priceTL: 890,
      imageUrl:
          'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800',
      highlights: ['Akşam turu', 'Fotoğraf durakları', 'Rehberli'],
      gygSearchQuery: 'Rome night tour',
    ),
  ];

  static final _barcelona = [
    _act(
      id: 'bcn-sagrada',
      category: 'museums',
      title: 'Sagrada Familia Giriş Bileti',
      description: 'Gaudí\'nin başyapıtı, kule erişimi',
      detail: 'Sagrada Familia\'ya öncelikli giriş ve isteğe bağlı kule '
          'çıkışı. Sesli rehber dahil.',
      duration: '2 saat',
      rating: 4.8,
      reviewCount: 19000,
      priceTL: 1650,
      imageUrl:
          'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
      highlights: ['Gaudí', 'Mobil bilet', 'Sesli rehber'],
      gygSearchQuery: 'Sagrada Familia ticket',
    ),
    _act(
      id: 'bcn-park',
      category: 'tours',
      title: 'Park Güell & Gaudí Turu',
      description: 'Rehberli mimari keşif turu',
      detail: 'Park Güell ve Casa Batlló çevresinde Gaudí mimarisini '
          'rehber eşliğinde keşfedin.',
      duration: '3 saat',
      rating: 4.7,
      reviewCount: 8200,
      priceTL: 1200,
      imageUrl:
          'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=800',
      highlights: ['Gaudí rotası', 'Rehberli', 'Fotoğraf'],
      gygSearchQuery: 'Park Guell tour Barcelona',
    ),
    _act(
      id: 'bcn-tapas',
      category: 'food',
      title: 'Barselona Tapas & Şarap Turu',
      description: 'Gotik Mahalle lezzet durakları',
      detail: 'El Born ve Gotik Mahalle\'de tapas, paella ve Katalan şarap '
          'tadımları.',
      duration: '3 saat',
      rating: 4.8,
      reviewCount: 5100,
      priceTL: 1100,
      imageUrl:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      highlights: ['Tapas', 'Şarap', 'Yerel mekanlar'],
      gygSearchQuery: 'Barcelona tapas tour',
    ),
    _act(
      id: 'bcn-beach',
      category: 'adventure',
      title: 'Barcelona Kıyı Bisiklet Turu',
      description: 'Sahil şeridi ve Barceloneta',
      detail: 'Barceloneta sahili boyunca bisiklet turu. Bisiklet ve rehber '
          'dahil, fotoğraf molaları.',
      duration: '2,5 saat',
      rating: 4.6,
      reviewCount: 2900,
      priceTL: 750,
      imageUrl:
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
      highlights: ['Sahil', 'Bisiklet dahil', 'Açık hava'],
      gygSearchQuery: 'Barcelona bike tour beach',
    ),
  ];

  static final _athens = [
    _act(
      id: 'ath-acropolis',
      category: 'museums',
      title: 'Akropolis & Parthenon Bileti',
      description: 'Öncelikli giriş ve müze kombine',
      detail: 'Akropolis, Parthenon ve Akropolis Müzesi kombine bileti. '
          'Sabah erken giriş seçeneği.',
      duration: '3 saat',
      rating: 4.9,
      reviewCount: 15000,
      priceTL: 1400,
      imageUrl:
          'https://images.unsplash.com/photo-1555993539-1732b0258235?w=800',
      highlights: ['Parthenon', 'Müze dahil', 'Öncelikli giriş'],
      gygSearchQuery: 'Acropolis ticket Athens',
    ),
    _act(
      id: 'ath-food',
      category: 'food',
      title: 'Atina Sokak Yemek Turu',
      description: 'Souvlaki, loukoumades ve yerel pazar',
      detail: 'Monastiraki ve Psyrri\'de Yunan sokak lezzetlerini tadın.',
      duration: '3 saat',
      rating: 4.8,
      reviewCount: 4200,
      priceTL: 980,
      imageUrl:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      highlights: ['Sokak lezzetleri', 'Rehberli', 'Küçük grup'],
      gygSearchQuery: 'Athens food tour',
    ),
    _act(
      id: 'ath-sunset',
      category: 'tours',
      title: 'Atina Gün Batımı Akropolis Turu',
      description: 'Rehberli akşam yürüyüşü',
      detail: 'Akropolis çevresinde gün batımı yürüyüş turu. '
          'Fotoğraf durakları ve tarih anlatımı.',
      duration: '2 saat',
      rating: 4.7,
      reviewCount: 3100,
      priceTL: 850,
      imageUrl:
          'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800',
      highlights: ['Gün batımı', 'Rehberli', 'Fotoğraf'],
      gygSearchQuery: 'Athens sunset Acropolis tour',
    ),
    _act(
      id: 'ath-cruise',
      category: 'tours',
      title: 'Saronic Adaları Tekne Turu',
      description: 'Aegina ve Hydra günübirlik gezi',
      detail: 'Ege\'de üç adaya tekne turu. Öğle yemeği ve yüzme molaları.',
      duration: '10 saat',
      rating: 4.6,
      reviewCount: 2800,
      priceTL: 1650,
      imageUrl:
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
      highlights: ['Ada turu', 'Öğle yemeği', 'Yüzme'],
      gygSearchQuery: 'Athens island cruise',
    ),
  ];

  static final _budapest = [
    _act(
      id: 'bud-spa',
      category: 'adventure',
      title: 'Széchenyi Termal Banyo Girişi',
      description: 'Tarihi kaplıca deneyimi',
      detail: 'Avrupa\'nın en büyük termal banyolarından Széchenyi\'de '
          'rahatlayın. Fast track giriş.',
      duration: '3 saat',
      rating: 4.8,
      reviewCount: 9800,
      priceTL: 720,
      imageUrl:
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
      highlights: ['Termal banyo', 'Fast track', 'Havuzlar'],
      gygSearchQuery: 'Szechenyi Baths Budapest',
    ),
    _act(
      id: 'bud-danube',
      category: 'tours',
      title: 'Tuna Nehri Akşam Tekne Turu',
      description: 'Işıklı Parlamento ve zincirli köprü',
      detail: 'Tuna\'da akşam tekne turu ile Budapeşte\'nin siluetini izleyin.',
      duration: '1,5 saat',
      rating: 4.7,
      reviewCount: 6500,
      priceTL: 680,
      imageUrl:
          'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=800',
      highlights: ['Akşam turu', 'Parlamento manzarası', 'İçecek'],
      gygSearchQuery: 'Danube river cruise Budapest',
    ),
    _act(
      id: 'bud-ruin',
      category: 'food',
      title: 'Budapeşte Ruin Bar Turu',
      description: 'Yerel barlar ve macar şnaps tadımı',
      detail: 'Yahudi Mahallesi ruin barlarında rehberli gece turu.',
      duration: '3 saat',
      rating: 4.6,
      reviewCount: 3200,
      priceTL: 890,
      imageUrl:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      highlights: ['Ruin barlar', 'Tadım', 'Yerel rehber'],
      gygSearchQuery: 'Budapest ruin bar tour',
    ),
    _act(
      id: 'bud-parliament',
      category: 'museums',
      title: 'Macar Parlamentosu İç Tur',
      description: 'Rehberli saray ve taç mücevherleri',
      detail: 'Neo-Gotik Parlamento binasında rehberli iç tur.',
      duration: '1 saat',
      rating: 4.8,
      reviewCount: 7800,
      priceTL: 950,
      imageUrl:
          'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
      highlights: ['Parlamento', 'Rehberli', 'Taç mücevherleri'],
      gygSearchQuery: 'Budapest Parliament tour',
    ),
  ];

  static final _lisbon = [
    _act(
      id: 'lis-tram',
      category: 'tours',
      title: 'Lizbon Sarı Tramvay & Alfama Turu',
      description: '28 numaralı tramvay ve yürüyüş',
      detail: 'İkonik 28 tramvayı ve Alfama\'nın dar sokaklarını keşfedin.',
      duration: '3 saat',
      rating: 4.7,
      reviewCount: 7200,
      priceTL: 820,
      imageUrl:
          'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800',
      highlights: ['Tramvay', 'Alfama', 'Rehberli'],
      gygSearchQuery: 'Lisbon tram tour Alfama',
    ),
    _act(
      id: 'lis-belem',
      category: 'museums',
      title: 'Belém Kulesi & Jerónimos Manastırı',
      description: 'Kombine bilet ve rehberli tur',
      detail: 'UNESCO mirası Belém bölgesini rehber eşliğinde gezin.',
      duration: '3 saat',
      rating: 4.8,
      reviewCount: 8900,
      priceTL: 1050,
      imageUrl:
          'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
      highlights: ['UNESCO', 'Pastéis de Belém', 'Rehberli'],
      gygSearchQuery: 'Belem Tower Lisbon ticket',
    ),
    _act(
      id: 'lis-fado',
      category: 'events',
      title: 'Lizbon Fado Gecesi & Akşam Yemeği',
      description: 'Canlı fado ve geleneksel yemek',
      detail: 'Bairro Alto\'da canlı fado performansı ve Portekiz akşam yemeği.',
      duration: '3 saat',
      rating: 4.6,
      reviewCount: 4100,
      priceTL: 1280,
      imageUrl:
          'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800',
      highlights: ['Canlı fado', 'Akşam yemeği', 'Yerel mekan'],
      gygSearchQuery: 'Lisbon fado dinner',
    ),
    _act(
      id: 'lis-sintra',
      category: 'tours',
      title: 'Sintra & Pena Sarayı Günübirlik',
      description: 'Transfer ve rehberli saray turu',
      detail: 'Pena Sarayı, Quinta da Regaleira ve Cascais sahil durağı.',
      duration: '8 saat',
      rating: 4.8,
      reviewCount: 5600,
      priceTL: 1750,
      imageUrl:
          'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=800',
      highlights: ['Pena Sarayı', 'Transfer', 'Rehberli'],
      gygSearchQuery: 'Sintra day trip Lisbon',
    ),
  ];

  static final _dubai = [
    _act(
      id: 'dxb-burj',
      category: 'tours',
      title: 'Burj Khalifa 124. Kat Bileti',
      description: 'Dünyanın en yüksek binası manzarası',
      detail: 'Burj Khalifa gözlem güvertesine öncelikli giriş. '
          'Dubai Fountain gösterisi dahil.',
      duration: '2 saat',
      rating: 4.8,
      reviewCount: 14000,
      priceTL: 1550,
      imageUrl:
          'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800',
      highlights: ['Manzara', 'Fountain', 'Mobil bilet'],
      gygSearchQuery: 'Burj Khalifa ticket',
    ),
    _act(
      id: 'dxb-desert',
      category: 'adventure',
      title: 'Çöl Safari & BBQ Akşam Yemeği',
      description: '4x4 safari, deve binme ve akşam şov',
      detail: 'Dubai çölünde dune bashing, deve binme ve Bedevi kampında '
          'barbekü akşam yemeği.',
      duration: '6 saat',
      rating: 4.7,
      reviewCount: 11200,
      priceTL: 1350,
      imageUrl:
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
      highlights: ['Safari', 'BBQ', 'Gün batımı'],
      gygSearchQuery: 'Dubai desert safari',
    ),
    _act(
      id: 'dxb-marina',
      category: 'tours',
      title: 'Dubai Marina Tekne Turu',
      description: 'Gökdelenler ve Palm Jumeirah manzarası',
      detail: 'Marina ve JBR sahil şeridinde tekne turu.',
      duration: '1,5 saat',
      rating: 4.6,
      reviewCount: 6800,
      priceTL: 780,
      imageUrl:
          'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800',
      highlights: ['Marina', 'Manzara', 'Fotoğraf'],
      gygSearchQuery: 'Dubai Marina cruise',
    ),
    _act(
      id: 'dxb-old',
      category: 'tours',
      title: 'Eski Dubai & Souk Turu',
      description: 'Al Fahidi, Gold Souk ve abra tekne',
      detail: 'Tarihi Al Fahidi mahallesi, baharat ve altın çarşıları.',
      duration: '4 saat',
      rating: 4.7,
      reviewCount: 3900,
      priceTL: 920,
      imageUrl:
          'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800',
      highlights: ['Eski Dubai', 'Souk', 'Abra tekne'],
      gygSearchQuery: 'Old Dubai tour',
    ),
  ];

  static final _london = [
    _act(
      id: 'lon-eye',
      category: 'tours',
      title: 'London Eye Fast Track Bileti',
      description: 'Thames manzarası, 30 dakika tur',
      detail: 'London Eye\'da fast track giriş ile Thames ve şehir manzarası.',
      duration: '1 saat',
      rating: 4.6,
      reviewCount: 16000,
      priceTL: 1380,
      imageUrl:
          'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800',
      highlights: ['Fast track', 'Manzara', 'Mobil bilet'],
      gygSearchQuery: 'London Eye ticket',
    ),
    _act(
      id: 'lon-tower',
      category: 'museums',
      title: 'Tower of London & Taç Mücevherleri',
      description: 'Yeoman rehberli tur',
      detail: 'Tower of London\'da Taç Mücevherleri ve Beefeaters turu.',
      duration: '3 saat',
      rating: 4.8,
      reviewCount: 12500,
      priceTL: 1650,
      imageUrl:
          'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
      highlights: ['Taç mücevherleri', 'Rehberli', 'Tarih'],
      gygSearchQuery: 'Tower of London ticket',
    ),
    _act(
      id: 'lon-harry',
      category: 'tours',
      title: 'Harry Potter Studio Turu',
      description: 'Warner Bros. stüdyo transferi',
      detail: 'Leavesden stüdyolarında Harry Potter setleri ve sihirli dünya.',
      duration: '7 saat',
      rating: 4.9,
      reviewCount: 9800,
      priceTL: 2100,
      imageUrl:
          'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=800',
      highlights: ['Transfer', 'Stüdyo turu', 'Film setleri'],
      gygSearchQuery: 'Harry Potter studio tour London',
    ),
    _act(
      id: 'lon-food',
      category: 'food',
      title: 'Borough Market Yemek Turu',
      description: 'Londra sokak lezzetleri ve çay',
      detail: 'Borough Market ve Southwark\'ta İngiliz ve dünya mutfağı tadımları.',
      duration: '3 saat',
      rating: 4.7,
      reviewCount: 4200,
      priceTL: 1150,
      imageUrl:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      highlights: ['Borough Market', 'Tadımlar', 'Rehberli'],
      gygSearchQuery: 'Borough Market food tour London',
    ),
  ];

  static final _berlin = [
    _act(
      id: 'ber-wall',
      category: 'tours',
      title: 'Berlin Duvarı & Soğuk Savaş Turu',
      description: 'Yürüyüş turu ve Checkpoint Charlie',
      detail: 'Doğu-Batı Berlin tarihini rehber eşliğinde keşfedin.',
      duration: '3 saat',
      rating: 4.8,
      reviewCount: 8700,
      priceTL: 780,
      imageUrl:
          'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800',
      highlights: ['Duvar tarihi', 'Rehberli', 'Yürüyüş'],
      gygSearchQuery: 'Berlin Wall tour',
    ),
    _act(
      id: 'ber-museum',
      category: 'museums',
      title: 'Museum Island Kombine Bilet',
      description: 'Pergamon ve Neues Müzesi',
      detail: 'Müze Adası\'ndaki 5 müzeye 1 günlük kombine giriş.',
      duration: '4 saat',
      rating: 4.7,
      reviewCount: 6200,
      priceTL: 1180,
      imageUrl:
          'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
      highlights: ['Müze Adası', 'Kombine bilet', 'Nefertiti'],
      gygSearchQuery: 'Museum Island Berlin ticket',
    ),
    _act(
      id: 'ber-reich',
      category: 'museums',
      title: 'Reichstag Kubbe Rezervasyonu',
      description: 'Parlamento kubbe manzarası',
      detail: 'Reichstag kubbesinde ücretsiz rehberli tur rezervasyonu.',
      duration: '1,5 saat',
      rating: 4.6,
      reviewCount: 9100,
      priceTL: 0,
      imageUrl:
          'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=800',
      highlights: ['Ücretsiz', 'Manzara', 'Rezervasyon'],
      gygSearchQuery: 'Reichstag dome Berlin',
    ),
    _act(
      id: 'ber-food',
      category: 'food',
      title: 'Berlin Street Food & Craft Beer Turu',
      description: 'Kreuzberg lezzet durakları',
      detail: 'Currywurst, döner ve craft beer tadımları Kreuzberg\'de.',
      duration: '3 saat',
      rating: 4.7,
      reviewCount: 3400,
      priceTL: 950,
      imageUrl:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      highlights: ['Sokak yemeği', 'Craft beer', 'Kreuzberg'],
      gygSearchQuery: 'Berlin food tour',
    ),
  ];

  static final _antalya = [
    _act(
      id: 'ayt-rafting',
      category: 'adventure',
      title: 'Köprülü Kanyon Rafting',
      description: 'Rehberli nehir rafting macerası',
      detail: 'Köprüçay\'da tam gün rafting, öğle yemeği ve transfer dahil.',
      duration: '8 saat',
      rating: 4.8,
      reviewCount: 4200,
      priceTL: 1100,
      imageUrl:
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
      highlights: ['Rafting', 'Transfer', 'Öğle yemeği'],
      gygSearchQuery: 'Koprulu Canyon rafting Antalya',
    ),
    _act(
      id: 'ayt-old',
      category: 'tours',
      title: 'Kaleiçi & Düden Şelalesi Turu',
      description: 'Tarihi merkez ve şelale',
      detail: 'Antalya Kaleiçi yürüyüşü ve Düden Şelalesi ziyareti.',
      duration: '4 saat',
      rating: 4.6,
      reviewCount: 2800,
      priceTL: 650,
      imageUrl:
          'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800',
      highlights: ['Kaleiçi', 'Şelale', 'Rehberli'],
      gygSearchQuery: 'Antalya old town tour',
    ),
    _act(
      id: 'ayt-boat',
      category: 'tours',
      title: 'Antalya Tekne Turu & Yüzme Molaları',
      description: 'Akdeniz koyları ve öğle yemeği',
      detail: 'Kekova ve Phaselis koylarında tekne turu.',
      duration: '7 saat',
      rating: 4.7,
      reviewCount: 3600,
      priceTL: 890,
      imageUrl:
          'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800',
      highlights: ['Tekne', 'Yüzme', 'Öğle yemeği'],
      gygSearchQuery: 'Antalya boat tour',
    ),
    _act(
      id: 'ayt-museum',
      category: 'museums',
      title: 'Antalya Müzesi Rehberli Tur',
      description: 'Arkeoloji ve Likya hazineleri',
      detail: 'Türkiye\'nin en önemli arkeoloji müzelerinden birinde rehberli tur.',
      duration: '2 saat',
      rating: 4.5,
      reviewCount: 1200,
      priceTL: 420,
      imageUrl:
          'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
      highlights: ['Arkeoloji', 'Rehberli', 'Likya'],
      gygSearchQuery: 'Antalya Museum tour',
    ),
  ];

  static final _istanbul = [
    _act(
      id: 'ist-hagia',
      category: 'museums',
      title: 'Ayasofya & Sultanahmet Rehberli Tur',
      description: 'Tarihi yarımada yürüyüş turu',
      detail: 'Ayasofya, Sultanahmet Camii ve Hipodrom rehberli tur.',
      duration: '3 saat',
      rating: 4.9,
      reviewCount: 8900,
      priceTL: 950,
      imageUrl:
          'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800',
      highlights: ['Ayasofya', 'Rehberli', 'Tarihi yarımada'],
      gygSearchQuery: 'Hagia Sophia tour Istanbul',
    ),
    _act(
      id: 'ist-bosphorus',
      category: 'tours',
      title: 'Boğaz Tekne Turu',
      description: 'Avrupa-Asya kıyıları ve köşkler',
      detail: 'Boğaz\'da 2 saatlik tekne turu, Dolmabahçe ve Rumeli Hisarı manzarası.',
      duration: '2 saat',
      rating: 4.8,
      reviewCount: 11200,
      priceTL: 580,
      imageUrl:
          'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800',
      highlights: ['Boğaz', 'Manzara', 'Tekne'],
      gygSearchQuery: 'Bosphorus cruise Istanbul',
    ),
    _act(
      id: 'ist-food',
      category: 'food',
      title: 'İstanbul Sokak Lezzet Turu',
      description: 'Kadıköy ve Eminönü tadımları',
      detail: 'Balık ekmek, börek, lokum ve Türk kahvesi tadımları.',
      duration: '3,5 saat',
      rating: 4.8,
      reviewCount: 5400,
      priceTL: 1100,
      imageUrl:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      highlights: ['Sokak lezzetleri', 'Rehberli', 'Yerel mekanlar'],
      gygSearchQuery: 'Istanbul food tour',
    ),
    _act(
      id: 'ist-topkapi',
      category: 'museums',
      title: 'Topkapı Sarayı & Harem Bileti',
      description: 'Osmanlı sarayı ve hazine',
      detail: 'Topkapı Sarayı, Harem dairesi ve Kutsal Emanetler.',
      duration: '3 saat',
      rating: 4.7,
      reviewCount: 7600,
      priceTL: 1250,
      imageUrl:
          'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
      highlights: ['Harem', 'Hazine', 'Mobil bilet'],
      gygSearchQuery: 'Topkapi Palace ticket Istanbul',
    ),
  ];
}
