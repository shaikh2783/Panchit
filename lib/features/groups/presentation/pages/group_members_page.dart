import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/group.dart';
import '../../data/models/group_member.dart';
import '../../data/services/groups_api_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/application/auth_notifier.dart';

class GroupMembersPage extends StatefulWidget {
  final Group group;
  final bool isAdmin;

  const GroupMembersPage({
    super.key,
    required this.group,
    required this.isAdmin,
  });

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GroupsApiService _groupsService;

  // Tab data
  final List<String> _tabLabels = ['الكل', 'المسؤولين', 'الأعضاء'];
  final List<String> _statusFilters = ['all', 'approved', 'approved'];
  bool _filterAdminsOnly = false;

  // Pagination
  List<GroupMember> _members = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 20;

  // Helper: Check if current user is the group owner
  bool get _isOwner {
    final auth = context.read<AuthNotifier>();
    final currentUserId = int.tryParse(
      auth.currentUser?['user_id']?.toString() ?? '',
    );
    return currentUserId != null && 
           currentUserId == widget.group.admin.userId;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    // تهيئة GroupsApiService مع ApiClient
    final apiClient = context.read<ApiClient>();
    _groupsService = GroupsApiService(apiClient);
    
    _loadMembers(refresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _filterAdminsOnly = _tabController.index == 1; // Admins tab
        _loadMembers(refresh: true);
      });
    }
  }

  Future<void> _loadMembers({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _members.clear();
    }

    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final response = await _groupsService.getMembers(
        widget.group.groupId,
        status: _statusFilters[_tabController.index],
        page: _currentPage,
        limit: _limit,
      );

      List<GroupMember> newMembers = response.members;

      // Filter admins if on admins tab
      if (_filterAdminsOnly) {
        newMembers = newMembers.where((m) => m.isAdmin).toList();
      }
      // Filter non-admins if on members tab
      else if (_tabController.index == 2) {
        newMembers = newMembers.where((m) => !m.isAdmin).toList();
      }

      setState(() {
        if (refresh) {
          _members = newMembers;
        } else {
          _members.addAll(newMembers);
        }
        _currentPage++;
        _hasMore = response.page < response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الأعضاء: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('أعضاء المجموعة'),
            Text(
              widget.group.groupTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          3,
          (index) => _buildMembersList(),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    if (_isLoading && _members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.profile_2user,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد أعضاء',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadMembers(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _members.length) {
            // Load more indicator
            _loadMembers();
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return _buildMemberCard(_members[index]);
        },
      ),
    );
  }

  Widget _buildMemberCard(GroupMember member) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              backgroundImage: member.picture != null
                  ? CachedNetworkImageProvider(
                      member.picture!.startsWith('http')
                          ? member.picture!
                          : appConfig.mediaAsset(member.picture!).toString(),
                    )
                  : null,
              child: member.picture == null
                  ? const Icon(Iconsax.user)
                  : null,
            ),
            if (member.verified)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified,
                    size: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.fullname.isNotEmpty
                    ? member.fullname
                    : member.username ?? 'مستخدم',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (member.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.shield,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'مسؤول',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: member.username != null
            ? Text(
                '@${member.username}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            : null,
        trailing: (widget.isAdmin || _isOwner) && 
                  member.userId != widget.group.admin.userId
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMemberAction(value, member),
                itemBuilder: (context) => [
                  // تعيين كمسؤول: للمالك فقط
                  if (!member.isAdmin && _isOwner)
                    const PopupMenuItem(
                      value: 'make_admin',
                      child: Row(
                        children: [
                          Icon(Iconsax.shield_tick, size: 20),
                          SizedBox(width: 12),
                          Text('تعيين كمسؤول'),
                        ],
                      ),
                    ),
                  // إزالة صلاحيات المشرف: للمالك فقط
                  if (member.isAdmin && _isOwner)
                    const PopupMenuItem(
                      value: 'remove_admin',
                      child: Row(
                        children: [
                          Icon(Iconsax.shield_cross, size: 20, color: Colors.orange),
                          SizedBox(width: 12),
                          Text('إزالة صلاحيات المشرف', style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                  // إزالة عضو عادي: للمالك والأدمن
                  if (!member.isAdmin && (widget.isAdmin || _isOwner))
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Iconsax.user_remove, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('إزالة العضو', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              )
            : null,
      ),
    );
  }

  void _handleMemberAction(String action, GroupMember member) {
    switch (action) {
      case 'make_admin':
        _makeAdmin(member);
        break;
      case 'remove_admin':
        _removeAdmin(member);
        break;
      case 'remove':
        _removeMember(member);
        break;
    }
  }

  Future<void> _makeAdmin(GroupMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعيين مسؤول'),
        content: Text(
          'هل تريد تعيين ${member.fullname.isNotEmpty ? member.fullname : member.username} كمسؤول للمجموعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _groupsService.makeAdmin(
          widget.group.groupId,
          member.userId,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تعيين العضو كمسؤول بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload members list
          _loadMembers(refresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: ${e.toString().contains('404') ? 'الميزة قيد التطوير' : 'فشل تعيين المسؤول'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeAdmin(GroupMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إزالة صلاحيات المشرف'),
        content: Text(
          'هل تريد إزالة صلاحيات المشرف من ${member.fullname.isNotEmpty ? member.fullname : member.username} وتحويله إلى عضو عادي؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('إزالة الصلاحيات'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _groupsService.removeAdmin(
          widget.group.groupId,
          member.userId,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إزالة صلاحيات المشرف بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload members list
          _loadMembers(refresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: ${e.toString().contains('404') ? 'الميزة قيد التطوير' : 'فشل إزالة صلاحيات المشرف'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeMember(GroupMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إزالة عضو'),
        content: Text(
          'هل تريد إزالة ${member.fullname.isNotEmpty ? member.fullname : member.username} من المجموعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _groupsService.removeMember(
          widget.group.groupId,
          member.userId,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إزالة العضو بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload members list
          _loadMembers(refresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: فشل إزالة العضو'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
