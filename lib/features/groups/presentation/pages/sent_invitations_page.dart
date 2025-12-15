import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../application/bloc/group_invitations_bloc.dart';
import '../../application/bloc/group_invitations_events.dart';
import '../../application/bloc/group_invitations_states.dart';
import '../../data/models/sent_invitation.dart';
class SentInvitationsPage extends StatefulWidget {
  final int groupId;
  final String groupTitle;
  const SentInvitationsPage({
    super.key,
    required this.groupId,
    required this.groupTitle,
  });
  @override
  State<SentInvitationsPage> createState() => _SentInvitationsPageState();
}
class _SentInvitationsPageState extends State<SentInvitationsPage> {
  final ScrollController _scrollController = ScrollController();
  final Set<int> _cancellingUsers = {}; // Track users being cancelled
  @override
  void initState() {
    super.initState();
    _loadSentInvitations();
    _scrollController.addListener(_onScroll);
  }
  void _loadSentInvitations() {
    context.read<GroupInvitationsBloc>().add(
          LoadSentInvitationsEvent(
            groupId: widget.groupId,
            isRefresh: true,
          ),
        );
  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<GroupInvitationsBloc>().add(
            LoadMoreSentInvitationsEvent(groupId: widget.groupId),
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
        title: Text('الدعوات المرسلة - ${widget.groupTitle}'),
        centerTitle: true,
      ),
      body: BlocConsumer<GroupInvitationsBloc, GroupInvitationsState>(
        listener: (context, state) {
          if (state is InvitationCancelledState) {
            _cancellingUsers.remove(state.userId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is GroupInvitationsErrorState) {
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
          if (state is SentInvitationsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SentInvitationsEmptyState) {
            return _buildEmptyState();
          }
          if (state is SentInvitationsLoadedState) {
            return _buildInvitationsList(state.invitations, state.hasMore);
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
            Icons.mail_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد دعوات مرسلة',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم تقم بدعوة أي شخص لهذه المجموعة بعد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInvitationsList(List<SentInvitation> invitations, bool hasMore) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadSentInvitations();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: invitations.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= invitations.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final invitation = invitations[index];
          return _buildInvitationCard(invitation);
        },
      ),
    );
  }
  Widget _buildInvitationCard(SentInvitation invitation) {
    final userId = int.tryParse(invitation.userId) ?? 0;
    final isCancelling = _cancellingUsers.contains(userId);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: invitation.userPicture.isNotEmpty
              ? CachedNetworkImageProvider(invitation.userPicture)
              : null,
          child: invitation.userPicture.isEmpty
              ? Text(
                  invitation.userFirstname.isNotEmpty
                      ? invitation.userFirstname[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 20),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                invitation.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (invitation.isVerified)
              const Icon(
                Icons.verified,
                color: Colors.blue,
                size: 18,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@${invitation.userName}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.pending_outlined,
                  size: 14,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 4),
                Text(
                  'قيد الانتظار',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isCancelling
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: () => _cancelInvitation(invitation),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('إلغاء'),
              ),
      ),
    );
  }
  void _cancelInvitation(SentInvitation invitation) {
    final userId = int.tryParse(invitation.userId) ?? 0;
    if (userId == 0) return;
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الدعوة'),
        content: Text('هل تريد إلغاء دعوة ${invitation.fullName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _cancellingUsers.add(userId);
              });
              this.context.read<GroupInvitationsBloc>().add(
                    CancelInvitationEvent(
                      groupId: widget.groupId,
                      userId: userId,
                    ),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );
  }
}
