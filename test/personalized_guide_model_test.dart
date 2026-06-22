import 'package:flutter_test/flutter_test.dart';
import 'package:tatil_arama/models/personalized_guide_model.dart';

void main() {
  test('parses guide sections with kind defaults', () {
    final guide = PersonalizedGuide.fromJson({
      'headline': 'Dubai Rehberi',
      'subtitle': '5 gece',
      'sections': [
        {
          'kind': 'lifeSavers',
          'items': [
            'Çöl safarisine gözlük ve ağız-burun bandı götürün.',
          ],
        },
        {
          'kind': 'strictRules',
          'title': 'Yerel kurallar',
          'emoji': '⚠️',
          'items': ['Yapma: Kamusal alanda alkol tüketmeyin.'],
        },
      ],
      'weather': {
        'summaryLine': '38–42°C ortalama',
        'clothingHint': 'Hafif pamuklu kıyafet.',
        'avgHighC': 40,
        'avgLowC': 28,
        'days': [],
      },
    });

    expect(guide.headline, 'Dubai Rehberi');
    expect(guide.weather?.summaryLine, contains('38'));
    expect(guide.sections.length, 2);
    final lifeSavers = guide.sections
        .firstWhere((s) => s.kind == GuideSectionKind.lifeSavers);
    expect(lifeSavers.title, 'Hayat kurtaran tavsiyeler');
    expect(lifeSavers.emoji, '🆘');
  });

  test('section sort order follows kind priority', () {
    final guide = PersonalizedGuide.fromJson({
      'headline': 'Test',
      'sections': [
        {'kind': 'localTips', 'items': ['a']},
        {'kind': 'mustDo', 'items': ['b']},
        {'kind': 'strictRules', 'items': ['c']},
      ],
    });

    expect(guide.sections.map((s) => s.kind).toList(), [
      GuideSectionKind.mustDo,
      GuideSectionKind.strictRules,
      GuideSectionKind.localTips,
    ]);
  });
}
