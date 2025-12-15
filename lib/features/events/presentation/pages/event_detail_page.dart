import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:snginepro/features/events/application/bloc/events_bloc.dart';
import 'package:snginepro/features/events/application/bloc/events_events.dart';
import 'package:snginepro/features/events/application/bloc/events_states.dart';
import 'package:snginepro/features/events/data/models/event.dart';
import 'package:snginepro/features/events/presentation/pages/create_event_page.dart';
import 'package:snginepro/features/events/presentation/pages/invite_friends_to_event_page.dart';
import 'package:snginepro/features/events/presentation/pages/event_members_page.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/presentation/widgets/post_card.dart';
import 'package:snginepro/features/feed/presentation/pages/create_post_page_modern.dart';
import 'package:snginepro/features/feed/data/datasources/posts_api_service.dart';
import 'package:snginepro/features/feed/data/models/upload_file_data.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:intl/intl.dart';
class EventDetailPage extends StatefulWidget {
  final int eventId;
  const EventDetailPage({
    super.key,
    required this.eventId,
  });
  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}
class _EventDetailPageState extends State<EventDetailPage> {
  Event? _currentEvent;
  List<Post> _posts = [];
  bool _isLoadingPosts = false;
  bool _hasMorePosts = true;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    // تنظيف البيانات القديمة
    _currentEvent = null;
    _posts.clear();
    _isLoadingPosts = false;
    _hasMorePosts = true;
    // Always load event details from API using eventId
    context.read<EventsBloc>().add(FetchEventDetailsEvent(widget.eventId));
    // Load event posts
    context
        .read<EventsBloc>()
        .add(FetchEventPostsEvent(eventId: widget.eventId, refresh: true));
    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }
  @override
  void didUpdateWidget(EventDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If eventId changed, reload everything
    if (oldWidget.eventId != widget.eventId) {
      setState(() {
        _currentEvent = null;
        _posts.clear();
        _hasMorePosts = true;
        _isLoadingPosts = false;
      });
      // Load new event
      context.read<EventsBloc>().add(FetchEventDetailsEvent(widget.eventId));
      context.read<EventsBloc>().add(FetchEventPostsEvent(eventId: widget.eventId));
    }
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingPosts &&
        _hasMorePosts) {
      // Load more posts (pagination will be handled by bloc)
      setState(() => _isLoadingPosts = true);
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Get.theme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: _buildCreatePostFAB(),
      body: BlocListener<EventsBloc, EventsState>(
        listener: (context, state) {
          if (state is EventDetailsLoaded) {
            // Only update if it's for the current event
            if (state.event.eventId == widget.eventId) {
              setState(() {
                _currentEvent = state.event;
              });
              // Debug: Print i_admin value
            }
          } else if (state is EventPostsLoaded) {
            setState(() {
              // استبدال القائمة بالكامل بدلاً من الإضافة
              _posts = state.posts.map((p) => Post.fromJson(p)).toList();
              _hasMorePosts = state.hasMore;
              _isLoadingPosts = false;
            });
          } else if (state is EventJoined) {
            Get.snackbar(
              'success'.tr,
              state.message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            // Reload event details
            context
                .read<EventsBloc>()
                .add(FetchEventDetailsEvent(widget.eventId));
          } else if (state is EventLeft) {
            Get.snackbar(
              'success'.tr,
              state.message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
            // Reload event details
            context
                .read<EventsBloc>()
                .add(FetchEventDetailsEvent(widget.eventId));
          } else if (state is EventDeleted) {
            Get.snackbar(
              'success'.tr,
              state.message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            Navigator.pop(context);
          } else if (state is EventPictureUpdated) {
            setState(() {
              _currentEvent = state.event;
            });
            Get.snackbar(
              'success'.tr,
              'event_picture_updated'.tr,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else if (state is EventCoverUpdated) {
            setState(() {
              _currentEvent = state.event;
            });
            Get.snackbar(
              'success'.tr,
              'event_cover_updated'.tr,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else if (state is EventsError) {
            Get.snackbar(
              'error'.tr,
              state.message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        child: _currentEvent == null
            ? _buildLoadingState()
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEventInfo(),
                        _buildActionButtons(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  _buildPostsList(),
                ],
              ),
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
            'loading_events'.tr,
            style: Get.theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAppBar() {
    final event = _currentEvent!;
    final isDark = Get.isDarkMode;
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: event.eventCover != null && event.eventCover!.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: event.eventCover!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: isDark ? Colors.grey[850] : Colors.grey[200],
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: isDark ? Colors.grey[850] : Colors.grey[200],
                      child: const Icon(
                        Iconsax.calendar,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // زر تعديل الغلاف للمسؤول
                  if (event.iAdmin)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton.small(
                        onPressed: _updateEventCover,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: Icon(
                          Iconsax.camera,
                          color: Get.theme.primaryColor,
                        ),
                      ),
                    ),
                ],
              )
            : Container(
                color: isDark ? Colors.grey[850] : Colors.grey[200],
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Iconsax.calendar,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                    // زر إضافة غلاف للمسؤول
                    if (event.iAdmin)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton.small(
                          onPressed: _updateEventCover,
                          backgroundColor: Get.theme.primaryColor,
                          child: const Icon(
                            Iconsax.camera,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        if (event.iAdmin)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateEventPage(event: _currentEvent),
                  ),
                );
                // Reload event details if it was updated
                if (result == true && _currentEvent != null) {
                  context
                      .read<EventsBloc>()
                      .add(FetchEventDetailsEvent(_currentEvent!.eventId));
                }
              } else if (value == 'update_picture') {
                _updateEventPicture();
              } else if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Iconsax.edit),
                    const SizedBox(width: 12),
                    Text('edit_event'.tr),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'update_picture',
                child: Row(
                  children: [
                    const Icon(Iconsax.image),
                    const SizedBox(width: 12),
                    Text('update_event_picture'.tr),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Iconsax.trash, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      'delete_event'.tr,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
  Widget _buildEventInfo() {
    final event = _currentEvent!;
    final theme = Get.theme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Title
          Text(
            event.eventTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Date & Time
          _buildInfoRow(
            icon: Iconsax.calendar_1,
            title: 'start_date'.tr,
            value: _formatDateTime(event.eventStartDate),
          ),
          if (event.eventEndDate != event.eventStartDate)
            _buildInfoRow(
              icon: Iconsax.calendar,
              title: 'end_date'.tr,
              value: _formatDateTime(event.eventEndDate),
            ),
          // Location
          if (event.eventLocation != null && event.eventLocation!.isNotEmpty)
            _buildInfoRow(
              icon: Iconsax.location,
              title: 'event_location'.tr,
              value: event.eventLocation!,
            ),
          // Online/In-person
          _buildInfoRow(
            icon: event.eventIsOnline ? Iconsax.video : Iconsax.people,
            title: event.eventIsOnline ? 'Online Event' : 'In-Person Event',
            value: '',
          ),
          // Privacy
          _buildInfoRow(
            icon: Iconsax.shield_tick,
            title: 'event_privacy'.tr,
            value: event.eventPrivacy == 'public'
                ? 'privacy_public'.tr
                : 'privacy_private'.tr,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Organizer
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: event.adminPicture != null &&
                        event.adminPicture!.isNotEmpty
                    ? CachedNetworkImageProvider(event.adminPicture!)
                    : null,
                child: event.adminPicture == null || event.adminPicture!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          event.adminFullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (event.isVerified)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      'organizer'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Description
          if (event.eventDescription != null &&
              event.eventDescription!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'event_description'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.eventDescription!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          // Stats
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Iconsax.people,
                  label: 'going'.tr,
                  count: event.eventMembers,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Iconsax.heart,
                  label: 'interested'.tr,
                  count: event.eventInterested,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Get.theme;
    final isDark = Get.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                if (value.isNotEmpty)
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    final isDark = Get.isDarkMode;
    final theme = Get.theme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildActionButtons() {
    final event = _currentEvent!;
    final theme = Get.theme;
    if (event.iAdmin) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateEventPage(event: _currentEvent),
                        ),
                      );
                      // Reload event details if it was updated
                      if (result == true && _currentEvent != null) {
                        context
                            .read<EventsBloc>()
                            .add(FetchEventDetailsEvent(_currentEvent!.eventId));
                      }
                    },
                    icon: const Icon(Iconsax.edit),
                    label: Text('edit_event'.tr),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.to(() => InviteFriendsToEventPage(
                        eventId: event.eventId,
                        eventTitle: event.eventTitle,
                      ));
                    },
                    icon: const Icon(Iconsax.user_add),
                    label: Text('invite_friends'.tr),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.to(() => EventMembersPage(
                    eventId: event.eventId,
                    eventTitle: event.eventTitle,
                    isAdmin: event.iAdmin,
                  ));
                },
                icon: const Icon(Iconsax.people),
                label: Text('events_members'.tr),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: event.iJoined
                  ? () => _handleLeaveEvent()
                  : () => _handleJoinEvent('interested'),
              icon: Icon(
                event.iJoined ? Iconsax.heart_slash : Iconsax.heart,
              ),
              label: Text(
                event.iJoined ? 'leave_event'.tr : 'interested'.tr,
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: event.iJoined
                  ? null
                  : () => _handleJoinEvent('going'),
              icon: const Icon(Iconsax.tick_circle),
              label: Text(event.iJoined ? 'going'.tr : 'join_event'.tr),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPostsList() {
    if (_posts.isEmpty && _isLoadingPosts) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_posts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.document_text,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'no_posts_yet'.tr,
                style: Get.theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to share something!',
                style: Get.theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < _posts.length) {
            return PostCard(
              key: ValueKey('event-post-${_posts[index].id}'),
              post: _posts[index],
              onReactionChanged: (postId, reaction) {
                // Update post reaction locally
                setState(() {
                  final postIndex = _posts.indexWhere((p) => p.id.toString() == postId);
                  if (postIndex != -1) {
                    _posts[postIndex] = _posts[postIndex].copyWith(
                      myReaction: reaction,
                    );
                  }
                });
              },
              onPostUpdated: (updatedPost) {
                setState(() {
                  final postIndex = _posts.indexWhere((p) => p.id == updatedPost.id);
                  if (postIndex != -1) {
                    _posts[postIndex] = updatedPost;
                  }
                });
              },
              onPostDeleted: (postId) {
                setState(() {
                  _posts.removeWhere((p) => p.id.toString() == postId);
                });
              },
            );
          } else if (_hasMorePosts) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return const SizedBox.shrink();
        },
        childCount: _posts.length + (_hasMorePosts ? 1 : 0),
      ),
    );
  }
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('EEEE, MMM dd, yyyy • hh:mm a').format(dateTime);
  }
  void _handleJoinEvent(String action) {
    context.read<EventsBloc>().add(
          JoinEventEvent(
            eventId: widget.eventId,
            action: action,
          ),
        );
  }
  void _handleLeaveEvent() {
    context.read<EventsBloc>().add(LeaveEventEvent(widget.eventId));
  }
  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        title: Text('delete_event'.tr),
        content: Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<EventsBloc>()
                  .add(DeleteEventEvent(widget.eventId));
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }
  /// Build FAB for creating posts (only for joined members)
  Widget? _buildCreatePostFAB() {
    if (_currentEvent == null || !_currentEvent!.iJoined) {
      return null;
    }
    return FloatingActionButton.extended(
      onPressed: _openCreatePost,
      icon: const Icon(Iconsax.edit),
      label: Text('create_post'.tr),
      backgroundColor: Get.theme.colorScheme.primary,
      foregroundColor: Colors.white,
    );
  }
  /// Open create post page for this event
  void _openCreatePost() {
    if (_currentEvent == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => CreatePostPageModern(
            handle: 'event',
            handleId: _currentEvent!.eventId,
            handleName: _currentEvent!.eventTitle,
          ),
        ))
        .then((_) {
          // Clear and reload event posts after creating new post
          setState(() {
            _posts.clear();
            _hasMorePosts = true;
          });
          context
              .read<EventsBloc>()
              .add(FetchEventPostsEvent(eventId: widget.eventId));
        });
  }
  /// اختيار وتحديث غلاف الفعالية
  Future<void> _updateEventCover() async {
    if (_currentEvent == null) return;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      try {
        // عرض loading
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
        // رفع الصورة أولاً
        final apiClient = context.read<ApiClient>();
        final apiService = PostsApiService(apiClient);
        final uploadResult = await apiService.uploadFile(
          File(image.path),
          type: FileUploadType.photo,
        );
        // إغلاق loading
        if (Get.isDialogOpen ?? false) Get.back();
        if (uploadResult != null) {
          if (mounted) {
            // إرسال source للـ API
            context.read<EventsBloc>().add(UpdateEventCoverEvent(
                  eventId: _currentEvent!.eventId,
                  coverData: uploadResult.source,
                ));
          } else {
          }
        } else {
          Get.snackbar(
            'error'.tr,
            'failed_to_upload_image'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        // إغلاق loading
        if (Get.isDialogOpen ?? false) Get.back();
        Get.snackbar(
          'error'.tr,
          'failed_to_upload_image'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
  /// اختيار وتحديث صورة الفعالية
  Future<void> _updateEventPicture() async {
    if (_currentEvent == null) return;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      try {
        // عرض loading
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
        // رفع الصورة أولاً
        final apiClient = context.read<ApiClient>();
        final apiService = PostsApiService(apiClient);
        final uploadResult = await apiService.uploadFile(
          File(image.path),
          type: FileUploadType.photo,
        );
        // إغلاق loading
        if (Get.isDialogOpen ?? false) Get.back();
        if (uploadResult != null) {
          if (mounted) {
            // إرسال source للـ API
            context.read<EventsBloc>().add(UpdateEventPictureEvent(
                  eventId: _currentEvent!.eventId,
                  pictureData: uploadResult.source,
                ));
          }
        } else {
          Get.snackbar(
            'error'.tr,
            'failed_to_upload_image'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        // إغلاق loading
        if (Get.isDialogOpen ?? false) Get.back();
        Get.snackbar(
          'error'.tr,
          'failed_to_upload_image'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}
