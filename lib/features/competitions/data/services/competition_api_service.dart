import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/features/competitions/data/models/competition_models.dart';
import 'package:snginepro/main.dart' show configCfgP;

class CompetitionApiService {
  CompetitionApiService(this._client);

  final ApiClient _client;

  Future<List<CompetitionModel>> getLiveCompetitions() async {
    return _fetchCompetitionList(
      _endpoint('competitions_live', '/data/competitions'),
      queryParameters: const {'status': 'live'},
    );
  }

  Future<List<CompetitionModel>> getUpcomingCompetitions() async {
    return _fetchCompetitionList(
      _endpoint('competitions_upcoming', '/data/competitions'),
      queryParameters: const {'status': 'upcoming'},
    );
  }

  Future<List<CompetitionModel>> getPastCompetitions() async {
    return _fetchCompetitionList(
      _endpoint('competitions_past', '/data/competitions'),
      queryParameters: const {'status': 'completed'},
    );
  }

  Future<List<CompetitionModel>> getPastWinners() async {
    return getPastCompetitions();
  }

  Future<CompetitionModel> getCompetitionDetails(int competitionId) async {
    final response = await _client.get(
      _idEndpoint(
        configKey: 'competition_details',
        fallbackBase: '/data/competitions/$competitionId',
        id: competitionId,
      ),
    );

    final item = _extractCompetitionMap(response);
    if (item == null) {
      throw ApiException(
        'Competition details are unavailable',
        details: response,
      );
    }

    return CompetitionModel.fromJson(item);
  }

  Future<List<CompetitionEntryModel>> getCompetitionEntries(
    int competitionId,
  ) async {
    final response = await _client.get(
      _idEndpoint(
        configKey: 'competition_entries',
        fallbackBase: '/data/competitions/$competitionId/entries',
        id: competitionId,
        suffix: '/entries',
      ),
    );

    final list = _extractItems(
      response,
      preferredKeys: const [
        'entries',
        'competition_entries',
        'participants',
        'items',
      ],
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(CompetitionEntryModel.fromJson)
        .toList(growable: false);
  }

  Future<CompetitionLeaderboardModel> getCompetitionLeaderboard(
    int competitionId,
  ) async {
    final response = await _client.get(
      _idEndpoint(
        configKey: 'competition_leaderboard',
        fallbackBase: '/data/competitions/$competitionId/leaderboard',
        id: competitionId,
        suffix: '/leaderboard',
      ),
    );
    final items = _extractItems(
      response,
      preferredKeys: const [
        'leaderboard',
        'leaders',
        'entries',
        'items',
      ],
    );
    return CompetitionLeaderboardModel(
      entries: items
          .whereType<Map<String, dynamic>>()
          .map(CompetitionEntryModel.fromJson)
          .toList(growable: false),
      updatedAt: DateTime.tryParse(
        response['updated_at']?.toString() ??
            response['data']?['updated_at']?.toString() ??
            '',
      ),
    );
  }

  Future<List<CompetitionWinnerModel>> getCompetitionWinners(
    int competitionId,
  ) async {
    final response = await _client.get(
      _idEndpoint(
        configKey: 'competition_winners_by_id',
        fallbackBase: '/data/competitions/$competitionId/winners',
        id: competitionId,
        suffix: '/winners',
      ),
    );
    final items = _extractItems(
      response,
      preferredKeys: const [
        'winners',
        'past_winners',
        'items',
      ],
    );
    return items
        .whereType<Map<String, dynamic>>()
        .map(CompetitionWinnerModel.fromJson)
        .toList(growable: false);
  }

  Future<List<UserCompetitionModel>> getMyCompetitions() async {
    final response = await _client.get(
      _endpoint('user_competitions', '/data/user/competitions'),
    );
    final items = _extractItems(
      response,
      preferredKeys: const [
        'competitions',
        'items',
        'results',
        'joined_competitions',
      ],
    );
    return items
        .whereType<Map<String, dynamic>>()
        .map(UserCompetitionModel.fromJson)
        .toList(growable: false);
  }

  Future<CompetitionWalletBalance> checkWalletBalance() async {
    final response = await _client.get(
      _endpoint('wallet_balance', '/data/wallet/balance'),
    );
    return CompetitionWalletBalance.fromJson(
      response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response,
    );
  }

  Future<CompetitionSubmitResponse> checkEligibility(int competitionId) async {
    final response = await _client.post(
      _idEndpoint(
        configKey: 'competition_check_eligibility',
        fallbackBase: '/data/competitions/$competitionId/check-eligibility',
        id: competitionId,
        suffix: '/check-eligibility',
      ),
      body: {'competition_id': competitionId},
    );
    return CompetitionSubmitResponse.fromJson({
      'success': response['success'] ?? response['status'] == 'success',
      'message': response['message'],
      'data': response['data'],
    });
  }

  Future<CompetitionSubmitResponse> joinCompetition({
    required int competitionId,
    required CompetitionSubmitRequest request,
  }) {
    return submitCompetitionEntry(
      competitionId: competitionId,
      request: request,
    );
  }

  Future<CompetitionSubmitResponse> submitCompetitionEntry({
    required int competitionId,
    required CompetitionSubmitRequest request,
  }) async {
    final response = await _client.post(
      _idEndpoint(
        configKey: 'competition_submit_entry',
        fallbackBase: '/data/competitions/$competitionId/submit-entry',
        id: competitionId,
        suffix: '/submit-entry',
      ),
      body: request.toJson(),
    );

    final result = CompetitionSubmitResponse.fromJson(response);
    if (!result.success) {
      throw ApiException(
        result.message ?? 'Failed to submit competition entry',
        details: response,
      );
    }
    return result;
  }

  Future<void> notifyCompetition(int competitionId) async {
    final response = await _client.post(
      _idEndpoint(
        configKey: 'competition_notify',
        fallbackBase: '/data/competitions/$competitionId/notify-me',
        id: competitionId,
        suffix: '/notify-me',
      ),
      body: {'competition_id': competitionId},
    );

    final success = response['status'] == 'success' || response['success'] == true;
    if (!success) {
      throw ApiException(
        response['message']?.toString() ??
            'Unable to enable competition notifications',
        details: response,
      );
    }
  }

  Future<List<CompetitionTagModel>> getUserCompetitionTags(int userId) async {
    final response = await _client.get(
      _endpoint('competition_user_tags', '/data/user/competitions/tags'),
      queryParameters: {'user_id': userId.toString()},
    );

    final list = _extractItems(
      response,
      preferredKeys: const [
        'winner_tags',
        'profile_tags',
        'achievement_tags',
        'category_tags',
        'competition_tags',
        'tags',
      ],
    );

    return list
        .map(CompetitionTagModel.fromJson)
        .where((tag) => tag.title.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<List<CompetitionModel>> _fetchCompetitionList(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _client.get(
      endpoint,
      queryParameters: queryParameters,
    );
    final items = _extractItems(
      response,
      preferredKeys: const [
        'competitions',
        'items',
        'results',
        'past_winners',
        'winners',
      ],
    );

    return items
        .whereType<Map<String, dynamic>>()
        .map(CompetitionModel.fromJson)
        .toList(growable: false);
  }

  String _endpoint(String configKey, String fallback) {
    final configured = configCfgP(configKey);
    if (configured.trim().isNotEmpty) {
      return configured;
    }
    return fallback;
  }

  String _idEndpoint({
    required String configKey,
    required String fallbackBase,
    required int id,
    String suffix = '',
  }) {
    final configured = configCfgP(configKey);
    if (configured.trim().isEmpty) {
      return fallbackBase;
    }
    if (configured.contains('{id}')) {
      return configured.replaceAll('{id}', '$id');
    }
    if (configured.endsWith('/$id') || configured.endsWith(suffix)) {
      return configured;
    }
    final normalized = configured.endsWith('/')
        ? configured.substring(0, configured.length - 1)
        : configured;
    return '$normalized/$id$suffix';
  }

  Map<String, dynamic>? _extractCompetitionMap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      for (final key in const ['competition', 'item', 'details']) {
        final value = data[key];
        if (value is Map<String, dynamic>) {
          return value;
        }
      }

      if (data.containsKey('id') || data.containsKey('competition_id')) {
        return data;
      }
    }
    if (response.containsKey('id') || response.containsKey('competition_id')) {
      return response;
    }
    return null;
  }

  List<dynamic> _extractItems(
    Map<String, dynamic> response, {
    required List<String> preferredKeys,
  }) {
    final data = response['data'];
    if (data is List) return data;

    if (data is Map<String, dynamic>) {
      for (final key in preferredKeys) {
        final value = data[key];
        if (value is List) {
          return value;
        }
      }
    }

    for (final key in preferredKeys) {
      final value = response[key];
      if (value is List) {
        return value;
      }
    }

    return const <dynamic>[];
  }
}
