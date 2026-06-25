/// GetYourGuide Yönlendirme Programı (affiliate) ayarları.
///
/// Partner ID: partner.getyourguide.com → profil / Account Details
abstract final class GygAffiliateConfig {
  /// Boş bırakılırsa linkler partner_id olmadan açılır (komisyon takibi olmaz).
  static const String partnerId = 'OSFL8L1';

  /// `true`: aktivite rezervasyonu GetYourGuide sitesinde (tarayıcı).
  /// `false`: uygulama içi checkout + Partner API (token gerekir).
  static const bool useAffiliateLinks = true;

  /// Analytics kampanya etiketi (partner portal raporlarında görünür).
  static const String campaign = 'vizegoo';

  /// GetYourGuide içerik dili.
  static const String localeCode = 'tr-TR';
}
