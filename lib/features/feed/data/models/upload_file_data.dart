/// File upload related models for API communication
library;
/// Type of file being uploaded
enum FileUploadType {
  photo('photo'),
  video('video'),
  audio('audio'),
  file('file'); // Documents: pdf, doc, etc.
  const FileUploadType(this.value);
  final String value;
}
/// Data returned from file upload API
class UploadedFileData {
  const UploadedFileData({
    required this.source,
    required this.type,
    required this.url,
    this.thumb,
    this.name,
    this.size,
    this.blur = 0,
    this.duration,
    this.width,
    this.height,
    this.extension,
    this.meta,
  });
  /// Relative path on server (e.g., "content/uploads/photos/2025/11/abc.jpg")
  final String source;
  /// Type of uploaded file: photo, video, audio, file
  final String type;
  /// Full URL to access the file
  final String url;
  /// Thumbnail URL (for videos)
  final String? thumb;
  /// Original filename (for documents)
  final String? name;
  /// File size in bytes
  final int? size;
  /// Blur level (for photos that might contain sensitive content)
  final int blur;
  /// Video duration in seconds
  final int? duration;
  /// Video width in pixels
  final int? width;
  /// Video height in pixels
  final int? height;
  /// File extension (mp4, jpg, etc.)
  final String? extension;
  /// Additional metadata
  final Map<String, dynamic>? meta;
  factory UploadedFileData.fromJson(Map<String, dynamic> json) {
    return UploadedFileData(
      source: json['source'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      thumb: json['thumb'] as String?,
      name: json['name'] as String?,
      size: json['size'] as int?,
      blur: json['blur'] as int? ?? 0,
      duration: json['duration'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      extension: json['extension'] as String?,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'type': type,
      'url': url,
      if (thumb != null) 'thumb': thumb,
      if (name != null) 'name': name,
      if (size != null) 'size': size,
      'blur': blur,
      if (duration != null) 'duration': duration,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (extension != null) 'extension': extension,
      if (meta != null) 'meta': meta,
    };
  }
  @override
  String toString() => 'UploadedFileData(source: $source, type: $type, url: $url)';
}
