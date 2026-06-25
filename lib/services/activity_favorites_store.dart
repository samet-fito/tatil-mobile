import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Aktivite favorileri — kalp ikonu state'i.
class ActivityFavoritesStore {
  ActivityFavoritesStore._();
  static final ActivityFavoritesStore instance = ActivityFavoritesStore._();

  static const _key = 'activity_favorites_v1';
  final Set<String> _ids = {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw != null) _ids.addAll(raw);
    _loaded = true;
  }

  bool isFavorite(String id) => _ids.contains(id);

  Future<bool> toggle(String id) async {
    await ensureLoaded();
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _ids.toList());
    return _ids.contains(id);
  }

  static String activityId(Map<String, dynamic> activity, String city) {
    final title = activity['title'] ?? '';
    final payload = '$city|$title';
    return base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
  }
}
