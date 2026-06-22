import 'dart:convert';

import '../models/route_result_model.dart';
import '../models/route_search_outcome.dart';
import '../models/search_model.dart';
import 'api_service.dart';

class _CacheEntry {
  final List<RouteResultModel> routes;
  final DateTime storedAt;

  const _CacheEntry(this.routes, this.storedAt);

  bool isValid(Duration ttl) => DateTime.now().difference(storedAt) <= ttl;
}

/// Rota aramasının tek giriş noktası — önbellek, eşzamanlı istek birleştirme ve retry.
class RouteSearchService {
  RouteSearchService._();

  static const _cacheTtl = Duration(minutes: 10);
  static const _warmInterval = Duration(seconds: 45);

  static final Map<String, _CacheEntry> _cache = {};
  static final Map<String, Future<RouteSearchOutcome>> _inFlight = {};
  static DateTime? _gatewayWarmedAt;

  static void remember(SearchModel model, List<RouteResultModel> routes) {
    if (routes.isEmpty) return;
    _cache[model.routeSearchCacheKey] = _CacheEntry(
      List<RouteResultModel>.from(routes),
      DateTime.now(),
    );
  }

  static void clearCache() {
    _cache.clear();
    _inFlight.clear();
    _gatewayWarmedAt = null;
  }

  static Future<RouteSearchOutcome> search(
    SearchModel model, {
    bool forceNetwork = false,
  }) async {
    final key = model.routeSearchCacheKey;

    if (!forceNetwork) {
      final cached = _readCache(key);
      if (cached != null) {
        return RouteSearchOutcome(
          routes: cached,
          rawPackageCount: cached.length,
        );
      }

      final pending = _inFlight[key];
      if (pending != null) return pending;
    }

    final future = _fetchWithRetry(model);
    if (!forceNetwork) {
      _inFlight[key] = future;
    }

    try {
      final outcome = await future;
      if (outcome.isSuccess) {
        remember(model, outcome.routes);
      }
      return outcome;
    } finally {
      if (!forceNetwork) {
        _inFlight.remove(key);
      }
    }
  }

  /// Ağ başarısız olursa son başarılı önbelleğe düşer.
  static Future<RouteSearchOutcome> searchWithCacheFallback(
    SearchModel model, {
    bool forceNetwork = false,
  }) async {
    final outcome = await search(model, forceNetwork: forceNetwork);
    if (outcome.isSuccess || forceNetwork == false) return outcome;

    final cached = _readCache(model.routeSearchCacheKey);
    if (cached != null) {
      return RouteSearchOutcome(
        routes: cached,
        rawPackageCount: cached.length,
      );
    }
    return outcome;
  }

  static List<RouteResultModel>? _readCache(String key) {
    final entry = _cache[key];
    if (entry == null || !entry.isValid(_cacheTtl)) {
      _cache.remove(key);
      return null;
    }
    return List<RouteResultModel>.from(entry.routes);
  }

  static Future<void> prewarm() => _warmGatewayIfNeeded();

  static Future<void> _warmGatewayIfNeeded() async {
    final warmedAt = _gatewayWarmedAt;
    if (warmedAt != null &&
        DateTime.now().difference(warmedAt) < _warmInterval) {
      return;
    }

    try {
      await ApiService.warmGateway();
      _gatewayWarmedAt = DateTime.now();
    } catch (_) {}
  }

  static Future<RouteSearchOutcome> _fetchWithRetry(SearchModel model) async {
    await _warmGatewayIfNeeded();

    RouteSearchOutcome? lastOutcome;
    const backoff = [Duration(seconds: 0), Duration(seconds: 3), Duration(seconds: 5)];
    const rateLimitBackoff = [
      Duration(seconds: 8),
      Duration(seconds: 18),
      Duration(seconds: 30),
    ];

    for (var attempt = 0; attempt < backoff.length; attempt++) {
      final wait = lastOutcome?.failure == RouteSearchFailure.rateLimited
          ? rateLimitBackoff[attempt.clamp(0, rateLimitBackoff.length - 1)]
          : backoff[attempt];
      if (wait > Duration.zero) {
        await Future.delayed(wait);
      }

      lastOutcome = await ApiService.searchRoutesOutcomeForModel(model);
      if (lastOutcome.isSuccess) return lastOutcome;

      if (!_isRetryable(lastOutcome)) break;
    }

    return lastOutcome ??
        const RouteSearchOutcome(
          routes: [],
          failure: RouteSearchFailure.connection,
        );
  }

  static bool _isRetryable(RouteSearchOutcome outcome) {
    if (outcome.failure == RouteSearchFailure.rateLimited) return true;
    if (outcome.failure == RouteSearchFailure.timeout ||
        outcome.failure == RouteSearchFailure.connection ||
        outcome.failure == RouteSearchFailure.serverError) {
      return true;
    }
    final msg = outcome.message?.toLowerCase() ?? '';
    return msg.contains('503') ||
        msg.contains('502') ||
        msg.contains('504') ||
        msg.contains('429') ||
        msg.contains('çok fazla') ||
        msg.contains('uyanıyor');
  }
}

extension RouteSearchCacheKey on SearchModel {
  String get routeSearchCacheKey {
    final payload = {
      'originIata': originIata,
      'departureDate': _dateKey(departureDate),
      'returnDate': _dateKey(returnDate),
      'totalBudgetTL': totalBudgetTL.round(),
      'passengers': passengers,
      'children': children,
      'continent': continent,
      'holidayType': holidayType,
      'holidayTypes': holidayTypes,
      'destinationIata': destinationIata,
      'destinationCountry': destinationCountry,
    };
    return jsonEncode(payload);
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
