import '../models/personalized_guide_model.dart';
import '../data/destination_travel_hints.dart';
import '../data/destination_interest_pois.dart';
import '../data/holiday_types.dart';
import '../services/ai_chat_service.dart';
import '../services/guide_cache_store.dart';
import '../services/guide_quality.dart';
import '../services/weather_service.dart';
import '../utils/traveler_group_profile.dart';

/// Post-booking seyahat rehberi — hava + AI + önbellek.
class TravelGuideService {
  TravelGuideService._();

  static const _weatherTimeout = Duration(seconds: 8);
  static const _aiTimeout = Duration(seconds: 28);

  /// Ağ beklemeden anında gösterilebilir yerel rehber.
  static PersonalizedGuide buildLocalGuide({
    required String cityName,
    required String country,
    required String destinationIata,
    required int nights,
    required int adults,
    required int children,
    List<int> passengerAges = const [],
    List<String> holidayTypes = const [],
  }) {
    final ages = passengerAges.isNotEmpty
        ? passengerAges
        : List.filled(adults, 30) + List.filled(children, 8);
    final profile = TravelerGroupProfile.from(
      adults: adults,
      children: children,
      passengerAges: ages,
    );

    var guide = DestinationTravelHints.build(
      iata: destinationIata,
      cityName: cityName,
      country: country,
      nights: nights,
      travelers: adults + children,
      groupProfile: profile,
      holidayTypes: holidayTypes,
    );

    guide = _ensureGroupProfileSection(guide, profile);
    guide = _ensureInterestsSection(
      guide,
      destinationIata: destinationIata,
      cityName: cityName,
      holidayTypes: holidayTypes,
    );
    return guide;
  }

  static Future<PersonalizedGuide?> load({
    required String cityName,
    required String country,
    required String destinationIata,
    required DateTime departureDate,
    required DateTime returnDate,
    required int nights,
    required int adults,
    required int children,
    List<int> passengerAges = const [],
    String? hotelName,
    String? reservationId,
    bool forceRefresh = false,
    List<String> holidayTypes = const [],
  }) async {
    if (reservationId != null &&
        reservationId.isNotEmpty &&
        !forceRefresh) {
      final cached = await GuideCacheStore.get(reservationId);
      if (cached != null && GuideQuality.isAcceptable(cached)) return cached;
    }

    final ages = passengerAges.isNotEmpty
        ? passengerAges
        : List.filled(adults, 30) + List.filled(children, 8);

    final localGuide = buildLocalGuide(
      cityName: cityName,
      country: country,
      destinationIata: destinationIata,
      nights: nights,
      adults: adults,
      children: children,
      passengerAges: ages,
      holidayTypes: holidayTypes,
    );

    final results = await Future.wait([
      WeatherService.getTripWeather(
        cityName: cityName,
        destinationIata: destinationIata,
        departureDate: departureDate,
        returnDate: returnDate,
      ).timeout(_weatherTimeout, onTimeout: () => null).catchError((_) => null),
      AiChatService.getPersonalizedTravelGuide(
        cityName: cityName,
        country: country,
        nights: nights,
        departureDate: departureDate,
        returnDate: returnDate,
        passengerAges: ages,
        adults: adults,
        children: children,
        hotelName: hotelName,
        holidayTypes: holidayTypes,
        destinationIata: destinationIata,
      ).timeout(_aiTimeout, onTimeout: () => null).catchError((_) => null),
    ]);

    final weather = results[0] as TripWeatherSummary?;
    var guide = results[1] as PersonalizedGuide?;

    if (guide == null || !GuideQuality.isAcceptable(guide)) {
      guide = localGuide;
    } else {
      guide = _ensureGroupProfileSection(
        guide,
        TravelerGroupProfile.from(
          adults: adults,
          children: children,
          passengerAges: ages,
        ),
      );
      guide = _ensureInterestsSection(
        guide,
        destinationIata: destinationIata,
        cityName: cityName,
        holidayTypes: holidayTypes,
      );
    }

    var resolved = guide;
    if (!GuideQuality.isAcceptable(resolved)) return null;

    if (weather != null) {
      resolved = resolved.copyWith(weather: weather);
      resolved = _ensurePackingFromWeather(resolved, weather);
    }

    if (reservationId != null && reservationId.isNotEmpty) {
      await GuideCacheStore.save(reservationId, resolved);
    }

    return resolved;
  }

  static Future<void> prefetch({
    required String reservationId,
    required String cityName,
    required String country,
    required String destinationIata,
    required DateTime departureDate,
    required DateTime returnDate,
    required int nights,
    required int adults,
    required int children,
    List<int> passengerAges = const [],
    String? hotelName,
    List<String> holidayTypes = const [],
  }) async {
    final local = buildLocalGuide(
      cityName: cityName,
      country: country,
      destinationIata: destinationIata,
      nights: nights,
      adults: adults,
      children: children,
      passengerAges: passengerAges,
      holidayTypes: holidayTypes,
    );
    await GuideCacheStore.save(reservationId, local);

    await load(
      reservationId: reservationId,
      cityName: cityName,
      country: country,
      destinationIata: destinationIata,
      departureDate: departureDate,
      returnDate: returnDate,
      nights: nights,
      adults: adults,
      children: children,
      passengerAges: passengerAges,
      hotelName: hotelName,
      holidayTypes: holidayTypes,
      forceRefresh: true,
    );
  }

  /// Önbellekte kaliteli rehber var mı.
  static Future<bool> isCached(String reservationId) async {
    if (reservationId.isEmpty) return false;
    final cached = await GuideCacheStore.get(reservationId);
    return cached != null && GuideQuality.isAcceptable(cached);
  }

  static PersonalizedGuide _ensureInterestsSection(
    PersonalizedGuide guide,
    {
    required String destinationIata,
    required String cityName,
    required List<String> holidayTypes,
  }) {
    if (holidayTypes.isEmpty) return guide;
    final hasInterests =
        guide.sections.any((s) => s.kind == GuideSectionKind.interests);
    if (hasInterests) return guide;

    final pois = DestinationInterestPois.forDestination(
      destinationIata,
      holidayTypes,
    );
    final labels = HolidayTypes.labelsOf(holidayTypes);
    final items = pois.isEmpty
        ? [
            '${labels.join(', ')} odaklı öneriler rehberinize eklenecek.',
          ]
        : pois
            .map((p) {
              final discount = p.discountHint != null && p.discountHint!.isNotEmpty
                  ? ' · ${p.discountHint}'
                  : '';
              return '${p.name} (${p.area}): ${p.note}$discount';
            })
            .toList();

    final section = PersonalizedGuideSection(
      emoji: GuideSectionKind.interests.defaultEmoji,
      title: labels.length == 1
          ? '${labels.first} rehberi'
          : GuideSectionKind.interests.defaultTitle,
      kind: GuideSectionKind.interests,
      items: items,
    );

    return guide.copyWith(
      sections: [...guide.sections, section]
        ..sort((a, b) => a.kind.sortOrder.compareTo(b.kind.sortOrder)),
    );
  }

  static PersonalizedGuide _ensureGroupProfileSection(
    PersonalizedGuide guide,
    TravelerGroupProfile profile,
  ) {
    final hasGroup = guide.sections
        .any((s) => s.kind == GuideSectionKind.groupProfile);
    if (hasGroup) return guide;

    final section = PersonalizedGuideSection(
      emoji: GuideSectionKind.groupProfile.defaultEmoji,
      title: GuideSectionKind.groupProfile.defaultTitle,
      kind: GuideSectionKind.groupProfile,
      items: [
        profile.summaryLabel,
        profile.groupType.travelStyleHint,
        'Öncelikler: ${profile.groupType.priorities}',
      ],
    );

    return guide.copyWith(
      sections: [section, ...guide.sections]
        ..sort((a, b) => a.kind.sortOrder.compareTo(b.kind.sortOrder)),
    );
  }

  static PersonalizedGuide _ensurePackingFromWeather(
    PersonalizedGuide guide,
    TripWeatherSummary weather,
  ) {
    final hasPacking =
        guide.sections.any((s) => s.kind == GuideSectionKind.packing);
    if (hasPacking || weather.clothingHint.isEmpty) return guide;

    final sections = [
      ...guide.sections,
      PersonalizedGuideSection(
        emoji: GuideSectionKind.packing.defaultEmoji,
        title: GuideSectionKind.packing.defaultTitle,
        kind: GuideSectionKind.packing,
        items: [weather.clothingHint],
      ),
    ]..sort((a, b) => a.kind.sortOrder.compareTo(b.kind.sortOrder));

    return guide.copyWith(sections: sections);
  }
}
