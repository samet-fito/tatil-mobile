import 'package:flutter_test/flutter_test.dart';
import 'package:tatil_arama/services/api_service.dart';

void main() {
  test('ApiService.searchRoutesWithRetry returns routes', () async {
    final outcome = await ApiService.searchRoutesWithRetry(
      originIata: 'IST',
      departureDate: DateTime(2026, 7, 9),
      returnDate: DateTime(2026, 7, 14),
      totalBudgetTL: 200000,
      passengers: 1,
    );
    expect(outcome.isSuccess, true, reason: outcome.userMessage);
    expect(outcome.routes.length, greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
