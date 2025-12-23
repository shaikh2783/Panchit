import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/group.dart';
import '../../data/repositories/groups_repository.dart';
import '../../data/services/groups_api_service.dart';
import '../widgets/group_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/bloc/group_posts_bloc.dart';
import 'group_profile_page.dart';

/// صفحة البحث المتقدم في المجموعات مع الفلاتر
class GroupsSearchPage extends StatefulWidget {
  const GroupsSearchPage({super.key});

  @override
  State<GroupsSearchPage> createState() => _GroupsSearchPageState();
}

class _GroupsSearchPageState extends State<GroupsSearchPage> {
  late GroupsRepository _repository;
  final TextEditingController _searchController = TextEditingController();
  
  // Filters
  int? _selectedCategoryId;
  String? _selectedPrivacy;
  
  // Data
  List<Group> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  
  // Pagination
  int _currentPage = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _repository = GroupsRepository(GroupsApiService(apiClient));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch({bool loadMore = false}) async {
    if (_isLoading || _isLoadingMore) return;
    
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedCategoryId == null && _selectedPrivacy == null) {
      return;
    }

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
        _currentPage++;
      } else {
        _isLoading = true;
        _currentPage = 1;
        _searchResults.clear();
        _hasMore = true;
      }
      _hasSearched = true;
    });

    try {
      final results = await _repository.searchGroups(
        query: query,
        categoryId: _selectedCategoryId,
        privacy: _selectedPrivacy,
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _searchResults.addAll(results);
          } else {
            _searchResults = results;
          }
          _hasMore = results.length >= _limit;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategoryId = null;
      _selectedPrivacy = null;
      _searchResults.clear();
      _hasSearched = false;
      _currentPage = 1;
      _hasMore = true;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterSheet(
        selectedCategoryId: _selectedCategoryId,
        selectedPrivacy: _selectedPrivacy,
        onApply: (categoryId, privacy) {
          setState(() {
            _selectedCategoryId = categoryId;
            _selectedPrivacy = privacy;
          });
          Navigator.pop(context);
          _performSearch();
        },
      ),
    );
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث في المجموعات'),
        actions: [
          // Clear filters button
          if (_selectedCategoryId != null || _selectedPrivacy != null)
            IconButton(
              icon: const Icon(Iconsax.refresh),
              tooltip: 'مسح الفلاتر',
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن مجموعة...',
                      prefixIcon: const Icon(Iconsax.search_normal),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Iconsax.close_circle),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _performSearch(),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                // Filter button
                Badge(
                  isLabelVisible: _selectedCategoryId != null || _selectedPrivacy != null,
                  child: IconButton.filledTonal(
                    icon: const Icon(Iconsax.filter),
                    onPressed: _showFilterSheet,
                    tooltip: 'الفلاتر',
                  ),
                ),
                const SizedBox(width: 8),
                // Search button
                IconButton.filled(
                  icon: const Icon(Iconsax.search_normal_1),
                  onPressed: _performSearch,
                ),
              ],
            ),
          ),

          // Active Filters Chips
          if (_selectedCategoryId != null || _selectedPrivacy != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedCategoryId != null)
                    Chip(
                      label: Text('الفئة: $_selectedCategoryId'),
                      deleteIcon: const Icon(Iconsax.close_circle, size: 18),
                      onDeleted: () {
                        setState(() => _selectedCategoryId = null);
                        _performSearch();
                      },
                    ),
                  if (_selectedPrivacy != null)
                    Chip(
                      label: Text(_getPrivacyLabel(_selectedPrivacy!)),
                      deleteIcon: const Icon(Iconsax.close_circle, size: 18),
                      onDeleted: () {
                        setState(() => _selectedPrivacy = null);
                        _performSearch();
                      },
                    ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _buildBody(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.search_normal, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'ابحث عن مجموعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'استخدم البحث أو الفلاتر للعثور على مجموعات',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.search_status, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب كلمات بحث مختلفة أو قم بتغيير الفلاتر',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isLoadingMore &&
            _hasMore &&
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          _performSearch(loadMore: true);
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _searchResults.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _searchResults.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final group = _searchResults[index];
          return GroupCard(
            group: group,
            onTap: () => _onGroupTap(group),
          );
        },
      ),
    );
  }

  String _getPrivacyLabel(String privacy) {
    switch (privacy) {
      case 'public':
        return 'عامة';
      case 'closed':
        return 'مغلقة';
      case 'secret':
        return 'سرية';
      default:
        return privacy;
    }
  }
}

/// Filter Sheet Widget
class _FilterSheet extends StatefulWidget {
  final int? selectedCategoryId;
  final String? selectedPrivacy;
  final Function(int?, String?) onApply;

  const _FilterSheet({
    this.selectedCategoryId,
    this.selectedPrivacy,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int? _categoryId;
  String? _privacy;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.selectedCategoryId;
    _privacy = widget.selectedPrivacy;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Row(
            children: [
              const Icon(Iconsax.filter),
              const SizedBox(width: 8),
              const Text(
                'الفلاتر',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _categoryId = null;
                    _privacy = null;
                  });
                },
                child: const Text('مسح الكل'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Filter
          const Text('الفئة', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'رقم الفئة (مثال: 1)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(
              text: _categoryId?.toString() ?? '',
            ),
            onChanged: (value) {
              _categoryId = int.tryParse(value);
            },
          ),
          const SizedBox(height: 16),

          // Privacy Filter
          const Text('الخصوصية', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('عامة'),
                selected: _privacy == 'public',
                onSelected: (selected) {
                  setState(() => _privacy = selected ? 'public' : null);
                },
              ),
              ChoiceChip(
                label: const Text('مغلقة'),
                selected: _privacy == 'closed',
                onSelected: (selected) {
                  setState(() => _privacy = selected ? 'closed' : null);
                },
              ),
              ChoiceChip(
                label: const Text('سرية'),
                selected: _privacy == 'secret',
                onSelected: (selected) {
                  setState(() => _privacy = selected ? 'secret' : null);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Apply Button
          FilledButton.icon(
            onPressed: () => widget.onApply(_categoryId, _privacy),
            icon: const Icon(Iconsax.tick_circle),
            label: const Text('تطبيق الفلاتر'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
