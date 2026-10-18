// ignore: file_names
import 'package:shared_preferences/shared_preferences.dart';


class SharedP {
  static Remove() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tok');
    await prefs.remove('user_id');

  }

  static Get(String key) async {
    var prefs = await SharedPreferences.getInstance();

    String? tokens = prefs.getString(key);
    return tokens;
  }

  static Save(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static const String _reelCategoriesKey = 'recent_reel_categories';
  static const int _maxRecentReelCategories = 3;

  /// Most-recently-engaged reel categories, most recent first (capped at 3).
  static Future<List<String>> getRecentReelCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_reelCategoriesKey);
    if (stored == null || stored.trim().isEmpty) return [];
    return stored
        .split(',')
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toList();
  }

  /// Records interest in [category] (e.g. after a reel dwell or a like),
  /// moving it to the front of the recent-categories list and capping the
  /// list at the 3 most recent distinct categories.
  static Future<void> recordReelCategoryInterest(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final current = await getRecentReelCategories();
    current.remove(trimmed);
    current.insert(0, trimmed);
    final capped = current.take(_maxRecentReelCategories).toList();
    await prefs.setString(_reelCategoriesKey, capped.join(','));
  }
}
