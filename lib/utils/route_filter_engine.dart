import '../data/destination_vibes.dart';
import '../models/route_result_model.dart';
import '../models/search_model.dart';

/// Filtrelenmiş ve sıralanmış rota + uyarı mesajları.
class RouteFilterResult {
  final List<RankedRoute> routes;
  final String? bannerMessage;
  final bool usedRatingFallback;

  const RouteFilterResult({
    required this.routes,
    this.bannerMessage,
    this.usedRatingFallback = false,
  });
}

class RankedRoute {
  final RouteResultModel route;
  final String? upgradeWarning;
  final bool isPreferredRating;

  const RankedRoute({
    required this.route,
    this.upgradeWarning,
    this.isPreferredRating = true,
  });
}

class RouteFilterEngine {
  static double serviceScore(RouteResultModel route) {
    final hotel = route.hotel?.reviewScore;
    if (hotel != null && hotel > 0) return hotel;
    if (route.matchPercentage > 0) return route.matchPercentage / 10.0;
    return route.score > 0 ? (route.score / 10.0).clamp(5.0, 10.0) : 7.0;
  }

  static int totalCost(RouteResultModel route) => route.estimatedCost.total;

  static RouteFilterResult apply({
    required List<RouteResultModel> routes,
    required double budgetTL,
    List<String> holidayTypes = const [],
    double minRating = 5.0,
    double maxRating = 10.0,
    bool sortByCheapest = false,
  }) {
    var list = routes.toList();
    final hasBudget = budgetTL >= SearchModel.minBudgetTL;

    if (holidayTypes.isNotEmpty) {
      list = list
          .where((r) => DestinationVibes.matchesAll(
                r.destinationIata,
                holidayTypes,
                vibeBadge: r.vibeBadge,
              ))
          .toList();
    }

    final inRating = list.where((r) {
      final s = serviceScore(r);
      return s >= minRating && s <= maxRating;
    }).toList();

    if (!hasBudget) {
      var chosen = inRating.isNotEmpty ? inRating : list;
      if (chosen.isEmpty && routes.isNotEmpty) chosen = routes;

      if (sortByCheapest) {
        chosen.sort((a, b) => totalCost(a).compareTo(totalCost(b)));
      } else {
        chosen.sort((a, b) => b.score.compareTo(a.score));
      }

      final ranked = chosen
          .map(
            (route) => RankedRoute(
              route: route,
              isPreferredRating: serviceScore(route) >= minRating &&
                  serviceScore(route) <= maxRating,
            ),
          )
          .toList();

      return RouteFilterResult(routes: ranked);
    }

    final inRatingAffordable =
        inRating.where((r) => r.isAffordable || totalCost(r) <= budgetTL).toList();

    final belowRatingAffordable = list.where((r) {
      final s = serviceScore(r);
      return s < minRating && (r.isAffordable || totalCost(r) <= budgetTL);
    }).toList();

    final inRatingOverBudget = inRating.where((r) {
      return !r.isAffordable && totalCost(r) > budgetTL;
    }).toList();

    List<RouteResultModel> chosen;
    String? banner;
    var usedFallback = false;

    if (inRatingAffordable.isNotEmpty) {
      chosen = inRatingAffordable;
    } else if (inRatingOverBudget.isNotEmpty) {
      chosen = inRatingOverBudget;
      banner =
          'Seçtiğiniz hizmet puanı aralığında rotalar bütçenizi biraz aşıyor. '
          'Fark az ise yükseltmeyi düşünebilirsiniz.';
    } else if (belowRatingAffordable.isNotEmpty) {
      chosen = belowRatingAffordable;
      usedFallback = true;
      banner =
          'Seçtiğiniz puan aralığında ($minRating–$maxRating) bütçeye uygun rota bulunamadı. '
          'Fiyat/performans odaklı alternatifler listeleniyor.';
    } else {
      chosen = list;
    }

    if (chosen.isEmpty && routes.isNotEmpty) {
      chosen = routes;
      banner ??= 'Filtrelere tam uyan rota yok; tüm sonuçlar gösteriliyor.';
    }

    if (sortByCheapest) {
      chosen.sort((a, b) => totalCost(a).compareTo(totalCost(b)));
    } else {
      chosen.sort((a, b) {
        final afford = (b.isAffordable ? 1 : 0) - (a.isAffordable ? 1 : 0);
        if (afford != 0) return afford;
        return b.score.compareTo(a.score);
      });
    }

    const upgradeThreshold = 0.12;
    final ranked = chosen.map((route) {
      final score = serviceScore(route);
      final cost = totalCost(route);
      final inPreferred = score >= minRating && score <= maxRating;
      String? warning;

      if (inPreferred &&
          !route.isAffordable &&
          cost > budgetTL &&
          cost <= budgetTL * (1 + upgradeThreshold)) {
        final diff = cost - budgetTL.toInt();
        warning =
            'Bütçenizden ${diff > 0 ? diff : 0} TL farkla daha yüksek puanlı hizmet';
      } else if (!inPreferred && usedFallback) {
        warning = 'Hizmet puanı ${score.toStringAsFixed(1)} · bütçe dostu seçenek';
      }

      return RankedRoute(
        route: route,
        upgradeWarning: warning,
        isPreferredRating: inPreferred,
      );
    }).toList();

    return RouteFilterResult(
      routes: ranked,
      bannerMessage: banner,
      usedRatingFallback: usedFallback,
    );
  }
}
