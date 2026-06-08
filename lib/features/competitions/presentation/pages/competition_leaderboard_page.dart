import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/core/theme/widgets/elevated_card.dart';
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
                final mediaAsset = context.read<AppConfig>().mediaAsset;
                return _LeaderboardEntryCard(
                  entry: entry,
                  rank: rank,
                  mediaAsset: mediaAsset,
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

class _LeaderboardEntryCard extends StatelessWidget {
  const _LeaderboardEntryCard({
    required this.entry,
    required this.rank,
    required this.mediaAsset,
  });

  final CompetitionEntryModel entry;
  final int rank;
  final Uri Function(String) mediaAsset;

  String? _resolveUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final cleaned = raw.trim();
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return cleaned;
    }
    return mediaAsset(cleaned).toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTopRank = rank <= 3;
    final avatarUrl = _resolveUrl(entry.userAvatar);

    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.1,
    );
    final subtle = theme.colorScheme.onSurface.withValues(alpha: 0.62);

    final card = ElevatedCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(Spacing.md),
      borderRadius: Radii.large,
      color: isTopRank ? theme.colorScheme.primary.withValues(alpha: 0.06) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WinnerRankBadge(rank: rank, compact: true),
          const SizedBox(width: Spacing.md),
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Icon(
                    Icons.person_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  )
                : null,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.userName ?? 'competition_participant_default'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    _ScorePill(score: entry.totalScore),
                  ],
                ),
                if ((entry.postText ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    entry.postText!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                ],
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.xs,
                  runSpacing: Spacing.xs,
                  children: [
                    _StatChip(
                      icon: Icons.thumb_up_alt_outlined,
                      value: entry.likesCount ?? 0,
                    ),
                    _StatChip(
                      icon: Icons.mode_comment_outlined,
                      value: entry.commentsCount ?? 0,
                    ),
                    _StatChip(
                      icon: Icons.auto_awesome_outlined,
                      value: entry.reactionsCount ?? 0,
                    ),
                    if (entry.prizeAmount != null)
                      _PrizeChip(
                        label: formatMoney(entry.prizeAmount, entry.currencySymbol),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: subtle,
          ),
        ],
      ),
    );

    if (!isTopRank) return card;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.large),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.24),
        ),
      ),
      child: card,
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final double? score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = (score ?? 0).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt,
            size: 14,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.secondary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrizeChip extends StatelessWidget {
  const _PrizeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 14,
            color: Color(0xFF16A34A),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF16A34A),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
