import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../../data/models/chat_backgrounds_response.dart';
import '../../data/models/chat_report_models.dart';
import '../../data/models/chat_shared_content.dart';
import '../../data/services/chat_service.dart';
import '../controllers/conversation_details_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';

String _chatInitials(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed[0];
}

class ConversationDetailsPage extends StatefulWidget {
  const ConversationDetailsPage({
    super.key,
    required this.conversationId,
    required this.title,
    required this.avatarUrl,
    required this.targetUserId,
    required this.nodeId,
    required this.nodeType,
    required this.nodeLink,
    required this.isDirectConversation,
    required this.initialIsPinned,
    required this.initialIsMuted,
    required this.initialBlockedByMe,
    required this.initialBlockedByRecipient,
    this.chatControllerTag,
  });

  final int conversationId;
  final String title;
  final String avatarUrl;
  final int targetUserId;
  final int nodeId;
  final String nodeType;
  final String nodeLink;
  final bool isDirectConversation;
  final bool initialIsPinned;
  final bool initialIsMuted;
  final bool initialBlockedByMe;
  final bool initialBlockedByRecipient;
  final String? chatControllerTag;

  @override
  State<ConversationDetailsPage> createState() =>
      _ConversationDetailsPageState();
}

class _ConversationDetailsPageState extends State<ConversationDetailsPage> {
  late final String _tag;
  late final ConversationDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _tag = 'conversation-details-${widget.conversationId}';
    _controller = Get.put(
      ConversationDetailsController(
        chatService: Get.find<ChatService>(),
        conversationId: widget.conversationId,
        titleText: widget.title,
        avatar: widget.avatarUrl,
        targetUserId: widget.targetUserId,
        nodeId: widget.nodeId,
        nodeType: widget.nodeType,
        nodeLink: widget.nodeLink,
        isDirectConversation: widget.isDirectConversation,
        initialIsPinned: widget.initialIsPinned,
        initialIsMuted: widget.initialIsMuted,
        initialBlockedByMe: widget.initialBlockedByMe,
        initialBlockedByRecipient: widget.initialBlockedByRecipient,
        chatControllerTag: widget.chatControllerTag,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<ConversationDetailsController>(tag: _tag, force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final background = palette.groupedCanvas;
    final cardColor = palette.surface;
    final strongText = palette.text;
    final mutedText = palette.muted;

    return Scaffold(
      backgroundColor: background,
      appBar: MessengerAppBar(title: AppTranslations.chatInfoTitle.tr),
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 160) {
              _controller.loadMore();
            }
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _HeaderCard(
                controller: _controller,
                title: widget.title,
                avatarUrl: widget.avatarUrl,
                cardColor: cardColor,
                strongText: strongText,
                mutedText: mutedText,
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: AppTranslations.chatInfoSettings.tr,
                strongText: strongText,
              ),
              const SizedBox(height: 10),
              _SettingsCard(
                controller: _controller,
                cardColor: cardColor,
                strongText: strongText,
                mutedText: mutedText,
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: AppTranslations.chatInfoSharedMedia.tr,
                strongText: strongText,
              ),
              const SizedBox(height: 10),
              _FilterStrip(
                controller: _controller,
                strongText: strongText,
                mutedText: mutedText,
                cardColor: cardColor,
              ),
              const SizedBox(height: 12),
              _SharedContentCard(
                controller: _controller,
                cardColor: cardColor,
                strongText: strongText,
                mutedText: mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.controller,
    required this.title,
    required this.avatarUrl,
    required this.cardColor,
    required this.strongText,
    required this.mutedText,
  });

  final ConversationDetailsController controller;
  final String title;
  final String avatarUrl;
  final Color cardColor;
  final Color strongText;
  final Color mutedText;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Obx(() {
      final counts = controller.counts.value;
      final canOpenTimelineTarget = controller.canOpenTimelineTarget;
      final avatar = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: palette.divider),
        ),
        child: CircleAvatar(
          radius: 40,
          backgroundColor: palette.primarySoft,
          backgroundImage: avatarUrl.trim().isEmpty
              ? null
              : NetworkImage(avatarUrl),
          child: avatarUrl.trim().isEmpty
              ? Text(
                  _chatInitials(title),
                  style: TextStyle(
                    color: MessengerDesign.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                  ),
                )
              : null,
        ),
      );
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(MessengerDesign.sectionRadius),
          border: Border.all(color: palette.divider, width: 0.7),
        ),
        child: Column(
          children: [
            if (canOpenTimelineTarget)
              GestureDetector(
                onTap: controller.openTimelineTarget,
                child: avatar,
              )
            else
              avatar,
            const SizedBox(height: 16),
            Text(
              title.isEmpty ? AppTranslations.commonConversation.tr : title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: strongText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppTranslations.chatInfoSharedMedia.tr,
              style: TextStyle(
                color: mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _HeaderMetricChip(
                  label: AppTranslations.chatInfoImages.tr,
                  value: counts.images,
                ),
                _HeaderMetricChip(
                  label: AppTranslations.chatInfoVideos.tr,
                  value: counts.videos,
                ),
                _HeaderMetricChip(
                  label: AppTranslations.chatInfoAudio.tr,
                  value: counts.audio,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(
                  icon: controller.isPinned.value
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  label: AppTranslations.chatSettingPin.tr,
                  active: controller.isPinned.value,
                ),
                _StatusPill(
                  icon: controller.isMuted.value
                      ? Icons.notifications_off_rounded
                      : Icons.notifications_active_outlined,
                  label: AppTranslations.chatSettingMute.tr,
                  active: controller.isMuted.value,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _HeaderMetricChip extends StatelessWidget {
  const _HeaderMetricChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.softSurface,
        borderRadius: BorderRadius.circular(MessengerDesign.compactRadius),
        border: Border.all(color: palette.divider, width: 0.7),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: palette.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: active ? palette.primarySoft : palette.softSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? MessengerDesign.primary : palette.divider,
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? MessengerDesign.primary : palette.muted,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? MessengerDesign.primary : palette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.strongText});

  final String title;
  final Color strongText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          color: strongText,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.controller,
    required this.strongText,
    required this.mutedText,
    required this.cardColor,
  });

  final ConversationDetailsController controller;
  final Color strongText;
  final Color mutedText;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final filters = <String>['all', 'image', 'video', 'audio', 'file', 'link'];

    return Obx(() {
      final selectedType = controller.selectedType.value;
      final counts = controller.counts.value;

      return SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final selected = selectedType == filter;
            final count = counts.countFor(filter);
            return GestureDetector(
              onTap: () => controller.selectType(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : mutedText.withValues(alpha: 0.12),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.labelForType(filter),
                      style: TextStyle(
                        color: selected ? AppColors.white : strongText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.white.withValues(alpha: 0.16)
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: selected ? AppColors.white : AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemCount: filters.length,
        ),
      );
    });
  }
}

class _SharedContentCard extends StatelessWidget {
  const _SharedContentCard({
    required this.controller,
    required this.cardColor,
    required this.strongText,
    required this.mutedText,
  });

  final ConversationDetailsController controller;
  final Color cardColor;
  final Color strongText;
  final Color mutedText;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          height: 220,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(MessengerDesign.sectionRadius),
            border: Border.all(color: palette.divider, width: 0.7),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.errorMessage.value.isNotEmpty &&
          controller.items.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(MessengerDesign.sectionRadius),
            border: Border.all(color: palette.divider, width: 0.7),
          ),
          child: Column(
            children: [
              Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(color: strongText),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: controller.load,
                child: Text(AppTranslations.retry.tr),
              ),
            ],
          ),
        );
      }

      final visibleItems = controller.visibleItems;
      if (visibleItems.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(MessengerDesign.sectionRadius),
            border: Border.all(color: palette.divider, width: 0.7),
          ),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.perm_media_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppTranslations.chatInfoNoSharedMedia.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: strongText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppTranslations.chatInfoSharedMedia.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedText),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(MessengerDesign.sectionRadius),
          border: Border.all(color: palette.divider, width: 0.7),
        ),
        child: Column(
          children: [
            for (final item in visibleItems) ...[
              _SharedItemTile(
                cardColor: cardColor,
                item: item,
                strongText: strongText,
                mutedText: mutedText,
                onTap: () => controller.openSharedItem(item),
              ),
              if (item != visibleItems.last) const SizedBox(height: 12),
            ],
            if (controller.isLoadingMore.value) ...[
              const SizedBox(height: 12),
              const CircularProgressIndicator(strokeWidth: 2.2),
            ],
          ],
        ),
      );
    });
  }
}

class _SharedItemTile extends StatelessWidget {
  const _SharedItemTile({
    required this.cardColor,
    required this.item,
    required this.strongText,
    required this.mutedText,
    required this.onTap,
  });

  final Color cardColor;
  final ChatSharedItemModel item;
  final Color strongText;
  final Color mutedText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String preview = item.message.trim().isNotEmpty
        ? item.message
        : item.title.trim().isNotEmpty
        ? item.title
        : item.bestUrl;
    final sender = item.sender?.fullName.trim() ?? '';
    final hasThumb =
        item.thumbnail.trim().isNotEmpty &&
        Uri.tryParse(item.thumbnail)?.hasAbsolutePath == true;
    final senderHasAvatar =
        (item.sender?.picture.trim().isNotEmpty ?? false) &&
        Uri.tryParse(item.sender!.picture)?.hasAbsolutePath == true;
    final accentColor = _accentForType(item.type);
    final opensInternally = item.isImage || item.isVideo || item.isAudio;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MessengerDesign.compactRadius),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(MessengerDesign.compactRadius),
            border: Border.all(color: mutedText.withValues(alpha: 0.10)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  image: hasThumb
                      ? DecorationImage(
                          image: NetworkImage(item.thumbnail),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: hasThumb
                    ? null
                    : Icon(
                        _iconForType(item.type),
                        color: accentColor,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _labelForType(context, item.type),
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.timeAgo.isNotEmpty
                              ? item.timeAgo
                              : item.createdAt,
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: strongText,
                        fontSize: 14,
                        fontWeight: preview == item.bestUrl
                            ? FontWeight.w600
                            : FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (sender.isNotEmpty) ...[
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: accentColor.withValues(
                              alpha: 0.10,
                            ),
                            backgroundImage: senderHasAvatar
                                ? NetworkImage(item.sender!.picture)
                                : null,
                            child: senderHasAvatar
                                ? null
                                : Text(
                                    sender.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sender,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else
                          Expanded(
                            child: Text(
                              item.createdAt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(width: 10),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: opensInternally
                                ? accentColor.withValues(alpha: 0.12)
                                : cardColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            opensInternally
                                ? _actionIconForType(item.type)
                                : Icons.open_in_new_rounded,
                            size: 16,
                            color: opensInternally ? accentColor : mutedText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelForType(BuildContext context, String type) {
    switch (type) {
      case 'image':
        return AppTranslations.chatInfoImages.tr;
      case 'video':
        return AppTranslations.chatInfoVideos.tr;
      case 'audio':
        return AppTranslations.chatInfoAudio.tr;
      case 'file':
        return AppTranslations.chatInfoFiles.tr;
      case 'link':
        return AppTranslations.chatInfoLinks.tr;
      case 'post':
        return AppTranslations.commonPost.tr;
      case 'reel':
        return AppTranslations.commonReel.tr;
      default:
        return AppTranslations.chatInfoSharedMedia.tr;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'audio':
        return Icons.graphic_eq_rounded;
      case 'file':
        return Icons.insert_drive_file_outlined;
      case 'link':
        return Icons.link_rounded;
      case 'post':
        return Icons.article_outlined;
      case 'reel':
        return Icons.movie_creation_outlined;
      default:
        return Icons.attach_file_rounded;
    }
  }

  IconData _actionIconForType(String type) {
    switch (type) {
      case 'video':
        return Icons.play_arrow_rounded;
      case 'audio':
        return Icons.headphones_rounded;
      case 'image':
        return Icons.fullscreen_rounded;
      default:
        return Icons.chevron_right_rounded;
    }
  }

  Color _accentForType(String type) {
    switch (type) {
      case 'video':
        return const Color(0xFF7C3AED);
      case 'audio':
        return const Color(0xFFF59E0B);
      case 'file':
        return const Color(0xFF10B981);
      case 'link':
        return const Color(0xFFEF4444);
      case 'post':
        return const Color(0xFF2563EB);
      case 'reel':
        return const Color(0xFFEC4899);
      default:
        return AppColors.primary;
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.controller,
    required this.cardColor,
    required this.strongText,
    required this.mutedText,
  });

  final ConversationDetailsController controller;
  final Color cardColor;
  final Color strongText;
  final Color mutedText;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final borderRadius = BorderRadius.circular(MessengerDesign.sectionRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: palette.divider, width: 0.7),
      ),
      child: Material(
        color: cardColor,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingTile(
                icon: Icons.wallpaper_outlined,
                iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                iconColor: AppColors.primary,
                title: AppTranslations.chatSettingBackground.tr,
                subtitle: controller.backgroundSummary,
                strongText: strongText,
                mutedText: mutedText,
                onTap: () => _showBackgroundPicker(context),
              ),
              _SettingDivider(mutedText: mutedText),
              _SettingTile(
                icon: Icons.notifications_off_outlined,
                iconBgColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                iconColor: const Color(0xFFF59E0B),
                title: AppTranslations.chatSettingMute.tr,
                subtitle: '',
                strongText: strongText,
                mutedText: mutedText,
                trailing: Obx(
                  () => Switch(
                    value: controller.isMuted.value,
                    onChanged: (_) => _toggleMuted(context),
                  ),
                ),
                showChevron: false,
                onTap: () => _toggleMuted(context),
              ),
              _SettingDivider(mutedText: mutedText),
              _SettingTile(
                icon: Icons.push_pin_outlined,
                iconBgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                iconColor: const Color(0xFF10B981),
                title: AppTranslations.chatSettingPin.tr,
                subtitle: '',
                strongText: strongText,
                mutedText: mutedText,
                trailing: Obx(
                  () => Switch(
                    value: controller.isPinned.value,
                    onChanged: (_) => _togglePinned(context),
                  ),
                ),
                showChevron: false,
                onTap: () => _togglePinned(context),
              ),
              if (controller.isDirectConversation) ...[
                _SettingDivider(mutedText: mutedText),
                Obx(
                  () => _SettingTile(
                    icon: controller.isBlockedByMe.value
                        ? Icons.lock_open_rounded
                        : Icons.block_outlined,
                    iconBgColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    iconColor: const Color(0xFFEF4444),
                    title: controller.isBlockedByMe.value
                        ? AppTranslations.blockedUsersUnblock.tr
                        : AppTranslations.chatSettingBlock.tr,
                    subtitle: '',
                    strongText: strongText,
                    mutedText: mutedText,
                    showChevron: false,
                    onTap: () => _confirmBlockToggle(context),
                  ),
                ),
                _SettingDivider(mutedText: mutedText),
                _SettingTile(
                  icon: Icons.flag_outlined,
                  iconBgColor: const Color(0xFFF97316).withValues(alpha: 0.1),
                  iconColor: const Color(0xFFF97316),
                  title: AppTranslations.chatSettingReport.tr,
                  subtitle: AppTranslations.chatSettingReportSubtitle.tr,
                  strongText: strongText,
                  mutedText: mutedText,
                  onTap: () => _showReportSheet(context),
                ),
              ],
              _SettingDivider(mutedText: mutedText),
              Obx(
                () => _SettingTile(
                  icon: Icons.delete_outline_rounded,
                  iconBgColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  iconColor: const Color(0xFFEF4444),
                  title: AppTranslations.chatSettingDelete.tr,
                  subtitle: controller.isDeleting.value
                      ? AppTranslations.loading.tr
                      : '',
                  strongText: const Color(0xFFE05454),
                  mutedText: mutedText,
                  showChevron: false,
                  onTap: controller.isDeleting.value
                      ? null
                      : () => _confirmDelete(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePinned(BuildContext context) async {
    try {
      await controller.setPinned(!controller.isPinned.value);
    } catch (_) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _confirmBlockToggle(BuildContext context) async {
    final isBlocked = controller.isBlockedByMe.value;
    final approved =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              isBlocked
                  ? AppTranslations.blockedUsersUnblockTitle.tr
                  : AppTranslations.chatBlockConfirmTitle.tr,
            ),
            content: Text(
              isBlocked
                  ? AppTranslations.blockedUsersUnblockMessage.tr
                  : AppTranslations.chatBlockConfirmMessage.tr,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(AppTranslations.settingsLogoutCancel.tr),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  isBlocked
                      ? AppTranslations.blockedUsersUnblock.tr
                      : AppTranslations.chatBlockConfirmAction.tr,
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!approved) {
      return;
    }

    try {
      final message = await controller.toggleBlockCurrentUser();
      Get.snackbar(
        isBlocked
            ? AppTranslations.blockedUsersUserUnblocked.tr
            : AppTranslations.chatUserBlocked.tr,
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        AppTranslations.chatInfoSettings.tr,
        controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _showBackgroundPicker(BuildContext context) async {
    try {
      await controller.loadBackgroundOptions();
    } catch (_) {
      if (controller.errorMessage.value.isNotEmpty) {
        Get.snackbar(
          AppTranslations.loginFailed.tr,
          controller.errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }
    if (!context.mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BackgroundPickerSheet(controller: controller),
    );
  }

  Future<void> _showReportSheet(BuildContext context) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportUserSheet(controller: controller),
    );
    if (message == null || message.isEmpty) {
      return;
    }
    Get.snackbar(
      AppTranslations.chatReportSuccess.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _toggleMuted(BuildContext context) async {
    try {
      await controller.setMuted(!controller.isMuted.value);
    } catch (_) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(AppTranslations.chatDeleteTitle.tr),
              content: Text(AppTranslations.chatDeleteMessage.tr),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(AppTranslations.chatDeleteConfirm.tr),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    final deleted = await controller.deleteConversation();
    if (!context.mounted) {
      return;
    }
    if (deleted) {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.removeConversationById(controller.conversationId);
        homeController.selectTab(0);
      }
      Get.until((route) => route.isFirst);
      Get.snackbar(
        AppTranslations.chatInfoTitle.tr,
        AppTranslations.chatDeleted.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (controller.errorMessage.value.isNotEmpty) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _ReportUserSheet extends StatefulWidget {
  const _ReportUserSheet({required this.controller});

  final ConversationDetailsController controller;

  @override
  State<_ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<_ReportUserSheet> {
  final TextEditingController _reasonController = TextEditingController();
  final List<ChatReportCategoryModel> _categories = <ChatReportCategoryModel>[];

  int? _selectedCategoryId;
  bool _isLoading = true;
  String _errorMessage = '';

  ConversationDetailsController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final categories = await controller.fetchReportCategories();
      if (!mounted) {
        return;
      }
      setState(() {
        _categories
          ..clear()
          ..addAll(categories);
        _selectedCategoryId = categories.isNotEmpty
            ? categories.first.id
            : null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = controller.errorMessage.value.isNotEmpty
            ? controller.errorMessage.value
            : AppTranslations.chatReportLoadFailed.tr;
      });
    }
  }

  Future<void> _submit() async {
    final categoryId = _selectedCategoryId;
    if (categoryId == null || categoryId <= 0) {
      Get.snackbar(
        AppTranslations.chatReportTitle.tr,
        AppTranslations.chatReportCategoryRequired.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final message = await controller.reportCurrentUser(
        categoryId: categoryId,
        reason: _reasonController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(message);
    } catch (_) {
      Get.snackbar(
        AppTranslations.chatReportTitle.tr,
        controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final strongText = isDark ? AppColors.white : AppColors.surfaceDark;
    final mutedText = isDark ? AppColors.accent : const Color(0xFF8D91AE);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2138) : AppColors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: mutedText.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.flag_outlined,
                      color: Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      AppTranslations.chatReportTitle.tr,
                      style: TextStyle(
                        color: strongText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppTranslations.chatReportDescription.tr,
                style: TextStyle(
                  color: mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage.isNotEmpty)
                _ReportSheetMessage(
                  message: _errorMessage,
                  strongText: strongText,
                  mutedText: mutedText,
                  actionLabel: AppTranslations.retry.tr,
                  onAction: _loadCategories,
                )
              else if (_categories.isEmpty)
                _ReportSheetMessage(
                  message: AppTranslations.chatReportEmptyCategories.tr,
                  strongText: strongText,
                  mutedText: mutedText,
                )
              else ...[
                Text(
                  AppTranslations.chatReportCategoryLabel.tr,
                  style: TextStyle(
                    color: strongText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    hintText: AppTranslations.chatReportCategoryHint.tr,
                    filled: true,
                    fillColor: isDark
                        ? AppColors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF6F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
                if (_selectedCategory != null &&
                    _selectedCategory!.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _selectedCategory!.description,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  AppTranslations.chatReportReasonLabel.tr,
                  style: TextStyle(
                    color: strongText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: AppTranslations.chatReportReasonHint.tr,
                    filled: true,
                    fillColor: isDark
                        ? AppColors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF6F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        MaterialLocalizations.of(context).cancelButtonLabel,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => FilledButton(
                        onPressed:
                            _isLoading ||
                                _categories.isEmpty ||
                                controller.isSubmittingReport.value
                            ? null
                            : _submit,
                        child: controller.isSubmittingReport.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(AppTranslations.chatReportSubmit.tr),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ChatReportCategoryModel? get _selectedCategory {
    final selectedCategoryId = _selectedCategoryId;
    if (selectedCategoryId == null) {
      return null;
    }
    for (final category in _categories) {
      if (category.id == selectedCategoryId) {
        return category;
      }
    }
    return null;
  }
}

class _ReportSheetMessage extends StatelessWidget {
  const _ReportSheetMessage({
    required this.message,
    required this.strongText,
    required this.mutedText,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final Color strongText;
  final Color mutedText;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: strongText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
          const SizedBox(height: 4),
          Text(
            AppTranslations.chatSettingReportSubtitle.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _SettingsOverview extends StatelessWidget {
  const _SettingsOverview({
    required this.controller,
    required this.strongText,
    required this.mutedText,
  });

  final ConversationDetailsController controller;
  final Color strongText;
  final Color mutedText;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.12),
              AppColors.primary.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.tune_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.chatInfoSettings.tr,
                        style: TextStyle(
                          color: strongText,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppTranslations.chatSettingsSubtitle.tr,
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _QuickSettingBadge(
                  icon: controller.isPinned.value
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  label: controller.isPinned.value
                      ? '${AppTranslations.chatSettingPin.tr}: ${AppTranslations.commonOn.tr}'
                      : '${AppTranslations.chatSettingPin.tr}: ${AppTranslations.commonOff.tr}',
                  active: controller.isPinned.value,
                ),
                _QuickSettingBadge(
                  icon: controller.isMuted.value
                      ? Icons.notifications_off_rounded
                      : Icons.notifications_active_outlined,
                  label: controller.isMuted.value
                      ? '${AppTranslations.chatSettingMute.tr}: ${AppTranslations.commonOn.tr}'
                      : '${AppTranslations.chatSettingMute.tr}: ${AppTranslations.commonOff.tr}',
                  active: controller.isMuted.value,
                ),
                _QuickSettingBadge(
                  icon: controller.isDirectConversation
                      ? Icons.person_outline_rounded
                      : Icons.groups_2_outlined,
                  label: controller.isDirectConversation
                      ? AppTranslations.chatDirectConversation.tr
                      : AppTranslations.chatGroupConversation.tr,
                  active: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickSettingBadge extends StatelessWidget {
  const _QuickSettingBadge({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.10)
            : AppColors.white.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.surfaceDark.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: active ? AppColors.primary : AppColors.surfaceDark,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.primary : AppColors.surfaceDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPickerSheet extends StatelessWidget {
  const _BackgroundPickerSheet({required this.controller});

  final ConversationDetailsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strongText = isDark ? AppColors.white : AppColors.surfaceDark;
    final mutedText = isDark ? AppColors.accent : const Color(0xFF8D91AE);
    final surface = isDark ? const Color(0xFF23253E) : AppColors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.58,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Obx(
            () => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: mutedText.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.chatSettingBackground.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: strongText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTranslations.chatBackgroundSubtitle.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: mutedText,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: controller.isSavingBackground.value
                            ? null
                            : () async {
                                try {
                                  await controller.applyConversationBackground(
                                    null,
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                } catch (_) {
                                  if (controller
                                      .errorMessage
                                      .value
                                      .isNotEmpty) {
                                    Get.snackbar(
                                      AppTranslations.loginFailed.tr,
                                      controller.errorMessage.value,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  }
                                }
                              },
                        child: Text(AppTranslations.commonReset.tr),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      if (controller.colorBackgrounds.isNotEmpty) ...[
                        _PickerSectionTitle(
                          title: AppTranslations.commonColors.tr,
                          strongText: strongText,
                        ),
                        const SizedBox(height: 12),
                        _BackgroundGrid(
                          items: controller.colorBackgrounds,
                          selected: controller.resolvedConversationBackground,
                          onSelect: (item) => _selectBackground(context, item),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (controller.gradientBackgrounds.isNotEmpty) ...[
                        _PickerSectionTitle(
                          title: AppTranslations.commonGradients.tr,
                          strongText: strongText,
                        ),
                        const SizedBox(height: 12),
                        _BackgroundGrid(
                          items: controller.gradientBackgrounds,
                          selected: controller.resolvedConversationBackground,
                          onSelect: (item) => _selectBackground(context, item),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (controller.imageBackgrounds.isNotEmpty) ...[
                        _PickerSectionTitle(
                          title: AppTranslations.chatInfoImages.tr,
                          strongText: strongText,
                        ),
                        const SizedBox(height: 12),
                        _BackgroundGrid(
                          items: controller.imageBackgrounds,
                          selected: controller.resolvedConversationBackground,
                          onSelect: (item) => _selectBackground(context, item),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectBackground(
    BuildContext context,
    ChatBackgroundModel item,
  ) async {
    try {
      await controller.applyConversationBackground(item);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (controller.errorMessage.value.isNotEmpty) {
        Get.snackbar(
          AppTranslations.loginFailed.tr,
          controller.errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}

class _PickerSectionTitle extends StatelessWidget {
  const _PickerSectionTitle({required this.title, required this.strongText});

  final String title;
  final Color strongText;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: strongText,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BackgroundGrid extends StatelessWidget {
  const _BackgroundGrid({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final List<ChatBackgroundModel> items;
  final ChatBackgroundModel? selected;
  final ValueChanged<ChatBackgroundModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected =
            selected?.id == item.id &&
            selected?.type == item.type &&
            selected?.value == item.value;
        return _BackgroundOptionTile(
          item: item,
          isSelected: isSelected,
          onTap: () => onSelect(item),
        );
      },
    );
  }
}

class _BackgroundOptionTile extends StatelessWidget {
  const _BackgroundOptionTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ChatBackgroundModel item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strongText = theme.brightness == Brightness.dark
        ? AppColors.white
        : AppColors.surfaceDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.08),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: item.isColor
                      ? ColoredBox(color: _parsePickerColor(item.value))
                      : item.isGradient
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _parseGradientColors(item),
                            ),
                          ),
                        )
                      : item.isSvg
                      ? SvgPicture.network(
                          item.resolvedPreview,
                          fit: BoxFit.cover,
                          placeholderBuilder: (_) => Container(
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                        )
                      : item.hasPreviewUrl
                      ? Image.network(
                          item.resolvedPreview,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                        )
                      : Container(
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.36),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  item.title.isEmpty ? item.type : item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: item.isColor ? strongText : AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.check_rounded,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parsePickerColor(String raw) {
    final value = raw.trim().replaceFirst('#', '');
    final hex = value.length == 6 ? 'FF$value' : value;
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) {
      return AppColors.primary.withValues(alpha: 0.18);
    }
    return Color(parsed);
  }

  List<Color> _parseGradientColors(ChatBackgroundModel item) {
    final parsed = item.gradientStops.map(_parsePickerColor).toList();
    if (parsed.length >= 2) {
      return parsed;
    }
    return <Color>[
      AppColors.primary,
      AppColors.primary.withValues(alpha: 0.55),
    ];
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.strongText,
    required this.mutedText,
    this.showChevron = true,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color strongText;
  final Color mutedText;
  final bool showChevron;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: strongText,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle.trim().isEmpty
          ? null
          : Text(subtitle, style: TextStyle(color: mutedText, fontSize: 12)),
      trailing:
          trailing ??
          (showChevron
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: mutedText.withValues(alpha: 0.5),
                )
              : null),
    );
  }
}

class _SettingDivider extends StatelessWidget {
  const _SettingDivider({required this.mutedText});

  final Color mutedText;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 16,
      color: mutedText.withValues(alpha: 0.16),
    );
  }
}
