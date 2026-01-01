class PostMedia {
  final String? mediaId;
  final String? sourceUrl;
  final String? sourceProvider; // 'YouTube', 'Vimeo', etc.
  final String? sourceType; // 'rich', 'video', 'link', etc.
  final String? sourceTitle;
  final String? sourceText;
  final String? sourceHtml;
  final String? sourceThumbnail;

  PostMedia({
    this.mediaId,
    this.sourceUrl,
    this.sourceProvider,
    this.sourceType,
    this.sourceTitle,
    this.sourceText,
    this.sourceHtml,
    this.sourceThumbnail,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      mediaId: json['media_id']?.toString(),
      sourceUrl: json['source_url'] as String?,
      sourceProvider: json['source_provider'] as String?,
      sourceType: json['source_type'] as String?,
      sourceTitle: json['source_title'] as String?,
      sourceText: json['source_text'] as String?,
      sourceHtml: json['source_html'] as String?,
      sourceThumbnail: json['source_thumbnail'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'media_id': mediaId,
      'source_url': sourceUrl,
      'source_provider': sourceProvider,
      'source_type': sourceType,
      'source_title': sourceTitle,
      'source_text': sourceText,
      'source_html': sourceHtml,
      'source_thumbnail': sourceThumbnail,
    };
  }

  bool get isYouTube => sourceProvider?.toLowerCase() == 'youtube';
  bool get isVimeo => sourceProvider?.toLowerCase() == 'vimeo';
  bool get hasUrl => sourceUrl != null && sourceUrl!.isNotEmpty;
  bool get hasThumbnail => sourceThumbnail != null && sourceThumbnail!.isNotEmpty;
}
