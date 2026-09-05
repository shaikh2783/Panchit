import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/friends/data/models/friend.dart';
import 'package:snginepro/features/profile/presentation/pages/profile_page.dart';
import 'package:snginepro/features/friends/data/services/friends_api_service.dart';

/// Clean, self‑contained FriendRequestsPage (single file)
/// - Gradient header + custom tabs with counters
/// - Polished cards (received/sent)
/// - Skeleton while loading
/// - Works with your existing FriendRequest model (uses timeAgo & mutualFriendsText)
class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  FriendsApiService? _friendsService;

  List<FriendRequest> _sentRequests = [];
  List<FriendRequest> _receivedRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Register Arabic timeago locale
    timeago.setLocaleMessages('ar', timeago.ArMessages());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize FriendsApiService only if not already initialized
    if (_friendsService == null) {
      final apiClient = context.read<ApiClient>();
      _friendsService = FriendsApiService(apiClient);
      _loadFriendRequests();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendRequests() async {
    if (_friendsService == null)
      return; // Return early if service not initialized

    setState(() => _isLoading = true);

    try {
      // جلب الطلبات الواردة والمرسلة من API
      final receivedData = await _friendsService!.getFriendRequests();
      final sentData = await _friendsService!.getSentFriendRequests();

      // تحويل البيانات إلى FriendRequest objects
      _receivedRequests = receivedData
          .map((data) => _mapToFriendRequest(data))
          .toList();
      _sentRequests = sentData
          .map((data) => _mapToFriendRequest(data))
          .toList();
    } catch (e) {
      // في حالة الخطأ، عرض قائمة فارغة
      _receivedRequests = [];
      _sentRequests = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // تحويل البيانات من API إلى FriendRequest model
  FriendRequest _mapToFriendRequest(Map<String, dynamic> data) {
    return FriendRequest(
      id: int.tryParse(data['user_id']?.toString() ?? '0') ?? 0,
      senderId: int.tryParse(data['user_id']?.toString() ?? '0') ?? 0,
      senderName:
          '${data['user_firstname'] ?? ''} ${data['user_lastname'] ?? ''}'
              .trim(),
      senderUsername: data['user_name'] ?? '',
      senderAvatar: data['user_picture'] ?? '',
      sentAt: DateTime.now(), // API doesn't provide request time
      mutualFriendsCount:
          int.tryParse(data['mutual_friends_count']?.toString() ?? '0') ?? 0,
      isVerified:
          (data['user_verified']?.toString() == '1' ||
          data['user_verified'] == true),
      bio: '', // Not provided in this endpoint
      location: '', // Not provided in this endpoint
    );
  }

  void _acceptRequest(FriendRequest request) async {
    if (_friendsService == null)
      return; // Return early if service not initialized

    try {
      final result = await _friendsService!.acceptFriendRequest(
        request.senderId,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _receivedRequests.removeWhere((r) => r.id == request.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'friend_requests_accept_success'.trParams({
                'name': request.senderName,
              }),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'friend_requests_accept_error'.trParams({
                'message': result.message,
              }),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'friend_requests_accept_error_general'.trParams({
              'error': e.toString(),
            }),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _declineRequest(FriendRequest request) async {
    if (_friendsService == null)
      return; // Return early if service not initialized

    try {
      final result = await _friendsService!.declineFriendRequest(
        request.senderId,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _receivedRequests.removeWhere((r) => r.id == request.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'friend_requests_decline_success'.trParams({
                'name': request.senderName,
              }),
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'friend_requests_decline_error'.trParams({
                'message': result.message,
              }),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'friend_requests_decline_error_general'.trParams({
              'error': e.toString(),
            }),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _cancelRequest(FriendRequest request) async {
    if (_friendsService == null)
      return; // Return early if service not initialized

    try {
      final result = await _friendsService!.cancelFriendRequest(
        request.senderId,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _sentRequests.removeWhere((r) => r.id == request.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'friend_requests_cancel_success'.trParams({
                'name': request.senderName,
              }),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'friend_requests_cancel_error'.trParams({
                'message': result.message,
              }),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'friend_requests_cancel_error_general'.trParams({
              'error': e.toString(),
            }),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double headerHeight =
        MediaQuery.of(context).padding.top + kToolbarHeight + 64;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('friend_requests_title'.tr),
        flexibleSpace: const _GradientAppBar(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    (isDark ? Colors.black : Colors.white).withOpacity(0.10),
                  ],
                ),
              ),
              child: _Tabs(
                controller: _tabController,
                receivedCount: _receivedRequests.length,
                sentCount: _sentRequests.length,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const _SkeletonList()
          : TabBarView(
              controller: _tabController,
              children: [
                _ReceivedList(
                  items: _receivedRequests,
                  onAccept: _acceptRequest,
                  onDecline: _declineRequest,
                  topPadding: headerHeight + 12,
                  onRefresh: _loadFriendRequests,
                ),
                _SentList(
                  items: _sentRequests,
                  onCancel: _cancelRequest,
                  topPadding: headerHeight + 12,
                  onRefresh: _loadFriendRequests,
                ),
              ],
            ),
    );
  }
}

// ------------------------------------------------------------
// Header & Tabs
// ------------------------------------------------------------

class _GradientAppBar extends StatelessWidget {
  const _GradientAppBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top = MediaQuery.of(context).padding.top;

    final Color p = AppColors.primary;
    final Color a = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Container(
      height: kToolbarHeight + 64 + top,
      padding: EdgeInsets.only(top: top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.withOpacity(0.28), p.withOpacity(0.10), a],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.controller,
    required this.receivedCount,
    required this.sentCount,
  });

  final TabController controller;
  final int receivedCount;
  final int sentCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    final tabs = [
      (
        icon: Iconsax.user_add,
        label: 'friend_requests_received'.tr,
        count: receivedCount,
      ),
      (
        icon: Iconsax.user_minus,
        label: 'friend_requests_sent'.tr,
        count: sentCount,
      ),
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isSelected = controller.index == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.animateTo(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: isSelected
                          ? (isDark
                                ? AppColors.darkShadow
                                : AppColors.lightShadow)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.55)
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.55,
                                      )),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            tab.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.75)),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (tab.count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.24)
                                  : AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${tab.count}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// Lists
// ------------------------------------------------------------

class _ReceivedList extends StatelessWidget {
  const _ReceivedList({
    required this.items,
    required this.onAccept,
    required this.onDecline,
    required this.topPadding,
    required this.onRefresh,
  });

  final List<FriendRequest> items;
  final void Function(FriendRequest) onAccept;
  final void Function(FriendRequest) onDecline;
  final double topPadding;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - topPadding - 100,
            child: const _EmptyState(
              icon: Iconsax.user_add,
              title: 'friend_requests_empty_received_title',
              subtitle: 'friend_requests_empty_received_subtitle',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final request = items[index];
          return _ReceivedRequestCard(
            request: request,
            onAccept: () => onAccept(request),
            onDecline: () => onDecline(request),
          );
        },
      ),
    );
  }
}

class _SentList extends StatelessWidget {
  const _SentList({
    required this.items,
    required this.onCancel,
    required this.topPadding,
    required this.onRefresh,
  });

  final List<FriendRequest> items;
  final void Function(FriendRequest) onCancel;
  final double topPadding;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - topPadding - 100,
            child: const _EmptyState(
              icon: Iconsax.user_minus,
              title: 'friend_requests_empty_sent_title',
              subtitle: 'friend_requests_empty_sent_subtitle',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final request = items[index];
          return _SentRequestCard(
            request: request,
            onCancel: () => onCancel(request),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------
// Cards & Bits
// ------------------------------------------------------------

class _ReceivedRequestCard extends StatelessWidget {
  const _ReceivedRequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
        boxShadow: isDark ? AppColors.darkShadow : AppColors.lightShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (request.senderId > 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfilePage(userId: request.senderId),
                        ),
                      );
                    }
                  },
                  child: _Avatar(
                    avatar: request.senderAvatar,
                    verified: request.isVerified,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (request.senderId > 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfilePage(userId: request.senderId),
                          ),
                        );
                      }
                    },
                    child: _UserInfo(request: request),
                  ),
                ),
              ],
            ),

            if (request.bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                request.bio,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (request.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Iconsax.location,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    request.location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Iconsax.user_tick, size: 18),
                    label: Text('friend_requests_accept'.tr),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDecline,
                    icon: const Icon(Iconsax.user_remove, size: 18),
                    label: Text('friend_requests_decline'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SentRequestCard extends StatelessWidget {
  const _SentRequestCard({required this.request, required this.onCancel});

  final FriendRequest request;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
        boxShadow: isDark ? AppColors.darkShadow : AppColors.lightShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (request.senderId > 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfilePage(userId: request.senderId),
                    ),
                  );
                }
              },
              child: _Avatar(
                avatar: request.senderAvatar,
                verified: request.isVerified,
                radius: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (request.senderId > 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfilePage(userId: request.senderId),
                      ),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.senderName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '@${request.senderUsername}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Iconsax.clock,
                          size: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'friend_requests_sent_time'.trParams({
                            'time': request.timeAgo,
                          }),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Iconsax.close_circle, size: 16),
              label: Text('friend_requests_cancel'.tr),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatar,
    required this.verified,
    this.radius = 30,
  });

  final String avatar;
  final bool verified;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor = isDark
        ? AppColors.hoverDark
        : AppColors.hoverLight;
    final placeholderIconColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: placeholderColor,
          child: avatar.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatar,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: placeholderColor,
                      child: Icon(Iconsax.user, color: placeholderIconColor),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: placeholderColor,
                      child: Icon(Iconsax.user, color: placeholderIconColor),
                    ),
                  ),
                )
              : Icon(Iconsax.user, size: 28, color: placeholderIconColor),
        ),
        if (verified)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.info,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).cardColor,
                  width: 2,
                ),
              ),
              child: const Icon(Iconsax.verify, color: Colors.white, size: 16),
            ),
          ),
      ],
    );
  }
}

class _UserInfo extends StatelessWidget {
  const _UserInfo({required this.request});
  final FriendRequest request;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                request.senderName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Text(
          '@${request.senderUsername}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          request.mutualFriendsText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          request.timeAgo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// Empty & Skeleton
// ------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final onSurf = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: onSurf),
            const SizedBox(height: 16),
            Text(
              title.tr,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurf),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.hoverDark : AppColors.hoverLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + kToolbarHeight + 64 + 12,
        16,
        16,
      ),
      itemCount: 6,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 160,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(10),
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
}
