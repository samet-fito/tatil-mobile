/// Katalog sağlayıcı kimlikleri — API ve affiliate entegrasyonları için sabit slotlar.
abstract final class CatalogProviderRegistry {
  static const busLive = 'bus-gateway';
  static const carRentalLive = 'car-rental-gateway';
  static const transferSupabase = 'transfer-supabase';

  /// Gelecek affiliate entegrasyonları için rezerve slotlar.
  static const affiliateBus = 'affiliate-bus';
  static const affiliateCar = 'affiliate-car';
  static const affiliateTransfer = 'affiliate-transfer';
}
