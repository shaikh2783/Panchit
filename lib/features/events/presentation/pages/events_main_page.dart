import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../application/bloc/events_bloc.dart';
import '../../application/bloc/events_events.dart';
import '../../application/bloc/events_states.dart';
import '../../data/models/event.dart';
import '../../data/models/event_category.dart';
import '../widgets/event_card.dart';
import 'create_event_page.dart';
import 'event_detail_page.dart';
class EventsMainPage extends StatefulWidget {
  const EventsMainPage({super.key});
  @override
  State<EventsMainPage> createState() => _EventsMainPageState();
}
class _EventsMainPageState extends State<EventsMainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  // للفلترة في Discover tab
  EventCategory? _selectedCategory;
  // Categories من API
  List<EventCategory> _categories = [];
  bool _categoriesLoading = true;
  // للبحث
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    // تحميل التصنيفات أولاً
    _loadCategories();
    // تحميل البيانات الأولية
    _loadData();
  }
  void _loadCategories() {
    context.read<EventsBloc>().add(const FetchEventCategoriesEvent());
  }
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadData();
    }
  }
  void _loadData() {
    final bloc = context.read<EventsBloc>();
    final currentTab = _tabController.index;
    switch (currentTab) {
      case 0: // Discover
        bloc.add(FetchSuggestedEventsEvent(
          categoryId: _selectedCategory?.categoryId,
          refresh: true, // دائماً نحمل من جديد
        ));
        break;
      case 1: // Going
        bloc.add(const FetchMyEventsEvent(filter: 'going', refresh: true));
        break;
      case 2: // Interested
        bloc.add(const FetchMyEventsEvent(filter: 'interested', refresh: true));
        break;
      case 3: // Invited
        bloc.add(const FetchMyEventsEvent(filter: 'invited', refresh: true));
        break;
      case 4: // My Events
        bloc.add(const FetchMyEventsEvent(filter: 'admin', refresh: true));
        break;
    }
  }  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more based on current tab
      // TODO: Add pagination logic
    }
  }
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Get.theme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('events'.tr),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_circle),
            onPressed: () {
              Get.to(() => const CreateEventPage());
            },
            tooltip: 'create_event'.tr,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              icon: const Icon(Iconsax.discover),
              text: 'discover'.tr,
            ),
            Tab(
              icon: const Icon(Iconsax.tick_circle),
              text: 'going'.tr,
            ),
            Tab(
              icon: const Icon(Iconsax.heart),
              text: 'interested'.tr,
            ),
            Tab(
              icon: const Icon(Iconsax.user_add),
              text: 'invited'.tr,
            ),
            Tab(
              icon: const Icon(Iconsax.calendar),
              text: 'my_events'.tr,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTab(),
          _buildTabContent('going'),
          _buildTabContent('interested'),
          _buildTabContent('invited'),
          _buildTabContent('admin'),
        ],
      ),
    );
  }
  // Discover Tab مع فلترة Categories وزر البحث
  Widget _buildDiscoverTab() {
    final theme = Get.theme;
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'search_events'.tr,
              prefixIcon: const Icon(Iconsax.search_normal_1),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Iconsax.close_circle),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _isSearching = false;
                          _searchQuery = '';
                        });
                        // إعادة تحميل الفعاليات العادية
                        _loadData();
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (query) {
              if (query.trim().isNotEmpty) {
                setState(() {
                  _isSearching = true;
                  _searchQuery = query.trim();
                });
                // البحث عن فعاليات
                context.read<EventsBloc>().add(SearchEventsEvent(query.trim()));
              }
            },
          ),
        ),
        // Category Filter
        _buildCategoryFilter(),
        // Search Results Header
        if (_isSearching && _searchQuery.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Iconsax.search_normal_1, size: 20, color: theme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'search_results_for'.trParams({'query': _searchQuery}),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Events List
        Expanded(
          child: _buildTabContent('discover'),
        ),
      ],
    );
  }
  Widget _buildCategoryFilter() {
    final theme = Get.theme;
    return BlocListener<EventsBloc, EventsState>(
      listener: (context, state) {
        if (state is EventCategoriesLoaded) {
          setState(() {
            _categories = state.categories;
            _categoriesLoading = false;
          });
        }
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: _categoriesLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _categories.length + 1, // +1 for "All"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // "All" chip
                    final isSelected = _selectedCategory == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('all'.tr),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = null;
                            });
                            _loadData();
                          }
                        },
                        selectedColor: theme.primaryColor,
                        backgroundColor: theme.scaffoldBackgroundColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    );
                  }
                  final category = _categories[index - 1];
                  final isSelected = _selectedCategory?.categoryId == category.categoryId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category.categoryName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategory = category;
                          } else {
                            _selectedCategory = null;
                          }
                        });
                        // إعادة تحميل مع الفلترة الجديدة
                        _loadData();
                      },
                      selectedColor: theme.primaryColor,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
  Widget _buildTabContent(String type) {
    return BlocBuilder<EventsBloc, EventsState>(
      builder: (context, state) {
        // حالة التحميل
        if (state is EventsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        // حالة الخطأ
        if (state is EventsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.danger, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: Get.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadData(),
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }
        // استخراج البيانات
        List<Event> events = [];
        if (state is SuggestedEventsLoaded && type == 'discover') {
          events = state.events;
        } else if (state is MyEventsLoaded && type != 'discover') {
          events = state.events;
        } else if (state is EventsSearchResultsLoaded) {
          // نتائج البحث
          events = state.events;
        }
        // حالة Empty
        if (events.isEmpty) {
          return _buildEmptyState(type);
        }
        // عرض القائمة
        return RefreshIndicator(
          onRefresh: () async {
            _loadData();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: EventCard(
                  event: events[index],
                  onTap: () async {
                    // التوجه لصفحة تفاصيل الفعالية
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailPage(
                          eventId: events[index].eventId,
                        ),
                      ),
                    );
                    // إعادة تحميل البيانات بعد الرجوع
                    _loadData();
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
  Widget _buildEmptyState(String type) {
    final theme = Get.theme;
    String title;
    String subtitle;
    IconData icon;
    switch (type) {
      case 'discover':
        title = 'no_events_found'.tr;
        subtitle = 'try_different_category'.tr;
        icon = Iconsax.search_normal;
        break;
      case 'going':
        title = 'no_going_events'.tr;
        subtitle = 'join_events_to_see_them_here'.tr;
        icon = Iconsax.calendar_tick;
        break;
      case 'interested':
        title = 'no_interested_events'.tr;
        subtitle = 'mark_events_interested'.tr;
        icon = Iconsax.heart;
        break;
      case 'invited':
        title = 'no_invitations'.tr;
        subtitle = 'wait_for_friends_invitations'.tr;
        icon = Iconsax.user_add;
        break;
      case 'admin':
        title = 'no_created_events'.tr;
        subtitle = 'create_your_first_event'.tr;
        icon = Iconsax.add_circle;
        break;
      default:
        title = 'no_events'.tr;
        subtitle = '';
        icon = Iconsax.calendar;
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (type == 'admin') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Get.to(() => const CreateEventPage());
              },
              icon: const Icon(Iconsax.add_circle),
              label: Text('create_event'.tr),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
