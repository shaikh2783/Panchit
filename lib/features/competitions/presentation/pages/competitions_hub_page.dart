import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/competitions/data/models/competition_models.dart';
import 'package:snginepro/features/competitions/data/services/competition_api_service.dart';
import 'package:snginepro/features/competitions/presentation/pages/competition_detail_page.dart';
import 'package:snginepro/features/competitions/presentation/pages/my_competitions_page.dart';
import 'package:snginepro/features/competitions/presentation/widgets/competition_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
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

  Future<void> _handleNotifyMe(CompetitionModel competition) async {
    setState(() {
      _notifyingCompetitionIds = {..._notifyingCompetitionIds, competition.id};
    });
    try {
      await context.read<CompetitionApiService>().notifyCompetition(competition.id);
      if (!mounted) return;
      setState(() {
        _upcomingCompetitions = _upcomingCompetitions.map((item) {
          if (item.id == competition.id) {
            return item.copyWith(isNotifyEnabled: true);
          }
          return item;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Competitions'),
        actions: [
          IconButton(
            tooltip: 'My Competitions',
            onPressed: _openMyCompetitions,
            icon: const Icon(Icons.person_outline),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Live Now'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Past Winners'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.06),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            RefreshIndicator(
              onRefresh: _loadLiveCompetitions,
              child: _buildCompetitionTab(
                state: _liveState,
                competitions: _liveCompetitions,
                emptyTitle: 'No live competitions',
                emptyMessage: 'Check back soon for the next paid challenge.',
                errorTitle: 'Unable to load live competitions',
                errorMessage: _liveError,
                onRetry: _loadLiveCompetitions,
                cardBuilder: (competition) => CompetitionCard(
                  competition: competition,
                  primaryButtonLabel: competition.isJoined
                      ? 'View My Entry'
                      : 'Join Competition',
                  onPrimaryTap: () => _openCompetitionDetails(competition),
                  onTap: () => _openCompetitionDetails(competition),
                  showCountdown: true,
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: _loadUpcomingCompetitions,
              child: _buildCompetitionTab(
                state: _upcomingState,
                competitions: _upcomingCompetitions,
                emptyTitle: 'No upcoming competitions',
                emptyMessage: 'New premium contests will appear here.',
                errorTitle: 'Unable to load upcoming competitions',
                errorMessage: _upcomingError,
                onRetry: _loadUpcomingCompetitions,
                cardBuilder: (competition) => CompetitionCard(
                  competition: competition,
                  primaryButtonLabel: _notifyingCompetitionIds.contains(competition.id)
                      ? 'Please wait...'
                      : competition.isNotifyEnabled
                          ? 'Reminder Enabled'
                          : 'Notify Me',
                  onPrimaryTap: () {
                    if (_notifyingCompetitionIds.contains(competition.id) ||
                        competition.isNotifyEnabled) {
                      return;
                    }
                    _handleNotifyMe(competition);
                  },
                  onTap: () => _openCompetitionDetails(competition),
                  showRegistrationStart: true,
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: _loadPastCompetitions,
              child: _buildCompetitionTab(
                state: _pastState,
                competitions: _pastCompetitions,
                emptyTitle: 'No past winners',
                emptyMessage: 'Completed competitions will appear here.',
                errorTitle: 'Unable to load past winners',
                errorMessage: _pastError,
                onRetry: _loadPastCompetitions,
                cardBuilder: (competition) => CompetitionCard(
                  competition: competition,
                  primaryButtonLabel: 'View Winners',
                  onPrimaryTap: () => _openCompetitionDetails(competition),
                  onTap: () => _openCompetitionDetails(competition),
                  secondaryChild: competition.winners.isEmpty
                      ? const Text('Winner details will be shown when available.')
                      : Column(
                          children: competition.winners
                              .take(3)
                              .map((winner) => CompetitionWinnerTile(
                                    winner: winner,
                                  ))
                              .toList(growable: false),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionTab({
    required CompetitionListState state,
    required List<CompetitionModel> competitions,
    required String emptyTitle,
    required String emptyMessage,
    required String errorTitle,
    required String? errorMessage,
    required Future<void> Function() onRetry,
    required Widget Function(CompetitionModel competition) cardBuilder,
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
        return ListView.builder(
          padding: const EdgeInsets.all(Spacing.lg),
          itemCount: competitions.length,
          itemBuilder: (context, index) => cardBuilder(competitions[index]),
        );
    }
  }
}
