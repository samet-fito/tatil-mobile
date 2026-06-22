import 'route_result_model.dart';

enum RouteSearchFailure {
  connection,
  timeout,
  serverError,
  rateLimited,
  emptyPackages,
  parseError,
}

class RouteSearchOutcome {
  final List<RouteResultModel> routes;
  final RouteSearchFailure? failure;
  final String? message;
  final int rawPackageCount;
  final int parseFailures;

  const RouteSearchOutcome({
    required this.routes,
    this.failure,
    this.message,
    this.rawPackageCount = 0,
    this.parseFailures = 0,
  });

  bool get isSuccess => routes.isNotEmpty;

  String get userMessage {
    if (routes.isNotEmpty) return '';
    if (message != null && message!.trim().isNotEmpty) return message!.trim();

    switch (failure) {
      case RouteSearchFailure.timeout:
        return 'Sunucu yanıt vermedi. Birkaç saniye bekleyip tekrar deneyin.';
      case RouteSearchFailure.connection:
        return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
      case RouteSearchFailure.serverError:
        return 'Arama sunucusu hata döndü. Lütfen tekrar deneyin.';
      case RouteSearchFailure.rateLimited:
        return message != null && message!.trim().isNotEmpty
            ? message!.trim()
            : 'Çok fazla istek gönderildi. Bir dakika bekleyip tekrar deneyin.';
      case RouteSearchFailure.emptyPackages:
        return 'Bu kriterlerle uygun rota bulunamadı. Bütçeyi veya tarihleri güncelleyin.';
      case RouteSearchFailure.parseError:
        return 'Rota verileri okunamadı. Lütfen tekrar deneyin.';
      case null:
        return 'Rota sunucusuna ulaşılamadı veya arama sonucu boş döndü. Lütfen tekrar deneyin.';
    }
  }
}
