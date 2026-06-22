import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/flight_duration_format.dart';
import '../utils/flight_schedule_format.dart';
import '../utils/live_offer_matcher.dart';
import '../utils/price_format.dart';

/// Tam ekran uçuş listesi — detay/checkout'tan "Değiştir" ile açılır.
class FlightPickerScreen extends StatelessWidget {
  const FlightPickerScreen({
    super.key,
    required this.flights,
    required this.selectedIndex,
    required this.recommendedIndex,
    required this.originIata,
    required this.destinationCity,
    required this.departureDate,
    required this.returnDate,
  });

  final List<Map<String, dynamic>> flights;
  final int selectedIndex;
  final int recommendedIndex;
  final String originIata;
  final String destinationCity;
  final DateTime departureDate;
  final DateTime returnDate;

  String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final order = LiveOfferMatcher.sortedFlightIndices(flights);

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
          'Uçuş Seç',
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
              '$originIata → $destinationCity · Gidiş-dönüş\n'
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
                final flight = flights[index];
                final isSelected = index == selectedIndex;
                final isRecommended = index == recommendedIndex;
                final priceLabel =
                    PriceFormat.formatRoundTripFlightPrice(flight);
                final stops = flight['stops'];
                final stopLabel = stops == 0
                    ? 'Direkt'
                    : '$stops aktarma';
                final timesLine = FlightScheduleFormat.roundTripTimesLine(
                  flight,
                  departureDate,
                  returnDate,
                );

                return GestureDetector(
                  onTap: () => Navigator.pop(context, index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.teal.withValues(alpha: 0.08)
                          : AppTheme.bgSecondary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppTheme.teal : AppTheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            CupertinoIcons.airplane,
                            color: AppTheme.teal,
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
                                      flight['airline']?.toString() ?? 'Uçuş',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isRecommended)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
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
                              const SizedBox(height: 4),
                              Text(
                                [
                                  if (timesLine.isNotEmpty) timesLine,
                                  stopLabel,
                                  FlightDurationFormat.label(flight['duration']),
                                  'Gidiş-dönüş',
                                ].join(' · '),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (priceLabel != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            priceLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.teal,
                            ),
                          ),
                        ],
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: AppTheme.teal,
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
