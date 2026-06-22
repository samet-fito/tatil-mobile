/// Doğum tarihinden yaş hesaplama (checkout formu: GG.AA.YYYY).
class PassengerAge {
  static int? fromBirthDateString(String raw, {DateTime? reference}) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final ref = reference ?? DateTime.now();
    DateTime? birth;

    final dot = RegExp(r'^(\d{1,2})[./](\d{1,2})[./](\d{4})$');
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');

    final dotMatch = dot.firstMatch(s);
    if (dotMatch != null) {
      birth = DateTime.tryParse(
        '${dotMatch.group(3)}-${dotMatch.group(2)!.padLeft(2, '0')}-${dotMatch.group(1)!.padLeft(2, '0')}',
      );
    } else {
      final isoMatch = iso.firstMatch(s);
      if (isoMatch != null) {
        birth = DateTime.tryParse(s);
      }
    }

    if (birth == null) return null;
    var age = ref.year - birth.year;
    if (ref.month < birth.month ||
        (ref.month == birth.month && ref.day < birth.day)) {
      age--;
    }
    if (age < 0 || age > 120) return null;
    return age;
  }

  static String ageGroupLabel(int age) {
    if (age < 3) return 'bebek';
    if (age < 13) return 'çocuk';
    if (age < 18) return 'genç';
    if (age < 30) return 'genç yetişkin';
    if (age < 50) return 'yetişkin';
    if (age < 65) return 'orta yaş';
    return '65+';
  }

  static String summarize(List<int> ages) {
    if (ages.isEmpty) return 'Yetişkin gezgin';
    if (ages.length == 1) {
      return '${ages.first} yaş · ${ageGroupLabel(ages.first)}';
    }
    return ages.map((a) => '$a yaş').join(', ');
  }
}
