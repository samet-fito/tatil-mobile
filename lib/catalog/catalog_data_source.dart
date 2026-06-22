/// Veri kaynağı — canlı API, affiliate veya yerel katalog.
enum CatalogDataSource {
  liveApi,
  affiliate,
  supabase,
  localCatalog,
}

extension CatalogDataSourceMeta on CatalogDataSource {
  String get label {
    switch (this) {
      case CatalogDataSource.liveApi:
        return 'Canlı API';
      case CatalogDataSource.affiliate:
        return 'Affiliate';
      case CatalogDataSource.supabase:
        return 'Partner katalog';
      case CatalogDataSource.localCatalog:
        return 'Yerel katalog';
    }
  }

  /// Gelecekte affiliate sağlayıcı kimliği (ör. skyscanner, booking).
  String? get providerSlot => switch (this) {
        CatalogDataSource.affiliate => 'affiliate',
        CatalogDataSource.liveApi => 'gateway',
        CatalogDataSource.supabase => 'supabase',
        CatalogDataSource.localCatalog => 'local',
      };
}
