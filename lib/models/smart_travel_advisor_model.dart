class SmartTravelAdvisorResponse {
  const SmartTravelAdvisorResponse({
    required this.groupAnalysis,
    required this.weatherForecast,
    required this.goldenRules,
    required this.liveEventsAffiliate,
    required this.currencyConverter,
    this.source,
  });

  final GroupAnalysis groupAnalysis;
  final AdvisorWeatherForecast weatherForecast;
  final List<String> goldenRules;
  final List<LiveEventAffiliate> liveEventsAffiliate;
  final CurrencyConverter currencyConverter;
  final String? source;

  factory SmartTravelAdvisorResponse.fromJson(Map<String, dynamic> json) {
    return SmartTravelAdvisorResponse(
      groupAnalysis: GroupAnalysis.fromJson(
        Map<String, dynamic>.from(json['group_analysis'] as Map? ?? {}),
      ),
      weatherForecast: AdvisorWeatherForecast.fromJson(
        Map<String, dynamic>.from(json['weather_forecast'] as Map? ?? {}),
      ),
      goldenRules: (json['golden_rules'] as List?)
              ?.map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList() ??
          const [],
      liveEventsAffiliate: _parseEvents(json['live_events_affiliate']),
      currencyConverter: CurrencyConverter.fromJson(
        Map<String, dynamic>.from(json['currency_converter'] as Map? ?? {}),
      ),
      source: json['_source'] as String?,
    );
  }

  bool get isEmpty =>
      groupAnalysis.personalizedNote.isEmpty &&
      goldenRules.isEmpty &&
      weatherForecast.status.isEmpty;

  static List<LiveEventAffiliate> _parseEvents(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => LiveEventAffiliate.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.isDisplayable)
        .toList();
  }

  List<LiveEventAffiliate> get displayableEvents => liveEventsAffiliate
      .where((e) => e.isDisplayable && e.eventName.trim().isNotEmpty)
      .toList();
}

class GroupAnalysis {
  const GroupAnalysis({
    required this.vibeType,
    required this.personalizedNote,
  });

  final String vibeType;
  final String personalizedNote;

  factory GroupAnalysis.fromJson(Map<String, dynamic> json) {
    return GroupAnalysis(
      vibeType: json['vibe_type']?.toString() ?? '',
      personalizedNote: json['personalized_note']?.toString() ?? '',
    );
  }
}

class AdvisorWeatherForecast {
  const AdvisorWeatherForecast({
    required this.status,
    required this.clothingSuggestions,
  });

  final String status;
  final ClothingSuggestions clothingSuggestions;

  factory AdvisorWeatherForecast.fromJson(Map<String, dynamic> json) {
    return AdvisorWeatherForecast(
      status: json['status']?.toString() ?? '',
      clothingSuggestions: ClothingSuggestions.fromJson(
        Map<String, dynamic>.from(json['clothing_suggestions'] as Map? ?? {}),
      ),
    );
  }
}

class ClothingSuggestions {
  const ClothingSuggestions({
    required this.daily,
    required this.activitySpecific,
  });

  final String daily;
  final String activitySpecific;

  factory ClothingSuggestions.fromJson(Map<String, dynamic> json) {
    return ClothingSuggestions(
      daily: json['daily']?.toString() ?? '',
      activitySpecific: json['activity_specific']?.toString() ?? '',
    );
  }
}

class LiveEventAffiliate {
  const LiveEventAffiliate({
    required this.eventName,
    required this.date,
    required this.ticketAffiliateUrl,
    required this.description,
  });

  final String eventName;
  final String date;
  final String ticketAffiliateUrl;
  final String description;

  factory LiveEventAffiliate.fromJson(Map<String, dynamic> json) {
    return LiveEventAffiliate(
      eventName: _str(json, ['event_name', 'eventName', 'name', 'title']),
      date: _str(json, ['date', 'event_date', 'eventDate', 'when']),
      ticketAffiliateUrl: _str(json, [
        'ticket_affiliate_url',
        'ticketAffiliateUrl',
        'ticket_url',
        'url',
        'link',
      ]),
      description: _str(json, ['description', 'summary', 'details']),
    );
  }

  bool get isDisplayable =>
      eventName.trim().isNotEmpty &&
      (description.trim().isNotEmpty ||
          date.trim().isNotEmpty ||
          ticketAffiliateUrl.trim().isNotEmpty);

  static String _str(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final raw = json[key];
      if (raw == null) continue;
      final text = raw.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

class CurrencyConverter {
  const CurrencyConverter({
    required this.localCurrency,
    required this.currentRateText,
  });

  final String localCurrency;
  final String currentRateText;

  factory CurrencyConverter.fromJson(Map<String, dynamic> json) {
    return CurrencyConverter(
      localCurrency: json['local_currency']?.toString() ?? '',
      currentRateText: json['current_rate_text']?.toString() ?? '',
    );
  }
}
