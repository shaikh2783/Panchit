class ChatSharedDraftModel {
  const ChatSharedDraftModel({
    required this.messageType,
    required this.postId,
    required this.reelId,
    required this.productPostId,
    required this.itemType,
    required this.title,
    required this.thumbnail,
    required this.url,
    required this.authorName,
    required this.draftMessage,
  });

  final String messageType;
  final int postId;
  final int reelId;
  final int productPostId;
  final String itemType;
  final String title;
  final String thumbnail;
  final String url;
  final String authorName;
  final String draftMessage;

  bool get isSharedPost => messageType == 'shared_post';
  bool get isSharedReel => messageType == 'shared_reel';
  bool get isProductShare => productPostId > 0;
  bool get isValid =>
      (isSharedPost && postId > 0) ||
      (isSharedReel && reelId > 0) ||
      isProductShare;

  factory ChatSharedDraftModel.fromUri(Uri uri) {
    return ChatSharedDraftModel(
      messageType:
          uri.queryParameters['messageType']?.trim() ??
          uri.queryParameters['message_type']?.trim() ??
          '',
      postId: _parseInt(
        uri.queryParameters['postId'] ?? uri.queryParameters['post_id'],
      ),
      reelId: _parseInt(
        uri.queryParameters['reelId'] ?? uri.queryParameters['reel_id'],
      ),
      productPostId: _parseInt(
        uri.queryParameters['productPostId'] ??
            uri.queryParameters['product_post_id'],
      ),
      itemType:
          uri.queryParameters['shareItemType']?.trim() ??
          uri.queryParameters['share_item_type']?.trim() ??
          '',
      title:
          uri.queryParameters['shareTitle']?.trim() ??
          uri.queryParameters['share_title']?.trim() ??
          '',
      thumbnail:
          uri.queryParameters['shareThumbnail']?.trim() ??
          uri.queryParameters['share_thumbnail']?.trim() ??
          '',
      url:
          uri.queryParameters['shareUrl']?.trim() ??
          uri.queryParameters['share_url']?.trim() ??
          '',
      authorName:
          uri.queryParameters['shareAuthor']?.trim() ??
          uri.queryParameters['share_author']?.trim() ??
          '',
      draftMessage:
          uri.queryParameters['draftMessage']?.trim() ??
          uri.queryParameters['draft_message']?.trim() ??
          '',
    );
  }
}

int _parseInt(String? value) {
  return int.tryParse(value ?? '') ?? 0;
}
