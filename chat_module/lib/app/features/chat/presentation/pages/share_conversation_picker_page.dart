import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../data/models/chat_contacts_response.dart';
import '../../data/models/chat_conversations_response.dart';
import '../../data/models/chat_shared_draft.dart';
import '../../data/services/chat_service.dart';
import 'chat_conversation_page.dart';

class ShareConversationPickerPage extends StatefulWidget {
  const ShareConversationPickerPage({
    super.key,
    required this.shareDraft,
    this.preferredUserId,
  });

  final ChatSharedDraftModel shareDraft;
  final int? preferredUserId;

  @override
  State<ShareConversationPickerPage> createState() =>
      _ShareConversationPickerPageState();
}

class _ShareConversationPickerPageState
    extends State<ShareConversationPickerPage> {
  final TextEditingController _searchController = TextEditingController();

  ChatContactsResponse? _contactsResponse;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';
  bool _didAutoSend = false;

  HomeController get _homeController => Get.find<HomeController>();
  ChatService get _chatService => Get.find<ChatService>();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_rebuild);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _homeController.load(ignoreSearch: true);
      final contacts = await _chatService.fetchContacts();
      if (!mounted) {
        return;
      }
      setState(() {
        _contactsResponse = contacts;
        _isLoading = false;
      });
      await _maybeAutoSendToPreferredUser();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _cleanError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _maybeAutoSendToPreferredUser() async {
    final preferredUserId = widget.preferredUserId ?? 0;
    if (_didAutoSend || preferredUserId <= 0 || !mounted) {
      return;
    }
    _didAutoSend = true;

    ChatConversationModel? existingConversation;
    for (final item in _homeController.conversations) {
      if (item.targetUserId == preferredUserId) {
        existingConversation = item;
        break;
      }
    }
    if (existingConversation != null) {
      await _sendToConversation(existingConversation);
      return;
    }

    ChatContactModel? contact;
    for (final item
        in _contactsResponse?.contacts ?? const <ChatContactModel>[]) {
      if (item.id == preferredUserId) {
        contact = item;
        break;
      }
    }

    if (contact != null && !contact.canMessage) {
      setState(() {
        _errorMessage = AppTranslations.composeCannotMessage.tr;
      });
      return;
    }

    final contactConversationId = contact != null && contact.conversationId > 0
        ? contact.conversationId
        : null;

    final fallbackConversation = ChatConversationModel(
      id: '${contactConversationId ?? 0}',
      title: contact?.title ?? AppTranslations.commonConversation.tr,
      preview: widget.shareDraft.title.trim(),
      timeLabel: '',
      avatarUrl: contact?.avatarUrl ?? '',
      isOnline: contact?.isOnline ?? false,
      isTyping: false,
      unreadCount: 0,
      isSeen: true,
      isPinned: false,
      isMuted: false,
      targetUserId: preferredUserId,
    );

    await _sendShare(
      conversationId: contactConversationId,
      recipients: contactConversationId == null ? <int>[preferredUserId] : null,
      fallbackConversation: fallbackConversation,
    );
  }

  List<ChatConversationModel> get _filteredConversations {
    final query = _searchController.text.trim().toLowerCase();
    final items = _homeController.conversations.toList(growable: false);
    if (query.isEmpty) {
      return items;
    }
    return items
        .where(
          (item) =>
              item.title.toLowerCase().contains(query) ||
              item.preview.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  List<ChatContactModel> get _filteredContacts {
    final query = _searchController.text.trim().toLowerCase();
    final items = _contactsResponse?.contacts ?? const <ChatContactModel>[];
    final existingConversationIds = _homeController.conversations
        .map((item) => int.tryParse(item.id) ?? 0)
        .where((item) => item > 0)
        .toSet();
    return items
        .where((item) {
          if (!item.canMessage ||
              (item.conversationId > 0 &&
                  existingConversationIds.contains(item.conversationId))) {
            return false;
          }
          return query.isEmpty ||
              item.title.toLowerCase().contains(query) ||
              item.userName.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _sendToConversation(ChatConversationModel conversation) async {
    await _sendShare(
      conversationId: int.tryParse(conversation.id),
      recipients: null,
      fallbackConversation: conversation,
    );
  }

  Future<void> _sendToContact(ChatContactModel contact) async {
    if (!contact.canMessage) {
      return;
    }
    final conversationId = contact.conversationId > 0
        ? contact.conversationId
        : null;
    await _sendShare(
      conversationId: conversationId,
      recipients: conversationId == null ? <int>[contact.id] : null,
      fallbackConversation: ChatConversationModel(
        id: '${conversationId ?? 0}',
        title: contact.title,
        preview: widget.shareDraft.title,
        timeLabel: '',
        avatarUrl: contact.avatarUrl,
        isOnline: contact.isOnline,
        isTyping: false,
        unreadCount: 0,
        isSeen: true,
        isPinned: false,
        isMuted: false,
        targetUserId: contact.id,
      ),
    );
  }

  Future<void> _sendShare({
    required int? conversationId,
    required List<int>? recipients,
    required ChatConversationModel fallbackConversation,
  }) async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      final result = await _chatService.sendMessage(
        conversationId: conversationId,
        recipients: recipients,
        message: widget.shareDraft.draftMessage,
        messageType: widget.shareDraft.messageType,
        postId: widget.shareDraft.postId > 0 ? widget.shareDraft.postId : null,
        reelId: widget.shareDraft.reelId > 0 ? widget.shareDraft.reelId : null,
        productPostId: widget.shareDraft.productPostId > 0
            ? widget.shareDraft.productPostId
            : null,
      );
      await _homeController.load(ignoreSearch: true);
      if (!mounted) {
        return;
      }

      var resolvedConversation = fallbackConversation;
      final resolvedConversationId = result.conversationId;
      if (resolvedConversationId > 0) {
        final matchIndex = _homeController.conversations.indexWhere(
          (item) => item.id == '$resolvedConversationId',
        );
        resolvedConversation = matchIndex != -1
            ? _homeController.conversations[matchIndex]
            : fallbackConversation.copyWith(
                id: '$resolvedConversationId',
                preview:
                    result.lastMessage?.previewText ??
                    fallbackConversation.preview,
                timeLabel:
                    result.lastMessage?.timeLabel ??
                    fallbackConversation.timeLabel,
              );
      }

      // Replace only this picker. The previous implementation used offAll and
      // unexpectedly erased the user's entire navigation history.
      Get.off<void>(
        () => ChatConversationPage(
          key: ValueKey(
            'shared-chat-${resolvedConversation.id}-${resolvedConversation.targetUserId}',
          ),
          conversation: resolvedConversation,
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _cleanError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final draft = widget.shareDraft;
    final conversations = _filteredConversations;
    final contacts = _filteredContacts;
    final hasTargets = conversations.isNotEmpty || contacts.isNotEmpty;
    final pageTitle = draft.isProductShare
        ? AppTranslations.commonProduct.tr
        : draft.isSharedReel
        ? AppTranslations.shareReelTitle.tr
        : AppTranslations.sharePostTitle.tr;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: MessengerAppBar(title: pageTitle),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _SharePreviewCard(draft: draft),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: MessengerSearchField(
                controller: _searchController,
                hintText: AppTranslations.shareSearchHint.tr,
                onClear: _searchController.clear,
              ),
            ),
            if (_isSubmitting) const LinearProgressIndicator(minHeight: 2),
            if (_errorMessage.isNotEmpty && hasTargets)
              _InlinePickerError(message: _errorMessage),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty && !hasTargets
                  ? MessengerEmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: pageTitle,
                      message: _errorMessage,
                      actionLabel: AppTranslations.retry.tr,
                      onAction: _load,
                    )
                  : !hasTargets
                  ? MessengerEmptyState(
                      icon: Icons.person_search_outlined,
                      title: AppTranslations.shareEmptyTargets.tr,
                      message: AppTranslations.shareSearchHint.tr,
                    )
                  : ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        if (conversations.isNotEmpty)
                          _TargetSection(
                            title: AppTranslations.commonConversations.tr,
                            children: [
                              for (final item in conversations)
                                _TargetTile(
                                  title: item.title.isEmpty
                                      ? AppTranslations.commonConversation.tr
                                      : item.title,
                                  subtitle: item.preview,
                                  avatarUrl: item.avatarUrl,
                                  online: item.isOnline,
                                  icon: Icons.chat_bubble_outline_rounded,
                                  enabled: !_isSubmitting,
                                  onTap: () => _sendToConversation(item),
                                ),
                            ],
                          ),
                        if (conversations.isNotEmpty && contacts.isNotEmpty)
                          const SizedBox(height: 18),
                        if (contacts.isNotEmpty)
                          _TargetSection(
                            title: AppTranslations.commonPeople.tr,
                            children: [
                              for (final item in contacts)
                                _TargetTile(
                                  title: item.title,
                                  subtitle: item.isOnline
                                      ? AppTranslations.chatOnlineNow.tr
                                      : item.lastSeen,
                                  avatarUrl: item.avatarUrl,
                                  online: item.isOnline,
                                  icon: Icons.person_outline_rounded,
                                  enabled: !_isSubmitting,
                                  onTap: () => _sendToContact(item),
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}

class _SharePreviewCard extends StatelessWidget {
  const _SharePreviewCard({required this.draft});

  final ChatSharedDraftModel draft;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final fallbackIcon = draft.isProductShare
        ? Icons.shopping_bag_outlined
        : draft.isSharedReel
        ? Icons.movie_creation_outlined
        : Icons.article_outlined;
    final fallbackTitle = draft.isProductShare
        ? AppTranslations.commonProduct.tr
        : draft.isSharedReel
        ? AppTranslations.commonReel.tr
        : AppTranslations.commonPost.tr;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(MessengerDesign.controlRadius),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(MessengerDesign.compactRadius),
            child: SizedBox(
              width: 58,
              height: 58,
              child: draft.thumbnail.trim().isEmpty
                  ? ColoredBox(
                      color: palette.softSurface,
                      child: Icon(fallbackIcon, color: MessengerDesign.primary),
                    )
                  : Image.network(
                      draft.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: palette.softSurface,
                        child: Icon(
                          fallbackIcon,
                          color: MessengerDesign.primary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.isProductShare
                      ? AppTranslations.commonProduct.tr
                      : draft.isSharedReel
                      ? AppTranslations.sharedReel.tr
                      : AppTranslations.sharedPost.tr,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: MessengerDesign.primary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  draft.title.trim().isEmpty ? fallbackTitle : draft.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (draft.authorName.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    draft.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetSection extends StatelessWidget {
  const _TargetSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return MessengerSection(
      title: title,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++)
            DecoratedBox(
              decoration: index != children.length - 1
                  ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: palette.divider),
                      ),
                    )
                  : const BoxDecoration(),
              child: children[index],
            ),
        ],
      ),
    );
  }
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({
    required this.title,
    required this.subtitle,
    required this.avatarUrl,
    required this.online,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String avatarUrl;
  final bool online;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MessengerRow(
      title: title,
      subtitle: subtitle,
      leading: MessengerAvatar(
        name: title,
        imageUrl: avatarUrl,
        online: online,
        radius: 23,
      ),
      trailing: Icon(icon, color: MessengerDesign.primary, size: 20),
      enabled: enabled,
      onTap: onTap,
    );
  }
}

class _InlinePickerError extends StatelessWidget {
  const _InlinePickerError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: MessengerDesign.destructive,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MessengerDesign.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
