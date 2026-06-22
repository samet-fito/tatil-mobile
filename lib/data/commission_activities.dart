import '../utils/activity_schedule_utils.dart';

/// Aktivite API yanıtını komisyonlu aktivite ekranı formatına dönüştürür.
class CommissionActivities {
  static Map<String, dynamic> fromApiActivities(
    Map<String, dynamic> apiData,
    String iata,
    String cityName, {
    DateTime? tripStart,
    DateTime? tripEnd,
  }) {
    final acts = apiData['activities'];
    if (acts is! Map) {
      throw StateError('Aktivite verisi bulunamadı');
    }

    final withinTrip = List<Map<String, dynamic>>.from(acts['withinTrip'] ?? []);
    final nearby = List<Map<String, dynamic>>.from(acts['nearby'] ?? []);
    final all = [...withinTrip, ...nearby];
    if (all.isEmpty) {
      throw StateError('Bu destinasyon için aktivite bulunamadı');
    }

    final categoryLabels = {
      'tours': {'title': 'Turlar & Geziler', 'icon': '🗺️'},
      'museums': {'title': 'Müzeler & Kültür', 'icon': '🏛️'},
      'adventure': {'title': 'Macera & Doğa', 'icon': '🏄'},
      'events': {'title': 'Gösteriler & Etkinlikler', 'icon': '🎭'},
      'food': {'title': 'Yemek Deneyimleri', 'icon': '🍽️'},
    };

    final grouped = <String, List<Map<String, dynamic>>>{};
    var index = 0;
    for (final act in all) {
      final enriched = _enrichWithSchedule(
        _fromApiItem(act),
        act,
        tripStart: tripStart,
        tripEnd: tripEnd,
        index: index++,
      );
      if (tripStart != null &&
          tripEnd != null &&
          !ActivityScheduleUtils.isWithinTrip(
            schedule: ActivityScheduleInfo(
              isDaily: enriched['isDaily'] == true,
              eventDate: ActivityScheduleUtils.parseEventDate(enriched),
            ),
            tripStart: tripStart,
            tripEnd: tripEnd,
          )) {
        continue;
      }
      final cat = act['category'] as String? ?? 'tours';
      grouped.putIfAbsent(cat, () => []).add(enriched);
    }

    final categories = grouped.entries.map((e) {
      final meta = categoryLabels[e.key] ?? {'title': e.key, 'icon': '🎯'};
      return {
        'id': e.key,
        'title': meta['title'],
        'icon': meta['icon'],
        'activities': e.value,
      };
    }).toList();

    if (categories.isEmpty) {
      throw StateError('Seçilen tarihler arasında aktivite bulunamadı');
    }

    return {
      'cityName': cityName,
      'iata': iata.toUpperCase(),
      'headline': '$cityName\'de Önerilen Aktiviteler',
      'subtitle': apiData['source'] == 'mock'
          ? 'Backend aktivite kataloğu'
          : 'Vizegoo partner ağı — güvenli rezervasyon',
      'dataSource': apiData['source'] ?? 'api',
      'categories': categories,
      if (tripStart != null) 'eventDeparture': tripStart.toIso8601String(),
      if (tripEnd != null) 'eventReturn': tripEnd.toIso8601String(),
    };
  }

  static Map<String, dynamic> _enrichWithSchedule(
    Map<String, dynamic> item,
    Map<String, dynamic> source, {
    DateTime? tripStart,
    DateTime? tripEnd,
    required int index,
  }) {
    if (tripStart == null || tripEnd == null) return item;
    return ActivityScheduleUtils.enrichActivity(
      {...source, ...item},
      tripStart: tripStart,
      tripEnd: tripEnd,
      index: index,
    );
  }

  static Map<String, dynamic> _fromApiItem(Map<String, dynamic> act) {
    final title = act['title'] as String? ?? 'Aktivite';
    final desc = act['description'] as String? ?? '';
    final commission = (act['commission'] as num?)?.toDouble() ??
        (act['commissionRate'] as num?)?.toDouble() ??
        0.12;
    return {
      'title': title,
      'summary': desc,
      'description': desc,
      'detail': act['detail'] as String? ??
          '$desc\n\nPartner ağımız üzerinden güvenli rezervasyon yapabilirsiniz.',
      'duration': act['duration'] as String? ?? '—',
      'priceTL': (act['priceTL'] as num?)?.toInt() ?? 0,
      'rating': (act['rating'] as num?)?.toDouble() ?? 4.5,
      'reviewCount': (act['reviewCount'] as num?)?.toInt() ?? 0,
      'commissionRate': commission,
      'highlights': List<String>.from(
        act['highlights'] ?? ['Partner aktivite', 'Anında onay', 'Güvenli ödeme'],
      ),
      'isPartner': true,
    };
  }

  static int totalActivityCount(Map<String, dynamic> data) {
    final cats = List<Map<String, dynamic>>.from(data['categories'] ?? []);
    var n = 0;
    for (final c in cats) {
      n += (c['activities'] as List?)?.length ?? 0;
    }
    return n;
  }

  /// AI yanıtından katalog formatına dönüştürür.
  static Map<String, dynamic> fromAiActivities(
    List<Map<String, dynamic>> items,
    String cityName,
    String iata, {
    DateTime? tripStart,
    DateTime? tripEnd,
  }) {
    if (items.isEmpty) {
      throw StateError('Aktivite listesi boş');
    }

    final categoryLabels = {
      'tours': {'title': 'Turlar & Geziler', 'icon': '🗺️'},
      'museums': {'title': 'Müzeler & Kültür', 'icon': '🏛️'},
      'adventure': {'title': 'Macera & Doğa', 'icon': '🏄'},
      'events': {'title': 'Gösteriler & Etkinlikler', 'icon': '🎭'},
      'food': {'title': 'Yemek Deneyimleri', 'icon': '🍽️'},
    };

    final sorted = [...items]..sort((a, b) {
        final ra = (a['popularityRank'] as num?)?.toInt() ?? 99;
        final rb = (b['popularityRank'] as num?)?.toInt() ?? 99;
        return ra.compareTo(rb);
      });

    final grouped = <String, List<Map<String, dynamic>>>{};
    var index = 0;
    for (final act in sorted) {
      final enriched = _enrichWithSchedule(
        _fromAiItem(act),
        act,
        tripStart: tripStart,
        tripEnd: tripEnd,
        index: index++,
      );
      if (tripStart != null &&
          tripEnd != null &&
          !ActivityScheduleUtils.isWithinTrip(
            schedule: ActivityScheduleInfo(
              isDaily: enriched['isDaily'] == true,
              eventDate: ActivityScheduleUtils.parseEventDate(enriched),
            ),
            tripStart: tripStart,
            tripEnd: tripEnd,
          )) {
        continue;
      }
      final cat = act['category'] as String? ?? 'tours';
      grouped.putIfAbsent(cat, () => []).add(enriched);
    }

    final categories = grouped.entries.map((e) {
      final meta = categoryLabels[e.key] ?? {'title': e.key, 'icon': '🎯'};
      return {
        'id': e.key,
        'title': meta['title'],
        'icon': meta['icon'],
        'activities': e.value,
      };
    }).toList();

    if (categories.isEmpty) {
      throw StateError('Seçilen tarihler arasında aktivite bulunamadı');
    }

    return {
      'cityName': cityName,
      'iata': iata.toUpperCase(),
      'headline': '$cityName — En Popüler Aktiviteler',
      'subtitle': 'Turistlerin en çok tercih ettiği deneyimler · anında online rezervasyon',
      'categories': categories,
      'source': 'ai',
      if (tripStart != null) 'eventDeparture': tripStart.toIso8601String(),
      if (tripEnd != null) 'eventReturn': tripEnd.toIso8601String(),
    };
  }

  static Map<String, dynamic> _fromAiItem(Map<String, dynamic> act) {
    final title = act['title'] as String? ?? 'Aktivite';
    final desc = act['description'] as String? ?? '';
    return {
      'title': title,
      'summary': desc,
      'description': desc,
      'detail': desc,
      'duration': act['duration'] as String? ?? '—',
      'priceTL': (act['priceTL'] as num?)?.toInt() ?? 0,
      'rating': (act['rating'] as num?)?.toDouble() ?? 4.7,
      'reviewCount': (act['reviewCount'] as num?)?.toInt() ?? 0,
      'commissionRate': (act['commissionRate'] as num?)?.toDouble() ?? 0.15,
      'highlights': List<String>.from(
        act['highlights'] ?? ['Anında onay', 'Mobil bilet', 'Ücretsiz iptal'],
      ),
      'isPartner': true,
      'popularityRank': act['popularityRank'],
    };
  }

  /// Kategorilerden düz aktivite listesi (sıralı).
  static List<Map<String, dynamic>> flatActivities(Map<String, dynamic> data) {
    final cats = List<Map<String, dynamic>>.from(data['categories'] ?? []);
    final all = <Map<String, dynamic>>[];
    for (final c in cats) {
      all.addAll(List<Map<String, dynamic>>.from(c['activities'] ?? []));
    }
    all.sort((a, b) {
      final ra = (a['popularityRank'] as num?)?.toInt() ?? 99;
      final rb = (b['popularityRank'] as num?)?.toInt() ?? 99;
      return ra.compareTo(rb);
    });
    return all;
  }
}
