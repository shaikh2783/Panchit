import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which posts have been viewed by which user, persisted across sessions.
/// Prevents the same account from incrementing a post's view count more than once.
class PostViewTrackingService {
  static const _keyPrefix = 'pv_';

  final SharedPreferences _prefs;
  final Set<String> _sessionCache = {};

  PostViewTrackingService(this._prefs);

  String _key(String userId, int postId) => '$_keyPrefix${userId}_$postId';

  bool hasViewed(String userId, int postId) {
    final k = _key(userId, postId);
    return _sessionCache.contains(k) || (_prefs.getBool(k) ?? false);
  }

  /// Returns true the very first time this user views this post, then false.
  /// Persists immediately so it survives app restarts.
  bool shouldCountView(String userId, int postId) {
    if (hasViewed(userId, postId)) return false;
    final k = _key(userId, postId);
    _sessionCache.add(k);
    _prefs.setBool(k, true);
    return true;
  }
}