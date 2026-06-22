import '../config/app_experience.dart';

/// Rezervasyon kapsamı — tam paket veya tek ürün.
enum BookingScope {
  package,
  flightOnly,
  hotelOnly,
}

enum CheckoutFlowStep {
  flight,
  hotel,
  summary,
  passenger,
  payment,
}

List<CheckoutFlowStep> checkoutFlowFor(BookingScope scope) {
  final steps = switch (scope) {
    BookingScope.flightOnly => const [
        CheckoutFlowStep.flight,
        CheckoutFlowStep.summary,
        CheckoutFlowStep.passenger,
        CheckoutFlowStep.payment,
      ],
    BookingScope.hotelOnly => const [
        CheckoutFlowStep.hotel,
        CheckoutFlowStep.summary,
        CheckoutFlowStep.passenger,
        CheckoutFlowStep.payment,
      ],
    BookingScope.package => const [
        CheckoutFlowStep.flight,
        CheckoutFlowStep.hotel,
        CheckoutFlowStep.summary,
        CheckoutFlowStep.passenger,
        CheckoutFlowStep.payment,
      ],
  };
  if (AppExperience.paymentsEnabled) return steps;
  return steps.where((s) => s != CheckoutFlowStep.payment).toList();
}

String checkoutStepLabel(CheckoutFlowStep step) {
  switch (step) {
    case CheckoutFlowStep.flight:
      return 'Uçuş';
    case CheckoutFlowStep.hotel:
      return 'Otel';
    case CheckoutFlowStep.summary:
      return 'Özet';
    case CheckoutFlowStep.passenger:
      return 'Yolcu';
    case CheckoutFlowStep.payment:
      return 'Ödeme';
  }
}

String checkoutStepTitle(CheckoutFlowStep step) {
  switch (step) {
    case CheckoutFlowStep.flight:
      return 'Uçuş Seç';
    case CheckoutFlowStep.hotel:
      return 'Otel Seç';
    case CheckoutFlowStep.summary:
      return 'Rezervasyon Özeti';
    case CheckoutFlowStep.passenger:
      return 'Yolcu Bilgileri';
    case CheckoutFlowStep.payment:
      return 'Ödeme';
  }
}
