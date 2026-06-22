import 'package:flutter/material.dart';
import '../models/search_category.dart';
import '../theme/tatil_theme.dart';

/// Kategori seçimine göre kısa yol haritası — kullanıcı ne yapacağını anlasın.
class CategorySearchGuide extends StatelessWidget {
  const CategorySearchGuide({super.key, required this.category});

  final SearchCategory category;

  @override
  Widget build(BuildContext context) {
    final steps = category.searchGuideSteps;
    if (steps.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TatilTheme.orangeSoft.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TatilTheme.orange.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nasıl çalışır?',
            style: TatilTheme.sectionLabel.copyWith(
              fontSize: 12,
              color: TatilTheme.orange,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(steps.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TatilTheme.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: TatilTheme.hint.copyWith(
                        fontSize: 12,
                        height: 1.35,
                        color: TatilTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
