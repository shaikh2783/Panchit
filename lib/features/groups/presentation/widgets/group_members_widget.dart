import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/core/theme/widgets/elevated_card.dart';
import '../../data/models/group.dart';
import '../../application/bloc/groups_bloc.dart';
import '../../application/bloc/groups_events.dart';
import '../../application/bloc/groups_states.dart';
/// Exclusive widget design for displaying group members
class GroupMembersWidget extends StatefulWidget {
  final Group group;
  final String mediaAsset;
  final Function(GroupMember)? onMemberTap;
  final Function(GroupMember)? onMemberAction;
  const GroupMembersWidget({
    super.key,
    required this.group,
    required this.mediaAsset,
    this.onMemberTap,
    this.onMemberAction,
  });
  @override
  State<GroupMembersWidget> createState() => _GroupMembersWidgetState();
}
class _GroupMembersWidgetState extends State<GroupMembersWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _hasLoaded = false;
  int? _loadedGroupId;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load members only if not loaded before or if the group has changed
    if (!_hasLoaded || _loadedGroupId != widget.group.groupId) {
      _hasLoaded = true;
      _loadedGroupId = widget.group.groupId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GroupsBloc>().add(LoadGroupMembersEvent(
          groupId: widget.group.groupId,
          isRefresh: true, // Clear previous data
        ));
      });
    }
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 100) {
      // Load more members
      context.read<GroupsBloc>().add(
        LoadGroupMembersEvent(groupId: widget.group.groupId),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<GroupsBloc, GroupsState>(
      buildWhen: (previous, current) {
        // Build the view only when Group Members states change
        return current is GroupMembersLoadingState ||
               current is GroupMembersLoadedState ||
               current is GroupMembersErrorState ||
               current is GroupMembersEmptyState;
      },
      builder: (context, state) {
        List<GroupMember> members = [];
        bool isLoading = false;
        bool hasError = false;
        String errorMessage = '';
        if (state is GroupMembersLoadedState) {
          // Ensure members are for the correct group
          if (state.groupId == widget.group.groupId) {
            members = state.members;
          }
        } else if (state is GroupMembersLoadingState) {
          isLoading = true;
        } else if (state is GroupMembersErrorState) {
          hasError = true;
          errorMessage = state.message;
        }
        if (hasError) {
          return _buildErrorView(errorMessage, theme);
        }
        if (isLoading && members.isEmpty) {
          return _buildLoadingView();
        }
        if (members.isEmpty) {
          return _buildEmptyView(theme);
        }
        return _buildMembersList(members, isLoading, theme);
      },
    );
  }
  Widget _buildMembersList(List<GroupMember> members, bool isLoading, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with stats
        _buildMembersHeader(members.length, theme),
        // Members list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: members.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= members.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final member = members[index];
              return _buildMemberCard(member, theme);
            },
          ),
        ),
      ],
    );
  }
  Widget _buildMembersHeader(int count, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Iconsax.people,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '$count Members',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Search button
          IconButton(
            icon: Icon(
              Iconsax.search_normal_1,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              // Execute search
              showSearch(
                context: context,
                delegate: _MemberSearchDelegate(
                  members: [],
                  mediaAsset: widget.mediaAsset,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  Widget _buildMemberCard(GroupMember member, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => widget.onMemberTap?.call(member),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Member picture
                _buildMemberAvatar(member, theme),
                const SizedBox(width: 16),
                // Member info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.fullname,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Role badge
                          if (member.membership.isAdmin)
                            _buildRoleBadge('Admin', Colors.orange, Iconsax.crown_1),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (member.username.isNotEmpty)
                        Text(
                          '@${member.username}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Additional info
                      Row(
                        children: [
                          _buildStatusIndicator(member, theme),
                          const SizedBox(width: 12),
                          Text(
                            'Joined ${member.membership.timeAdded}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons
                if (widget.group.isCurrentUserAdmin)
                  _buildMemberActions(member, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildMemberAvatar(GroupMember member, ThemeData theme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.3),
            theme.colorScheme.secondary.withOpacity(0.3),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: member.picture.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: '${widget.mediaAsset}${member.picture}',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  child: const Icon(
                    Iconsax.user,
                    color: Colors.grey,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  child: const Icon(
                    Iconsax.user,
                    color: Colors.grey,
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                child: const Icon(
                  Iconsax.user,
                  color: Colors.white,
                  size: 24,
                ),
              ),
      ),
    );
  }
  Widget _buildRoleBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatusIndicator(GroupMember member, ThemeData theme) {
    // Use approved as the default value
    final bool isApproved = member.membership.approved;
    Color statusColor = isApproved ? Colors.green : Colors.orange;
    String statusText = isApproved ? 'Approved' : 'Pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          color: statusColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  Widget _buildMemberActions(GroupMember member, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Iconsax.more_2,
        color: theme.iconTheme.color,
      ),
      onSelected: (value) {
        _handleMemberAction(value, member);
      },
      itemBuilder: (context) {
        List<PopupMenuEntry<String>> items = [];
        // Cannot perform actions on the primary admin
        if (member.membership.isAdmin) {
          items.add(
            const PopupMenuItem(
              value: 'remove_admin',
              child: Row(
                children: [
                  Icon(Iconsax.crown_1, size: 18),
                  SizedBox(width: 8),
                  Text('Remove Admin Role'),
                ],
              ),
            ),
          );
        } else {
          items.add(
            const PopupMenuItem(
              value: 'make_admin',
              child: Row(
                children: [
                  Icon(Iconsax.crown_1, size: 18),
                  SizedBox(width: 8),
                  Text('Make Admin'),
                ],
              ),
            ),
          );
        }
        items.add(
          const PopupMenuItem(
            value: 'remove_member',
            child: Row(
              children: [
                Icon(Iconsax.logout, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Remove from Group', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        );
        return items;
      },
    );
  }
  void _handleMemberAction(String action, GroupMember member) {
    switch (action) {
      case 'make_admin':
        context.read<GroupsBloc>().add(
          MakeMemberAdminEvent(
            groupId: widget.group.groupId,
            userId: member.userId,
          ),
        );
        break;
      case 'remove_admin':
        context.read<GroupsBloc>().add(
          RemoveAdminRoleEvent(
            groupId: widget.group.groupId,
            userId: member.userId,
          ),
        );
        break;
      case 'remove_member':
        context.read<GroupsBloc>().add(
          RemoveMemberEvent(
            groupId: widget.group.groupId,
            userId: member.userId,
          ),
        );
        break;
    }
    widget.onMemberAction?.call(member);
  }
  Widget _buildLoadingView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }
  Widget _buildErrorView(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<GroupsBloc>().add(
                  LoadGroupMembersEvent(groupId: widget.group.groupId),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEmptyView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.people,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No members in this group yet',
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
/// Delegate for searching members
class _MemberSearchDelegate extends SearchDelegate<GroupMember?> {
  final List<GroupMember> members;
  final String mediaAsset;
  _MemberSearchDelegate({
    required this.members,
    required this.mediaAsset,
  });
  @override
  String get searchFieldLabel => 'Search members...';
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }
  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }
  Widget _buildSearchResults() {
    final filteredMembers = members.where((member) {
      return member.fullname.toLowerCase().contains(query.toLowerCase()) ||
             member.username.toLowerCase().contains(query.toLowerCase());
    }).toList();
    if (filteredMembers.isEmpty) {
      return const Center(
        child: Text('No members found'),
      );
    }
    return ListView.builder(
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: member.picture.isNotEmpty
                ? CachedNetworkImageProvider('$mediaAsset${member.picture}')
                : null,
            child: member.picture.isEmpty
                ? const Icon(Iconsax.user)
                : null,
          ),
          title: Text(member.fullname),
          subtitle: member.username.isNotEmpty 
              ? Text('@${member.username}')
              : null,
          onTap: () {
            close(context, member);
          },
        );
      },
    );
  }
}