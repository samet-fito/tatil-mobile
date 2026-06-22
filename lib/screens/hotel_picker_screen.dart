import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/route_result_model.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/hotel_location_hints.dart';
import '../utils/live_offer_matcher.dart';
import '../utils/plan_price_anchor.dart';
import '../utils/price_format.dart';

/// Tam ekran otel listesi — detay/checkout'tan "Değiştir" ile açılır.
class HotelPickerScreen extends StatelessWidget {
  const HotelPickerScreen({
    super.key,
    required this.hotels,
    required this.route,
    required this.selectedIndex,
    required this.recommendedIndex,
    required this.departureDate,
    required this.returnDate,
    this.preferCheapest = false,
  });

  final List<Map<String, dynamic>> hotels;
  final RouteResultModel route;
  final int selectedIndex;
  final int recommendedIndex;
  final DateTime departureDate;
  final DateTime returnDate;
  final bool preferCheapest;

  String _fmt(int price) => PriceFormat.format(price);

  String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final order = LiveOfferMatcher.sortedHotelIndices(
      hotels: hotels,
      nights: route.nights,
      planHotel: route.hotel,
      targetPerNightTL: PlanPriceAnchor.targetHotelPerNightTL(route),
      preferCheapest: preferCheapest,
    );

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Otel Seç',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              '${route.cityName} · ${route.nights} gece\n'
              '${_formatDate(departureDate)} – ${_formatDate(returnDate)}',
              style: TatilTheme.hint.copyWith(height: 1.4),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: order.length,
              itemBuilder: (context, displayPos) {
                final index = order[displayPos];
                final hotel = hotels[index];
                final isSelected = index == selectedIndex;
                final isRecommended = index == recommendedIndex;
                final perNight = PriceFormat.hotelPerNightTL(hotel);
                final total = PriceFormat.hotelTotalTL(hotel, route.nights);
                final locationHint =
                    HotelLocationHints.forHotel(hotel, route.cityName);

                return GestureDetector(
                  onTap: () => Navigator.pop(context, index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.orangeSoft
                          : AppTheme.bgSecondary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppTheme.orange : AppTheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            CupertinoIcons.house_fill,
                            color: AppTheme.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      hotel['name']?.toString() ?? 'Otel',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isRecommended)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      margin: const EdgeInsets.only(left: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.orangeSoft,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: const Text(
                                        'Önerilen',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.orange,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (locationHint != null)
                                Text(
                                  locationHint,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              if (PriceFormat.hotelRatingLine(hotel).isNotEmpty)
                                Text(
                                  PriceFormat.hotelRatingLine(hotel),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_fmt(perNight)}/gece',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? AppTheme.orange : AppTheme.teal,
                              ),
                            ),
                            Text(
                              'Toplam ${_fmt(total)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: AppTheme.orange,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
