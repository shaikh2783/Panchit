import 'package:flutter/material.dart';
import 'package:get/get.dart' as get_x;
import 'package:provider/provider.dart';

import 'package:chat_module/app/bootstrap/app_bootstrap.dart' as chat_bootstrap;
import 'package:chat_module/app/core/controllers/session_controller.dart'
    as chat_session;
import 'package:chat_module/app/data/services/fcm_call_service.dart'
    as chat_fcm;
import 'package:chat_module/app/data/services/one_signal_service.dart'
    as chat_one_signal;
import 'package:chat_module/app/features/chat/data/models/chat_shared_draft.dart'
    as chat_draft;
import 'package:chat_module/app/features/chat/presentation/pages/open_conversation_page.dart'
    as chat_conversation;
import 'package:chat_module/app/features/chat/presentation/pages/share_conversation_picker_page.dart'
    as chat_share;

import 'package:snginepro/features/auth/application/auth_notifier.dart';

/// Single entry point for opening chat_module screens from anywhere in the
/// host app. Mirrors the bootstrap/session-attach sequence already used in
/// home_page.dart so every entry point shares one chat_module session and
/// one conversation store.
class ChatModuleLauncher {
  ChatModuleLauncher._();

  static Future<bool> _attachSession(BuildContext context) async {
    final authNotifier = context.read<AuthNotifier>();
    final token = authNotifier.authToken;
    final user = authNotifier.currentUser;
    final userId = int.tryParse(
      (user?['user_id'] ?? user?['id'])?.toString() ?? '',
    );
    if (token == null || token.isEmpty || userId == null) {
      return false;
    }

    await _attachExternalSession(
      token: token,
      userId: userId,
      userName: (user?['user_fullname'] ?? user?['name'])?.toString(),
      userPicture: (user?['user_picture'] ?? user?['avatar'])?.toString(),
    );
    return true;
  }

  static Future<void> _attachExternalSession({
    required String token,
    required int userId,
    String? userName,
    String? userPicture,
  }) async {
    await chat_bootstrap.AppBootstrap.ensureInitialized();
    await get_x.Get.find<chat_session.SessionController>()
        .attachExternalSession(
          token: token,
          userId: userId,
          userName: userName,
          userPicture: userPicture,
        );
  }

  /// Attaches the host user to chat_module without opening any screen, so
  /// the device is registered for chat pushes as soon as the user logs in
  /// or switches accounts rather than on first messenger open.
  static Future<void> registerPushForUser({
    required String token,
    required int userId,
    String? userName,
    String? userPicture,
  }) async {
    if (token.isEmpty || userId <= 0) {
      return;
    }
    try {
      await _attachExternalSession(
        token: token,
        userId: userId,
        userName: userName,
        userPicture: userPicture,
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      // Registration retries on the next messenger open.
    }
  }

  static void _showFailureSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to open chat'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Removes this device's OneSignal subscription and FCM call registration
  /// from the chat backend so it stops receiving chat pushes and calls for
  /// the outgoing user (logout or account switch). Must run before the host
  /// logs out of OneSignal, while the subscription ID is still readable. Bootstraps chat_module if needed, since a registration saved
  /// in an earlier run survives even if chat was never opened this run.
  static Future<void> clearPushRegistration() async {
    try {
      await chat_bootstrap.AppBootstrap.ensureInitialized()
          .timeout(const Duration(seconds: 5));
      await Future.wait([
        get_x.Get.find<chat_one_signal.OneSignalService>().detachCurrentUser(),
        get_x.Get.find<chat_fcm.FcmCallService>().detachCurrentUser(),
      ]).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Never block host logout on the chat backend.
    }
  }

  /// Opens (or creates) a 1:1 conversation with [targetUserId].
  static Future<void> openUserConversation(
    BuildContext context, {
    required int targetUserId,
  }) async {
    final attached = await _attachSession(context);
    if (!context.mounted) return;
    if (!attached) {
      _showFailureSnackBar(context);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            chat_conversation.OpenConversationPage(userId: targetUserId),
      ),
    );
  }

  /// Opens a group conversation for [groupId].
  static Future<void> openGroupConversation(
    BuildContext context, {
    required int groupId,
  }) async {
    final attached = await _attachSession(context);
    if (!context.mounted) return;
    if (!attached) {
      _showFailureSnackBar(context);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            chat_conversation.OpenConversationPage(groupId: groupId),
      ),
    );
  }

  /// Opens a conversation by whichever identifier is available, preferring
  /// [conversationId], then [groupId], then [userId]. Used by push
  /// notification taps, where the payload may carry any of them.
  static Future<bool> openConversation(
    BuildContext context, {
    int? conversationId,
    int? groupId,
    int? userId,
  }) async {
    final hasConversation = conversationId != null && conversationId > 0;
    final hasGroup = groupId != null && groupId > 0;
    final hasUser = userId != null && userId > 0;
    if (!hasConversation && !hasGroup && !hasUser) {
      return false;
    }

    final attached = await _attachSession(context);
    if (!context.mounted) return false;
    if (!attached) {
      _showFailureSnackBar(context);
      return false;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => chat_conversation.OpenConversationPage(
          conversationId: hasConversation ? conversationId : null,
          groupId: !hasConversation && hasGroup ? groupId : null,
          userId: !hasConversation && !hasGroup ? userId : null,
        ),
      ),
    );
    return true;
  }

  /// Opens chat_module's conversation/contact picker so the user can forward
  /// [shareDraft] (a shared post/reel/product) into an existing or new chat.
  static Future<void> shareToChat(
    BuildContext context, {
    required chat_draft.ChatSharedDraftModel shareDraft,
    int? preferredUserId,
  }) async {
    final attached = await _attachSession(context);
    if (!context.mounted) return;
    if (!attached) {
      _showFailureSnackBar(context);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => chat_share.ShareConversationPickerPage(
          shareDraft: shareDraft,
          preferredUserId: preferredUserId,
        ),
      ),
    );
  }
}

typedef ChatSharedDraftModel = chat_draft.ChatSharedDraftModel;
