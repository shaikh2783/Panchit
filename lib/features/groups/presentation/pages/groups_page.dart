import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/group.dart';
import '../../data/models/groups_response.dart';
import '../../data/repositories/groups_repository.dart';
import '../../data/services/groups_api_service.dart';
import '../../application/bloc/group_posts_bloc.dart';
import '../widgets/group_card.dart';
import 'group_profile_page.dart';
import 'groups_search_page.dart';
import 'create_group_page.dart';

/// صفحة المجموعات الرئيسية مع Tabs
class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GroupsRepository _repository;

  // حالة التحميل والبيانات
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  // البيانات
  List<Group> _joinedGroups = [];
  List<Group> _managedGroups = [];
  List<Group> _suggestedGroups = [];
  GroupsStats? _stats;

  // Pagination
  int _joinedPage = 1;
  int _managedPage = 1;
  int _suggestedPage = 1;
  bool _hasMoreJoined = true;
  bool _hasMoreManaged = true;
  bool _hasMoreSuggested = true;

  // Controllers للـ Scroll
  late ScrollController _joinedScrollController;
  late ScrollController _managedScrollController;
  late ScrollController _suggestedScrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // تهيئة Repository
    final apiClient = context.read<ApiClient>();
    _repository = GroupsRepository(GroupsApiService(apiClient));

    // تهيئة Scroll Controllers
    _joinedScrollController = ScrollController()..addListener(_onJoinedScroll);
    _managedScrollController = ScrollController()
      ..addListener(_onManagedScroll);
    _suggestedScrollController = ScrollController()
      ..addListener(_onSuggestedScroll);

    // جلب البيانات
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _joinedScrollController.dispose();
    _managedScrollController.dispose();
    _suggestedScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // جلب كل tab على حدة (لأن endpoint المجمّع غير متوفر حالياً في Backend)
      await _loadTabsSeparately();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'فشل تحميل المجموعات';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTabsSeparately() async {
    try {
      final results = await Future.wait([
        _repository.getJoinedGroups(),
        _repository.getManagedGroups(),
        _repository.getSuggestedGroups(),
      ]);

      if (!mounted) return;

      setState(() {
        _joinedGroups = results[0];
        _managedGroups = results[1];
        _suggestedGroups = results[2];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'groups_load_failed'.tr;
        _isLoading = false;
      });
    }
  }

  // Pagination Listeners
  void _onJoinedScroll() {
    if (_joinedScrollController.position.pixels >=
        _joinedScrollController.position.maxScrollExtent - 200) {
      if (_hasMoreJoined && !_isLoadingMore) {
        _loadMoreJoined();
      }
    }
  }

  void _onManagedScroll() {
    if (_managedScrollController.position.pixels >=
        _managedScrollController.position.maxScrollExtent - 200) {
      if (_hasMoreManaged && !_isLoadingMore) {
        _loadMoreManaged();
      }
    }
  }

  void _onSuggestedScroll() {
    if (_suggestedScrollController.position.pixels >=
        _suggestedScrollController.position.maxScrollExtent - 200) {
      if (_hasMoreSuggested && !_isLoadingMore) {
        _loadMoreSuggested();
      }
    }
  }

  Future<void> _loadMoreJoined() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      _joinedPage++;
      final newGroups = await _repository.getJoinedGroups(page: _joinedPage);

      if (!mounted) return;

      setState(() {
        _joinedGroups.addAll(newGroups);
        _hasMoreJoined = newGroups.isNotEmpty;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadMoreManaged() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      _managedPage++;
      final newGroups = await _repository.getManagedGroups(page: _managedPage);

      if (!mounted) return;

      setState(() {
        _managedGroups.addAll(newGroups);
        _hasMoreManaged = newGroups.isNotEmpty;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadMoreSuggested() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      _suggestedPage++;
      final newGroups = await _repository.getSuggestedGroups(
        page: _suggestedPage,
      );

      if (!mounted) return;

      setState(() {
        _suggestedGroups.addAll(newGroups);
        _hasMoreSuggested = newGroups.isNotEmpty;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onJoinGroup(Group group) async {
    final success = await _repository.joinGroup(group.groupId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            group.groupPrivacy.requiresApproval
                ? 'groups_join_request_sent'.tr
                : 'groups_join_success'.tr,
          ),
          backgroundColor: Colors.green,
        ),
      );

      // تحديث البيانات
      _loadInitialData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل الانضمام للمجموعة'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onLeaveGroup(Group group) async {
    // تأكيد المغادرة
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('groups_leave_confirm_title'.tr),
        content: Text('groups_leave_confirm_message'.trParams({'title': group.groupTitle})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('groups_leave_button'.tr),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _repository.leaveGroup(group.groupId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('groups_leave_success'.tr),
          backgroundColor: Colors.green,
        ),
      );

      // تحديث البيانات
      _loadInitialData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('groups_leave_failed'.tr),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onGroupTap(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => GroupPostsBloc(_repository),
          child: GroupProfilePage(groupId: group.groupId),
        ),
      ),
    ).then((_) {
      // تحديث البيانات عند العودة
      _loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.people, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'groups_page_title'.tr,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.grey[900],
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.search_normal),
            tooltip: 'groups_search_tooltip'.tr,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GroupsSearchPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Iconsax.add_circle),
            tooltip: 'groups_create_tooltip'.tr,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupPage(),
                ),
              );
              // تحديث القوائم إذا تم إنشاء مجموعة
              if (result == true) {
                _loadTabsSeparately();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark
                  ? Colors.grey[400]
                  : Colors.grey[600],
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('groups_tab_joined'.tr),
                      if (_stats != null && _stats!.totalJoined > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_stats!.totalJoined}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('groups_tab_managed'.tr),
                      if (_stats != null && _stats!.totalManaged > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_stats!.totalManaged}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(text: 'groups_tab_suggested'.tr),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGroupsList(
                  _joinedGroups,
                  _joinedScrollController,
                  'groups_empty_joined',
                ),
                _buildGroupsList(
                  _managedGroups,
                  _managedScrollController,
                  'groups_empty_managed',
                ),
                _buildGroupsList(
                  _suggestedGroups,
                  _suggestedScrollController,
                  'groups_empty_suggested',
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.info_circle, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: Text('retry_button'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(
    List<Group> groups,
    ScrollController scrollController,
    String emptyMessageKey,
  ) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.people, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessageKey.tr,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: groups.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == groups.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final group = groups[index];

          return GroupCard(
            group: group,
            onTap: () => _onGroupTap(group),
            onJoinTap: () => _onJoinGroup(group),
            onLeaveTap: () => _onLeaveGroup(group),
          );
        },
      ),
    );
  }
}
