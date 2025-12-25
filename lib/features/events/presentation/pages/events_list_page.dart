import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/events/application/bloc/events_bloc.dart';
import 'package:snginepro/features/events/application/bloc/events_events.dart';
import 'package:snginepro/features/events/application/bloc/events_states.dart';
import 'package:snginepro/features/events/presentation/widgets/event_card.dart';
import 'package:snginepro/features/events/presentation/pages/event_detail_page.dart';
import 'package:snginepro/features/events/presentation/pages/create_event_page.dart';
import 'package:snginepro/features/events/data/models/event.dart';

class EventsListPage extends StatefulWidget {
  const EventsListPage({super.key});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Store events locally
  List<Event> _suggestedEvents = [];
  List<Event> _myEvents = [];
  List<Event> _searchResults = [];

  bool _isLoadingSuggested = false;
  bool _isLoadingMy = false;
  bool _isSearching = false;
  
  bool _hasMoreSuggested = true;
  bool _hasMoreMy = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load initial data
    context.read<EventsBloc>().add(const FetchSuggestedEventsEvent());
    context.read<EventsBloc>().add(const FetchMyEventsEvent());

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Setup tab listener
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      if (_tabController.index == 0 && !_isLoadingSuggested && _hasMoreSuggested) {
        context.read<EventsBloc>().add(const FetchSuggestedEventsEvent());
      } else if (_tabController.index == 1 && !_isLoadingMy && _hasMoreMy) {
        context.read<EventsBloc>().add(const FetchMyEventsEvent());
      }
    }
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      return;
    }
    context.read<EventsBloc>().add(SearchEventsEvent(query));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final theme = Get.theme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'events'.tr,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.search_normal),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: const Icon(Iconsax.add_circle),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateEventPage(),
                ),
              );
              
              // Refresh list if event was created
              if (result == true) {
                context
                    .read<EventsBloc>()
                    .add(const FetchSuggestedEventsEvent(refresh: true));
                context
                    .read<EventsBloc>()
                    .add(const FetchMyEventsEvent(refresh: true));
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          tabs: [
            Tab(text: 'suggested_events'.tr),
            Tab(text: 'my_events'.tr),
            Tab(text: 'search'.tr),
          ],
        ),
      ),
      body: BlocListener<EventsBloc, EventsState>(
        listener: (context, state) {
          if (state is SuggestedEventsLoaded) {
            setState(() {
              _suggestedEvents = state.events;
              _isLoadingSuggested = false;
              _hasMoreSuggested = state.hasMore;
            });
          } else if (state is MyEventsLoaded) {
            setState(() {
              _myEvents = state.events;
              _isLoadingMy = false;
              _hasMoreMy = state.hasMore;
            });
          } else if (state is EventsSearchResultsLoaded) {
            setState(() {
              _searchResults = state.events;
              _isSearching = false;
            });
          } else if (state is EventsLoading) {
            setState(() {
              if (_tabController.index == 0) {
                _isLoadingSuggested = true;
              } else if (_tabController.index == 1) {
                _isLoadingMy = true;
              } else {
                _isSearching = true;
              }
            });
          } else if (state is EventsError) {
            setState(() {
              _isLoadingSuggested = false;
              _isLoadingMy = false;
              _isSearching = false;
            });
            Get.snackbar(
              'error'.tr,
              state.message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            // Suggested Events
            _buildSuggestedEventsTab(),

            // My Events
            _buildMyEventsTab(),

            // Search
            _buildSearchTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedEventsTab() {
    if (_isLoadingSuggested && _suggestedEvents.isEmpty) {
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

    if (_suggestedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.calendar,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'no_events_found'.tr,
              style: Get.theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<EventsBloc>()
                    .add(const FetchSuggestedEventsEvent(refresh: true));
              },
              icon: const Icon(Iconsax.refresh),
              label: Text('try_again'.tr),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<EventsBloc>()
            .add(const FetchSuggestedEventsEvent(refresh: true));
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: _suggestedEvents.length + (_isLoadingSuggested ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _suggestedEvents.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final event = _suggestedEvents[index];
          return EventCard(
            event: event,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailPage(
                    eventId: event.eventId,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMyEventsTab() {
    if (_isLoadingMy && _myEvents.isEmpty) {
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

    if (_myEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.calendar,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'no_events_found'.tr,
              style: Get.theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first event!',
              style: Get.theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<EventsBloc>()
            .add(const FetchMyEventsEvent(refresh: true));
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: _myEvents.length + (_isLoadingMy ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _myEvents.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final event = _myEvents[index];
          return EventCard(
            event: event,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailPage(
                    eventId: event.eventId,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'search_events'.tr,
              prefixIcon: const Icon(Iconsax.search_normal),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Iconsax.close_circle),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Get.isDarkMode ? Colors.grey[850] : Colors.grey[100],
            ),
            onSubmitted: _onSearch,
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),

        // Search Results
        Expanded(
          child: _isSearching
              ? Center(
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
                )
              : _searchResults.isEmpty && _searchController.text.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.search_normal,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'search_events'.tr,
                            style: Get.theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.search_status,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'no_events_found'.tr,
                                style: Get.theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final event = _searchResults[index];
                            return EventCard(
                              event: event,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventDetailPage(
                                      eventId: event.eventId,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('search_events'.tr),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'event_title'.tr,
              prefixIcon: const Icon(Iconsax.search_normal),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _searchController.text = value;
                _tabController.animateTo(2);
                _onSearch(value);
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _searchController.text = controller.text;
                  _tabController.animateTo(2);
                  _onSearch(controller.text);
                  Navigator.pop(context);
                }
              },
              child: Text('search'.tr),
            ),
          ],
        );
      },
    );
  }
}
