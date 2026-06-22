import '../models/smart_travel_advisor_model.dart';
import '../utils/traveler_group_profile.dart';
import 'advisor_events_catalog.dart';
import 'destination_currency.dart';

/// API offline / 502 olduğunda cihazda gösterilecek danışman yedek verisi.
class AdvisorFallbackCatalog {
  AdvisorFallbackCatalog._();

  static SmartTravelAdvisorResponse build({
    required String destinationIata,
    required String cityName,
    required String country,
    required DateTime departureDate,
    required int nights,
    required int adults,
    required int children,
    List<int> passengerAges = const [],
    double fxRateTl = 35,
  }) {
    final iata = destinationIata.toUpperCase();
    final profile = TravelerGroupProfile.from(
      adults: adults,
      children: children,
      passengerAges: passengerAges,
    );
    final currency = DestinationCurrency.forIata(iata);
    final content = _content[iata] ?? _generic(cityName, country);

    return SmartTravelAdvisorResponse(
      groupAnalysis: GroupAnalysis(
        vibeType: profile.groupType.label,
        personalizedNote:
            '${profile.summaryLabel} için $cityName planı: ${profile.groupType.travelStyleHint}',
      ),
      weatherForecast: AdvisorWeatherForecast(
        status: _weatherLine(cityName, departureDate),
        clothingSuggestions: ClothingSuggestions(
          daily: content.dailyClothing,
          activitySpecific: content.activityClothing,
        ),
      ),
      goldenRules: content.goldenRules,
      liveEventsAffiliate: AdvisorEventsCatalog.forIata(iata),
      currencyConverter: CurrencyConverter(
        localCurrency: currency,
        currentRateText:
            '1 $currency ≈ ${fxRateTl.round()} TL. Harcamalarınızı buna göre planlayın.',
      ),
      source: 'offline_fallback',
    );
  }

  static String _weatherLine(String city, DateTime dep) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    final m = dep.month;
    if (m >= 6 && m <= 9) {
      return '$city · ${months[m - 1]}: sıcak/kurak sezon — gündüz 35°C+, akşam daha serin.';
    }
    if (m >= 11 || m <= 2) {
      return '$city · ${months[m - 1]}: ılıman-kurak — gündüz rahat, akşam hafif serin.';
    }
    return '$city · ${months[m - 1]}: geçiş mevsimi — katmanlı giyim ve hafif yağmurluk iyi olur.';
  }

  static _AdvisorContent _generic(String city, String country) {
    return _AdvisorContent(
      goldenRules: [
        'Resmi kuralları ve yerel adetleri önceden kontrol edin.',
        '$city ($country) için pasaport/vize ve sigorta belgelerinizi yanınızda bulundurun.',
        'Yoğun turistik bölgelerde dolandırıcılığa karşı resmi satıcı ve uygulama kullanın.',
      ],
      dailyClothing: 'Rahat yürüyüş ayakkabısı, güneş/klima için ince üst katman.',
      activityClothing: 'Planladığınız aktiviteye göre mayo, spor veya şık giyim ayrı çantada.',
    );
  }

  static final Map<String, _AdvisorContent> _content = {
    'DXB': _AdvisorContent(
      goldenRules: [
        'Kamusal alanda alkol tüketmeyin — yalnızca lisanslı mekânlarda.',
        'AVM, metro ve cami girişlerinde omuz-diz örtülü giyinin.',
        'İzinsiz kişileri ve güvenlik alanlarını fotoğraflamayın.',
        'Temmuz–Ağustos 45°C+ olabilir; öğlen açık alan turu planlamayın.',
      ],
      dailyClothing:
          'Hafif pamuklu kıyafet, şapka, SPF 50+ güneş kremi, klimalı mekânlar için ince üst.',
      activityClothing:
          'Çöl safarisi: kapalı ayakkabı, buff/maske, gözlük. AVM: omuz örtüsü.',
    ),
    'IST': _AdvisorContent(
      goldenRules: [
        'Camii ziyaretlerinde başörtüsü ve uygun kıyafet şart.',
        'Taksim–Sultanahmet arası yoğun; metro/tramvay ve resmi taksi tercih edin.',
        'Bahşiş zorunlu değil; iyi hizmet için %5–10 bırakılabilir.',
      ],
      dailyClothing: 'Rahat yürüyüş ayakkabısı, mevsime göre yağmurluk veya hafif mont.',
      activityClothing: 'Boğaz turu için rüzgârlık; Kapalıçarşı için omuz çantası.',
    ),
    'AYT': _AdvisorContent(
      goldenRules: [
        'Plajda şehir merkezi kuralları geçerli — aşırı alkol kamusal alanda sorun olabilir.',
        'Güneşte 11:00–15:00 arası dinlenme planlayın.',
        'Antalya Havalimanı–otel transferinde resmi firma veya uygulama kullanın.',
      ],
      dailyClothing: 'Mayo, şapka, güneş kremi, akşam hafif üst.',
      activityClothing: 'Tekne turu için kaymaz ayakkabı; Kaleiçi için rahat sandalet.',
    ),
    'FCO': _AdvisorContent(
      goldenRules: [
        'Cenova ve Vatikan’da omuz ve diz kapalı olmalı.',
        'Pickpocket riski yüksek — metro ve turistik meydanlarda çanta önde.',
        'Restoranlarda oturma ücreti (coperto) hesaba eklenebilir.',
      ],
      dailyClothing: 'Yürüyüş ayakkabısı, yazın hafif kıyafet, akşam ince üst.',
      activityClothing: 'Vatikan/cami ziyareti için omuz örtüsü ve uzun pantolon.',
    ),
  };
}

class _AdvisorContent {
  const _AdvisorContent({
    required this.goldenRules,
    required this.dailyClothing,
    required this.activityClothing,
  });

  final List<String> goldenRules;
  final String dailyClothing;
  final String activityClothing;
}
