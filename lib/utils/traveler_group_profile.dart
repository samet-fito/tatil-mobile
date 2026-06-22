import 'passenger_age.dart';

/// Yolcu yaşlarından grup tipi — AI rehberi ve arayüz metinleri.
class TravelerGroupProfile {
  const TravelerGroupProfile({
    required this.adults,
    required this.children,
    required this.ages,
    required this.groupType,
    required this.summaryLabel,
    required this.aiContext,
  });

  final int adults;
  final int children;
  final List<int> ages;
  final TravelerGroupType groupType;
  final String summaryLabel;
  final String aiContext;

  int get total => adults + children;

  static TravelerGroupProfile from({
    required int adults,
    required int children,
    List<int> passengerAges = const [],
  }) {
    final ages = passengerAges.isNotEmpty
        ? List<int>.from(passengerAges)
        : [...List.filled(adults, 30), ...List.filled(children, 8)];

    final groupType = _detectGroupType(adults: adults, children: children, ages: ages);
    final summaryLabel = _buildSummaryLabel(
      adults: adults,
      children: children,
      ages: ages,
      groupType: groupType,
    );
    final aiContext = _buildAiContext(
      adults: adults,
      children: children,
      ages: ages,
      groupType: groupType,
    );

    return TravelerGroupProfile(
      adults: adults,
      children: children,
      ages: ages,
      groupType: groupType,
      summaryLabel: summaryLabel,
      aiContext: aiContext,
    );
  }

  static TravelerGroupType _detectGroupType({
    required int adults,
    required int children,
    required List<int> ages,
  }) {
    if (ages.isEmpty) {
      if (children > 0) return TravelerGroupType.family;
      if (adults == 1) return TravelerGroupType.solo;
      if (adults == 2) return TravelerGroupType.couple;
      return TravelerGroupType.friends;
    }

    final hasInfant = ages.any((a) => a < 3);
    final hasChild = ages.any((a) => a >= 3 && a < 13);
    final hasTeen = ages.any((a) => a >= 13 && a < 18);
    final hasSenior = ages.any((a) => a >= 65);
    final allSenior = ages.every((a) => a >= 60);
    final allYoung = ages.every((a) => a >= 18 && a <= 35);
    final count = ages.length;

    if (children > 0 || hasInfant || hasChild) {
      return TravelerGroupType.family;
    }
    if (count == 1) {
      if (hasSenior) return TravelerGroupType.seniorSolo;
      return TravelerGroupType.solo;
    }
    if (count == 2 && adults == 2 && !hasTeen) {
      if (allSenior) return TravelerGroupType.seniorCouple;
      return TravelerGroupType.couple;
    }
    if (allSenior) return TravelerGroupType.seniors;
    if (allYoung) return TravelerGroupType.youngGroup;
    if (hasSenior && (hasChild || hasTeen)) return TravelerGroupType.multiGenFamily;
    if (hasSenior) return TravelerGroupType.mixedWithSeniors;
    if (hasTeen) return TravelerGroupType.teensAndAdults;
    return TravelerGroupType.mixed;
  }

  static String _buildSummaryLabel({
    required int adults,
    required int children,
    required List<int> ages,
    required TravelerGroupType groupType,
  }) {
    final parts = <String>[groupType.label];
    if (adults > 0) parts.add('$adults yetişkin');
    if (children > 0) parts.add('$children çocuk');
    if (ages.isNotEmpty) {
      parts.add(PassengerAge.summarize(ages));
    }
    return parts.join(' · ');
  }

  static String _buildAiContext({
    required int adults,
    required int children,
    required List<int> ages,
    required TravelerGroupType groupType,
  }) {
    final ageLines = ages.isEmpty
        ? '$adults yetişkin${children > 0 ? ', $children çocuk (yaş bilgisi yok — genel aile profili varsay)' : ''}'
        : ages.asMap().entries.map((e) {
            final n = e.key + 1;
            final age = e.value;
            return 'Yolcu $n: $age yaş (${PassengerAge.ageGroupLabel(age)})';
          }).join('\n');

    return '''
Grup profili analizi (tüm öneriler buna göre özelleştirilmeli):
- Grup tipi: ${groupType.label} — ${groupType.travelStyleHint}
- Kişi sayısı: ${adults + children} ($adults yetişkin${children > 0 ? ', $children çocuk' : ''})
- Yaş dağılımı:
$ageLines
- Öncelikler: ${groupType.priorities}
''';
  }
}

enum TravelerGroupType {
  solo('Yalnız gezgin', 'Esnek tempo, tek kişilik rota ve pratik ulaşım'),
  couple('Çift', 'Romantik ve orta tempolu deneyimler, birlikte keşif'),
  family('Aile', 'Çocuk dostu aktiviteler, güvenli rotalar, molalı program'),
  multiGenFamily('Kuşaklar arası aile', 'Hem çocuk hem yaşlı için erişilebilir, yorucu olmayan plan'),
  youngGroup('Genç grup', 'Aktif tempo, trend noktalar, gece ve sosyal deneyimler'),
  friends('Arkadaş grubu', 'Esnek program, paylaşımlı aktiviteler, orta-yüksek tempo'),
  seniors('Yaşlı grup', 'Yavaş tempo, dinlenme molaları, erişilebilir ulaşım, sağlık odaklı'),
  seniorCouple('Yaşlı çift', 'Konforlu tempo, az yürüyüş, klimali mekânlar'),
  seniorSolo('65+ yalnız gezgin', 'Güvenli bölgeler, kolay ulaşım, sağlık ve dinlenme'),
  mixedWithSeniors('Yaşlı dahil karma grup', 'Tempo düşük tutulmalı, herkes için erişilebilir seçenekler'),
  teensAndAdults('Genç + yetişkin', 'Enerjik gündüz, akşam ayrı opsiyonlar'),
  mixed('Karma grup', 'Farklı yaşlara uygun alternatifli program');

  const TravelerGroupType(this.label, this.travelStyleHint);

  final String label;
  final String travelStyleHint;

  String get priorities {
    switch (this) {
      case TravelerGroupType.solo:
        return 'güvenlik, pratik ulaşım, tek kişilik bütçe ipuçları';
      case TravelerGroupType.couple:
        return 'romantik noktalar, rezervasyon kolaylığı, birlikte deneyim';
      case TravelerGroupType.family:
        return 'çocuk güvenliği, tuvalet/mola noktaları, erken yatış, eğlenceli ama yorucu olmayan rota';
      case TravelerGroupType.multiGenFamily:
        return 'bebek arabası/tek tekerlekli erişim, her yaş için alternatif, ortak aile aktiviteleri';
      case TravelerGroupType.youngGroup:
        return 'Instagram noktaları, gece hayatı opsiyonu, aktif turlar, bütçe dostu yemek';
      case TravelerGroupType.friends:
        return 'grup indirimleri, paylaşımlı aktiviteler, esnek program';
      case TravelerGroupType.seniors:
      case TravelerGroupType.seniorCouple:
      case TravelerGroupType.seniorSolo:
        return 'az merdiven, oturma molaları, sıcak/soğuk hava uyarıları, eczane/hastane bilgisi';
      case TravelerGroupType.mixedWithSeniors:
        return 'yaşlılar için yavaş alternatif, gençler için ekstra opsiyon';
      case TravelerGroupType.teensAndAdults:
        return 'gençler için macera, yetişkinler için kültür/dinlenme dengesi';
      case TravelerGroupType.mixed:
        return 'her yaştan kişi için alternatifli günlük plan';
    }
  }
}
