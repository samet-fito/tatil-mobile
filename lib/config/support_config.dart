/// Canlı destek iletişim bilgileri.
abstract final class SupportConfig {
  static const supportEmail = 'destek@vizegoo.com';
  static const supportHours = '09:00 – 22:00 (TR)';
  /// Uluslararası format, başında + yok (wa.me için).
  static const whatsAppNumber = '905054712323';

  static String get mailtoUrl =>
      'mailto:$supportEmail?subject=${Uri.encodeComponent('Vizegoo Destek')}';

  static String whatsAppUrl({String? prefilledMessage}) {
    final msg = prefilledMessage ??
        'Merhaba, Vizegoo uygulamasından destek almak istiyorum.';
    return 'https://wa.me/$whatsAppNumber?text=${Uri.encodeComponent(msg)}';
  }
}
