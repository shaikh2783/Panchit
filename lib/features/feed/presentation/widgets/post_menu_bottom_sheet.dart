import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/reports/presentation/pages/report_content_page.dart';
import '../../../feed/data/models/post.dart';
import '../../../feed/data/services/post_management_api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Professional post menu options
class PostMenuBottomSheet extends StatelessWidget {
  final Post post;
  final Function(PostAction action) onAction;

  const PostMenuBottomSheet({
    super.key,
    required this.post,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 500,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
              : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Professional handle bar
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.6),
                  theme.primaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Enhanced header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF3A3A3A), const Color(0xFF2F2F2F)]
                    : [const Color(0xFFF5F6FA), Colors.white],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.transparent,
                    backgroundImage: post.authorAvatarUrl != null
                        ? CachedNetworkImageProvider(post.authorAvatarUrl!)
                        : null,
                    child: post.authorAvatarUrl == null
                        ? Icon(Iconsax.user, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'post_menu_options'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable menu items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Save/Unsave post
                  _buildMenuItem(
                    context: context,
                    icon: post.isSaved
                        ? Iconsax.archive_minus
                        : Iconsax.archive_add,
                    title: post.isSaved
                        ? 'post_menu_unsave'.tr
                        : 'post_menu_save'.tr,
                    subtitle: post.isSaved
                        ? 'post_menu_unsave_subtitle'.tr
                        : 'post_menu_save_subtitle'.tr,
                    onTap: () {
                      final action = post.isSaved
                          ? PostAction.unsavePost
                          : PostAction.savePost;
                      Navigator.pop(context);
                      onAction(action);
                    },
                  ),

                  // Copy link
                  _buildMenuItem(
                    context: context,
                    icon: Iconsax.link,
                    title: 'post_menu_copy_link'.tr,
                    subtitle: 'post_menu_copy_link_subtitle'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Copy link functionality
                    },
                  ),

                  // Hide/Show post
                  _buildMenuItem(
                    context: context,
                    icon: post.isHidden ? Iconsax.eye : Iconsax.eye_slash,
                    title: post.isHidden
                        ? 'post_menu_show'.tr
                        : 'post_menu_hide'.tr,
                    subtitle: post.isHidden
                        ? 'post_menu_show_subtitle'.tr
                        : 'post_menu_hide_subtitle'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      onAction(
                        post.isHidden
                            ? PostAction.unhidePost
                            : PostAction.hidePost,
                      );
                    },
                  ),

                  // Report (if not owner)
                  if (!_isOwner(context, post))
                    _buildMenuItem(
                      context: context,
                      icon: Iconsax.flag,
                      title: 'post_menu_report'.tr,
                      subtitle: 'post_menu_report_subtitle'.tr,
                      isWarning: true,
                      onTap: () async {
                        Navigator.pop(context);

                        try {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportContentPage(
                                contentType: ReportContentType.post,
                                contentId: post.id.toString(),
                                contentTitle: post.text.length > 50
                                    ? '\${post.text.substring(0, 50)}...'
                                    : post.text,
                                contentAuthor: post.authorName,
                              ),
                            ),
                          );

                          if (result == true && context.mounted) {
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'post_menu_report_success'.tr,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.green[600],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            String errorMessage = 'post_menu_report_error'.tr;

                            // Handle specific error messages
                            if (e.toString().contains('already reported')) {
                              errorMessage = 'post_menu_report_already'.tr;
                            } else if (e.toString().contains('network')) {
                              errorMessage =
                                  'post_menu_report_network_error'.tr;
                            } else if (e.toString().contains('server')) {
                              errorMessage = 'post_menu_report_server_error'.tr;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.warning_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        errorMessage,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.orange[600],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      },
                    ),

                  // Owner-only options
                  if (_isOwner(context, post)) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pin/Unpin to profile
                    _buildMenuItem(
                      context: context,
                      icon: post.isPinned
                          ? Iconsax.archive_tick
                          : Iconsax.archive,
                      title: post.isPinned
                          ? 'post_menu_unpin'.tr
                          : 'post_menu_pin'.tr,
                      subtitle: post.isPinned
                          ? 'post_menu_unpin_subtitle'.tr
                          : 'post_menu_pin_subtitle'.tr,
                      onTap: () {
                        final action = post.isPinned
                            ? PostAction.unpinPost
                            : PostAction.pinPost;
                        Navigator.pop(context);
                        onAction(action);
                      },
                    ),

                    // Turn on/off commenting
                    _buildMenuItem(
                      context: context,
                      icon: post.commentsDisabled
                          ? Iconsax.message_add
                          : Iconsax.message_minus,
                      title: post.commentsDisabled
                          ? 'post_menu_enable_comments'.tr
                          : 'post_menu_disable_comments'.tr,
                      subtitle: post.commentsDisabled
                          ? 'post_menu_enable_comments_subtitle'.tr
                          : 'post_menu_disable_comments_subtitle'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        onAction(
                          post.commentsDisabled
                              ? PostAction.enableComments
                              : PostAction.disableComments,
                        );
                      },
                    ),

                    // Edit post
                    _buildMenuItem(
                      context: context,
                      icon: Iconsax.edit,
                      title: 'post_menu_edit'.tr,
                      subtitle: 'post_menu_edit_subtitle'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        onAction(PostAction.editPost);
                      },
                    ),

                    // Mark/Unmark as Adult Content 🔞
                    _buildMenuItem(
                      context: context,
                      icon: post.forAdult
                          ? Iconsax.shield_tick
                          : Iconsax.warning_2,
                      title: post.forAdult
                          ? 'post_menu_unmark_adult'.tr
                          : 'post_menu_mark_adult'.tr,
                      subtitle: post.forAdult
                          ? 'post_menu_unmark_adult_subtitle'.tr
                          : 'post_menu_mark_adult_subtitle'.tr,
                      isWarning: !post.forAdult,
                      onTap: () {
                        Navigator.pop(context);
                        onAction(
                          post.forAdult
                              ? PostAction.unmarkAsAdult
                              : PostAction.markAsAdult,
                        );
                      },
                    ),

                    // Delete post
                    _buildMenuItem(
                      context: context,
                      icon: Iconsax.trash,
                      title: 'post_menu_delete'.tr,
                      subtitle: 'post_menu_delete_subtitle'.tr,
                      isWarning: true,
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteConfirmation(context, onAction);
                      },
                    ),
                  ],

                  // Bottom padding
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF3A3A3A), const Color(0xFF2F2F2F)]
              : [Colors.white, const Color(0xFFF5F6FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isWarning
                          ? [Colors.red, Colors.red.withOpacity(0.8)]
                          : [
                              theme.primaryColor,
                              theme.primaryColor.withOpacity(0.8),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (isWarning ? Colors.red : theme.primaryColor)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isWarning
                              ? Colors.red
                              : (isDark ? Colors.white : Colors.grey[800]),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isWarning
                              ? Colors.red.withOpacity(0.8)
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isOwner(BuildContext context, Post post) {
    try {
      final auth = Provider.of<AuthNotifier>(context, listen: false);
      final currentUser = auth.currentUser;
      if (currentUser == null) return false;

      String? currentUserId;
      if (currentUser['user_id'] != null) {
        currentUserId = currentUser['user_id'].toString();
      } else if (currentUser['id'] != null) {
        currentUserId = currentUser['id'].toString();
      } else if (currentUser['userID'] != null) {
        currentUserId = currentUser['userID'].toString();
      }

      if (currentUserId == null || currentUserId.isEmpty) return false;

      // If post is authored by a user -> compare authorId
      if (post.authorType == 'user') {
        return post.authorId != null && post.authorId == currentUserId;
      }

      // If post is from a page try matching pageId or authorId as a fallback
      if (post.isPagePost) {
        if (post.pageId != null && post.pageId == currentUserId) return true;
        if (post.authorId != null && post.authorId == currentUserId)
          return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Function(PostAction) onAction,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'post_menu_delete_title'.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
        content: Text(
          'post_menu_delete_confirm'.tr,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey[300] : Colors.grey[600],
            height: 1.5,
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF3A3A3A), const Color(0xFF2F2F2F)]
                    : [Colors.grey[100]!, Colors.white],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'post_menu_cancel'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Color(0xFFD32F2F)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                onAction(PostAction.deletePost);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'post_menu_delete_button'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
