/// Taksit planları — checkout ödeme adımı.
class InstallmentOption {
  const InstallmentOption({
    required this.months,
    this.interestFree = false,
    this.badge,
  });

  final int months;
  final bool interestFree;
  final String? badge;
}

abstract final class InstallmentPlans {
  static const options = [
    InstallmentOption(months: 2, interestFree: true, badge: 'Vade farksız'),
    InstallmentOption(months: 3, interestFree: true, badge: 'Vade farksız'),
    InstallmentOption(months: 6),
    InstallmentOption(months: 9),
    InstallmentOption(months: 12, badge: 'En düşük taksit'),
  ];

  static int monthlyAmountTL(int totalTL, int months) {
    if (months <= 0) return totalTL;
    return (totalTL / months).ceil();
  }

  static InstallmentOption? recommendedFor(int totalTL) {
    if (totalTL >= 15000) return options[2]; // 6 ay
    if (totalTL >= 5000) return options[1]; // 3 ay vade farksız
    return options[0];
  }
}
