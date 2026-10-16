import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_translations.dart';
import '../../../../settings.dart';

class TimelineLauncher {
  TimelineLauncher._();

  static Future<void> openNode(
    BuildContext context, {
    required String nodeType,
    int? nodeId,
    String? nodeLink,
  }) async {
    final normalizedType = nodeType.trim().toLowerCase();
    final resolvedNodeId = nodeId ?? 0;
    final resolvedNodeLink = nodeLink?.trim() ?? '';

    switch (normalizedType) {
      case 'user':
        if (resolvedNodeId > 0) {
          await openUser(context, userId: resolvedNodeId);
        }
        return;
      case 'event':
        if (resolvedNodeId <= 0 && resolvedNodeLink.isEmpty) {
          return;
        }
        await _openTimeline(
          context,
          path: '/open/event',
          queryParameters: <String, String>{
            if (resolvedNodeId > 0) 'eventId': '$resolvedNodeId',
            if (resolvedNodeId > 0) 'event_id': '$resolvedNodeId',
            if (resolvedNodeLink.isNotEmpty) 'link': resolvedNodeLink,
            'launchTs': '${DateTime.now().millisecondsSinceEpoch}',
          },
        );
        return;
      case 'group':
        if (resolvedNodeId <= 0 && resolvedNodeLink.isEmpty) {
          return;
        }
        await _openTimeline(
          context,
          path: '/open/group',
          queryParameters: <String, String>{
            if (resolvedNodeId > 0) 'groupId': '$resolvedNodeId',
            if (resolvedNodeId > 0) 'group_id': '$resolvedNodeId',
            if (resolvedNodeLink.isNotEmpty) 'link': resolvedNodeLink,
            'launchTs': '${DateTime.now().millisecondsSinceEpoch}',
          },
        );
        return;
      case 'page':
        if (resolvedNodeId <= 0 && resolvedNodeLink.isEmpty) {
          return;
        }
        await _openTimeline(
          context,
          path: '/open/page',
          queryParameters: <String, String>{
            if (resolvedNodeId > 0) 'pageId': '$resolvedNodeId',
            if (resolvedNodeId > 0) 'page_id': '$resolvedNodeId',
            if (resolvedNodeLink.isNotEmpty) 'link': resolvedNodeLink,
            'launchTs': '${DateTime.now().millisecondsSinceEpoch}',
          },
        );
        return;
    }
  }

  static Future<void> openUser(
    BuildContext context, {
    required int userId,
  }) async {
    if (userId <= 0) {
      return;
    }
    await _openTimeline(
      context,
      path: '/open/user',
      queryParameters: <String, String>{
        'userId': '$userId',
        'user_id': '$userId',
        'launchTs': '${DateTime.now().millisecondsSinceEpoch}',
      },
    );
  }

  static Future<void> openPost(
    BuildContext context, {
    required int postId,
  }) async {
    if (postId <= 0) {
      return;
    }
    await _openTimeline(
      context,
      path: '/open/post',
      queryParameters: <String, String>{
        'postId': '$postId',
        'post_id': '$postId',
        'launchTs': '${DateTime.now().millisecondsSinceEpoch}',
      },
    );
  }

  static Future<void> openProduct(
    BuildContext context, {
    required int postId,
  }) async {
    if (postId <= 0) {
      return;
    }
    await _openTimeline(
      context,
      path: '/open/product',
      queryParameters: <String, String>{
        'postId': '$postId',
        'post_id': '$postId',
        'launchTs': '${DateTime.now().millisecondsSinceEpoch}',
      },
    );
  }

  static Future<void> openReel(
    BuildContext context, {
    int? postId,
    int? reelId,
  }) async {
    final resolvedPostId = postId ?? 0;
    final resolvedReelId = reelId ?? 0;
    if (resolvedPostId <= 0 && resolvedReelId <= 0) {
      return;
    }
    await _openTimeline(
      context,
      path: '/open/reel',
      queryParameters: <String, String>{
        if (resolvedPostId > 0) 'postId': '$resolvedPostId',
        if (resolvedPostId > 0) 'post_id': '$resolvedPostId',
        if (resolvedReelId > 0) 'reelId': '$resolvedReelId',
        if (resolvedReelId > 0) 'reel_id': '$resolvedReelId',
        'launchTs': '${DateTime.now().millisecondsSinceEpoch}',
      },
    );
  }

  static Future<void> openStory(
    BuildContext context, {
    required int userId,
    int? storyId,
    int? storyMediaId,
  }) async {
    final resolvedStoryId = storyId ?? 0;
    final resolvedStoryMediaId = storyMediaId ?? 0;
    if (userId <= 0 && resolvedStoryId <= 0 && resolvedStoryMediaId <= 0) {
      return;
    }
    await _openTimeline(
      context,
      path: '/open/story',
      queryParameters: <String, String>{
        if (userId > 0) 'userId': '$userId',
        if (userId > 0) 'user_id': '$userId',
        if (resolvedStoryId > 0) 'storyId': '$resolvedStoryId',
        if (resolvedStoryId > 0) 'story_id': '$resolvedStoryId',
        if (resolvedStoryMediaId > 0) 'storyMediaId': '$resolvedStoryMediaId',
        if (resolvedStoryMediaId > 0) 'story_media_id': '$resolvedStoryMediaId',
        'launchTs': '${DateTime.now().millisecondsSinceEpoch}',
      },
    );
  }

  static Future<void> _openTimeline(
    BuildContext context, {
    required String path,
    required Map<String, String> queryParameters,
  }) async {
    final uri = _buildTimelineUri(path: path, queryParameters: queryParameters);
    if (uri == null) {
      if (context.mounted) {
        await _promptTimelineDownload(context);
      }
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !context.mounted) {
        return;
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }
    }

    if (!context.mounted) {
      return;
    }
    await _promptTimelineDownload(context);
  }

  static Future<void> _promptTimelineDownload(BuildContext context) async {
    final shouldDownload =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(AppTranslations.timelineAppNotInstalledTitle.tr),
              content: Text(AppTranslations.timelineAppNotInstalledMessage.tr),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(AppTranslations.timelineAppCancelAction.tr),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(AppTranslations.timelineAppDownloadAction.tr),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDownload) {
      return;
    }

    final hasCustomUrl = Platform.isAndroid
        ? hasCustomTimelineAndroidStoreUrl
        : hasCustomTimelineIosStoreUrl;
    final customUri = Uri.parse(
      Platform.isAndroid ? timelineAndroidStoreUrl : timelineIosStoreUrl,
    );

    if (hasCustomUrl) {
      await launchUrl(customUri, mode: LaunchMode.externalApplication);
      return;
    }

    final primaryUri = Platform.isAndroid
        ? Uri.parse('market://details?id=$timelinePackage')
        : Uri.parse(
            'itms-apps://itunes.apple.com/search?term=${Uri.encodeComponent(timelineDeepLinkHost)}',
          );
    final fallbackUri = customUri;

    try {
      final opened = await launchUrl(
        primaryUri,
        mode: LaunchMode.externalApplication,
      );
      if (opened) {
        return;
      }
    } catch (_) {}

    await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
  }

  static Uri? _buildTimelineUri({
    required String path,
    required Map<String, String> queryParameters,
  }) {
    final scheme = _resolvedLaunchScheme(timelineUrlScheme);
    final host = timelineDeepLinkHost.trim();

    if (scheme.isNotEmpty && host.isNotEmpty) {
      return Uri(
        scheme: scheme,
        host: host,
        path: path,
        queryParameters: queryParameters,
      );
    }

    return null;
  }

  static String _resolvedLaunchScheme(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'sngine_timeline') {
      return 'sngine';
    }
    if (RegExp(r'^[A-Za-z][A-Za-z0-9+\-.]*$').hasMatch(normalized)) {
      return normalized;
    }
    return 'sngine';
  }
}
