import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/compare_route_snapshot.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/price_format.dart';

class RouteCompareScreen extends StatelessWidget {
  const RouteCompareScreen({super.key, required this.routes});

  final List<CompareRouteSnapshot> routes;

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Karşılaştır')),
        body: const Center(child: Text('Karşılaştırılacak rota seçilmedi')),
      );
    }

    final cheapest = routes.reduce(
      (a, b) => a.totalPriceTL <= b.totalPriceTL ? a : b,
    );

    return Scaffold(
      backgroundColor: TatilTheme.bgSoft,
      appBar: AppBar(
        title: Text('${routes.length} rota karşılaştır'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.teal.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.chart_bar, color: AppTheme.teal, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'En uygun: ${cheapest.cityName} — ${PriceFormat.format(cheapest.totalPriceTL)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...routes.map((r) {
            final isBest = r.destinationIata == cheapest.destinationIata;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isBest
                      ? AppTheme.teal.withValues(alpha: 0.45)
                      : AppTheme.border,
                  width: isBest ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.cityName,
                          style: TatilTheme.destination(fontSize: 20),
                        ),
                      ),
                      if (isBest)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'En ucuz',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.teal,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    r.country,
                    style: TatilTheme.hint.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    PriceFormat.format(r.totalPriceTL),
                    style: TatilTheme.priceDisplay(fontSize: 26),
                  ),
                  const SizedBox(height: 12),
                  _row('Gece', '${r.nights}'),
                  _row('Uçuş', PriceFormat.format(r.flightPriceTL)),
                  _row('Otel', PriceFormat.format(r.hotelPriceTL)),
                  if (r.hotelName != null) _row('Konaklama', r.hotelName!),
                  if (r.airline != null) _row('Havayolu', r.airline!),
                  _row('Uyum puanı', r.score.toStringAsFixed(1)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TatilTheme.hint.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
