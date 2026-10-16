import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/utils/audio_cache_warmer.dart';
import '../../../../core/utils/video_cache_warmer.dart';
import '../../../chat/data/models/chat_reaction_types_response.dart';
import '../../data/models/groups_chat_models.dart';
import '../../data/services/groups_chat_service.dart';
import '../controllers/group_chat_conversation_controller.dart';
import '../../utils/groups_chat_logger.dart';
import 'group_chat_settings_page.dart';

const Set<String> _groupAudioExtensions = <String>{
  'mp3',
  'm4a',
  'aac',
  'wav',
  'ogg',
  'oga',
  'flac',
  'opus',
  'amr',
  '3gp',
};

enum _GroupMessageAction { deleteForEveryone, muteMember, unmuteMember }

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key, required this.group});

  final GroupsChatGroupModel group;

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  late final String _tag;
  late final GroupChatConversationController _controller;

  @override
  void initState() {
    super.initState();
    _tag = 'group-chat-${widget.group.groupId}';
    GroupsChatLogger.log(
      'page',
      'open groupId=${widget.group.groupId} name="${widget.group.name}"',
    );
    _controller = Get.put(
      GroupChatConversationController(
        Get.find<GroupsChatService>(),
        Get.find<ChatAppPreferences>(),
        widget.group,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    GroupsChatLogger.log('page', 'close groupId=${widget.group.groupId}');
    Get.delete<GroupChatConversationController>(tag: _tag, force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _GroupChatPalette.of(context);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.cardBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: Obx(() => _GroupChatTitle(group: _controller.group.value)),
        actions: [
          Obx(
            () => _controller.isGroupDeleted.value
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: _openGroupSettings,
                    icon: const Icon(Icons.more_vert_rounded),
                    tooltip: AppTranslations.groupDetailsTitle.tr,
                  ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Obx(
          () => _controller.isGroupDeleted.value
              ? const _GroupDeletedView()
              : Column(
                  children: [
                    Expanded(child: _MessagesArea(controller: _controller)),
                    _GroupComposer(controller: _controller),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _openGroupSettings() async {
    final result = await Get.to<GroupChatSettingsResult>(
      () => GroupChatSettingsPage(initialGroup: _controller.group.value),
    );
    if (!mounted || result == null) {
      return;
    }
    if (result.left) {
      Navigator.of(context).pop();
      return;
    }
    final updated = result.group;
    if (updated != null) {
      _controller.updateGroup(updated);
    }
  }
}

class _GroupDeletedView extends StatelessWidget {
  const _GroupDeletedView();

  @override
  Widget build(BuildContext context) {
    final palette = _GroupChatPalette.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFC0394B).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFC0394B),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppTranslations.groupDetailsDeletedGroup.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: palette.strongText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppTranslations.groupDetailsDeleteGroupSubtitle.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.mutedText,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(AppTranslations.navChats.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupChatTitle extends StatelessWidget {
  const _GroupChatTitle({required this.group});

  final GroupsChatGroupModel group;

  @override
  Widget build(BuildContext context) {
    final palette = _GroupChatPalette.of(context);
    final theme = Theme.of(context);
    final membersLabel = group.memberCount == 1
        ? AppTranslations.groupsMember.tr
        : AppTranslations.groupsMembers.tr;

    return Row(
      children: [
        _GroupAvatar(imageUrl: group.imageUrl, name: group.name, radius: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                group.name.isEmpty
                    ? AppTranslations.groupsTitle.tr
                    : group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: palette.strongText,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${group.memberCount} $membersLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessagesArea extends StatelessWidget {
  const _MessagesArea({required this.controller});

  final GroupChatConversationController controller;

  @override
  Widget build(BuildContext context) {
    final palette = _GroupChatPalette.of(context);
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.errorMessage.value.isNotEmpty &&
          controller.messages.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.forum_outlined, size: 42, color: palette.mutedText),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.load,
                  child: Text(AppTranslations.retry.tr),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.messages.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: palette.softSurface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppTranslations.groupChatEmptyTitle.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.strongText,
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppTranslations.groupChatEmptyBody.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.mutedText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (controller.hasMore &&
              notification.metrics.maxScrollExtent > 0 &&
              notification.metrics.pixels <= 80) {
            controller.loadMore();
          }
          return false;
        },
        child: ListView.builder(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          itemCount:
              controller.messages.length +
              (controller.isLoadingMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (controller.isLoadingMore.value && index == 0) {
              return const Padding(
                key: ValueKey('group-loading-more-indicator'),
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final messageIndex =
                index - (controller.isLoadingMore.value ? 1 : 0);
            final message = controller.messages[messageIndex];
            final isOwn = controller.isOwnMessage(message);
            return _GroupMessageBubble(
              key: ValueKey('group-message-${message.messageId}'),
              message: message,
              isOwn: isOwn,
              canDeleteForEveryone:
                  isOwn || controller.group.value.canDeleteMessages,
              canMuteSender:
                  !isOwn &&
                  message.senderId > 0 &&
                  controller.group.value.canMuteMembers,
              canViewReactionAuthors:
                  controller.group.value.canViewReactionAuthors,
              reactionTypesRx: controller.reactionTypes,
              onDelete: () => controller.deleteMessage(message),
              onReact: (reaction) =>
                  controller.reactToMessage(message, reaction: reaction),
              onMuteSender: () => controller.muteMessageSender(message),
              onUnmuteSender: () => controller.unmuteMessageSender(message),
              fetchReactionAuthors: (reactionType, offset) =>
                  controller.fetchReactionAuthors(
                    message,
                    reactionType: reactionType,
                    offset: offset,
                  ),
              resolveSenderMember: () =>
                  controller.fetchMessageSenderMember(message),
            );
          },
        ),
      );
    });
  }
}

class _GroupMessageBubble extends StatelessWidget {
  const _GroupMessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.canDeleteForEveryone,
    required this.canMuteSender,
    required this.canViewReactionAuthors,
    required this.reactionTypesRx,
    required this.onDelete,
    required this.onReact,
    required this.onMuteSender,
    required this.onUnmuteSender,
    required this.fetchReactionAuthors,
    required this.resolveSenderMember,
  });

  final GroupsChatMessageModel message;
  final bool isOwn;
  final bool canDeleteForEveryone;
  final bool canMuteSender;
  final bool canViewReactionAuthors;
  final RxList<ChatReactionTypeModel> reactionTypesRx;
  final Future<void> Function() onDelete;
  final Future<void> Function(String reaction) onReact;
  final Future<void> Function() onMuteSender;
  final Future<void> Function() onUnmuteSender;
  final Future<GroupsChatReactionAuthorsResponse> Function(
    String reactionType,
    int? offset,
  )
  fetchReactionAuthors;
  final Future<GroupsChatMemberModel?> Function() resolveSenderMember;

  @override
  Widget build(BuildContext context) {
    final palette = _GroupChatPalette.of(context);
    final theme = Theme.of(context);
    final body = message.message.trim();
    final bubbleTextColor = isOwn ? palette.outgoingText : palette.strongText;
    final contentTextDirection = _resolvedTextDirection(body);
    final avatar = !isOwn
        ? Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _GroupAvatar(
              imageUrl: message.sender?.picture ?? '',
              name: message.senderName,
              radius: 16,
            ),
          )
        : null;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: message.hasMedia ? 280 : 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isOwn ? null : palette.incomingBubble,
        gradient: isOwn ? MessengerDesign.primaryGradient : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isOwn ? 18 : 5),
          bottomRight: Radius.circular(isOwn ? 5 : 18),
        ),
        border: isOwn
            ? null
            : Border.all(color: palette.sectionBorder, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.hasMedia)
            Padding(
              padding: EdgeInsets.only(bottom: body.isNotEmpty ? 10 : 0),
              child: _GroupMediaAttachment(message: message, isOwn: isOwn),
            ),
          if (body.isNotEmpty)
            Directionality(
              textDirection: contentTextDirection,
              child: Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bubbleTextColor,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else if (!message.hasMedia)
            _MediaPlaceholder(message: message, isOwn: isOwn),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isOwn
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isOwn && message.senderName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 42, bottom: 4),
              child: Text(
                message.senderName,
                textAlign: TextAlign.left,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.messageMetaText,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          Align(
            alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              textDirection: TextDirection.ltr,
              children: [
                if (!isOwn && avatar != null) ...[
                  avatar,
                  const SizedBox(width: 8),
                ],
                GestureDetector(
                  onLongPress: () => _showMessageActions(context),
                  child: bubble,
                ),
              ],
            ),
          ),
          if (message.hasReactions)
            Padding(
              padding: EdgeInsets.only(
                top: 3,
                left: isOwn ? 0 : 42,
                right: isOwn ? 2 : 0,
              ),
              child: Align(
                alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => _showReactionAuthors(context),
                  child: _GroupReactionSummaryChip(
                    reactionType: message.displayedReactionType,
                    reactionCounts: message.reactionCounts,
                    reactionTypesRx: reactionTypesRx,
                    count: message.reactionsTotalCount,
                    isHighlighted: message.iReact,
                    isOwn: isOwn,
                    mutedText: palette.messageMetaText,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              message.timeLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.messageMetaText,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMessageActions(BuildContext context) async {
    final senderMember = canMuteSender ? await resolveSenderMember() : null;
    if (!context.mounted) {
      return;
    }
    final senderIsMuted = senderMember?.isMutedByAdmin ?? false;
    final action = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() {
                  final reactionTypes = reactionTypesRx.toList(growable: false);
                  if (reactionTypes.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: reactionTypes
                            .map(
                              (option) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: _GroupReactionOptionButton(
                                  option: option,
                                  isSelected:
                                      message.myReactionType == option.key,
                                  onTap: () => Navigator.of(
                                    sheetContext,
                                  ).pop(option.key),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  );
                }),
                if (canDeleteForEveryone)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: Text(
                      AppTranslations.groupMessageDeleteForEveryone.tr,
                    ),
                    onTap: () => Navigator.of(
                      sheetContext,
                    ).pop(_GroupMessageAction.deleteForEveryone),
                  ),
                if (canMuteSender)
                  ListTile(
                    leading: Icon(
                      senderIsMuted
                          ? Icons.volume_up_outlined
                          : Icons.volume_off_outlined,
                    ),
                    title: Text(
                      senderIsMuted
                          ? AppTranslations.groupMemberUnmute.tr
                          : AppTranslations.groupMemberMute.tr,
                    ),
                    onTap: () => Navigator.of(sheetContext).pop(
                      senderIsMuted
                          ? _GroupMessageAction.unmuteMember
                          : _GroupMessageAction.muteMember,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (action == null || !context.mounted) {
      return;
    }

    try {
      if (action is String) {
        await onReact(action);
        return;
      }
      if (action is! _GroupMessageAction) {
        return;
      }
      switch (action) {
        case _GroupMessageAction.deleteForEveryone:
          await onDelete();
          break;
        case _GroupMessageAction.muteMember:
          await onMuteSender();
          break;
        case _GroupMessageAction.unmuteMember:
          await onUnmuteSender();
          break;
      }
      if (!context.mounted) {
        return;
      }
      Get.snackbar(
        action == _GroupMessageAction.deleteForEveryone
            ? AppTranslations.groupMessageDeleted.tr
            : action == _GroupMessageAction.muteMember
            ? AppTranslations.groupMemberMuted.tr
            : AppTranslations.groupMemberUnmute.tr,
        action == _GroupMessageAction.deleteForEveryone
            ? AppTranslations.groupMessageDeleteForEveryone.tr
            : action == _GroupMessageAction.muteMember
            ? AppTranslations.groupMemberMute.tr
            : AppTranslations.groupMemberUnmute.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      Get.snackbar(
        action == _GroupMessageAction.deleteForEveryone
            ? AppTranslations.groupMessageUnableToDelete.tr
            : AppTranslations.groupDetailsUnableToSave.tr,
        action == _GroupMessageAction.deleteForEveryone
            ? AppTranslations.groupMessageDeleteForEveryone.tr
            : action == _GroupMessageAction.muteMember
            ? AppTranslations.groupMemberMute.tr
            : AppTranslations.groupMemberUnmute.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _showReactionAuthors(BuildContext context) async {
    if (!canViewReactionAuthors) {
      Get.snackbar(
        AppTranslations.groupReactionsAdminsOnly.tr,
        AppTranslations.groupReactionsAuthorsTitle.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: FutureBuilder<GroupsChatReactionAuthorsResponse>(
            future: fetchReactionAuthors('all', null),
            builder: (context, snapshot) {
              final items =
                  snapshot.data?.items ??
                  const <GroupsChatReactionAuthorModel>[];
              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppTranslations.groupReactionsAuthorsTitle.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      )
                    else if (snapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          AppTranslations.groupReactionsUnableToLoad.tr,
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          AppTranslations.groupReactionsEmpty.tr,
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Row(
                              children: [
                                _GroupAvatar(
                                  imageUrl: item.picture,
                                  name: item.displayName,
                                  radius: 19,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                _GroupReactionIconBadge(
                                  reactionKey: item.reaction,
                                  reactionImageUrl: item.reactionImageUrl,
                                  reactionTypes: reactionTypesRx.toList(
                                    growable: false,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _GroupReactionOptionButton extends StatelessWidget {
  const _GroupReactionOptionButton({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ChatReactionTypeModel option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: _GroupReactionIcon(option: option),
        ),
      ),
    );
  }
}

class _GroupReactionIcon extends StatelessWidget {
  const _GroupReactionIcon({required this.option});

  final ChatReactionTypeModel option;

  @override
  Widget build(BuildContext context) {
    if (option.hasIconUrl) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: option.iconUrl,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) =>
              _GroupReactionEmojiFallback(emoji: option.emoji),
        ),
      );
    }

    return _GroupReactionEmojiFallback(emoji: option.emoji);
  }
}

class _GroupReactionEmojiFallback extends StatelessWidget {
  const _GroupReactionEmojiFallback({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji.isEmpty ? _emojiForReaction('like') : emoji,
      style: const TextStyle(fontSize: 24, height: 1),
      textAlign: TextAlign.center,
    );
  }
}

class _GroupReactionSummaryChip extends StatelessWidget {
  const _GroupReactionSummaryChip({
    required this.reactionType,
    required this.reactionCounts,
    required this.reactionTypesRx,
    required this.count,
    required this.isHighlighted,
    required this.isOwn,
    required this.mutedText,
  });

  final String reactionType;
  final Map<String, int> reactionCounts;
  final RxList<ChatReactionTypeModel> reactionTypesRx;
  final int count;
  final bool isHighlighted;
  final bool isOwn;
  final Color mutedText;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reactionTypes = reactionTypesRx.toList(growable: false);
      final distinctReactionKeys = reactionCounts.entries.toList()
        ..sort((a, b) {
          final countCompare = b.value.compareTo(a.value);
          if (countCompare != 0) {
            return countCompare;
          }
          return a.key.compareTo(b.key);
        });
      final visibleReactionKeys = distinctReactionKeys
          .map((entry) => entry.key)
          .where((key) => key.trim().isNotEmpty)
          .take(3)
          .toList();
      final background = isOwn
          ? AppColors.primary.withValues(alpha: isHighlighted ? 0.16 : 0.1)
          : Colors.white.withValues(alpha: 0.86);
      final borderColor = isHighlighted
          ? AppColors.primary.withValues(alpha: 0.3)
          : mutedText.withValues(alpha: 0.18);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [
            _GroupReactionIconsCluster(
              reactionKeys: visibleReactionKeys.isEmpty
                  ? [reactionType]
                  : visibleReactionKeys,
              reactionTypes: reactionTypes,
            ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isHighlighted ? AppColors.primary : mutedText,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _GroupReactionIconsCluster extends StatelessWidget {
  const _GroupReactionIconsCluster({
    required this.reactionKeys,
    required this.reactionTypes,
  });

  final List<String> reactionKeys;
  final List<ChatReactionTypeModel> reactionTypes;

  @override
  Widget build(BuildContext context) {
    final visibleKeys = reactionKeys
        .where((key) => key.trim().isNotEmpty)
        .take(3)
        .toList();
    final width = 18 + ((visibleKeys.length - 1).clamp(0, 2) * 12);

    return SizedBox(
      width: width.toDouble(),
      height: 18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < visibleKeys.length; index++)
            Positioned(
              left: index * 12,
              child: _GroupReactionIconBadge(
                reactionKey: visibleKeys[index],
                reactionImageUrl: '',
                reactionTypes: reactionTypes,
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupReactionIconBadge extends StatelessWidget {
  const _GroupReactionIconBadge({
    required this.reactionKey,
    required this.reactionImageUrl,
    required this.reactionTypes,
  });

  final String reactionKey;
  final String reactionImageUrl;
  final List<ChatReactionTypeModel> reactionTypes;

  @override
  Widget build(BuildContext context) {
    final reactionModel = reactionTypes
        .where((type) => type.key == reactionKey)
        .firstOrNull;
    final imageUrl = reactionImageUrl.trim().isNotEmpty
        ? reactionImageUrl.trim()
        : reactionModel?.iconUrl.trim() ?? '';
    final emoji = reactionModel?.emoji ?? _emojiForReaction(reactionKey);

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      alignment: Alignment.center,
      child: imageUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 16,
                height: 16,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) =>
                    _GroupReactionEmojiFallback(emoji: emoji),
              ),
            )
          : _GroupReactionEmojiFallback(emoji: emoji),
    );
  }
}

String _emojiForReaction(String reactionType) {
  return switch (reactionType) {
    'love' => '❤️',
    'haha' => '😂',
    'yay' => '🎉',
    'wow' => '😮',
    'sad' => '😢',
    'angry' => '😡',
    _ => '👍',
  };
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.message, required this.isOwn});

  final GroupsChatMessageModel message;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final color = isOwn ? AppColors.white : AppColors.primary;
    final label = switch (message.messageType) {
      'image' => AppTranslations.groupsPhoto.tr,
      'video' => AppTranslations.groupsVideo.tr,
      'audio' => AppTranslations.groupsVoice.tr,
      'voice_note' => AppTranslations.groupsVoice.tr,
      'file' => AppTranslations.groupsFile.tr,
      _ => AppTranslations.commonChat.tr,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_mediaIcon(message.messageType), size: 18, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  IconData _mediaIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'audio':
      case 'voice_note':
        return Icons.mic_none_rounded;
      case 'file':
        return Icons.insert_drive_file_outlined;
      default:
        return Icons.attachment_rounded;
    }
  }
}

class _GroupMediaAttachment extends StatelessWidget {
  const _GroupMediaAttachment({required this.message, required this.isOwn});

  final GroupsChatMessageModel message;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final url = message.mediaBestUrl;
    if (url.isEmpty) {
      return _MediaPlaceholder(message: message, isOwn: isOwn);
    }

    if (_isVideoMessage(message)) {
      return _GroupVideoAttachment(
        key: ValueKey('group-video-${message.messageId}-$url'),
        videoUrl: url,
        isOwn: isOwn,
      );
    }

    if (_isAudioMessage(message)) {
      return _GroupVoiceNoteAttachment(
        key: ValueKey('group-audio-${message.messageId}-$url'),
        audioUrl: url,
        isOwn: isOwn,
      );
    }

    if (message.messageType == 'image') {
      return GestureDetector(
        onTap: () => _openImagePreview(context, url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CachedNetworkImage(
            imageUrl: url,
            width: 208,
            height: 208,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (_, _) => Container(
              width: 208,
              height: 208,
              color: Colors.black.withValues(alpha: 0.08),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (_, _, _) => _AttachmentTile(
              message: message,
              isOwn: isOwn,
              onTap: () => _openMediaUrl(context, url),
            ),
          ),
        ),
      );
    }

    return _AttachmentTile(
      message: message,
      isOwn: isOwn,
      onTap: () => _openMediaUrl(context, url),
    );
  }

  void _openImagePreview(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    errorWidget: (_, _, _) => Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.white,
                      size: 38,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupMediaPlaybackCoordinator {
  _GroupMediaPlaybackCoordinator._();

  static final _GroupMediaPlaybackCoordinator instance =
      _GroupMediaPlaybackCoordinator._();

  String? _activeId;
  Future<void> Function()? _stopActive;

  Future<void> activate({
    required String id,
    required Future<void> Function() stopPlayback,
  }) async {
    if (_activeId == id) {
      _stopActive = stopPlayback;
      return;
    }

    final previousStop = _stopActive;
    _activeId = id;
    _stopActive = stopPlayback;
    await previousStop?.call();
  }

  void deactivate(String id) {
    if (_activeId != id) {
      return;
    }
    _activeId = null;
    _stopActive = null;
  }
}

class _GroupVoiceNoteAttachment extends StatefulWidget {
  const _GroupVoiceNoteAttachment({
    super.key,
    required this.audioUrl,
    required this.isOwn,
  });

  final String audioUrl;
  final bool isOwn;

  @override
  State<_GroupVoiceNoteAttachment> createState() =>
      _GroupVoiceNoteAttachmentState();
}

class _GroupVoiceNoteAttachmentState extends State<_GroupVoiceNoteAttachment> {
  late final AudioPlayer _player;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isReady = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isPriming = false;

  String get _playbackId => 'group-audio:${widget.audioUrl}';

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _durationSubscription = _player.durationStream.listen((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        _duration = value ?? Duration.zero;
      });
    });
    _positionSubscription = _player.positionStream.listen((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        _position = value;
      });
    });
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (!mounted) {
        return;
      }
      if (state.processingState == ProcessingState.completed) {
        unawaited(_player.seek(Duration.zero));
        unawaited(_player.pause());
        _GroupMediaPlaybackCoordinator.instance.deactivate(_playbackId);
      }
      setState(() {});
    });
    unawaited(_primeAudio());
  }

  @override
  void didUpdateWidget(covariant _GroupVoiceNoteAttachment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl == widget.audioUrl) {
      return;
    }
    _GroupMediaPlaybackCoordinator.instance.deactivate(
      'group-audio:${oldWidget.audioUrl}',
    );
    _duration = Duration.zero;
    _position = Duration.zero;
    _isReady = false;
    _isLoading = false;
    _hasError = false;
    _isPriming = false;
    unawaited(_player.stop());
    unawaited(_primeAudio());
  }

  Future<void> _primeAudio() async {
    if (_isPriming || _isReady || _isLoading) {
      return;
    }

    _isPriming = true;
    try {
      final duration = await _setAudioSource();
      if (!mounted) {
        return;
      }
      setState(() {
        _isReady = true;
        _hasError = false;
        _duration = duration ?? _duration;
      });
    } catch (error) {
      GroupsChatLogger.error('group_audio.prime', error);
      if (!mounted) {
        return;
      }
      setState(() {
        _hasError = true;
      });
    } finally {
      _isPriming = false;
    }
  }

  Future<void> _initialize() async {
    if (_isReady || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final duration = await _setAudioSource();
      if (!mounted) {
        return;
      }
      setState(() {
        _isReady = true;
        _isLoading = false;
        _hasError = false;
        _duration = duration ?? _duration;
      });
    } catch (error) {
      GroupsChatLogger.error('group_audio.initialize', error);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<Duration?> _setAudioSource() async {
    try {
      unawaited(AudioCacheWarmer.warm(widget.audioUrl));
      return await _player.setUrl(widget.audioUrl);
    } catch (networkError) {
      GroupsChatLogger.error('group_audio.setUrl', networkError);
      final cachedFile = await AudioCacheWarmer.getCachedFile(widget.audioUrl);
      if (cachedFile == null) {
        rethrow;
      }
      final playableFile = await _playableCachedAudioFile(
        cachedFile,
        widget.audioUrl,
      );
      return _player.setFilePath(playableFile.path);
    }
  }

  Future<File> _playableCachedAudioFile(
    File cachedFile,
    String audioUrl,
  ) async {
    final extension = _audioExtensionFromUrl(audioUrl);
    if (extension.isEmpty ||
        cachedFile.path.toLowerCase().endsWith('.$extension')) {
      return cachedFile;
    }

    final playableFile = File('${cachedFile.path}.$extension');
    if (await playableFile.exists()) {
      return playableFile;
    }

    return cachedFile.copy(playableFile.path);
  }

  String _audioExtensionFromUrl(String audioUrl) {
    final uri = Uri.tryParse(audioUrl);
    final path = uri?.path.trim().isNotEmpty == true ? uri!.path : audioUrl;
    final filename = path.split('/').last;
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == filename.length - 1) {
      return 'm4a';
    }

    final extension = filename.substring(dotIndex + 1).toLowerCase();
    const supportedExtensions = <String>{
      'mp3',
      'm4a',
      'aac',
      'wav',
      'ogg',
      'oga',
      'flac',
      'opus',
      'amr',
      '3gp',
    };
    return supportedExtensions.contains(extension) ? extension : 'm4a';
  }

  Future<void> _pausePlayback() async {
    if (_player.playing) {
      await _player.pause();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (!_isReady) {
      await _initialize();
    }
    if (!_isReady) {
      return;
    }

    if (_player.playing) {
      await _pausePlayback();
      _GroupMediaPlaybackCoordinator.instance.deactivate(_playbackId);
    } else {
      await _GroupMediaPlaybackCoordinator.instance.activate(
        id: _playbackId,
        stopPlayback: _pausePlayback,
      );
      await _player.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _retryPlayback() async {
    await _player.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _isReady = false;
      _isLoading = false;
      _hasError = false;
      _duration = Duration.zero;
      _position = Duration.zero;
    });
    await _togglePlayback();
  }

  @override
  void dispose() {
    _GroupMediaPlaybackCoordinator.instance.deactivate(_playbackId);
    unawaited(_durationSubscription?.cancel() ?? Future<void>.value());
    unawaited(_positionSubscription?.cancel() ?? Future<void>.value());
    unawaited(_stateSubscription?.cancel() ?? Future<void>.value());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _GroupChatPalette.of(context);
    final textColor = widget.isOwn ? AppColors.white : palette.strongText;
    final accentColor = widget.isOwn ? AppColors.white : AppColors.primary;
    final mutedColor = widget.isOwn
        ? AppColors.white.withValues(alpha: 0.75)
        : palette.mutedText;
    final isPlaying = _player.playing;
    final effectiveDuration = _duration.inMilliseconds <= 0
        ? const Duration(seconds: 1)
        : _duration;
    final clampedPosition = _position > effectiveDuration
        ? effectiveDuration
        : _position;

    if (_hasError) {
      return _AudioRetryTile(
        label: AppTranslations.groupsVoice.tr,
        subtitle: AppTranslations.chatVoiceUnavailable.tr,
        isOwn: widget.isOwn,
        onRetry: _retryPlayback,
        onOpenExternal: () => _openMediaUrl(context, widget.audioUrl),
      );
    }

    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _togglePlayback,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              accentColor,
                            ),
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: accentColor,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppTranslations.groupsVoice.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _formatPlaybackDuration(clampedPosition),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: accentColor,
              inactiveTrackColor: mutedColor.withValues(alpha: 0.34),
              thumbColor: accentColor,
            ),
            child: Slider(
              value: clampedPosition.inMilliseconds
                  .clamp(0, effectiveDuration.inMilliseconds)
                  .toDouble(),
              max: effectiveDuration.inMilliseconds.toDouble(),
              onChanged: !_isReady || _isLoading
                  ? null
                  : (value) =>
                        _player.seek(Duration(milliseconds: value.round())),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _formatPlaybackDuration(effectiveDuration),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: mutedColor, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupVideoAttachment extends StatefulWidget {
  const _GroupVideoAttachment({
    super.key,
    required this.videoUrl,
    required this.isOwn,
  });

  final String videoUrl;
  final bool isOwn;

  @override
  State<_GroupVideoAttachment> createState() => _GroupVideoAttachmentState();
}

class _GroupVideoAttachmentState extends State<_GroupVideoAttachment> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;

  String get _playbackId => 'group-video:${widget.videoUrl}';

  @override
  void initState() {
    super.initState();
    unawaited(VideoCacheWarmer.warm(widget.videoUrl));
  }

  @override
  void didUpdateWidget(covariant _GroupVideoAttachment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl == widget.videoUrl) {
      return;
    }
    final previousController = _controller;
    _controller = null;
    _loading = false;
    _failed = false;
    _GroupMediaPlaybackCoordinator.instance.deactivate(
      'group-video:${oldWidget.videoUrl}',
    );
    unawaited(previousController?.dispose() ?? Future<void>.value());
    unawaited(VideoCacheWarmer.warm(widget.videoUrl));
  }

  Future<void> _togglePlayback() async {
    if (_loading) {
      return;
    }

    final existingController = _controller;
    if (existingController != null) {
      if (existingController.value.isPlaying) {
        await _pausePlayback();
        _GroupMediaPlaybackCoordinator.instance.deactivate(_playbackId);
      } else {
        if (existingController.value.position >=
            existingController.value.duration) {
          await existingController.seekTo(Duration.zero);
        }
        await _GroupMediaPlaybackCoordinator.instance.activate(
          id: _playbackId,
          stopPlayback: _pausePlayback,
        );
        await existingController.play();
      }
      if (mounted) {
        setState(() {});
      }
      return;
    }

    setState(() {
      _loading = true;
      _failed = false;
    });

    VideoPlayerController? controller;
    try {
      controller = await VideoCacheWarmer.createController(widget.videoUrl);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
      await _GroupMediaPlaybackCoordinator.instance.activate(
        id: _playbackId,
        stopPlayback: _pausePlayback,
      );
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      await controller?.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _controller = null;
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _pausePlayback() async {
    final controller = _controller;
    if (controller != null && controller.value.isPlaying) {
      await controller.pause();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _GroupMediaPlaybackCoordinator.instance.deactivate(_playbackId);
    unawaited(_controller?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    const width = 220.0;
    const height = 220.0;

    if (_failed) {
      return SizedBox(
        width: width,
        child: _MediaUnavailableTile(
          label: AppTranslations.chatVideoUnavailable.tr,
          isOwn: widget.isOwn,
          onTap: () => _openMediaUrl(context, widget.videoUrl),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: width,
        height: height,
        child: _loading
            ? Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              )
            : controller == null
            ? _VideoIdleSurface(
                onPlay: _togglePlayback,
                onOpen: () => _openMediaUrl(context, widget.videoUrl),
              )
            : ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final duration = value.duration;
                  final position = value.position > duration
                      ? duration
                      : value.position;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: value.size.width <= 0
                                  ? 16
                                  : value.size.width,
                              height: value.size.height <= 0
                                  ? 9
                                  : value.size.height,
                              child: VideoPlayer(controller),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.18),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.62),
                              ],
                              stops: const [0, 0.5, 1],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: _VideoRoundButton(
                          icon: value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          onTap: _togglePlayback,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _VideoOpenButton(
                          onTap: () => _openMediaUrl(context, widget.videoUrl),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VideoProgressIndicator(
                              controller,
                              allowScrubbing: true,
                              padding: EdgeInsets.zero,
                              colors: VideoProgressColors(
                                playedColor: AppColors.primary,
                                bufferedColor: Colors.white.withValues(
                                  alpha: 0.36,
                                ),
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Text(
                                  _formatPlaybackDuration(position),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatPlaybackDuration(duration),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.86),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _VideoIdleSurface extends StatelessWidget {
  const _VideoIdleSurface({required this.onPlay, required this.onOpen});

  final VoidCallback onPlay;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.04),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.52),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: _VideoRoundButton(
              icon: Icons.play_arrow_rounded,
              onTap: onPlay,
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: _VideoOpenButton(onTap: onOpen),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Row(
              children: [
                const Icon(
                  Icons.videocam_outlined,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    AppTranslations.groupsVideo.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoRoundButton extends StatelessWidget {
  const _VideoRoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.58),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 34),
      ),
    );
  }
}

class _VideoOpenButton extends StatelessWidget {
  const _VideoOpenButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppTranslations.commonVideo.tr,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.56),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.open_in_full_rounded,
            color: Colors.white,
            size: 17,
          ),
        ),
      ),
    );
  }
}

class _MediaUnavailableTile extends StatelessWidget {
  const _MediaUnavailableTile({
    required this.label,
    required this.isOwn,
    required this.onTap,
  });

  final String label;
  final bool isOwn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _GroupChatPalette.of(context);
    final color = isOwn ? AppColors.white : palette.strongText;
    final muted = isOwn
        ? AppColors.white.withValues(alpha: 0.75)
        : palette.mutedText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOwn
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: muted.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Icon(Icons.open_in_new_rounded, color: muted, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioRetryTile extends StatelessWidget {
  const _AudioRetryTile({
    required this.label,
    required this.subtitle,
    required this.isOwn,
    required this.onRetry,
    required this.onOpenExternal,
  });

  final String label;
  final String subtitle;
  final bool isOwn;
  final VoidCallback onRetry;
  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final palette = _GroupChatPalette.of(context);
    final color = isOwn ? AppColors.white : palette.strongText;
    final muted = isOwn
        ? AppColors.white.withValues(alpha: 0.75)
        : palette.mutedText;
    final accent = isOwn ? AppColors.white : AppColors.primary;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOwn
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: muted.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRetry,
              customBorder: const CircleBorder(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.replay_rounded, color: accent, size: 21),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onOpenExternal,
            icon: Icon(Icons.open_in_new_rounded, color: muted, size: 18),
            tooltip: AppTranslations.chatInfoOpen.tr,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.message,
    required this.isOwn,
    required this.onTap,
  });

  final GroupsChatMessageModel message;
  final bool isOwn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _GroupChatPalette.of(context);
    final theme = Theme.of(context);
    final foreground = isOwn ? AppColors.white : AppColors.primary;
    final textColor = isOwn ? AppColors.white : palette.strongText;
    final muted = isOwn
        ? AppColors.white.withValues(alpha: 0.74)
        : palette.mutedText;
    final title = message.attachmentName.isNotEmpty
        ? message.attachmentName
        : _mediaLabel(message.messageType);
    final subtitle = _attachmentSubtitle(message);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 216,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOwn
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isOwn
                  ? Colors.white.withValues(alpha: 0.16)
                  : AppColors.primary.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: isOwn ? 0.12 : 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _mediaIconForType(message),
                  color: foreground,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, size: 18, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openMediaUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return;
  }

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    Get.snackbar(
      AppTranslations.loginFailed.tr,
      AppTranslations.chatSharedItemOpenFailed.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

bool _isVideoMessage(GroupsChatMessageModel message) {
  return message.messageType == 'video' ||
      message.attachmentMimeType.startsWith('video/');
}

bool _isAudioMessage(GroupsChatMessageModel message) {
  final extension = _attachmentExtension(message.attachmentName);
  return message.messageType == 'audio' ||
      message.messageType == 'voice' ||
      message.messageType == 'voice_note' ||
      message.attachmentMimeType.startsWith('audio/') ||
      _groupAudioExtensions.contains(extension);
}

IconData _mediaIconForType(GroupsChatMessageModel message) {
  final mimeType = message.attachmentMimeType;
  final extension = _attachmentExtension(message.attachmentName);
  if (message.messageType == 'image' || mimeType.startsWith('image/')) {
    return Icons.image_outlined;
  }
  if (message.messageType == 'video' || mimeType.startsWith('video/')) {
    return Icons.videocam_outlined;
  }
  if (message.messageType == 'audio' ||
      mimeType.startsWith('audio/') ||
      _groupAudioExtensions.contains(extension)) {
    return Icons.audio_file_outlined;
  }
  if (mimeType == 'application/pdf' || extension == 'pdf') {
    return Icons.picture_as_pdf_outlined;
  }
  if (const <String>{'doc', 'docx', 'txt', 'rtf'}.contains(extension)) {
    return Icons.description_outlined;
  }
  if (const <String>{'xls', 'xlsx', 'csv'}.contains(extension)) {
    return Icons.table_chart_outlined;
  }
  if (const <String>{'zip', 'rar', '7z'}.contains(extension)) {
    return Icons.folder_zip_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

String _mediaLabel(String type) {
  switch (type) {
    case 'image':
      return AppTranslations.groupsPhoto.tr;
    case 'video':
      return AppTranslations.groupsVideo.tr;
    case 'audio':
    case 'voice_note':
      return AppTranslations.groupsVoice.tr;
    case 'file':
      return AppTranslations.groupsFile.tr;
    default:
      return AppTranslations.commonChat.tr;
  }
}

String _attachmentSubtitle(GroupsChatMessageModel message) {
  final parts = <String>[];
  final extension = _attachmentExtension(message.attachmentName);
  if (extension.isNotEmpty) {
    parts.add(extension.toUpperCase());
  } else {
    parts.add(_mediaLabel(message.messageType));
  }
  if (message.attachmentSize > 0) {
    parts.add(_formatFileSize(message.attachmentSize));
  }
  return parts.join(' • ');
}

String _attachmentExtension(String filename) {
  final trimmedName = filename.trim().toLowerCase();
  final dotIndex = trimmedName.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == trimmedName.length - 1) {
    return '';
  }
  return trimmedName.substring(dotIndex + 1);
}

String _formatPlaybackDuration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

String _formatFileSize(int bytes) {
  const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  double size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final display = unitIndex == 0
      ? size.toStringAsFixed(0)
      : size.toStringAsFixed(1);
  return '$display ${units[unitIndex]}';
}

class _GroupComposer extends StatelessWidget {
  const _GroupComposer({required this.controller});

  final GroupChatConversationController controller;

  @override
  Widget build(BuildContext context) {
    final palette = _GroupChatPalette.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Obx(() {
      final canSend = controller.canSendMessages;
      final isMutedByAdmin = controller.isCurrentUserMutedByAdmin;
      final busy = controller.isSending.value;
      final recording = controller.isRecordingVoice.value;
      final disabledMessage = isMutedByAdmin
          ? AppTranslations.groupChatMutedByAdmin.tr
          : AppTranslations.groupChatOnlyAdmins.tr;
      return Container(
        padding: EdgeInsets.fromLTRB(12, 10, 12, bottomInset > 0 ? 10 : 12),
        decoration: BoxDecoration(
          color: palette.cardBackground,
          border: Border(top: BorderSide(color: palette.sectionBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!canSend)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      isMutedByAdmin
                          ? Icons.volume_off_outlined
                          : Icons.admin_panel_settings_outlined,
                      size: 17,
                      color: palette.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        disabledMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (canSend) ...[
                  _ComposerToolButton(
                    icon: Icons.add_rounded,
                    tooltip: AppTranslations.composeMessage.tr,
                    onTap: busy ? null : () => _openAttachmentMenu(context),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.softSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: controller.inputController,
                      enabled: canSend,
                      minLines: 1,
                      maxLines: 4,
                      cursorColor: AppColors.primary,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: canSend
                            ? AppTranslations.groupChatInputHint.tr
                            : disabledMessage,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.mutedText.withValues(alpha: 0.72),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.strongText,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller.inputController,
                  builder: (context, value, _) {
                    final hasText = value.text.trim().isNotEmpty;
                    return SizedBox(
                      width: 46,
                      height: 46,
                      child: FilledButton(
                        onPressed: !canSend || busy
                            ? null
                            : hasText
                            ? () => _send(context)
                            : () => _toggleVoice(context),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),
                        child: busy
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.1,
                                  color: AppColors.white,
                                ),
                              )
                            : Icon(
                                hasText
                                    ? Icons.send_rounded
                                    : recording
                                    ? Icons.stop_rounded
                                    : Icons.mic_none_rounded,
                                size: 20,
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Future<void> _openAttachmentMenu(BuildContext context) async {
    final palette = _GroupChatPalette.of(context);
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.mutedText.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppTranslations.composeMessage.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.strongText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AttachmentMenuAction(
                          icon: Icons.photo_library_outlined,
                          label: AppTranslations.commonImage.tr,
                          color: const Color(0xFF4F8CFF),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _sendPhoto(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AttachmentMenuAction(
                          icon: Icons.videocam_outlined,
                          label: AppTranslations.commonVideo.tr,
                          color: const Color(0xFFFF7A45),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _sendVideo(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AttachmentMenuAction(
                          icon: Icons.audio_file_outlined,
                          label: AppTranslations.groupsVoice.tr,
                          color: const Color(0xFF22B8B2),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _sendAudio(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AttachmentMenuAction(
                          icon: Icons.attach_file_rounded,
                          label: AppTranslations.chatInfoFiles.tr,
                          color: const Color(0xFF6C7BFF),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _sendFile(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _send(BuildContext context) async {
    try {
      await controller.sendTextMessage();
    } catch (_) {
      _showSendError();
    }
  }

  Future<void> _sendPhoto(BuildContext context) async {
    try {
      await controller.pickAndSendPhoto();
    } catch (_) {
      _showSendError();
    }
  }

  Future<void> _sendVideo(BuildContext context) async {
    try {
      await controller.pickAndSendVideo();
    } catch (_) {
      _showSendError();
    }
  }

  Future<void> _sendFile(BuildContext context) async {
    try {
      await controller.pickAndSendFile();
    } catch (_) {
      _showSendError();
    }
  }

  Future<void> _sendAudio(BuildContext context) async {
    try {
      await controller.pickAndSendAudio();
    } catch (_) {
      _showSendError();
    }
  }

  Future<void> _toggleVoice(BuildContext context) async {
    try {
      await controller.toggleVoiceRecording();
    } catch (_) {
      _showSendError();
    }
  }

  void _showSendError() {
    final message = controller.errorMessage.value.trim();
    Get.snackbar(
      AppTranslations.groupChatUnableToSend.tr,
      message.isEmpty ? AppTranslations.groupChatUnableToSend.tr : message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class _AttachmentMenuAction extends StatelessWidget {
  const _AttachmentMenuAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _GroupChatPalette.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: palette.softSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.sectionBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.strongText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerToolButton extends StatelessWidget {
  const _ComposerToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _GroupChatPalette.of(context);
    final color = AppColors.primary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: onTap == null
                  ? palette.softSurface.withValues(alpha: 0.58)
                  : color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: onTap == null ? palette.mutedText : color,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({
    required this.imageUrl,
    required this.name,
    required this.radius,
  });

  final String imageUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final initials = _buildInitials(name);

    if (imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          errorWidget: (_, _, _) =>
              _AvatarFallback(initials: initials, size: size),
        ),
      );
    }

    return _AvatarFallback(initials: initials, size: size);
  }

  String _buildInitials(String value) {
    final parts = value
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'G';
    }
    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: MessengerDesign.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GroupChatPalette {
  const _GroupChatPalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.softSurface,
    required this.strongText,
    required this.mutedText,
    required this.messageMetaText,
    required this.incomingBubble,
    required this.outgoingBubble,
    required this.outgoingText,
    required this.sectionBorder,
    required this.shadowColor,
  });

  final Color pageBackground;
  final Color cardBackground;
  final Color softSurface;
  final Color strongText;
  final Color mutedText;
  final Color messageMetaText;
  final Color incomingBubble;
  final Color outgoingBubble;
  final Color outgoingText;
  final Color sectionBorder;
  final Color shadowColor;

  static _GroupChatPalette of(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return _GroupChatPalette(
      pageBackground: palette.canvas,
      cardBackground: palette.surface,
      softSurface: palette.field,
      strongText: palette.text,
      mutedText: palette.muted,
      messageMetaText: palette.muted,
      incomingBubble: palette.softSurface,
      outgoingBubble: MessengerDesign.primary,
      outgoingText: Colors.white,
      sectionBorder: palette.divider,
      shadowColor: Colors.transparent,
    );
  }
}

TextDirection _resolvedTextDirection(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return TextDirection.ltr;
  }
  final rtlRegex = RegExp(r'[\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC]');
  return rtlRegex.hasMatch(trimmed) ? TextDirection.rtl : TextDirection.ltr;
}
