import 'package:flutter/foundation.dart';
import 'app_config_model.dart';
import 'colored_pattern_model.dart';
import 'reaction_model.dart';
import 'upload_settings_model.dart';
import 'dynamic_app_config_service.dart';
/// Provider لإدارة إعدادات التطبيق الديناميكية
class DynamicAppConfigProvider extends ChangeNotifier {
  final DynamicAppConfigService _configService;
  AppConfig? _appConfig;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdate;
  DynamicAppConfigProvider(this._configService);
  /// الإعدادات الحالية
  AppConfig? get appConfig => _appConfig;
  /// حالة التحميل
  bool get isLoading => _isLoading;
  /// رسالة الخطأ إن وجدت
  String? get error => _error;
  /// تاريخ آخر تحديث
  DateTime? get lastUpdate => _lastUpdate;
  /// التحقق من وجود الإعدادات
  bool get hasConfig => _appConfig != null;
  /// تحميل الإعدادات
  Future<void> loadConfig({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final config = await _configService.getAppConfig(forceRefresh: forceRefresh);
      _appConfig = config;
      _lastUpdate = await _configService.getLastCacheUpdate();
      if (kDebugMode) {
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  /// تحديث إعدادات معينة
  Future<bool> updateSettings(Map<String, dynamic> updates) async {
    if (_isLoading) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await _configService.updateSettings(updates);
      if (success) {
        // إعادة تحميل الإعدادات بعد التحديث
        await loadConfig(forceRefresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  /// مسح الكاش وإعادة التحميل
  Future<void> clearCacheAndReload() async {
    await _configService.clearCache();
    await loadConfig(forceRefresh: true);
  }
  /// التحقق من صحة الكاش
  Future<bool> isCacheValid() async {
    return await _configService.isCacheValid();
  }
  // Helper methods للوصول السريع للإعدادات
  /// معلومات التطبيق
  AppInfo? get appInfo => _appConfig?.appInfo;
  /// إعدادات الواجهة
  UiSettings? get uiSettings => _appConfig?.uiSettings;
  /// المميزات المتاحة
  Features? get features => _appConfig?.features;
  /// صلاحيات المستخدم
  UserPermissions? get userPermissions => _appConfig?.userPermissions;
  /// الأنماط الملونة
  List<ColoredPattern>? get coloredPatterns => _appConfig?.coloredPatterns;
  /// ردود الأفعال المتاحة
  List<Reaction>? get reactions => _appConfig?.reactions;
  /// المشاعر المتاحة
  List<Map<String, dynamic>>? get feelings => _appConfig?.feelings;
  /// الأنشطة المتاحة  
  List<Map<String, dynamic>>? get activities => _appConfig?.activities;
  /// إعدادات الرفع
  UploadSettings? get uploadSettings => _appConfig?.uploadSettings;
  /// التحقق من تفعيل ميزة معينة
  bool isFeatureEnabled(String featurePath) {
    if (_appConfig?.features == null) return false;
    final parts = featurePath.split('.');
    dynamic current = _appConfig!.features.toJson();
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return false;
      }
    }
    return current == true;
  }
  /// التحقق من صلاحية معينة للمستخدم
  bool hasPermission(String permission) {
    if (_appConfig?.userPermissions == null) return false;
    final permissions = _appConfig!.userPermissions.toJson();
    return permissions[permission] == true;
  }
  /// الحصول على نمط ملون بالمعرف
  ColoredPattern? getColoredPatternById(int id) {
    if (_appConfig?.coloredPatterns == null) return null;
    try {
      return _appConfig!.coloredPatterns.firstWhere(
        (pattern) => pattern.id == id,
      );
    } catch (e) {
      return null;
    }
  }
  /// الحصول على رد فعل بالاسم
  Reaction? getReactionByName(String name) {
    if (_appConfig?.reactions == null) return null;
    try {
      return _appConfig!.reactions.firstWhere(
        (reaction) => reaction.name == name,
      );
    } catch (e) {
      return null;
    }
  }
  /// التحقق من إمكانية رفع نوع ملف معين
  bool canUploadFileType(String extension, String fileType) {
    if (_appConfig?.uploadSettings == null) return false;
    final settings = _appConfig!.uploadSettings;
    switch (fileType.toLowerCase()) {
      case 'image':
      case 'photo':
        return settings.isPhotoExtensionAllowed(extension);
      case 'video':
        return settings.isVideoExtensionAllowed(extension);
      case 'audio':
        return settings.isAudioExtensionAllowed(extension);
      default:
        return false;
    }
  }
  /// الحصول على الحد الأقصى لحجم الملف لنوع معين (بالكيلوبايت)
  int? getMaxFileSizeForType(String type) {
    if (_appConfig?.uploadSettings == null) return null;
    final settings = _appConfig!.uploadSettings;
    switch (type.toLowerCase()) {
      case 'image':
      case 'photo':
        return settings.maxPhotoSize;
      case 'video':
        return settings.maxVideoSize;
      case 'audio':
        return settings.maxAudioSize;
      default:
        return null;
    }
  }
}