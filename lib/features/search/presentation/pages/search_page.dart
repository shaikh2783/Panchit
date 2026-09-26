import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../feed/data/models/post.dart';
import '../../../feed/presentation/widgets/post_card.dart';
import '../../../friends/presentation/widgets/add_friend_button.dart';
import '../../../friends/data/models/friendship_model.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../pages/presentation/pages/page_profile_page.dart';
import '../../../groups/presentation/pages/group_profile_page.dart';
import '../../../groups/application/bloc/group_posts_bloc.dart';
import '../../../groups/data/repositories/groups_repository.dart';
import '../../../groups/data/services/groups_api_service.dart';
import '../../../events/presentation/pages/event_detail_page.dart';
import '../../data/services/search_api_service.dart';
import '../../data/models/search_models.dart';
import '../../../discover/presentation/pages/discover_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final SearchApiService _searchService;
  late final TextEditingController _searchController;

  // البحث والنتائج
  String _currentQuery = '';
  SearchType _currentTab = SearchType.users;
  bool _isSearching = false;
  bool _hasSearched = false;

  // النتائج
  List<Post> _posts = [];
  List<SearchResult> _results = [];

  // Pagination
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchService = SearchApiService(context.read<ApiClient>());
    _searchController = TextEditingController();
    _scrollController = ScrollController();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectTab(SearchType type) {
    if (type == _currentTab) return;

    setState(() {
      _currentTab = type;
    });

    if (_currentQuery.isNotEmpty && _hasSearched) {
      _search(reset: true);
    }
  }

  void _onScroll() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoadingMore && !_isSearching) {
        _loadMore();
      }
    }
  }

  Future<void> _search({bool reset = true}) async {
    if (_currentQuery.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      if (reset) {
        _currentPage = 1;
        _hasMore = false;
        _posts.clear();
        _results.clear();
      }
    });

    try {
      final response = await _searchService.search(
        query: _currentQuery,
        tab: _currentTab.key,
        page: _currentPage,
        limit: 20,
      );

      if (!mounted) return;

      setState(() {
        _hasSearched = true;
        _hasMore = response.pagination.hasMore;

        if (reset) {
          _posts.clear();
          _results.clear();
        }

        if (response.success && response.results.isNotEmpty) {
          if (_currentTab == SearchType.posts ||
              _currentTab == SearchType.blogs) {
            // تحويل النتائج إلى Post objects للاستخدام مع PostCard
            final newPosts = response.results
                .map((json) => Post.fromJson(json))
                .toList();
            _posts.addAll(newPosts);
          } else {
            // استخدام SearchResult models للأنواع الأخرى
            final newResults = SearchResultFactory.fromJsonList(
              response.results,
              _currentTab.key,
            );
            _results.addAll(newResults);
          }
        }
      });
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _search(reset: false);

    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchSubmitted(String value) {
    final query = value.trim();
    if (query.isNotEmpty && query != _currentQuery) {
      setState(() {
        _currentQuery = query;
      });
      _search();
    }
  }

  void _clearSearch() {
    setState(() {
      _currentQuery = '';
      _hasSearched = false;
      _posts.clear();
      _results.clear();
    });
    _searchController.clear();
  }

  // Groups module removed; group navigation disabled

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.search_normal,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Search',
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Discover',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.discover_1,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DiscoverPage())),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Type filter bar
          _buildTypeTabBar(isDarkMode),

          // Search Bar
          _buildSearchBar(isDarkMode),

          // Results
          Expanded(child: _buildSearchResults(isDarkMode)),
        ],
      ),
    );
  }

  IconData _iconForSearchType(SearchType type) {
    switch (type) {
      case SearchType.users:
        return Iconsax.user;
      case SearchType.posts:
        return Iconsax.document_text;
      case SearchType.pages:
        return Iconsax.document;
      case SearchType.groups:
        return Iconsax.people;
      case SearchType.events:
        return Iconsax.calendar;
      case SearchType.blogs:
        return Iconsax.document_text_1;
    }
  }

  Widget _buildTypeTabBar(bool isDarkMode) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = isDarkMode
        ? AppColors.dividerDark
        : AppColors.dividerLight;

    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: SearchType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final type = SearchType.values[index];
          final isSelected = _currentTab == type;

          return GestureDetector(
            onTap: () => _selectTab(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                gradient: isSelected ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.circular(28),
                boxShadow: isDarkMode
                    ? AppColors.darkShadow
                    : AppColors.lightShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconForSearchType(type),
                    size: 15,
                    color: isSelected
                        ? Colors.white
                        : (isDarkMode
                              ? Colors.white.withValues(alpha: 0.55)
                              : cs.onSurface.withValues(alpha: 0.55)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    type.title,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDarkMode
                                ? Colors.white.withValues(alpha: 0.7)
                                : cs.onSurface.withValues(alpha: 0.75)),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: isSelected ? 0.1 : 0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.dividerDark : AppColors.dividerLight,
          width: 1,
        ),
        boxShadow: isDarkMode ? AppColors.darkShadow : AppColors.lightShadow,
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDarkMode
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search for ${_currentTab.title.toLowerCase()}...',
          hintStyle: TextStyle(
            color: isDarkMode
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Iconsax.search_normal,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: _currentQuery.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.hoverDark
                          : AppColors.hoverLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.close_circle,
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      size: 16,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
        onSubmitted: _onSearchSubmitted,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildSearchResults(bool isDarkMode) {
    if (!_hasSearched) {
      return _buildEmptyState(
        isDarkMode: isDarkMode,
        icon: Iconsax.search_normal,
        title: 'Start Searching',
        subtitle:
            'Enter search terms to find ${_currentTab.title.toLowerCase()}',
      );
    }

    if (_isSearching && (_posts.isEmpty && _results.isEmpty)) {
      return _buildLoadingState(isDarkMode);
    }

    final isEmpty =
        (_currentTab == SearchType.posts || _currentTab == SearchType.blogs)
        ? _posts.isEmpty
        : _results.isEmpty;

    if (isEmpty && !_isSearching) {
      return _buildEmptyState(
        isDarkMode: isDarkMode,
        icon: Iconsax.search_status,
        title: 'No Results Found',
        subtitle: 'Try different keywords or check your spelling',
      );
    }

    if (_currentTab == SearchType.posts || _currentTab == SearchType.blogs) {
      return _buildPostsList(isDarkMode);
    } else {
      return _buildResultsList(isDarkMode);
    }
  }

  Widget _buildPostsList(bool isDarkMode) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // No ads - original behavior
        if (index == _posts.length) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final post = _posts[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDarkMode
                ? AppColors.darkShadow
                : AppColors.lightShadow,
          ),
          child: PostCard(post: post),
        );
      },
    );
  }

  Widget _buildResultsList(bool isDarkMode) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _results.length) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final result = _results[index];
        return _buildResultCard(result, isDarkMode);
      },
    );
  }

  Widget _buildResultCard(SearchResult result, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.dividerDark : AppColors.dividerLight,
          width: 1,
        ),
        boxShadow: isDarkMode ? AppColors.darkShadow : AppColors.lightShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onResultTap(result),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildResultAvatar(result, isDarkMode),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              result.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (result.verified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.info,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.info.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionButton(result, isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultAvatar(SearchResult result, bool isDarkMode) {
    final placeholderColor = isDarkMode
        ? AppColors.hoverDark
        : AppColors.hoverLight;
    final placeholderIconColor = isDarkMode
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.secondary.withValues(alpha: 0.25),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.transparent,
        child: result.imageUrl != null && result.imageUrl!.isNotEmpty
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: result.imageUrl!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: placeholderColor,
                    ),
                    child: Icon(
                      _getIconForType(result.type),
                      color: placeholderIconColor,
                      size: 24,
                    ),
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: placeholderColor,
                ),
                child: Icon(
                  _getIconForType(result.type),
                  color: placeholderIconColor,
                  size: 24,
                ),
              ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'user':
        return Iconsax.user;
      case 'page':
        return Iconsax.document;
      case 'group':
        return Iconsax.people;
      case 'event':
        return Iconsax.calendar;
      default:
        return Iconsax.search_normal;
    }
  }

  Widget _buildActionButton(SearchResult result, bool isDarkMode) {
    switch (result.type) {
      case 'user':
        final user = result as SearchUser;
        return _buildUserActionButton(user);
      case 'page':
        final page = result as SearchPageResult;
        return _buildPageActionButton(page);
      case 'group':
        final group = result as SearchGroup;
        return _buildGroupActionButton(group, isDarkMode);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUserActionButton(SearchUser user) {
    // Map connection status to FriendshipStatus
    FriendshipStatus status;
    switch (user.connectionStatus) {
      case 'friends':
        status = FriendshipStatus.friends;
        break;
      case 'pending':
        status = FriendshipStatus.pending;
        break;
      case 'requested':
        status = FriendshipStatus.requested;
        break;
      default:
        status = FriendshipStatus.none;
    }

    return AddFriendButton(
      userId: user.userId,
      initialStatus: status,
      size: AddFriendButtonSize.small,
      style: AddFriendButtonStyle.outlined,
      showText: false, // إظهار الأيقونة فقط في نتائج البحث
    );
  }

  Widget _buildPageActionButton(SearchPageResult page) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {
          // Navigate to page profile using pageId only
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PageProfilePage.fromId(pageId: page.pageId),
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'View',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupActionButton(SearchGroup _group, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.dividerDark : AppColors.dividerLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Groups are no longer available.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Unavailable',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  void _onResultTap(SearchResult result) {
    switch (result.type) {
      case 'user':
        // Navigate to user profile
        if (result is SearchUser) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProfilePage(userId: result.userId, username: result.username),
            ),
          );
        }
        break;
      case 'page':
        // Navigate to page detail using pageId only
        if (result is SearchPageResult) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PageProfilePage.fromId(pageId: result.pageId),
            ),
          );
        }
        break;
      case 'group':
        // Navigate to group detail
        if (result is SearchGroup) {
          final groupsApiService = GroupsApiService(context.read<ApiClient>());
          final groupsRepository = GroupsRepository(groupsApiService);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => GroupPostsBloc(groupsRepository),
                child: GroupProfilePage(groupId: result.groupId),
              ),
            ),
          );
        }
        break;
      case 'event':
        // Navigate to event detail
        if (result is SearchEvent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailPage(eventId: result.eventId),
            ),
          );
        }
        break;
      case 'post':
      case 'blog':
        // TODO: Navigate to post detail
        break;
      default:
    }
  }

  Widget _buildLoadingState(bool isDarkMode) {
    final skeletonColor = isDarkMode
        ? AppColors.hoverDark
        : AppColors.hoverLight;
    final cardColor = isDarkMode ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDarkMode
        ? AppColors.dividerDark
        : AppColors.dividerLight;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) {
        if (_currentTab == SearchType.posts ||
            _currentTab == SearchType.blogs) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        } else {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: skeletonColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 150,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildEmptyState({
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
          boxShadow: isDarkMode ? AppColors.darkShadow : AppColors.lightShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.secondary.withValues(alpha: 0.3),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 48,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
