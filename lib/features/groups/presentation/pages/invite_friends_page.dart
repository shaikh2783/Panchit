import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../application/bloc/group_invitations_bloc.dart';
import '../../application/bloc/group_invitations_events.dart';
import '../../application/bloc/group_invitations_states.dart';
import '../../data/models/invitable_friend.dart';
import 'sent_invitations_page.dart';
class InviteFriendsPage extends StatefulWidget {
  final int groupId;
  final String groupTitle;
  const InviteFriendsPage({
    super.key,
    required this.groupId,
    required this.groupTitle,
  });
  @override
  State<InviteFriendsPage> createState() => _InviteFriendsPageState();
}
class _InviteFriendsPageState extends State<InviteFriendsPage> {
  final ScrollController _scrollController = ScrollController();
  final Set<int> _invitingUsers = {}; // Track users being invited
  final Set<int> _invitedUsers = {}; // Track users who have been invited
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }
  void _loadInitialData() async {
    // Load sent invitations first to populate _invitedUsers
    context.read<GroupInvitationsBloc>().add(
          LoadSentInvitationsEvent(groupId: widget.groupId),
        );
    // Wait a bit for sent invitations to load
    await Future.delayed(const Duration(milliseconds: 300));
    // Then load initial friends
    context.read<GroupInvitationsBloc>().add(
          LoadInvitableFriendsEvent(groupId: widget.groupId),
        );
  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<GroupInvitationsBloc>().add(
            LoadMoreInvitableFriendsEvent(groupId: widget.groupId),
          );
    }
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('دعوة أصدقاء إلى ${widget.groupTitle}'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              Get.to(() => SentInvitationsPage(
                    groupId: widget.groupId,
                    groupTitle: widget.groupTitle,
                  ));
            },
            icon: const Icon(Icons.send, color: Colors.white, size: 20),
            label: const Text(
              'المدعوين',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: BlocConsumer<GroupInvitationsBloc, GroupInvitationsState>(
        listener: (context, state) {
          if (state is SentInvitationsLoadedState) {
            // Populate _invitedUsers from sent invitations
            setState(() {
              _invitedUsers.clear();
              for (var invitation in state.invitations) {
                final userId = int.tryParse(invitation.userId);
                if (userId != null) {
                  _invitedUsers.add(userId);
                }
              }
            });
          } else if (state is InvitationSentState) {
            setState(() {
              _invitingUsers.remove(state.userId);
              _invitedUsers.add(state.userId); // Mark as invited
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is GroupInvitationsErrorState) {
            setState(() {
              _invitingUsers.clear(); // Clear all in case of error
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is InvitableFriendsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InvitableFriendsEmptyState) {
            return _buildEmptyState();
          }
          if (state is InvitableFriendsLoadedState) {
            return _buildFriendsList(state.friends, state.hasMore);
          }
          // Default state
          return const SizedBox.shrink();
        },
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد أصدقاء متاحون للدعوة',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جميع أصدقائك إما أعضاء بالفعل أو تم دعوتهم',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFriendsList(List<InvitableFriend> friends, bool hasMore) {
    return RefreshIndicator(
      onRefresh: () async {
        // Force refresh from API
        context.read<GroupInvitationsBloc>().add(
              LoadInvitableFriendsEvent(
                groupId: widget.groupId,
                isRefresh: true,
              ),
            );
        // Wait a bit for the refresh to complete
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: friends.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= friends.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final friend = friends[index];
          return _buildFriendCard(friend);
        },
      ),
    );
  }
  Widget _buildFriendCard(InvitableFriend friend) {
    final userId = int.tryParse(friend.userId) ?? 0;
    final isInviting = _invitingUsers.contains(userId);
    final isInvited = _invitedUsers.contains(userId);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: friend.userPicture.isNotEmpty
              ? CachedNetworkImageProvider(friend.userPicture)
              : null,
          child: friend.userPicture.isEmpty
              ? Text(
                  friend.userFirstname.isNotEmpty
                      ? friend.userFirstname[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 20),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                friend.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (friend.isVerified)
              const Icon(
                Icons.verified,
                color: Colors.blue,
                size: 18,
              ),
          ],
        ),
        subtitle: Text(
          '@${friend.userName}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: isInviting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : isInvited
                ? ElevatedButton.icon(
                    onPressed: null, // Disabled button
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade100,
                      disabledBackgroundColor: Colors.green.shade100,
                      foregroundColor: Colors.green.shade800,
                      disabledForegroundColor: Colors.green.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('تم الإرسال'),
                  )
                : ElevatedButton(
                    onPressed: () => _inviteFriend(friend),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('دعوة'),
                  ),
      ),
    );
  }
  void _inviteFriend(InvitableFriend friend) {
    final userId = int.tryParse(friend.userId) ?? 0;
    if (userId == 0) return;
    setState(() {
      _invitingUsers.add(userId);
    });
    context.read<GroupInvitationsBloc>().add(
          InviteFriendEvent(
            groupId: widget.groupId,
            userId: userId,
          ),
        );
  }
}
