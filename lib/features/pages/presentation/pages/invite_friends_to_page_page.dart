import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/invitable_friend.dart';
import '../../data/services/page_invitations_service.dart';
import '../../data/models/page.dart';

class InviteFriendsToPagePage extends StatefulWidget {
  final PageModel page;

  const InviteFriendsToPagePage({super.key, required this.page});

  @override
  State<InviteFriendsToPagePage> createState() =>
      _InviteFriendsToPagePageState();
}

class _InviteFriendsToPagePageState extends State<InviteFriendsToPagePage> {
  final ScrollController _scrollController = ScrollController();
  late final PageInvitationsService _invitationsService;

  List<InvitableFriend> _friends = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;

  // تتبع الدعوات
  final Set<String> _invitingUsers = {};
  final Set<String> _invitedUsers = {};

  @override
  void initState() {
    super.initState();
    _invitationsService = PageInvitationsService(context.read<ApiClient>());
    _loadFriends();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreFriends();
      }
    }
  }

  Future<void> _loadFriends() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _offset = 0;
      _friends.clear();
    });

    try {
      final friends = await _invitationsService.getInvitableFriends(
        pageId: widget.page.id,
        offset: 0,
      );

      setState(() {
        _friends = friends;
        _offset = friends.length;
        _hasMore = friends.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل الأصدقاء'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreFriends() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final friends = await _invitationsService.getInvitableFriends(
        pageId: widget.page.id,
        offset: _offset,
      );

      setState(() {
        _friends.addAll(friends);
        _offset += friends.length;
        _hasMore = friends.length >= 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _inviteFriend(InvitableFriend friend) async {
    if (_invitingUsers.contains(friend.userId) ||
        _invitedUsers.contains(friend.userId)) {
      return;
    }

    setState(() => _invitingUsers.add(friend.userId));

    try {
      final success = await _invitationsService.inviteFriend(
        pageId: widget.page.id,
        userId: int.parse(friend.userId),
      );

      if (success) {
        setState(() {
          _invitingUsers.remove(friend.userId);
          _invitedUsers.add(friend.userId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تمت دعوة ${friend.fullName}'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _invitingUsers.remove(friend.userId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشلت دعوة ${friend.fullName}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _invitingUsers.remove(friend.userId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الدعوة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'دعوة أصدقاء',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.page.name,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(onRefresh: _loadFriends, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا يوجد أصدقاء للدعوة',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'جميع أصدقائك إما أعضاء في الصفحة\nأو تمت دعوتهم بالفعل',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _friends.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _friends.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final friend = _friends[index];
        final isInviting = _invitingUsers.contains(friend.userId);
        final isInvited = _invitedUsers.contains(friend.userId);

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: EdgeInsets.all(12),
            leading: ClipOval(
              child: CachedNetworkImage(
                imageUrl: friend.userPicture,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.person),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    friend.fullName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (friend.userVerified)
                  Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.verified, color: Colors.blue, size: 18),
                  ),
                if (friend.userSubscribed)
                  Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.stars, color: Colors.amber, size: 18),
                  ),
              ],
            ),
            subtitle: Text(
              '@${friend.userName}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: isInvited
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.green, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'تمت الدعوة',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : isInviting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ElevatedButton(
                    onPressed: () => _inviteFriend(friend),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('دعوة'),
                  ),
          ),
        );
      },
    );
  }
}
