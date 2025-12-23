import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/groups/data/models/group_privacy.dart';
import '../../data/models/group.dart';

/// كارت عرض المجموعة
class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  final VoidCallback? onJoinTap;
  final VoidCallback? onLeaveTap;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
    this.onJoinTap,
    this.onLeaveTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Cover Image
            if (group.groupCover != null) _buildCoverImage(isDark),

            // Group Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Picture + Title + Privacy
                  Row(
                    children: [
                      // Group Picture
                      _buildGroupPicture(isDark),
                      const SizedBox(width: 12),

                      // Title + Privacy
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.groupTitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  _getPrivacyIcon(),
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  group.groupPrivacy.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Join/Leave Button
                      _buildActionButton(isDark),
                    ],
                  ),

                  // Description
                  if (group.groupDescription != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      group.groupDescription!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Stats (Members + Category)
                  Row(
                    children: [
                      // Members Count
                      Icon(
                        Iconsax.people,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${group.groupMembers} ${'group_member_unit'.tr}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Category
                      Icon(
                        Iconsax.tag,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          group.category.categoryName,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Pending Requests Badge (for managed groups)
                      if (group.pendingRequests != null && group.pendingRequests! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${group.pendingRequests}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  Widget _buildCoverImage(bool isDark) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: CachedNetworkImage(
        imageUrl: group.groupCover!,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 120,
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 120,
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          child: const Icon(Icons.error_outline, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildGroupPicture(bool isDark) {
    if (group.groupPicture == null) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[700] : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Iconsax.people,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          size: 24,
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: group.groupPicture!,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 50,
          height: 50,
          color: isDark ? Colors.grey[800] : Colors.grey[200],
        ),
        errorWidget: (context, url, error) => Container(
          width: 50,
          height: 50,
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          child: const Icon(Icons.error_outline, size: 20),
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isDark) {
    if (group.isMember) {
      // زر المغادرة
      return OutlinedButton(
        onPressed: onLeaveTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'group_leave_button'.tr,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.red,
          ),
        ),
      );
    } else if (group.membership?.isPending ?? false) {
      // طلب معلق
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: Text(
          'group_pending_status'.tr,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.orange,
          ),
        ),
      );
    } else {
      // زر الانضمام
      return ElevatedButton(
        onPressed: onJoinTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'group_join_button'.tr,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  IconData _getPrivacyIcon() {
    switch (group.groupPrivacy) {
      case GroupPrivacy.public:
        return Iconsax.global;
      case GroupPrivacy.closed:
        return Iconsax.lock;
      case GroupPrivacy.secret:
        return Iconsax.eye_slash;
    }
  }
}
