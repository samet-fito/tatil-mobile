import 'package:flutter_test/flutter_test.dart';
import 'package:tatil_arama/data/destination_travel_hints.dart';
import 'package:tatil_arama/models/personalized_guide_model.dart';
import 'package:tatil_arama/services/guide_quality.dart';

void main() {
  test('Dubai hints include lifeSavers and strictRules', () {
    final guide = DestinationTravelHints.build(
      iata: 'DXB',
      cityName: 'Dubai',
      country: 'UAE',
      nights: 5,
      travelers: 1,
    );

    expect(GuideQuality.isAcceptable(guide), isTrue);
    expect(
      guide.sections.any((s) => s.kind == GuideSectionKind.lifeSavers),
      isTrue,
    );
    expect(
      guide.sections
          .where((s) => s.kind == GuideSectionKind.lifeSavers)
          .expand((s) => s.items)
          .any((i) => i.contains('gözlük')),
      isTrue,
    );
  });

  test('rejects junk API fallback content', () {
    final bad = PersonalizedGuide(
      headline: 'Test',
      subtitle: '',
      sections: [
        PersonalizedGuideSection(
          emoji: '📌',
          title: 'Genel',
          kind: GuideSectionKind.other,
          items: ['Fiyatlar Türk Lirası (TL) olarak gösterilir.'],
        ),
        PersonalizedGuideSection(
          emoji: '🎯',
          title: 'Mutlaka yapılacaklar',
          kind: GuideSectionKind.mustDo,
          items: ['Tur'],
        ),
      ],
    );

    expect(GuideQuality.isAcceptable(bad), isFalse);
  });
}
