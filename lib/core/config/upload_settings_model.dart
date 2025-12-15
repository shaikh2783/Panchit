/// إعدادات رفع الملفات
class UploadSettings {
  final int maxPhotoSize; // in KB
  final int maxVideoSize; // in KB  
  final int maxAudioSize; // in KB
  final List<String> allowedPhotoExtensions;
  final List<String> allowedVideoExtensions;
  final List<String> allowedAudioExtensions;
  const UploadSettings({
    required this.maxPhotoSize,
    required this.maxVideoSize,
    required this.maxAudioSize,
    required this.allowedPhotoExtensions,
    required this.allowedVideoExtensions,
    required this.allowedAudioExtensions,
  });
  factory UploadSettings.fromJson(Map<String, dynamic> json) {
    return UploadSettings(
      maxPhotoSize: int.tryParse(json['max_photo_size']?.toString() ?? '') ?? 10240,
      maxVideoSize: int.tryParse(json['max_video_size']?.toString() ?? '') ?? 102400,
      maxAudioSize: int.tryParse(json['max_audio_size']?.toString() ?? '') ?? 10240,
      allowedPhotoExtensions: _parseExtensions(json['allowed_photo_extensions']),
      allowedVideoExtensions: _parseExtensions(json['allowed_video_extensions']),
      allowedAudioExtensions: _parseExtensions(json['allowed_audio_extensions']),
    );
  }
  static List<String> _parseExtensions(dynamic extensions) {
    if (extensions is List) {
      return extensions.map((e) => e.toString().trim()).toList();
    }
    if (extensions is String) {
      return extensions.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }
  Map<String, dynamic> toJson() {
    return {
      'max_photo_size': maxPhotoSize,
      'max_video_size': maxVideoSize,
      'max_audio_size': maxAudioSize,
      'allowed_photo_extensions': allowedPhotoExtensions,
      'allowed_video_extensions': allowedVideoExtensions,
      'allowed_audio_extensions': allowedAudioExtensions,
    };
  }
  /// حجم الصورة بالميجابايت
  double get maxPhotoSizeMB => maxPhotoSize / 1024.0;
  /// حجم الفيديو بالميجابايت
  double get maxVideoSizeMB => maxVideoSize / 1024.0;
  /// حجم الصوت بالميجابايت
  double get maxAudioSizeMB => maxAudioSize / 1024.0;
  /// التحقق من صيغة الصورة
  bool isPhotoExtensionAllowed(String extension) {
    return allowedPhotoExtensions.contains(extension.toLowerCase());
  }
  /// التحقق من صيغة الفيديو
  bool isVideoExtensionAllowed(String extension) {
    return allowedVideoExtensions.contains(extension.toLowerCase());
  }
  /// التحقق من صيغة الصوت
  bool isAudioExtensionAllowed(String extension) {
    return allowedAudioExtensions.contains(extension.toLowerCase());
  }
}