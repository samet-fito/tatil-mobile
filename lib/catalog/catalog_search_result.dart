import 'catalog_data_source.dart';

enum CatalogSearchStatus {
  success,
  empty,
  fallback,
  error,
}

/// Kategori arama sonucu — tüm ürün tipleri (otobüs, araç, transfer vb.) için ortak.
class CatalogSearchResult {
  const CatalogSearchResult({
    required this.items,
    required this.source,
    required this.status,
    this.errorMessage,
    this.providerId,
  });

  final List<Map<String, dynamic>> items;
  final CatalogDataSource source;
  final CatalogSearchStatus status;
  final String? errorMessage;

  /// İleride affiliate / API sağlayıcı kimliği.
  final String? providerId;

  bool get isEmpty => items.isEmpty;
  bool get hasItems => items.isNotEmpty;
  bool get isFallback => status == CatalogSearchStatus.fallback;
  bool get isError => status == CatalogSearchStatus.error;

  String get sourceLabel => source.label;

  String get statusHint {
    switch (status) {
      case CatalogSearchStatus.success:
        return sourceLabel;
      case CatalogSearchStatus.fallback:
        return '$sourceLabel · yedek katalog';
      case CatalogSearchStatus.empty:
        return 'Sonuç yok';
      case CatalogSearchStatus.error:
        return errorMessage ?? 'Bağlantı hatası';
    }
  }

  factory CatalogSearchResult.success(
    List<Map<String, dynamic>> items,
    CatalogDataSource source, {
    String? providerId,
  }) {
    return CatalogSearchResult(
      items: items,
      source: source,
      status: items.isEmpty
          ? CatalogSearchStatus.empty
          : CatalogSearchStatus.success,
      providerId: providerId,
    );
  }

  factory CatalogSearchResult.fallback(
    List<Map<String, dynamic>> items, {
    String? apiError,
    CatalogDataSource source = CatalogDataSource.localCatalog,
  }) {
    return CatalogSearchResult(
      items: items,
      source: source,
      status: items.isEmpty
          ? CatalogSearchStatus.error
          : CatalogSearchStatus.fallback,
      errorMessage: apiError,
    );
  }

  factory CatalogSearchResult.failure({String? message}) {
    return CatalogSearchResult(
      items: const [],
      source: CatalogDataSource.liveApi,
      status: CatalogSearchStatus.error,
      errorMessage: message ?? 'Arama tamamlanamadı',
    );
  }
}
