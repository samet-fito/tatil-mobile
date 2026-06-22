import 'package:flutter_test/flutter_test.dart';
import 'package:tatil_arama/models/search_model.dart';

void main() {
  test('gatewayBudgetTL falls back when user budget is empty', () {
    final open = SearchModel(totalBudgetTL: 0);
    expect(open.hasBudget, isFalse);
    expect(open.gatewayBudgetTL, SearchModel.gatewayDefaultBudgetTL);

    final withBudget = SearchModel(totalBudgetTL: 30000);
    expect(withBudget.hasBudget, isTrue);
    expect(withBudget.gatewayBudgetTL, 30000);
  });
}
