import '../models/search_category.dart';

class CouponResult {
  const CouponResult({
    required this.code,
    required this.discountTL,
    required this.message,
    this.category,
  });

  final String code;
  final int discountTL;
  final String message;
  final SearchCategory? category;
}

/// Kupon doğrulama — önizleme modunda sabit kodlar; ödeme aktif olunca API'ye taşınır.
abstract final class CouponService {
  static const _codes = {
    'VIZE50': _CouponDef(50, null, '50 TL indirim uygulandı'),
    'VIZE100': _CouponDef(100, SearchCategory.flight, 'Uçuşlarda 100 TL indirim'),
    'YAZ250': _CouponDef(250, SearchCategory.packageTour, 'Paket turda 250 TL indirim'),
    'TUR50': _CouponDef(50, SearchCategory.activities, 'Aktivitede 50 TL indirim'),
    'OTEL10': _CouponDef(0, SearchCategory.hotel, 'Otel kampanyası kaydedildi — %10 yakında'),
  };

  static CouponResult? validate({
    required String rawCode,
    SearchCategory? checkoutCategory,
    int subtotalTL = 0,
  }) {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return null;

    final def = _codes[code];
    if (def == null) {
      return null;
    }

    if (def.category != null &&
        checkoutCategory != null &&
        def.category != checkoutCategory) {
      return null;
    }

    if (def.discountTL > 0 && subtotalTL > 0 && def.discountTL >= subtotalTL) {
      return CouponResult(
        code: code,
        discountTL: (subtotalTL * 0.15).round().clamp(50, def.discountTL),
        message: 'İndirim uygulandı (tutar sepete göre ayarlandı)',
        category: def.category,
      );
    }

    return CouponResult(
      code: code,
      discountTL: def.discountTL,
      message: def.message,
      category: def.category,
    );
  }

  static String? errorMessage(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return 'Kupon kodu girin';
    if (_codes.containsKey(code)) return null;
    return 'Geçersiz veya süresi dolmuş kupon';
  }
}

class _CouponDef {
  const _CouponDef(this.discountTL, this.category, this.message);

  final int discountTL;
  final SearchCategory? category;
  final String message;
}
