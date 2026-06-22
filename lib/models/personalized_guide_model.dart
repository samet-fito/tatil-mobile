enum GuideSectionKind {
  groupProfile,
  interests,
  mustDo,
  strictRules,
  lifeSavers,
  packing,
  localTips,
  other;

  static GuideSectionKind fromString(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'groupprofile':
        return GuideSectionKind.groupProfile;
      case 'interests':
        return GuideSectionKind.interests;
      case 'mustdo':
        return GuideSectionKind.mustDo;
      case 'strictrules':
        return GuideSectionKind.strictRules;
      case 'lifesavers':
        return GuideSectionKind.lifeSavers;
      case 'packing':
        return GuideSectionKind.packing;
      case 'localtips':
        return GuideSectionKind.localTips;
      default:
        return GuideSectionKind.other;
    }
  }

  String get defaultEmoji {
    switch (this) {
      case GuideSectionKind.groupProfile:
        return '👥';
      case GuideSectionKind.interests:
        return '🛍️';
      case GuideSectionKind.mustDo:
        return '🎯';
      case GuideSectionKind.strictRules:
        return '⚠️';
      case GuideSectionKind.lifeSavers:
        return '🆘';
      case GuideSectionKind.packing:
        return '🎒';
      case GuideSectionKind.localTips:
        return '💡';
      case GuideSectionKind.other:
        return '📌';
    }
  }

  String get defaultTitle {
    switch (this) {
      case GuideSectionKind.groupProfile:
        return 'Grubunuz için özet';
      case GuideSectionKind.interests:
        return 'Tatil türüne özel';
      case GuideSectionKind.mustDo:
        return 'Mutlaka yapılacaklar';
      case GuideSectionKind.strictRules:
        return 'Uyulması gereken kurallar';
      case GuideSectionKind.lifeSavers:
        return 'Hayat kurtaran tavsiyeler';
      case GuideSectionKind.packing:
        return 'Valiz & ekipman';
      case GuideSectionKind.localTips:
        return 'Seyahat ipuçları';
      case GuideSectionKind.other:
        return 'Pratik bilgiler';
    }
  }

  int get sortOrder {
    switch (this) {
      case GuideSectionKind.groupProfile:
        return -1;
      case GuideSectionKind.interests:
        return 0;
      case GuideSectionKind.mustDo:
        return 1;
      case GuideSectionKind.strictRules:
        return 2;
      case GuideSectionKind.lifeSavers:
        return 3;
      case GuideSectionKind.packing:
        return 4;
      case GuideSectionKind.localTips:
        return 5;
      case GuideSectionKind.other:
        return 6;
    }
  }
}

class TripWeatherDay {
  const TripWeatherDay({
    required this.date,
    required this.highC,
    required this.lowC,
    required this.precipMm,
    required this.label,
  });

  final DateTime date;
  final double highC;
  final double lowC;
  final double precipMm;
  final String label;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'highC': highC,
        'lowC': lowC,
        'precipMm': precipMm,
        'label': label,
      };

  factory TripWeatherDay.fromJson(Map<String, dynamic> json) {
    return TripWeatherDay(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      highC: (json['highC'] as num?)?.toDouble() ?? 0,
      lowC: (json['lowC'] as num?)?.toDouble() ?? 0,
      precipMm: (json['precipMm'] as num?)?.toDouble() ?? 0,
      label: json['label']?.toString() ?? '',
    );
  }
}

class TripWeatherSummary {
  const TripWeatherSummary({
    required this.summaryLine,
    required this.clothingHint,
    required this.days,
    required this.avgHighC,
    required this.avgLowC,
  });

  final String summaryLine;
  final String clothingHint;
  final List<TripWeatherDay> days;
  final double avgHighC;
  final double avgLowC;

  String get aiContext =>
      'Hava özeti: $summaryLine. Giyim: $clothingHint';

  Map<String, dynamic> toJson() => {
        'summaryLine': summaryLine,
        'clothingHint': clothingHint,
        'avgHighC': avgHighC,
        'avgLowC': avgLowC,
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory TripWeatherSummary.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    return TripWeatherSummary(
      summaryLine: json['summaryLine']?.toString() ?? '',
      clothingHint: json['clothingHint']?.toString() ?? '',
      avgHighC: (json['avgHighC'] as num?)?.toDouble() ?? 0,
      avgLowC: (json['avgLowC'] as num?)?.toDouble() ?? 0,
      days: rawDays is List
          ? rawDays
              .whereType<Map>()
              .map((d) => TripWeatherDay.fromJson(Map<String, dynamic>.from(d)))
              .toList()
          : const [],
    );
  }
}

class PersonalizedGuideSection {
  final String emoji;
  final String title;
  final List<String> items;
  final GuideSectionKind kind;

  const PersonalizedGuideSection({
    required this.emoji,
    required this.title,
    required this.items,
    this.kind = GuideSectionKind.other,
  });

  factory PersonalizedGuideSection.fromJson(Map<String, dynamic> json) {
    final kind = GuideSectionKind.fromString(json['kind'] as String?);
    final title = (json['title'] as String? ?? '').trim();
    return PersonalizedGuideSection(
      emoji: json['emoji'] as String? ?? kind.defaultEmoji,
      title: title.isNotEmpty ? title : kind.defaultTitle,
      items: List<String>.from(json['items'] ?? []),
      kind: kind,
    );
  }

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'title': title,
        'items': items,
        'kind': kind.name,
      };
}

class PersonalizedGuide {
  final String headline;
  final String subtitle;
  final List<PersonalizedGuideSection> sections;
  final TripWeatherSummary? weather;
  final String disclaimer;

  const PersonalizedGuide({
    required this.headline,
    required this.subtitle,
    required this.sections,
    this.weather,
    this.disclaimer =
        'Kurallar ve uyarılar genel bilgidir; resmi kaynakları kontrol edin.',
  });

  factory PersonalizedGuide.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    final sections = rawSections is List
        ? rawSections
            .whereType<Map>()
            .map((s) => PersonalizedGuideSection.fromJson(
                  Map<String, dynamic>.from(s),
                ))
            .where((s) => s.title.isNotEmpty && s.items.isNotEmpty)
            .toList()
        : <PersonalizedGuideSection>[];

    sections.sort((a, b) => a.kind.sortOrder.compareTo(b.kind.sortOrder));

    TripWeatherSummary? weather;
    final rawWeather = json['weather'];
    if (rawWeather is Map) {
      weather = TripWeatherSummary.fromJson(Map<String, dynamic>.from(rawWeather));
    }

    return PersonalizedGuide(
      headline: json['headline'] as String? ?? 'Seyahat Rehberin',
      subtitle: json['subtitle'] as String? ?? '',
      sections: sections,
      weather: weather,
      disclaimer: json['disclaimer'] as String? ??
          'Kurallar ve uyarılar genel bilgidir; resmi kaynakları kontrol edin.',
    );
  }

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'subtitle': subtitle,
        'sections': sections.map((s) => s.toJson()).toList(),
        if (weather != null) 'weather': weather!.toJson(),
        'disclaimer': disclaimer,
      };

  PersonalizedGuide copyWith({
    String? headline,
    String? subtitle,
    List<PersonalizedGuideSection>? sections,
    TripWeatherSummary? weather,
    String? disclaimer,
  }) {
    return PersonalizedGuide(
      headline: headline ?? this.headline,
      subtitle: subtitle ?? this.subtitle,
      sections: sections ?? this.sections,
      weather: weather ?? this.weather,
      disclaimer: disclaimer ?? this.disclaimer,
    );
  }

  bool get isEmpty => sections.isEmpty && weather == null;
}
