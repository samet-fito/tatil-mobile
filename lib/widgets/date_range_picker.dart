import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class DateRangePicker extends StatelessWidget {
  final DateTime departureDate;
  final DateTime returnDate;
  final Function(DateTime, DateTime) onChanged;

  const DateRangePicker({
    super.key,
    required this.departureDate,
    required this.returnDate,
    required this.onChanged,
  });

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'tr_TR').format(date);
  }

  int get _nights => returnDate.difference(departureDate).inDays;

  Future<void> _pickDates(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: departureDate,
        end: returnDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.accent,
              onPrimary: Colors.white,
              surface: AppTheme.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickDates(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _DateBox(
                label: 'Kalkış',
                date: _formatDate(departureDate),
                icon: Icons.flight_takeoff,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Icon(Icons.arrow_forward, color: AppTheme.accent, size: 18),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$_nights gece',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _DateBox(
                label: 'Dönüş',
                date: _formatDate(returnDate),
                icon: Icons.flight_land,
                alignRight: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;
  final bool alignRight;

  const _DateBox({
    required this.label,
    required this.date,
    required this.icon,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!alignRight) ...[
              Icon(icon, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (alignRight) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: AppTheme.textMuted),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}