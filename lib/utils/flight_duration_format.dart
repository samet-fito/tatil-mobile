/// ISO 8601 süre (PT1H16M) → okunabilir Türkçe etiket.
class FlightDurationFormat {
  FlightDurationFormat._();

  static String label(dynamic raw) {
    if (raw == null) return '—';
    final value = raw.toString().trim();
    if (value.isEmpty || value == '--') return '—';
    if (!value.startsWith('PT')) return value;

    final hours = RegExp(r'(\d+)H').firstMatch(value)?.group(1);
    final minutes = RegExp(r'(\d+)M').firstMatch(value)?.group(1);
    final h = hours != null ? int.tryParse(hours) ?? 0 : 0;
    final m = minutes != null ? int.tryParse(minutes) ?? 0 : 0;

    if (h > 0 && m > 0) return '${h}s ${m}dk';
    if (h > 0) return '${h}s';
    if (m > 0) return '${m}dk';
    return value;
  }
}
