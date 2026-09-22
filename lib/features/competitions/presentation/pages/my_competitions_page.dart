import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/competitions/data/models/competition_models.dart';
import 'package:snginepro/features/competitions/data/services/competition_api_service.dart';
import 'package:snginepro/features/competitions/presentation/pages/competition_detail_page.dart';
import 'package:snginepro/features/competitions/presentation/widgets/competition_widgets.dart';

class MyCompetitionsPage extends StatefulWidget {
  const MyCompetitionsPage({super.key});

  @override
  State<MyCompetitionsPage> createState() => _MyCompetitionsPageState();
}

class _MyCompetitionsPageState extends State<MyCompetitionsPage> {
  CompetitionListState _state = CompetitionListState.initial;
  List<UserCompetitionModel> _items = const <UserCompetitionModel>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = CompetitionListState.loading;
      _error = null;
    });

    try {
      final items = await context.read<CompetitionApiService>().getMyCompetitions();
      if (!mounted) return;
      setState(() {
        _items = items;
        _state = items.isEmpty
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

  void _openDetails(UserCompetitionModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompetitionDetailPage(
          competitionId: item.competition.id,
          initialCompetition: item.competition,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('my_competitions_title'.tr),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: switch (_state) {
          CompetitionListState.initial ||
          CompetitionListState.loading => const Center(
              child: CircularProgressIndicator(),
            ),
          CompetitionListState.empty => CompetitionSectionPlaceholder(
              title: 'my_competitions_empty_title'.tr,
              message: 'my_competitions_empty_msg'.tr,
            ),
          CompetitionListState.error => CompetitionSectionPlaceholder(
              title: 'my_competitions_load_failed'.tr,
              message: _error ?? 'something_went_wrong'.tr,
              showRetry: true,
              onRetry: _load,
            ),
          CompetitionListState.success => ListView.builder(
              padding: const EdgeInsets.all(Spacing.lg),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return CompetitionHistoryTile(
                  item: item,
                  onTap: () => _openDetails(item),
                );
              },
            ),
        },
      ),
    );
  }
}
