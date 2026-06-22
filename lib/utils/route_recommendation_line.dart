import '../data/holiday_types.dart';
import '../models/budget_package_offer.dart';
import '../models/route_result_model.dart';
import '../utils/price_format.dart';

/// Arama sonuç kartında tek satırlık "neden bu rota?" açıklaması.
class RouteRecommendationLine {
  RouteRecommendationLine._();

  static String build({
    required RouteResultModel route,
    BudgetPackageOffer? offer,
    List<String> holidayTypes = const [],
    int rank = 1,
    double? serviceScore,
  }) {
    if (route.isBestChoice) {
      return 'En yüksek eşleşme skoru — arama kriterlerinize en uygun paket';
    }

    if (holidayTypes.isNotEmpty) {
      final labels = HolidayTypes.labelsOf(holidayTypes);
      if (labels.isNotEmpty) {
        final extra = labels.length > 1
            ? ' · ${labels.sublist(1, labels.length.clamp(0, 3)).join(', ')}'
            : '';
        return '${labels.first} tatili için ${route.cityName} önerisi$extra';
      }
    }

    if (offer != null) {
      switch (offer.fitKind) {
        case BudgetFitKind.liveWithinBudget:
          return 'Canlı uçuş + otel fiyatı bütçenizin içinde';
        case BudgetFitKind.planWithinBudget:
          return 'Plan fiyatı bütçenize uyuyor — canlı fiyatlar kontrol edildi';
        case BudgetFitKind.planOnly:
          return 'Bütçenize uygun plan tahmini — detayda canlı fiyat güncellenir';
        case BudgetFitKind.overBudget:
          final gap = offer.budgetGapTL;
          if (gap > 0) {
            return 'Bütçenizi ${PriceFormat.format(gap)} aşıyor; alternatif olarak değerlendirin';
          }
          return 'Bütçenizi aşıyor; alternatif olarak değerlendirin';
        case BudgetFitKind.unscoped:
          break;
      }

      if (offer.hasVerifiedRoundTripFlight && offer.hotelsFromLive) {
        return 'Doğrulanmış gidiş-dönüş uçuş ve canlı otel fiyatı';
      }
    }

    if (rank == 1) {
      return 'Listenin başı — tarih ve bütçe tercihlerinize en yakın rota';
    }

    final score = serviceScore ?? route.hotel?.reviewScore;
    if (score != null && score >= 8.5) {
      return 'Yüksek otel puanı (${score.toStringAsFixed(1)}) — konfor odaklı seçenek';
    }

    if (route.nights >= 5) {
      return '${route.nights} gece konaklama — uzun tatil için dengeli plan';
    }

    return '${route.cityName} — fiyat ve konaklama dengesi iyi';
  }
}
