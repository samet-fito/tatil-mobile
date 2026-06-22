import '../models/personalized_guide_model.dart';

/// Rehber içeriğinin kullanıcıya gösterilmeye değer olup olmadığını denetler.
class GuideQuality {
  GuideQuality._();

  static final _junkPattern = RegExp(
    r'API kaynak|maliyet endeksi|Fiyatlar Türk Lirası|'
    r'Uçuş ve otel fiyatları|minimum otel puanı|'
    r'Destinasyon Özeti|güncel fiyatlar API',
    caseSensitive: false,
  );

  static bool isAcceptable(PersonalizedGuide guide) {
    if (guide.sections.isEmpty) return false;

    final kinds = guide.sections.map((s) => s.kind).toSet();
    final hasCritical = kinds.contains(GuideSectionKind.strictRules) ||
        kinds.contains(GuideSectionKind.lifeSavers);
    if (!hasCritical) return false;

    if (guide.sections.length < 3) return false;

    for (final section in guide.sections) {
      if (section.items.isEmpty) return false;
      if (section.title.toLowerCase() == 'genel') return false;
      for (final item in section.items) {
        if (_junkPattern.hasMatch(item)) return false;
      }
    }

    return !_hasDuplicateActivitySpam(guide);
  }

  /// Aktivite listesinin ipuçları bölümünde tekrar etmesi (eski fallback hatası).
  static bool _hasDuplicateActivitySpam(PersonalizedGuide guide) {
    final mustDo = guide.sections
        .where((s) => s.kind == GuideSectionKind.mustDo)
        .expand((s) => s.items)
        .toSet();
    if (mustDo.isEmpty) return false;

    final tips = guide.sections
        .where((s) => s.kind == GuideSectionKind.localTips)
        .expand((s) => s.items)
        .toList();
    if (tips.isEmpty) return false;

    var overlap = 0;
    for (final tip in tips) {
      for (final activity in mustDo) {
        if (_similar(tip, activity)) overlap++;
      }
    }
    return overlap >= 2;
  }

  static bool _similar(String a, String b) {
    final na = a.toLowerCase().replaceAll(RegExp(r'[^a-z0-9ğüşıöç ]'), '');
    final nb = b.toLowerCase().replaceAll(RegExp(r'[^a-z0-9ğüşıöç ]'), '');
    if (na.isEmpty || nb.isEmpty) return false;
    return na.contains(nb.substring(0, nb.length.clamp(0, 12))) ||
        nb.contains(na.substring(0, na.length.clamp(0, 12)));
  }
}
