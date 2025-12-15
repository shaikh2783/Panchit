import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../data/models/group.dart';
/// Exclusive design widget for displaying detailed group information
class GroupInfoWidget extends StatelessWidget {
  final Group group;
  final String mediaAsset;
  const GroupInfoWidget({
    super.key,
    required this.group,
    required this.mediaAsset,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Description
          _buildDescriptionSection(theme),
          const SizedBox(height: 24),
          // General Information
          _buildGeneralInfoSection(theme),
          const SizedBox(height: 24),
          // Group Settings
          _buildGroupSettingsSection(theme),
          const SizedBox(height: 24),
          // Admin Info
          _buildAdminSection(theme),
          const SizedBox(height: 24),
          // Group Stats
          _buildStatsSection(theme),
        ],
      ),
    );
  }
  Widget _buildDescriptionSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.document_text,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Group Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (group.groupDescription.isNotEmpty)
            Text(
              group.groupDescription,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: theme.textTheme.bodyMedium?.color,
              ),
            )
          else
            Text(
              'No description has been added for this group yet.',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildGeneralInfoSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'General Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Iconsax.people,
            label: 'Members',
            value: '${group.groupMembers} members',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: group.groupPrivacy == GroupPrivacy.public
                ? Iconsax.global
                : group.groupPrivacy == GroupPrivacy.closed
                    ? Iconsax.lock_1
                    : Iconsax.eye_slash,
            label: 'Group Type',
            value: _getPrivacyText(group.groupPrivacy),
            color: _getPrivacyColor(group.groupPrivacy),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Iconsax.category,
            label: 'Category',
            value: group.category.name,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Iconsax.calendar,
            label: 'Creation Date',
            value: 'Since ${DateTime.parse(group.groupDate).year}',
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Iconsax.star,
            label: 'Rating',
            value: '${group.groupRate.toStringAsFixed(1)} out of 5',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }
  Widget _buildGroupSettingsSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingRow(
            icon: Iconsax.edit,
            label: 'Posting Enabled',
            isEnabled: group.groupPublishEnabled,
          ),
          const SizedBox(height: 12),
          _buildSettingRow(
            icon: Iconsax.verify,
            label: 'Post Approval',
            isEnabled: group.groupPublishApprovalEnabled,
          ),
          const SizedBox(height: 12),
          _buildSettingRow(
            icon: Iconsax.coin,
            label: 'Monetization Enabled',
            isEnabled: group.groupMonetizationEnabled,
          ),
          if (group.groupMonetizationEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.dollar_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Monetization Minimum: ${group.groupMonetizationMinPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildSettingRow(
            icon: Iconsax.message,
            label: 'Chat Enabled',
            isEnabled: group.chatboxEnabled,
          ),
        ],
      ),
    );
  }
  Widget _buildAdminSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.deepOrange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.crown_1,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Group Admin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Admin Picture
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: group.admin.picture.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: '$mediaAsset${group.admin.picture}',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Icon(
                            Iconsax.user,
                            color: Colors.white,
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Iconsax.user,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Iconsax.user,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Admin Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.admin.fullname,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        if (group.admin.verified)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Iconsax.verify,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${group.admin.username}',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildStatsSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Iconsax.people,
                  title: 'Members',
                  value: group.groupMembers.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Iconsax.star,
                  title: 'Rating',
                  value: group.groupRate.toStringAsFixed(1),
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required bool isEnabled,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isEnabled ? Colors.green : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isEnabled ? null : Colors.grey,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isEnabled ? 'Enabled' : 'Disabled',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.green : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  String _getPrivacyText(GroupPrivacy privacy) {
    switch (privacy) {
      case GroupPrivacy.public:
        return 'Public Group';
      case GroupPrivacy.closed:
        return 'Closed Group';
      case GroupPrivacy.secret:
        return 'Secret Group';
    }
  }
  Color _getPrivacyColor(GroupPrivacy privacy) {
    switch (privacy) {
      case GroupPrivacy.public:
        return Colors.green;
      case GroupPrivacy.closed:
        return Colors.orange;
      case GroupPrivacy.secret:
        return Colors.red;
    }
  }
}