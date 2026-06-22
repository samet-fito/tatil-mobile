import 'package:flutter_test/flutter_test.dart';
import 'package:tatil_arama/models/search_model.dart';
import 'package:tatil_arama/services/route_search_service.dart';

void main() {
  tearDown(RouteSearchService.clearCache);

  SearchModel testModel({double budget = 200000}) => SearchModel(
        originIata: 'IST',
        departureDate: DateTime(2026, 7, 9),
        returnDate: DateTime(2026, 7, 14),
        totalBudgetTL: budget,
        passengers: 1,
      );

  test('two sequential searches: second hits cache', () async {
    final model = testModel();

    final first = await RouteSearchService.search(model, forceNetwork: true);
    expect(first.isSuccess, true, reason: first.userMessage);
    expect(first.routes.length, greaterThan(0));

    final second = await RouteSearchService.search(model);
    expect(second.isSuccess, true, reason: second.userMessage);
    expect(second.routes.length, first.routes.length);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('refresh fallback uses cache when network forced but fails gracefully',
      () async {
    final model = testModel();

    final first = await RouteSearchService.search(model, forceNetwork: true);
    expect(first.isSuccess, true);

    final cached = await RouteSearchService.searchWithCacheFallback(model);
    expect(cached.isSuccess, true);
    expect(cached.routes.length, first.routes.length);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
