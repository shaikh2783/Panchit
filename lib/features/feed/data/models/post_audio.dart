class PostAudio {
  PostAudio({
    required this.audioId,
    required this.postId,
    required this.source,
    required this.views,
    this.title,
    this.duration,
    this.size,
    this.fileExtension,
  });

  final String audioId;
  final String postId;
  final String source;
  final int views;
  final String? title;
  final Duration? duration;
  final int? size;
  final String? fileExtension;

  /// حصول على صيغة مدة الملف الصوتي
  String get formattedDuration {
    if (duration == null) return '0:00';
    final totalSeconds = duration!.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// حصول على حجم الملف المنسق
  String get formattedSize {
    if (size == null) return '';
    
    if (size! < 1024) {
      return '${size}B';
    } else if (size! < 1024 * 1024) {
      return '${(size! / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(size! / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// التحقق من صيغة الملف الصوتي
  bool get isMP3 => fileExtension?.toLowerCase() == 'mp3';
  bool get isWAV => fileExtension?.toLowerCase() == 'wav';
  bool get isM4A => fileExtension?.toLowerCase() == 'm4a';
  bool get isOGG => fileExtension?.toLowerCase() == 'ogg';

  factory PostAudio.fromJson(Map<String, dynamic> json) {
    // استخراج مدة الملف الصوتي إذا كانت متوفرة
    Duration? duration;
    if (json['duration'] != null) {
      final durationSeconds = int.tryParse(json['duration'].toString());
      if (durationSeconds != null) {
        duration = Duration(seconds: durationSeconds);
      }
    }

    // استخراج امتداد الملف من المصدر
    String? fileExtension;
    final source = json['source']?.toString();
    if (source != null && source.contains('.')) {
      fileExtension = source.split('.').last.toLowerCase();
    }

    return PostAudio(
      audioId: json['audio_id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      source: source ?? '',
      views: int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString(),
      duration: duration,
      size: int.tryParse(json['size']?.toString() ?? '0'),
      fileExtension: fileExtension,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audio_id': audioId,
      'post_id': postId,
      'source': source,
      'views': views,
      if (title != null) 'title': title,
      if (duration != null) 'duration': duration!.inSeconds,
      if (size != null) 'size': size,
      if (fileExtension != null) 'file_extension': fileExtension,
    };
  }

  static PostAudio? maybeFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    try {
      return PostAudio.fromJson(value);
    } catch (e) {

      return null;
    }
  }

  PostAudio copyWith({
    String? audioId,
    String? postId,
    String? source,
    int? views,
    String? title,
    Duration? duration,
    int? size,
    String? fileExtension,
  }) {
    return PostAudio(
      audioId: audioId ?? this.audioId,
      postId: postId ?? this.postId,
      source: source ?? this.source,
      views: views ?? this.views,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      fileExtension: fileExtension ?? this.fileExtension,
    );
  }

  @override
  String toString() {
    return 'PostAudio(audioId: $audioId, source: $source, duration: $formattedDuration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostAudio &&
        other.audioId == audioId &&
        other.postId == postId &&
        other.source == source;
  }

  @override
  int get hashCode {
    return audioId.hashCode ^ postId.hashCode ^ source.hashCode;
  }
}