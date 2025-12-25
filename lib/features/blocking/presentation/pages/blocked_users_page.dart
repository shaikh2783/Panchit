import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../data/services/blocking_service.dart';
import '../../data/models/blocked_user.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  late final BlockingService _service;
  final ScrollController _scrollController = ScrollController();
  List<BlockedUser> _users = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _service = BlockingService(apiClient);
    _scrollController.addListener(_onScroll);
    _loadUsers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadUsers();
    }
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final page = refresh ? 1 : _currentPage;
      final result = await _service.getBlockedUsers(page: page, limit: 20);
      final newUsers = result['blockedUsers'] as List<BlockedUser>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      setState(() {
        if (refresh) {
          _users = newUsers;
          _currentPage = 2;
        } else {
          _users.addAll(newUsers);
          _currentPage++;
        }
        _hasMore = pagination['has_more'] == true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error_loading_blocked_users'.tr}: $e')),
        );
      }
    }
  }

  Future<void> _unblock(BlockedUser user) async {
    try {
      final resp = await _service.unblockUser(userId: user.userId);
      final ok =
          (resp['status']?.toString() == 'success') ||
          (resp['message']?.toString().contains('unblocked') ?? false);
      if (ok) {
        setState(() {
          _users.removeWhere((u) => u.userId == user.userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resp['message']?.toString() ?? 'user_unblocked_successfully'.tr,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resp['message']?.toString() ?? 'failed_to_unblock_user'.tr,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${'error'.tr}: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('blocked_users_title'.tr)),
      body: RefreshIndicator(
        onRefresh: () => _loadUsers(refresh: true),
        child: _isLoading && _users.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
            ? _emptyState(context)
            : ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _users.length + (_hasMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index >= _users.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final user = _users[index];
                  return _BlockedUserTile(
                    user: user,
                    onUnblock: () => _unblock(user),
                  );
                },
              ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.shield_cross,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'no_blocked_users'.tr,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({required this.user, required this.onUnblock});
  final BlockedUser user;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundImage: user.avatar != null
              ? CachedNetworkImageProvider(user.avatar!)
              : null,
          child: user.avatar == null ? const Icon(Iconsax.user) : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.verified)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Iconsax.verify,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '@${user.username}',
                    style: TextStyle(color: cs.outline, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onUnblock,
              icon: const Icon(Iconsax.user_minus),
              label: Text('unblock'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
