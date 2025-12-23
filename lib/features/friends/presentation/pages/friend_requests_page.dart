import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/friends/data/models/friend.dart';
import 'package:snginepro/features/friends/data/services/friends_api_service.dart';
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
    // Register Arabic timeago locale to silence "Locale [ar] has not been added" logs
    timeago.setLocaleMessages('en', timeago.ArMessages());
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
    if (_friendsService == null) return; // Return early if service not initialized
    setState(() => _isLoading = true);
    try {
      // جلب الطلبات الواردة والمرسلة من API
      final receivedData = await _friendsService!.getFriendRequests();
      final sentData = await _friendsService!.getSentFriendRequests();
      // تحويل البيانات إلى FriendRequest objects
      _receivedRequests = receivedData.map((data) => _mapToFriendRequest(data)).toList();
      _sentRequests = sentData.map((data) => _mapToFriendRequest(data)).toList();
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
      senderName: '${data['user_firstname'] ?? ''} ${data['user_lastname'] ?? ''}' .trim(),
      senderUsername: data['user_name'] ?? '',
      senderAvatar: data['user_picture'] ?? '',
      sentAt: DateTime.now(), // API doesn't provide request time
      mutualFriendsCount: int.tryParse(data['mutual_friends_count']?.toString() ?? '0') ?? 0,
      isVerified: (data['user_verified']?.toString() == '1' || data['user_verified'] == true),
      bio: '', // Not provided in this endpoint
      location: '', // Not provided in this endpoint
    );
  }
  void _acceptRequest(FriendRequest request) async {
    if (_friendsService == null) return; // Return early if service not initialized
    try {
      final result = await _friendsService!.acceptFriendRequest(request.senderId);
      if (!mounted) return;
      if (result.success) {
        setState(() {
          _receivedRequests.removeWhere((r) => r.id == request.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'accepted_friend_request_from'.tr} ${request.senderName}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'failed_to_accept_request'.tr} ${result.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'error_accepting_request'.tr} $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  void _declineRequest(FriendRequest request) async {
    if (_friendsService == null) return; // Return early if service not initialized
    try {
      final result = await _friendsService!.declineFriendRequest(request.senderId);
      if (!mounted) return;
      if (result.success) {
        setState(() {
          _receivedRequests.removeWhere((r) => r.id == request.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'declined_friend_request_from'.tr} ${request.senderName}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'failed_to_decline_request'.tr} ${result.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'error_declining_request'.tr} $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  void _cancelRequest(FriendRequest request) async {
    if (_friendsService == null) return; // Return early if service not initialized
    try {
      final result = await _friendsService!.cancelFriendRequest(request.senderId);
      if (!mounted) return;
      if (result.success) {
        setState(() {
          _sentRequests.removeWhere((r) => r.id == request.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'cancelled_friend_request_to'.tr} ${request.senderName}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'failed_to_cancel_request'.tr} ${result.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'error_cancelling_request'.tr} $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double headerHeight = MediaQuery.of(context).padding.top + kToolbarHeight + 64;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title:  Text('friend_requests'.tr),
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
                    (isDark ? Colors.black : Colors.white).withValues(alpha: 0.10),
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
    final Color a = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB);
    return Container(
      height: kToolbarHeight + 64 + top,
      padding: EdgeInsets.only(top: top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.withValues(alpha: 0.28),
            p.withValues(alpha: 0.10),
            a,
          ],
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
    final onSurf = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    final primary = AppColors.primary;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: onSurf.withValues(alpha: 0.15)),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primary.withValues(alpha: 0.25)),
        ),
        splashBorderRadius: BorderRadius.circular(10),
        labelColor: Theme.of(context).colorScheme.onSurface,
        unselectedLabelColor: onSurf,
        dividerColor: Colors.transparent,
        tabs: [
          _TabItem(icon: Iconsax.user_add, label: 'received'.tr, count: receivedCount),
          _TabItem(icon: Iconsax.user_minus, label: 'sent'.tr, count: sentCount),
        ],
      ),
    );
  }
}
class _TabItem extends StatelessWidget {
  const _TabItem({required this.icon, required this.label, required this.count});
  final IconData icon;
  final String label;
  final int count;
  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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
            child:  _EmptyState(
              icon: Iconsax.user_add,
              title: 'no_friend_requests'.tr,
              subtitle: 'no_friend_requests_hint'.tr,
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
            child:  _EmptyState(
              icon: Iconsax.user_minus,
              title: 'no_sent_requests'.tr,
              subtitle: 'no_sent_requests_hint'.tr,
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
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(avatar: request.senderAvatar, verified: request.isVerified),
                const SizedBox(width: 12),
                Expanded(child: _UserInfo(request: request)),
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
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    request.location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                    label:  Text('accept'.tr),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDecline,
                    icon: const Icon(Iconsax.user_remove, size: 18),
                    label:  Text('decline'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  const _SentRequestCard({
    required this.request,
    required this.onCancel,
  });
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
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _Avatar(avatar: request.senderAvatar, verified: request.isVerified, radius: 25),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.senderName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${request.senderUsername}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Iconsax.clock,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sent ${request.timeAgo}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Iconsax.close_circle, size: 16),
              label:  Text('cancel'.tr),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatar, required this.verified, this.radius = 30});
  final String avatar;
  final bool verified;
  final double radius;
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[300],
          child: avatar.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatar,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Iconsax.user, color: Colors.grey),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Iconsax.user, color: Colors.grey),
                    ),
                  ),
                )
              : const Icon(Iconsax.user, size: 28, color: Colors.grey),
        ),
        if (verified)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).cardColor, width: 2),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Text(
          '@${request.senderUsername}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
    final onSurf = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: onSurf),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + kToolbarHeight + 64 + 12, 16, 16),
      itemCount: 6,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: base),
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
                  Container(height: 14, width: 160, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 120, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Container(height: 40, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(width: 10),
                      Expanded(child: Container(height: 40, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(10)))),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
