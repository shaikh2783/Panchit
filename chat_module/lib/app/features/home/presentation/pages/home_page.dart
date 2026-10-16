import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../../settings.dart';
import '../../../../core/controllers/session_controller.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../../../accounts/data/models/connected_accounts_models.dart';
import '../../../chat/data/models/chat_contacts_response.dart';
import '../../../chat/data/models/chat_conversations_response.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../../calls/data/models/chat_call_models.dart';
import '../../../calls/presentation/controllers/calls_controller.dart';
import '../../../chat/presentation/pages/chat_conversation_page.dart';
import '../../../chat/presentation/widgets/compose_conversation_sheet.dart';
import '../../../groups_chat/data/models/groups_chat_models.dart';
import '../../../groups_chat/presentation/controllers/groups_chat_controller.dart';
import '../../../groups_chat/presentation/pages/group_chat_page.dart';
import '../../../groups_chat/utils/groups_chat_logger.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../widgets/stories_section.dart';
import '../controllers/home_controller.dart';
import '../controllers/profile_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionController = Get.find<SessionController>();
    final homeController = Get.find<HomeController>();
    final palette = _HomePalette.of(context);

    return Obx(() {
      final selectedTab = homeController.currentTabIndex.value;
      return PopScope(
        canPop: selectedTab != 4,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && selectedTab == 4) {
            homeController.selectTab(0);
          }
        },
        child: Scaffold(
          backgroundColor: palette.pageBackground,
          body: SafeArea(
            child: Column(
              children: [
                _ChatModuleBackBar(
                  palette: palette,
                  selectedTab: selectedTab,
                  homeController: homeController,
                ),
                Expanded(
                  child: IndexedStack(
                    index: selectedTab,
                    children: [
                      _ChatsTab(
                        sessionController: sessionController,
                        homeController: homeController,
                      ),
                      _ContactsTab(homeController: homeController),
                      const _CallsTab(),
                      const SettingsContent(),
                      _GroupsTab(homeController: homeController),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: selectedTab == 4
              ? null
              : _BottomMessengerBar(homeController: homeController),
        ),
      );
    });
  }
}

/// Lets the user return to the host app. This module is pushed as a plain
/// route on top of the host's own navigator (not run under its own
/// GetMaterialApp), so it has no app-owned back affordance of its own by
/// default beyond the system back gesture.
class _ChatModuleBackBar extends StatelessWidget {
  const _ChatModuleBackBar({
    required this.palette,
    required this.selectedTab,
    required this.homeController,
  });

  final _HomePalette palette;
  final int selectedTab;
  final HomeController homeController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // Mirrors the PopScope handling above: from the Groups tab,
                // the first back action returns to Chats; otherwise it
                // leaves the module and returns to the host app.
                if (selectedTab == 4) {
                  homeController.selectTab(0);
                  return;
                }
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.inlineActionSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.sectionBorder),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: palette.strongText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatsTab extends StatelessWidget {
  const _ChatsTab({
    required this.sessionController,
    required this.homeController,
  });

  final SessionController sessionController;
  final HomeController homeController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = homeController.isLoading.value;
      final isSearching = homeController.isSearching.value;
      final isSearchActive = homeController.isSearchActive;
      final conversations = homeController.visibleConversations;
      final searchError = homeController.searchErrorMessage.value;
      final showInitialLoading = isLoading && !isSearchActive;
      final showSearchLoading =
          isSearchActive && isSearching && conversations.isEmpty;
      final showSearchError =
          isSearchActive && searchError.isNotEmpty && conversations.isEmpty;
      final showSearchEmpty =
          isSearchActive &&
          !isSearching &&
          searchError.isEmpty &&
          conversations.isEmpty;

      final conversationSliverChildCount = conversations.isEmpty
          ? 0
          : (conversations.length * 2) - 1;
      final listSliverChildCount =
          conversationSliverChildCount +
          (homeController.isLoadingMore.value ? 1 : 0);

      return RefreshIndicator(
        onRefresh: homeController.load,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (conversations.isNotEmpty &&
                homeController.hasMore &&
                notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 120) {
              homeController.loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Column(
                    children: [
                      _TopBar(
                        controller: sessionController,
                        onCompose: () => _showComposeConversationSheet(
                          context,
                          homeController,
                        ),
                        onGroups: () => homeController.selectTab(4),
                        onProfile: () => homeController.selectTab(3),
                      ),
                      const SizedBox(height: 14),
                      _SearchBar(controller: homeController),
                      if (!isSearchActive) ...[
                        const SizedBox(height: 12),
                        const StoriesSection(),
                      ],
                    ],
                  ),
                ),
              ),
              if (showInitialLoading || showSearchLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (showSearchError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: MessengerEmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: AppTranslations.homeSearchErrorTitle.tr,
                    message: searchError,
                    actionLabel: AppTranslations.retry.tr,
                    onAction: () => homeController.load(),
                  ),
                )
              else if (showSearchEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _TabPlaceholder(
                    icon: Icons.search_off_rounded,
                    title: AppTranslations.homeSearchEmptyTitle.tr,
                    subtitle: AppTranslations.homeSearchEmptyBody.tr,
                  ),
                )
              else if (conversations.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _UnavailableState(controller: homeController),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index >= conversationSliverChildCount) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (index.isOdd) {
                        return Divider(
                          height: 1,
                          indent: 66,
                          color: _HomePalette.of(context).sectionBorder,
                        );
                      }
                      return _LiveChatRow(
                        chat: conversations[index ~/ 2],
                        homeController: homeController,
                      );
                    }, childCount: listSliverChildCount),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _ContactsTab extends StatefulWidget {
  const _ContactsTab({required this.homeController});

  final HomeController homeController;

  @override
  State<_ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<_ContactsTab> {
  late Future<ChatContactsResponse> _contactsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _contactsFuture = Get.find<ChatService>().fetchContacts();
  }

  Future<void> _reload() async {
    setState(() {
      _contactsFuture = Get.find<ChatService>().fetchContacts();
    });
    await _contactsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppTranslations.navContacts.tr,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: palette.strongText,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: AppTranslations.groupsTitle.tr,
                    onPressed: () => widget.homeController.selectTab(4),
                    icon: const Icon(Icons.groups_2_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: palette.searchBackground,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: AppTranslations.homeSearchHint.tr,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: palette.mutedText,
                      size: 19,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<ChatContactsResponse>(
            future: _contactsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _TabPlaceholder(
                  icon: Icons.people_outline_rounded,
                  title: AppTranslations.composeContactsUnavailable.tr,
                  subtitle: snapshot.error?.toString() ?? '',
                );
              }

              final normalizedQuery = _query.trim().toLowerCase();
              final contacts = snapshot.data!.contacts.where((contact) {
                if (normalizedQuery.isEmpty) return true;
                return contact.title.toLowerCase().contains(normalizedQuery) ||
                    contact.userName.toLowerCase().contains(normalizedQuery);
              }).toList();

              if (contacts.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.55,
                        child: _TabPlaceholder(
                          icon: Icons.people_outline_rounded,
                          title: AppTranslations.composeNoContacts.tr,
                          subtitle: AppTranslations.homeSearchEmptyBody.tr,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                  itemCount: contacts.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 62,
                    color: palette.sectionBorder,
                  ),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ListTile(
                      onTap: () => _openContact(contact),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _AvatarView(
                            imageUrl: contact.avatarUrl,
                            name: contact.title,
                            radius: 23,
                          ),
                          if (contact.isOnline)
                            PositionedDirectional(
                              end: -1,
                              bottom: 1,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: MessengerDesign.online,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: palette.pageBackground,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              contact.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: palette.strongText,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (contact.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified_rounded,
                              color: MessengerDesign.primary,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        !contact.canMessage
                            ? AppTranslations.composeCannotMessage.tr
                            : contact.isOnline
                            ? AppTranslations.chatOnlineNow.tr
                            : contact.lastSeen,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: !contact.canMessage
                              ? palette.mutedText
                              : contact.isOnline
                              ? MessengerDesign.online
                              : palette.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        contact.canMessage
                            ? Icons.chevron_right_rounded
                            : Icons.lock_outline_rounded,
                        color: palette.mutedText,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openContact(ChatContactModel contact) {
    if (!contact.canMessage) {
      Get.snackbar(
        AppTranslations.navContacts.tr,
        AppTranslations.composeCannotMessage.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (contact.conversationId <= 0) {
      _showComposeConversationSheet(
        context,
        widget.homeController,
        initialContact: contact,
      );
      return;
    }
    final conversation = ChatConversationModel(
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
    Get.to(
      () => ChatConversationPage(
        key: ValueKey('contact-chat-${contact.id}'),
        conversation: conversation,
      ),
    );
  }
}

class _GroupsTab extends StatefulWidget {
  const _GroupsTab({required this.homeController});

  final HomeController homeController;

  @override
  State<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<_GroupsTab> {
  int? _actingInvitationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final controller = Get.find<GroupsChatController>();
      controller.ensureLoaded(reason: 'tab_init');
      controller.loadPendingInvitations(showSpinner: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GroupsChatController>();
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.errorMessage.value.isNotEmpty &&
          controller.groups.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.groups_2_outlined,
                  size: 42,
                  color: palette.mutedText,
                ),
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

      final totalMembers = controller.groups.fold<int>(
        0,
        (total, group) => total + group.memberCount,
      );
      final unreadGroups = controller.groups
          .where((group) => group.unreadCount > 0)
          .length;
      final pendingInvitationsCount = controller.pendingInvitationsCount.value;

      return RefreshIndicator(
        onRefresh: () => _refresh(controller),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (controller.hasLoadedOnce &&
                controller.groups.isNotEmpty &&
                controller.hasMore &&
                notification.metrics.maxScrollExtent > 0 &&
                notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 120) {
              controller.loadMore();
            }
            return false;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            children: [
              _GroupsHeader(
                totalGroups: controller.groups.length,
                totalMembers: totalMembers,
                unreadGroups: unreadGroups,
                invitationsCount: pendingInvitationsCount,
                invitationsBusy: controller.isLoadingInvitations.value,
                onBack: () => widget.homeController.selectTab(0),
                onInvitations: () => _showInvitationsSheet(controller),
                onCreateGroup: () => _showCreateGroupSheet(context, controller),
              ),
              const SizedBox(height: 18),
              if (controller.groups.isEmpty)
                Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.40,
                      child: _TabPlaceholder(
                        icon: Icons.groups_2_outlined,
                        title: AppTranslations.groupsEmptyTitle.tr,
                        subtitle: AppTranslations.groupsEmptyBody.tr,
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            _showCreateGroupSheet(context, controller),
                        icon: const Icon(Icons.add_rounded, size: 19),
                        label: Text(AppTranslations.groupsCreate.tr),
                      ),
                    ),
                  ],
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppTranslations.groupsLatest.tr,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: palette.strongText,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _showCreateGroupSheet(context, controller),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(AppTranslations.groupsCreate.tr),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...controller.groups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _GroupChatTile(
                      group: group,
                      joinRequestsCount: controller.joinRequestsCountFor(
                        group.groupId,
                      ),
                    ),
                  ),
                ),
                if (controller.isLoadingMore.value)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Future<void> _showCreateGroupSheet(
    BuildContext context,
    GroupsChatController controller,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _CreateGroupSheet(controller: controller),
    );
  }

  Future<void> _showInvitationsSheet(GroupsChatController controller) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Obx(
          () => _GroupInvitationsSheet(
            invitations: controller.pendingInvitations.toList(),
            isLoading: controller.isLoadingInvitations.value,
            errorMessage: controller.invitationsError.value,
            actingInvitationId: _actingInvitationId,
            onRetry: controller.loadPendingInvitations,
            onAccept: (invitation) {
              Navigator.of(sheetContext).pop();
              _respondInvitation(controller, invitation, true);
            },
            onReject: (invitation) {
              Navigator.of(sheetContext).pop();
              _respondInvitation(controller, invitation, false);
            },
          ),
        );
      },
    );
  }

  Future<void> _refresh(GroupsChatController controller) async {
    await Future.wait([
      controller.load(),
      controller.loadPendingInvitations(showSpinner: false),
      controller.refreshJoinRequestCounts(),
    ]);
  }

  Future<void> _respondInvitation(
    GroupsChatController controller,
    GroupsChatInvitationModel invitation,
    bool accept,
  ) async {
    if (_actingInvitationId != null) {
      return;
    }

    setState(() => _actingInvitationId = invitation.invitationId);
    try {
      await controller.respondInvitation(
        invitation: invitation,
        accept: accept,
      );
      if (!mounted) {
        return;
      }
      Get.snackbar(
        accept
            ? AppTranslations.groupInvitationAccepted.tr
            : AppTranslations.groupInvitationRejected.tr,
        invitation.group.name,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        AppTranslations.groupInvitationUnableToUpdate.tr,
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _actingInvitationId = null);
      }
    }
  }
}

class _GroupsHeader extends StatelessWidget {
  const _GroupsHeader({
    required this.totalGroups,
    required this.totalMembers,
    required this.unreadGroups,
    required this.invitationsCount,
    required this.invitationsBusy,
    required this.onBack,
    required this.onInvitations,
    required this.onCreateGroup,
  });

  final int totalGroups;
  final int totalMembers;
  final int unreadGroups;
  final int invitationsCount;
  final bool invitationsBusy;
  final VoidCallback onBack;
  final VoidCallback onInvitations;
  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
      decoration: const BoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  AppTranslations.groupsTitle.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.strongText,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _HeroMetricPill(
                label: AppTranslations.groupsTotal.tr,
                value: '$totalGroups',
              ),
              const SizedBox(width: 8),
              _HeroIconButton(
                icon: Icons.notifications_active_outlined,
                message: AppTranslations.groupInvitationsTitle.tr,
                badgeCount: invitationsCount,
                busy: invitationsBusy,
                onPressed: onInvitations,
              ),
              const SizedBox(width: 8),
              _HeroIconButton(
                icon: Icons.add_rounded,
                message: AppTranslations.groupsCreate.tr,
                onPressed: onCreateGroup,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppTranslations.groupsSubtitle.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroMetricPill(
                label: AppTranslations.groupsMembers.tr,
                value: '$totalMembers',
              ),
              _HeroMetricPill(
                label: AppTranslations.groupsUnread.tr,
                value: '$unreadGroups',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupInvitationsSheet extends StatelessWidget {
  const _GroupInvitationsSheet({
    required this.invitations,
    required this.isLoading,
    required this.errorMessage,
    required this.actingInvitationId,
    required this.onRetry,
    required this.onAccept,
    required this.onReject,
  });

  final List<GroupsChatInvitationModel> invitations;
  final bool isLoading;
  final String errorMessage;
  final int? actingInvitationId;
  final VoidCallback onRetry;
  final ValueChanged<GroupsChatInvitationModel> onAccept;
  final ValueChanged<GroupsChatInvitationModel> onReject;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.mark_email_unread_rounded,
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppTranslations.groupInvitationsTitle.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: palette.strongText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.mutedText,
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(AppTranslations.retry.tr),
              ),
            ] else if (invitations.isEmpty) ...[
              const SizedBox(height: 18),
              Text(
                AppTranslations.groupInvitationsEmpty.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: invitations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final invitation = invitations[index];
                    return _GroupInvitationTile(
                      invitation: invitation,
                      isBusy: actingInvitationId == invitation.invitationId,
                      onAccept: () => onAccept(invitation),
                      onReject: () => onReject(invitation),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _GroupInvitationTile extends StatelessWidget {
  const _GroupInvitationTile({
    required this.invitation,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
  });

  final GroupsChatInvitationModel invitation;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);
    final actor = invitation.actorName.isEmpty
        ? AppTranslations.groupsMemberRole.tr
        : invitation.actorName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AvatarView(
          imageUrl: invitation.group.imageUrl,
          name: invitation.group.name,
          radius: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invitation.group.name.isEmpty
                    ? AppTranslations.groupsTitle.tr
                    : invitation.group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.strongText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                AppTranslations.groupInvitationFrom.trParams({'name': actor}),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.mutedText,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: isBusy ? null : onAccept,
                    icon: isBusy
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 17),
                    label: Text(AppTranslations.groupInvitationAccept.tr),
                  ),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onReject,
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: Text(AppTranslations.groupInvitationReject.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet({required this.controller});

  final GroupsChatController controller;

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.sectionBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.groups_2_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppTranslations.groupsCreateTitle.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: palette.strongText,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: palette.mutedText),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: AppTranslations.groupsName.tr,
                    hintText: AppTranslations.groupsNameHint.tr,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppTranslations.groupsNameRequired.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    labelText: AppTranslations.groupsDescription.tr,
                    hintText: AppTranslations.groupsDescriptionHint.tr,
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                Obx(() {
                  final isSubmitting = widget.controller.isCreatingGroup.value;
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isSubmitting ? null : _submit,
                      icon: isSubmitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.1,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(Icons.add_rounded, size: 19),
                      label: Text(AppTranslations.groupsCreate.tr),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final group = await widget.controller.createGroup(
        name: _nameController.text,
        description: _descriptionController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      Get.snackbar(
        AppTranslations.groupsCreated.tr,
        group.name,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      final message = widget.controller.errorMessage.value.trim();
      Get.snackbar(
        AppTranslations.groupsCreateFailed.tr,
        message.isEmpty ? AppTranslations.groupsCreateFailed.tr : message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _GroupChatTile extends StatelessWidget {
  const _GroupChatTile({required this.group, required this.joinRequestsCount});

  final GroupsChatGroupModel group;
  final int joinRequestsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _HomePalette.of(context);
    final preview = _groupPreviewText(group);

    return InkWell(
      onTap: () {
        GroupsChatLogger.log(
          'home',
          'openGroup groupId=${group.groupId} name="${group.name}" unread=${group.unreadCount}',
        );
        Get.to(() => GroupChatPage(group: group));
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _AvatarView(
                  imageUrl: group.imageUrl,
                  name: group.name,
                  radius: 24,
                ),
                PositionedDirectional(
                  bottom: -1,
                  end: -1,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.cardBackground,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.groups_2_rounded,
                      color: AppColors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name.isEmpty
                              ? AppTranslations.groupsTitle.tr
                              : group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.strongText,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (group.isMuted) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 15,
                          color: palette.mutedText,
                        ),
                      ],
                      if (!group.canSendMessages) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 15,
                          color: palette.mutedText,
                        ),
                      ],
                      if (joinRequestsCount > 0) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 15,
                          color: MessengerDesign.primary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: group.lastMessage == null
                          ? palette.mutedText.withValues(alpha: 0.78)
                          : palette.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  group.timeLabel.isEmpty ? '--:--' : group.timeLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (group.unreadCount > 0)
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${group.unreadCount}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: palette.mutedText.withValues(alpha: 0.55),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _groupPreviewText(GroupsChatGroupModel group) {
  final message = group.lastMessage;
  if (message == null) {
    return AppTranslations.groupsNoMessages.tr;
  }

  if (message.message.trim().isNotEmpty) {
    return message.previewText;
  }

  switch (message.messageType) {
    case 'image':
      return AppTranslations.groupsPhoto.tr;
    case 'video':
      return AppTranslations.groupsVideo.tr;
    case 'audio':
      return AppTranslations.groupsVoice.tr;
    case 'file':
      return AppTranslations.groupsFile.tr;
    default:
      return message.previewText.isEmpty
          ? AppTranslations.groupsNoMessages.tr
          : message.previewText;
  }
}

class _CallsTab extends StatelessWidget {
  const _CallsTab();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallsController>();
    final palette = _HomePalette.of(context);

    return Obx(() {
      final missedCount = controller.calls
          .where((call) => call.isMissedCall)
          .length;
      final subtitle = controller.calls.isEmpty
          ? AppTranslations.callsHeroSubtitle.tr
          : '${controller.calls.length} ${AppTranslations.callsTotal.tr}'
                '${missedCount > 0 ? ' • $missedCount ${AppTranslations.callsMissed.tr}' : ''}';

      if (controller.isLoading.value) {
        return Column(
          children: [
            MessengerPageTitle(
              title: AppTranslations.navCalls.tr,
              subtitle: AppTranslations.callsHeroSubtitle.tr,
            ),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        );
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return Column(
          children: [
            MessengerPageTitle(
              title: AppTranslations.navCalls.tr,
              subtitle: AppTranslations.callsHeroSubtitle.tr,
            ),
            Expanded(
              child: MessengerEmptyState(
                icon: Icons.call_outlined,
                title: AppTranslations.callsEmptyTitle.tr,
                message: controller.errorMessage.value,
                actionLabel: AppTranslations.retry.tr,
                onAction: controller.load,
              ),
            ),
          ],
        );
      }

      return Column(
        children: [
          MessengerPageTitle(
            title: AppTranslations.navCalls.tr,
            subtitle: subtitle,
          ),
          Expanded(
            child: controller.calls.isEmpty
                ? RefreshIndicator(
                    onRefresh: controller.load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.55,
                          child: MessengerEmptyState(
                            icon: Icons.call_outlined,
                            title: AppTranslations.callsEmptyTitle.tr,
                            message: AppTranslations.callsEmptyBody.tr,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: controller.load,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 120) {
                          controller.loadMore();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount:
                            controller.calls.length +
                            (controller.isLoadingMore.value ? 1 : 0),
                        separatorBuilder: (_, index) =>
                            index >= controller.calls.length - 1
                            ? const SizedBox.shrink()
                            : Divider(
                                height: 0.7,
                                indent: 60,
                                color: palette.sectionBorder,
                              ),
                        itemBuilder: (context, index) {
                          if (index >= controller.calls.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _CallHistoryTile(
                            call: controller.calls[index],
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

// Kept temporarily while connected-account controls move into SettingsContent.
// ignore: unused_element
class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.sessionController});

  final SessionController sessionController;

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);

    return Obx(() {
      if (profileController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (profileController.errorMessage.value.isNotEmpty &&
          profileController.accounts.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 42,
                  color: palette.mutedText,
                ),
                const SizedBox(height: 16),
                Text(
                  profileController.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: profileController.load,
                  child: Text(AppTranslations.retry.tr),
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: profileController.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            _ProfileHeaderCard(
              sessionController: sessionController,
              onOpenSettings: () => Get.to(() => const SettingsPage()),
              onAddAccount: profileController.canAddAccount.value
                  ? () => _showAddAccountDialog(context, profileController)
                  : null,
              isMasterAccount: profileController.isMasterAccount.value,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ProfileQuickActionTile(
                    icon: Icons.settings_outlined,
                    title: AppTranslations.profileManageSettings.tr,
                    subtitle: AppTranslations.profileQuickSettingsSubtitle.tr,
                    onTap: () => Get.to(() => const SettingsPage()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileQuickActionTile(
                    icon: Icons.person_add_alt_1_rounded,
                    title: AppTranslations.profileAddAccount.tr,
                    subtitle: profileController.canAddAccount.value
                        ? AppTranslations.profileConnectAnother.tr
                        : AppTranslations.profileAddAccountDisabled.tr,
                    enabled: profileController.canAddAccount.value,
                    onTap: profileController.canAddAccount.value
                        ? () =>
                              _showAddAccountDialog(context, profileController)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileSectionCard(
              title: AppTranslations.profileCurrentAccount.tr,
              eyebrow: AppTranslations.profileIdentityEyebrow.tr,
              trailing: _ProfileCountBadge(
                text: profileController.isMasterAccount.value
                    ? AppTranslations.profileAccountMaster.tr
                    : AppTranslations.profileAccountCurrent.tr,
              ),
              child: Column(
                children: [
                  _ProfileInfoRow(
                    icon: Icons.alternate_email_rounded,
                    label: AppTranslations.profileAccountUsername.tr,
                    value: sessionController.currentUserName.value.isEmpty
                        ? '-'
                        : sessionController.currentUserName.value,
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoRow(
                    icon: Icons.mail_outline_rounded,
                    label: AppTranslations.profileAccountEmail.tr,
                    value: sessionController.currentUserEmail.value.isEmpty
                        ? '-'
                        : sessionController.currentUserEmail.value,
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoRow(
                    icon: Icons.badge_outlined,
                    label: AppTranslations.profileAccountStatus.tr,
                    value: profileController.isMasterAccount.value
                        ? AppTranslations.profileAccountMaster.tr
                        : AppTranslations.profileAccountCurrent.tr,
                  ),
                  if (sessionController.isActiveTimelineBridgeSession) ...[
                    const SizedBox(height: 12),
                    _ProfileInfoRow(
                      icon: Icons.link_rounded,
                      label: AppTranslations.commonTimeline.tr,
                      value: AppTranslations.profileTimelineBridgeActive.tr,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            _ProfileSectionCard(
              title: AppTranslations.profileConnectedAccounts.tr,
              eyebrow: AppTranslations.profileSwitcherEyebrow.tr,
              trailing: _ProfileCountBadge(
                text: '${profileController.accounts.length}',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!profileController.switchAccountsEnabled.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProfileNoteBanner(
                        icon: Icons.info_outline_rounded,
                        text: AppTranslations.profileLinkedAccountsDisabled.tr,
                      ),
                    ),
                  if (profileController.canAddAccount.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ProfileInlineAction(
                        icon: Icons.add_rounded,
                        title: AppTranslations.profileAddAccount.tr,
                        subtitle:
                            AppTranslations.profileAttachAnotherAccount.tr,
                        onTap: profileController.isSubmitting.value
                            ? null
                            : () => _showAddAccountDialog(
                                context,
                                profileController,
                              ),
                      ),
                    ),
                  if (profileController.accounts.isEmpty)
                    Text(
                      AppTranslations.profileNoConnectedAccounts.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.mutedText,
                      ),
                    )
                  else
                    ...profileController.accounts.map(
                      (account) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ConnectedAccountTile(
                          account: account,
                          isSubmitting: profileController.isSubmitting.value,
                          onSwitch: account.switchable
                              ? () => _switchAccount(profileController, account)
                              : null,
                          onRemove: account.removable
                              ? () => _confirmRemoveAccount(
                                  context,
                                  profileController,
                                  account,
                                )
                              : null,
                          onRevoke: account.revokeAvailable
                              ? () => _confirmRevokeAccount(
                                  context,
                                  profileController,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _showAddAccountDialog(
    BuildContext context,
    ProfileController controller,
  ) async {
    final identifierController = TextEditingController();
    final passwordController = TextEditingController();

    final submitted =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(AppTranslations.profileAddAccountTitle.tr),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: identifierController,
                    decoration: InputDecoration(
                      labelText: AppTranslations.profileAddAccountIdentifier.tr,
                      hintText:
                          AppTranslations.profileAddAccountIdentifierHint.tr,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppTranslations.profileAddAccountPassword.tr,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(AppTranslations.profileAddAccountConfirm.tr),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!submitted) {
      return;
    }

    final identifier = identifierController.text.trim();
    final password = passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        AppTranslations.profileAccountEmptyField.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      await controller.addAccount(
        usernameEmail: identifier,
        password: password,
      );
      Get.snackbar(
        AppTranslations.profileAccountAdded.tr,
        AppTranslations.profileAddAccountSuccess.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _switchAccount(
    ProfileController controller,
    ConnectedAccountModel account,
  ) async {
    try {
      await controller.switchAccount(account);
    } catch (_) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _confirmRemoveAccount(
    BuildContext context,
    ProfileController controller,
    ConnectedAccountModel account,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(AppTranslations.profileRemoveAccountTitle.tr),
              content: Text(AppTranslations.profileRemoveAccountMessage.tr),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(AppTranslations.profileRemoveAccount.tr),
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
      await controller.removeAccount(account);
      Get.snackbar(
        AppTranslations.profileConnectedAccounts.tr,
        AppTranslations.profileRemoveAccountSuccess.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _confirmRevokeAccount(
    BuildContext context,
    ProfileController controller,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(AppTranslations.profileRevokeAccountTitle.tr),
              content: Text(AppTranslations.profileRevokeAccountMessage.tr),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(AppTranslations.profileRevokeAccount.tr),
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
      await controller.revokeCurrentConnection();
      Get.snackbar(
        AppTranslations.profileConnectedAccounts.tr,
        AppTranslations.profileRevokeAccountSuccess.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.sessionController,
    required this.onOpenSettings,
    required this.isMasterAccount,
    this.onAddAccount,
  });

  final SessionController sessionController;
  final VoidCallback onOpenSettings;
  final bool isMasterAccount;
  final VoidCallback? onAddAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _HomePalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.88),
            palette.heroAccent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
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
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: onOpenSettings,
                  icon: const Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (onAddAccount != null)
                FilledButton.tonalIcon(
                  onPressed: onAddAccount,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(AppTranslations.profileAddAccount.tr),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Obx(
            () => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: _AvatarView(
                    imageUrl: sessionController.currentUserPicture.value,
                    name: sessionController.currentUserName.value,
                    radius: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sessionController.currentUserName.value.isEmpty
                            ? AppTranslations.navProfile.tr
                            : sessionController.currentUserName.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sessionController.currentUserEmail.value.isEmpty
                            ? AppTranslations.profileNoEmailAttached.tr
                            : sessionController.currentUserEmail.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeroPill(
                            icon: Icons.verified_outlined,
                            label: isMasterAccount
                                ? AppTranslations.profileAccountMaster.tr
                                : AppTranslations.profileAccountCurrent.tr,
                          ),
                          if (sessionController.isActiveTimelineBridgeSession)
                            _HeroPill(
                              icon: Icons.link_rounded,
                              label: AppTranslations
                                  .profileTimelineBridgeActive
                                  .tr,
                            ),
                        ],
                      ),
                    ],
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

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.title,
    required this.child,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final Widget child;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.sectionBorder),
        boxShadow: [
          BoxShadow(
            color: palette.shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.mutedText,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: palette.strongText,
                  ),
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: palette.softSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 20, color: palette.strongText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.mutedText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.strongText,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConnectedAccountTile extends StatelessWidget {
  const _ConnectedAccountTile({
    required this.account,
    required this.isSubmitting,
    this.onSwitch,
    this.onRemove,
    this.onRevoke,
  });

  final ConnectedAccountModel account;
  final bool isSubmitting;
  final VoidCallback? onSwitch;
  final VoidCallback? onRemove;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: account.isCurrent
            ? palette.selectedAccountSurface
            : palette.softSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: account.isCurrent
              ? AppColors.primary.withValues(alpha: 0.28)
              : palette.sectionBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: account.isCurrent
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : Colors.transparent,
                    width: 1.6,
                  ),
                ),
                child: _AvatarView(
                  imageUrl: account.userPicture,
                  name: account.resolvedName,
                  radius: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.resolvedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.strongText,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${account.userName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                account.isCurrent
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: account.isCurrent
                    ? AppColors.primary
                    : palette.mutedText.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (account.isCurrent)
                _ProfileStatusChip(
                  label: AppTranslations.profileAccountCurrent.tr,
                ),
              if (account.isMaster)
                _ProfileStatusChip(
                  label: AppTranslations.profileAccountMaster.tr,
                  primary: false,
                ),
              if (!account.isCurrent && account.switchable)
                _ProfileStatusChip(
                  label: AppTranslations.profileReadyToSwitch.tr,
                  primary: false,
                ),
            ],
          ),
          if (onSwitch != null || onRemove != null || onRevoke != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onSwitch != null)
                  FilledButton(
                    onPressed: isSubmitting ? null : onSwitch,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Text(AppTranslations.profileSwitchAccount.tr),
                  ),
                if (onRemove != null)
                  FilledButton.tonal(
                    onPressed: isSubmitting ? null : onRemove,
                    child: Text(AppTranslations.profileRemoveAccount.tr),
                  ),
                if (onRevoke != null)
                  OutlinedButton(
                    onPressed: isSubmitting ? null : onRevoke,
                    child: Text(AppTranslations.profileRevokeAccount.tr),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileStatusChip extends StatelessWidget {
  const _ProfileStatusChip({required this.label, this.primary = true});

  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final color = primary ? AppColors.primary : palette.secondaryChipText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileQuickActionTile extends StatelessWidget {
  const _ProfileQuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.sectionBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.primary.withValues(alpha: 0.10)
                      : palette.softSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled ? AppColors.primary : palette.mutedText,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.strongText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.mutedText,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInlineAction extends StatelessWidget {
  const _ProfileInlineAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.inlineActionSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.strongText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: palette.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCountBadge extends StatelessWidget {
  const _ProfileCountBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.softSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: palette.strongText,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileNoteBanner extends StatelessWidget {
  const _ProfileNoteBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.searchBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: palette.mutedText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.strongText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _HomePalette.of(context);
    final technicalMessage = controller.backendMessage.value.trim();
    final hasTechnicalMessage = debug && technicalMessage.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.14),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.forum_outlined,
                            color: AppColors.primary,
                            size: 34,
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          right: 18,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    AppTranslations.homeChatsEmptyTitle.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppTranslations.homeChatsEmptyBody.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.55,
                      color: palette.mutedText,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _EmptyStatePill(
                        icon: Icons.edit_outlined,
                        label: AppTranslations.homeChatsEmptyAction.tr,
                      ),
                      _EmptyStatePill(
                        icon: Icons.photo_library_outlined,
                        label: AppTranslations.addStory.tr,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 220,
                    child: ElevatedButton.icon(
                      onPressed: () => _showComposeSheet(context, controller),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(AppTranslations.homeChatsEmptyAction.tr),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: controller.load,
                    child: Text(AppTranslations.retry.tr),
                  ),
                  if (hasTechnicalMessage) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.softSurface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        technicalMessage,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.mutedText,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showComposeSheet(
    BuildContext context,
    HomeController homeController,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComposeConversationSheet(homeController: homeController),
    );
  }
}

class _EmptyStatePill extends StatelessWidget {
  const _EmptyStatePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.softSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.strongText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.controller,
    required this.onCompose,
    required this.onGroups,
    required this.onProfile,
  });

  final SessionController controller;
  final VoidCallback onCompose;
  final VoidCallback onGroups;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final configuredName = AppRuntimeSettings.appName.trim();
    final brandName =
        configuredName.isEmpty || configuredName.toLowerCase() == 'messenger'
        ? 'M-Sngine'
        : configuredName;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                brandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: MessengerDesign.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            Obx(
              () => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onProfile,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _AvatarView(
                        imageUrl: controller.currentUserPicture.value,
                        name: controller.currentUserName.value,
                        radius: 19,
                      ),
                      PositionedDirectional(
                        end: -1,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: MessengerDesign.online,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: palette.pageBackground,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                AppTranslations.homeHeadline.tr,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: palette.strongText,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                ),
              ),
            ),
            _HeaderShortcutButton(
              icon: Icons.groups_2_outlined,
              label: AppTranslations.groupsTitle.tr,
              onTap: onGroups,
            ),
            const SizedBox(width: 9),
            Material(
              color: MessengerDesign.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onCompose,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 27),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderShortcutButton extends StatelessWidget {
  const _HeaderShortcutButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);

    return Material(
      color: palette.inlineActionSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(11, 9, 13, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: MessengerDesign.primary, size: 19),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.strongText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.controller});

  final HomeController controller;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.searchQuery.value,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);

    return Obx(
      () => Container(
        height: 42,
        decoration: BoxDecoration(
          color: palette.searchBackground,
          borderRadius: BorderRadius.circular(22),
        ),
        child: TextField(
          controller: _textController,
          onChanged: widget.controller.updateSearchQuery,
          decoration: InputDecoration(
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: AppTranslations.homeSearchHint.tr,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.mutedText,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: palette.mutedText,
              size: 19,
            ),
            suffixIcon: widget.controller.isSearchActive
                ? IconButton(
                    onPressed: () {
                      _textController.clear();
                      widget.controller.clearSearchQuery();
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: palette.mutedText,
                      size: 18,
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

class _LiveChatRow extends StatelessWidget {
  const _LiveChatRow({required this.chat, required this.homeController});

  final ChatConversationModel chat;
  final HomeController homeController;

  Future<void> _openConversation(BuildContext context) async {
    Get.to(
      () => ChatConversationPage(
        key: ValueKey('chat-${chat.id}-${chat.targetUserId}'),
        conversation: chat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _HomePalette.of(context);
    final conversationId = int.tryParse(chat.id) ?? 0;

    return Dismissible(
      key: ValueKey('chat-swipe-${chat.id}'),
      direction: conversationId == 0
          ? DismissDirection.none
          : DismissDirection.horizontal,
      background: _ChatSwipeActionBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.primary,
        icon: chat.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
        label: chat.isPinned
            ? AppTranslations.chatUnpin.tr
            : AppTranslations.chatPin.tr,
      ),
      secondaryBackground: _ChatSwipeActionBackground(
        alignment: Alignment.centerRight,
        color: Color(0xFFE45454),
        icon: Icons.delete_outline_rounded,
        label: AppTranslations.chatDeleteConfirm.tr,
      ),
      confirmDismiss: (direction) async {
        if (conversationId == 0) {
          return false;
        }
        if (direction == DismissDirection.startToEnd) {
          try {
            await homeController.togglePinnedConversation(
              conversationId: conversationId,
            );
            Get.snackbar(
              AppTranslations.chatInfoTitle.tr,
              chat.isPinned
                  ? AppTranslations.chatConversationUnpinned.tr
                  : AppTranslations.chatConversationPinned.tr,
              snackPosition: SnackPosition.BOTTOM,
            );
          } catch (error) {
            Get.snackbar(
              AppTranslations.loginFailed.tr,
              error.toString(),
              snackPosition: SnackPosition.BOTTOM,
            );
          }
          return false;
        }
        if (direction == DismissDirection.endToStart) {
          return _confirmDelete(context, conversationId);
        }
        return false;
      },
      child: InkWell(
        onTap: () => _openConversation(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.all(chat.unreadCount > 0 ? 2 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: chat.unreadCount > 0
                          ? Border.all(
                              color: MessengerDesign.primary,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: _AvatarView(
                      imageUrl: chat.avatarUrl,
                      name: chat.title,
                      radius: chat.unreadCount > 0 ? 22 : 24,
                    ),
                  ),
                  if (chat.isOnline)
                    PositionedDirectional(
                      bottom: 1,
                      end: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: MessengerDesign.online,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: palette.cardBackground,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.title.isEmpty
                                ? AppTranslations.commonConversation.tr
                                : chat.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.strongText,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (chat.isPinned) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.push_pin_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ],
                        if (chat.isMuted) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 15,
                            color: palette.mutedText,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.preview.isEmpty ? '-' : chat.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: chat.isTyping
                            ? MessengerDesign.primary
                            : palette.mutedText,
                        fontSize: 13.5,
                        fontWeight: chat.isTyping
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    chat.timeLabel.isEmpty ? '--:--' : chat.timeLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (chat.unreadCount > 0)
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 21,
                        minHeight: 21,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: MessengerDesign.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${chat.unreadCount}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 21),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, int conversationId) async {
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
      return false;
    }

    try {
      await homeController.deleteConversation(conversationId: conversationId);
      Get.snackbar(
        AppTranslations.chatInfoTitle.tr,
        AppTranslations.chatDeleted.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (error) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}

class _ChatSwipeActionBackground extends StatelessWidget {
  const _ChatSwipeActionBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: alignment,
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (alignment == Alignment.centerRight) const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (alignment == Alignment.centerLeft) const Spacer(),
        ],
      ),
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  const _CallHistoryTile({required this.call});

  final ChatCallModel call;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _HomePalette.of(context);
    final name = call.displayName;
    final subtitle = _buildSubtitle();
    final conversation = ChatConversationModel(
      id: '0',
      title: name,
      preview: '',
      timeLabel: call.timeAgo,
      avatarUrl: call.displayPicture,
      isOnline: false,
      isTyping: false,
      unreadCount: 0,
      isSeen: true,
      isPinned: false,
      isMuted: false,
      targetUserId: call.counterparty?.userId ?? 0,
    );

    return InkWell(
      onTap: conversation.targetUserId == 0
          ? null
          : () => Get.to(
              () => ChatConversationPage(
                key: ValueKey(
                  'call-chat-${conversation.id}-${conversation.targetUserId}',
                ),
                conversation: conversation,
              ),
            ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _AvatarView(
                  imageUrl: call.displayPicture,
                  name: name,
                  radius: 25,
                ),
                PositionedDirectional(
                  bottom: -2,
                  end: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: call.isMissedCall
                          ? const Color(0xFFFFEEF1)
                          : palette.softSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.cardBackground,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      call.isVideoCall
                          ? Icons.videocam_rounded
                          : Icons.call_rounded,
                      size: 13,
                      color: call.isMissedCall
                          ? const Color(0xFFE05454)
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name.isEmpty ? 'Call' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.strongText,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _CallTypeBadge(call: call),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        _subtitleIcon(),
                        size: 15,
                        color: call.isMissedCall
                            ? const Color(0xFFE05454)
                            : palette.mutedText,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: call.isMissedCall
                                ? const Color(0xFFE05454)
                                : palette.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  call.timeAgo.isNotEmpty ? call.timeAgo : call.time,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: palette.mutedText.withValues(alpha: 0.75),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _subtitleIcon() {
    if (call.isMissedCall) {
      return Icons.call_missed_rounded;
    }
    if (call.answered) {
      return Icons.call_received_rounded;
    }
    if (call.declined) {
      return Icons.call_end_rounded;
    }
    return call.isIngoing ? Icons.south_west_rounded : Icons.north_east_rounded;
  }

  String _buildSubtitle() {
    final direction = call.isIngoing
        ? AppTranslations.callsIncoming.tr
        : AppTranslations.callsOutgoing.tr;
    final type = call.isVideoCall
        ? AppTranslations.callVideo.tr
        : AppTranslations.callVoice.tr;

    if (call.isMissedCall) {
      return '${AppTranslations.callsMissed.tr} • $type';
    }
    if (call.declined) {
      return '${AppTranslations.callsDeclined.tr} • $direction';
    }
    if (call.answered) {
      return '${AppTranslations.callsAnswered.tr} • $direction • $type';
    }
    return '$direction • $type';
  }
}

// ignore: unused_element
class _CallsHeroSection extends StatelessWidget {
  const _CallsHeroSection({
    required this.totalCalls,
    required this.missedCalls,
    required this.videoCalls,
    required this.answeredCalls,
  });

  final int totalCalls;
  final int missedCalls;
  final int videoCalls;
  final int answeredCalls;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.9),
            palette.heroAccent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.call_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppTranslations.navCalls.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _HeroMetricPill(
                label: AppTranslations.callsTotal.tr,
                value: '$totalCalls',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppTranslations.callsHeroSubtitle.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.76),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroMetricPill(
                label: AppTranslations.callsMissed.tr,
                value: '$missedCalls',
              ),
              _HeroMetricPill(
                label: AppTranslations.callsAnswered.tr,
                value: '$answeredCalls',
              ),
              _HeroMetricPill(
                label: AppTranslations.callVideo.tr,
                value: '$videoCalls',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _CallsSummaryRow extends StatelessWidget {
  const _CallsSummaryRow({
    required this.totalCalls,
    required this.missedCalls,
    required this.videoCalls,
  });

  final int totalCalls;
  final int missedCalls;
  final int videoCalls;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CallsStatCard(
            icon: Icons.history_rounded,
            title: AppTranslations.callsAll.tr,
            value: '$totalCalls',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CallsStatCard(
            icon: Icons.call_missed_outgoing_rounded,
            title: AppTranslations.callsMissed.tr,
            value: '$missedCalls',
            accentColor: const Color(0xFFE05454),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CallsStatCard(
            icon: Icons.videocam_rounded,
            title: AppTranslations.callVideo.tr,
            value: '$videoCalls',
          ),
        ),
      ],
    );
  }
}

class _CallsStatCard extends StatelessWidget {
  const _CallsStatCard({
    required this.icon,
    required this.title,
    required this.value,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final theme = Theme.of(context);
    final resolvedAccentColor = accentColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.sectionBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: resolvedAccentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 18, color: resolvedAccentColor),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: palette.strongText,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallTypeBadge extends StatelessWidget {
  const _CallTypeBadge({required this.call});

  final ChatCallModel call;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final color = call.isMissedCall
        ? const Color(0xFFE05454)
        : call.isVideoCall
        ? AppColors.primary
        : palette.secondaryChipText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        call.isVideoCall
            ? AppTranslations.callVideo.tr
            : AppTranslations.callVoice.tr,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroMetricPill extends StatelessWidget {
  const _HeroMetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.inlineActionSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MessengerDesign.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.message,
    required this.onPressed,
    this.badgeCount = 0,
    this.busy = false,
  });

  final IconData icon;
  final String message;
  final VoidCallback onPressed;
  final int badgeCount;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    return Tooltip(
      message: message,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.inlineActionSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: onPressed,
              icon: busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: MessengerDesign.primary,
                      ),
                    )
                  : Icon(icon, color: palette.strongText, size: 23),
            ),
          ),
          if (badgeCount > 0)
            PositionedDirectional(
              top: -5,
              end: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: MessengerDesign.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _showComposeConversationSheet(
  BuildContext context,
  HomeController homeController, {
  ChatContactModel? initialContact,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => ComposeConversationSheet(
      homeController: homeController,
      initialContact: initialContact,
    ),
  );
}

class _BottomMessengerBar extends StatelessWidget {
  const _BottomMessengerBar({required this.homeController});

  final HomeController homeController;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);

    return ColoredBox(
      color: palette.cardBackground,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 4),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            border: Border(
              top: BorderSide(color: palette.sectionBorder, width: 1),
            ),
          ),
          child: Obx(() {
            final hasMissedCalls = Get.find<CallsController>().calls.any(
              (call) => call.isMissedCall,
            );
            return Row(
              children: [
                Expanded(
                  child: _NavIcon(
                    assetName: 'assets/icons/nav/chats.svg',
                    label: AppTranslations.navChats.tr,
                    selected: homeController.currentTabIndex.value == 0,
                    onTap: () => homeController.selectTab(0),
                  ),
                ),
                Expanded(
                  child: _NavIcon(
                    assetName: 'assets/icons/nav/calls.svg',
                    label: AppTranslations.navCalls.tr,
                    selected: homeController.currentTabIndex.value == 2,
                    badge: hasMissedCalls,
                    onTap: () => homeController.selectTab(2),
                  ),
                ),
                Expanded(
                  child: _NavIcon(
                    assetName: 'assets/icons/nav/profile.svg',
                    label: AppTranslations.navContacts.tr,
                    selected: homeController.currentTabIndex.value == 1,
                    onTap: () => homeController.selectTab(1),
                  ),
                ),
                Expanded(
                  child: _NavIcon(
                    assetName: 'assets/icons/nav/settings.svg',
                    label: AppTranslations.navSettings.tr,
                    selected: homeController.currentTabIndex.value == 3,
                    onTap: () => homeController.selectTab(3),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.assetName,
    required this.label,
    required this.selected,
    this.badge = false,
    this.onTap,
  });

  final String assetName;
  final String label;
  final bool selected;
  final bool badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final color = selected ? MessengerDesign.primary : palette.mutedText;

    return SizedBox(
      height: 58,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 34,
                height: 30,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: selected
                              ? MessengerDesign.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          assetName,
                          package: 'chat_module',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            selected ? Colors.white : color,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    if (badge)
                      PositionedDirectional(
                        top: 1,
                        end: 2,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: MessengerDesign.destructive,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarView extends StatelessWidget {
  const _AvatarView({
    required this.imageUrl,
    required this.name,
    required this.radius,
  });

  final String imageUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(name);
    final size = radius * 2;

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
          placeholderFadeInDuration: Duration.zero,
          errorWidget: (_, _, _) {
            return _AvatarFallback(initials: initials, size: size);
          },
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
      return 'M';
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
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: MessengerDesign.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HomePalette {
  const _HomePalette({
    required this.pageBackground,
    required this.cardBackground,
    required this.searchBackground,
    required this.softSurface,
    required this.inlineActionSurface,
    required this.selectedAccountSurface,
    required this.strongText,
    required this.mutedText,
    required this.secondaryChipText,
    required this.sectionBorder,
    required this.shadowColor,
    required this.heroAccent,
  });

  final Color pageBackground;
  final Color cardBackground;
  final Color searchBackground;
  final Color softSurface;
  final Color inlineActionSurface;
  final Color selectedAccountSurface;
  final Color strongText;
  final Color mutedText;
  final Color secondaryChipText;
  final Color sectionBorder;
  final Color shadowColor;
  final Color heroAccent;

  static _HomePalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return _HomePalette(
        pageBackground: MessengerDesign.darkCanvas,
        cardBackground: MessengerDesign.darkSurface,
        searchBackground: MessengerDesign.darkSoftSurface,
        softSurface: MessengerDesign.darkSoftSurface,
        inlineActionSurface: MessengerDesign.darkSoftSurface,
        selectedAccountSurface: Color(0xFF2A2750),
        strongText: MessengerDesign.darkInk,
        mutedText: MessengerDesign.darkMuted,
        secondaryChipText: Color(0xFFC7C8D1),
        sectionBorder: MessengerDesign.darkDivider,
        shadowColor: Color(0x40000000),
        heroAccent: MessengerDesign.primaryPressed,
      );
    }

    return _HomePalette(
      pageBackground: MessengerDesign.canvas,
      cardBackground: MessengerDesign.canvas,
      searchBackground: MessengerDesign.softSurface,
      softSurface: Color(0xFFF7F7FA),
      inlineActionSurface: Color(0xFFF4F3FF),
      selectedAccountSurface: Color(0xFFF4F3FF),
      strongText: MessengerDesign.ink,
      mutedText: MessengerDesign.muted,
      secondaryChipText: Color(0xFF61687D),
      sectionBorder: MessengerDesign.divider,
      shadowColor: Color(0x0A11152F),
      heroAccent: MessengerDesign.ink,
    );
  }
}
