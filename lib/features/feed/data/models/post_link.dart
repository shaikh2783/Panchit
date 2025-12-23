class PostLink {
  PostLink({
    required this.linkId,
    required this.postId,
    required this.sourceUrl,
    required this.sourceHost,
    required this.sourceTitle,
    required this.sourceText,
    this.sourceThumbnail,
  });

  final String linkId;
  final String postId;
  final String sourceUrl;
  final String sourceHost;
  final String sourceTitle;
  final String sourceText;
  final String? sourceThumbnail;

  static PostLink? maybeFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;

    final linkId = json['link_id']?.toString();
    final postId = json['post_id']?.toString();
    final sourceUrl = json['source_url']?.toString();
    final sourceHost = json['source_host']?.toString();
    final sourceTitle = json['source_title']?.toString();
    final sourceText = json['source_text']?.toString();

    if (linkId == null || postId == null || sourceUrl == null) return null;

    return PostLink(
      linkId: linkId,
      postId: postId,
      sourceUrl: sourceUrl,
      sourceHost: sourceHost ?? '',
      sourceTitle: sourceTitle ?? sourceHost ?? '',
      sourceText: sourceText ?? '',
      sourceThumbnail: json['source_thumbnail']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'link_id': linkId,
      'post_id': postId,
      'source_url': sourceUrl,
      'source_host': sourceHost,
      'source_title': sourceTitle,
      'source_text': sourceText,
      if (sourceThumbnail != null) 'source_thumbnail': sourceThumbnail,
    };
  }

  PostLink copyWith({
    String? linkId,
    String? postId,
    String? sourceUrl,
    String? sourceHost,
    String? sourceTitle,
    String? sourceText,
    String? sourceThumbnail,
  }) {
    return PostLink(
      linkId: linkId ?? this.linkId,
      postId: postId ?? this.postId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceHost: sourceHost ?? this.sourceHost,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceText: sourceText ?? this.sourceText,
      sourceThumbnail: sourceThumbnail ?? this.sourceThumbnail,
    );
  }

  @override
  String toString() {
    return 'PostLink(linkId: $linkId, sourceUrl: $sourceUrl, sourceTitle: $sourceTitle)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PostLink &&
        other.linkId == linkId &&
        other.postId == postId &&
        other.sourceUrl == sourceUrl &&
        other.sourceHost == sourceHost &&
        other.sourceTitle == sourceTitle &&
        other.sourceText == sourceText &&
        other.sourceThumbnail == sourceThumbnail;
  }

  @override
  int get hashCode {
    return linkId.hashCode ^
        postId.hashCode ^
        sourceUrl.hashCode ^
        sourceHost.hashCode ^
        sourceTitle.hashCode ^
        sourceText.hashCode ^
        sourceThumbnail.hashCode;
  }
}