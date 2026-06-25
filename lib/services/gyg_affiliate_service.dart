import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/gyg_affiliate_config.dart';

/// GetYourGuide affiliate deep link üretimi ve tarayıcıda açma.
///
/// GYG, uygulama içi WebView yerine **harici tarayıcı** ile açılmayı önerir
/// (1st-party cookie / komisyon takibi için).
abstract final class GygAffiliateService {
  static const _base = 'https://www.getyourguide.com';

  static const _cityCountry = <String, String>{
    'Roma': 'Italy',
    'Paris': 'France',
    'Amsterdam': 'Netherlands',
    'Barselona': 'Spain',
    'Barcelona': 'Spain',
    'Atina': 'Greece',
    'Budapeşte': 'Hungary',
    'Lizbon': 'Portugal',
    'Lisbon': 'Portugal',
    'İstanbul': 'Turkey',
    'Istanbul': 'Turkey',
    'Antalya': 'Turkey',
    'Dubai': 'United Arab Emirates',
    'Londra': 'United Kingdom',
    'London': 'United Kingdom',
    'Berlin': 'Germany',
    'Prag': 'Czech Republic',
    'Prague': 'Czech Republic',
    'Osaka': 'Japan',
    'Kyoto': 'Japan',
  };

  static bool get isConfigured =>
      GygAffiliateConfig.partnerId.trim().isNotEmpty;

  static Uri citySearchUri(String cityName) {
    final country = _cityCountry[cityName] ?? '';
    final query = country.isNotEmpty ? '$cityName, $country' : cityName;
    return _searchUri(query);
  }

  static Uri activitySearchUri({
    required String title,
    required String cityName,
  }) {
    return _searchUri('$title $cityName');
  }

  static Uri tourUri({
    int? tourId,
    String? gygUrl,
    String? gygSearchQuery,
    required String title,
    required String cityName,
  }) {
    if (gygSearchQuery != null && gygSearchQuery.trim().isNotEmpty) {
      return _searchUri(gygSearchQuery.trim());
    }
    if (gygUrl != null && gygUrl.trim().isNotEmpty) {
      return _withPartner(Uri.parse(gygUrl.trim()));
    }
    if (tourId != null) {
      return _withPartner(Uri.parse('$_base/-t$tourId/'));
    }
    return activitySearchUri(title: title, cityName: cityName);
  }

  static Uri _searchUri(String query) {
    return _withPartner(
      Uri.parse('$_base/s/').replace(
        queryParameters: {
          'q': query,
          if (GygAffiliateConfig.localeCode.isNotEmpty)
            'locale_code': GygAffiliateConfig.localeCode,
        },
      ),
    );
  }

  static Uri _withPartner(Uri uri) {
    final params = Map<String, String>.from(uri.queryParameters);
    final partnerId = GygAffiliateConfig.partnerId.trim();
    if (partnerId.isNotEmpty) {
      params['partner_id'] = partnerId;
    }
    if (GygAffiliateConfig.campaign.isNotEmpty) {
      params['cmp'] = GygAffiliateConfig.campaign;
    }
    return uri.replace(queryParameters: params);
  }

  static Future<bool> openUri(
    BuildContext context,
    Uri uri, {
    bool warnIfUnconfigured = true,
  }) async {
    if (warnIfUnconfigured && !isConfigured && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Partner ID henüz ayarlanmadı — link açılacak ancak komisyon '
            'takibi çalışmayabilir. lib/config/gyg_affiliate_config.dart dosyasına '
            'Partner ID ekleyin.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GetYourGuide bağlantısı açılamadı.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return ok;
  }

  static Future<bool> openCity(BuildContext context, String cityName) =>
      openUri(context, citySearchUri(cityName));

  static Future<bool> openActivity(
    BuildContext context, {
    required Map<String, dynamic> activity,
    required String cityName,
  }) {
    final tourRaw = activity['gygTourId'];
    final tourId = tourRaw is int
        ? tourRaw
        : int.tryParse(tourRaw?.toString() ?? '');
    return openUri(
      context,
      tourUri(
        tourId: tourId,
        gygUrl: activity['gygUrl'] as String?,
        gygSearchQuery: activity['gygSearchQuery'] as String?,
        title: activity['title'] as String? ?? 'activity',
        cityName: cityName,
      ),
    );
  }
}
