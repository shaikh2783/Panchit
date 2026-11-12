import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../data/models/chat_contacts_response.dart';
import '../../data/models/chat_conversation_details.dart';
import '../../data/models/chat_conversations_response.dart';
import '../../data/services/chat_service.dart';
import 'chat_conversation_page.dart';

class ForwardMessagePickerPage extends StatefulWidget {
  const ForwardMessagePickerPage({super.key, required this.sourceMessage});

  final ChatMessageModel sourceMessage;

  @override
  State<ForwardMessagePickerPage> createState() =>
      _ForwardMessagePickerPageState();
}

class _ForwardMessagePickerPageState extends State<ForwardMessagePickerPage> {
  final TextEditingController _searchController = TextEditingController();

  ChatContactsResponse? _contactsResponse;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';

  HomeController get _homeController => Get.find<HomeController>();
  ChatService get _chatService => Get.find<ChatService>();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
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

  Future<void> _forwardToConversation(
    ChatConversationModel conversation,
  ) async {
    await _forwardMessage(
      conversationId: int.tryParse(conversation.id),
      recipients: null,
      fallbackConversation: conversation,
    );
  }

  Future<void> _forwardToContact(ChatContactModel contact) async {
    final conversationId = contact.conversationId > 0
        ? contact.conversationId
        : null;
    await _forwardMessage(
      conversationId: conversationId,
      recipients: conversationId == null ? <int>[contact.id] : null,
      fallbackConversation: ChatConversationModel(
        id: '${conversationId ?? 0}',
        title: contact.title,
        preview: widget.sourceMessage.previewText,
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

  Future<void> _forwardMessage({
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
      final result = await _chatService.forwardMessage(
        sourceMessageId: widget.sourceMessage.id,
        conversationId: conversationId,
        recipients: recipients,
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

      Get.snackbar(
        AppTranslations.forwardTitle.tr,
        AppTranslations.forwardSent.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.off<void>(
        () => ChatConversationPage(
          key: ValueKey(
            'forwarded-chat-${resolvedConversation.id}-${resolvedConversation.targetUserId}',
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
    final conversations = _filteredConversations;
    final contacts = _filteredContacts;
    final hasTargets = conversations.isNotEmpty || contacts.isNotEmpty;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: MessengerAppBar(title: AppTranslations.forwardTitle.tr),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _ForwardPreviewCard(message: widget.sourceMessage),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: MessengerSearchField(
                controller: _searchController,
                hintText: AppTranslations.forwardSearchHint.tr,
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
                      title: AppTranslations.forwardTitle.tr,
                      message: _errorMessage,
                      actionLabel: AppTranslations.retry.tr,
                      onAction: _load,
                    )
                  : !hasTargets
                  ? MessengerEmptyState(
                      icon: Icons.person_search_outlined,
                      title: AppTranslations.forwardEmptyTargets.tr,
                      message: AppTranslations.forwardSearchHint.tr,
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
                                  onTap: () => _forwardToConversation(item),
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
                                  onTap: () => _forwardToContact(item),
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

class _ForwardPreviewCard extends StatelessWidget {
  const _ForwardPreviewCard({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(MessengerDesign.controlRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.forward_rounded, color: MessengerDesign.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.forwardPreviewTitle.tr,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: MessengerDesign.primary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message.previewText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (message.senderName.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message.senderName,
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
    return MessengerSection(
      title: title,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++)
            _TargetTileShell(
              showDivider: index != children.length - 1,
              child: children[index],
            ),
        ],
      ),
    );
  }
}

class _TargetTileShell extends StatelessWidget {
  const _TargetTileShell({required this.showDivider, required this.child});

  final bool showDivider;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return DecoratedBox(
      decoration: showDivider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.divider)),
            )
          : const BoxDecoration(),
      child: child,
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
