import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reaction_model.dart';
import 'reactions_api_service.dart';
/// سيرفس Singleton لإدارة التفاعلات مع Cache
/// يجلب التفاعلات مرة واحدة ويحفظها محلياً
class ReactionsService {
  ReactionsService._();
  static final ReactionsService instance = ReactionsService._();
  static const String _cacheKey = 'cached_reactions';
  static const String _cacheTimestampKey = 'reactions_cache_timestamp';
  static const int _cacheValidityHours = 24; // صلاحية الكاش 24 ساعة
  ReactionsApiService? _apiService;
  List<ReactionModel>? _cachedReactions;
  bool _isInitialized = false;
  /// تهيئة السيرفس مع API Service
  void initialize(ReactionsApiService apiService) {
    _apiService = apiService;
  }
  /// تحميل التفاعلات (من الكاش أو من السيرفر)
  Future<List<ReactionModel>> loadReactions({bool forceRefresh = false}) async {
    // إذا كانت موجودة في الذاكرة وليس force refresh
    if (_cachedReactions != null && !forceRefresh) {
      return _cachedReactions!;
    }
    // محاولة تحميل من SharedPreferences
    if (!forceRefresh) {
      final cached = await _loadFromCache();
      if (cached != null && cached.isNotEmpty) {
        _cachedReactions = cached;
        _isInitialized = true;
        return cached;
      }
    }
    // جلب من السيرفر
    if (_apiService != null) {
      try {
        final reactions = await _apiService!.fetchReactions();
        if (reactions.isNotEmpty) {
          await _saveToCache(reactions);
          _cachedReactions = reactions;
          _isInitialized = true;
          return reactions;
        }
      } catch (e) {
      }
    }
    // في حالة الفشل، إرجاع التفاعلات الافتراضية
    return _getDefaultReactions();
  }
  /// الحصول على التفاعلات المحفوظة (بدون انتظار)
  List<ReactionModel> getReactions() {
    return _cachedReactions ?? _getDefaultReactions();
  }
  /// الحصول على تفاعل معين حسب الاسم
  ReactionModel? getReactionByName(String reactionName) {
    final reactions = getReactions();
    try {
      return reactions.firstWhere(
        (r) => r.reaction.toLowerCase() == reactionName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  /// تحميل من الكاش المحلي
  Future<List<ReactionModel>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // فحص صلاحية الكاش
      final timestamp = prefs.getInt(_cacheTimestampKey);
      if (timestamp != null) {
        final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        final difference = now.difference(cacheDate).inHours;
        if (difference > _cacheValidityHours) {
          return null;
        }
      }
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final reactions = jsonList
            .map((json) => ReactionModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return reactions;
      }
    } catch (e) {
    }
    return null;
  }
  /// حفظ في الكاش المحلي
  Future<void> _saveToCache(List<ReactionModel> reactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = reactions.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
    }
  }
  /// مسح الكاش
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      _cachedReactions = null;
    } catch (e) {
    }
  }
  /// تفاعلات افتراضية (في حالة عدم توفر الإنترنت)
  List<ReactionModel> _getDefaultReactions() {
    return [
      ReactionModel(
        reactionId: '1',
        reaction: 'like',
        title: 'Like',
        color: '#1e8bd2',
        image: 'reactions/like.png',
        order: 1,
        enabled: true,
      ),
      ReactionModel(
        reactionId: '2',
        reaction: 'love',
        title: 'Love',
        color: '#f25268',
        image: 'reactions/love.png',
        order: 2,
        enabled: true,
      ),
      ReactionModel(
        reactionId: '3',
        reaction: 'haha',
        title: 'Haha',
        color: '#f3b715',
        image: 'reactions/haha.png',
        order: 3,
        enabled: true,
      ),
      ReactionModel(
        reactionId: '5',
        reaction: 'wow',
        title: 'Wow',
        color: '#f3b715',
        image: 'reactions/wow.png',
        order: 5,
        enabled: true,
      ),
      ReactionModel(
        reactionId: '6',
        reaction: 'sad',
        title: 'Sad',
        color: '#f3b715',
        image: 'reactions/sad.png',
        order: 6,
        enabled: true,
      ),
      ReactionModel(
        reactionId: '7',
        reaction: 'angry',
        title: 'Angry',
        color: '#f7806c',
        image: 'reactions/angry.png',
        order: 7,
        enabled: true,
      ),
    ];
  }
  /// هل السيرفس مهيئ؟
  bool get isInitialized => _isInitialized;
}
