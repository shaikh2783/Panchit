import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
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
      final items = await context.read<CompetitionApiService>().getLiveCompetitions();
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
      final items = await context.read<CompetitionApiService>().getPastWinners();
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
      await context.read<CompetitionApiService>().notifyCompetition(competition.id);
      if (!mounted) return;
      setState(() {
        _upcomingCompetitions = _upcomingCompetitions.map((item) {
          return item.id == competition.id
              ? item.copyWith(isNotifyEnabled: true)
              : item;
        }).toList(growable: false);
      });
      _showMessage('Competition reminder enabled.');
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyCompetitionsPage()),
    );
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
        headerSliverBuilder: (context, _) => [
          _buildSliverHeader(theme),
        ],
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
                      emptyTitle: 'No live competitions',
                      emptyMessage: 'Check back soon for the next paid challenge.',
                      errorTitle: 'Unable to load live competitions',
                      errorMessage: _liveError,
                      onRetry: _loadLiveCompetitions,
                      cardBuilder: (c) => _CompetitionHubCard(
                        competition: c,
                        primaryLabel: c.isJoined ? 'View My Entry' : 'Join Now',
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
                      emptyTitle: 'No upcoming competitions',
                      emptyMessage: 'New premium contests will appear here.',
                      errorTitle: 'Unable to load upcoming competitions',
                      errorMessage: _upcomingError,
                      onRetry: _loadUpcomingCompetitions,
                      cardBuilder: (c) => _CompetitionHubCard(
                        competition: c,
                        primaryLabel: _notifyingCompetitionIds.contains(c.id)
                            ? 'Please wait…'
                            : c.isNotifyEnabled
                                ? 'Reminder Set'
                                : 'Notify Me',
                        onTap: () => _openCompetitionDetails(c),
                        onPrimaryTap: () {
                          if (_notifyingCompetitionIds.contains(c.id) ||
                              c.isNotifyEnabled) { return; }
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
                      emptyTitle: 'No past winners yet',
                      emptyMessage: 'Completed competitions will appear here.',
                      errorTitle: 'Unable to load past winners',
                      errorMessage: _pastError,
                      onRetry: _loadPastCompetitions,
                      cardBuilder: (c) => _CompetitionHubCard(
                        competition: c,
                        primaryLabel: 'View Winners',
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

    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          tooltip: 'My Competitions',
          onPressed: _openMyCompetitions,
          icon: const Icon(Icons.person_outline),
          color: Colors.white,
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                    theme.colorScheme.primary.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            // Decorative blurred circle
            Positioned(
              right: -40,
              top: -20,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
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
                      const Icon(Iconsax.cup, size: 22, color: Colors.white),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Competitions',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      _HeaderStatBadge(
                        label: '$liveCount Live',
                        icon: Iconsax.flash_1,
                      ),
                      const SizedBox(width: Spacing.sm),
                      _HeaderStatBadge(
                        label: '$upcomingCount Upcoming',
                        icon: Iconsax.calendar_1,
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
            Icon(Iconsax.cup, size: 18, color: Colors.white),
            const SizedBox(width: Spacing.sm),
            const Text(
              'Competitions',
              style: TextStyle(
                color: Colors.white,
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
        preferredSize: const Size.fromHeight(48),
        child: ColoredBox(
          color: theme.colorScheme.primary,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: theme.textTheme.labelLarge,
            tabs: const [
              Tab(text: 'Live Now'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Past Winners'),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────

  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(theme),
                  const SizedBox(width: Spacing.xs),
                  _sortChip(_SortField.date, 'Date', theme),
                  const SizedBox(width: Spacing.xs),
                  _sortChip(_SortField.price, 'Price', theme),
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
    final hasCategory = _selectedCategory != null;
    return FilterChip(
      label: Text(hasCategory ? _selectedCategory! : 'Category'),
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
  }) {
    switch (state) {
      case CompetitionListState.initial:
      case CompetitionListState.loading:
        return const Center(child: CircularProgressIndicator());
      case CompetitionListState.empty:
        return CompetitionSectionPlaceholder(
          title: emptyTitle,
          message: emptyMessage,
        );
      case CompetitionListState.error:
        return CompetitionSectionPlaceholder(
          title: errorTitle,
          message: errorMessage ?? 'Something went wrong.',
          showRetry: true,
          onRetry: onRetry,
        );
      case CompetitionListState.success:
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
          cmp = (a.registrationStart ?? DateTime(0))
              .compareTo(b.registrationStart ?? DateTime(0));
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
    final hasBanner = (competition.bannerUrl ?? '').isNotEmpty;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xLarge),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner section ─────────────────────────────────────────────
            AspectRatio(
              aspectRatio: 16 / 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner image or fallback
                  if (hasBanner)
                    Image.network(
                      competition.bannerUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallback(theme),
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : _buildFallback(theme),
                    )
                  else
                    _buildFallback(theme),

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
                        label: 'Joined',
                        icon: Icons.check_circle_outline,
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
                          _GlassChip(label: competition.category!),
                        const SizedBox(height: 4),
                        Text(
                          competition.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black54),
                            ],
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
                        tooltip: 'Entry Fee',
                      ),
                      const SizedBox(width: Spacing.sm),
                      _StatChip(
                        icon: Iconsax.cup,
                        label: formatMoney(
                          competition.prizePool,
                          competition.currencySymbol,
                        ),
                        tooltip: 'Prize Pool',
                        highlight: true,
                      ),
                      if (competition.totalParticipants != null) ...[
                        const SizedBox(width: Spacing.sm),
                        _StatChip(
                          icon: Iconsax.people,
                          label: '${competition.totalParticipants}',
                          tooltip: 'Participants',
                        ),
                      ],
                      const Spacer(),
                      _StatChip(
                        icon: Iconsax.gallery,
                        label: competition.allowedMediaType.label,
                        tooltip: 'Allowed media',
                      ),
                    ],
                  ),

                  // Countdown / registration start
                  if (showCountdown && competition.registrationEnd != null) ...[
                    const SizedBox(height: Spacing.sm),
                    CompetitionCountdownTimer(
                      targetTime: competition.registrationEnd,
                      prefix: 'Closes in',
                      emptyLabel: 'Closing soon',
                    ),
                  ] else if (showRegistrationStart &&
                      competition.registrationStart != null) ...[
                    const SizedBox(height: Spacing.sm),
                    CompetitionCountdownTimer(
                      targetTime: competition.registrationStart,
                      prefix: 'Opens in',
                      emptyLabel: 'Opening soon',
                    ),
                  ],

                  // Winner preview for past tab
                  if (winnerPreview != null && winnerPreview!.isNotEmpty) ...[
                    const SizedBox(height: Spacing.sm),
                    const Divider(height: 1),
                    const SizedBox(height: Spacing.sm),
                    ...winnerPreview!.take(2).map(
                          (w) => CompetitionWinnerTile(winner: w),
                        ),
                  ],

                  const SizedBox(height: Spacing.sm),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onPrimaryTap,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.large),
                        ),
                      ),
                      child: Text(primaryLabel),
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

  Widget _buildFallback(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Center(
        child: Icon(
          Iconsax.cup,
          size: 48,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 11, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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
    final color = highlight
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final bg = highlight
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

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
            Icon(icon, size: 13, color: color),
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
  const _HeaderStatBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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
                    'Filter by Category',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
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
                    title: const Text('All Categories'),
                    selected: selectedCategory == null,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor:
                        theme.colorScheme.primary.withValues(alpha: 0.08),
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
                      selectedTileColor:
                          theme.colorScheme.primary.withValues(alpha: 0.08),
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