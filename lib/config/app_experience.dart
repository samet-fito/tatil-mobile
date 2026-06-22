/// Uygulama deneyimi bayrakları — ödeme entegrasyonu hazır olunca açılır.
abstract final class AppExperience {
  /// `false`: ödeme adımı gizlenir, kullanıcı akışı önizleme olarak tamamlar.
  static const bool paymentsEnabled = false;

  /// Önizlemede 3D Secure ekranını göster (gerçek tahsilat yok).
  static const bool runPaymentSimulation = true;

  static const previewBannerText =
      'Önizleme modu — ödeme ve gerçek bilet kesimi yakında. Şimdilik tüm adımları deneyebilirsiniz.';

  static const previewSuccessNote =
      'Bu bir önizleme rezervasyonudur; bilet veya voucher henüz kesilmez.';

  static const confirmReservationLabel = 'Rezervasyonu Onayla';

  static const completeFlowLabel = 'Rezervasyonu Tamamla';

  static const resultsPreviewNote =
      'Fiyatlar bilgilendirme amaçlıdır; kesin tutar ödeme entegrasyonu sonrası doğrulanacaktır.';
}
