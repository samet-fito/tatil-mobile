import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HolidayTypeSelector extends StatelessWidget {
  final String? selected;
  final Function(String?) onChanged;

  const HolidayTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const List<Map<String, dynamic>> types = [
    {'value': 'beach', 'label': 'Deniz & Güneş', 'emoji': '🏖️', 'color': 0xFF0EA5E9},
    {'value': 'culture', 'label': 'Kültür & Tarih', 'emoji': '🏛️', 'color': 0xFFD85A30},
    {'value': 'nature', 'label': 'Doğa & Macera', 'emoji': '🌲', 'color': 0xFF16A34A},
    {'value': 'health', 'label': 'Sağlık & Güzellik', 'emoji': '🏥', 'color': 0xFF7C3AED},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: types.map((type) {
        final isSelected = selected == type['value'];
        final color = Color(type['color'] as int);
        final isHealth = type['value'] == 'health';

        return GestureDetector(
          onTap: () => onChanged(
            selected == type['value'] ? null : type['value'],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.15)
                  : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Sağlık seçilince arka plan animasyonu
                if (isHealth && isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.health.withOpacity(0.1),
                            AppTheme.health.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Text(
                        type['emoji'] as String,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? color : AppTheme.textPrimary,
                              ),
                            ),
                            if (isHealth && isSelected)
                              Text(
                                'Yüksek bütçe modu',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.health.withOpacity(0.8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: color, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}