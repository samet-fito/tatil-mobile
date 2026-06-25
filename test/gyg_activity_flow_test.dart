import 'package:flutter_test/flutter_test.dart';
import 'package:tatil_arama/config/gyg_affiliate_config.dart';
import 'package:tatil_arama/data/commission_activities.dart';
import 'package:tatil_arama/data/gyg_activity_catalog.dart';
import 'package:tatil_arama/services/gyg_affiliate_service.dart';

void main() {
  test('Amsterdam catalog has at least 4 activities', () {
    final list = GygActivityCatalog.forCity('Amsterdam', 'AMS');
    expect(list, isNotNull);
    expect(list!.length, greaterThanOrEqualTo(4));
    expect(list.first['imageUrl'], isNotEmpty);
    expect(list.first['detail'], isNotEmpty);
  });

  test('mock API response merges catalog for Amsterdam', () {
    final result = CommissionActivities.fromApiActivities(
      {
        'source': 'mock',
        'activities': {
          'withinTrip': [
            {
              'id': 'def-1',
              'category': 'tours',
              'title': 'Amsterdam Şehir Turu',
              'description': 'Genel',
              'duration': '3 saat',
              'rating': 4.5,
              'reviewCount': 200,
              'priceTL': 800,
            },
          ],
          'nearby': [],
        },
      },
      'AMS',
      'Amsterdam',
    );

    expect(result['dataSource'], 'catalog');
    expect(result['subtitle'], contains('uygulama içinde'));
    final count = CommissionActivities.totalActivityCount(result);
    expect(count, greaterThanOrEqualTo(4));
  });

  test('GYG purchase link includes partner_id OSFL8L1', () {
    expect(GygAffiliateConfig.partnerId, 'OSFL8L1');

    final uri = GygAffiliateService.citySearchUri('Amsterdam');
    expect(uri.queryParameters['partner_id'], 'OSFL8L1');
    expect(uri.queryParameters['cmp'], 'vizegoo');
    expect(uri.toString(), contains('Amsterdam'));
  });

  test('activity link uses gygSearchQuery when present', () {
    final uri = GygAffiliateService.tourUri(
      title: 'Test',
      cityName: 'Amsterdam',
      gygSearchQuery: 'Amsterdam canal cruise',
    );
    expect(uri.queryParameters['partner_id'], 'OSFL8L1');
    expect(uri.queryParameters['q'], 'Amsterdam canal cruise');
  });
}
