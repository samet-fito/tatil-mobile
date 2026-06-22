import 'budget_package_offer.dart';
import 'route_search_outcome.dart';

class BudgetSearchOutcome {
  const BudgetSearchOutcome({
    required this.offers,
    this.failure,
    this.message,
    this.bannerMessage,
    this.liveEnrichedCount = 0,
  });

  final List<BudgetPackageOffer> offers;
  final RouteSearchFailure? failure;
  final String? message;
  final String? bannerMessage;
  final int liveEnrichedCount;

  bool get isSuccess => offers.isNotEmpty;

  int get withinBudgetCount =>
      offers.where((o) => o.isWithinBudget).length;

  String get userMessage {
    if (offers.isNotEmpty) return '';
    if (message != null && message!.trim().isNotEmpty) return message!.trim();

    switch (failure) {
      case RouteSearchFailure.timeout:
        return 'Sunucu yanıt vermedi. Birkaç saniye bekleyip tekrar deneyin.';
      case RouteSearchFailure.connection:
        return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
      case RouteSearchFailure.serverError:
        return 'Arama sunucusu hata döndü. Lütfen tekrar deneyin.';
      case RouteSearchFailure.rateLimited:
        return message?.trim().isNotEmpty == true
            ? message!.trim()
            : 'Çok fazla istek gönderildi. Bir dakika bekleyip tekrar deneyin.';
      case RouteSearchFailure.emptyPackages:
        return 'Bu kriterlerle uygun rota bulunamadı. Bütçeyi veya tarihleri güncelleyin.';
      case RouteSearchFailure.parseError:
        return 'Rota verisi işlenemedi. Lütfen tekrar deneyin.';
      case null:
        return 'Rota bulunamadı.';
    }
  }
}
