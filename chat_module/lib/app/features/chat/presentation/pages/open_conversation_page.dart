import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../settings.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../../data/models/chat_conversations_response.dart';
import '../../data/models/chat_shared_draft.dart';
import '../../data/services/chat_service.dart';
import 'chat_conversation_page.dart';

class OpenConversationPage extends StatefulWidget {
  const OpenConversationPage({
    super.key,
    this.conversationId,
    this.userId,
    this.groupId,
    this.openToken,
    this.shareDraft,
  }) : assert(
         conversationId != null ||
             userId != null ||
             groupId != null ||
             (openToken != null && openToken != ''),
       );

  final int? conversationId;
  final int? userId;
  final int? groupId;
  final String? openToken;
  final ChatSharedDraftModel? shareDraft;

  @override
  State<OpenConversationPage> createState() => _OpenConversationPageState();
}

class _OpenConversationPageState extends State<OpenConversationPage> {
  late Future<ChatConversationModel> _openConversationFuture;

  @override
  void initState() {
    super.initState();
    _startOpeningConversation();
  }

  void _startOpeningConversation() {
    _openConversationFuture = _openConversation();
  }

  void _retry() {
    setState(_startOpeningConversation);
  }

  void _logOpenConversation(String message) {
    if (traceLoggingEnabled) {
      debugPrint('[OpenConversationPage] $message');
    }
  }

  Future<ChatConversationModel> _openConversation() async {
    final chatService = Get.find<ChatService>();
    _logOpenConversation(
      'resolving conversation with conversationId=${widget.conversationId}, '
      'userId=${widget.userId}, groupId=${widget.groupId}, '
      'hasOpenToken=${(widget.openToken ?? '').isNotEmpty}, '
      'hasShareDraft=${widget.shareDraft?.isValid ?? false}',
    );

    final details = await chatService.fetchConversation(
      conversationId: widget.conversationId,
      userId: widget.userId,
      groupId: widget.groupId,
      openToken: widget.openToken,
    );

    final baseConversationId = details.resolvedConversationId > 0
        ? details.resolvedConversationId
        : details.conversationId;
    var conversation = ChatConversationModel(
      id: baseConversationId.toString(),
      title: details.title,
      preview: '',
      timeLabel: details.lastSeenAgo,
      avatarUrl: details.avatarUrl,
      isOnline: details.isOnline,
      isTyping: false,
      unreadCount: 0,
      isSeen: true,
      isPinned: details.isPinned,
      isMuted: details.isMuted,
      targetUserId: details.userId != 0 ? details.userId : (widget.userId ?? 0),
    );

    final shareDraft = widget.shareDraft;
    if (shareDraft != null && shareDraft.isValid) {
      _logOpenConversation(
        'sending share draft to conversationId=${conversation.id}, '
        'targetUserId=${conversation.targetUserId}, '
        'productPostId=${shareDraft.productPostId}',
      );
      final parsedConversationId = int.tryParse(conversation.id) ?? 0;
      final result = await chatService.sendMessage(
        conversationId: parsedConversationId > 0 ? parsedConversationId : null,
        recipients: parsedConversationId <= 0 && conversation.targetUserId > 0
            ? <int>[conversation.targetUserId]
            : null,
        message: shareDraft.draftMessage,
        messageType: shareDraft.messageType,
        postId: shareDraft.postId > 0 ? shareDraft.postId : null,
        reelId: shareDraft.reelId > 0 ? shareDraft.reelId : null,
        productPostId: shareDraft.productPostId > 0
            ? shareDraft.productPostId
            : null,
      );

      if (result.conversationId > 0) {
        conversation = conversation.copyWith(
          id: '${result.conversationId}',
          preview: result.lastMessage?.previewText ?? conversation.preview,
          timeLabel: result.lastMessage?.timeLabel ?? conversation.timeLabel,
        );
      }
    }

    _logOpenConversation(
      'opening ChatConversationPage with id=${conversation.id}, '
      'targetUserId=${conversation.targetUserId}, title=${conversation.title}',
    );
    return conversation;
  }

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return FutureBuilder<ChatConversationModel>(
      future: _openConversationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          _logOpenConversation('waiting for conversation payload');
          return Scaffold(
            backgroundColor: palette.canvas,
            appBar: MessengerAppBar(
              title: AppTranslations.commonConversation.tr,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          _logOpenConversation(
            'failed to resolve conversation: ${snapshot.error ?? 'no data returned'}',
          );
          return Scaffold(
            backgroundColor: palette.canvas,
            appBar: MessengerAppBar(
              title: AppTranslations.commonConversation.tr,
            ),
            body: MessengerEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: AppTranslations.composeContactsUnavailable.tr,
              message: _cleanError(snapshot.error),
              actionLabel: AppTranslations.retry.tr,
              onAction: _retry,
            ),
          );
        }

        final conversation = snapshot.data!;

        return ChatConversationPage(
          key: ValueKey(
            'open-chat-${conversation.id}-${conversation.targetUserId}',
          ),
          conversation: conversation,
        );
      },
    );
  }

  String _cleanError(Object? error) {
    final message = error?.toString().replaceFirst('Exception: ', '').trim();
    return message == null || message.isEmpty
        ? AppTranslations.composeContactsUnavailable.tr
        : message;
  }
}
