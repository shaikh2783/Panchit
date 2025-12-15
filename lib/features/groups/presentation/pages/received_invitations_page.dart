import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../application/bloc/group_invitations_bloc.dart';
import '../../application/bloc/group_invitations_events.dart';
import '../../application/bloc/group_invitations_states.dart';
import '../../data/models/received_invitation.dart';
import '../pages/group_page.dart';
class ReceivedInvitationsPage extends StatefulWidget {
  const ReceivedInvitationsPage({super.key});
  @override
  State<ReceivedInvitationsPage> createState() => _ReceivedInvitationsPageState();
}
class _ReceivedInvitationsPageState extends State<ReceivedInvitationsPage> {
  final ScrollController _scrollController = ScrollController();
  final Set<int> _processingGroups = {}; // Track groups being processed
  @override
  void initState() {
    super.initState();
    _loadReceivedInvitations();
    _scrollController.addListener(_onScroll);
  }
  void _loadReceivedInvitations() {
    context.read<GroupInvitationsBloc>().add(
          const LoadReceivedInvitationsEvent(isRefresh: true),
        );
  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<GroupInvitationsBloc>().add(
            const LoadMoreReceivedInvitationsEvent(),
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
        title: const Text('دعوات المجموعات'),
        centerTitle: true,
      ),
      body: BlocConsumer<GroupInvitationsBloc, GroupInvitationsState>(
        listener: (context, state) {
          if (state is InvitationAcceptedState) {
            _processingGroups.remove(state.groupId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is InvitationDeclinedState) {
            _processingGroups.remove(state.groupId);
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
          if (state is ReceivedInvitationsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReceivedInvitationsEmptyState) {
            return _buildEmptyState();
          }
          if (state is ReceivedInvitationsLoadedState) {
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
            Icons.group_add_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد دعوات',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم تتلقَ أي دعوات للانضمام إلى مجموعات',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInvitationsList(List<ReceivedInvitation> invitations, bool hasMore) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadReceivedInvitations();
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
  Widget _buildInvitationCard(ReceivedInvitation invitation) {
    final groupId = int.tryParse(invitation.groupId) ?? 0;
    final isProcessing = _processingGroups.contains(groupId);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group info
            Row(
              children: [
                // Group picture
                GestureDetector(
                  onTap: () => _navigateToGroup(groupId),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: invitation.groupPicture.isNotEmpty
                        ? CachedNetworkImageProvider(invitation.groupPicture)
                        : null,
                    child: invitation.groupPicture.isEmpty
                        ? Text(
                            invitation.groupTitle.isNotEmpty
                                ? invitation.groupTitle[0].toUpperCase()
                                : 'G',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Group details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToGroup(groupId),
                        child: Text(
                          invitation.groupTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            invitation.isPublicGroup ? Icons.public : Icons.lock,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            invitation.isPublicGroup ? 'مجموعة عامة' : 'مجموعة خاصة',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            // Inviter info
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: invitation.inviterPicture.isNotEmpty
                      ? CachedNetworkImageProvider(invitation.inviterPicture)
                      : null,
                  child: invitation.inviterPicture.isEmpty
                      ? Text(
                          invitation.inviterFirstname.isNotEmpty
                              ? invitation.inviterFirstname[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 14),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      children: [
                        const TextSpan(text: 'دعاك '),
                        TextSpan(
                          text: invitation.inviterFullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(text: ' للانضمام'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            if (isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptInvitation(invitation),
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('قبول'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _declineInvitation(invitation),
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('رفض'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
  void _acceptInvitation(ReceivedInvitation invitation) {
    final groupId = int.tryParse(invitation.groupId) ?? 0;
    if (groupId == 0) return;
    setState(() {
      _processingGroups.add(groupId);
    });
    context.read<GroupInvitationsBloc>().add(
          AcceptInvitationEvent(groupId: groupId),
        );
  }
  void _declineInvitation(ReceivedInvitation invitation) {
    final groupId = int.tryParse(invitation.groupId) ?? 0;
    if (groupId == 0) return;
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الدعوة'),
        content: Text('هل تريد رفض الدعوة للانضمام إلى "${invitation.groupTitle}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _processingGroups.add(groupId);
              });
              this.context.read<GroupInvitationsBloc>().add(
                    DeclineInvitationEvent(groupId: groupId),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('نعم، رفض'),
          ),
        ],
      ),
    );
  }
  void _navigateToGroup(int groupId) {
    if (groupId == 0) return;
    Get.to(() => GroupPage.byId(groupId: groupId));
  }
}
