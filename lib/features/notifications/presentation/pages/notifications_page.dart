import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/features/notifications/application/notifications_notifier.dart';
import 'package:snginepro/features/notifications/data/models/notification.dart';
import 'package:snginepro/features/feed/presentation/pages/post_detail_page.dart';
import 'package:snginepro/features/profile/presentation/pages/profile_page.dart';
import 'package:snginepro/features/pages/presentation/pages/page_profile_page.dart';
import 'package:snginepro/features/groups/presentation/pages/group_profile_page.dart';
import 'package:snginepro/features/friends/presentation/pages/friend_requests_page.dart';
import 'package:snginepro/features/groups/application/bloc/group_posts_bloc.dart';
import 'package:snginepro/features/groups/data/repositories/groups_repository.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/groups/data/services/groups_api_service.dart';
import 'package:snginepro/features/funding/presentation/pages/funding_detail_page.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // العربية لـ timeago
    timeago.setLocaleMessages('en', timeago.ArMessages());

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsNotifier>().fetchNotifications(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final notifier = context.read<NotificationsNotifier>();
    final currentPosition = _scrollController.position.pixels;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final scrollPercentage = maxExtent > 0 ? (currentPosition / maxExtent) * 100 : 0.0;
    
    // عند الوصول إلى 70% من نهاية القائمة، جلب المزيد
    if (scrollPercentage >= 70 &&
        !_isLoadingMore &&
        !notifier.isLoadingMore &&
        notifier.hasMore) {

      _isLoadingMore = true;
      
      notifier.loadMoreNotifications().then((_) {
        _isLoadingMore = false;
      }).catchError((e) {

        _isLoadingMore = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await context.read<NotificationsNotifier>().fetchNotifications(
      refresh: true,
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      await context.read<NotificationsNotifier>().markAllAsRead();
      Get.snackbar(
        'notifications_success'.tr,
        'notifications_marked_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.withOpacity(0.85),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'notifications_error'.tr,
        'notifications_mark_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.85),
        colorText: Colors.white,
      );
    }
  }

  void _handleNotificationTap(NotificationModel n) {
    // Mark notification as read
    context.read<NotificationsNotifier>().markAsRead(n.notificationId);

    // Navigate based on action type
    switch (n.action.toLowerCase()) {
      // Group notifications
      case 'group_join':
        if (n.nodeId != null) {
          // Navigate to group profile with bloc provider
          final groupsApiService = GroupsApiService(context.read<ApiClient>());
          final groupsRepository = GroupsRepository(groupsApiService);
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => GroupPostsBloc(groupsRepository)
                  ..add(LoadGroupPostsEvent(n.nodeId!.toString())),
                child: GroupProfilePage(groupId: n.nodeId!),
              ),
            ),
          );
        } else {
          // Fallback: try to navigate from URL if possible
          if (n.url.isNotEmpty || n.nodeUrl.isNotEmpty) {
            _navigateFromUrl(n.url.isNotEmpty ? n.url : n.nodeUrl);
          } else {
            Get.snackbar(
              'notification'.tr,
              'group_not_available'.tr,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        }
        break;

      // Funding notifications
      case 'funding_donation':
        // Funding items use the postId as the fundingId
        if (n.nodeId != null && n.nodeId! > 0) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FundingDetailPage(fundingId: n.nodeId!),
            ),
          );
        } else if (n.url.isNotEmpty || n.nodeUrl.isNotEmpty) {
          // Try to extract postId from URL and treat it as fundingId
          final match = RegExp(r'posts?[/=](\d+)').firstMatch(n.url.isNotEmpty ? n.url : n.nodeUrl);
          final fundingId = match != null ? int.tryParse(match.group(1) ?? '') : null;
          if (fundingId != null && fundingId > 0) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FundingDetailPage(fundingId: fundingId),
              ),
            );
          }
        }
        break;

      // Live stream notifications -> open the related post
      case 'live_stream':
        if (n.nodeId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailPage(postId: n.nodeId!),
            ),
          );
        } else if (n.url.isNotEmpty || n.nodeUrl.isNotEmpty) {
          _navigateFromUrl(n.url.isNotEmpty ? n.url : n.nodeUrl);
        }
        break;

      // Friend notifications
      case 'friend_add':
        // Navigate to the user's profile or friend requests page
        if (n.fromUserId > 0) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfilePage(userId: n.fromUserId),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FriendRequestsPage()),
          );
        }
        break;

      // Post interaction notifications
      case 'react_like':
      case 'like':
      case 'comment':
      case 'post_review':
      case 'post':
        if (n.nodeType == 'post' && n.nodeId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailPage(postId: n.nodeId!),
            ),
          );
        } else if (n.nodeType == 'post') {
          // Parse nodeId from nodeUrl if available
          _navigateFromUrl(n.nodeUrl);
        }
        break;

      // User follow notification
      case 'follow':
        if (n.fromUserId > 0) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfilePage(userId: n.fromUserId),
            ),
          );
        }
        break;

      // Page notifications
      case 'page_follow':
      case 'page_like':
        if (n.nodeType == 'page' && n.nodeId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PageProfilePage.fromId(pageId: n.nodeId!),
            ),
          );
        }
        break;

      // Event notifications
      case 'event_join':
      case 'event_invite':
        if (n.nodeType == 'event' && n.nodeId != null) {

          // TODO: Implement EventDetailPage navigation when available
        }
        break;

      // System notifications or unknown actions
      default:
        // Try to navigate using the URL or nodeType as fallback
        if (n.nodeType == 'post' && n.nodeId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailPage(postId: n.nodeId!),
            ),
          );
        } else if (n.nodeType == 'user' && n.fromUserId > 0) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfilePage(userId: n.fromUserId),
            ),
          );
        } else {

        }
        break;
    }
  }

  /// Navigate using URL fallback when nodeId is not available
  void _navigateFromUrl(String url) {
    try {
      // Try to extract ID from URL
      // Example: /api/posts/123 or posts/123
      final match = RegExp(r'posts?[/=](\d+)').firstMatch(url);
      if (match != null) {
        final postId = int.tryParse(match.group(1) ?? '');
        if (postId != null && postId > 0) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailPage(postId: postId),
            ),
          );
          return;
        }
      }

      // Try for users
      final userMatch = RegExp(r'users?[/=](\d+)').firstMatch(url);
      if (userMatch != null) {
        final userId = int.tryParse(userMatch.group(1) ?? '');
        if (userId != null && userId > 0) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfilePage(userId: userId),
            ),
          );
          return;
        }
      }

      // Try for groups
      final groupMatch = RegExp(r'groups?[/=](\d+)').firstMatch(url);
      if (groupMatch != null) {
        final groupId = int.tryParse(groupMatch.group(1) ?? '');
        if (groupId != null && groupId > 0) {
          final groupsApiService = GroupsApiService(context.read<ApiClient>());
          final groupsRepository = GroupsRepository(groupsApiService);
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => GroupPostsBloc(groupsRepository)
                  ..add(LoadGroupPostsEvent(groupId.toString())),
                child: GroupProfilePage(groupId: groupId),
              ),
            ),
          );
          return;
        }
      }

    } catch (e) {

    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'notifications_title'.tr,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          Consumer<NotificationsNotifier>(
            builder: (context, notifier, _) {
              if (notifier.unreadCount > 0) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    tooltip: 'notifications_mark_all_read'.tr,
                    onPressed: _markAllAsRead,
                    icon: const Icon(
                      Icons.mark_email_read_rounded,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)]
                : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
          ),
        ),
        child: Consumer<NotificationsNotifier>(
          builder: (context, n, _) {
            if (n.isLoading && n.notifications.isEmpty) {
              return _buildInitialLoading(isDark);
            }

            if (n.error != null && n.notifications.isEmpty) {
              return _buildErrorView(
                n.error!,
                () => n.fetchNotifications(refresh: true),
                isDark,
              );
            }

            if (n.notifications.isEmpty) {
              return _buildEmptyView(isDark);
            }

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              color: cs.primary,
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                itemCount: n.notifications.length + (n.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == n.notifications.length) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                        ),
                      ),
                    );
                  }

                  final item = n.notifications[index];

                  return Dismissible(
                    key: ValueKey(item.notificationId),
                    background: _slideBg(
                      context,
                      color: cs.primary,
                      icon: Icons.mark_email_read_rounded,
                      label: 'notifications_mark_read'.tr,
                      alignStart: true,
                    ),
                    secondaryBackground: _slideBg(
                      context,
                      color: Colors.red,
                      icon: Icons.delete_outline_rounded,
                      label: 'notifications_delete'.tr,
                      alignStart: false,
                    ),
                    confirmDismiss: (dir) async {
                      if (dir == DismissDirection.startToEnd) {
                        // Mark as read on swipe right
                        await context.read<NotificationsNotifier>().markAsRead(
                          item.notificationId,
                        );
                        return false;
                      }
                      // Allow dismissal for swipe left (endToStart)
                      return true;
                    },
                    onDismissed: (dir) {
                      if (dir == DismissDirection.endToStart) {
                        context
                            .read<NotificationsNotifier>()
                            .removeNotificationById(item.notificationId)
                            .then((_) {
                          Get.snackbar(
                            'notification'.tr,
                            'notifications_deleted'.tr,
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        }).catchError((e) {
                          Get.snackbar(
                            'notifications_error'.tr,
                            e.toString(),
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        });
                      }
                    },
                    child: _NotificationCard(
                      notification: item,
                      onTap: () {
                        context.read<NotificationsNotifier>().markAsRead(
                          item.notificationId,
                        );
                        _handleNotificationTap(item);
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInitialLoading(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)]
              : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
                    : [Colors.white, const Color(0xFFF5F5F5)],
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: isDark
                                ? const Color(0xFF3A3A3A)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF0F0F0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)]
              : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Card(
            elevation: isDark ? 8 : 4,
            shadowColor: isDark ? Colors.black54 : Colors.grey.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFF8F9FA)],
                      ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.red[700]!, Colors.red[800]!]
                            : [Colors.red[300]!, Colors.red[400]!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'notifications_connection_error'.tr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.blue[600]!, Colors.blue[700]!]
                            : [Colors.blue[500]!, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        'notifications_try_again'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)]
              : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Card(
            elevation: isDark ? 8 : 4,
            shadowColor: isDark ? Colors.black54 : Colors.grey.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFF8F9FA)],
                      ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.blue[700]!, Colors.blue[800]!]
                            : [Colors.blue[300]!, Colors.blue[400]!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'notifications_empty_title'.tr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'notifications_empty_subtitle'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'notifications_empty_hint'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _slideBg(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    required bool alignStart,
  }) {
    return Container(
      alignment: alignStart ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!alignStart) const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (alignStart) const Spacer(),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  String _t(String t) {
    try {
      return timeago.format(DateTime.parse(t), locale: 'ar');
    } catch (_) {
      return t;
    }
  }

  IconData _icon() {
    switch (notification.action) {
      case 'friend_add':
      case 'friend_accept':
        return Icons.person_add_alt_1_rounded;
      case 'follow':
        return Icons.rss_feed_rounded;
      case 'poke':
        return Icons.back_hand_rounded;
      case 'comment':
      case 'reply':
      case 'mention':
        return Icons.mode_comment_rounded;
      case 'share':
        return Icons.ios_share_rounded;
      default:
        return notification.isReaction
            ? Icons.favorite_rounded
            : Icons.notifications_rounded;
    }
  }

  Color _iconColor(ColorScheme cs) {
    switch (notification.action) {
      case 'friend_add':
      case 'friend_accept':
      case 'follow':
        return cs.primary;
      case 'poke':
        return Colors.orange;
      case 'comment':
      case 'reply':
      case 'mention':
        return Colors.green;
      case 'share':
        return Colors.purple;
      default:
        return notification.isReaction ? Colors.red : cs.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !notification.seen;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? isUnread
                    ? [const Color(0xFF2A3A4A), const Color(0xFF1F2F3F)]
                    : [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
              : isUnread
              ? [const Color(0xFFF0F8FF), Colors.white]
              : [Colors.white, const Color(0xFFFAFAFA)],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.15),
            blurRadius: isUnread ? 12 : 6,
            spreadRadius: isUnread ? 1 : 0,
            offset: const Offset(0, 3),
          ),
        ],
        border: isUnread
            ? Border.all(color: cs.primary.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة المستخدم مع طبقات الحالة
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isUnread ? cs.primary : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(isUnread ? 0.3 : 0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: CachedNetworkImageProvider(
                          notification.user.picture,
                        ),
                      ),
                    ),
                    if (notification.user.verified)
                      Positioned(
                        right: -2,
                        bottom: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: const Icon(
                            Icons.verified,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Positioned(
                      left: -4,
                      bottom: -4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _iconColor(cs),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _iconColor(cs).withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(_icon(), size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // المحتوى
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: notification.user.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey[800],
                                fontSize: 15,
                              ),
                            ),
                            TextSpan(
                              text: ' ${notification.message}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[600],
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isDark ? Colors.grey[800] : Colors.grey[100])
                                      ?.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _t(notification.time),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (notification.reactionEmoji != null)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                notification.reactionEmoji!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          if (isUnread) ...[
                            const SizedBox(width: 12),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    cs.primary,
                                    cs.primary.withOpacity(0.8),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withOpacity(0.4),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
