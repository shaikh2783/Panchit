import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../../feed/data/models/post.dart';
import '../../../feed/presentation/widgets/post_card.dart';
import '../../../friends/presentation/widgets/add_friend_button.dart';
import '../../../friends/data/models/friendship_model.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../groups/presentation/pages/group_page.dart';
import '../../../groups/data/models/group.dart';
import '../../../pages/presentation/pages/page_profile_page.dart';
import '../../data/services/search_api_service.dart';
import '../../data/models/search_models.dart';
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}
class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  late final SearchApiService _searchService;
  late final TextEditingController _searchController;
  late final TabController _tabController;
  // البحث والنتائج
  String _currentQuery = '';
  SearchType _currentTab = SearchType.posts;
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
    _tabController = TabController(length: SearchType.values.length, vsync: this);
    _scrollController = ScrollController();
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final newTab = SearchType.values[_tabController.index];
    if (newTab != _currentTab) {
      setState(() {
        _currentTab = newTab;
      });
      if (_currentQuery.isNotEmpty && _hasSearched) {
        _search(reset: true);
      }
    }
  }
  void _onScroll() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 200) {
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
          if (_currentTab == SearchType.posts || _currentTab == SearchType.blogs) {
            // تحويل النتائج إلى Post objects للاستخدام مع PostCard
            final newPosts = response.results.map((json) => Post.fromJson(json)).toList();
            _posts.addAll(newPosts);
          } else {
            // استخدام SearchResult models للأنواع الأخرى
            final newResults = SearchResultFactory.fromJsonList(response.results, _currentTab.key);
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
  /// Convert SearchGroup to Group for navigation
  Group _createGroupFromSearchResult(SearchGroup searchGroup) {
    // Create minimal Group object from SearchGroup data
    return Group(
      groupId: searchGroup.groupId,
      groupName: searchGroup.groupName,
      groupTitle: searchGroup.groupTitle,
      groupDescription: searchGroup.groupDescription,
      groupPrivacy: GroupPrivacy.fromString(searchGroup.groupPrivacy),
      groupPicture: searchGroup.groupPicture,
      groupPictureFull: searchGroup.groupPicture,
      groupCover: searchGroup.groupCover,
      groupCoverFull: searchGroup.groupCover,
      groupCoverPosition: null,
      groupMembers: searchGroup.groupMembers,
      groupRate: 0.0,
      groupDate: DateTime.now().toIso8601String(),
      groupPublishEnabled: true,
      groupPublishApprovalEnabled: false,
      groupMonetizationEnabled: false,
      groupMonetizationMinPrice: 0.0,
      chatboxEnabled: false,
      isFake: false,
      admin: GroupAdmin(
        userId: 0,
        username: '',
        firstname: '',
        lastname: '',
        fullname: 'Admin',
        picture: '',
        verified: false,
      ),
      category: GroupCategory(
        categoryId: searchGroup.groupCategory,
        categoryName: 'Category',
      ),
      membership: GroupMembershipStatus(
        isMember: searchGroup.iJoined,
        status: searchGroup.iJoined ? 'approved' : 'not_member',
        isAdmin: false,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Get.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.search_normal,
                color: Colors.blue,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Search',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.grey[900],
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
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
              unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              dividerColor: Colors.transparent,
              tabs: SearchType.values.map((type) => Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(type.title),
                ),
              )).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          // Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }
  Widget _buildSearchBar() {
    final isDarkMode = Get.isDarkMode;
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
            ? Colors.grey.withOpacity(0.2)
            : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.grey[900],
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search for ${_currentTab.title.toLowerCase()}...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Iconsax.search_normal,
            color: Colors.blue,
            size: 20,
          ),
          suffixIcon: _currentQuery.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.close_circle,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        onSubmitted: _onSearchSubmitted,
        textInputAction: TextInputAction.search,
      ),
    );
  }
  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return _buildEmptyState(
        icon: Iconsax.search_normal,
        title: 'Start Searching',
        subtitle: 'Enter search terms to find ${_currentTab.title.toLowerCase()}',
      );
    }
    if (_isSearching && (_posts.isEmpty && _results.isEmpty)) {
      return _buildLoadingState();
    }
    final isEmpty = (_currentTab == SearchType.posts || _currentTab == SearchType.blogs) 
        ? _posts.isEmpty 
        : _results.isEmpty;
    if (isEmpty && !_isSearching) {
      return _buildEmptyState(
        icon: Iconsax.search_status,
        title: 'No Results Found',
        subtitle: 'Try different keywords or check your spelling',
      );
    }
    if (_currentTab == SearchType.posts || _currentTab == SearchType.blogs) {
      return _buildPostsList();
    } else {
      return _buildResultsList();
    }
  }
  Widget _buildPostsList() {
    final isDarkMode = Get.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode 
            ? [
                Colors.black.withOpacity(0.8),
                Colors.black,
              ]
            : [
                Colors.white.withOpacity(0.8),
                const Color(0xFFF5F6FA),
              ],
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.3),
                        Colors.purple.withOpacity(0.3),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CircularProgressIndicator(
                    color: isDarkMode ? Colors.white : Colors.grey[700],
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }
          final post = _posts[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: PostCard(
              post: post,
            ),
          );
        },
      ),
    );
  }
  Widget _buildResultsList() {
    final isDarkMode = Get.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode 
            ? [
                Colors.black.withOpacity(0.8),
                Colors.black,
              ]
            : [
                Colors.white.withOpacity(0.8),
                const Color(0xFFF5F6FA),
              ],
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _results.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _results.length) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.3),
                        Colors.purple.withOpacity(0.3),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CircularProgressIndicator(
                    color: isDarkMode ? Colors.white : Colors.grey[700],
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }
          final result = _results[index];
          return _buildResultCard(result);
        },
      ),
    );
  }
  Widget _buildResultCard(SearchResult result) {
    final isDarkMode = Get.isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode 
            ? [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ]
            : [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? Colors.black.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                _buildResultAvatar(result),
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
                                color: isDarkMode ? Colors.white : Colors.grey[800],
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (result.verified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.blue, Colors.cyan],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
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
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[600],
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionButton(result),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildResultAvatar(SearchResult result) {
    final isDarkMode = Get.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.3),
            Colors.purple.withOpacity(0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
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
                      gradient: LinearGradient(
                        colors: isDarkMode 
                          ? [
                              Colors.grey.withOpacity(0.3),
                              Colors.grey.withOpacity(0.1),
                            ]
                          : [
                              Colors.grey.withOpacity(0.5),
                              Colors.grey.withOpacity(0.3),
                            ],
                      ),
                    ),
                    child: Icon(
                      _getIconForType(result.type),
                      color: isDarkMode 
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isDarkMode 
                      ? [
                          Colors.grey.withOpacity(0.3),
                          Colors.grey.withOpacity(0.1),
                        ]
                      : [
                          Colors.grey.withOpacity(0.5),
                          Colors.grey.withOpacity(0.3),
                        ],
                  ),
                ),
                child: Icon(
                  _getIconForType(result.type),
                  color: isDarkMode 
                    ? Colors.white.withOpacity(0.8)
                    : Colors.grey[600],
                  size: 24,
                ),
              ),
      ),
    );
  }
  IconData _getIconForType(String type) {
    switch (type) {
      case 'user': return Iconsax.user;
      case 'page': return Iconsax.document;
      case 'group': return Iconsax.people;
      case 'event': return Iconsax.calendar;
      default: return Iconsax.search_normal;
    }
  }
  Widget _buildActionButton(SearchResult result) {
    switch (result.type) {
      case 'user':
        final user = result as SearchUser;
        return _buildUserActionButton(user);
      case 'page':
        final page = result as SearchPageResult;
        return _buildPageActionButton(page);
      case 'group':
        final group = result as SearchGroup;
        return _buildGroupActionButton(group);
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
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.8),
            Colors.teal.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
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
              builder: (context) => PageProfilePage.fromId(
                pageId: page.pageId,
              ),
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
  Widget _buildGroupActionButton(SearchGroup group) {
    final isJoined = group.iJoined;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isJoined 
            ? [
                Colors.blue.withOpacity(0.8),
                Colors.cyan.withOpacity(0.8),
              ]
            : [
                Colors.orange.withOpacity(0.8),
                Colors.red.withOpacity(0.8),
              ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isJoined ? Colors.blue : Colors.orange).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {
          // Navigate to group page with full group data
          final groupData = _createGroupFromSearchResult(group);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupPage.withGroup(
                group: groupData,
              ),
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
          isJoined ? 'View' : 'Join',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
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
              builder: (context) => ProfilePage(
                userId: result.userId,
                username: result.username,
              ),
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
              builder: (context) => PageProfilePage.fromId(
                pageId: result.pageId,
              ),
            ),
          );
        }
        break;
      case 'group':
        // Navigate to group detail
        if (result is SearchGroup) {
          final group = _createGroupFromSearchResult(result);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupPage.withGroup(
                group: group,
              ),
            ),
          );
        }
        break;
      case 'event':
        // TODO: Navigate to event detail
        break;
      case 'post':
      case 'blog':
        // TODO: Navigate to post detail
        break;
      default:
    }
  }
  Widget _buildLoadingState() {
    final isDarkMode = Get.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode 
            ? [
                Colors.black.withOpacity(0.8),
                Colors.black,
              ]
            : [
                Colors.white.withOpacity(0.8),
                const Color(0xFFF5F6FA),
              ],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          if (_currentTab == SearchType.posts || _currentTab == SearchType.blogs) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode 
                    ? [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
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
                gradient: LinearGradient(
                  colors: isDarkMode 
                    ? [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDarkMode 
                          ? [
                              Colors.grey.withOpacity(0.3),
                              Colors.grey.withOpacity(0.1),
                            ]
                          : [
                              Colors.grey.withOpacity(0.4),
                              Colors.grey.withOpacity(0.2),
                            ],
                      ),
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
                            gradient: LinearGradient(
                              colors: isDarkMode 
                                ? [
                                    Colors.grey.withOpacity(0.3),
                                    Colors.grey.withOpacity(0.1),
                                  ]
                                : [
                                    Colors.grey.withOpacity(0.4),
                                    Colors.grey.withOpacity(0.2),
                                  ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 150,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDarkMode 
                                ? [
                                    Colors.grey.withOpacity(0.2),
                                    Colors.grey.withOpacity(0.05),
                                  ]
                                : [
                                    Colors.grey.withOpacity(0.3),
                                    Colors.grey.withOpacity(0.15),
                                  ],
                            ),
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
      ),
    );
  }
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDarkMode = Get.isDarkMode;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
              ? [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ]
              : [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode 
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.purple.withOpacity(0.3),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 48,
                color: isDarkMode ? Colors.white : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.grey[800],
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
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey[600],
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
