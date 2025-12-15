import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../application/bloc/events_bloc.dart';
import '../../application/bloc/events_events.dart';
import '../../application/bloc/events_states.dart';
import '../../data/models/event_member.dart';
import '../../../profile/presentation/pages/profile_page.dart';
class EventMembersPage extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final bool isAdmin;
  const EventMembersPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.isAdmin = false,
  });
  @override
  State<EventMembersPage> createState() => _EventMembersPageState();
}
class _EventMembersPageState extends State<EventMembersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  String? _selectedType; // going, interested, invited
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    // Load initial data (All members)
    _loadMembers();
  }
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadMembers();
    }
  }
  void _loadMembers() {
    String? type;
    switch (_tabController.index) {
      case 0: // All
        type = null;
        break;
      case 1: // Going
        type = 'going';
        break;
      case 2: // Interested
        type = 'interested';
        break;
    }
    setState(() {
      _selectedType = type;
    });
    context.read<EventsBloc>().add(FetchEventMembersEvent(
          eventId: widget.eventId,
          type: type,
          refresh: true,
        ));
  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // TODO: Load more members (pagination)
    }
  }
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Get.theme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'events_members'.tr,
              style: theme.textTheme.titleLarge,
            ),
            Text(
              widget.eventTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Iconsax.people),
              text: 'all'.tr,
            ),
            Tab(
              icon: const Icon(Iconsax.tick_circle),
              text: 'going'.tr,
            ),
            Tab(
              icon: const Icon(Iconsax.heart),
              text: 'interested'.tr,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMembersList(),
          _buildMembersList(),
          _buildMembersList(),
        ],
      ),
    );
  }
  Widget _buildMembersList() {
    return BlocBuilder<EventsBloc, EventsState>(
      builder: (context, state) {
        if (state is EventsLoading) {
          return _buildLoadingState();
        }
        if (state is EventMembersLoaded) {
          if (state.members.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              _loadMembers();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.members.length,
              itemBuilder: (context, index) {
                return _buildMemberCard(state.members[index]);
              },
            ),
          );
        }
        if (state is EventsError) {
          return _buildErrorState(state.message);
        }
        return const SizedBox();
      },
    );
  }
  Widget _buildMemberCard(EventMember member) {
    final theme = Get.theme;
    return InkWell(
      onTap: () {
        // الانتقال لصفحة البروفايل
        Get.to(() => ProfilePage(
          userId: int.tryParse(member.userId),
          username: member.userName,
        ));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // صورة العضو
            CircleAvatar(
              radius: 28,
              backgroundImage: member.userPicture != null
                  ? CachedNetworkImageProvider(member.userPicture!)
                  : null,
              child: member.userPicture == null
                  ? Icon(
                      Iconsax.user,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // معلومات العضو
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '@${member.userName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getMembershipColor(member.membershipStatus)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getMembershipLabel(member.membershipStatus),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getMembershipColor(member.membershipStatus),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // زر الخيارات للـ Admin
            if (widget.isAdmin)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'remove') {
                    _showRemoveMemberDialog(member);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        const Icon(Iconsax.user_remove, color: Colors.red),
                        const SizedBox(width: 12),
                        Text(
                          'remove_member'.tr,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  Color _getMembershipColor(String type) {
    switch (type.toLowerCase()) {
      case 'going':
        return Colors.green;
      case 'interested':
        return Colors.orange;
      case 'invited':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  String _getMembershipLabel(String type) {
    switch (type.toLowerCase()) {
      case 'going':
        return 'going'.tr;
      case 'interested':
        return 'interested'.tr;
      case 'invited':
        return 'invited'.tr;
      default:
        return type;
    }
  }
  void _showRemoveMemberDialog(EventMember member) {
    Get.dialog(
      AlertDialog(
        title: Text('remove_member'.tr),
        content: Text(
          'remove_member_confirmation'
              .trParams({'name': member.fullName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // TODO: Implement remove member functionality
              Get.snackbar(
                'info'.tr,
                'feature_coming_soon'.tr,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('remove'.tr),
          ),
        ],
      ),
    );
  }
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Get.theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'loading_members'.tr,
            style: Get.theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyState() {
    final theme = Get.theme;
    String message;
    switch (_selectedType) {
      case 'going':
        message = 'no_going_members'.tr;
        break;
      case 'interested':
        message = 'no_interested_members'.tr;
        break;
      default:
        message = 'لا يوجد أعضاء بعد'; // استخدام النص مباشرة
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.user_search,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.danger,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Get.theme.textTheme.bodyMedium?.copyWith(
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadMembers,
            icon: const Icon(Iconsax.refresh),
            label: Text('retry'.tr),
          ),
        ],
      ),
    );
  }
}
