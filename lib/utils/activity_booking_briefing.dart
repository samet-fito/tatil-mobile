/// Seçilen aktivite için alınış saati, kurallar ve kıyafet önerileri.
class ActivityBookingBriefing {
  const ActivityBookingBriefing({
    required this.program,
    required this.pickupTime,
    required this.dropoffTime,
    required this.meetingPoint,
    required this.rules,
    required this.clothingTips,
    required this.warnings,
  });

  final String program;
  final String pickupTime;
  final String dropoffTime;
  final String meetingPoint;
  final List<String> rules;
  final List<String> clothingTips;
  final List<String> warnings;

  static ActivityBookingBriefing fromActivity({
    required Map<String, dynamic> activity,
    required String cityName,
    String category = 'tours',
    DateTime? eventDate,
  }) {
    final title = activity['title'] as String? ?? 'Aktivite';
    final duration = activity['duration'] as String? ?? '3 saat';
    final detail = activity['detail'] as String? ??
        activity['description'] as String? ??
        activity['summary'] as String? ??
        '';
    final highlights = List<String>.from(activity['highlights'] ?? []);
    final seed = title.hashCode ^ cityName.hashCode;
    final day = eventDate ?? DateTime.now().add(const Duration(days: 7));

    final pickupHour = 8 + (seed.abs() % 4);
    final pickup = DateTime(day.year, day.month, day.day, pickupHour, 0);
    final durationHours = _parseDurationHours(duration);
    final dropoff = pickup.add(Duration(hours: durationHours));

    final meeting = _meetingPoint(cityName, category);
    final program = _buildProgram(title, detail, duration, category);
    final rules = _buildRules(category, highlights);
    final clothing = _buildClothing(category, cityName);
    final warnings = _buildWarnings(category);

    return ActivityBookingBriefing(
      program: program,
      pickupTime: _formatTime(pickup),
      dropoffTime: _formatTime(dropoff),
      meetingPoint: meeting,
      rules: rules,
      clothingTips: clothing,
      warnings: warnings,
    );
  }

  static int _parseDurationHours(String duration) {
    final lower = duration.toLowerCase();
    if (lower.contains('gün')) {
      final n = int.tryParse(RegExp(r'\d+').firstMatch(lower)?.group(0) ?? '') ?? 1;
      return n * 8;
    }
    if (lower.contains('saat')) {
      return int.tryParse(RegExp(r'\d+').firstMatch(lower)?.group(0) ?? '') ?? 3;
    }
    return 3;
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _meetingPoint(String city, String category) {
    switch (category) {
      case 'museums':
        return '$city — Müze ana girişi, resepsiyon noktası';
      case 'adventure':
        return '$city — Tur operatörü ofisi / belirtilen iskele';
      case 'events':
        return '$city — Etkinlik alanı gişesi';
      case 'food':
        return '$city — Restoran önü / buluşma noktası';
      default:
        return '$city — Merkez buluşma noktası (detay SMS ile)';
    }
  }

  static String _buildProgram(
    String title,
    String detail,
    String duration,
    String category,
  ) {
    if (detail.trim().length > 40) return detail.trim();

    switch (category) {
      case 'museums':
        return '$title ($duration): rehberli veya serbest gezi, öne çıkan salonlar ve '
            'koleksiyonlar. Bilet ve giriş işlemleri dahil.';
      case 'adventure':
        return '$title ($duration): ekipman tanıtımı, güvenlik brifingi ve ana aktivite '
            'deneyimi. Fotoğraf molaları dahil.';
      case 'events':
        return '$title ($duration): gösteri / konser akışı, oturma veya ayakta izleme '
            'alanı. Etkinlik öncesi kapı açılışı.';
      case 'food':
        return '$title ($duration): yerel lezzet turu, tadım menüsü ve şef / rehber '
            'eşliğinde anlatım.';
      default:
        return '$title ($duration): şehir turu, önemli duraklar ve rehber anlatımı. '
            'Serbest zaman ve fotoğraf molaları dahil.';
    }
  }

  static List<String> _buildRules(String category, List<String> highlights) {
    final base = <String>[
      'Alınış saatinden en az 15 dakika önce buluşma noktasında olun.',
      'Onay kodunuzu veya dijital biletinizi yanınızda bulundurun.',
      'Rehber talimatlarına uyun; grup bütünlüğünü koruyun.',
    ];

    switch (category) {
      case 'museums':
        base.addAll([
          'Flaşlı fotoğraf çekimi yasak alanlara dikkat edin.',
          'Sessiz alanlarda telefonu sessize alın.',
        ]);
      case 'adventure':
        base.addAll([
          'Sağlık durumunuzu tur öncesi rehbere bildirin.',
          'Ekipman kullanım kurallarına uyun.',
        ]);
      case 'events':
        base.addAll([
          'Geç giriş kabul edilmeyebilir; kapı saatine uyun.',
          'Büyük çanta ve yiyecek içeri alınmayabilir.',
        ]);
      case 'food':
        base.addAll([
          'Alerjilerinizi önceden bildirin.',
          'Alkol servisi yaş sınırına tabidir.',
        ]);
      default:
        base.add('Tur rotası hava veya trafik nedeniyle güncellenebilir.');
    }

    for (final h in highlights.take(2)) {
      if (!base.contains(h)) base.add(h);
    }
    return base;
  }

  static List<String> _buildClothing(String category, String city) {
    switch (category) {
      case 'museums':
        return [
          'Rahat yürüyüş ayakkabısı',
          'Omuzları örten üst (bazı alanlarda zorunlu)',
          'Hafif ceket — salonlar serin olabilir',
        ];
      case 'adventure':
        return [
          'Kaymaz spor ayakkabı',
          'Rahat, hareket özgürlüğü veren kıyafet',
          'Güneş kremi ve şapka (açık hava turları)',
          'Yedek tişört önerilir',
        ];
      case 'events':
        return [
          'Akşam etkinlikleri için smart casual',
          'Ceket veya ince üst (klimalı salonlar)',
          'Rahat ayakkabı — ayakta bekleme olabilir',
        ];
      case 'food':
        return [
          'Rahat kıyafet',
          'Aç gelmeniz önerilir — tadım menüsü bol',
        ];
      default:
        return [
          'Rahat yürüyüş ayakkabısı',
          '$city için mevsimine uygun katmanlı giyim',
          'Güneş gözlüğü ve şişe su',
        ];
    }
  }

  static List<String> _buildWarnings(String category) {
    switch (category) {
      case 'adventure':
        return [
          'Hamileler ve belirli sağlık sorunları olanlar katılamayabilir.',
          'Hava koşulları nedeniyle tur iptal veya ertelenebilir.',
        ];
      case 'events':
        return [
          'Bilet iadesi etkinlik politikasına tabidir.',
          'Yaş sınırı olabilir — bilette belirtilir.',
        ];
      case 'food':
        return [
          'Menü mevsimsel olarak değişebilir.',
          'Vejetaryen / vegan talebi önceden bildirilmelidir.',
        ];
      default:
        return [
          'İptal koşulları biletinizde yer alır; son 24 saatte iptal ücreti uygulanabilir.',
          'Grup turu minimum katılımcı sayısına bağlıdır.',
        ];
    }
  }
}
