import 'package:get/get.dart';

import '../../../../../api_config.dart';
import '../../../../core/localization/app_translations.dart';

class ChatStickersResponse {
  const ChatStickersResponse({
    required this.packName,
    required this.items,
    required this.packSummaries,
  });

  final String packName;
  final List<ChatStickerModel> items;
  final List<ChatStickerPackSummaryModel> packSummaries;

  factory ChatStickersResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final rawItems = (data['items'] as List?) ?? const [];
    final rawSummaries = (data['pack_summaries'] as List?) ?? const [];
    return ChatStickersResponse(
      packName: data['pack_name']?.toString() ?? 'all',
      items: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                ChatStickerModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      packSummaries: rawSummaries
          .whereType<Map>()
          .map(
            (item) => ChatStickerPackSummaryModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class ChatStickerPacksResponse {
  const ChatStickerPacksResponse({required this.items});

  final List<ChatStickerPackSummaryModel> items;

  factory ChatStickerPacksResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final rawItems = (data['items'] as List?) ?? const [];
    return ChatStickerPacksResponse(
      items: rawItems
          .whereType<Map>()
          .map(
            (item) => ChatStickerPackSummaryModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class ChatStickerModel {
  const ChatStickerModel({
    required this.id,
    required this.title,
    required this.packName,
    required this.packSlug,
    required this.folder,
    required this.image,
    required this.preview,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String packName;
  final String packSlug;
  final String folder;
  final String image;
  final String preview;
  final bool isActive;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  bool get isSvg {
    final candidate = resolvedImage;
    final path =
        Uri.tryParse(candidate)?.path.toLowerCase() ?? candidate.toLowerCase();
    return path.endsWith('.svg');
  }

  String get resolvedImage =>
      image.trim().isNotEmpty ? image.trim() : preview.trim();
  String get packKey {
    for (final value in <String>[packSlug, packName, folder]) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return id > 0 ? id.toString() : '';
  }

  bool matchesPack(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == 'all') {
      return true;
    }
    return packSlug == normalized ||
        packName == normalized ||
        folder == normalized ||
        id.toString() == normalized;
  }

  String get displayTitle =>
      title.trim().isNotEmpty ? title : AppTranslations.commonSticker.tr;

  factory ChatStickerModel.fromJson(Map<String, dynamic> json) {
    return ChatStickerModel(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      packName: json['pack_name']?.toString() ?? '',
      packSlug: json['pack_slug']?.toString() ?? '',
      folder: json['folder']?.toString() ?? '',
      image: _normalizeAssetUrl(json['image']),
      preview: _normalizeAssetUrl(json['preview']),
      isActive: _parseBool(json['is_active'] ?? true),
      sortOrder: _parseInt(json['sort_order']),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class ChatStickerPackSummaryModel {
  const ChatStickerPackSummaryModel({
    required this.id,
    required this.title,
    required this.packName,
    required this.packSlug,
    required this.folder,
    required this.preview,
    required this.count,
    required this.items,
  });

  final String id;
  final String title;
  final String packName;
  final String packSlug;
  final String folder;
  final String preview;
  final int count;
  final List<ChatStickerModel> items;

  String get selectionKey {
    for (final value in <String>[packSlug, packName, folder, id]) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  String get resolvedPreview {
    if (preview.trim().isNotEmpty) {
      return preview.trim();
    }
    for (final item in items) {
      if (item.resolvedImage.isNotEmpty) {
        return item.resolvedImage;
      }
    }
    return '';
  }

  int get resolvedCount => count > 0 ? count : items.length;

  String get displayTitle {
    for (final value in <String>[title, packName, packSlug, folder]) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return AppTranslations.commonSticker.tr;
  }

  factory ChatStickerPackSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    return ChatStickerPackSummaryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      packName: json['pack_name']?.toString() ?? '',
      packSlug: json['pack_slug']?.toString() ?? '',
      folder: json['folder']?.toString() ?? '',
      preview: _normalizeAssetUrl(json['preview']),
      count: _parseInt(json['count']),
      items: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                ChatStickerModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == '1' || normalized == 'true';
}

String _normalizeAssetUrl(dynamic value) {
  if (value == null) {
    return '';
  }
  final raw = value.toString().trim();
  if (raw.isEmpty || raw.toLowerCase() == 'null') {
    return '';
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  if (raw.startsWith('/')) {
    return '${ApiConfig.baseUrl}$raw';
  }
  if (raw.startsWith('api-addon-messangr/')) {
    return '${ApiConfig.baseUrl}/$raw';
  }
  return raw;
}
