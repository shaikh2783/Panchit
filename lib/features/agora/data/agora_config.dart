
import 'package:snginepro/App_Settings.dart';

/// إعدادات Agora للبث المباشر
/// جميع الإعدادات الآن في app_config.dart
class AgoraConfig {
  // استخدام إعدادات من AppSettings
  static String get appId => AppSettings.agoraAppId;
  static String? get token => AppSettings.agoraToken;
  
  // إعدادات جودة الفيديو
  static int get videoWidth => AppSettings.agoraVideoWidth;
  static int get videoHeight => AppSettings.agoraVideoHeight;
  static int get frameRate => AppSettings.agoraFrameRate;
  static int get bitrate => AppSettings.agoraBitrate;
  
  // إعدادات الصوت
  static int get audioSampleRate => AppSettings.agoraAudioSampleRate;
  static int get audioChannels => AppSettings.agoraAudioChannels;
  
  // مدة انتظار الاتصال
  static int get connectionTimeoutSeconds => AppSettings.agoraConnectionTimeoutSeconds;
  
  // أقصى عدد مستخدمين في البث
  static int get maxUsers => AppSettings.agoraMaxUsers;
  
  /// التحقق من صحة إعدادات Agora
  static bool get isConfigured => AppSettings.isAgoraConfigured;
  
  /// رسالة خطأ للإعدادات غير المكتملة
  static String get configurationError => 
      'يرجى تكوين Agora App ID في app_config.dart قبل استخدام البث المباشر';
}