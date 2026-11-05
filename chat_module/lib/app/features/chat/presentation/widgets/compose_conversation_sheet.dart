import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../data/models/chat_contacts_response.dart';
import '../../data/models/chat_conversations_response.dart';
import '../../data/services/chat_service.dart';
import '../pages/chat_conversation_page.dart';

class ComposeConversationSheet extends StatefulWidget {
  const ComposeConversationSheet({
    super.key,
    required this.homeController,
    this.initialContact,
  });

  final HomeController homeController;

  /// Preselects the contact that opened the composer.
  ///
  /// Contacts that cannot be messaged are deliberately not selected. Callers
  /// can use this to keep the Contacts -> New message flow anchored to the
  /// person the user actually tapped.
  final ChatContactModel? initialContact;

  @override
  State<ComposeConversationSheet> createState() =>
      _ComposeConversationSheetState();
}

class _ComposeConversationSheetState extends State<ComposeConversationSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  ChatContactsResponse? _contactsResponse;
  ChatContactModel? _selectedContact;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _loadErrorMessage = '';
  String _submitErrorMessage = '';

  @override
  void initState() {
    super.initState();
    final initialContact = widget.initialContact;
    if (initialContact != null && initialContact.canMessage) {
      _selectedContact = initialContact;
    }
    _searchController.addListener(_rebuild);
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_rebuild)
      ..dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final filteredContacts = _filteredContacts();

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: SizedBox(
          height: availableHeight * 0.82,
          child: Column(
            children: [
              MessengerSheetHeader(
                title: AppTranslations.composeTitle.tr,
                subtitle: _selectedContact == null
                    ? AppTranslations.composeSelectContact.tr
                    : _selectedContact!.title,
                action: IconButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: MessengerSearchField(
                  controller: _searchController,
                  hintText: AppTranslations.composeSearchHint.tr,
                  onClear: _searchController.clear,
                ),
              ),
              Divider(height: 1, color: palette.divider),
              Expanded(child: _buildContacts(filteredContacts)),
              if (_selectedContact != null) ...[
                Divider(height: 1, color: palette.divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      MessengerAvatar(
                        name: _selectedContact!.title,
                        imageUrl: _selectedContact!.avatarUrl,
                        online: _selectedContact!.isOnline,
                        radius: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedContact!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => setState(() {
                                _selectedContact = null;
                                _submitErrorMessage = '';
                              }),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
                if (_selectedContact!.conversationId == 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 3,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: AppTranslations.composeMessageHint.tr,
                        prefixIcon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                        ),
                      ),
                    ),
                  ),
              ],
              if (_submitErrorMessage.isNotEmpty)
                _InlineError(message: _submitErrorMessage),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedContact == null || _isSubmitting
                        ? null
                        : _submit,
                    child: _isSubmitting
                        ? SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: MessengerDesign.canvas,
                            ),
                          )
                        : Text(_submitLabel()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContacts(List<ChatContactModel> contacts) {
    if (_isLoading && _contactsResponse == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadErrorMessage.isNotEmpty && _contactsResponse == null) {
      return _CompactInfoState(
        icon: Icons.wifi_off_rounded,
        message: _loadErrorMessage,
        onRetry: _loadContacts,
      );
    }
    if (_contactsResponse != null && !_contactsResponse!.isReady) {
      return _CompactInfoState(
        icon: Icons.people_outline_rounded,
        message: AppTranslations.composeContactsUnavailable.tr,
        onRetry: _loadContacts,
      );
    }
    if (contacts.isEmpty) {
      return _CompactInfoState(
        icon: Icons.person_search_outlined,
        message: AppTranslations.composeNoContacts.tr,
        onRetry: _loadContacts,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _ContactTile(
          contact: contact,
          selected: _selectedContact?.id == contact.id,
          showDivider: index != contacts.length - 1,
          onTap: () => setState(() {
            _selectedContact = contact;
            _submitErrorMessage = '';
          }),
        );
      },
    );
  }

  Future<void> _loadContacts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadErrorMessage = '';
      });
    }

    try {
      final response = await Get.find<ChatService>().fetchContacts();
      if (!mounted) {
        return;
      }
      final selectedId = _selectedContact?.id ?? widget.initialContact?.id;
      final selectableContacts = response.contacts
          .where((contact) => contact.canMessage)
          .toList(growable: false);
      ChatContactModel? refreshedSelection;
      if (selectedId != null) {
        for (final contact in selectableContacts) {
          if (contact.id == selectedId) {
            refreshedSelection = contact;
            break;
          }
        }
      }
      setState(() {
        _contactsResponse = ChatContactsResponse(
          implemented: response.implemented,
          scaffoldOnly: response.scaffoldOnly,
          message: response.message,
          contacts: selectableContacts,
        );
        _selectedContact = refreshedSelection ?? _selectedContact;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadErrorMessage = _cleanError(error);
        _isLoading = false;
      });
    }
  }

  List<ChatContactModel> _filteredContacts() {
    final contacts = _contactsResponse?.contacts ?? const <ChatContactModel>[];
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return contacts;
    }
    return contacts
        .where((contact) {
          return contact.title.toLowerCase().contains(query) ||
              contact.userName.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  String _submitLabel() {
    final contact = _selectedContact;
    if (contact == null) {
      return AppTranslations.composeSelectContact.tr;
    }
    return contact.conversationId != 0
        ? AppTranslations.composeOpenConversation.tr
        : AppTranslations.composeSend.tr;
  }

  Future<void> _submit() async {
    final contact = _selectedContact;
    if (contact == null || !contact.canMessage || _isSubmitting) {
      return;
    }
    final message = _messageController.text.trim();
    if (contact.conversationId == 0 && message.isEmpty) {
      setState(() {
        _submitErrorMessage = AppTranslations.composeMessageRequired.tr;
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSubmitting = true;
      _submitErrorMessage = '';
    });

    try {
      if (contact.conversationId != 0) {
        final conversation = _conversationFor(contact);
        if (mounted) {
          Navigator.of(context).pop();
        }
        await _openConversation(conversation);
        return;
      }

      final createdConversation = await widget.homeController.startConversation(
        recipientId: contact.id,
        message: message,
      );
      if (createdConversation == null) {
        throw Exception(AppTranslations.composeContactsUnavailable.tr);
      }
      final resolvedConversation = createdConversation.copyWith(
        title: createdConversation.title.trim().isEmpty
            ? contact.title
            : createdConversation.title,
        avatarUrl: createdConversation.avatarUrl.trim().isEmpty
            ? contact.avatarUrl
            : createdConversation.avatarUrl,
        isOnline: contact.isOnline,
        targetUserId: contact.id,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
      await _openConversation(resolvedConversation);
    } catch (error) {
      if (mounted) {
        setState(() => _submitErrorMessage = _cleanError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  ChatConversationModel _conversationFor(ChatContactModel contact) {
    return ChatConversationModel(
      id: '${contact.conversationId}',
      title: contact.title,
      preview: '',
      timeLabel: '',
      avatarUrl: contact.avatarUrl,
      isOnline: contact.isOnline,
      isTyping: false,
      unreadCount: 0,
      isSeen: true,
      isPinned: false,
      isMuted: false,
      targetUserId: contact.id,
    );
  }

  Future<void> _openConversation(ChatConversationModel conversation) async {
    await Get.to<void>(
      () => ChatConversationPage(
        key: ValueKey('chat-${conversation.id}-${conversation.targetUserId}'),
        conversation: conversation,
      ),
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });

  final ChatContactModel contact;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MessengerRow(
      title: contact.title.isEmpty ? contact.userName : contact.title,
      subtitle: contact.isOnline
          ? AppTranslations.chatOnlineNow.tr
          : contact.lastSeen,
      leading: MessengerAvatar(
        name: contact.title,
        imageUrl: contact.avatarUrl,
        online: contact.isOnline,
        radius: 23,
      ),
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected
            ? MessengerDesign.primary
            : MessengerDesign.of(context).subtle,
        size: 22,
      ),
      showDivider: showDivider,
      onTap: onTap,
    );
  }
}

class _CompactInfoState extends StatelessWidget {
  const _CompactInfoState({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: palette.muted, size: 30),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(AppTranslations.retry.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
