import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/friends/data/models/follower.dart';
import 'package:snginepro/features/friends/data/services/user_relationships_service.dart';
import '../../data/models/conversation_model.dart';
import '../../data/services/messenger_api_service.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'chat_page.dart';
import 'all_media_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({Key? key}) : super(key: key);

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final _scrollController = ScrollController();
  bool _isLoading = false;
  int _offset = 0;
  List<ConversationModel> _conversations = [];
  late MessengerApiService _apiService;
  late UserRelationshipsService _relationshipsService;
  Timer? _pollingTimer;
  String _currentUserId = '0';
  // friends picker state
  final List<Follower> _friends = [];
  bool _friendsLoading = false;
  bool _friendsHasMore = true;
  int _friendsPage = 1;
  static const int _friendsPageSize = 20;

  @override
  void initState() {
    super.initState();
    // إعداد timeago للغة العربية
    timeago.setLocaleMessages('ar', timeago.ArMessages());
    _apiService = MessengerApiService(context.read<ApiClient>());
    _relationshipsService = UserRelationshipsService(context.read<ApiClient>());
    
    // Get current user ID
    final authNotifier = context.read<AuthNotifier>();
    final userId = authNotifier.currentUser?['user_id'];
    _currentUserId = userId?.toString() ?? '0';
    
    _loadConversations();
    _scrollController.addListener(_onScroll);
    _startPolling();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadMoreConversations();
    }
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    _offset = 0;
    try {
      final conversations = await _apiService.getConversations(offset: _offset);
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreConversations() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // الصفحة التالية
    _offset++;

    try {
      final moreConversations = await _apiService.getConversations(
        offset: _offset,
      );
      if (mounted) {
        setState(() {
          // منع التكرارات: فقط أضف المحادثات التي لا توجد بالفعل
          final existingIds = _conversations
              .map((c) => c.conversationId)
              .toSet();
          final newConversations = moreConversations
              .where((c) => !existingIds.contains(c.conversationId))
              .toList();

          if (newConversations.isNotEmpty) {
            _conversations.addAll(newConversations);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startPolling() {
    // التحقق من المحادثات الجديدة كل 5 ثواني
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkNewConversations();
    });
  }

  Future<void> _checkNewConversations() async {
    if (_isLoading || !mounted) return;

    try {
      final latestConversations = await _apiService.getConversations(offset: 0);
      if (mounted && latestConversations.isNotEmpty) {
        setState(() {
          // دمج المحادثات الجديدة مع الموجودة
          final existingIds = _conversations
              .map((c) => c.conversationId)
              .toSet();
          final newConversations = latestConversations
              .where((c) => !existingIds.contains(c.conversationId))
              .toList();

          if (newConversations.isNotEmpty) {
            // إضافة المحادثات الجديدة في البداية
            _conversations.insertAll(0, newConversations);
          }

          // تحديث المحادثات الموجودة (آخر رسالة، عدد غير المقروءة، إلخ)
          for (var updatedConv in latestConversations) {
            final index = _conversations.indexWhere(
              (c) => c.conversationId == updatedConv.conversationId,
            );
            if (index != -1) {
              _conversations[index] = updatedConv;
            }
          }
        });
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    // استخدام Get.theme بدلاً من Theme.of(context) لضمان التزامن مع GetX
    final theme = Get.theme;

    return Directionality(
      textDirection: TextDirection.ltr,

      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        floatingActionButton: FloatingActionButton(
          onPressed: _openFriendPicker,
          backgroundColor: theme.primaryColor,
          elevation: 4,
          child: const Icon(Iconsax.edit, color: Colors.white),
        ),
        body: RefreshIndicator(
          onRefresh: () async => _loadConversations(),
          edgeOffset: 140,
          color: theme.primaryColor,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(),


              if (_isLoading && _conversations.isEmpty)
                const SliverFillRemaining(child: _ConversationsSkeleton())
              else if (_conversations.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.only(top: 10, bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ModernConversationTile(
                        conversation: _conversations[index],
                        currentUserId: _currentUserId,
                        onTap: () async {
                          final deleted = await Get.to(
                            () => ChatPage(
                              conversationId:
                                  _conversations[index].conversationId,
                              otherUser: _conversations[index].otherUser,
                            ),
                          );
                          // If conversation was deleted, remove it from list
                          if (deleted == true) {
                            setState(() {
                              _conversations.removeAt(index);
                            });
                          }
                        },
                      ),
                      childCount: _conversations.length,
                    ),
                  ),
                ),

              if (_isLoading && _conversations.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFriendPicker() async {
    // ensure first page loaded
    if (_friends.isEmpty && !_friendsLoading) {
      await _loadFriends();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'start_chat'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setModalState) {
                    Widget body;
                    if (_friendsLoading && _friends.isEmpty) {
                      body = const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (!_friendsLoading && _friends.isEmpty) {
                      body = Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'no_friends_found'.tr,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    } else {
                      body = NotificationListener<ScrollNotification>(
                        onNotification: (scroll) {
                          if (scroll.metrics.pixels >=
                                  scroll.metrics.maxScrollExtent - 120 &&
                              !_friendsLoading &&
                              _friendsHasMore) {
                            _loadFriends(loadMore: true, modalSetState: setModalState);
                          }
                          return false;
                        },
                        child: SizedBox(
                          height: 420,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _friends.length + (_friendsHasMore ? 1 : 0),
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              if (index == _friends.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final friend = _friends[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: friend.userPicture.isNotEmpty
                                      ? CachedNetworkImageProvider(friend.userPicture)
                                      : null,
                                  child: friend.userPicture.isEmpty
                                      ? Text(friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?')
                                      : null,
                                ),
                                title: Text(friend.name.isNotEmpty ? friend.name : friend.userName),
                                subtitle: Text(friend.isOnline ? 'online'.tr : ''),
                                trailing: const Icon(Iconsax.message_text_1),
                                onTap: () => _startChatWithFriend(friend),
                              );
                            },
                          ),
                        ),
                      );
                    }

                    return body;
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadFriends({bool loadMore = false, StateSetter? modalSetState}) async {
    if (_friendsLoading) return;
    if (loadMore && !_friendsHasMore) return;

    setState(() => _friendsLoading = true);
    modalSetState?.call(() {});

    final nextPage = loadMore ? _friendsPage + 1 : 1;

    try {
      final result = await _relationshipsService.getFriends(page: nextPage, limit: _friendsPageSize);
      final friends = (result['friends'] as List<Follower>? ?? []);
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};

      final hasMore = pagination['has_more'] == true || friends.length >= _friendsPageSize;

      if (loadMore) {
        _friends.addAll(friends);
      } else {
        _friends
          ..clear()
          ..addAll(friends);
      }

      _friendsPage = nextPage;
      _friendsHasMore = hasMore;
    } catch (e) {
      _friendsHasMore = false;
    } finally {
      _friendsLoading = false;
      if (mounted) setState(() {});
      modalSetState?.call(() {});
    }
  }

  Future<void> _startChatWithFriend(Follower friend) async {
    Get.back(); // close sheet
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final conversation = await _apiService.getOrCreateConversation(
        userId: friend.userId.toString(),
      );

      Get.back(); // close loader

      if (conversation == null && friend.connection!="friend") {
        Get.snackbar(
          'error'.tr,
          'failed_to_start_conversation'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      UserPreview otherUserObj=UserPreview(userId: friend.userId, username: friend.userName, firstName: friend.name,lastName: friend.name,avatar: friend.userPicture,isVerified: friend.isVerified,link: "");

      final otherUser = conversation?.otherUser??otherUserObj;
      Get.to(() => ChatPage(
            conversationId: conversation?.conversationId??"0",
            otherUser: otherUser,
          ));
    } catch (e) {
      Get.back();
      Get.snackbar(
        'error'.tr,
        'failed_to_start_conversation'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  UserPreview _followerToUserPreview(Follower follower) {
    return UserPreview(
      userId: follower.userId,
      username: follower.userName,
      fullName: follower.name,
      avatar: follower.userPicture.isNotEmpty ? follower.userPicture : null,
      avatarFull: follower.userPicture.isNotEmpty ? follower.userPicture : null,
      isVerified: follower.isVerified,
      link: follower.userName,
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: true,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      surfaceTintColor: Get.theme.scaffoldBackgroundColor,
      leading: IconButton(
        icon: Icon(
          Iconsax.arrow_left_2,
          color: Get.isDarkMode ? Colors.white : Colors.black,
        ),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Iconsax.camera,
            color: Get.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 62),
        title: Text(
          'messenger'.tr,
          style: TextStyle(
            color: Get.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(55),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Get.isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              style: TextStyle(
                color: Get.isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'search_conversations'.tr,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(
                  Iconsax.search_normal_1,
                  size: 18,
                  color: Colors.grey,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAddStoryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Get.isDarkMode ? Colors.white10 : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.add,
              size: 28,
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'your_story'.tr,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUserItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Get.theme.primaryColor, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(
                    "https://i.pravatar.cc/150?img=3",
                  ),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Get.theme.scaffoldBackgroundColor,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Ameen",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Get.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.message_notif,
            size: 80,
            color: Get.isDarkMode
                ? Colors.white24
                : Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'no_conversations'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

}

class _ModernConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const _ModernConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      onLongPress: () => Get.to(
        () => AllMediaPage(
          currentUserId: currentUserId,
          conversationId: conversation.conversationId,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _buildAvatar(isUnread),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_buildName(isUnread), _buildTime(isUnread)],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: _buildMessagePreview(isUnread)),
                      if (isUnread) _buildUnreadBadge(),
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

  Widget _buildAvatar(bool isUnread) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Get.theme.primaryColor.withOpacity(0.1),
          backgroundImage: conversation.otherUser.avatar != null
              ? CachedNetworkImageProvider(conversation.otherUser.avatar!)
              : null,
          child: conversation.otherUser.avatar == null
              ? Text(
                  conversation.otherUser.fullName[0].toUpperCase(),
                  style: TextStyle(
                    color: Get.theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (conversation.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Get.theme.scaffoldBackgroundColor,
                  width: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildName(bool isUnread) {
    return Row(
      children: [
        Text(
          conversation.otherUser.fullName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        if (conversation.otherUser.isVerified)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Iconsax.verify, color: Colors.blue, size: 16),
          ),
      ],
    );
  }

  Widget _buildTime(bool isUnread) {
    if (conversation.lastMessageTime == null) return const SizedBox.shrink();

    return Text(
      timeago.format(
        conversation.lastMessageTime!.toLocal(),
        locale: Get.locale?.languageCode ?? 'ar',
      ),
      style: TextStyle(
        fontSize: 11,
        color: isUnread ? Get.theme.primaryColor : Colors.grey,
        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMessagePreview(bool isUnread) {
    String text = conversation.lastMessage ?? "";
    if (conversation.lastMessageType == 'image') text = '📷 ${'photo'.tr}';

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        color: isUnread
            ? (Get.isDarkMode ? Colors.white : Colors.black)
            : Colors.grey[500],
        fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
      ),
    );
  }

  Widget _buildUnreadBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Get.theme.primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        conversation.unreadCount.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ConversationsSkeleton extends StatelessWidget {
  const _ConversationsSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Get.isDarkMode ? Colors.white10 : Colors.grey[200]!;
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(radius: 28, backgroundColor: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 15,
                    width: 100,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
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
