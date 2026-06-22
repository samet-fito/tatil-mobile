/// Uçuş kabin sınıfı — arama ve fiyat çarpanı.
enum FlightCabinClass {
  economy,
  premiumEconomy,
  business,
}

extension FlightCabinClassMeta on FlightCabinClass {
  String get label {
    switch (this) {
      case FlightCabinClass.economy:
        return 'Ekonomi';
      case FlightCabinClass.premiumEconomy:
        return 'Premium Ekonomi';
      case FlightCabinClass.business:
        return 'Business';
    }
  }

  /// API kabin farkı yoksa gösterim fiyatına uygulanan çarpan.
  double get priceMultiplier {
    switch (this) {
      case FlightCabinClass.economy:
        return 1.0;
      case FlightCabinClass.premiumEconomy:
        return 1.35;
      case FlightCabinClass.business:
        return 2.1;
    }
  }

  String get apiValue {
    switch (this) {
      case FlightCabinClass.economy:
        return 'economy';
      case FlightCabinClass.premiumEconomy:
        return 'premium_economy';
      case FlightCabinClass.business:
        return 'business';
    }
  }
}
