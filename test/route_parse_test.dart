import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tatil_arama/models/route_result_model.dart';
import 'package:tatil_arama/utils/route_filter_engine.dart';

void main() {
  test('parse 200k gateway packages and filter', () async {
    final client = HttpClient();
    final req = await client.postUrl(
      Uri.parse('https://tatil-backend.onrender.com/api/v1/gateway/search'),
    );
    req.headers.set('Content-Type', 'application/json');
    req.write(jsonEncode({
      'originIata': 'IST',
      'departureDate': '2026-07-15',
      'returnDate': '2026-07-20',
      'totalBudgetTL': 200000,
      'passengers': 1,
    }));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    client.close();

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    expect(decoded['success'], isTrue);

    final inner = decoded['data'];
    final list = inner is List
        ? inner
        : (inner as Map)['packages'] as List? ?? [];

    expect(list.isNotEmpty, isTrue);

    final routes = list
        .map((item) => RouteResultModel.fromJson(item as Map<String, dynamic>))
        .toList();

    expect(routes.length, list.length);

    final filtered = RouteFilterEngine.apply(
      routes: routes,
      budgetTL: 200000,
    );

    expect(filtered.routes.isNotEmpty, isTrue);

    for (final r in routes) {
      expect(r.hotel, isNotNull);
      expect(r.hotel!.reviewScore, greaterThan(7.0));
      expect(r.estimatedCost.hotel, greaterThan(r.estimatedCost.flight));
    }
  });
}
