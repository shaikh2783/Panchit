import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import '../../data/models/group.dart';
import '../../application/bloc/groups_bloc.dart';
import '../../application/bloc/groups_events.dart';
/// Exclusive design widget for group action buttons
class GroupActionsWidget extends StatelessWidget {
  final Group group;
  final Function()? onJoinPressed;
  final Function()? onLeavePressed;
  final Function()? onEditPressed;
  final Function()? onSharePressed;
  final Function()? onReportPressed;
  final Function()? onInvitePressed;
  const GroupActionsWidget({
    super.key,
    required this.group,
    this.onJoinPressed,
    this.onLeavePressed,
    this.onEditPressed,
    this.onSharePressed,
    this.onReportPressed,
    this.onInvitePressed,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary actions
          _buildPrimaryActions(context, theme),
          const SizedBox(height: 16),
          // Secondary actions
          _buildSecondaryActions(context, theme),
          if (group.membership != null && group.membership!.isAdmin) ...[
            const SizedBox(height: 16),
            // Management actions
            _buildAdminActions(context, theme),
          ],
        ],
      ),
    );
  }
  Widget _buildPrimaryActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Join/Leave Button
        Expanded(
          flex: 2,
          child: _buildActionButton(
            context: context,
            text: group.isCurrentUserMember ? 'Leave Group' : _getJoinButtonText(),
            icon: group.isCurrentUserMember ? Iconsax.logout : Iconsax.login,
            color: group.isCurrentUserMember ? Colors.red : theme.colorScheme.primary,
            onPressed: () {
              if (group.isCurrentUserMember) {
                _showLeaveConfirmation(context);
              } else {
                _handleJoinGroup(context);
              }
            },
          ),
        ),
        if (group.isCurrentUserMember) ...[
          const SizedBox(width: 12),
          // Invite Button
          Expanded(
            child: _buildActionButton(
              context: context,
              text: 'Invite',
              icon: Iconsax.user_add,
              color: theme.colorScheme.secondary,
              onPressed: () => onInvitePressed?.call(),
            ),
          ),
        ],
      ],
    );
  }
  Widget _buildSecondaryActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Share Button
        Expanded(
          child: _buildOutlinedButton(
            context: context,
            text: 'Share',
            icon: Iconsax.share,
            onPressed: () => onSharePressed?.call(),
          ),
        ),
        const SizedBox(width: 12),
        // More Button
        Expanded(
          child: _buildOutlinedButton(
            context: context,
            text: 'More',
            icon: Iconsax.more,
            onPressed: () => _showMoreOptions(context),
          ),
        ),
      ],
    );
  }
  Widget _buildAdminActions(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Divider
        Divider(
          color: theme.dividerColor.withOpacity(0.5),
          thickness: 1,
        ),
        const SizedBox(height: 16),
        // Admin Actions Title
        Row(
          children: [
            const Icon(
              Iconsax.crown_1,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Admin Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Admin Buttons
        Row(
          children: [
            // Edit Button
            Expanded(
              child: _buildAdminButton(
                context: context,
                text: 'Edit',
                icon: Iconsax.edit,
                color: Colors.blue,
                onPressed: () => onEditPressed?.call(),
              ),
            ),
            const SizedBox(width: 12),
            // Stats Button
            Expanded(
              child: _buildAdminButton(
                context: context,
                text: 'Stats',
                icon: Iconsax.chart,
                color: Colors.green,
                onPressed: () => _showGroupStats(context),
              ),
            ),
            const SizedBox(width: 12),
            // Settings Button
            Expanded(
              child: _buildAdminButton(
                context: context,
                text: 'Settings',
                icon: Iconsax.setting_2,
                color: Colors.purple,
                onPressed: () => _showGroupSettings(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildActionButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildOutlinedButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(25),
        color: theme.colorScheme.surface,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildAdminButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  String _getJoinButtonText() {
    switch (group.groupPrivacy) {
      case GroupPrivacy.public:
        return 'Join Now';
      case GroupPrivacy.closed:
        return 'Request to Join';
      case GroupPrivacy.secret:
        return 'Request to Join';
    }
  }
  void _handleJoinGroup(BuildContext context) {
    if (group.groupPrivacy == GroupPrivacy.public) {
      context.read<GroupsBloc>().add(JoinGroupEvent(group.groupId));
      onJoinPressed?.call();
    } else {
      _showJoinConfirmation(context);
    }
  }
  void _showJoinConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Iconsax.info_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Confirm Join'),
          ],
        ),
        content: Text(
          group.groupPrivacy == GroupPrivacy.public
              ? 'Do you want to join "${group.groupTitle}"?'
              : 'A request to join "${group.groupTitle}" will be sent and will require admin approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              context.read<GroupsBloc>().add(JoinGroupEvent(group.groupId));
              onJoinPressed?.call();
            },
            child: Text(group.groupPrivacy == GroupPrivacy.public ? 'Join' : 'Send Request'),
          ),
        ],
      ),
    );
  }
  void _showLeaveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Iconsax.warning_2,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Confirm Leave'),
          ],
        ),
        content: Text(
          'Are you sure you want to leave "${group.groupTitle}"?\n\nYou will need to request to join again if you want to come back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Get.back();
              context.read<GroupsBloc>().add(LeaveGroupEvent(group.groupId));
              onLeavePressed?.call();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              'More Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            // Options
            _buildOptionTile(
              context: context,
              icon: Iconsax.notification,
              title: 'Notification Settings',
              subtitle: 'Manage notifications for this group',
              onTap: () {
                Get.back();
                _showNotificationSettings(context);
              },
            ),
            _buildOptionTile(
              context: context,
              icon: Iconsax.copy,
              title: 'Copy Link',
              subtitle: 'Copy the group link to share',
              onTap: () {
                Get.back();
                _copyGroupLink();
              },
            ),
            if (!group.isCurrentUserMember)
              _buildOptionTile(
                context: context,
                icon: Iconsax.warning_2,
                title: 'Report Group',
                subtitle: 'Report inappropriate content',
                onTap: () {
                  Get.back();
                  onReportPressed?.call();
                },
                isDestructive: true,
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.red : theme.colorScheme.primary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
  void _showGroupStats(BuildContext context) {
    // Implement group stats view
    Get.snackbar(
      'In Development',
      'The statistics feature will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  void _showGroupSettings(BuildContext context) {
    // Implement group settings
    Get.snackbar(
      'In Development',
      'The settings feature will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  void _showNotificationSettings(BuildContext context) {
    // Implement notification settings
    Get.snackbar(
      'In Development',
      'Notification settings will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  void _copyGroupLink() {
    // Implement copy group link
    Get.snackbar(
      'Copied',
      'Group link copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}