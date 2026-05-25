import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ContinentSelector extends StatelessWidget {
  final String? selected;
  final Function(String?) onChanged;

  const ContinentSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const List<Map<String, String>> continents = [
    {'value': 'all', 'label': 'Tümü', 'emoji': '🌍'},
    {'value': 'domestic', 'label': 'Yurtiçi', 'emoji': '🇹🇷'},
    {'value': 'europe', 'label': 'Avrupa', 'emoji': '🏰'},
    {'value': 'asia', 'label': 'Asya', 'emoji': '🏯'},
    {'value': 'middleeast', 'label': 'Orta Doğu', 'emoji': '🕌'},
    {'value': 'africa', 'label': 'Afrika', 'emoji': '🦁'},
    {'value': 'america', 'label': 'Amerika', 'emoji': '🗽'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: continents.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = continents[index];
          final isSelected = selected == item['value'] ||
              (selected == null && item['value'] == 'all');

          return GestureDetector(
            onTap: () => onChanged(
              item['value'] == 'all' ? null : item['value'],
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accent : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accent
                      : AppTheme.textMuted.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Text(item['emoji']!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    item['label']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}