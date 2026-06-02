import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/competitions/data/models/competition_models.dart';
import 'package:snginepro/features/competitions/data/services/competition_api_service.dart';
import 'package:snginepro/features/competitions/presentation/widgets/competition_widgets.dart';

class CompetitionLeaderboardPage extends StatefulWidget {
  const CompetitionLeaderboardPage({
    super.key,
    required this.competitionId,
    required this.competitionName,
    this.initialEntries = const <CompetitionEntryModel>[],
  });

  final int competitionId;
  final String competitionName;
  final List<CompetitionEntryModel> initialEntries;

  @override
  State<CompetitionLeaderboardPage> createState() =>
      _CompetitionLeaderboardPageState();
}

class _CompetitionLeaderboardPageState
    extends State<CompetitionLeaderboardPage> {
  CompetitionListState _state = CompetitionListState.initial;
  List<CompetitionEntryModel> _entries = const <CompetitionEntryModel>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _entries = widget.initialEntries;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = CompetitionListState.loading;
      _error = null;
    });
    try {
      final result = await context
          .read<CompetitionApiService>()
          .getCompetitionLeaderboard(widget.competitionId);
      if (!mounted) return;
      setState(() {
        _entries = result.entries;
        _state = _entries.isEmpty
            ? CompetitionListState.empty
            : CompetitionListState.success;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _state = CompetitionListState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.competitionName} ${'leaderboard_title_suffix'.tr}'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: switch (_state) {
          CompetitionListState.initial ||
          CompetitionListState.loading => const Center(
              child: CircularProgressIndicator(),
            ),
          CompetitionListState.empty => CompetitionSectionPlaceholder(
              title: 'leaderboard_empty_title'.tr,
              message: 'leaderboard_empty_msg'.tr,
            ),
          CompetitionListState.error => CompetitionSectionPlaceholder(
              title: 'leaderboard_load_failed'.tr,
              message: _error ?? 'something_went_wrong'.tr,
              showRetry: true,
              onRetry: _load,
            ),
          CompetitionListState.success => ListView.separated(
              padding: const EdgeInsets.all(Spacing.lg),
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final rank = entry.rank ?? index + 1;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.md),
                    child: Row(
                      children: [
                        WinnerRankBadge(rank: rank, compact: true),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.userName ?? 'competition_participant_default'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if ((entry.postText ?? '').isNotEmpty)
                                Text(
                                  entry.postText!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: Spacing.xs),
                              Text(
                                'leaderboard_stats'.trParams({
                                  'likes': '${entry.likesCount ?? 0}',
                                  'comments': '${entry.commentsCount ?? 0}',
                                  'reactions': '${entry.reactionsCount ?? 0}',
                                }),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              (entry.totalScore ?? 0).toStringAsFixed(0),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (entry.prizeAmount != null)
                              Text(
                                formatMoney(
                                  entry.prizeAmount,
                                  entry.currencySymbol,
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
              itemCount: _entries.length,
            ),
        },
      ),
    );
  }
}
