import 'package:flutter_test/flutter_test.dart';
import 'package:tatil_arama/models/smart_travel_advisor_model.dart';

void main() {
  test('parses advisor JSON schema', () {
    final advisor = SmartTravelAdvisorResponse.fromJson({
      'group_analysis': {
        'vibe_type': 'Cocuklu Aile',
        'personalized_note': 'Rotayi cocugunuza gore optimize ettik.',
      },
      'weather_forecast': {
        'status': 'Temmuz sicak (~32C)',
        'clothing_suggestions': {
          'daily': 'Hafif keten',
          'activity_specific': 'Spor ayakkabi',
        },
      },
      'golden_rules': ['Nasone suyu icilebilir'],
      'live_events_affiliate': [
        {
          'event_name': 'Coldplay',
          'date': '9 Temmuz 2026',
          'ticket_affiliate_url': 'https://example.com',
          'description': 'Stadyum konseri',
        },
      ],
      'currency_converter': {
        'local_currency': 'EUR',
        'current_rate_text': '1 Euro = 35 TL',
      },
    });

    expect(advisor.groupAnalysis.vibeType, contains('Aile'));
    expect(advisor.goldenRules.length, 1);
    expect(advisor.liveEventsAffiliate.first.eventName, 'Coldplay');
    expect(advisor.weatherForecast.clothingSuggestions.daily, isNotEmpty);
  });
}
