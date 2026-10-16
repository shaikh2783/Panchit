import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../../../settings.dart';
import '../../../../core/utils/audio_cache_warmer.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/utils/chat_trace_logger.dart';
import '../../../../core/utils/video_cache_warmer.dart';
import '../../../../core/utils/timeline_launcher.dart';
import '../../data/models/chat_backgrounds_response.dart';
import '../../data/models/chat_conversation_details.dart';
import '../../data/models/chat_conversations_response.dart';
import '../../data/models/chat_reaction_types_response.dart';
import '../../data/models/chat_shared_content.dart';
import '../../data/models/chat_stickers_response.dart';
import '../../data/services/chat_cache_store.dart';
import '../../data/services/chat_service.dart';
import '../../../groups_chat/data/models/groups_chat_models.dart';
import '../../../groups_chat/data/services/groups_chat_service.dart';
import '../../../calls/data/services/agora_call_service.dart';
import '../../../calls/presentation/pages/agora_call_page.dart';
import '../../../calls/presentation/pages/webrtc_call_page.dart';
import '../../../home/data/models/story_group_model.dart';
import '../../../home/data/services/stories_service.dart';
import '../controllers/chat_conversation_controller.dart';
import 'conversation_details_page.dart';
import 'forward_message_picker_page.dart';
import 'shared_media_viewer_page.dart';
import '../../../home/presentation/pages/story_viewer_page.dart';

class ChatConversationPage extends StatefulWidget {
  const ChatConversationPage({super.key, required this.conversation});

  final ChatConversationModel conversation;

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  late String _tag;
  late ChatConversationController _controller;
  final FocusNode _inputFocusNode = FocusNode();
  bool _hasComposerText = false;
  bool _isInputFocused = false;
  bool _keyboardBottomLock = false;
  double _lastKeyboardInset = 0;
  int _lastLoggedMessageCount = -1;
  int _lastLoggedFirstMessageId = -1;
  int _lastLoggedLastMessageId = -1;
  double? _lastLoggedPixels;
  double? _lastLoggedMaxExtent;

  @override
  void initState() {
    super.initState();
    _bindController();
    _controller.inputController.addListener(_handleComposerChanged);
    _controller.scrollController.addListener(_handleScrollTrace);
    _inputFocusNode.addListener(_handleInputFocusChanged);
    _hasComposerText = _controller.inputController.text.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant ChatConversationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_conversationIdentity(oldWidget.conversation) !=
        _conversationIdentity(widget.conversation)) {
      _controller.inputController.removeListener(_handleComposerChanged);
      _controller.scrollController.removeListener(_handleScrollTrace);
      Get.delete<ChatConversationController>(tag: _tag, force: true);
      _bindController();
      _controller.inputController.addListener(_handleComposerChanged);
      _controller.scrollController.addListener(_handleScrollTrace);
      _hasComposerText = _controller.inputController.text.trim().isNotEmpty;
      _isInputFocused = _inputFocusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    _controller.inputController.removeListener(_handleComposerChanged);
    _controller.scrollController.removeListener(_handleScrollTrace);
    _inputFocusNode.removeListener(_handleInputFocusChanged);
    _inputFocusNode.dispose();
    Get.delete<ChatConversationController>(tag: _tag, force: true);
    super.dispose();
  }

  void _bindController() {
    _tag =
        'chat-conversation-${widget.conversation.id}-${widget.conversation.targetUserId}';
    _controller = Get.put(
      ChatConversationController(
        Get.find<ChatService>(),
        Get.find<ChatAppPreferences>(),
        Get.find<ChatCacheStore>(),
        widget.conversation,
      ),
      tag: _tag,
    );
  }

  void _handleComposerChanged() {
    final hasText = _controller.inputController.text.trim().isNotEmpty;
    if (_hasComposerText == hasText || !mounted) {
      return;
    }
    setState(() {
      _hasComposerText = hasText;
    });
  }

  void _handleInputFocusChanged() {
    if (!mounted) {
      return;
    }
    final isFocused = _inputFocusNode.hasFocus;
    final wasNearBottom = _controller.isNearBottom(threshold: 260);
    _keyboardBottomLock = isFocused && wasNearBottom;
    setState(() {
      _isInputFocused = isFocused;
    });
    unawaited(
      ChatTraceLogger.log(
        'keyboard',
        'focusChanged focused=$isFocused nearBottom=$wasNearBottom bottomLock=$_keyboardBottomLock',
      ),
    );
    if (isFocused && _keyboardBottomLock) {
      _scrollMessagesToBottomForKeyboard(reason: 'input_focus');
    }
  }

  void _handleKeyboardInsetChanged(double keyboardInset) {
    final wasClosed = _lastKeyboardInset <= 0;
    final openedOrChanged =
        keyboardInset > 0 &&
        (wasClosed || (keyboardInset - _lastKeyboardInset).abs() > 24);
    final nearBottom = _controller.isNearBottom(threshold: 320);
    final shouldPinToBottom = _keyboardBottomLock || nearBottom;
    _lastKeyboardInset = keyboardInset;
    if (keyboardInset <= 0) {
      _keyboardBottomLock = false;
    }
    if (!openedOrChanged) {
      return;
    }
    unawaited(
      ChatTraceLogger.log(
        'keyboard',
        'insetChanged inset=${keyboardInset.toStringAsFixed(1)} wasClosed=$wasClosed nearBottom=$nearBottom bottomLock=$_keyboardBottomLock action=${shouldPinToBottom ? 'scrollToBottom' : 'keepOffset'}',
      ),
    );
    if (shouldPinToBottom) {
      _scrollMessagesToBottomForKeyboard(reason: 'keyboard_inset');
    }
  }

  void _scrollMessagesToBottomForKeyboard({required String reason}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.scrollToBottom(reason: reason);
    });
  }

  void _hideKeyboard() {
    _inputFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  String _conversationIdentity(ChatConversationModel conversation) {
    return '${conversation.id}:${conversation.targetUserId}:${conversation.title}:${conversation.avatarUrl}';
  }

  void _handleScrollTrace() {
    if (!ChatTraceLogger.enabled) {
      return;
    }
    final controller = _controller.scrollController;
    if (!controller.hasClients) {
      return;
    }

    final pixels = controller.offset;
    final maxExtent = controller.position.maxScrollExtent;
    final shouldLog =
        _lastLoggedPixels == null ||
        (pixels - _lastLoggedPixels!).abs() >= 48 ||
        _lastLoggedMaxExtent == null ||
        (maxExtent - _lastLoggedMaxExtent!).abs() >= 48;
    if (!shouldLog) {
      return;
    }

    _lastLoggedPixels = pixels;
    _lastLoggedMaxExtent = maxExtent;
    unawaited(
      ChatTraceLogger.log(
        'page-scroll',
        'pixels=${pixels.toStringAsFixed(1)} maxExtent=${maxExtent.toStringAsFixed(1)} viewport=${controller.position.viewportDimension.toStringAsFixed(1)}',
      ),
    );
  }

  void _traceListShape() {
    if (!ChatTraceLogger.enabled) {
      return;
    }
    final messageCount = _controller.messages.length;
    final firstMessageId = messageCount == 0
        ? 0
        : _controller.messages.first.id;
    final lastMessageId = messageCount == 0 ? 0 : _controller.messages.last.id;
    if (messageCount == _lastLoggedMessageCount &&
        firstMessageId == _lastLoggedFirstMessageId &&
        lastMessageId == _lastLoggedLastMessageId) {
      return;
    }

    _lastLoggedMessageCount = messageCount;
    _lastLoggedFirstMessageId = firstMessageId;
    _lastLoggedLastMessageId = lastMessageId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _controller.scrollController;
      final pixels = controller.hasClients ? controller.offset : -1.0;
      final maxExtent = controller.hasClients
          ? controller.position.maxScrollExtent
          : -1.0;
      unawaited(
        ChatTraceLogger.log(
          'page-build',
          'messages=$messageCount first=$firstMessageId last=$lastMessageId pixels=${pixels.toStringAsFixed(1)} maxExtent=${maxExtent.toStringAsFixed(1)}',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      _traceListShape();
      final palette = _ConversationThemePalette.resolve(
        theme.brightness,
        _controller.conversationBackground.value,
      );
      final isGroupConversation = _controller.isGroupConversation.value;
      final canShowVoiceCall =
          !isGroupConversation && callsEnabled && audioCallsEnabled;
      final canShowVideoCall =
          !isGroupConversation && callsEnabled && videoCallsEnabled;
      _handleKeyboardInsetChanged(MediaQuery.viewInsetsOf(context).bottom);

      return Directionality(
        textDirection: Directionality.of(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              _ConversationScreenBackground(
                background: _controller.conversationBackground.value,
                fallbackColor: palette.pageBackground,
              ),
              SafeArea(
                top: false,
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final systemPadding = MediaQuery.paddingOf(context);
                    const isUltraCompactOverlay = false;
                    const outerPadding = EdgeInsets.zero;
                    const headerRadius = BorderRadius.zero;
                    const headerHorizontalPadding = 8.0;
                    const headerVerticalPadding = 7.0;
                    const headerAvatarRadius = 19.0;
                    const headerTitleFontSize = 16.0;
                    const headerStatusFontSize = 12.0;
                    const headerSpacing = 0.0;
                    const messageListPadding = EdgeInsets.fromLTRB(
                      12,
                      10,
                      12,
                      8,
                    );
                    const composerSpacing = 0.0;
                    const composerRadius = BorderRadius.zero;
                    const composerPadding = EdgeInsets.fromLTRB(10, 7, 10, 9);
                    const inputMinHeight = 50.0;
                    const attachmentButtonSize = 34.0;
                    const attachmentIconSize = 20.0;
                    const inputHorizontalPadding = 7.0;
                    const inputVerticalPadding = 4.0;
                    const sendButtonSize = 48.0;
                    const sendIconSize = 22.0;
                    final statusText = _controller.statusLabel.value.trim();
                    final showStatusLine =
                        !isUltraCompactOverlay && statusText.isNotEmpty;
                    const titleWidthFactor = 0.32;
                    final isBlocked =
                        !_controller.canSendMessages.value ||
                        _controller.isRecipientBlocked.value ||
                        _controller.isBlockedByRecipient.value;

                    return Padding(
                      padding: outerPadding,
                      child: Column(
                        children: [
                          Obx(
                            () => _ConversationGlassPanel(
                              borderRadius: headerRadius,
                              surfaceColor: palette.headerSurface,
                              borderColor: palette.panelBorder,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  headerHorizontalPadding,
                                  headerVerticalPadding + systemPadding.top,
                                  headerHorizontalPadding,
                                  headerVerticalPadding,
                                ),
                                child: Row(
                                  textDirection: Directionality.of(context),
                                  children: [
                                    IconButton(
                                      onPressed: Get.back,
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        Icons.arrow_back_ios_rounded,
                                        color: palette.strongText,
                                        size: 21,
                                      ),
                                    ),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: _openConversationDetails,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _ConversationAvatar(
                                            imageUrl:
                                                _controller.avatarUrl.value,
                                            name: _controller.title.value,
                                            radius: headerAvatarRadius,
                                          ),
                                          const SizedBox(width: 10),
                                          SizedBox(
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                titleWidthFactor,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _controller
                                                          .title
                                                          .value
                                                          .isEmpty
                                                      ? AppTranslations
                                                            .commonConversation
                                                            .tr
                                                      : _controller.title.value,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color:
                                                            palette.strongText,
                                                        fontSize:
                                                            headerTitleFontSize,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                if (showStatusLine) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    statusText,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color:
                                                              _controller
                                                                  .statusIsActive
                                                                  .value
                                                              ? MessengerDesign
                                                                    .online
                                                              : palette
                                                                    .mutedText,
                                                          fontSize:
                                                              headerStatusFontSize,
                                                        ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    if (canShowVoiceCall) ...[
                                      IconButton(
                                        onPressed: _onVoiceCallPressed,
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(
                                          Icons.call_outlined,
                                          color: MessengerDesign.primary,
                                          size: 23,
                                        ),
                                      ),
                                    ],
                                    if (canShowVideoCall)
                                      IconButton(
                                        onPressed: _onVideoCallPressed,
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(
                                          Icons.videocam_rounded,
                                          color: MessengerDesign.primary,
                                          size: 24,
                                        ),
                                      ),
                                    IconButton(
                                      onPressed: _openConversationDetails,
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        Icons.more_vert_rounded,
                                        color: palette.mutedText,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: headerSpacing),
                          Expanded(
                            child: Padding(
                              padding: messageListPadding,
                              child: Obx(() {
                                if (_controller.isLoading.value) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (_controller.errorMessage.value.isNotEmpty &&
                                    _controller.messages.isEmpty) {
                                  return Center(
                                    child: _ConversationGlassPanel(
                                      borderRadius: BorderRadius.circular(24),
                                      surfaceColor: palette.chatCanvasBase,
                                      borderColor: palette.panelBorder,
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _controller.errorMessage.value,
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: palette.strongText,
                                                  ),
                                            ),
                                            const SizedBox(height: 14),
                                            ElevatedButton(
                                              onPressed:
                                                  _controller.loadConversation,
                                              child: Text(
                                                AppTranslations.retry.tr,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  controller: _controller.scrollController,
                                  physics: const RangeMaintainingScrollPhysics(
                                    parent: ClampingScrollPhysics(),
                                  ),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.manual,
                                  itemCount: _controller.messages.length + 1,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 13,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: MessengerDesign.primary
                                                .withValues(alpha: 0.07),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            AppTranslations.chatToday.tr,
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  color: palette.strongText,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      );
                                    }
                                    final message =
                                        _controller.messages[index - 1];
                                    return KeyedSubtree(
                                      key: ValueKey('message-${message.id}'),
                                      child: _MessageBubble(
                                        message: message,
                                        isMe: _controller.isMyMessage(message),
                                        readReceiptLabel: _controller
                                            .readReceiptLabelFor(message),
                                        showSenderAvatar: _controller
                                            .isGroupConversation
                                            .value,
                                        strongText: palette.incomingText,
                                        mutedText: palette.messageMetaText,
                                        incomingBubble: palette.incomingBubble,
                                        outgoingBubble: palette.outgoingBubble,
                                        outgoingText: palette.outgoingText,
                                        reactionTypesRx:
                                            _controller.reactionTypes,
                                        onReact: (reaction) =>
                                            _onReactPressed(message, reaction),
                                        onDelete: () =>
                                            _onDeleteMessagePressed(message),
                                        onEdit: () =>
                                            _onEditMessagePressed(message),
                                        onReply: () => _controller
                                            .selectReplyMessage(message),
                                        onForward: () =>
                                            _onForwardMessagePressed(message),
                                        onCopy: () =>
                                            _onCopyMessagePressed(message),
                                      ),
                                    );
                                  },
                                );
                              }),
                            ),
                          ),
                          SizedBox(height: composerSpacing),
                          _ConversationGlassPanel(
                            borderRadius: composerRadius,
                            surfaceColor: palette.composerSurface,
                            borderColor: palette.panelBorder,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                composerPadding.left,
                                composerPadding.top,
                                composerPadding.right,
                                composerPadding.bottom + systemPadding.bottom,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Obx(() {
                                    if (_controller.canSendMessages.value) {
                                      return const SizedBox.shrink();
                                    }
                                    final bannerText =
                                        _controller.isBlockedByRecipient.value
                                        ? AppTranslations
                                              .chatBlockedByRecipientBanner
                                              .tr
                                        : AppTranslations
                                              .chatBlockedByMeBanner
                                              .tr;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: palette.composerActionSurface
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: palette.composerActionSurface
                                                .withValues(alpha: 0.24),
                                          ),
                                        ),
                                        child: Text(
                                          bannerText,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: palette.strongText,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    );
                                  }),
                                  Obx(() {
                                    final replyMessage =
                                        _controller.selectedReplyMessage.value;
                                    final editingMessage = _controller
                                        .selectedEditingMessage
                                        .value;
                                    if (replyMessage == null &&
                                        editingMessage == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: replyMessage != null
                                          ? _ComposerReplyBanner(
                                              message: replyMessage,
                                              isMine: _controller.isMyMessage(
                                                replyMessage,
                                              ),
                                              onClose: _controller
                                                  .clearReplySelection,
                                            )
                                          : _ComposerEditBanner(
                                              message: editingMessage!,
                                              onClose: () => _controller
                                                  .clearEditSelection(
                                                    clearInput: true,
                                                  ),
                                            ),
                                    );
                                  }),
                                  Row(
                                    textDirection: Directionality.of(context),
                                    children: [
                                      Expanded(
                                        child: Container(
                                          constraints: BoxConstraints(
                                            minHeight: inputMinHeight,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: inputHorizontalPadding,
                                            vertical: inputVerticalPadding,
                                          ),
                                          decoration: BoxDecoration(
                                            color: palette.composerFieldSurface,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color:
                                                  palette.composerFieldBorder,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap:
                                                      _controller
                                                              .isSending
                                                              .value ||
                                                          isBlocked
                                                      ? null
                                                      : _openStickerPicker,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  child: Container(
                                                    width: attachmentButtonSize,
                                                    height:
                                                        attachmentButtonSize,
                                                    decoration: BoxDecoration(
                                                      color: Colors.transparent,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .sentiment_satisfied_alt_outlined,
                                                      color: palette
                                                          .composerInputHint
                                                          .withValues(
                                                            alpha: isBlocked
                                                                ? 0.5
                                                                : 1,
                                                          ),
                                                      size: attachmentIconSize,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Container(
                                                  constraints: BoxConstraints(
                                                    minHeight:
                                                        inputMinHeight - 8,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 0,
                                                        vertical: 0,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: palette
                                                        .composerInputSurface,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 13,
                                                        ),
                                                    child: TextField(
                                                      focusNode:
                                                          _inputFocusNode,
                                                      controller: _controller
                                                          .inputController,
                                                      readOnly: isBlocked,
                                                      canRequestFocus:
                                                          !isBlocked,
                                                      minLines: 1,
                                                      maxLines: 5,
                                                      cursorColor: palette
                                                          .outgoingBubble,
                                                      textInputAction:
                                                          TextInputAction
                                                              .newline,
                                                      onSubmitted: (_) {
                                                        if (!isBlocked) {
                                                          _onSendPressed();
                                                        }
                                                      },
                                                      decoration: InputDecoration(
                                                        filled: false,
                                                        fillColor:
                                                            Colors.transparent,
                                                        border:
                                                            InputBorder.none,
                                                        enabledBorder:
                                                            InputBorder.none,
                                                        focusedBorder:
                                                            InputBorder.none,
                                                        disabledBorder:
                                                            InputBorder.none,
                                                        errorBorder:
                                                            InputBorder.none,
                                                        focusedErrorBorder:
                                                            InputBorder.none,
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        hintText: isBlocked
                                                            ? (_controller
                                                                      .isBlockedByRecipient
                                                                      .value
                                                                  ? AppTranslations
                                                                        .chatBlockedByRecipientBanner
                                                                        .tr
                                                                  : AppTranslations
                                                                        .chatBlockedInputHint
                                                                        .tr)
                                                            : AppTranslations
                                                                  .chatInputHint
                                                                  .tr,
                                                        hintStyle: theme
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              color: palette
                                                                  .composerInputHint,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                      ),
                                                      style: theme
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color: palette
                                                                .composerInputText,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed:
                                                    _controller
                                                            .isSending
                                                            .value ||
                                                        isBlocked
                                                    ? null
                                                    : _openAttachmentSheet,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints.tightFor(
                                                      width: 32,
                                                      height: 34,
                                                    ),
                                                icon: Icon(
                                                  Icons.attach_file_rounded,
                                                  color:
                                                      palette.composerInputHint,
                                                  size: 22,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed:
                                                    _controller
                                                            .isSending
                                                            .value ||
                                                        isBlocked
                                                    ? null
                                                    : _onPickImagePressed,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints.tightFor(
                                                      width: 34,
                                                      height: 34,
                                                    ),
                                                icon: Icon(
                                                  Icons.camera_alt_outlined,
                                                  color:
                                                      palette.composerInputHint,
                                                  size: 22,
                                                ),
                                              ),
                                              AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 160,
                                                ),
                                                switchInCurve: Curves.easeOut,
                                                switchOutCurve: Curves.easeIn,
                                                child: _isInputFocused
                                                    ? Padding(
                                                        key: const ValueKey(
                                                          'keyboard-hide-visible',
                                                        ),
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 6,
                                                            ),
                                                        child: Tooltip(
                                                          message: AppTranslations
                                                              .chatHideKeyboard
                                                              .tr,
                                                          child: Material(
                                                            color: Colors
                                                                .transparent,
                                                            child: InkWell(
                                                              onTap:
                                                                  _hideKeyboard,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    999,
                                                                  ),
                                                              child: Container(
                                                                width:
                                                                    attachmentButtonSize,
                                                                height:
                                                                    attachmentButtonSize,
                                                                decoration: BoxDecoration(
                                                                  color: palette
                                                                      .composerActionSurface
                                                                      .withValues(
                                                                        alpha:
                                                                            0.16,
                                                                      ),
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                                child: Icon(
                                                                  Icons
                                                                      .keyboard_hide_rounded,
                                                                  color: palette
                                                                      .composerInputText,
                                                                  size:
                                                                      attachmentIconSize,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : const SizedBox.shrink(
                                                        key: ValueKey(
                                                          'keyboard-hide-hidden',
                                                        ),
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Obx(() {
                                        final isSending =
                                            _controller.isSending.value;
                                        final isBlocked = _controller
                                            .isRecipientBlocked
                                            .value;
                                        final isRecording =
                                            _controller.isRecordingVoice.value;
                                        final shouldSend =
                                            _hasComposerText && !isBlocked;
                                        return GestureDetector(
                                          onTap: isSending || isBlocked
                                              ? null
                                              : shouldSend
                                              ? _onSendPressed
                                              : _onVoiceRecordPressed,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            width: sendButtonSize,
                                            height: sendButtonSize,
                                            decoration: BoxDecoration(
                                              color: isBlocked
                                                  ? palette.outgoingBubble
                                                        .withValues(alpha: 0.45)
                                                  : isSending
                                                  ? palette.outgoingBubble
                                                        .withValues(alpha: 0.7)
                                                  : palette.outgoingBubble,
                                              shape: BoxShape.circle,
                                              boxShadow: const [],
                                            ),
                                            child: isSending
                                                ? Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10,
                                                        ),
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.1,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            palette
                                                                .outgoingText,
                                                          ),
                                                    ),
                                                  )
                                                : Icon(
                                                    shouldSend
                                                        ? Icons.send_rounded
                                                        : (isRecording
                                                              ? Icons
                                                                    .stop_rounded
                                                              : Icons
                                                                    .mic_none_rounded),
                                                    color: palette.outgoingText,
                                                    size: sendIconSize,
                                                  ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _onSendPressed() async {
    try {
      await _controller.sendCurrentMessage();
    } catch (error) {
      await _showControllerError(error);
    }
  }

  Future<void> _onPickImagePressed() async {
    try {
      await _controller.pickAndSendPhoto();
    } catch (error) {
      await _showControllerError(error);
    }
  }

  Future<void> _onPickVideoPressed() async {
    try {
      await _controller.pickAndSendVideo();
    } catch (error) {
      await _showControllerError(error);
    }
  }

  Future<void> _onSendLocationPressed() async {
    try {
      await _controller.sendCurrentLocation();
    } catch (error) {
      await _showControllerError(error);
    }
  }

  Future<void> _onSendContactPressed() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(AppTranslations.chatSendContact.tr),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: AppTranslations.chatContactName.tr,
                      hintText: AppTranslations.chatContactNameHint.tr,
                    ),
                    validator: (value) {
                      if ((value?.trim().isEmpty ?? true)) {
                        return AppTranslations.chatContactNameRequired.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: AppTranslations.chatContactPhone.tr,
                      hintText: AppTranslations.chatContactPhoneHint.tr,
                    ),
                    validator: (value) {
                      if ((value?.trim().isEmpty ?? true)) {
                        return AppTranslations.chatContactPhoneRequired.tr;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                child: Text(AppTranslations.composeSend.tr),
              ),
            ],
          );
        },
      );

      if (submitted != true) {
        return;
      }

      await _controller.sendContact(
        displayName: nameController.text,
        phoneNumber: phoneController.text,
        phoneLabel: 'mobile',
      );
    } catch (error) {
      await _showControllerError(error);
    } finally {
      nameController.dispose();
      phoneController.dispose();
    }
  }

  Future<void> _openStickerPicker() async {
    try {
      await _controller.loadStickerCatalog();
    } catch (_) {
      if (!mounted) {
        return;
      }
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        _controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StickerPickerSheet(controller: _controller),
    );
  }

  Future<void> _openAttachmentSheet() async {
    final theme = Theme.of(context);
    final palette = _ConversationThemePalette.resolve(
      theme.brightness,
      _controller.conversationBackground.value,
    );
    final mediaQuery = MediaQuery.of(context);
    final hasAndroidBottomNavigationButtons =
        defaultTargetPlatform == TargetPlatform.android &&
        mediaQuery.viewPadding.bottom > 0 &&
        mediaQuery.systemGestureInsets.bottom == 0;
    final bottomNavigationPadding = hasAndroidBottomNavigationButtons
        ? mediaQuery.viewPadding.bottom
        : 0.0;
    final bottomSafeSpacing =
        mediaQuery.viewInsets.bottom + bottomNavigationPadding + 14;
    const sheetSideMargin = 12.0;
    final sheetRadius = BorderRadius.circular(30);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              sheetSideMargin,
              0,
              sheetSideMargin,
              bottomSafeSpacing,
            ),
            child: _ConversationGlassPanel(
              borderRadius: sheetRadius,
              surfaceColor: palette.composerSurface,
              borderColor: palette.panelBorder,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: palette.mutedText.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppTranslations.composeMessage.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: palette.strongText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Share media, files, and quick actions',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 14,
                      runSpacing: 18,
                      children: [
                        _AttachmentActionTile(
                          assetPath: 'assets/icons/chat/attachment-gallery.svg',
                          title: AppTranslations.commonImage.tr,
                          accentStart: const Color(0xFF4F8CFF),
                          accentEnd: const Color(0xFF2F6BFF),
                          textColor: palette.strongText,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _onPickImagePressed();
                          },
                        ),
                        _AttachmentActionTile(
                          assetPath: 'assets/icons/chat/attachment-video.svg',
                          title: AppTranslations.commonVideo.tr,
                          accentStart: const Color(0xFFFF8C42),
                          accentEnd: const Color(0xFFFF6A3D),
                          textColor: palette.strongText,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _onPickVideoPressed();
                          },
                        ),
                        _AttachmentActionTile(
                          assetPath: 'assets/icons/chat/attachment-file.svg',
                          title: AppTranslations.chatInfoFiles.tr,
                          accentStart: const Color(0xFF7887FF),
                          accentEnd: const Color(0xFF5B67F5),
                          textColor: palette.strongText,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _onPickFilePressed();
                          },
                        ),
                        _AttachmentActionTile(
                          assetPath:
                              'assets/icons/chat/attachment-location.svg',
                          title: AppTranslations.chatSendLocation.tr,
                          accentStart: const Color(0xFF1FBF75),
                          accentEnd: const Color(0xFF0D9B61),
                          textColor: palette.strongText,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _onSendLocationPressed();
                          },
                        ),
                        _AttachmentActionTile(
                          assetPath: 'assets/icons/chat/attachment-contact.svg',
                          title: AppTranslations.chatSendContact.tr,
                          accentStart: const Color(0xFF22B8B2),
                          accentEnd: const Color(0xFF0F9D98),
                          textColor: palette.strongText,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _onSendContactPressed();
                          },
                        ),
                        _AttachmentActionTile(
                          assetPath: 'assets/icons/chat/attachment-sticker.svg',
                          title: AppTranslations.commonSticker.tr,
                          accentStart: const Color(0xFFA855F7),
                          accentEnd: const Color(0xFF7C3AED),
                          textColor: palette.strongText,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _openStickerPicker();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onVoiceRecordPressed() async {
    try {
      await _controller.toggleVoiceRecording();
    } catch (error) {
      await _showControllerError(error);
    }
  }

  Future<void> _onPickFilePressed() async {
    try {
      await _controller.pickAndSendFile();
    } catch (error) {
      await _showControllerError(error);
    }
  }

  Future<void> _showControllerError(Object error) async {
    if (!mounted) {
      return;
    }

    final resolvedMessage = () {
      final controllerMessage = _controller.errorMessage.value.trim();
      if (controllerMessage.isNotEmpty) {
        return controllerMessage;
      }
      final raw = error.toString().trim();
      if (raw.isEmpty) {
        return (Get.locale?.languageCode.toLowerCase() ?? '') == 'ar'
            ? 'حدث خطأ أثناء تنفيذ العملية'
            : 'Something went wrong while processing your request';
      }
      return raw.replaceFirst('Exception: ', '');
    }();

    if (error is ChatPermissionException) {
      Get.snackbar(
        error.title,
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        mainButton: error.canOpenSettings
            ? TextButton(
                onPressed: () async {
                  await _controller.openPermissionSettings();
                },
                child: Text(
                  (Get.locale?.languageCode.toLowerCase() ?? '') == 'ar'
                      ? 'فتح الإعدادات'
                      : 'Open settings',
                ),
              )
            : null,
      );
      return;
    }

    Get.snackbar(
      AppTranslations.chatInfoTitle.tr,
      resolvedMessage,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _onReactPressed(
    ChatMessageModel message,
    String reaction,
  ) async {
    try {
      await _controller.reactToMessage(message, reaction: reaction);
    } catch (_) {
      if (!mounted) {
        return;
      }
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        _controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _onDeleteMessagePressed(ChatMessageModel message) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(AppTranslations.chatMessageDeleteTitle.tr),
              content: Text(AppTranslations.chatMessageDeleteMessage.tr),
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

    try {
      await _controller.deleteMessage(message);
      if (!mounted) {
        return;
      }
      Get.snackbar(
        AppTranslations.chatInfoTitle.tr,
        AppTranslations.chatMessageDeleted.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        _controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _onEditMessagePressed(ChatMessageModel message) async {
    _controller.beginEditMessage(message);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    _inputFocusNode.requestFocus();
  }

  Future<void> _onForwardMessagePressed(ChatMessageModel message) async {
    await Get.to<void>(() => ForwardMessagePickerPage(sourceMessage: message));
  }

  Future<void> _onCopyMessagePressed(ChatMessageModel message) async {
    final text = message.text.trim().isNotEmpty
        ? message.text.trim()
        : message.previewText.trim();
    if (text.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    Get.snackbar(
      AppTranslations.chatInfoTitle.tr,
      AppTranslations.chatMessageCopied.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _onVoiceCallPressed() {
    _openCall(AgoraCallType.voice);
  }

  void _onVideoCallPressed() {
    _openCall(AgoraCallType.video);
  }

  void _openCall(AgoraCallType type) {
    final conversationId = int.tryParse(widget.conversation.id) ?? 0;
    final agoraCallService = Get.find<AgoraCallService>();
    final recipientUserId = _controller.recipientUserId.value;

    final isTypeEnabled = type == AgoraCallType.video
        ? agoraCallService.isVideoEnabled
        : agoraCallService.isAudioEnabled;

    if (!isTypeEnabled) {
      Get.snackbar(
        AppTranslations.callVoice.tr,
        AppTranslations.callAgoraDisabled.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (conversationId == 0) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        AppTranslations.chatInvalidConversationId.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_controller.isGroupConversation.value || recipientUserId == 0) {
      Get.snackbar(
        type == AgoraCallType.video
            ? AppTranslations.callVideo.tr
            : AppTranslations.callVoice.tr,
        AppTranslations.callDirectOnly.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final title = _controller.title.value.isEmpty
        ? widget.conversation.title
        : _controller.title.value;
    final avatarUrl = _controller.avatarUrl.value.isEmpty
        ? widget.conversation.avatarUrl
        : _controller.avatarUrl.value;

    Get.to(
      () => agoraCallService.isWebRtcProvider
          ? WebRtcCallPage(
              conversationId: conversationId,
              recipientUserId: recipientUserId,
              conversationTitle: title,
              avatarUrl: avatarUrl,
              callType: type,
            )
          : AgoraCallPage(
              conversationId: conversationId,
              recipientUserId: recipientUserId,
              conversationTitle: title,
              avatarUrl: avatarUrl,
              callType: type,
            ),
    );
  }

  Future<void> _openConversationDetails() async {
    final deleted = await Get.to<bool>(
      () => ConversationDetailsPage(
        conversationId: _controller.conversationId,
        title: _controller.title.value,
        avatarUrl: _controller.avatarUrl.value,
        targetUserId: _controller.recipientUserId.value,
        nodeId: _controller.nodeId.value,
        nodeType: _controller.nodeType.value,
        nodeLink: _controller.nodeLink.value,
        isDirectConversation: !_controller.isGroupConversation.value,
        initialIsPinned: _controller.isPinned.value,
        initialIsMuted: _controller.isMuted.value,
        initialBlockedByMe:
            _controller.isRecipientBlocked.value &&
            !_controller.isBlockedByRecipient.value,
        initialBlockedByRecipient: _controller.isBlockedByRecipient.value,
        chatControllerTag: _tag,
      ),
    );
    if (deleted == true && mounted) {
      Get.back<void>();
      return;
    }
    await _controller.loadConversation();
  }
}

class _ConversationThemePalette {
  const _ConversationThemePalette({
    required this.pageBackground,
    required this.chatCanvasBase,
    required this.headerSurface,
    required this.composerSurface,
    required this.composerFieldSurface,
    required this.composerFieldBorder,
    required this.composerActionSurface,
    required this.composerInputSurface,
    required this.composerInputText,
    required this.composerInputHint,
    required this.panelBorder,
    required this.strongText,
    required this.mutedText,
    required this.messageMetaText,
    required this.incomingBubble,
    required this.incomingText,
    required this.outgoingBubble,
    required this.outgoingText,
  });

  final Color pageBackground;
  final Color chatCanvasBase;
  final Color headerSurface;
  final Color composerSurface;
  final Color composerFieldSurface;
  final Color composerFieldBorder;
  final Color composerActionSurface;
  final Color composerInputSurface;
  final Color composerInputText;
  final Color composerInputHint;
  final Color panelBorder;
  final Color strongText;
  final Color mutedText;
  final Color messageMetaText;
  final Color incomingBubble;
  final Color incomingText;
  final Color outgoingBubble;
  final Color outgoingText;

  static _ConversationThemePalette resolve(
    Brightness brightness,
    ChatBackgroundModel? background,
  ) {
    final isDark = brightness == Brightness.dark;
    final basePage = isDark
        ? MessengerDesign.darkCanvas
        : MessengerDesign.canvas;
    final baseSurface = isDark
        ? MessengerDesign.darkSurface
        : MessengerDesign.canvas;
    final defaultStrong = isDark ? AppColors.white : MessengerDesign.ink;
    final defaultMuted = isDark
        ? MessengerDesign.darkMuted
        : MessengerDesign.muted;

    if (background == null) {
      return _ConversationThemePalette(
        pageBackground: basePage,
        chatCanvasBase: baseSurface,
        headerSurface: baseSurface,
        composerSurface: baseSurface,
        composerFieldSurface: isDark
            ? MessengerDesign.darkSoftSurface
            : MessengerDesign.canvas,
        composerFieldBorder: isDark
            ? defaultMuted.withValues(alpha: 0.18)
            : MessengerDesign.divider,
        composerActionSurface: MessengerDesign.primary.withValues(
          alpha: isDark ? 0.16 : 0.1,
        ),
        composerInputSurface: Colors.transparent,
        composerInputText: defaultStrong,
        composerInputHint: defaultMuted.withValues(alpha: 0.82),
        panelBorder: defaultMuted.withValues(alpha: 0.12),
        strongText: defaultStrong,
        mutedText: defaultMuted,
        messageMetaText: defaultMuted.withValues(alpha: 0.95),
        incomingBubble: isDark
            ? MessengerDesign.darkSoftSurface
            : const Color(0xFFF1F1F3),
        incomingText: defaultStrong,
        outgoingBubble: MessengerDesign.primary,
        outgoingText: Colors.white,
      );
    }

    final accent = _accentFromBackground(background);
    final accentText = _bestTextColor(accent);

    if (background.isColor || background.isGradient) {
      final backgroundBase = _baseFromBackground(background, basePage);
      final cardSurface = _mix(backgroundBase, Colors.white, 0.86);
      final strongText = _bestTextColor(cardSurface);
      return _ConversationThemePalette(
        pageBackground: _mix(backgroundBase, basePage, 0.82),
        chatCanvasBase: _mix(backgroundBase, Colors.white, 0.92),
        headerSurface: cardSurface,
        composerSurface: cardSurface,
        composerFieldSurface: _mix(cardSurface, Colors.white, 0.24),
        composerFieldBorder: accent.withValues(alpha: 0.1),
        composerActionSurface: accent.withValues(alpha: 0.1),
        composerInputSurface: Colors.black.withValues(
          alpha: strongText == AppColors.white ? 0.08 : 0.03,
        ),
        composerInputText: strongText,
        composerInputHint: strongText.withValues(alpha: 0.62),
        panelBorder: accent.withValues(alpha: 0.14),
        strongText: strongText,
        mutedText: strongText.withValues(alpha: 0.58),
        messageMetaText: strongText.withValues(alpha: 0.68),
        incomingBubble: _mix(backgroundBase, Colors.white, 0.84),
        incomingText: _bestTextColor(_mix(backgroundBase, Colors.white, 0.84)),
        outgoingBubble: _mix(accent, Colors.black, 0.04),
        outgoingText: accentText,
      );
    }

    return _ConversationThemePalette(
      pageBackground: _mix(accent, basePage, 0.9),
      chatCanvasBase: Colors.white.withValues(alpha: 0.08),
      headerSurface: Colors.white.withValues(alpha: 0.84),
      composerSurface: Colors.white.withValues(alpha: 0.88),
      composerFieldSurface: Colors.white.withValues(alpha: 0.72),
      composerFieldBorder: Colors.black.withValues(alpha: 0.06),
      composerActionSurface: accent.withValues(alpha: 0.12),
      composerInputSurface: Colors.white.withValues(alpha: 0.18),
      composerInputText: AppColors.surfaceDark,
      composerInputHint: AppColors.surfaceDark.withValues(alpha: 0.52),
      panelBorder: Colors.white.withValues(alpha: 0.22),
      strongText: AppColors.surfaceDark,
      mutedText: AppColors.surfaceDark.withValues(alpha: 0.58),
      messageMetaText: AppColors.surfaceDark.withValues(alpha: 0.66),
      incomingBubble: Colors.white.withValues(alpha: 0.76),
      incomingText: AppColors.surfaceDark,
      outgoingBubble: accent,
      outgoingText: accentText,
    );
  }
}

Color _accentFromBackground(ChatBackgroundModel background) {
  if (background.isColor) {
    return _parseHexColor(background.value, AppColors.primary);
  }
  if (background.isGradient && background.gradientStops.isNotEmpty) {
    return _parseHexColor(background.gradientStops.first, AppColors.primary);
  }
  const accents = <Color>[
    Color(0xFF3063F7),
    Color(0xFF0F9D8A),
    Color(0xFF7C3AED),
    Color(0xFFEF6C57),
    Color(0xFF0EA5E9),
    Color(0xFFF59E0B),
  ];
  final key = '${background.title}:${background.value}';
  final index = key.hashCode.abs() % accents.length;
  return accents[index];
}

Color _baseFromBackground(ChatBackgroundModel background, Color fallback) {
  if (background.isColor) {
    return _parseHexColor(background.value, fallback);
  }
  if (background.isGradient && background.gradientStops.isNotEmpty) {
    final colors = background.gradientStops
        .map((item) => _parseHexColor(item, fallback))
        .toList();
    if (colors.length == 1) {
      return colors.first;
    }
    return Color.lerp(colors.first, colors.last, 0.5) ?? colors.first;
  }
  return fallback;
}

Color _parseHexColor(String raw, Color fallback) {
  final normalized = raw.trim().replaceFirst('#', '');
  if (normalized.length != 6 && normalized.length != 8) {
    return fallback;
  }
  final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) {
    return fallback;
  }
  return Color(parsed);
}

Color _mix(Color source, Color target, double amount) {
  return Color.lerp(source, target, amount) ?? source;
}

Color _bestTextColor(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? AppColors.white
      : AppColors.surfaceDark;
}

Color _parseChatBackgroundColor(String raw, {required Color fallback}) {
  final normalized = raw.trim().replaceFirst('#', '');
  if (normalized.length != 6 && normalized.length != 8) {
    return fallback;
  }
  final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) {
    return fallback;
  }
  return Color(parsed);
}

List<Color> _parseChatGradientColors(ChatBackgroundModel background) {
  final colors = background.gradientStops
      .map(
        (value) =>
            _parseChatBackgroundColor(value, fallback: AppColors.primary),
      )
      .toList();
  if (colors.length >= 2) {
    return colors;
  }
  return <Color>[AppColors.primary, AppColors.primary.withValues(alpha: 0.62)];
}

class _ConversationScreenBackground extends StatelessWidget {
  const _ConversationScreenBackground({
    required this.background,
    required this.fallbackColor,
  });

  final ChatBackgroundModel? background;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final selectedBackground = background;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: fallbackColor),
        if (selectedBackground != null) ...[
          if (selectedBackground.isColor)
            ColoredBox(
              color: _parseChatBackgroundColor(
                selectedBackground.value,
                fallback: fallbackColor,
              ),
            )
          else if (selectedBackground.isGradient)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _parseChatGradientColors(selectedBackground),
                ),
              ),
            )
          else if (selectedBackground.isSvg)
            SvgPicture.network(
              selectedBackground.resolvedPreview,
              fit: BoxFit.cover,
              placeholderBuilder: (_) => ColoredBox(color: fallbackColor),
            )
          else if (selectedBackground.hasPreviewUrl)
            Image.network(
              selectedBackground.resolvedPreview,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(color: fallbackColor),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(
                    alpha: selectedBackground.isColor
                        ? 0.02
                        : selectedBackground.isGradient
                        ? 0.06
                        : 0.16,
                  ),
                  Colors.white.withValues(
                    alpha: selectedBackground.isColor
                        ? 0.04
                        : selectedBackground.isGradient
                        ? 0.10
                        : 0.30,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ConversationGlassPanel extends StatelessWidget {
  const _ConversationGlassPanel({
    required this.borderRadius,
    required this.surfaceColor,
    required this.borderColor,
    required this.child,
  });

  final BorderRadius borderRadius;
  final Color surfaceColor;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _StickerPickerSheet extends StatelessWidget {
  const _StickerPickerSheet({required this.controller});

  final ChatConversationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF23253E) : AppColors.white;
    final strongText = isDark ? AppColors.white : AppColors.surfaceDark;
    final mutedText = isDark ? AppColors.accent : const Color(0xFF8D91AE);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.48,
      maxChildSize: 0.92,
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
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.chatStickerTitle.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: strongText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTranslations.chatStickerSubtitle.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.sticky_note_2_outlined,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                if (controller.stickerPacks.isNotEmpty)
                  SizedBox(
                    height: 74,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.stickerPacks.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final pack = controller.stickerPacks[index];
                        final selected =
                            controller.selectedStickerPack.value ==
                            pack.selectionKey;
                        return _StickerPackChip(
                          pack: pack,
                          selected: selected,
                          strongText: strongText,
                          mutedText: mutedText,
                          onTap: () => controller.selectedStickerPack.value =
                              pack.selectionKey,
                        );
                      },
                    ),
                  ),
                if (controller.stickerPacks.isNotEmpty)
                  const SizedBox(height: 8),
                Expanded(
                  child: controller.visibleStickers.isEmpty
                      ? Center(
                          child: Text(
                            AppTranslations.chatStickerEmpty.tr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: mutedText,
                            ),
                          ),
                        )
                      : GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1,
                              ),
                          itemCount: controller.visibleStickers.length,
                          itemBuilder: (context, index) {
                            final sticker = controller.visibleStickers[index];
                            return _StickerCatalogTile(
                              sticker: sticker,
                              onTap: () async {
                                try {
                                  await controller.sendSticker(sticker);
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
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StickerCatalogTile extends StatelessWidget {
  const _StickerCatalogTile({required this.sticker, required this.onTap});

  final ChatStickerModel sticker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: sticker.isSvg
                ? _StableSvgImage(
                    imageUrl: sticker.resolvedImage,
                    fit: BoxFit.contain,
                  )
                : _StableRasterImage(
                    imageUrl: sticker.resolvedImage,
                    fit: BoxFit.contain,
                    errorWidget: Icon(
                      Icons.sticky_note_2_outlined,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StickerPackChip extends StatelessWidget {
  const _StickerPackChip({
    required this.pack,
    required this.selected,
    required this.strongText,
    required this.mutedText,
    required this.onTap,
  });

  final ChatStickerPackSummaryModel pack;
  final bool selected;
  final Color strongText;
  final Color mutedText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewUrl = pack.resolvedPreview;
    final hasPreview = previewUrl.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 84,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.primary.withValues(alpha: 0.08),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.92)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: hasPreview
                    ? (previewUrl.toLowerCase().endsWith('.svg')
                          ? _StableSvgImage(
                              imageUrl: previewUrl,
                              fit: BoxFit.contain,
                            )
                          : _StableRasterImage(
                              imageUrl: previewUrl,
                              fit: BoxFit.contain,
                            ))
                    : Icon(
                        Icons.sticky_note_2_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
              ),
              const SizedBox(height: 5),
              Flexible(
                child: Text(
                  pack.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? AppColors.primary : strongText,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Flexible(
                child: Text(
                  '${pack.resolvedCount}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: mutedText,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 1,
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

class _StickerMessageView extends StatelessWidget {
  const _StickerMessageView({
    required this.message,
    required this.isMe,
    required this.bubbleTextColor,
  });

  final ChatMessageModel message;
  final bool isMe;
  final Color bubbleTextColor;

  @override
  Widget build(BuildContext context) {
    final stickerUrl = message.resolvedStickerUrl;
    final fallbackIcon = Center(
      child: Icon(
        Icons.sticky_note_2_outlined,
        color: bubbleTextColor,
        size: 42,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 160,
        height: 160,
        padding: const EdgeInsets.all(8),
        color: isMe
            ? bubbleTextColor.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.08),
        child: stickerUrl.isEmpty
            ? fallbackIcon
            : stickerUrl.toLowerCase().endsWith('.svg')
            ? _StableSvgImage(imageUrl: stickerUrl, fit: BoxFit.contain)
            : _StableRasterImage(
                imageUrl: stickerUrl,
                fit: BoxFit.contain,
                errorWidget: fallbackIcon,
              ),
      ),
    );
  }
}

class _ComposerReplyBanner extends StatelessWidget {
  const _ComposerReplyBanner({
    required this.message,
    required this.isMine,
    required this.onClose,
  });

  final ChatMessageModel message;
  final bool isMine;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${AppTranslations.chatReplyingTo.tr} ${isMine ? AppTranslations.chatReplyToYourself.tr : message.senderName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.previewText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.surfaceDark.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ComposerEditBanner extends StatelessWidget {
  const _ComposerEditBanner({required this.message, required this.onClose});

  final ChatMessageModel message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppTranslations.chatEditingMessage.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF9A5A00),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.previewText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.surfaceDark.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _AttachmentActionTile extends StatelessWidget {
  const _AttachmentActionTile({
    required this.assetPath,
    required this.title,
    required this.accentStart,
    required this.accentEnd,
    required this.textColor,
    required this.onTap,
  });

  final String assetPath;
  final String title;
  final Color accentStart;
  final Color accentEnd;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 96,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentStart, accentEnd],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentEnd.withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    assetPath,
                    package: 'chat_module',
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileAttachmentCard extends StatelessWidget {
  const _FileAttachmentCard({
    required this.file,
    required this.isMe,
    required this.strongText,
    required this.bubbleTextColor,
    required this.mutedText,
    required this.onTap,
  });

  final ChatFileAttachmentModel? file;
  final bool isMe;
  final Color strongText;
  final Color bubbleTextColor;
  final Color mutedText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final attachment = file;
    if (attachment == null) {
      return const SizedBox.shrink();
    }

    final iconColor = isMe ? Colors.white : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isMe
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
                  color: iconColor.withValues(alpha: isMe ? 0.12 : 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _resolveFileIcon(attachment),
                  color: iconColor,
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
                      attachment.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: bubbleTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fileSubtitle(attachment),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, size: 18, color: mutedText),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _resolveFileIcon(ChatFileAttachmentModel attachment) {
    final mime = attachment.mimeType;
    final ext = attachment.normalizedExtension;
    if (mime.startsWith('image/')) {
      return Icons.image_outlined;
    }
    if (mime.startsWith('video/')) {
      return Icons.videocam_outlined;
    }
    if (mime.startsWith('audio/')) {
      return Icons.audio_file_outlined;
    }
    if (mime == 'application/pdf' || ext == 'pdf') {
      return Icons.picture_as_pdf_outlined;
    }
    if (const <String>{'doc', 'docx', 'txt', 'rtf'}.contains(ext)) {
      return Icons.description_outlined;
    }
    if (const <String>{'xls', 'xlsx', 'csv'}.contains(ext)) {
      return Icons.table_chart_outlined;
    }
    if (const <String>{'zip', 'rar', '7z'}.contains(ext)) {
      return Icons.folder_zip_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  static String _fileSubtitle(ChatFileAttachmentModel attachment) {
    final parts = <String>[];
    final ext = attachment.normalizedExtension;
    if (ext.isNotEmpty) {
      parts.add(ext.toUpperCase());
    }
    if (attachment.fileSize > 0) {
      parts.add(_formatFileSize(attachment.fileSize));
    }
    if (parts.isEmpty) {
      return AppTranslations.chatInfoFiles.tr;
    }
    return parts.join(' • ');
  }

  static String _formatFileSize(int bytes) {
    const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final value = size >= 10 || unitIndex == 0
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(1);
    return '$value ${units[unitIndex]}';
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.readReceiptLabel,
    required this.showSenderAvatar,
    required this.strongText,
    required this.mutedText,
    required this.incomingBubble,
    required this.outgoingBubble,
    required this.outgoingText,
    required this.reactionTypesRx,
    required this.onReact,
    required this.onDelete,
    required this.onEdit,
    required this.onReply,
    required this.onForward,
    required this.onCopy,
  });

  final ChatMessageModel message;
  final bool isMe;
  final String? readReceiptLabel;
  final bool showSenderAvatar;
  final Color strongText;
  final Color mutedText;
  final Color incomingBubble;
  final Color outgoingBubble;
  final Color outgoingText;
  final RxList<ChatReactionTypeModel> reactionTypesRx;
  final ValueChanged<String> onReact;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onReply;
  final VoidCallback onForward;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = message.text.trim();
    final groupInvite = _GroupJoinInviteLink.tryParse(body);
    final showRawInviteLink =
        groupInvite == null || !_isOnlyGroupJoinInviteLink(body, groupInvite);
    final inviteNeedsBottomPadding =
        (showRawInviteLink && body.isNotEmpty) ||
        message.hasVoiceNote ||
        message.hasVideo;
    final bubbleTextColor = isMe ? outgoingText : strongText;
    final shouldShowSenderName = showSenderAvatar && !isMe;
    final contentTextDirection = _resolvedTextDirection(body);
    final avatar = !isMe
        ? Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _ConversationAvatar(
              imageUrl: message.senderPicture,
              name: message.senderName,
              radius: 15,
            ),
          )
        : null;
    final bubble = GestureDetector(
      onLongPress: () => _showReactionPicker(context),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.70,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? null : incomingBubble,
          gradient: isMe
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    outgoingBubble.withValues(alpha: 0.96),
                    MessengerDesign.primaryDark,
                  ],
                )
              : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.replyToMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ReplySnippetCard(
                  reply: message.replyToMessage!,
                  isMe: isMe,
                  strongText: strongText,
                  bubbleTextColor: bubbleTextColor,
                  mutedText: mutedText,
                ),
              ),
            if (message.hasImage)
              Padding(
                padding: EdgeInsets.only(bottom: body.isNotEmpty ? 10 : 0),
                child: GestureDetector(
                  onTap: () => _openImagePreview(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      message.imageUrl,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 220,
                        height: 120,
                        color: isMe
                            ? AppColors.white.withValues(alpha: 0.12)
                            : AppColors.white.withValues(alpha: 0.7),
                        alignment: Alignment.center,
                        child: Text(
                          AppTranslations.chatImageUnavailable.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: bubbleTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (message.hasSticker)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      body.isNotEmpty ||
                          message.hasVoiceNote ||
                          message.hasVideo ||
                          message.hasProduct
                      ? 10
                      : 0,
                ),
                child: _StickerMessageView(
                  message: message,
                  isMe: isMe,
                  bubbleTextColor: bubbleTextColor,
                ),
              ),
            if (message.hasProduct)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      body.isNotEmpty ||
                          message.hasVoiceNote ||
                          message.hasVideo
                      ? 10
                      : 0,
                ),
                child: _ProductAttachmentCard(
                  message: message,
                  isMe: isMe,
                  bubbleTextColor: bubbleTextColor,
                ),
              ),
            if (message.hasStoryAction)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      body.isNotEmpty ||
                          message.hasVoiceNote ||
                          message.hasVideo
                      ? 10
                      : 0,
                ),
                child: _StoryActionCard(
                  message: message,
                  isMe: isMe,
                  strongText: strongText,
                  bubbleTextColor: bubbleTextColor,
                  mutedText: mutedText,
                  reactionTypesRx: reactionTypesRx,
                  onTap: () => _openStoryAction(context),
                ),
              ),
            if (message.hasSharedItem)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      body.isNotEmpty ||
                          message.hasVoiceNote ||
                          message.hasLocation ||
                          message.hasVideo
                      ? 10
                      : 0,
                ),
                child: _SharedAttachmentCard(
                  message: message,
                  isMe: isMe,
                  strongText: strongText,
                  bubbleTextColor: bubbleTextColor,
                  mutedText: mutedText,
                  onTap: () => _openSharedItem(context),
                ),
              ),
            if (message.hasLocation)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      body.isNotEmpty ||
                          message.hasContact ||
                          message.hasVoiceNote ||
                          message.hasVideo
                      ? 10
                      : 0,
                ),
                child: _LocationAttachmentCard(
                  location: message.location,
                  isMe: isMe,
                  strongText: strongText,
                  bubbleTextColor: bubbleTextColor,
                  mutedText: mutedText,
                  onTap: () => _openLocation(context),
                ),
              ),
            if (message.hasContact)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      body.isNotEmpty ||
                          message.hasVoiceNote ||
                          message.hasVideo
                      ? 10
                      : 0,
                ),
                child: _ContactAttachmentCard(
                  contact: message.contact,
                  isMe: isMe,
                  strongText: strongText,
                  bubbleTextColor: bubbleTextColor,
                  mutedText: mutedText,
                  onTap: () => _openContact(context),
                ),
              ),
            if (message.hasFileAttachment)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      body.isNotEmpty ||
                          message.hasVoiceNote ||
                          message.hasVideo
                      ? 10
                      : 0,
                ),
                child: _FileAttachmentCard(
                  file: message.fileAttachment,
                  isMe: isMe,
                  strongText: strongText,
                  bubbleTextColor: bubbleTextColor,
                  mutedText: mutedText,
                  onTap: () => _openFileAttachment(context),
                ),
              ),
            if (groupInvite != null)
              Padding(
                padding: EdgeInsets.only(
                  bottom: inviteNeedsBottomPadding ? 10 : 0,
                ),
                child: _GroupJoinInviteCard(
                  invite: groupInvite,
                  senderName: isMe ? '' : message.senderName,
                  isMe: isMe,
                  strongText: strongText,
                  mutedText: mutedText,
                  bubbleTextColor: bubbleTextColor,
                ),
              ),
            if (message.hasVoiceNote)
              _VoiceNoteAttachment(
                audioUrl: message.voiceNoteUrl,
                isMe: isMe,
                strongText: strongText,
                mutedText: mutedText,
                bubbleTextColor: bubbleTextColor,
              )
            else if (body.isNotEmpty && showRawInviteLink)
              Directionality(
                textDirection: contentTextDirection,
                child: _MessageTextContent(
                  body: body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: bubbleTextColor,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                  linkColor: isMe ? Colors.white : AppColors.primary,
                  onTapUrl: (url) => _openHtmlLink(context, url),
                ),
              ),
            if (message.hasVideo)
              Padding(
                key: ValueKey('video-${message.id}-${message.videoUrl}'),
                padding: const EdgeInsets.only(top: 8),
                child: _VideoAttachment(
                  videoUrl: message.videoUrl,
                  isMe: isMe,
                  mutedText: mutedText,
                ),
              ),
            const SizedBox(height: 5),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              widthFactor: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.timeLabel.isEmpty
                        ? message.time
                        : message.timeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.78)
                          : mutedText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isMe &&
                      (readReceiptLabel?.trim().isNotEmpty ?? false)) ...[
                    const SizedBox(width: 3),
                    Icon(
                      Icons.done_all_rounded,
                      color: Colors.white.withValues(alpha: 0.88),
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (shouldShowSenderName)
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 42,
              right: isMe ? 42 : 0,
              bottom: 4,
            ),
            child: Text(
              message.senderName,
              textAlign: isMe ? TextAlign.right : TextAlign.left,
              style: theme.textTheme.bodySmall?.copyWith(
                color: mutedText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            textDirection: TextDirection.ltr,
            children: [
              if (!isMe && avatar != null) ...[
                avatar,
                const SizedBox(width: 8),
              ],
              bubble,
              if (isMe && avatar != null) ...[const SizedBox(width: 8), avatar],
            ],
          ),
        ),
        if (message.hasReactions)
          Padding(
            padding: EdgeInsets.only(top: 6, left: isMe ? 0 : 38, right: 0),
            child: GestureDetector(
              onTap: () => _showReactionPicker(context),
              child: _ReactionSummaryChip(
                reactionType: message.displayedReactionType,
                reactionCounts: message.reactionCounts,
                reactionTypesRx: reactionTypesRx,
                count: message.reactionsTotalCount,
                isHighlighted: message.iReact,
                isMe: isMe,
                mutedText: mutedText,
              ),
            ),
          ),
        const SizedBox(height: 1),
      ],
    );
  }

  void _openImagePreview(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => _ImagePreviewDialog(imageUrl: message.imageUrl),
    );
  }

  Future<void> _openHtmlLink(BuildContext context, String? url) async {
    final uri = Uri.tryParse(url ?? '');
    if (uri == null) {
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        'Unable to open link',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _openLocation(BuildContext context) async {
    final uri = message.location?.externalMapUri;
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

  Future<void> _openContact(BuildContext context) async {
    final uri = message.contact?.phoneUri;
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

  Future<void> _openSharedItem(BuildContext context) async {
    final item = message.sharedItem;
    if (item == null) {
      return;
    }
    if (item.isPost) {
      await TimelineLauncher.openPost(context, postId: item.postId);
      return;
    }
    if (item.isReel) {
      await TimelineLauncher.openReel(
        context,
        postId: item.postId > 0 ? item.postId : null,
        reelId: item.reelId > 0 ? item.reelId : null,
      );
      return;
    }
    final target = item.bestUrl;
    final uri = Uri.tryParse(target);
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

  Future<void> _openFileAttachment(BuildContext context) async {
    final target = message.fileAttachment?.bestUrl ?? '';
    final uri = Uri.tryParse(target);
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

  Future<void> _openStoryAction(BuildContext context) async {
    final story = message.storyAction?.story;
    final ownerUserId = story?.ownerUserId ?? 0;
    final resolvedStoryId = story?.storyId ?? message.storyId;
    final resolvedStoryMediaId = story?.storyMediaId ?? message.storyMediaId;

    if (ownerUserId <= 0 && resolvedStoryId <= 0 && resolvedStoryMediaId <= 0) {
      return;
    }

    try {
      final response = await Get.find<StoriesService>().loadStories();
      final stories = response.items;
      if (stories.isEmpty) {
        _showStoryOpenFailed();
        return;
      }

      final matchedGroupIndex = _findMatchingStoryGroupIndex(
        stories,
        ownerUserId: ownerUserId,
        storyId: resolvedStoryId,
        storyMediaId: resolvedStoryMediaId,
      );
      if (matchedGroupIndex < 0) {
        _showStoryOpenFailed();
        return;
      }

      final matchedGroup = stories[matchedGroupIndex];
      final matchedItemIndex = _findMatchingStoryItemIndex(
        matchedGroup,
        storyId: resolvedStoryId,
        storyMediaId: resolvedStoryMediaId,
      );

      await Get.to<void>(
        () => StoryViewerPage(
          story: matchedGroup,
          stories: stories,
          initialGroupIndex: matchedGroupIndex,
          initialItemIndex: matchedItemIndex < 0 ? 0 : matchedItemIndex,
        ),
      );
    } catch (_) {
      _showStoryOpenFailed();
    }
  }

  int _findMatchingStoryGroupIndex(
    List<StoryGroupModel> stories, {
    required int ownerUserId,
    required int storyId,
    required int storyMediaId,
  }) {
    for (var index = 0; index < stories.length; index++) {
      final group = stories[index];
      final containsRequestedItem = group.items.any(
        (item) =>
            (storyMediaId > 0 && item.storyMediaId == storyMediaId) ||
            (storyId > 0 && item.storyId == storyId),
      );
      if (containsRequestedItem) {
        return index;
      }
    }

    for (var index = 0; index < stories.length; index++) {
      final group = stories[index];
      if (ownerUserId > 0 &&
          (group.ownerUserId == ownerUserId || group.userId == ownerUserId)) {
        return index;
      }
    }

    return -1;
  }

  int _findMatchingStoryItemIndex(
    StoryGroupModel group, {
    required int storyId,
    required int storyMediaId,
  }) {
    for (var index = 0; index < group.items.length; index++) {
      final item = group.items[index];
      if (storyMediaId > 0 && item.storyMediaId == storyMediaId) {
        return index;
      }
      if (storyId > 0 && item.storyId == storyId) {
        return index;
      }
    }
    return -1;
  }

  void _showStoryOpenFailed() {
    Get.snackbar(
      AppTranslations.loginFailed.tr,
      AppTranslations.chatSharedItemOpenFailed.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _showReactionPicker(BuildContext context) async {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return;
    }
    final bubbleRect =
        renderObject.localToGlobal(Offset.zero) & renderObject.size;

    final selectedReaction = await showGeneralDialog<String>(
      context: context,
      barrierLabel: 'reaction_menu',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.08),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _AnchoredReactionMenu(
            anchorRect: bubbleRect,
            selectedReaction: message.myReactionType,
            reactionTypesRx: reactionTypesRx,
            isMine: isMe,
            canEdit: isMe && message.hasText,
          ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );

    if (selectedReaction == null || selectedReaction.isEmpty) {
      return;
    }
    if (selectedReaction == '__delete__') {
      onDelete();
      return;
    }
    if (selectedReaction == '__edit__') {
      onEdit();
      return;
    }
    if (selectedReaction == '__reply__') {
      onReply();
      return;
    }
    if (selectedReaction == '__forward__') {
      onForward();
      return;
    }
    if (selectedReaction == '__copy__') {
      onCopy();
      return;
    }
    onReact(selectedReaction);
  }
}

class _ReplySnippetCard extends StatelessWidget {
  const _ReplySnippetCard({
    required this.reply,
    required this.isMe,
    required this.strongText,
    required this.bubbleTextColor,
    required this.mutedText,
  });

  final ChatReplyMessageModel reply;
  final bool isMe;
  final Color strongText;
  final Color bubbleTextColor;
  final Color mutedText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white70 : AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            reply.senderName.trim().isNotEmpty
                ? reply.senderName
                : AppTranslations.chatReplyOriginalUnavailable.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isMe ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reply.previewText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isMe
                  ? bubbleTextColor
                  : strongText.withValues(alpha: 0.82),
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          if (reply.time.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              reply.time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: mutedText,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StoryActionCard extends StatelessWidget {
  const _StoryActionCard({
    required this.message,
    required this.isMe,
    required this.strongText,
    required this.bubbleTextColor,
    required this.mutedText,
    required this.reactionTypesRx,
    required this.onTap,
  });

  final ChatMessageModel message;
  final bool isMe;
  final Color strongText;
  final Color bubbleTextColor;
  final Color mutedText;
  final RxList<ChatReactionTypeModel> reactionTypesRx;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final story = message.storyAction?.story;
    final reactionKey = message.storyReaction.isNotEmpty
        ? message.storyReaction
        : message.storyAction?.reaction ?? '';
    final reactionType = reactionTypesRx.firstWhereOrNull(
      (item) => item.key.toLowerCase() == reactionKey.toLowerCase(),
    );
    final accentColor = isMe ? Colors.white : AppColors.primary;
    final title = message.messageType == 'story_reaction'
        ? AppTranslations.chatReactedToStory.tr
        : AppTranslations.chatRepliedToStory.tr;
    final subtitle = message.messageType == 'story_reaction'
        ? (reactionType?.label.isNotEmpty == true
              ? reactionType!.label
              : reactionKey)
        : story?.text.trim().isNotEmpty == true
        ? story!.text.trim()
        : AppTranslations.commonStory.tr;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 220,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.14)
                  : AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: story?.displayImageUrl.trim().isNotEmpty == true
                    ? Image.network(
                        story!.displayImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _StoryPlaceholder(accentColor),
                      )
                    : _StoryPlaceholder(accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (message.messageType == 'story_reaction' &&
                            reactionType?.iconUrl.trim().isNotEmpty ==
                                true) ...[
                          Image.network(
                            reactionType!.iconUrl,
                            width: 18,
                            height: 18,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isMe
                            ? bubbleTextColor
                            : strongText.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    if (story?.authorName.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        story!.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: mutedText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryPlaceholder extends StatelessWidget {
  const _StoryPlaceholder(this.accentColor);

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accentColor.withValues(alpha: 0.10),
      alignment: Alignment.center,
      child: Icon(Icons.auto_stories_rounded, color: accentColor, size: 24),
    );
  }
}

class _SharedAttachmentCard extends StatelessWidget {
  const _SharedAttachmentCard({
    required this.message,
    required this.isMe,
    required this.strongText,
    required this.bubbleTextColor,
    required this.mutedText,
    required this.onTap,
  });

  final ChatMessageModel message;
  final bool isMe;
  final Color strongText;
  final Color bubbleTextColor;
  final Color mutedText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final item = message.sharedItem;
    if (item == null) {
      return const SizedBox.shrink();
    }

    final canOpen = Uri.tryParse(item.bestUrl)?.hasScheme ?? false;
    final previewImageUrl = item.previewImageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canOpen ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 220,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.18)
                  : mutedText.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.10)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  image: item.hasThumbnail
                      ? DecorationImage(
                          image: NetworkImage(previewImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: item.hasThumbnail
                    ? null
                    : Icon(
                        item.isReel || item.isVideo
                            ? Icons.movie_creation_outlined
                            : item.isAudio
                            ? Icons.graphic_eq_rounded
                            : item.isImage
                            ? Icons.image_outlined
                            : Icons.article_outlined,
                        color: isMe ? bubbleTextColor : AppColors.primary,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.14)
                            : AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.isReel
                            ? AppTranslations.sharedReel.tr
                            : AppTranslations.sharedPost.tr,
                        style: TextStyle(
                          color: isMe ? bubbleTextColor : AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isMe ? bubbleTextColor : strongText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                    if (item.authorName.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isMe
                              ? bubbleTextColor.withValues(alpha: 0.8)
                              : mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canOpen)
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 2),
                  child: Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: isMe ? bubbleTextColor : mutedText,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationAttachmentCard extends StatelessWidget {
  const _LocationAttachmentCard({
    required this.location,
    required this.isMe,
    required this.strongText,
    required this.bubbleTextColor,
    required this.mutedText,
    required this.onTap,
  });

  final ChatLocationModel? location;
  final bool isMe;
  final Color strongText;
  final Color bubbleTextColor;
  final Color mutedText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedLocation = location;
    if (resolvedLocation == null) {
      return const SizedBox.shrink();
    }

    final subtitle = resolvedLocation.subtitle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: resolvedLocation.externalMapUri == null ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.18)
                  : mutedText.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.location_on_rounded,
                  color: isMe ? bubbleTextColor : const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedLocation.displayLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isMe ? bubbleTextColor : strongText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isMe
                              ? bubbleTextColor.withValues(alpha: 0.82)
                              : mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      AppTranslations.chatOpenLocation.tr,
                      style: TextStyle(
                        color: isMe ? bubbleTextColor : const Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
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
}

class _ContactAttachmentCard extends StatelessWidget {
  const _ContactAttachmentCard({
    required this.contact,
    required this.isMe,
    required this.strongText,
    required this.bubbleTextColor,
    required this.mutedText,
    required this.onTap,
  });

  final ChatContactAttachmentModel? contact;
  final bool isMe;
  final Color strongText;
  final Color bubbleTextColor;
  final Color mutedText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedContact = contact;
    if (resolvedContact == null) {
      return const SizedBox.shrink();
    }

    final subtitle = resolvedContact.subtitle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: resolvedContact.phoneUri == null ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.18)
                  : mutedText.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFF0F766E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.contact_phone_rounded,
                  color: isMe ? bubbleTextColor : const Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedContact.displayLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isMe ? bubbleTextColor : strongText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isMe
                              ? bubbleTextColor.withValues(alpha: 0.82)
                              : mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      AppTranslations.chatOpenContact.tr,
                      style: TextStyle(
                        color: isMe ? bubbleTextColor : const Color(0xFF0F766E),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
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
}

TextDirection _resolvedTextDirection(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return TextDirection.ltr;
  }
  final rtlRegex = RegExp(r'[\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC]');
  return rtlRegex.hasMatch(trimmed) ? TextDirection.rtl : TextDirection.ltr;
}

class _MessageTextContent extends StatelessWidget {
  const _MessageTextContent({
    required this.body,
    required this.style,
    required this.linkColor,
    required this.onTapUrl,
  });

  final String body;
  final TextStyle? style;
  final Color linkColor;
  final ValueChanged<String> onTapUrl;

  @override
  Widget build(BuildContext context) {
    final spans = _buildTextSpans(
      body,
      baseStyle: style,
      linkColor: linkColor,
      onTapUrl: onTapUrl,
    );
    return Text.rich(
      TextSpan(children: spans, style: style),
      textAlign: TextAlign.start,
      softWrap: true,
    );
  }

  List<InlineSpan> _buildTextSpans(
    String raw, {
    required TextStyle? baseStyle,
    required Color linkColor,
    required ValueChanged<String> onTapUrl,
  }) {
    final normalized = raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"');
    final anchorPattern = RegExp(
      r'<a\s+[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    );

    final spans = <InlineSpan>[];
    var currentIndex = 0;
    for (final match in anchorPattern.allMatches(normalized)) {
      if (match.start > currentIndex) {
        final plainText = _stripHtml(
          normalized.substring(currentIndex, match.start),
        );
        if (plainText.isNotEmpty) {
          spans.add(TextSpan(text: plainText));
        }
      }

      final href = (match.group(1) ?? '').trim();
      final label = _stripHtml(match.group(2) ?? '').trim();
      final displayText = label.isEmpty ? href : label;
      if (displayText.isNotEmpty) {
        spans.add(
          TextSpan(
            text: displayText,
            style: baseStyle?.copyWith(
              color: linkColor,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = () => onTapUrl(href),
          ),
        );
      }
      currentIndex = match.end;
    }

    if (currentIndex < normalized.length) {
      final plainText = _stripHtml(normalized.substring(currentIndex));
      if (plainText.isNotEmpty) {
        spans.add(TextSpan(text: plainText));
      }
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: _stripHtml(normalized)));
    }
    return spans;
  }

  String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]+>'), '');
  }
}

class _StableRasterImage extends StatelessWidget {
  const _StableRasterImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (_, _) => SizedBox(width: width, height: height),
      errorWidget: (_, _, _) => errorWidget ?? const SizedBox.shrink(),
    );
  }
}

class _StableSvgImage extends StatelessWidget {
  const _StableSvgImage({required this.imageUrl, this.fit = BoxFit.contain});

  final String imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.network(
      imageUrl,
      fit: fit,
      placeholderBuilder: (_) => const SizedBox.shrink(),
    );
  }
}

class _AnchoredReactionMenu extends StatelessWidget {
  const _AnchoredReactionMenu({
    required this.anchorRect,
    required this.selectedReaction,
    required this.reactionTypesRx,
    required this.isMine,
    required this.canEdit,
  });

  final Rect anchorRect;
  final String selectedReaction;
  final RxList<ChatReactionTypeModel> reactionTypesRx;
  final bool isMine;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    const menuWidth = 320.0;
    const menuHeight = 122.0;
    const sideMargin = 12.0;
    const gap = 10.0;

    final centeredLeft = anchorRect.center.dx - (menuWidth / 2);
    final clampedLeft = centeredLeft.clamp(
      sideMargin,
      screenWidth - menuWidth - sideMargin,
    );
    final showAbove =
        anchorRect.top >= menuHeight + gap + mediaQuery.padding.top;
    final top = showAbove
        ? anchorRect.top - menuHeight - gap
        : (anchorRect.bottom + gap).clamp(
            mediaQuery.padding.top + gap,
            screenHeight - menuHeight - gap,
          );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: clampedLeft.toDouble(),
            top: top.toDouble(),
            width: menuWidth,
            child: Obx(() {
              final reactionTypes = reactionTypesRx;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF23253E)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: reactionTypes
                            .map(
                              (option) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: _ReactionOptionButton(
                                  option: option,
                                  isSelected: selectedReaction == option.key,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MessageActionButton(
                          icon: Icons.reply_rounded,
                          label: AppTranslations.chatMessageReply.tr,
                          color: AppColors.primary,
                          onTap: () => Get.back(result: '__reply__'),
                        ),
                        _MessageActionButton(
                          icon: Icons.content_copy_rounded,
                          label: AppTranslations.chatMessageCopy.tr,
                          color: AppColors.primary,
                          onTap: () => Get.back(result: '__copy__'),
                        ),
                        _MessageActionButton(
                          icon: Icons.forward_to_inbox_rounded,
                          label: AppTranslations.chatMessageForward.tr,
                          color: AppColors.primary,
                          onTap: () => Get.back(result: '__forward__'),
                        ),
                        if (canEdit)
                          _MessageActionButton(
                            icon: Icons.edit_outlined,
                            label: AppTranslations.chatMessageEdit.tr,
                            color: AppColors.primary,
                            onTap: () => Get.back(result: '__edit__'),
                          ),
                        if (isMine)
                          _MessageActionButton(
                            icon: Icons.delete_outline_rounded,
                            label: AppTranslations.chatMessageDelete.tr,
                            color: const Color(0xFFE05454),
                            onTap: () => Get.back(result: '__delete__'),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MessageActionButton extends StatelessWidget {
  const _MessageActionButton({
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionOptionButton extends StatelessWidget {
  const _ReactionOptionButton({required this.option, required this.isSelected});

  final ChatReactionTypeModel option;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => Navigator.of(context).pop(option.key),
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
          child: _ReactionIcon(option: option),
        ),
      ),
    );
  }
}

class _ReactionIcon extends StatelessWidget {
  const _ReactionIcon({required this.option});

  final ChatReactionTypeModel option;

  @override
  Widget build(BuildContext context) {
    if (option.hasIconUrl) {
      return ClipOval(
        child: _StableRasterImage(
          imageUrl: option.iconUrl,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorWidget: _ReactionEmojiFallback(emoji: option.emoji),
        ),
      );
    }

    return _ReactionEmojiFallback(emoji: option.emoji);
  }
}

class _ReactionEmojiFallback extends StatelessWidget {
  const _ReactionEmojiFallback({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji.isEmpty ? '👍' : emoji,
      style: const TextStyle(fontSize: 24, height: 1),
      textAlign: TextAlign.center,
    );
  }
}

class _GroupJoinInviteLink {
  const _GroupJoinInviteLink({required this.token, required this.url});

  final String token;
  final String url;

  static final RegExp _pattern = RegExp(
    r'''(https?:\/\/[^\s<>"']*group-join\.php\?[^\s<>"']*token=([A-Za-z0-9_-]{8,80})|https?:\/\/[^\s<>"']*\/g\/([A-Za-z0-9_-]{8,80})(?:[/?#][^\s<>"']*)?|sngmessenger:\/\/groups-chat\/join\/([A-Za-z0-9_-]{8,80})|\/api-addon-messangr\/groups-chat\/join\/([A-Za-z0-9_-]{8,80}))''',
    caseSensitive: false,
  );

  static _GroupJoinInviteLink? tryParse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) {
      return null;
    }
    final token =
        match.group(2) ??
        match.group(3) ??
        match.group(4) ??
        match.group(5) ??
        '';
    if (token.isEmpty) {
      return null;
    }
    return _GroupJoinInviteLink(token: token, url: match.group(1) ?? '');
  }
}

bool _isOnlyGroupJoinInviteLink(String body, _GroupJoinInviteLink invite) {
  final normalized = body
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&nbsp;', ' ')
      .trim();
  if (normalized.isEmpty) {
    return false;
  }
  final withoutUrl = normalized
      .replaceAll(invite.url, '')
      .replaceAll(invite.token, '')
      .replaceAll(RegExp(r'[\s\.\,\-\_\|\:\/\?\=\&]+'), '')
      .trim();
  return withoutUrl.isEmpty;
}

class _GroupJoinInviteCard extends StatefulWidget {
  const _GroupJoinInviteCard({
    required this.invite,
    required this.senderName,
    required this.isMe,
    required this.strongText,
    required this.mutedText,
    required this.bubbleTextColor,
  });

  final _GroupJoinInviteLink invite;
  final String senderName;
  final bool isMe;
  final Color strongText;
  final Color mutedText;
  final Color bubbleTextColor;

  @override
  State<_GroupJoinInviteCard> createState() => _GroupJoinInviteCardState();
}

class _GroupJoinInviteCardState extends State<_GroupJoinInviteCard> {
  static final Map<String, Future<GroupsChatJoinPreviewModel>> _previewCache =
      {};

  bool _isJoining = false;
  bool _requestSent = false;
  bool _joined = false;

  Future<GroupsChatJoinPreviewModel> _previewFuture() {
    return _previewCache.putIfAbsent(widget.invite.token, () {
      return Get.find<GroupsChatService>().fetchJoinPreview(
        joinToken: widget.invite.token,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _GroupJoinInviteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invite.token != widget.invite.token) {
      _isJoining = false;
      _requestSent = false;
      _joined = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GroupsChatJoinPreviewModel>(
      future: _previewFuture(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _GroupInviteCardShell(
            isMe: widget.isMe,
            strongText: widget.strongText,
            mutedText: widget.mutedText,
            child: const SizedBox(
              height: 54,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        final preview = snapshot.data;
        if (preview == null || snapshot.hasError) {
          return _GroupInviteCardShell(
            isMe: widget.isMe,
            strongText: widget.strongText,
            mutedText: widget.mutedText,
            child: Text(
              AppTranslations.groupInviteCardUnavailable.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: widget.bubbleTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        final sender = widget.senderName.trim();
        final subtitle = sender.isEmpty
            ? AppTranslations.groupInviteCardTitle.tr
            : AppTranslations.groupInviteCardSubtitle.trParams({
                'name': sender,
              });
        final isAlreadyMember = preview.isAlreadyMember || _joined;
        final hasPendingRequest = preview.isPendingRequest || _requestSent;
        final canJoin =
            !isAlreadyMember && !preview.isBanned && !hasPendingRequest;
        final actionLabel = isAlreadyMember
            ? AppTranslations.groupInviteCardAlreadyMember.tr
            : hasPendingRequest
            ? AppTranslations.groupInviteCardRequestSent.tr
            : preview.isBanned
            ? AppTranslations.groupInviteCardUnavailable.tr
            : AppTranslations.groupInviteCardJoin.tr;

        return _GroupInviteCardShell(
          isMe: widget.isMe,
          strongText: widget.strongText,
          mutedText: widget.mutedText,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GroupInviteAvatar(
                    imageUrl: preview.imageUrl,
                    name: preview.name,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preview.name.isEmpty
                              ? AppTranslations.groupsTitle.tr
                              : preview.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: widget.strongText,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: widget.mutedText,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (preview.description.trim().isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  preview.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: widget.mutedText,
                    height: 1.25,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${preview.memberCount} ${AppTranslations.groupsMembers.tr}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: canJoin && !_isJoining ? _requestJoin : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(82, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: _isJoining
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(actionLabel),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestJoin() async {
    if (_isJoining) {
      return;
    }
    setState(() => _isJoining = true);
    try {
      final result = await Get.find<GroupsChatService>().requestJoin(
        joinToken: widget.invite.token,
      );
      if (!mounted) {
        return;
      }
      final alreadyJoined = result.status == 'already_member';
      setState(() {
        _joined = alreadyJoined;
        _requestSent = !alreadyJoined;
      });
      Get.snackbar(
        alreadyJoined
            ? AppTranslations.groupInviteCardAlreadyMember.tr
            : AppTranslations.groupInviteCardRequestSent.tr,
        result.group?.name ?? '',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        AppTranslations.groupChatUnableToSend.tr,
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }
}

class _GroupInviteCardShell extends StatelessWidget {
  const _GroupInviteCardShell({
    required this.isMe,
    required this.strongText,
    required this.mutedText,
    required this.child,
  });

  final bool isMe;
  final Color strongText;
  final Color mutedText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 216,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.13)
            : AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMe
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: child,
    );
  }
}

class _GroupInviteAvatar extends StatelessWidget {
  const _GroupInviteAvatar({required this.imageUrl, required this.name});

  final String imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'G'
        : name.trim().substring(0, 1).toUpperCase();
    if (imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _fallback(context, initials),
        ),
      );
    }
    return _fallback(context, initials);
  }

  Widget _fallback(BuildContext context, String initials) {
    final palette = MessengerDesign.of(context);
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: MessengerDesign.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReactionSummaryChip extends StatelessWidget {
  const _ReactionSummaryChip({
    required this.reactionType,
    required this.reactionCounts,
    required this.reactionTypesRx,
    required this.count,
    required this.isHighlighted,
    required this.isMe,
    required this.mutedText,
  });

  final String reactionType;
  final Map<String, int> reactionCounts;
  final RxList<ChatReactionTypeModel> reactionTypesRx;
  final int count;
  final bool isHighlighted;
  final bool isMe;
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

      final background = isMe
          ? AppColors.primary.withValues(alpha: isHighlighted ? 0.16 : 0.1)
          : Colors.white.withValues(alpha: 0.82);
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
            _ReactionIconsCluster(
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

class _ReactionIconsCluster extends StatelessWidget {
  const _ReactionIconsCluster({
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
              child: _ReactionIconBadge(
                reactionKey: visibleKeys[index],
                reactionTypes: reactionTypes,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReactionIconBadge extends StatelessWidget {
  const _ReactionIconBadge({
    required this.reactionKey,
    required this.reactionTypes,
  });

  final String reactionKey;
  final List<ChatReactionTypeModel> reactionTypes;

  @override
  Widget build(BuildContext context) {
    final reactionModel = reactionTypes
        .where((type) => type.key == reactionKey)
        .firstOrNull;

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      alignment: Alignment.center,
      child: reactionModel != null && reactionModel.hasIconUrl
          ? ClipOval(
              child: Image.network(
                reactionModel.iconUrl,
                width: 16,
                height: 16,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _ReactionEmojiFallback(
                  emoji: _emojiForReaction(reactionKey),
                ),
              ),
            )
          : _ReactionEmojiFallback(emoji: _emojiForReaction(reactionKey)),
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

class _VoiceNoteAttachment extends StatefulWidget {
  const _VoiceNoteAttachment({
    required this.audioUrl,
    required this.isMe,
    required this.strongText,
    required this.mutedText,
    required this.bubbleTextColor,
  });

  final String audioUrl;
  final bool isMe;
  final Color strongText;
  final Color mutedText;
  final Color bubbleTextColor;

  @override
  State<_VoiceNoteAttachment> createState() => _VoiceNoteAttachmentState();
}

class _ChatMediaPlaybackCoordinator {
  _ChatMediaPlaybackCoordinator._();

  static final _ChatMediaPlaybackCoordinator instance =
      _ChatMediaPlaybackCoordinator._();

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

class _VoiceNoteAttachmentState extends State<_VoiceNoteAttachment> {
  late final AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isReady = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isPriming = false;

  String get _playbackId => 'audio:${widget.audioUrl}';

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.durationStream.listen((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        _duration = value ?? Duration.zero;
      });
    });
    _player.positionStream.listen((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        _position = value;
      });
    });
    _player.playerStateStream.listen((state) {
      if (!mounted) {
        return;
      }
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
      setState(() {});
    });
    unawaited(_primeAudio());
  }

  Future<void> _initialize() async {
    if (_isReady || _isLoading) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      debugPrint('[ChatVoiceTrace] initialize player url=${widget.audioUrl}');
      final duration = await _setVoiceAudioSource();
      if (!mounted) {
        return;
      }
      setState(() {
        _isReady = true;
        _isLoading = false;
        _hasError = false;
        _duration = duration ?? _duration;
      });
    } catch (error, stackTrace) {
      debugPrint(
        '[ChatVoiceTrace] initialize player failed url=${widget.audioUrl} '
        'error=$error',
      );
      debugPrintStack(
        label: '[ChatVoiceTrace] initialize player stack',
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _primeAudio() async {
    if (_isPriming || _isReady || _isLoading) {
      return;
    }

    _isPriming = true;
    try {
      debugPrint('[ChatVoiceTrace] prime audio url=${widget.audioUrl}');
      final duration = await _setVoiceAudioSource();
      if (!mounted) {
        return;
      }
      setState(() {
        _isReady = true;
        _hasError = false;
        _duration = duration ?? _duration;
      });
    } catch (error, stackTrace) {
      debugPrint(
        '[ChatVoiceTrace] prime audio failed url=${widget.audioUrl} '
        'error=$error',
      );
      debugPrintStack(
        label: '[ChatVoiceTrace] prime audio stack',
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
    } finally {
      _isPriming = false;
    }
  }

  Future<Duration?> _setVoiceAudioSource() async {
    try {
      return await _player.setUrl(widget.audioUrl);
    } catch (networkError, networkStackTrace) {
      debugPrint(
        '[ChatVoiceTrace] setUrl failed url=${widget.audioUrl} '
        'error=$networkError',
      );
      debugPrintStack(
        label: '[ChatVoiceTrace] setUrl stack',
        stackTrace: networkStackTrace,
      );

      final cachedFile = await AudioCacheWarmer.getCachedFile(widget.audioUrl);
      if (cachedFile == null) {
        rethrow;
      }

      final playableFile = await _playableCachedAudioFile(
        cachedFile,
        widget.audioUrl,
      );
      debugPrint(
        '[ChatVoiceTrace] fallback cached audio path=${playableFile.path}',
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

  @override
  void dispose() {
    _ChatMediaPlaybackCoordinator.instance.deactivate(_playbackId);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _player.playing;
    final effectiveDuration = _duration.inMilliseconds <= 0
        ? const Duration(seconds: 1)
        : _duration;
    final clampedPosition = _position > effectiveDuration
        ? effectiveDuration
        : _position;

    if (_hasError) {
      return Text(
        AppTranslations.chatVoiceUnavailable.tr,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: widget.bubbleTextColor,
          fontWeight: FontWeight.w600,
        ),
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
                onTap: () async {
                  if (!_isReady) {
                    await _initialize();
                  }
                  if (!_isReady) {
                    return;
                  }
                  if (isPlaying) {
                    await _pausePlayback();
                    _ChatMediaPlaybackCoordinator.instance.deactivate(
                      _playbackId,
                    );
                  } else {
                    await _ChatMediaPlaybackCoordinator.instance.activate(
                      id: _playbackId,
                      stopPlayback: _pausePlayback,
                    );
                    await _player.play();
                  }
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: widget.isMe
                        ? AppColors.white.withValues(alpha: 0.18)
                        : AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.bubbleTextColor,
                            ),
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: widget.bubbleTextColor,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppTranslations.homeStatusVoice.tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.bubbleTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatDuration(clampedPosition),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: widget.bubbleTextColor.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: widget.isMe
                  ? AppColors.white
                  : AppColors.primary,
              inactiveTrackColor: widget.isMe
                  ? AppColors.white.withValues(alpha: 0.28)
                  : widget.mutedText.withValues(alpha: 0.35),
              thumbColor: widget.isMe ? AppColors.white : AppColors.primary,
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
              _formatDuration(effectiveDuration),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: widget.bubbleTextColor.withValues(alpha: 0.75),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _ProductAttachmentCard extends StatelessWidget {
  const _ProductAttachmentCard({
    required this.message,
    required this.isMe,
    required this.bubbleTextColor,
  });

  final ChatMessageModel message;
  final bool isMe;
  final Color bubbleTextColor;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final cardTextColor = isMe ? bubbleTextColor : palette.text;
    final cardMutedColor = isMe
        ? bubbleTextColor.withValues(alpha: 0.76)
        : palette.muted;
    final surfaceColor = isMe
        ? bubbleTextColor.withValues(alpha: 0.10)
        : palette.surface;
    final borderColor = isMe
        ? bubbleTextColor.withValues(alpha: 0.16)
        : palette.divider;
    final canOpen =
        message.productPostId > 0 ||
        (Uri.tryParse(message.productActionUrl)?.hasScheme ?? false);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: canOpen ? () => _openProduct(context) : null,
        child: Ink(
          width: 220,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.productImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    message.productImageUrl,
                    width: 220,
                    height: 130,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _ProductPlaceholder(color: cardTextColor),
                  ),
                )
              else
                _ProductPlaceholder(color: cardTextColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.productName.isEmpty
                          ? AppTranslations.commonProduct.tr
                          : message.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cardTextColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (message.productDescription.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        message.productDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cardMutedColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (message.productPrice.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        message.productPrice,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isMe
                              ? bubbleTextColor
                              : MessengerDesign.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openProduct(BuildContext context) async {
    if (message.productPostId > 0) {
      await TimelineLauncher.openProduct(
        context,
        postId: message.productPostId,
      );
      return;
    }

    final uri = Uri.tryParse(message.productActionUrl);
    if (uri == null) {
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        'Unable to open product link',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 92,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.08),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.shopping_bag_outlined,
        color: color.withValues(alpha: 0.85),
        size: 28,
      ),
    );
  }
}

class _VideoAttachment extends StatefulWidget {
  const _VideoAttachment({
    required this.videoUrl,
    required this.isMe,
    required this.mutedText,
  });

  final String videoUrl;
  final bool isMe;
  final Color mutedText;

  @override
  State<_VideoAttachment> createState() => _VideoAttachmentState();
}

class _VideoAttachmentState extends State<_VideoAttachment> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;

  String get _playbackId => 'video:${widget.videoUrl}';

  @override
  void initState() {
    super.initState();
    unawaited(VideoCacheWarmer.warm(widget.videoUrl));
  }

  @override
  void didUpdateWidget(covariant _VideoAttachment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      final previousController = _controller;
      _controller = null;
      _loading = false;
      _failed = false;
      unawaited(previousController?.dispose() ?? Future<void>.value());
      unawaited(VideoCacheWarmer.warm(widget.videoUrl));
    }
  }

  Future<void> _initializeAndPlay() async {
    if (_loading) {
      return;
    }

    final existingController = _controller;
    if (existingController != null) {
      if (existingController.value.isPlaying) {
        await _pausePlayback();
        _ChatMediaPlaybackCoordinator.instance.deactivate(_playbackId);
      } else {
        await _ChatMediaPlaybackCoordinator.instance.activate(
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

    final previousController = _controller;
    final controller = await VideoCacheWarmer.createController(widget.videoUrl);

    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }

    try {
      await controller.initialize();
      await previousController?.dispose();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
      await _ChatMediaPlaybackCoordinator.instance.activate(
        id: _playbackId,
        stopPlayback: _pausePlayback,
      );
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      await controller.dispose();
      await previousController?.dispose();
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

  @override
  void dispose() {
    _ChatMediaPlaybackCoordinator.instance.deactivate(_playbackId);
    _controller?.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    final controller = _controller;
    const attachmentHeight = 220.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 220,
        height: attachmentHeight,
        child: _loading
            ? Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              )
            : controller == null
            ? GestureDetector(
                onTap: _openProfessionalViewer,
                child: Container(
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
                                Colors.black.withValues(alpha: 0.42),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: GestureDetector(
                          onTap: _initializeAndPlay,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.56),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_full_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Open',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _failed
            ? Container(
                color: Colors.black12,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  AppTranslations.chatVideoUnavailable.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: widget.isMe ? AppColors.white : widget.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final duration = value.duration;
                  final position = value.position > duration
                      ? duration
                      : value.position;
                  final totalMs = duration.inMilliseconds <= 0
                      ? 1
                      : duration.inMilliseconds;
                  final progress = (position.inMilliseconds / totalMs).clamp(
                    0.0,
                    1.0,
                  );

                  return GestureDetector(
                    onTap: _openProfessionalViewer,
                    child: Stack(
                      children: [
                        Container(
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
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.22),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.55),
                                ],
                                stops: const [0, 0.45, 1],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: GestureDetector(
                            onTap: _initializeAndPlay,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.56),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.open_in_full_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Open',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.24,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatDuration(duration),
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
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
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _openProfessionalViewer() async {
    final item = ChatSharedItemModel(
      id: 0,
      messageId: 0,
      conversationId: 0,
      type: 'video',
      message: '',
      source: widget.videoUrl,
      url: widget.videoUrl,
      file: '',
      thumbnail: '',
      mediaUrl: widget.videoUrl,
      createdAt: '',
      timeAgo: '',
      postId: 0,
      reelId: 0,
      title: '',
      sender: null,
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SharedMediaViewerPage(
          item: item,
          title: AppTranslations.commonVideo.tr,
        ),
      ),
    );
  }

  String _formatDuration(Duration value) {
    final totalHours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (totalHours > 0) {
      return '$totalHours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _ImagePreviewDialog extends StatelessWidget {
  const _ImagePreviewDialog({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        AppTranslations.chatImageUnavailable.tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PreviewActionButton(
                  icon: Icons.download_rounded,
                  onTap: () => _downloadImage(context),
                ),
                const SizedBox(width: 8),
                _PreviewActionButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context) async {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        'Invalid image url',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        'Unable to open image link',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _PreviewActionButton extends StatelessWidget {
  const _PreviewActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
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
    final initials = name.trim().isEmpty
        ? 'M'
        : name.trim().substring(0, 1).toUpperCase();

    if (imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _FallbackAvatar(size: size, initials: initials),
        ),
      );
    }

    return _FallbackAvatar(size: size, initials: initials);
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.size, required this.initials});

  final double size;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.surfaceDark],
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
