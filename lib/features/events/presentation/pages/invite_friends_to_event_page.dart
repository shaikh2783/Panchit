import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../application/bloc/events_bloc.dart';
import '../../application/bloc/events_events.dart';
import '../../application/bloc/events_states.dart';
import '../../../groups/data/models/invitable_friend.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
class InviteFriendsToEventPage extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  const InviteFriendsToEventPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });
  @override
  State<InviteFriendsToEventPage> createState() => _InviteFriendsToEventPageState();
}
class _InviteFriendsToEventPageState extends State<InviteFriendsToEventPage> {
  final ScrollController _scrollController = ScrollController();
  final Set<int> _invitingUsers = {}; // Track users being invited
  List<InvitableFriend> _friends = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _limit = 20;
  @override
  void initState() {
    super.initState();
    _loadFriends();
    _scrollController.addListener(_onScroll);
  }
  Future<void> _loadFriends() async {
    if (!_hasMore || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final apiClient = context.read<ApiClient>();
      // ✅ استخدم الـ API الجديد المخصص للـ Events
      final response = await apiClient.get(
        '${configCfgP('events_base')}/${widget.eventId}/invitable_friends',
        queryParameters: {
          'offset': _offset.toString(),
          'limit': _limit.toString(),
        },
      );
      if (response['status'] == 'success') {
        // البيانات في data.friends حسب الـ API الجديد
        final dynamic data = response['data'];
        final List<dynamic> friendsData = data is Map 
            ? (data['friends'] as List? ?? [])
            : [];
        final newFriends = friendsData
            .map((json) {
              try {
                return InvitableFriend.fromJson(json);
              } catch (e) {
                return null;
              }
            })
            .whereType<InvitableFriend>()
            .toList();
        setState(() {
          _friends.addAll(newFriends);
          _offset += newFriends.length;
          _hasMore = newFriends.length >= _limit;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadFriends();
    }
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  void _inviteFriend(int userId) {
    setState(() {
      _invitingUsers.add(userId);
    });
    // استخدم EventsBloc لإرسال الدعوة
    context.read<EventsBloc>().add(
      InviteFriendsToEventEvent(
        eventId: widget.eventId,
        userIds: [userId],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Get.theme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('دعوة أصدقاء إلى ${widget.eventTitle}'),
        centerTitle: true,
      ),
      body: BlocListener<EventsBloc, EventsState>(
        listener: (context, state) {
          if (state is FriendsInvited) {
            // ✅ إعادة تحميل القائمة - المدعو سيختفي تلقائياً من الـ API
            setState(() {
              _invitingUsers.clear();
              _friends.clear();
              _offset = 0;
              _hasMore = true;
            });
            // إعادة تحميل القائمة المفلترة
            _loadFriends();
            Get.snackbar(
              'نجحت الدعوة',
              state.message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          } else if (state is EventsError) {
            setState(() {
              _invitingUsers.clear();
            });
            Get.snackbar(
              'خطأ',
              state.message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        },
        child: _friends.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _friends.isEmpty
                ? _buildEmptyState()
                : _buildFriendsList(),
      ),
    );
  }
  Widget _buildEmptyState() {
    final theme = Get.theme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.user_search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'لا يوجد أصدقاء للدعوة',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جميع أصدقائك مدعوين أو أعضاء في الفعالية',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildFriendsList() {
    final theme = Get.theme;
    final isDark = Get.isDarkMode;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _friends.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final friend = _friends[index];
        final userId = int.tryParse(friend.userId) ?? 0;
        final isInviting = _invitingUsers.contains(userId);
        final fullName = '${friend.userFirstname} ${friend.userLastname}'.trim();
        final isVerified = friend.userVerified == '1';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isDark ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: friend.userPicture.isNotEmpty
                  ? CachedNetworkImageProvider(friend.userPicture)
                  : null,
              child: friend.userPicture.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    fullName.isNotEmpty ? fullName : friend.userName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ],
            ),
            subtitle: friend.userName.isNotEmpty
                ? Text(
                    '@${friend.userName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  )
                : null,
            trailing: isInviting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _inviteFriend(userId),
                    icon: const Icon(Iconsax.user_add, size: 16),
                    label: const Text('دعوة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
