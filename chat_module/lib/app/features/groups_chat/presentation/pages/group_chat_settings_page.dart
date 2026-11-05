import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../chat/data/models/chat_contacts_response.dart';
import '../../../chat/data/models/chat_report_models.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../data/models/groups_chat_models.dart';
import '../../data/services/groups_chat_service.dart';
import '../controllers/groups_chat_controller.dart';

enum _MemberAction { promote, demote, permissions, mute, unmute, remove }

class GroupChatSettingsResult {
  const GroupChatSettingsResult._({this.group, this.left = false});

  const GroupChatSettingsResult.updated(GroupsChatGroupModel group)
    : this._(group: group);

  const GroupChatSettingsResult.left() : this._(left: true);

  final GroupsChatGroupModel? group;
  final bool left;
}

class GroupChatSettingsPage extends StatefulWidget {
  const GroupChatSettingsPage({super.key, required this.initialGroup});

  final GroupsChatGroupModel initialGroup;

  @override
  State<GroupChatSettingsPage> createState() => _GroupChatSettingsPageState();
}

class _GroupChatSettingsPageState extends State<GroupChatSettingsPage> {
  late GroupsChatGroupModel _group;
  final _groupsService = Get.find<GroupsChatService>();
  final _preferences = Get.find<ChatAppPreferences>();
  final _joinRequests = <GroupsChatInvitationModel>[];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLeaving = false;
  bool _isDeleting = false;
  bool _isTogglingMute = false;
  bool _isRegeneratingJoinLink = false;
  int? _actingJoinRequestId;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _group = widget.initialGroup;
    _loadDetails();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _GroupSettingsPalette.of(context);

    return PopScope<GroupChatSettingsResult>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(GroupChatSettingsResult.updated(_group));
      },
      child: Scaffold(
        backgroundColor: palette.pageBackground,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: palette.pageBackground,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(GroupChatSettingsResult.updated(_group)),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(AppTranslations.groupDetailsTitle.tr),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => _loadDetails(showSpinner: false),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  children: [
                    if (_errorMessage.isNotEmpty)
                      _ErrorPanel(
                        message: _errorMessage,
                        onRetry: _loadDetails,
                      ),
                    _GroupHeroPanel(
                      group: _group,
                      palette: palette,
                      onEdit: _group.canEditGroup ? _showEditGroupSheet : null,
                    ),
                    const SizedBox(height: 14),
                    _QuickActionsPanel(
                      group: _group,
                      palette: palette,
                      isTogglingMute: _isTogglingMute,
                      onMembers: _group.canViewMembers
                          ? _openMembersPage
                          : null,
                      onCopyLink: _group.canCopyJoinLink ? _copyJoinLink : null,
                      isRegeneratingJoinLink: _isRegeneratingJoinLink,
                      onRegenerateJoinLink: _group.canManageJoinLink
                          ? _confirmRegenerateJoinLink
                          : null,
                      joinRequestsCount: _joinRequests.length,
                      onJoinRequests: _group.canManageMembers
                          ? _showJoinRequestsSheet
                          : null,
                      onToggleMute: _toggleNotifications,
                    ),
                    if (_group.canManageAdminPermissions) ...[
                      const SizedBox(height: 14),
                      _PermissionsPanel(
                        group: _group,
                        palette: palette,
                        isSaving: _isSaving,
                        onMessagePermissionChanged: (value) =>
                            _updatePermissions(messagePermission: value),
                        onMemberListPermissionChanged: (value) =>
                            _updatePermissions(memberListPermission: value),
                        onReactionViewPermissionChanged: (value) =>
                            _updatePermissions(reactionViewPermission: value),
                        onJoinLinkPermissionChanged: (value) =>
                            _updatePermissions(joinLinkPermission: value),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _ReportGroupPanel(
                      group: _group,
                      palette: palette,
                      onReport: _showReportGroupSheet,
                    ),
                    const SizedBox(height: 14),
                    _LeaveGroupPanel(
                      group: _group,
                      palette: palette,
                      isLeaving: _isLeaving,
                      isDeleting: _isDeleting,
                      canDelete: _canDeleteGroup,
                      onLeave: _leaveGroup,
                      onDelete: _deleteGroup,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  bool get _canDeleteGroup {
    final currentUserId = _preferences.getUserId() ?? 0;
    return currentUserId > 0 && _group.createdBy == currentUserId;
  }

  Future<void> _loadDetails({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final group = await _groupsService.fetchGroupDetails(
        groupId: _group.groupId,
      );
      final joinRequests = group.canManageMembers
          ? await _groupsService.fetchJoinRequests(groupId: group.groupId)
          : null;
      final joinRequestsCount = joinRequests == null
          ? 0
          : joinRequests.count > joinRequests.items.length
          ? joinRequests.count
          : joinRequests.items.length;
      if (!mounted) {
        return;
      }
      setState(() {
        _group = group;
        _joinRequests
          ..clear()
          ..addAll(joinRequests?.items ?? const []);
        _errorMessage = '';
        _isLoading = false;
      });
      _syncGroup(group);
      _syncJoinRequestsCount(group.groupId, joinRequestsCount);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().trim().isEmpty
            ? AppTranslations.groupDetailsUnableToLoad.tr
            : error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditGroupSheet() async {
    final updated = await showModalBottomSheet<GroupsChatGroupModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _EditGroupSheet(group: _group),
    );
    if (updated == null || !mounted) {
      return;
    }
    setState(() => _group = updated);
    _syncGroup(updated);
    Get.snackbar(
      AppTranslations.groupDetailsSaved.tr,
      updated.name,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _openMembersPage() async {
    final updated = await Get.to<GroupsChatGroupModel>(
      () => _GroupMembersPage(initialGroup: _group),
    );
    if (updated == null || !mounted) {
      return;
    }
    setState(() => _group = updated);
    _syncGroup(updated);
  }

  Future<void> _showJoinRequestsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _JoinRequestsSheet(
        requests: _joinRequests,
        actingRequestId: _actingJoinRequestId,
        isSaving: _isSaving,
        onApprove: (request) {
          Navigator.of(sheetContext).pop();
          _respondJoinRequest(request, true);
        },
        onReject: (request) {
          Navigator.of(sheetContext).pop();
          _respondJoinRequest(request, false);
        },
      ),
    );
  }

  Future<void> _showReportGroupSheet() async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ReportGroupSheet(group: _group),
    );
    if (message == null || !mounted) {
      return;
    }
    Get.snackbar(
      AppTranslations.groupReportSubmitted.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _toggleNotifications() async {
    if (_isTogglingMute) {
      return;
    }
    setState(() => _isTogglingMute = true);
    try {
      final preferences = _group.isMuted
          ? await _groupsService.unmuteNotifications(groupId: _group.groupId)
          : await _groupsService.muteNotifications(groupId: _group.groupId);
      final updated = _group.copyWith(preferences: preferences);
      if (!mounted) {
        return;
      }
      setState(() => _group = updated);
      _syncGroup(updated);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isTogglingMute = false);
      }
    }
  }

  Future<void> _copyJoinLink() async {
    final link = _group.joinLink.trim();
    if (link.isEmpty) {
      _showError(AppTranslations.groupDetailsUnableToLoad.tr);
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    Get.snackbar(
      AppTranslations.groupDetailsLinkCopied.tr,
      link,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _confirmRegenerateJoinLink() async {
    if (_isRegeneratingJoinLink) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.groupDetailsChangeLink.tr),
        content: Text(AppTranslations.groupDetailsChangeLinkConfirmBody.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppTranslations.groupDetailsChangeLink.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await _regenerateJoinLink();
  }

  Future<void> _regenerateJoinLink() async {
    if (_isRegeneratingJoinLink) {
      return;
    }
    setState(() => _isRegeneratingJoinLink = true);
    try {
      final updated = await _groupsService.regenerateJoinLink(
        groupId: _group.groupId,
      );
      if (!mounted) {
        return;
      }
      setState(() => _group = updated);
      _syncGroup(updated);
      Get.snackbar(
        AppTranslations.groupDetailsLinkChanged.tr,
        updated.joinLink,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isRegeneratingJoinLink = false);
      }
    }
  }

  Future<void> _updatePermissions({
    String? messagePermission,
    String? editPermission,
    String? memberListPermission,
    String? reactionViewPermission,
    String? joinLinkPermission,
  }) async {
    if (_isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = await _groupsService.updatePermissions(
        groupId: _group.groupId,
        messagePermission: messagePermission,
        editPermission: editPermission,
        memberListPermission: memberListPermission,
        reactionViewPermission: reactionViewPermission,
        joinLinkPermission: joinLinkPermission,
      );
      if (!mounted) {
        return;
      }
      setState(() => _group = updated);
      _syncGroup(updated);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _respondJoinRequest(
    GroupsChatInvitationModel request,
    bool approve,
  ) async {
    if (_isSaving || _actingJoinRequestId != null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _actingJoinRequestId = request.invitationId;
    });
    try {
      final result = approve
          ? await _groupsService.approveJoinRequest(
              invitationId: request.invitationId,
            )
          : await _groupsService.rejectJoinRequest(
              invitationId: request.invitationId,
            );
      if (!mounted) {
        return;
      }
      setState(() {
        _joinRequests.removeWhere(
          (item) => item.invitationId == request.invitationId,
        );
        if (approve && result.group != null) {
          _group = result.group!;
        }
      });
      _syncJoinRequestsCount(_group.groupId, _joinRequests.length);
      if (approve && result.group != null) {
        _syncGroup(result.group!);
      }
      Get.snackbar(
        approve
            ? AppTranslations.groupJoinRequestsApproved.tr
            : AppTranslations.groupJoinRequestsRejected.tr,
        request.actorName,
        snackPosition: SnackPosition.BOTTOM,
      );
      if (approve) {
        await _loadDetails(showSpinner: false);
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _actingJoinRequestId = null;
        });
      }
    }
  }

  Future<void> _leaveGroup() async {
    if (_isLeaving || _isSaving) {
      return;
    }
    final confirmed = await _confirmLeaveGroup();
    if (confirmed != true) {
      return;
    }

    setState(() => _isLeaving = true);
    try {
      await _groupsService.leaveGroup(groupId: _group.groupId);
      _removeGroupFromList(_group.groupId);
      if (!mounted) {
        return;
      }
      Get.snackbar(
        AppTranslations.groupDetailsLeftGroup.tr,
        _group.name,
        snackPosition: SnackPosition.BOTTOM,
      );
      Navigator.of(context).pop(const GroupChatSettingsResult.left());
    } catch (error) {
      _showLeaveError(error);
    } finally {
      if (mounted) {
        setState(() => _isLeaving = false);
      }
    }
  }

  Future<void> _deleteGroup() async {
    if (_isDeleting || _isLeaving || _isSaving || !_canDeleteGroup) {
      return;
    }
    final confirmed = await _confirmDeleteGroup();
    if (confirmed != true) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await _groupsService.deleteGroup(groupId: _group.groupId);
      _removeGroupFromList(_group.groupId);
      if (!mounted) {
        return;
      }
      Get.snackbar(
        AppTranslations.groupDetailsDeletedGroup.tr,
        _group.name,
        snackPosition: SnackPosition.BOTTOM,
      );
      Navigator.of(context).pop(const GroupChatSettingsResult.left());
    } catch (error) {
      Get.snackbar(
        AppTranslations.groupDetailsUnableToDelete.tr,
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<bool?> _confirmLeaveGroup() {
    final body = _group.isOwner
        ? AppTranslations.groupDetailsConfirmLeaveOwnerBody.tr
        : AppTranslations.groupDetailsConfirmLeaveBody.tr;
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(AppTranslations.groupDetailsConfirmLeaveTitle.tr),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(AppTranslations.settingsLogoutCancel.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(AppTranslations.groupDetailsLeaveGroupAction.tr),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDeleteGroup() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppTranslations.groupDetailsConfirmDeleteTitle.tr),
        content: Text(AppTranslations.groupDetailsConfirmDeleteBody.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppTranslations.settingsLogoutCancel.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC0394B),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppTranslations.groupDetailsDeleteGroupAction.tr),
          ),
        ],
      ),
    );
  }

  void _syncGroup(GroupsChatGroupModel group) {
    if (Get.isRegistered<GroupsChatController>()) {
      Get.find<GroupsChatController>().upsertGroup(group);
    }
  }

  void _syncJoinRequestsCount(int groupId, int count) {
    if (Get.isRegistered<GroupsChatController>()) {
      Get.find<GroupsChatController>().setJoinRequestsCountFor(groupId, count);
    }
  }

  void _removeGroupFromList(int groupId) {
    if (Get.isRegistered<GroupsChatController>()) {
      Get.find<GroupsChatController>().removeGroup(groupId);
    }
  }

  void _showError(Object error) {
    Get.snackbar(
      AppTranslations.groupDetailsUnableToSave.tr,
      error.toString(),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showLeaveError(Object error) {
    Get.snackbar(
      AppTranslations.groupDetailsUnableToLeave.tr,
      error.toString(),
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class _GroupHeroPanel extends StatelessWidget {
  const _GroupHeroPanel({
    required this.group,
    required this.palette,
    required this.onEdit,
  });

  final GroupsChatGroupModel group;
  final _GroupSettingsPalette palette;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = group.description.trim().isEmpty
        ? AppTranslations.groupDetailsNoDescription.tr
        : group.description.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: [
          _GroupAvatar(imageUrl: group.imageUrl, name: group.name, size: 88),
          const SizedBox(height: 14),
          Text(
            group.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: palette.strongText,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedText,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MetricPill(
                icon: Icons.groups_2_rounded,
                label:
                    '${group.memberCount} ${AppTranslations.groupsMembers.tr}',
                palette: palette,
              ),
              const SizedBox(width: 8),
              _MetricPill(
                icon: Icons.admin_panel_settings_outlined,
                label: _roleLabel(group.role),
                palette: palette,
              ),
            ],
          ),
          if (onEdit != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(AppTranslations.groupDetailsEditInfo.tr),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({
    required this.group,
    required this.palette,
    required this.isTogglingMute,
    required this.onMembers,
    required this.onCopyLink,
    required this.isRegeneratingJoinLink,
    required this.onRegenerateJoinLink,
    required this.joinRequestsCount,
    required this.onJoinRequests,
    required this.onToggleMute,
  });

  final GroupsChatGroupModel group;
  final _GroupSettingsPalette palette;
  final bool isTogglingMute;
  final VoidCallback? onMembers;
  final VoidCallback? onCopyLink;
  final bool isRegeneratingJoinLink;
  final VoidCallback? onRegenerateJoinLink;
  final int joinRequestsCount;
  final VoidCallback? onJoinRequests;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      title: AppTranslations.settingsTitle.tr,
      icon: Icons.tune_outlined,
      palette: palette,
      child: Column(
        children: [
          _SettingsRow(
            icon: group.isMuted
                ? Icons.notifications_off_outlined
                : Icons.notifications_none_rounded,
            title: AppTranslations.groupDetailsMuteNotifications.tr,
            subtitle: group.isMuted
                ? AppTranslations.groupDetailsMutedSubtitle.tr
                : AppTranslations.groupDetailsUnmutedSubtitle.tr,
            palette: palette,
            busy: isTogglingMute,
            trailing: Switch(
              value: group.isMuted,
              onChanged: isTogglingMute ? null : (_) => onToggleMute(),
            ),
            onTap: isTogglingMute ? null : onToggleMute,
          ),
          if (onMembers != null) ...[
            _SettingsDivider(palette: palette),
            _SettingsRow(
              icon: Icons.groups_2_outlined,
              title: AppTranslations.groupDetailsMembersTitle.tr,
              subtitle:
                  '${group.memberCount} ${AppTranslations.groupsMembers.tr}',
              palette: palette,
              onTap: onMembers,
            ),
          ],
          if (onCopyLink != null) ...[
            _SettingsDivider(palette: palette),
            _SettingsRow(
              icon: Icons.link_rounded,
              title: AppTranslations.groupDetailsCopyLink.tr,
              palette: palette,
              onTap: onCopyLink,
            ),
          ],
          if (onRegenerateJoinLink != null) ...[
            _SettingsDivider(palette: palette),
            _SettingsRow(
              icon: Icons.sync_rounded,
              title: AppTranslations.groupDetailsChangeLink.tr,
              subtitle: AppTranslations.groupDetailsChangeLinkSubtitle.tr,
              palette: palette,
              busy: isRegeneratingJoinLink,
              onTap: isRegeneratingJoinLink ? null : onRegenerateJoinLink,
            ),
          ],
          if (onJoinRequests != null) ...[
            _SettingsDivider(palette: palette),
            _SettingsRow(
              icon: Icons.person_search_outlined,
              title: AppTranslations.groupJoinRequestsTitle.tr,
              subtitle: joinRequestsCount > 0
                  ? AppTranslations.groupJoinRequestsPending.tr
                  : AppTranslations.groupJoinRequestsEmpty.tr,
              palette: palette,
              badgeCount: joinRequestsCount,
              onTap: onJoinRequests,
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionsPanel extends StatelessWidget {
  const _PermissionsPanel({
    required this.group,
    required this.palette,
    required this.isSaving,
    required this.onMessagePermissionChanged,
    required this.onMemberListPermissionChanged,
    required this.onReactionViewPermissionChanged,
    required this.onJoinLinkPermissionChanged,
  });

  final GroupsChatGroupModel group;
  final _GroupSettingsPalette palette;
  final bool isSaving;
  final ValueChanged<String> onMessagePermissionChanged;
  final ValueChanged<String> onMemberListPermissionChanged;
  final ValueChanged<String> onReactionViewPermissionChanged;
  final ValueChanged<String> onJoinLinkPermissionChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      title: AppTranslations.groupDetailsPermissions.tr,
      icon: Icons.tune_rounded,
      palette: palette,
      child: Column(
        children: [
          _PermissionSwitchTile(
            enabled: group.messagePermission == 'members',
            enabledIcon: Icons.chat_bubble_outline_rounded,
            disabledIcon: Icons.lock_outline_rounded,
            title: AppTranslations.groupDetailsMemberChat.tr,
            enabledSubtitle: AppTranslations.groupDetailsMemberChatEnabled.tr,
            disabledSubtitle: AppTranslations.groupDetailsMemberChatDisabled.tr,
            palette: palette,
            controlsEnabled: !isSaving,
            onChanged: (enabled) =>
                onMessagePermissionChanged(enabled ? 'members' : 'admins'),
          ),
          _SettingsDivider(palette: palette),
          _PermissionSwitchTile(
            enabled: group.memberListPermission == 'members',
            enabledIcon: Icons.groups_2_outlined,
            disabledIcon: Icons.visibility_off_outlined,
            title: AppTranslations.groupDetailsWhoCanViewMembers.tr,
            enabledSubtitle: AppTranslations.groupDetailsMemberListVisible.tr,
            disabledSubtitle: AppTranslations.groupDetailsMemberListHidden.tr,
            palette: palette,
            controlsEnabled: !isSaving,
            onChanged: (enabled) =>
                onMemberListPermissionChanged(enabled ? 'members' : 'admins'),
          ),
          _SettingsDivider(palette: palette),
          _PermissionSwitchTile(
            enabled: group.reactionViewPermission == 'members',
            enabledIcon: Icons.add_reaction_outlined,
            disabledIcon: Icons.admin_panel_settings_outlined,
            title: AppTranslations.groupDetailsMembersCanViewReactions.tr,
            enabledSubtitle:
                AppTranslations.groupDetailsReactionAuthorsVisible.tr,
            disabledSubtitle:
                AppTranslations.groupDetailsReactionAuthorsHidden.tr,
            palette: palette,
            controlsEnabled: !isSaving,
            onChanged: (enabled) =>
                onReactionViewPermissionChanged(enabled ? 'members' : 'admins'),
          ),
          _SettingsDivider(palette: palette),
          _PermissionSwitchTile(
            enabled: group.joinLinkPermission == 'members',
            enabledIcon: Icons.link_rounded,
            disabledIcon: Icons.admin_panel_settings_outlined,
            title: AppTranslations.groupDetailsMembersCanCopyLink.tr,
            enabledSubtitle: AppTranslations.groupDetailsJoinLinkVisible.tr,
            disabledSubtitle: AppTranslations.groupDetailsJoinLinkHidden.tr,
            palette: palette,
            controlsEnabled: !isSaving,
            onChanged: (enabled) =>
                onJoinLinkPermissionChanged(enabled ? 'members' : 'admins'),
          ),
        ],
      ),
    );
  }
}

class _JoinRequestsSheet extends StatelessWidget {
  const _JoinRequestsSheet({
    required this.requests,
    required this.isSaving,
    required this.actingRequestId,
    required this.onApprove,
    required this.onReject,
  });

  final List<GroupsChatInvitationModel> requests;
  final bool isSaving;
  final int? actingRequestId;
  final ValueChanged<GroupsChatInvitationModel> onApprove;
  final ValueChanged<GroupsChatInvitationModel> onReject;

  @override
  Widget build(BuildContext context) {
    final palette = _GroupSettingsPalette.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppTranslations.groupJoinRequestsTitle.tr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: palette.strongText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _SmallCountBadge(count: requests.length),
              ],
            ),
            const SizedBox(height: 16),
            if (requests.isEmpty)
              _InfoState(message: AppTranslations.groupJoinRequestsEmpty.tr)
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: requests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _JoinRequestTile(
                      request: request,
                      palette: palette,
                      isBusy:
                          isSaving && actingRequestId == request.invitationId,
                      controlsEnabled: !isSaving,
                      onApprove: () => onApprove(request),
                      onReject: () => onReject(request),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallCountBadge extends StatelessWidget {
  const _SmallCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _JoinRequestTile extends StatelessWidget {
  const _JoinRequestTile({
    required this.request,
    required this.palette,
    required this.isBusy,
    required this.controlsEnabled,
    required this.onApprove,
    required this.onReject,
  });

  final GroupsChatInvitationModel request;
  final _GroupSettingsPalette palette;
  final bool isBusy;
  final bool controlsEnabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final actor = request.inviter;
    final name = actor?.displayName.trim().isNotEmpty == true
        ? actor!.displayName
        : AppTranslations.groupsMemberRole.tr;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GroupAvatar(imageUrl: actor?.picture ?? '', name: name, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.strongText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTranslations.groupJoinRequestsPending.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.mutedText,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: controlsEnabled ? onApprove : null,
                      icon: isBusy
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 17),
                      label: Text(AppTranslations.groupJoinRequestsApprove.tr),
                    ),
                    OutlinedButton.icon(
                      onPressed: controlsEnabled ? onReject : null,
                      icon: const Icon(Icons.close_rounded, size: 17),
                      label: Text(AppTranslations.groupJoinRequestsReject.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupMembersPage extends StatefulWidget {
  const _GroupMembersPage({required this.initialGroup});

  final GroupsChatGroupModel initialGroup;

  @override
  State<_GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<_GroupMembersPage> {
  late GroupsChatGroupModel _group;
  final _groupsService = Get.find<GroupsChatService>();
  final _members = <GroupsChatMemberModel>[];

  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _group = widget.initialGroup;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _GroupSettingsPalette.of(context);

    return PopScope<GroupsChatGroupModel>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_group);
      },
      child: Scaffold(
        backgroundColor: palette.pageBackground,
        appBar: AppBar(
          backgroundColor: palette.pageBackground,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(_group),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(AppTranslations.groupDetailsMembersTitle.tr),
          actions: [
            if (_group.canAddMembers)
              IconButton(
                onPressed: _isSaving ? null : _showAddMembersSheet,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                tooltip: AppTranslations.groupDetailsAddMembers.tr,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => _load(showSpinner: false),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  children: [
                    if (_errorMessage.isNotEmpty)
                      _ErrorPanel(message: _errorMessage, onRetry: _load),
                    _MembersPanel(
                      members: _members,
                      group: _group,
                      palette: palette,
                      isSaving: _isSaving,
                      onAddMembers: _group.canAddMembers
                          ? _showAddMembersSheet
                          : null,
                      onMemberAction: _handleMemberAction,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final results = await Future.wait<Object>([
        _groupsService.fetchGroupDetails(groupId: _group.groupId),
        _groupsService.fetchMembers(groupId: _group.groupId),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _group = results[0] as GroupsChatGroupModel;
        _members
          ..clear()
          ..addAll((results[1] as GroupsChatMembersResponse).items);
        _errorMessage = '';
        _isLoading = false;
      });
      _syncGroup(_group);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddMembersSheet() async {
    final result = await showModalBottomSheet<GroupsChatSendInvitationsResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddMembersSheet(
        groupId: _group.groupId,
        existingMemberIds: _members.map((member) => member.userId).toSet(),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    Get.snackbar(
      AppTranslations.groupInvitationSent.tr,
      '${result.createdCount}',
      snackPosition: SnackPosition.BOTTOM,
    );
    await _load(showSpinner: false);
  }

  Future<void> _handleMemberAction(
    GroupsChatMemberModel member,
    _MemberAction action,
  ) async {
    if (_isSaving) {
      return;
    }
    if (action == _MemberAction.permissions) {
      await _showAdminPermissionsSheet(member);
      return;
    }
    if (action == _MemberAction.remove) {
      final confirmed = await _confirmRemoveMember();
      if (confirmed != true) {
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      switch (action) {
        case _MemberAction.promote:
          await _groupsService.makeAdmin(
            groupId: _group.groupId,
            userId: member.userId,
          );
          break;
        case _MemberAction.demote:
          await _groupsService.removeAdmin(
            groupId: _group.groupId,
            userId: member.userId,
          );
          break;
        case _MemberAction.permissions:
          break;
        case _MemberAction.mute:
          await _groupsService.muteMember(
            groupId: _group.groupId,
            userId: member.userId,
          );
          break;
        case _MemberAction.unmute:
          await _groupsService.unmuteMember(
            groupId: _group.groupId,
            userId: member.userId,
          );
          break;
        case _MemberAction.remove:
          await _groupsService.removeMember(
            groupId: _group.groupId,
            userId: member.userId,
          );
          break;
      }
      await _load(showSpinner: false);
    } catch (error) {
      Get.snackbar(
        AppTranslations.groupDetailsUnableToSave.tr,
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showAdminPermissionsSheet(GroupsChatMemberModel member) async {
    final permissions =
        await showModalBottomSheet<GroupsChatAdminPermissionsModel>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (_) => _AdminPermissionsSheet(member: member),
        );
    if (permissions == null || !mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _groupsService.updateAdminPermissions(
        groupId: _group.groupId,
        userId: member.userId,
        permissions: permissions,
      );
      Get.snackbar(
        AppTranslations.groupAdminPermissionsSaved.tr,
        member.displayName,
        snackPosition: SnackPosition.BOTTOM,
      );
      await _load(showSpinner: false);
    } catch (error) {
      Get.snackbar(
        AppTranslations.groupDetailsUnableToSave.tr,
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool?> _confirmRemoveMember() {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(AppTranslations.groupDetailsConfirmRemoveMemberTitle.tr),
        content: Text(AppTranslations.groupDetailsConfirmRemoveMemberBody.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(AppTranslations.settingsLogoutCancel.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppTranslations.groupDetailsRemove.tr),
          ),
        ],
      ),
    );
  }

  void _syncGroup(GroupsChatGroupModel group) {
    if (Get.isRegistered<GroupsChatController>()) {
      Get.find<GroupsChatController>().upsertGroup(group);
    }
  }
}

class _MembersPanel extends StatelessWidget {
  const _MembersPanel({
    required this.members,
    required this.group,
    required this.palette,
    required this.isSaving,
    required this.onAddMembers,
    required this.onMemberAction,
  });

  final List<GroupsChatMemberModel> members;
  final GroupsChatGroupModel group;
  final _GroupSettingsPalette palette;
  final bool isSaving;
  final VoidCallback? onAddMembers;
  final void Function(GroupsChatMemberModel, _MemberAction) onMemberAction;

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      title: AppTranslations.groupDetailsMembersTitle.tr,
      icon: Icons.groups_2_outlined,
      palette: palette,
      trailing: onAddMembers == null
          ? null
          : IconButton(
              onPressed: onAddMembers,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              tooltip: AppTranslations.groupDetailsAddMembers.tr,
            ),
      child: Column(
        children: [
          for (var index = 0; index < members.length; index++) ...[
            _MemberTile(
              member: members[index],
              group: group,
              palette: palette,
              actionsEnabled: !isSaving,
              onAction: (action) => onMemberAction(members[index], action),
            ),
            if (index != members.length - 1) _SettingsDivider(palette: palette),
          ],
        ],
      ),
    );
  }
}

class _LeaveGroupPanel extends StatelessWidget {
  const _LeaveGroupPanel({
    required this.group,
    required this.palette,
    required this.isLeaving,
    required this.isDeleting,
    required this.canDelete,
    required this.onLeave,
    required this.onDelete,
  });

  final GroupsChatGroupModel group;
  final _GroupSettingsPalette palette;
  final bool isLeaving;
  final bool isDeleting;
  final bool canDelete;
  final VoidCallback onLeave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = group.isOwner
        ? AppTranslations.groupDetailsLeaveGroupOwnerSubtitle.tr
        : AppTranslations.groupDetailsLeaveGroupSubtitle.tr;

    return _SectionPanel(
      title: AppTranslations.groupDetailsLeaveGroup.tr,
      icon: Icons.logout_rounded,
      palette: palette,
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.logout_rounded,
            title: AppTranslations.groupDetailsLeaveGroupAction.tr,
            subtitle: subtitle,
            palette: palette,
            busy: isLeaving,
            destructive: true,
            onTap: isLeaving || isDeleting ? null : onLeave,
          ),
          if (canDelete) ...[
            _SettingsDivider(palette: palette),
            _SettingsRow(
              icon: Icons.delete_forever_rounded,
              title: AppTranslations.groupDetailsDeleteGroup.tr,
              subtitle: AppTranslations.groupDetailsDeleteGroupSubtitle.tr,
              palette: palette,
              busy: isDeleting,
              destructive: true,
              onTap: isDeleting || isLeaving ? null : onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportGroupPanel extends StatelessWidget {
  const _ReportGroupPanel({
    required this.group,
    required this.palette,
    required this.onReport,
  });

  final GroupsChatGroupModel group;
  final _GroupSettingsPalette palette;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      title: AppTranslations.groupReportSafetyTitle.tr,
      icon: Icons.shield_outlined,
      palette: palette,
      child: _SettingsRow(
        icon: Icons.flag_outlined,
        title: AppTranslations.groupReportTitle.tr,
        subtitle: AppTranslations.groupReportSubtitle.tr,
        palette: palette,
        destructive: true,
        onTap: onReport,
      ),
    );
  }
}

class _ReportGroupSheet extends StatefulWidget {
  const _ReportGroupSheet({required this.group});

  final GroupsChatGroupModel group;

  @override
  State<_ReportGroupSheet> createState() => _ReportGroupSheetState();
}

class _ReportGroupSheetState extends State<_ReportGroupSheet> {
  final TextEditingController _reasonController = TextEditingController();
  final List<ChatReportCategoryModel> _categories = <ChatReportCategoryModel>[];

  int? _selectedCategoryId;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';

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
      final result = await Get.find<GroupsChatService>()
          .fetchReportCategories();
      if (!mounted) {
        return;
      }
      setState(() {
        _categories
          ..clear()
          ..addAll(result.items);
        _selectedCategoryId = result.items.isNotEmpty
            ? result.items.first.id
            : null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().trim().isEmpty
            ? AppTranslations.chatReportLoadFailed.tr
            : error.toString();
      });
    }
  }

  Future<void> _submit() async {
    final categoryId = _selectedCategoryId;
    if (categoryId == null || categoryId <= 0) {
      Get.snackbar(
        AppTranslations.groupReportTitle.tr,
        AppTranslations.chatReportCategoryRequired.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final message = await Get.find<GroupsChatService>().reportGroup(
        groupId: widget.group.groupId,
        categoryId: categoryId,
        reason: _reasonController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(message);
    } catch (error) {
      Get.snackbar(
        AppTranslations.groupReportTitle.tr,
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flag_outlined, color: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.groupReportTitle.tr,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppTranslations.groupReportDescription.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.accent,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage.isNotEmpty)
                _InfoState(message: _errorMessage)
              else if (_categories.isEmpty)
                _InfoState(
                  message: AppTranslations.chatReportEmptyCategories.tr,
                )
              else ...[
                DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: AppTranslations.chatReportCategoryLabel.tr,
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(
                            category.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedCategoryId = value),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _reasonController,
                  minLines: 3,
                  maxLines: 5,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: AppTranslations.chatReportReasonLabel.tr,
                    hintText: AppTranslations.chatReportReasonHint.tr,
                    prefixIcon: const Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(AppTranslations.chatReportSubmit.tr),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EditGroupSheet extends StatefulWidget {
  const _EditGroupSheet({required this.group});

  final GroupsChatGroupModel group;

  @override
  State<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends State<_EditGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _imageSource;
  Uint8List? _imagePreviewBytes;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(
      text: widget.group.description,
    );
    _imageSource = widget.group.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetHandle(),
                const SizedBox(height: 18),
                Text(
                  AppTranslations.groupDetailsEditInfo.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                Center(child: _buildPhotoPicker(context)),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: AppTranslations.groupsName.tr,
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
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: AppTranslations.groupsDescription.tr,
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving || _isUploadingPhoto ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(AppTranslations.groupDetailsSaveChanges.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _isSaving ||
        _isUploadingPhoto) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = await Get.find<GroupsChatService>().updateGroup(
        groupId: widget.group.groupId,
        name: _nameController.text,
        description: _descriptionController.text,
        imageUrl: _imageSource,
      );
      if (mounted) {
        Navigator.of(context).pop(updated);
      }
    } catch (error) {
      Get.snackbar(
        AppTranslations.groupDetailsUnableToSave.tr,
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildPhotoPicker(BuildContext context) {
    final hasImage =
        _imagePreviewBytes != null || _imageSource.trim().isNotEmpty;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _EditableGroupAvatar(
              imageUrl: _imageSource,
              previewBytes: _imagePreviewBytes,
              name: _nameController.text.trim().isEmpty
                  ? widget.group.name
                  : _nameController.text,
              size: 92,
            ),
            PositionedDirectional(
              bottom: -4,
              end: -4,
              child: Tooltip(
                message: AppTranslations.groupDetailsChangePhoto.tr,
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isUploadingPhoto ? null : _pickGroupPhoto,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: _isUploadingPhoto
                          ? const Padding(
                              padding: EdgeInsets.all(9),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.photo_camera_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _isUploadingPhoto ? null : _pickGroupPhoto,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(
                _isUploadingPhoto
                    ? AppTranslations.groupDetailsUploadingPhoto.tr
                    : AppTranslations.groupDetailsChangePhoto.tr,
              ),
            ),
            if (hasImage)
              TextButton.icon(
                onPressed: _isUploadingPhoto
                    ? null
                    : () {
                        setState(() {
                          _imageSource = '';
                          _imagePreviewBytes = null;
                        });
                      },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(AppTranslations.groupDetailsRemovePhoto.tr),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickGroupPhoto() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1200,
    );
    if (file == null || !mounted) {
      return;
    }

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await file.readAsBytes();
      final source = await Get.find<GroupsChatService>().uploadPhoto(
        bytes: bytes,
        filename: file.name.trim().isEmpty ? 'group-photo.jpg' : file.name,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _imagePreviewBytes = bytes;
        _imageSource = source;
      });
    } catch (error) {
      Get.snackbar(
        AppTranslations.groupDetailsUnableToSave.tr,
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }
}

class _AddMembersSheet extends StatefulWidget {
  const _AddMembersSheet({
    required this.groupId,
    required this.existingMemberIds,
  });

  final int groupId;
  final Set<int> existingMemberIds;

  @override
  State<_AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends State<_AddMembersSheet> {
  final _searchController = TextEditingController();
  final _selectedIds = <int>{};
  List<ChatContactModel> _contacts = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final contacts = _filteredContacts();

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 18),
            Text(
              AppTranslations.groupDetailsSelectMembers.tr,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: AppTranslations.composeSearchHint.tr,
              ),
            ),
            const SizedBox(height: 14),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage.isNotEmpty)
              _InfoState(message: _errorMessage, onRetry: _loadContacts)
            else if (contacts.isEmpty)
              _InfoState(
                message: AppTranslations.groupDetailsNoContacts.tr,
                onRetry: _loadContacts,
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: contacts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final selected = _selectedIds.contains(contact.id);
                    return _ContactSelectTile(
                      contact: contact,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          selected
                              ? _selectedIds.remove(contact.id)
                              : _selectedIds.add(contact.id);
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedIds.isEmpty || _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1_rounded),
                label: Text(
                  '${AppTranslations.groupInvitationSend.tr} (${_selectedIds.length})',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await Get.find<ChatService>().fetchContacts();
      if (!mounted) {
        return;
      }
      setState(() {
        _contacts = response.contacts
            .where(
              (contact) =>
                  contact.id > 0 &&
                  contact.canMessage &&
                  !widget.existingMemberIds.contains(contact.id),
            )
            .toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  List<ChatContactModel> _filteredContacts() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _contacts;
    }
    return _contacts.where((contact) {
      return contact.title.toLowerCase().contains(query) ||
          contact.userName.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      final result = await Get.find<GroupsChatService>().sendInvitations(
        groupId: widget.groupId,
        userIds: _selectedIds.toList(),
      );
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (error) {
      Get.snackbar(
        AppTranslations.groupDetailsUnableToSave.tr,
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.icon,
    required this.palette,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final _GroupSettingsPalette palette;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: palette.mutedText, size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.strongText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({required this.palette});

  final _GroupSettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: palette.border);
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.palette,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.busy = false,
    this.badgeCount = 0,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final _GroupSettingsPalette palette;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool busy;
  final int badgeCount;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    final iconColor = destructive ? Colors.red : palette.mutedText;
    final titleColor = destructive ? Colors.red : palette.strongText;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        icon,
                        size: 22,
                        color: enabled ? iconColor : palette.mutedText,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: enabled ? titleColor : palette.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.mutedText,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 8),
              _SmallCountBadge(count: badgeCount),
            ],
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (trailing == null && onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.mutedText,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionSwitchTile extends StatelessWidget {
  const _PermissionSwitchTile({
    required this.enabled,
    required this.enabledIcon,
    required this.disabledIcon,
    required this.title,
    required this.enabledSubtitle,
    required this.disabledSubtitle,
    required this.palette,
    required this.controlsEnabled,
    required this.onChanged,
  });

  final bool enabled;
  final IconData enabledIcon;
  final IconData disabledIcon;
  final String title;
  final String enabledSubtitle;
  final String disabledSubtitle;
  final _GroupSettingsPalette palette;
  final bool controlsEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            enabled ? enabledIcon : disabledIcon,
            color: palette.mutedText,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: palette.strongText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled ? enabledSubtitle : disabledSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.mutedText,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: controlsEnabled ? onChanged : null),
        ],
      ),
    );
  }
}

class _AdminPermissionsSheet extends StatefulWidget {
  const _AdminPermissionsSheet({required this.member});

  final GroupsChatMemberModel member;

  @override
  State<_AdminPermissionsSheet> createState() => _AdminPermissionsSheetState();
}

class _AdminPermissionsSheetState extends State<_AdminPermissionsSheet> {
  late GroupsChatAdminPermissionsModel _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = widget.member.adminPermissions;
  }

  @override
  Widget build(BuildContext context) {
    final palette = _GroupSettingsPalette.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final displayName = widget.member.displayName.isEmpty
        ? '@${widget.member.userId}'
        : widget.member.displayName;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 18),
            Row(
              children: [
                _GroupAvatar(
                  imageUrl: widget.member.picture,
                  name: displayName,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.groupAdminPermissionsTitle.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: palette.strongText,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _AdminPermissionToggle(
              icon: Icons.group_add_outlined,
              title: AppTranslations.groupAdminPermissionManageMembers.tr,
              value: _permissions.canManageMembers,
              onChanged: (value) => setState(
                () => _permissions = _permissions.copyWith(
                  canManageMembers: value,
                ),
              ),
              palette: palette,
            ),
            _AdminPermissionToggle(
              icon: Icons.person_add_alt_1_outlined,
              title: AppTranslations.groupAdminPermissionManageAdminRoles.tr,
              value: _permissions.canManageAdminRoles,
              onChanged: (value) => setState(
                () => _permissions = _permissions.copyWith(
                  canManageAdminRoles: value,
                ),
              ),
              palette: palette,
            ),
            _AdminPermissionToggle(
              icon: Icons.admin_panel_settings_outlined,
              title:
                  AppTranslations.groupAdminPermissionManageAdminPermissions.tr,
              value: _permissions.canManageAdminPermissions,
              onChanged: (value) => setState(
                () => _permissions = _permissions.copyWith(
                  canManageAdminPermissions: value,
                ),
              ),
              palette: palette,
            ),
            _AdminPermissionToggle(
              icon: Icons.edit_note_rounded,
              title: AppTranslations.groupAdminPermissionEditGroup.tr,
              value: _permissions.canEditGroup,
              onChanged: (value) => setState(
                () => _permissions = _permissions.copyWith(canEditGroup: value),
              ),
              palette: palette,
            ),
            _AdminPermissionToggle(
              icon: Icons.delete_outline_rounded,
              title: AppTranslations.groupAdminPermissionDeleteMessages.tr,
              value: _permissions.canDeleteMessages,
              onChanged: (value) => setState(
                () => _permissions = _permissions.copyWith(
                  canDeleteMessages: value,
                ),
              ),
              palette: palette,
            ),
            _AdminPermissionToggle(
              icon: Icons.volume_off_outlined,
              title: AppTranslations.groupAdminPermissionMuteMembers.tr,
              value: _permissions.canMuteMembers,
              onChanged: (value) => setState(
                () =>
                    _permissions = _permissions.copyWith(canMuteMembers: value),
              ),
              palette: palette,
            ),
            _AdminPermissionToggle(
              icon: Icons.link_rounded,
              title: AppTranslations.groupAdminPermissionManageJoinLink.tr,
              value: _permissions.canManageJoinLink,
              onChanged: (value) => setState(
                () => _permissions = _permissions.copyWith(
                  canManageJoinLink: value,
                ),
              ),
              palette: palette,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_permissions),
                icon: const Icon(Icons.check_rounded),
                label: Text(AppTranslations.groupDetailsSaveChanges.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminPermissionToggle extends StatelessWidget {
  const _AdminPermissionToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.palette,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final _GroupSettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: palette.mutedText, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: palette.strongText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.group,
    required this.palette,
    required this.actionsEnabled,
    required this.onAction,
  });

  final GroupsChatMemberModel member;
  final GroupsChatGroupModel group;
  final _GroupSettingsPalette palette;
  final bool actionsEnabled;
  final ValueChanged<_MemberAction> onAction;

  @override
  Widget build(BuildContext context) {
    final canManageMembers =
        group.canManageMembers && !member.isOwner && actionsEnabled;
    final canManageAdminRoles =
        group.canManageAdminRoles && !member.isOwner && actionsEnabled;
    final canManageAdminPermissions =
        group.canManageAdminPermissions && !member.isOwner && actionsEnabled;
    final canMuteMembers =
        group.canMuteMembers && !member.isOwner && actionsEnabled;
    final menuItems = <PopupMenuEntry<_MemberAction>>[
      if (member.role == 'member' && canManageAdminRoles)
        PopupMenuItem(
          value: _MemberAction.promote,
          child: Text(AppTranslations.groupDetailsPromoteAdmin.tr),
        ),
      if (member.role == 'admin' && canManageAdminPermissions)
        PopupMenuItem(
          value: _MemberAction.permissions,
          child: Text(AppTranslations.groupAdminPermissionsTitle.tr),
        ),
      if (member.role == 'admin' && canManageAdminRoles)
        PopupMenuItem(
          value: _MemberAction.demote,
          child: Text(AppTranslations.groupDetailsRemoveAdmin.tr),
        ),
      if (canMuteMembers)
        PopupMenuItem(
          value: member.isMutedByAdmin
              ? _MemberAction.unmute
              : _MemberAction.mute,
          child: Text(
            member.isMutedByAdmin
                ? AppTranslations.groupMemberUnmute.tr
                : AppTranslations.groupMemberMute.tr,
          ),
        ),
      if (canManageMembers)
        PopupMenuItem(
          value: _MemberAction.remove,
          child: Text(AppTranslations.groupDetailsRemoveMember.tr),
        ),
    ];
    final roleLabel = !member.isMutedByAdmin
        ? _roleLabel(member.role)
        : '${_roleLabel(member.role)} · ${AppTranslations.groupMemberMuted.tr}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _GroupAvatar(
            imageUrl: member.picture,
            name: member.displayName,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName.isEmpty
                      ? '@${member.userId}'
                      : member.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: palette.strongText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roleLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _roleColor(member.role),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (menuItems.isNotEmpty)
            PopupMenuButton<_MemberAction>(
              onSelected: onAction,
              itemBuilder: (_) => menuItems,
            ),
        ],
      ),
    );
  }
}

class _ContactSelectTile extends StatelessWidget {
  const _ContactSelectTile({
    required this.contact,
    required this.selected,
    required this.onTap,
  });

  final ChatContactModel contact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.10)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.accent.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            _GroupAvatar(
              imageUrl: contact.avatarUrl,
              name: contact.title,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                contact.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? AppColors.primary : AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final _GroupSettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: palette.mutedText, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.strongText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoState extends StatelessWidget {
  const _InfoState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(AppTranslations.retry.tr),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
              TextButton(
                onPressed: onRetry,
                child: Text(AppTranslations.retry.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({
    required this.imageUrl,
    required this.name,
    required this.size,
  });

  final String imageUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    if (imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          errorWidget: (_, _, _) => _fallback(initials, context),
        ),
      );
    }
    return _fallback(initials, context);
  }

  Widget _fallback(String initials, BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.primarySoft,
        shape: BoxShape.circle,
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

  String _initials(String value) {
    final parts = value
        .trim()
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'G';
    }
    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }
}

class _EditableGroupAvatar extends StatelessWidget {
  const _EditableGroupAvatar({
    required this.imageUrl,
    required this.previewBytes,
    required this.name,
    required this.size,
  });

  final String imageUrl;
  final Uint8List? previewBytes;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bytes = previewBytes;
    if (bytes != null) {
      return ClipOval(
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return _GroupAvatar(imageUrl: imageUrl, name: name, size: size);
  }
}

class _GroupSettingsPalette {
  const _GroupSettingsPalette({
    required this.pageBackground,
    required this.surface,
    required this.strongText,
    required this.mutedText,
    required this.border,
  });

  final Color pageBackground;
  final Color surface;
  final Color strongText;
  final Color mutedText;
  final Color border;

  static _GroupSettingsPalette of(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return _GroupSettingsPalette(
      pageBackground: palette.groupedCanvas,
      surface: palette.surface,
      strongText: palette.text,
      mutedText: palette.muted,
      border: palette.divider,
    );
  }
}

String _roleLabel(String role) {
  switch (role) {
    case 'owner':
      return AppTranslations.groupsOwner.tr;
    case 'admin':
      return AppTranslations.groupsAdmin.tr;
    default:
      return AppTranslations.groupsMemberRole.tr;
  }
}

Color _roleColor(String role) {
  switch (role) {
    case 'owner':
      return const Color(0xFFB45309);
    case 'admin':
      return AppColors.primary;
    default:
      return AppColors.accent;
  }
}
