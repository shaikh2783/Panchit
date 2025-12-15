import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/network/api_client.dart';
import '../../../groups/data/models/invitable_friend.dart';
import '../../data/services/page_invitations_service.dart';
import '../../data/models/page.dart';
import '../../domain/pages_repository.dart';
class PageAdminsPage extends StatefulWidget {
  final PageModel page;
  const PageAdminsPage({super.key, required this.page});
  @override
  State<PageAdminsPage> createState() => _PageAdminsPageState();
}
class _PageAdminsPageState extends State<PageAdminsPage> {
  final ScrollController _scrollController = ScrollController();
  late final PageInvitationsService _invitationsService;
  late final PagesRepository _pagesRepository;
  List<InvitableFriend> _friends = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  // تتبع الإضافة/الحذف
  final Set<String> _processingUsers = {};
  @override
  void initState() {
    super.initState();
    _invitationsService = PageInvitationsService(context.read<ApiClient>());
    _pagesRepository = context.read<PagesRepository>();
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
      // استخدام المعجبين بدلاً من الأصدقاء - فقط المعجبين يمكن أن يصبحوا admins
      final likers = await _invitationsService.getPageLikers(
        pageId: widget.page.id,
        offset: 0,
        limit: 20,
      );
      setState(() {
        _friends = likers;
        _offset = likers.length;
        _hasMore = likers.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل المعجبين'),
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
      final likers = await _invitationsService.getPageLikers(
        pageId: widget.page.id,
        offset: _offset,
        limit: 20,
      );
      setState(() {
        _friends.addAll(likers);
        _offset += likers.length;
        _hasMore = likers.length >= 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }
  Future<void> _toggleAdmin(InvitableFriend friend, bool isAdmin) async {
    if (_processingUsers.contains(friend.userId)) {
      return;
    }
    // Find current index and save previous state
    final index = _friends.indexWhere((f) => f.userId == friend.userId);
    if (index == -1) return;
    final previousState = _friends[index];
    // Update UI immediately with processing lock
    setState(() {
      _processingUsers.add(friend.userId);
      _friends[index] = InvitableFriend(
        userId: friend.userId,
        userName: friend.userName,
        userFirstname: friend.userFirstname,
        userLastname: friend.userLastname,
        userGender: friend.userGender,
        userPicture: friend.userPicture,
        userSubscribed: friend.userSubscribed,
        userVerified: friend.userVerified,
        connection: friend.connection,
        nodeId: friend.nodeId,
        isAdmin: !isAdmin, // Toggle immediately
      );
    });
    try {
      if (isAdmin) {
        // Remove admin
        await _pagesRepository.removeAdmin(
          pageId: widget.page.id,
          userId: int.parse(friend.userId),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إزالة ${friend.fullName} من المديرين'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Add admin - المستخدم معجب بالفعل (من قائمة المعجبين)
        await _pagesRepository.addAdmin(
          pageId: widget.page.id,
          userId: int.parse(friend.userId),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إضافة ${friend.fullName} كمدير'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Rollback on error
      setState(() {
        _friends[index] = previousState;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء العملية'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always remove from processing set
      setState(() => _processingUsers.remove(friend.userId));
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
              'مديري الصفحة',
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
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'لا يوجد معجبين',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'يمكنك ترقية المعجبين بالصفحة إلى مديرين',
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
        final isProcessing = _processingUsers.contains(friend.userId);
        final isAdmin = friend.isAdmin;
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
                if (friend.isVerified)
                  Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.verified, color: Colors.blue, size: 18),
                  ),
                if (friend.isSubscribed)
                  Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.stars, color: Colors.amber, size: 18),
                  ),
              ],
            ),
            subtitle: Row(
              children: [
                Text(
                  '@${friend.userName}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (isAdmin) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'مدير',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: isProcessing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : isAdmin
                ? IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _toggleAdmin(friend, true),
                    tooltip: 'إزالة من المديرين',
                  )
                : IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () => _toggleAdmin(friend, false),
                    tooltip: 'إضافة كمدير',
                  ),
          ),
        );
      },
    );
  }
}
