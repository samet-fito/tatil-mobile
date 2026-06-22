import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/calendar_day_quote.dart';
import '../models/date_flexibility.dart';
import '../services/calendar_price_service.dart';
import '../theme/tatil_theme.dart';
import '../utils/price_format.dart';

class FlexibleTravelDatePickerResult {
  const FlexibleTravelDatePickerResult({
    required this.departureDate,
    required this.returnDate,
    required this.flexibility,
  });

  final DateTime departureDate;
  final DateTime returnDate;
  final DateFlexibility flexibility;
}

/// Kiwi tarzı uçuş + otel fiyatlı esnek tarih seçici.
Future<FlexibleTravelDatePickerResult?> showFlexibleTravelDatePicker(
  BuildContext context, {
  required DateTime initialDeparture,
  required DateTime initialReturn,
  required String originIata,
  required String? destinationIata,
  required String? destinationCity,
  required int passengers,
  DateFlexibility initialFlexibility = DateFlexibility.exact,
  String? referenceCityLabel,
}) {
  return showModalBottomSheet<FlexibleTravelDatePickerResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _FlexibleTravelDatePickerSheet(
      initialDeparture: initialDeparture,
      initialReturn: initialReturn,
      originIata: originIata,
      destinationIata: destinationIata,
      destinationCity: destinationCity,
      passengers: passengers,
      initialFlexibility: initialFlexibility,
      referenceCityLabel: referenceCityLabel,
    ),
  );
}

class _FlexibleTravelDatePickerSheet extends StatefulWidget {
  final String? referenceCityLabel;

  const _FlexibleTravelDatePickerSheet({
    required this.initialDeparture,
    required this.initialReturn,
    required this.originIata,
    required this.destinationIata,
    required this.destinationCity,
    required this.passengers,
    required this.initialFlexibility,
    this.referenceCityLabel,
  });

  final DateTime initialDeparture;
  final DateTime initialReturn;
  final String originIata;
  final String? destinationIata;
  final String? destinationCity;
  final int passengers;
  final DateFlexibility initialFlexibility;

  @override
  State<_FlexibleTravelDatePickerSheet> createState() =>
      _FlexibleTravelDatePickerSheetState();
}

class _FlexibleTravelDatePickerSheetState
    extends State<_FlexibleTravelDatePickerSheet> {
  static const _weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  static const _cellHeight = 66.0;
  static const _months = [
    '',
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  late DateTime _departure;
  DateTime? _return;
  late DateFlexibility _flexibility;
  late DateTime _visibleMonth;
  bool _pickingReturn = false;
  bool _loadingPrices = false;
  Map<DateTime, CalendarDayQuote> _quotes = {};
  late final TextEditingController _departureCtrl;
  late final TextEditingController _returnCtrl;
  late final FocusNode _departureFocus;
  late final FocusNode _returnFocus;

  int get _nights {
    if (_return == null) {
      return widget.initialReturn.difference(widget.initialDeparture).inDays;
    }
    return _return!.difference(_departure).inDays.clamp(1, 30);
  }

  bool get _canLoadPrices =>
      widget.destinationIata != null &&
      widget.destinationCity != null &&
      widget.destinationCity!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _departure = DateTime(
      widget.initialDeparture.year,
      widget.initialDeparture.month,
      widget.initialDeparture.day,
    );
    _return = DateTime(
      widget.initialReturn.year,
      widget.initialReturn.month,
      widget.initialReturn.day,
    );
    _flexibility = widget.initialFlexibility;
    _visibleMonth = DateTime(_departure.year, _departure.month);
    _departureCtrl = TextEditingController(text: _formatManual(_departure));
    _returnCtrl = TextEditingController(
      text: _return != null ? _formatManual(_return!) : '',
    );
    _departureFocus = FocusNode();
    _returnFocus = FocusNode();
    _departureFocus.addListener(() {
      if (_departureFocus.hasFocus) {
        setState(() => _pickingReturn = false);
      }
    });
    _returnFocus.addListener(() {
      if (_returnFocus.hasFocus) {
        setState(() => _pickingReturn = true);
      }
    });
    _loadMonthPrices();
  }

  String _formatManual(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.'
      '${d.year}';

  void _syncControllers() {
    _departureCtrl.text = _formatManual(_departure);
    if (_return != null) {
      _returnCtrl.text = _formatManual(_return!);
    }
  }

  DateTime get _todayOnly {
    final t = DateTime.now();
    return DateTime(t.year, t.month, t.day);
  }

  DateTime? _parseManualDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final match = RegExp(r'^(\d{1,2})[./](\d{1,2})[./](\d{2,4})$').firstMatch(text);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    var year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  void _showDateSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _applyManualDeparture({bool silent = false}) {
    final parsed = _parseManualDate(_departureCtrl.text);
    if (parsed == null) {
      if (!silent) _showDateSnack('Gidiş: GG.AA.YYYY formatında girin');
      _syncControllers();
      return false;
    }
    if (parsed.isBefore(_todayOnly)) {
      if (!silent) _showDateSnack('Gidiş tarihi bugünden önce olamaz');
      _syncControllers();
      return false;
    }

    setState(() {
      _departure = parsed;
      _visibleMonth = DateTime(parsed.year, parsed.month);
      if (_return == null || !_return!.isAfter(_departure)) {
        _return = _departure.add(Duration(days: _nights.clamp(1, 30)));
      }
      _pickingReturn = true;
      _syncControllers();
    });
    _loadMonthPrices();
    return true;
  }

  bool _applyManualReturn({bool silent = false}) {
    final parsed = _parseManualDate(_returnCtrl.text);
    if (parsed == null) {
      if (!silent) _showDateSnack('Dönüş: GG.AA.YYYY formatında girin');
      _syncControllers();
      return false;
    }
    if (!parsed.isAfter(_departure)) {
      if (!silent) _showDateSnack('Dönüş, gidişten sonra olmalı');
      _syncControllers();
      return false;
    }
    final nights = parsed.difference(_departure).inDays;
    if (nights > 30) {
      if (!silent) _showDateSnack('Konaklama en fazla 30 gece olabilir');
      _syncControllers();
      return false;
    }

    setState(() {
      _return = parsed;
      _pickingReturn = false;
      _syncControllers();
    });
    _loadMonthPrices();
    return true;
  }

  @override
  void dispose() {
    CalendarPriceService.cancelPendingLoads();
    _departureCtrl.dispose();
    _returnCtrl.dispose();
    _departureFocus.dispose();
    _returnFocus.dispose();
    super.dispose();
  }

  Future<void> _loadMonthPrices() async {
    if (!_canLoadPrices) return;
    setState(() => _loadingPrices = true);
    final month = DateTime(_visibleMonth.year, _visibleMonth.month);
    final quotes = await CalendarPriceService.loadMonth(
      originIata: widget.originIata,
      destinationIata: widget.destinationIata!,
      destinationCity: widget.destinationCity!,
      nights: _nights,
      passengers: widget.passengers,
      month: month,
      focusDate: _departure,
      onDayUpdated: (day, quote) {
        if (!mounted) return;
        setState(() {
          _quotes[DateTime(day.year, day.month, day.day)] = quote;
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _quotes.addAll(quotes.map(
        (k, v) => MapEntry(DateTime(k.year, k.month, k.day), v),
      ));
      _loadingPrices = false;
    });
  }

  void _onMonthChanged(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
    _loadMonthPrices();
  }

  void _onDayTap(DateTime day) {
    if (day.isBefore(_todayOnly)) return;
    FocusScope.of(context).unfocus();

    if (_pickingReturn) {
      if (!day.isAfter(_departure)) {
        setState(() {
          _departure = day;
          _visibleMonth = DateTime(day.year, day.month);
          if (_flexibility == DateFlexibility.dateRange) {
            _return = null;
            _returnCtrl.clear();
            _pickingReturn = true;
          } else {
            _return = day.add(Duration(days: _nights.clamp(1, 30)));
            _pickingReturn = true;
          }
          _syncControllers();
        });
        _loadMonthPrices();
        return;
      }

      final nights = day.difference(_departure).inDays;
      if (nights > 30) {
        _showDateSnack('Konaklama en fazla 30 gece olabilir');
        return;
      }

      setState(() {
        _return = day;
        _pickingReturn = false;
        _syncControllers();
      });
      _loadMonthPrices();
      return;
    }

    setState(() {
      _departure = day;
      _visibleMonth = DateTime(day.year, day.month);
      if (_flexibility == DateFlexibility.dateRange) {
        _return = null;
        _returnCtrl.clear();
        _pickingReturn = true;
      } else {
        _return = day.add(Duration(days: _nights.clamp(1, 30)));
        _pickingReturn = true;
      }
      _syncControllers();
    });
    _loadMonthPrices();
  }

  void _confirm() {
    FocusScope.of(context).unfocus();
    if (!_applyManualDeparture(silent: true)) return;
    if (!_applyManualReturn(silent: true)) return;

    final ret = _return ?? _departure.add(Duration(days: _nights));
    Navigator.pop(
      context,
      FlexibleTravelDatePickerResult(
        departureDate: _departure,
        returnDate: ret,
        flexibility: _flexibility,
      ),
    );
  }

  int? _cheapestInMonth() {
    var min = 0;
    for (final entry in _quotes.entries) {
      final price = CalendarPriceService.displayPriceForDay(
        day: entry.key,
        quotes: _quotes,
        flexDays: _flexibility.flexDays,
      );
      if (price <= 0) continue;
      if (min == 0 || price < min) min = price;
    }
    return min == 0 ? null : min;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final monthCheapest = _cheapestInMonth();

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TatilTheme.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Tarih seç',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _confirm, child: const Text('Tamam')),
                ],
              ),
            ),
            if (widget.referenceCityLabel != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Fiyatlar: ${widget.referenceCityLabel}',
                    style: TatilTheme.hint.copyWith(fontSize: 11),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _manualDateField(
                      label: 'Gidiş',
                      controller: _departureCtrl,
                      focusNode: _departureFocus,
                      selected: !_pickingReturn,
                      hint: 'GG.AA.YYYY',
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _pickingReturn = false);
                      },
                      onSubmitted: (_) => _applyManualDeparture(),
                      onEditingComplete: _applyManualDeparture,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _manualDateField(
                      label: 'Dönüş',
                      controller: _returnCtrl,
                      focusNode: _returnFocus,
                      selected: _pickingReturn,
                      hint: 'GG.AA.YYYY',
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _pickingReturn = true);
                      },
                      onSubmitted: (_) => _applyManualReturn(),
                      onEditingComplete: _applyManualReturn,
                      showClear: _return != null,
                      onClear: () {
                        setState(() {
                          _return = _departure.add(Duration(days: _nights));
                          _pickingReturn = false;
                          _syncControllers();
                        });
                        _loadMonthPrices();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _pickingReturn
                      ? 'Aktif alan: Dönüş — takvim seçimi buraya uygulanır'
                      : 'Aktif alan: Gidiş — ilk seçim gidiş, ikinci seçim dönüş',
                  style: TatilTheme.hint.copyWith(fontSize: 11),
                ),
              ),
            ),
            if (_canLoadPrices)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Row(
                  children: [
                    Icon(Icons.flight, size: 12, color: const Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text('Uçuş', style: TatilTheme.hint.copyWith(fontSize: 10)),
                    const SizedBox(width: 14),
                    Icon(Icons.hotel_rounded, size: 12, color: TatilTheme.orange),
                    const SizedBox(width: 4),
                    Text('Otel', style: TatilTheme.hint.copyWith(fontSize: 10)),
                    const Spacer(),
                    Text(
                      'Yeşil: en ucuz · en fazla 12 gün',
                      style: TatilTheme.hint.copyWith(
                        fontSize: 10,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            if (!_canLoadPrices)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text(
                  'Fiyatları görmek için önce bir destinasyon seçin.',
                  style: TatilTheme.hint.copyWith(fontSize: 12),
                ),
              ),
            if (_canLoadPrices && _loadingPrices)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  color: TatilTheme.orange,
                  minHeight: 2,
                ),
              ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                children: [
                  _monthHeader(),
                  _calendarGrid(monthCheapest),
                ],
              ),
            ),
            _flexChips(),
            SizedBox(height: bottom + 12),
          ],
        ),
      ),
    );
  }

  Widget _monthHeader({int offset = 0}) {
    final m = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      child: Row(
        children: [
          if (offset == 0)
            IconButton(
              onPressed: () => _onMonthChanged(-1),
              icon: const Icon(Icons.chevron_left),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              '${_months[m.month]} ${m.year}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          if (offset == 0)
            IconButton(
              onPressed: () => _onMonthChanged(1),
              icon: const Icon(Icons.chevron_right),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _calendarGrid(int? monthCheapest, {int monthOffset = 0}) {
    final month = DateTime(_visibleMonth.year, _visibleMonth.month + monthOffset);
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final today = DateTime.now();
    final startPad = first.weekday - 1;

    return Column(
      children: [
        Row(
          children: _weekdays
              .map(
                (w) => Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: TatilTheme.hint.copyWith(fontSize: 11),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        ...List.generate(((last.day + startPad) / 7).ceil(), (week) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (col) {
                final dayNum = week * 7 + col - startPad + 1;
                if (dayNum < 1 || dayNum > last.day) {
                  return Expanded(child: SizedBox(height: _cellHeight));
                }
                final day = DateTime(month.year, month.month, dayNum);
                final isPast = day.isBefore(
                  DateTime(today.year, today.month, today.day),
                );
                return Expanded(child: _dayCell(day, isPast, monthCheapest));
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _priceLine({
    required IconData icon,
    required int amount,
    required bool highlight,
    required Color iconColor,
  }) {
    if (amount <= 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: iconColor.withValues(alpha: 0.45)),
          const SizedBox(width: 2),
          Text(
            '—',
            style: GoogleFonts.inter(
              fontSize: 8,
              color: TatilTheme.textMuted.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: iconColor),
        const SizedBox(width: 2),
        Text(
          PriceFormat.formatCompact(amount),
          style: GoogleFonts.inter(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: highlight
                ? const Color(0xFF16A34A)
                : TatilTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _dayCell(DateTime day, bool isPast, int? monthCheapest) {
    final key = DateTime(day.year, day.month, day.day);
    final quote = _quotes[key];
    final isDeparture = _sameDay(day, _departure);
    final isReturn = _return != null && _sameDay(day, _return!);
    final inRange = _return != null &&
        day.isAfter(_departure.subtract(const Duration(days: 1))) &&
        day.isBefore(_return!.add(const Duration(days: 1)));

    final flightTL = _canLoadPrices
        ? CalendarPriceService.displayFlightPriceForDay(
            day: key,
            quotes: _quotes,
            flexDays: _flexibility.flexDays,
          )
        : 0;
    final hotelTL = _canLoadPrices
        ? CalendarPriceService.displayHotelPriceForDay(
            day: key,
            quotes: _quotes,
            flexDays: _flexibility.flexDays,
          )
        : 0;
    final packageTL = flightTL + hotelTL;

    final isCheap = monthCheapest != null &&
        packageTL > 0 &&
        packageTL <= monthCheapest * 1.05;

    return GestureDetector(
      onTap: isPast ? null : () => _onDayTap(day),
      child: Container(
        height: _cellHeight,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: inRange && !isDeparture && !isReturn
              ? TatilTheme.orangeSoft.withValues(alpha: 0.35)
              : null,
          borderRadius: BorderRadius.circular(10),
          border: isDeparture || isReturn
              ? Border.all(color: const Color(0xFF2563EB), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isPast
                    ? TatilTheme.textMuted.withValues(alpha: 0.4)
                    : TatilTheme.textDark,
              ),
            ),
            if (_canLoadPrices && !isPast) ...[
              const SizedBox(height: 2),
              if (quote?.loading == true)
                SizedBox(
                  width: 20,
                  height: 10,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: TatilTheme.orange.withValues(alpha: 0.5),
                  ),
                )
              else ...[
                _priceLine(
                  icon: Icons.flight,
                  amount: flightTL,
                  highlight: isCheap,
                  iconColor: const Color(0xFF2563EB),
                ),
                const SizedBox(height: 1),
                _priceLine(
                  icon: Icons.hotel_rounded,
                  amount: hotelTL,
                  highlight: isCheap,
                  iconColor: TatilTheme.orange,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _manualDateField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool selected,
    required String hint,
    required VoidCallback onTap,
    required ValueChanged<String> onSubmitted,
    required VoidCallback onEditingComplete,
    bool showClear = false,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : TatilTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: TatilTheme.hint.copyWith(fontSize: 11)),
                ),
                if (showClear && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.close, size: 18, color: Color(0xFF2563EB)),
                    ),
                  ),
              ],
            ),
            TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.datetime,
              textInputAction: TextInputAction.done,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.only(top: 2),
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: TatilTheme.textMuted.withValues(alpha: 0.65),
                ),
              ),
              onTap: onTap,
              onSubmitted: onSubmitted,
              onEditingComplete: onEditingComplete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _flexChips() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: DateFlexibility.values.map((f) {
            final selected = _flexibility == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f.labelTr),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _flexibility = f;
                    if (f == DateFlexibility.dateRange) {
                      _pickingReturn = _return == null;
                    } else {
                      _pickingReturn = false;
                      _return ??= _departure.add(Duration(days: _nights));
                    }
                    _syncControllers();
                  });
                },
                selectedColor: const Color(0xFF2563EB),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : TatilTheme.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: selected ? const Color(0xFF2563EB) : TatilTheme.border,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
