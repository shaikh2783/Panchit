import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/group.dart';
import '../../data/services/groups_api_service.dart';

/// نموذج بسيط للصديق
class Friend {
  final int userId;
  final String username;
  final String firstname;
  final String lastname;
  final String fullname;
  final String? picture;
  final bool verified;
  final bool subscribed;

  Friend({
    required this.userId,
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.fullname,
    this.picture,
    required this.verified,
    required this.subscribed,
  });
}

/// صفحة دعوة الأصدقاء إلى المجموعة
class GroupInviteFriendsPage extends StatefulWidget {
  const GroupInviteFriendsPage({super.key, required this.group});

  final Group group;

  @override
  State<GroupInviteFriendsPage> createState() => _GroupInviteFriendsPageState();
}

class _GroupInviteFriendsPageState extends State<GroupInviteFriendsPage> {
  late GroupsApiService _groupsService;

  List<Friend> _friends = [];
  List<Friend> _filteredFriends = [];
  Set<int> _selectedFriends = {};
  Set<int> _invitedFriends = {}; // للأصدقاء المدعوين بالفعل

  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _groupsService = GroupsApiService(context.read<ApiClient>());
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final friendsData = await _groupsService.getFriendsToInvite(
        widget.group.groupId,
      );

      // تحويل البيانات إلى Friend
      _friends = friendsData.map((data) {
        return Friend(
          userId: data['user_id'] ?? 0,
          username: data['user_name'] ?? data['username'] ?? '',
          firstname: data['user_firstname'] ?? data['firstname'] ?? '',
          lastname: data['user_lastname'] ?? data['lastname'] ?? '',
          fullname: data['user_fullname'] ?? data['fullname'] ?? '',
          picture: data['user_picture'] ?? data['picture'],
          verified: data['user_verified'] == 1 || data['verified'] == 1,
          subscribed: data['user_subscribed'] == 1 || data['subscribed'] == 1,
        );
      }).toList();

      _filteredFriends = _friends;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterFriends(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = _friends;
      } else {
        _filteredFriends = _friends.where((friend) {
          final name = '${friend.firstname} ${friend.lastname}'.toLowerCase();
          final username = friend.username.toLowerCase();
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) || username.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _toggleSelection(int userId) {
    setState(() {
      if (_selectedFriends.contains(userId)) {
        _selectedFriends.remove(userId);
      } else {
        _selectedFriends.add(userId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedFriends = _filteredFriends
          .where((f) => !_invitedFriends.contains(f.userId))
          .map((f) => f.userId)
          .toSet();
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedFriends.clear();
    });
  }

  Future<void> _sendInvitations() async {
    if (_selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('invite_friends_select_friends'.tr)),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final result = await _groupsService.inviteFriends(
        widget.group.groupId,
        _selectedFriends.toList(),
      );

      final successCount = result['success_count'] as int;
      final failedCount = result['failed_count'] as int;

      if (mounted) {
        // إضافة المدعوين بنجاح إلى القائمة
        final failedUsers = (result['failed_users'] as List<int>).toSet();
        final successfulInvites = _selectedFriends.difference(failedUsers);

        setState(() {
          _invitedFriends.addAll(successfulInvites);
          _selectedFriends.clear();
          _isSending = false;
        });

        // عرض رسالة مناسبة
        if (failedCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'invite_friends_success'.trParams({
                  'count': successCount.toString(),
                }),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'invite_friends_partial_success'.trParams({
                  'success': successCount.toString(),
                  'failed': failedCount.toString(),
                }),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('invite_friends_all_failed'.tr),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'invite_friends_send_error'.trParams({'error': e.toString()}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = context.read<AppConfig>();

    return Scaffold(
      appBar: AppBar(
        title: Text('invite_friends_title'.tr),
        actions: [
          if (_filteredFriends.isNotEmpty && !_isLoading)
            TextButton(
              onPressed: _selectedFriends.isEmpty ? _selectAll : _deselectAll,
              child: Text(
                _selectedFriends.isEmpty
                    ? 'invite_friends_select_all'.tr
                    : 'invite_friends_deselect_all'.tr,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterFriends,
              decoration: InputDecoration(
                hintText: 'invite_friends_search_hint'.tr,
                prefixIcon: const Icon(Iconsax.search_normal),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterFriends('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ),

          // عداد المحددين
          if (_selectedFriends.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.primaryContainer,
              child: Row(
                children: [
                  Icon(
                    Iconsax.tick_circle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'invite_friends_selected_count'.trParams({
                      'count': _selectedFriends.length.toString(),
                    }),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // قائمة الأصدقاء
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Iconsax.info_circle,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'invite_friends_error_title'.tr,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadFriends,
                          icon: const Icon(Icons.refresh),
                          label: Text('invite_friends_retry'.tr),
                        ),
                      ],
                    ),
                  )
                : _filteredFriends.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isNotEmpty
                              ? Iconsax.search_normal
                              : Iconsax.user_tick,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'invite_friends_no_results'.tr
                              : 'invite_friends_no_friends'.tr,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'invite_friends_try_different_search'.tr
                              : 'invite_friends_all_members'.tr,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = _filteredFriends[index];
                      final isSelected = _selectedFriends.contains(
                        friend.userId,
                      );
                      final isInvited = _invitedFriends.contains(friend.userId);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: friend.picture != null
                              ? CachedNetworkImageProvider(
                                  friend.picture!.startsWith('http')
                                      ? friend.picture!
                                      : appConfig
                                            .mediaAsset(friend.picture!)
                                            .toString(),
                                )
                              : null,
                          child: friend.picture == null
                              ? const Icon(Iconsax.user)
                              : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                friend.fullname.isNotEmpty
                                    ? friend.fullname
                                    : friend.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (friend.verified)
                              const Icon(
                                Iconsax.verify,
                                size: 16,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                        subtitle: Text('@${friend.username}'),
                        trailing: isInvited
                            ? Chip(
                                label: Text('invite_friends_invited_label'.tr),
                                backgroundColor: Colors.green.shade100,
                                labelStyle: TextStyle(
                                  color: Colors.green.shade900,
                                  fontSize: 12,
                                ),
                              )
                            : Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  _toggleSelection(friend.userId);
                                },
                              ),
                        onTap: isInvited
                            ? null
                            : () => _toggleSelection(friend.userId),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedFriends.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _isSending ? null : _sendInvitations,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Iconsax.send_1),
                  label: Text(
                    _isSending
                        ? 'invite_friends_sending'.tr
                        : 'invite_friends_send_button'.trParams({
                            'count': _selectedFriends.length.toString(),
                          }),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
