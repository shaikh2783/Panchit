import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/core/theme/panchit_auth_ui.dart';
import 'package:snginepro/features/competitions/data/models/competition_models.dart';
import 'package:snginepro/features/competitions/data/services/competition_api_service.dart';
import 'package:snginepro/features/competitions/presentation/pages/competition_detail_page.dart';
import 'package:snginepro/features/competitions/presentation/pages/my_competitions_page.dart';
import 'package:snginepro/features/competitions/presentation/widgets/competition_widgets.dart';

enum _SortField { date, price }

class CompetitionsHubPage extends StatefulWidget {
  const CompetitionsHubPage({super.key});

  @override
  State<CompetitionsHubPage> createState() => _CompetitionsHubPageState();
}

class _CompetitionsHubPageState extends State<CompetitionsHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  CompetitionListState _liveState = CompetitionListState.initial;
  CompetitionListState _upcomingState = CompetitionListState.initial;
  CompetitionListState _pastState = CompetitionListState.initial;
  List<CompetitionModel> _liveCompetitions = const <CompetitionModel>[];
  List<CompetitionModel> _upcomingCompetitions = const <CompetitionModel>[];
  List<CompetitionModel> _pastCompetitions = const <CompetitionModel>[];
  String? _liveError;
  String? _upcomingError;
  String? _pastError;
  Set<int> _notifyingCompetitionIds = <int>{};
  _SortField? _sortField;
  bool _sortAscending = true;
  String? _selectedCategory;
  List<String> _categories = const [];
  bool _categoriesLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadLiveCompetitions(),
      _loadUpcomingCompetitions(),
      _loadPastCompetitions(),
    ]);
  }

  Future<void> _loadLiveCompetitions() async {
    setState(() {
      _liveState = CompetitionListState.loading;
      _liveError = null;
    });
    try {
      final items = await context
          .read<CompetitionApiService>()
          .getLiveCompetitions();
      if (!mounted) return;
      setState(() {
        _liveCompetitions = items;
        _liveState = items.isEmpty
            ? CompetitionListState.empty
            : CompetitionListState.success;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _liveError = error.toString();
        _liveState = CompetitionListState.error;
      });
    }
  }

  Future<void> _loadUpcomingCompetitions() async {
    setState(() {
      _upcomingState = CompetitionListState.loading;
      _upcomingError = null;
    });
    try {
      final items = await context
          .read<CompetitionApiService>()
          .getUpcomingCompetitions();
      if (!mounted) return;
      setState(() {
        _upcomingCompetitions = items;
        _upcomingState = items.isEmpty
            ? CompetitionListState.empty
            : CompetitionListState.success;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _upcomingError = error.toString();
        _upcomingState = CompetitionListState.error;
      });
    }
  }

  Future<void> _loadPastCompetitions() async {
    setState(() {
      _pastState = CompetitionListState.loading;
      _pastError = null;
    });
    try {
      final items = await context
          .read<CompetitionApiService>()
          .getPastWinners();
      if (!mounted) return;
      setState(() {
        _pastCompetitions = items;
        _pastState = items.isEmpty
            ? CompetitionListState.empty
            : CompetitionListState.success;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pastError = error.toString();
        _pastState = CompetitionListState.error;
      });
    }
  }

  Future<void> _loadCategories() async {
    if (_categoriesLoading) return;
    setState(() => _categoriesLoading = true);
    try {
      final items = await context
          .read<CompetitionApiService>()
          .getCompetitionCategories();
      if (!mounted) return;
      setState(() => _categories = items);
    } catch (_) {
      // silently fall back
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _handleNotifyMe(CompetitionModel competition) async {
    setState(() {
      _notifyingCompetitionIds = {..._notifyingCompetitionIds, competition.id};
    });
    try {
      await context.read<CompetitionApiService>().notifyCompetition(
        competition.id,
      );
      if (!mounted) return;
      setState(() {
        _upcomingCompetitions = _upcomingCompetitions
            .map((item) {
              return item.id == competition.id
                  ? item.copyWith(isNotifyEnabled: true)
                  : item;
            })
            .toList(growable: false);
      });
      _showMessage('competition_reminder_enabled'.tr);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _notifyingCompetitionIds = {..._notifyingCompetitionIds}
            ..remove(competition.id);
        });
      }
    }
  }

  void _openCompetitionDetails(CompetitionModel competition) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompetitionDetailPage(
          competitionId: competition.id,
          initialCompetition: competition,
        ),
      ),
    );
  }

  void _openMyCompetitions() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MyCompetitionsPage()));
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [_buildSliverHeader(theme)],
        body: Column(
          children: [
            _buildFilterBar(theme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    onRefresh: _loadLiveCompetitions,
                    child: _buildTab(
                      state: _liveState,
                      competitions: _sorted(_filtered(_liveCompetitions)),
                      emptyTitle: 'hub_no_live_competitions'.tr,
                      emptyMessage: 'hub_no_live_msg'.tr,
                      errorTitle: 'hub_live_load_failed'.tr,
                      errorMessage: _liveError,
                      onRetry: _loadLiveCompetitions,
                      emptyIcon: Iconsax.flash_1,
                      emptyAccentColor: const Color(0xFF14B8A6),
                      filteredEmptyTitle: _selectedCategory != null
                          ? 'hub_no_filtered_competitions'.trParams({
                              'category': _selectedCategory!,
                            })
                          : null,
                      filteredEmptyMessage: _selectedCategory != null
                          ? 'hub_no_filtered_msg'.tr
                          : null,
                      onClearFilter: _selectedCategory != null
                          ? () => setState(() => _selectedCategory = null)
                          : null,
                      cardBuilder: (c) => _CompetitionHubCard(
                        competition: c,
                        primaryLabel: c.isJoined
                            ? 'competition_action_view_my_entry'.tr
                            : 'hub_join_now'.tr,
                        onTap: () => _openCompetitionDetails(c),
                        onPrimaryTap: () => _openCompetitionDetails(c),
                        showCountdown: true,
                      ),
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: _loadUpcomingCompetitions,
                    child: _buildTab(
                      state: _upcomingState,
                      competitions: _sorted(_filtered(_upcomingCompetitions)),
                      emptyTitle: 'hub_no_upcoming_competitions'.tr,
                      emptyMessage: 'hub_no_upcoming_msg'.tr,
                      errorTitle: 'hub_upcoming_load_failed'.tr,
                      errorMessage: _upcomingError,
                      onRetry: _loadUpcomingCompetitions,
                      emptyIcon: Iconsax.calendar_1,
                      emptyAccentColor: const Color(0xFF6366F1),
                      filteredEmptyTitle: _selectedCategory != null
                          ? 'hub_no_filtered_competitions'.trParams({
                              'category': _selectedCategory!,
                            })
                          : null,
                      filteredEmptyMessage: _selectedCategory != null
                          ? 'hub_no_filtered_msg'.tr
                          : null,
                      onClearFilter: _selectedCategory != null
                          ? () => setState(() => _selectedCategory = null)
                          : null,
                      cardBuilder: (c) => _CompetitionHubCard(
                        competition: c,
                        primaryLabel: _notifyingCompetitionIds.contains(c.id)
                            ? 'hub_please_wait'.tr
                            : c.isNotifyEnabled
                            ? 'hub_reminder_set'.tr
                            : 'competition_notify_me'.tr,
                        onTap: () => _openCompetitionDetails(c),
                        onPrimaryTap: () {
                          if (_notifyingCompetitionIds.contains(c.id) ||
                              c.isNotifyEnabled) {
                            return;
                          }
                          _handleNotifyMe(c);
                        },
                        showRegistrationStart: true,
                      ),
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: _loadPastCompetitions,
                    child: _buildTab(
                      state: _pastState,
                      competitions: _sorted(_filtered(_pastCompetitions)),
                      emptyTitle: 'hub_no_past_winners'.tr,
                      emptyMessage: 'hub_no_past_msg'.tr,
                      errorTitle: 'hub_past_load_failed'.tr,
                      errorMessage: _pastError,
                      onRetry: _loadPastCompetitions,
                      emptyIcon: Iconsax.crown_1,
                      emptyAccentColor: const Color(0xFFF59E0B),
                      filteredEmptyTitle: _selectedCategory != null
                          ? 'hub_no_filtered_competitions'.trParams({
                              'category': _selectedCategory!,
                            })
                          : null,
                      filteredEmptyMessage: _selectedCategory != null
                          ? 'hub_no_filtered_msg'.tr
                          : null,
                      onClearFilter: _selectedCategory != null
                          ? () => setState(() => _selectedCategory = null)
                          : null,
                      cardBuilder: (c) => _CompetitionHubCard(
                        competition: c,
                        primaryLabel: 'competition_action_view_winners'.tr,
                        onTap: () => _openCompetitionDetails(c),
                        onPrimaryTap: () => _openCompetitionDetails(c),
                        winnerPreview: c.winners.isNotEmpty ? c.winners : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header sliver ─────────────────────────────────────────────────────────

  Widget _buildSliverHeader(ThemeData theme) {
    final liveCount = _liveCompetitions.length;
    final upcomingCount = _upcomingCompetitions.length;
    final isDark = theme.brightness == Brightness.dark;
    const LinearGradient horizontalBrandGradient = LinearGradient(
      colors: [Color(0xFF6C00FF), Color(0xFFFF2E88)],
    );
    return SliverAppBar(
      expandedHeight: 145,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: PanchitAuthColors.background(isDark),
      foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
      actions: [
        IconButton(
          tooltip: 'hub_my_competitions_tooltip'.tr,
          onPressed: _openMyCompetitions,
          icon: const Icon(Icons.person_outline),
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            DecoratedBox(
              decoration: BoxDecoration(
                color: PanchitAuthColors.background(isDark),
              ),
            ),
            // Decorative blurred circle
            Positioned(
              right: -45,
              top: -35,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.pinkAccent.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: 10,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Title + stats content
            Positioned(
              left: Spacing.lg,
              right: Spacing.lg,
              bottom: Spacing.lg + 48, // leave room for TabBar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.cup,
                        size: 22,
                        color: isDark
                            ? Colors.white
                            : AppColors.textPrimaryLight,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'hub_competitions_title'.tr,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      _HeaderStatBadge(
                        label: '$liveCount ${'hub_live'.tr}',
                        icon: Iconsax.flash_1,
                        isDark: isDark,
                      ),
                      const SizedBox(width: Spacing.sm),
                      _HeaderStatBadge(
                        label: '$upcomingCount ${'hub_tab_upcoming'.tr}',
                        icon: Iconsax.calendar_1,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        // Collapsed title
        title: Row(
          children: [
            Icon(
              Iconsax.cup,
              size: 18,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              'hub_competitions_title'.tr,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsetsDirectional.fromSTEB(
          Spacing.lg,
          0,
          0,
          Spacing.sm,
        ),
        collapseMode: CollapseMode.pin,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            0,
            Spacing.lg,
            Spacing.sm,
          ),
          child: _buildHubTabBar(isDark, theme),
        ),
      ),
    );
  }

  Widget _buildHubTabBar(bool isDark, ThemeData theme) {
    final tabs = [
      (icon: Iconsax.flash_1, label: 'hub_tab_live_now'.tr),
      (icon: Iconsax.calendar_1, label: 'hub_tab_upcoming'.tr),
      (icon: Iconsax.crown_1, label: 'hub_tab_past_winners'.tr),
    ];
    final unselectedColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.6);

    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.35),
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: List.generate(tabs.length, (index) {
                  final tab = tabs[index];
                  final isSelected = _tabController.index == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? AppColors.primaryGradient
                              : null,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab.icon,
                              size: 15,
                              color: isSelected
                                  ? Colors.white
                                  : unselectedColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                tab.label,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : unselectedColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────

  Widget _buildFilterBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 12, Spacing.lg, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 18,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(theme),
                  const SizedBox(width: 8),
                  _sortChip(_SortField.date, 'hub_sort_date'.tr, theme),
                  const SizedBox(width: 8),
                  _sortChip(_SortField.price, 'hub_sort_price'.tr, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(_SortField field, String label, ThemeData theme) {
    final isSelected = _sortField == field;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      avatar: isSelected
          ? Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 13,
            )
          : null,
      onSelected: (_) => _onSortTap(field),
    );
  }

  Widget _buildCategoryChip(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final hasCategory = _selectedCategory != null;
    return FilterChip(
      label: Text(hasCategory ? _selectedCategory! : 'competition_category'.tr),
      selected: hasCategory,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      avatar: _categoriesLoading
          ? const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          : Icon(
              hasCategory ? Icons.label : Icons.filter_list_outlined,
              size: 13,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
      onSelected: _categoriesLoading ? null : (_) => _showCategoryPicker(),
      onDeleted: hasCategory
          ? () => setState(() => _selectedCategory = null)
          : null,
    );
  }

  // ── Tab content ───────────────────────────────────────────────────────────

  Widget _buildTab({
    required CompetitionListState state,
    required List<CompetitionModel> competitions,
    required String emptyTitle,
    required String emptyMessage,
    required String errorTitle,
    required String? errorMessage,
    required Future<void> Function() onRetry,
    required Widget Function(CompetitionModel) cardBuilder,
    IconData emptyIcon = Iconsax.cup,
    Color? emptyAccentColor,
    String? filteredEmptyTitle,
    String? filteredEmptyMessage,
    VoidCallback? onClearFilter,
  }) {
    switch (state) {
      case CompetitionListState.initial:
      case CompetitionListState.loading:
        return const Center(child: CircularProgressIndicator());
      case CompetitionListState.empty:
        return _CompetitionsEmptyState(
          title: emptyTitle,
          message: emptyMessage,
          icon: emptyIcon,
          accentColor: emptyAccentColor,
        );
      case CompetitionListState.error:
        return CompetitionSectionPlaceholder(
          title: errorTitle,
          message: errorMessage ?? 'something_went_wrong'.tr,
          showRetry: true,
          onRetry: onRetry,
        );
      case CompetitionListState.success:
        if (competitions.isEmpty) {
          return _CompetitionsEmptyState(
            title: filteredEmptyTitle ?? emptyTitle,
            message: filteredEmptyMessage ?? emptyMessage,
            icon: emptyIcon,
            accentColor: emptyAccentColor,
            actionLabel: onClearFilter != null ? 'hub_clear_filter'.tr : null,
            onAction: onClearFilter,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.lg,
            Spacing.lg,
            Spacing.xxxl,
          ),
          itemCount: competitions.length,
          separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
          itemBuilder: (_, index) => cardBuilder(competitions[index]),
        );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<CompetitionModel> _filtered(List<CompetitionModel> items) {
    final cat = _selectedCategory;
    if (cat == null) return items;
    return items.where((c) => c.category == cat).toList(growable: false);
  }

  List<CompetitionModel> _sorted(List<CompetitionModel> items) {
    final field = _sortField;
    if (field == null) return items;
    final sorted = [...items];
    sorted.sort((a, b) {
      int cmp;
      switch (field) {
        case _SortField.date:
          cmp = (a.registrationStart ?? DateTime(0)).compareTo(
            b.registrationStart ?? DateTime(0),
          );
        case _SortField.price:
          cmp = (a.entryFee ?? 0).compareTo(b.entryFee ?? 0);
      }
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  Future<void> _showCategoryPicker() async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xLarge)),
      ),
      builder: (ctx) => _CategoryPickerSheet(
        categories: _categories,
        selectedCategory: _selectedCategory,
        isLoading: _categoriesLoading,
      ),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedCategory = picked == '__all__' ? null : picked;
    });
  }

  void _onSortTap(_SortField field) {
    setState(() {
      if (_sortField == field) {
        if (_sortAscending) {
          _sortAscending = false;
        } else {
          _sortField = null;
          _sortAscending = true;
        }
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }
}

// ── Hub card ──────────────────────────────────────────────────────────────────

class _CompetitionHubCard extends StatelessWidget {
  const _CompetitionHubCard({
    required this.competition,
    required this.primaryLabel,
    required this.onTap,
    required this.onPrimaryTap,
    this.showCountdown = false,
    this.showRegistrationStart = false,
    this.winnerPreview,
  });

  final CompetitionModel competition;
  final String primaryLabel;
  final VoidCallback onTap;
  final VoidCallback onPrimaryTap;
  final bool showCountdown;
  final bool showRegistrationStart;
  final List<CompetitionWinnerModel>? winnerPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasBanner = (competition.bannerUrl ?? '').isNotEmpty;
    final borderColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final cardColor = isDark ? AppColors.cardDark : Colors.white;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner section ─────────────────────────────────────────────
            AspectRatio(
              aspectRatio: 16 / 6.5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner image or fallback
                  if (hasBanner)
                    Image.network(
                      competition.bannerUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallback(context),
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : _buildFallback(context),
                    )
                  else
                    _buildFallback(context),

                  // Darken the photo slightly so the top badges stay legible
                  if (hasBanner)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: [0.0, 0.7],
                          colors: [Color(0x99000000), Colors.transparent],
                        ),
                      ),
                    ),

                  // Bottom gradient for text legibility
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: [0.0, 0.65],
                        colors: [Color(0xCC000000), Colors.transparent],
                      ),
                    ),
                  ),

                  // Top-left: status badge
                  Positioned(
                    top: Spacing.sm,
                    left: Spacing.sm,
                    child: CompetitionStatusBadge(status: competition.status),
                  ),

                  // Top-right: Joined chip
                  if (competition.isJoined)
                    Positioned(
                      top: Spacing.sm,
                      right: Spacing.sm,
                      child: _GlassChip(
                        label: 'joined'.tr,
                        icon: Icons.check_circle_outline,
                        isDark: isDark || hasBanner,
                      ),
                    ),

                  // Bottom: title + category
                  Positioned(
                    left: Spacing.md,
                    right: Spacing.md,
                    bottom: Spacing.sm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((competition.category ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor),
                              boxShadow: isDark
                                  ? AppColors.darkShadow
                                  : AppColors.lightShadow,
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              competition.category!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),

                        Text(
                          competition.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content section ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Iconsax.ticket_discount,
                        label: formatMoney(
                          competition.entryFee,
                          competition.currencySymbol,
                        ),
                        tooltip: 'competition_entry_fee'.tr,
                      ),
                      const SizedBox(width: Spacing.sm),
                      _StatChip(
                        icon: Iconsax.cup,
                        label: formatMoney(
                          competition.prizePool,
                          competition.currencySymbol,
                        ),
                        tooltip: 'competition_prize_pool'.tr,
                      ),
                      if (competition.totalParticipants != null) ...[
                        const SizedBox(width: Spacing.sm),
                        _StatChip(
                          icon: Iconsax.people,
                          label: '${competition.totalParticipants}',
                          tooltip: 'competition_participants'.tr,
                        ),
                      ],
                      const Spacer(),
                      _StatChip(
                        icon: Iconsax.gallery,
                        label: competition.allowedMediaType.label,
                        tooltip: 'hub_allowed_media_tooltip'.tr,
                      ),
                    ],
                  ),

                  // Countdown / registration start
                  if (showCountdown && competition.registrationEnd != null) ...[
                    const SizedBox(height: Spacing.sm),
                    CompetitionCountdownTimer(
                      targetTime: competition.registrationEnd,
                      prefix: 'competition_closes_in'.tr,
                      emptyLabel: 'competition_closing_soon'.tr,
                    ),
                  ] else if (showRegistrationStart &&
                      competition.registrationStart != null) ...[
                    const SizedBox(height: Spacing.sm),
                    CompetitionCountdownTimer(
                      targetTime: competition.registrationStart,
                      prefix: 'competition_opens_in'.tr,
                      emptyLabel: 'competition_opening_soon'.tr,
                    ),
                  ],

                  // Winner preview for past tab
                  if (winnerPreview != null && winnerPreview!.isNotEmpty) ...[
                    const SizedBox(height: Spacing.sm),
                    const Divider(height: 1),
                    const SizedBox(height: Spacing.sm),
                    ...winnerPreview!
                        .take(2)
                        .map((w) => CompetitionWinnerTile(winner: w)),
                  ],

                  const SizedBox(height: Spacing.sm),

                  // CTA button
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.verticalBrandGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: onPrimaryTap,
                        child: Center(
                          child: Text(
                            primaryLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF171225), const Color(0xFF241033)]
              : [const Color(0xFFF7F3FF), const Color(0xFFFFF2F7)],
        ),
      ),
      child: Center(
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(Iconsax.cup, size: 28, color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _CompetitionsEmptyState extends StatelessWidget {
  const _CompetitionsEmptyState({
    required this.title,
    required this.message,
    required this.icon,
    this.accentColor,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color? accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xxxl,
          vertical: Spacing.xl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Layered circles with icon
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: isDark ? 0.08 : 0.06),
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: isDark ? 0.13 : 0.10),
                  ),
                ),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.75)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xl),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.sm),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),

            // Decorative divider dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  width: i == 1 ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == 1
                        ? color.withValues(alpha: 0.7)
                        : color.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                );
              }),
            ),

            // Clear-filter action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Spacing.lg),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: Text(actionLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label, this.icon, this.isDark = true});

  final String label;
  final IconData? icon;

  /// Whether this chip sits over a dark surface (a photo or the dark
  /// fallback gradient) and should use light glass + white content, or a
  /// light surface (the light fallback gradient) and needs dark content.
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final contentColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.28)
                  : AppColors.dividerLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 11, color: contentColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: contentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.tooltip,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = highlight
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.65);

    final bg = highlight
        ? theme.colorScheme.primary.withValues(alpha: 0.09)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.medium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStatBadge extends StatelessWidget {
  const _HeaderStatBadge({
    required this.label,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final contentColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.25)
                  : AppColors.dividerLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: contentColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: contentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category picker sheet ─────────────────────────────────────────────────────

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedCategory,
    required this.isLoading,
  });

  final List<String> categories;
  final String? selectedCategory;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.lg,
              Spacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'hub_filter_by_category'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (isLoading && categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(Spacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.apps_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text('hub_all_categories'.tr),
                    selected: selectedCategory == null,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primary.withValues(
                      alpha: 0.08,
                    ),
                    trailing: selectedCategory == null
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop('__all__'),
                  ),
                  ...categories.map(
                    (cat) => ListTile(
                      leading: Icon(
                        Icons.label_outline,
                        color: theme.colorScheme.secondary,
                      ),
                      title: Text(cat),
                      selected: selectedCategory == cat,
                      selectedColor: theme.colorScheme.primary,
                      selectedTileColor: theme.colorScheme.primary.withValues(
                        alpha: 0.08,
                      ),
                      trailing: selectedCategory == cat
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(cat),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
