import 'package:flutter/material.dart';
import 'package:get/get.dart' as get_x;
import 'package:provider/provider.dart';

import 'package:chat_module/app/bootstrap/app_bootstrap.dart' as chat_bootstrap;
import 'package:chat_module/app/core/controllers/session_controller.dart'
    as chat_session;
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

    await chat_bootstrap.AppBootstrap.ensureInitialized();
    await get_x.Get.find<chat_session.SessionController>()
        .attachExternalSession(
          token: token,
          userId: userId,
          userName: (user?['user_fullname'] ?? user?['name'])?.toString(),
          userPicture: (user?['user_picture'] ?? user?['avatar'])?.toString(),
        );
    return true;
  }

  static void _showFailureSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to open chat'),
        backgroundColor: Colors.red,
      ),
    );
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
