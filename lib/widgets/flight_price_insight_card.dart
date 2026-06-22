import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/calendar_day_quote.dart';
import '../services/calendar_price_service.dart';
import '../theme/tatil_theme.dart';
import '../utils/price_format.dart';

/// Uçuş aramasında gidiş tarihi çevresinde fiyat grafiği (Turna tarzı).
class FlightPriceInsightCard extends StatefulWidget {
  const FlightPriceInsightCard({
    super.key,
    required this.originIata,
    required this.destinationIata,
    required this.destinationCity,
    required this.passengers,
    required this.isRoundTrip,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final String originIata;
  final String destinationIata;
  final String destinationCity;
  final int passengers;
  final bool isRoundTrip;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<FlightPriceInsightCard> createState() => _FlightPriceInsightCardState();
}

class _FlightPriceInsightCardState extends State<FlightPriceInsightCard> {
  Map<DateTime, CalendarDayQuote> _quotes = {};
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FlightPriceInsightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destinationIata != widget.destinationIata ||
        oldWidget.originIata != widget.originIata ||
        oldWidget.passengers != widget.passengers ||
        oldWidget.isRoundTrip != widget.isRoundTrip) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final month = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    final nights = widget.isRoundTrip ? 5 : 1;
    final quotes = await CalendarPriceService.loadMonth(
      originIata: widget.originIata,
      destinationIata: widget.destinationIata,
      destinationCity: widget.destinationCity,
      nights: nights,
      passengers: widget.passengers,
      month: month,
      focusDate: widget.selectedDate,
      onDayUpdated: (day, quote) {
        if (!mounted) return;
        setState(() => _quotes = {..._quotes, day: quote});
      },
    );
    if (!mounted) return;
    setState(() {
      _quotes = quotes;
      _loading = false;
      if (quotes.values.any((q) => !q.loading && q.flightTL > 0)) {
        _expanded = true;
      }
    });
  }

  List<CalendarDayQuote> get _sortedQuotes {
    final list = _quotes.values
        .where((q) => !q.loading && q.flightTL > 0)
        .toList()
      ..sort((a, b) => a.departureDate.compareTo(b.departureDate));
    return list.take(14).toList();
  }

  int? get _cheapestTL {
    final prices = _sortedQuotes.map((q) => q.flightTL).where((p) => p > 0);
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final quotes = _sortedQuotes;
    final cheapest = _cheapestTL;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TatilTheme.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.chart_bar_alt_fill,
                      color: TatilTheme.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fiyat grafiği',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          cheapest != null
                              ? 'Bu ay en düşük uçuş: ${PriceFormat.format(cheapest)}'
                              : 'Tarih seçerek en uygun günü bulun',
                          style: TatilTheme.hint.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CupertinoActivityIndicator(radius: 9),
                    )
                  else
                    Icon(
                      _expanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 16,
                      color: TatilTheme.textMuted,
                    ),
                ],
              ),
            ),
          ),
          if (_expanded && !_loading && quotes.isEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Bu rota için fiyat verisi henüz yüklenemedi. '
                'Aşağıdaki çubuklara dokunarak veya tarihi değiştirerek tekrar deneyin.',
                style: TatilTheme.hint.copyWith(fontSize: 11, height: 1.4),
              ),
            ),
          ],
          if (_expanded && quotes.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: SizedBox(
                height: 120,
                child: _PriceBarChart(
                  quotes: quotes,
                  cheapestTL: cheapest,
                  selectedDate: widget.selectedDate,
                  onTapDay: widget.onDateSelected,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
              child: Text(
                'Çubuğa dokunarak gidiş tarihini değiştirin. '
                'Fiyatlar bilgilendirme amaçlıdır.',
                style: TatilTheme.hint.copyWith(fontSize: 10, height: 1.35),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceBarChart extends StatelessWidget {
  const _PriceBarChart({
    required this.quotes,
    required this.cheapestTL,
    required this.selectedDate,
    required this.onTapDay,
  });

  final List<CalendarDayQuote> quotes;
  final int? cheapestTL;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onTapDay;

  @override
  Widget build(BuildContext context) {
    final maxPrice = quotes.map((q) => q.flightTL).reduce((a, b) => a > b ? a : b);
    final minPrice = quotes.map((q) => q.flightTL).reduce((a, b) => a < b ? a : b);
    final range = (maxPrice - minPrice).clamp(1, 999999);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: quotes.map((q) {
        final day = q.departureDate;
        final selected = day.year == selectedDate.year &&
            day.month == selectedDate.month &&
            day.day == selectedDate.day;
        final isCheapest = cheapestTL != null && q.flightTL == cheapestTL;
        final normalized = (q.flightTL - minPrice) / range;
        final barH = 24.0 + normalized * 72;

        return Expanded(
          child: GestureDetector(
            onTap: () => onTapDay(day),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isCheapest)
                    Text(
                      '★',
                      style: TextStyle(
                        fontSize: 9,
                        color: TatilTheme.orange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: barH,
                    decoration: BoxDecoration(
                      color: selected
                          ? TatilTheme.orange
                          : isCheapest
                              ? TatilTheme.orange.withValues(alpha: 0.55)
                              : TatilTheme.orange.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: selected
                          ? Border.all(color: TatilTheme.orange, width: 2)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected ? TatilTheme.orange : TatilTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
