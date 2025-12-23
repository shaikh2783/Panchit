import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/models/reaction_user_model.dart';
import 'package:snginepro/core/services/reaction_users_api_service.dart';
import 'package:snginepro/core/services/reactions_service.dart';
import 'package:snginepro/core/network/api_client.dart';
class ReactionUsersBottomSheet extends StatefulWidget {
  final String type; // 'post', 'photo', or 'comment'
  final int id;
  final Map<String, int> reactionStats;
  const ReactionUsersBottomSheet({
    super.key,
    required this.type,
    required this.id,
    required this.reactionStats,
  });
  @override
  State<ReactionUsersBottomSheet> createState() =>
      _ReactionUsersBottomSheetState();
}
class _ReactionUsersBottomSheetState extends State<ReactionUsersBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ReactionUsersApiService _apiService;
  String _selectedReaction = 'all';
  List<ReactionUser> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _error;
  @override
  void initState() {
    super.initState();
    _apiService = ReactionUsersApiService(context.read<ApiClient>());
    // Create tabs: All + each reaction type that has users
    final tabs = ['all'] + widget.reactionStats.keys.toList();
    _tabController = TabController(length: tabs.length, vsync: this);
    _loadUsers();
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  Future<void> _loadUsers() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiService.getReactionUsers(
        type: widget.type,
        id: widget.id,
        reaction: _selectedReaction,
        offset: _offset,
      );
      setState(() {
        if (_offset == 0) {
          _users = response.users;
        } else {
          _users.addAll(response.users);
        }
        _hasMore = response.hasMore;
        _offset++;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  void _changeReaction(String reaction) {
    setState(() {
      _selectedReaction = reaction;
      _users = [];
      _offset = 0;
      _hasMore = true;
    });
    _loadUsers();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCount =
        widget.reactionStats.values.fold(0, (sum, count) => sum + count);
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with total count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Reactions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  totalCount.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Reaction tabs
          if (widget.reactionStats.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                onTap: (index) {
                  final tabs = ['all'] + widget.reactionStats.keys.toList();
                  _changeReaction(tabs[index]);
                },
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor:
                    theme.colorScheme.onSurface.withOpacity(0.6),
                indicatorColor: theme.colorScheme.primary,
                tabs: [
                  Tab(
                    child: Row(
                      children: [
                        const Text('All'),
                        const SizedBox(width: 4),
                        Text(
                          '($totalCount)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ...widget.reactionStats.entries.map((e) {
                    final reaction =
                        ReactionsService.instance.getReactionByName(e.key);
                    return Tab(
                      child: Row(
                        children: [
                          if (reaction != null)
                            CachedNetworkImage(
                              imageUrl: reaction.imageUrl,
                              width: 20,
                              height: 20,
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.emoji_emotions, size: 20),
                            )
                          else
                            const Icon(Icons.emoji_emotions, size: 20),
                          const SizedBox(width: 4),
                          Text('${e.value}'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          // Users list
          Expanded(
            child: _buildUsersList(),
          ),
        ],
      ),
    );
  }
  Widget _buildUsersList() {
    if (_error != null && _users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _offset = 0;
                  _hasMore = true;
                });
                _loadUsers();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_users.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_emotions_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No reactions yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _users.length + (_hasMore ? 1 : 0),
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 72,
        color: Theme.of(context).dividerColor.withOpacity(0.5),
      ),
      itemBuilder: (context, index) {
        if (index >= _users.length) {
          // Load more indicator
          if (!_isLoading) {
            _loadUsers();
          }
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final user = _users[index];
        return _buildUserTile(user);
      },
    );
  }
  Widget _buildUserTile(ReactionUser user) {
    final theme = Theme.of(context);
    final reaction = ReactionsService.instance.getReactionByName(user.reaction);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: user.picture.isNotEmpty
                ? CachedNetworkImageProvider(user.picture)
                : null,
            child: user.picture.isEmpty
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          // Reaction badge
          if (reaction != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: CachedNetworkImage(
                  imageUrl: reaction.imageUrl,
                  width: 16,
                  height: 16,
                  errorWidget: (context, url, error) =>
                      Icon(Icons.emoji_emotions, size: 16, color: reaction.colorValue),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.fullname.isNotEmpty ? user.fullname : user.userName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.verified) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.verified,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
          if (user.subscribed) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.workspace_premium,
              size: 16,
              color: Colors.amber.shade700,
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.userName.isNotEmpty)
            Text(
              '@${user.userName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          if (user.mutualFriendsCount > 0)
            Text(
              '${user.mutualFriendsCount} mutual friends',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing: _buildConnectionButton(user),
      onTap: () {
        // TODO: Navigate to profile
        Navigator.pop(context);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => ProfilePage(userId: user.userId),
        //   ),
        // );
      },
    );
  }
  Widget? _buildConnectionButton(ReactionUser user) {
    final theme = Theme.of(context);
    if (user.isFriend) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Friends',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (user.isFollowing) {
      return OutlinedButton(
        onPressed: () {
          // TODO: Unfollow user
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(80, 32),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text('Following'),
      );
    } else if (user.noConnection) {
      return ElevatedButton(
        onPressed: () {
          // TODO: Follow user
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(80, 32),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child:  Text('follow'.tr),
      );
    }
    return null;
  }
}
// Helper function to show the bottom sheet
void showReactionUsersSheet({
  required BuildContext context,
  required String type,
  required int id,
  required Map<String, int> reactionStats,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ReactionUsersBottomSheet(
      type: type,
      id: id,
      reactionStats: reactionStats,
    ),
  );
}
