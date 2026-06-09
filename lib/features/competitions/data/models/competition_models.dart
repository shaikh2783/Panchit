enum CompetitionListState {
  initial,
  loading,
  success,
  empty,
  error,
}

enum CompetitionSubmissionState {
  initial,
  submitting,
  success,
  failure,
}

enum CompetitionAllowedMediaType {
  all,
  imageOnly,
  videoOnly,
  textOnly,
}

extension CompetitionAllowedMediaTypeX on CompetitionAllowedMediaType {
  bool get allowsImages =>
      this == CompetitionAllowedMediaType.all ||
      this == CompetitionAllowedMediaType.imageOnly;

  bool get allowsVideo =>
      this == CompetitionAllowedMediaType.all ||
      this == CompetitionAllowedMediaType.videoOnly;

  bool get allowsText => true;

  String get label {
    switch (this) {
      case CompetitionAllowedMediaType.imageOnly:
        return 'Image Only';
      case CompetitionAllowedMediaType.videoOnly:
        return 'Video Only';
      case CompetitionAllowedMediaType.textOnly:
        return 'Text Only';
      case CompetitionAllowedMediaType.all:
        return 'All';
    }
  }
}

enum CompetitionStatus {
  live,
  upcoming,
  registrationOpen,
  registrationClosed,
  voting,
  completed,
  cancelled,
  unknown,
}

extension CompetitionStatusX on CompetitionStatus {
  String get label {
    switch (this) {
      case CompetitionStatus.live:
        return 'Live Now';
      case CompetitionStatus.upcoming:
        return 'Upcoming';
      case CompetitionStatus.registrationOpen:
        return 'Registration Open';
      case CompetitionStatus.registrationClosed:
        return 'Registration Closed';
      case CompetitionStatus.voting:
        return 'Voting Ongoing';
      case CompetitionStatus.completed:
        return 'Completed';
      case CompetitionStatus.cancelled:
        return 'Cancelled';
      case CompetitionStatus.unknown:
        return 'Unknown';
    }
  }
}

class CompetitionPrizeModel {
  const CompetitionPrizeModel({
    required this.rank,
    this.title,
    this.amount,
    this.currencySymbol,
    this.description,
  });

  final int rank;
  final String? title;
  final double? amount;
  final String? currencySymbol;
  final String? description;

  String get displayTitle {
    if ((title ?? '').trim().isNotEmpty) {
      return title!.trim();
    }
    switch (rank) {
      case 1:
        return '1st Prize';
      case 2:
        return '2nd Prize';
      case 3:
        return '3rd Prize';
      default:
        return 'Prize';
    }
  }

  factory CompetitionPrizeModel.fromJson(
    Map<String, dynamic> json, {
    int? fallbackRank,
  }) {
    return CompetitionPrizeModel(
      rank: _int(
        json['rank'] ?? json['position'] ?? json['place'],
        fallback: fallbackRank ?? 0,
      ),
      title: _string(json['title'] ?? json['name'] ?? json['label']),
      amount: _double(json['amount'] ?? json['prize_amount'] ?? json['value']),
      currencySymbol: _string(
        json['currency_symbol'] ?? json['currency'] ?? json['symbol'],
      ),
      description: _string(json['description'] ?? json['details']),
    );
  }
}

class CompetitionWinnerModel {
  const CompetitionWinnerModel({
    required this.rank,
    this.userId,
    this.userName,
    this.userAvatar,
    this.postId,
    this.postThumbnail,
    this.postText,
    this.prizeAmount,
    this.currencySymbol,
  });

  final int rank;
  final int? userId;
  final String? userName;
  final String? userAvatar;
  final int? postId;
  final String? postThumbnail;
  final String? postText;
  final double? prizeAmount;
  final String? currencySymbol;

  factory CompetitionWinnerModel.fromJson(Map<String, dynamic> json) {
    return CompetitionWinnerModel(
      rank: _int(json['rank'] ?? json['winner_rank'] ?? json['position']),
      userId: _nullableInt(json['user_id'] ?? json['winner_user_id']),
      userName: _string(
        json['user_name'] ??
            json['winner_name'] ??
            json['full_name'] ??
            json['name'],
      ),
      userAvatar: _string(
        json['user_picture'] ??
            json['user_avatar'] ??
            json['winner_avatar'] ??
            json['picture'],
      ),
      postId: _nullableInt(json['post_id'] ?? json['winning_post_id']),
      postThumbnail: _string(
        json['post_thumbnail'] ??
            json['winning_post_thumbnail'] ??
            json['thumbnail'] ??
            json['image'],
      ),
      postText: _string(json['post_text'] ?? json['text'] ?? json['caption']),
      prizeAmount: _double(
        json['prize_amount'] ?? json['amount'] ?? json['prize_value'],
      ),
      currencySymbol: _string(
        json['currency_symbol'] ?? json['currency'] ?? json['symbol'],
      ),
    );
  }
}

class CompetitionEntryModel {
  const CompetitionEntryModel({
    required this.id,
    this.userId,
    this.userName,
    this.userAvatar,
    this.postId,
    this.postText,
    this.previewUrl,
    this.mediaType,
    this.publishedAt,
    this.privacy,
    this.likesCount,
    this.commentsCount,
    this.reactionsCount,
    this.sharesCount,
    this.viewsCount,
    this.reviewsCount,
    this.totalScore,
    this.rank,
    this.prizeAmount,
    this.currencySymbol,
  });

  final int id;
  final int? userId;
  final String? userName;
  final String? userAvatar;
  final int? postId;
  final String? postText;
  final String? previewUrl;
  final String? mediaType;
  final String? publishedAt;
  final String? privacy;
  final int? likesCount;
  final int? commentsCount;
  final int? reactionsCount;
  final int? sharesCount;
  final int? viewsCount;
  final int? reviewsCount;
  final double? totalScore;
  final int? rank;
  final double? prizeAmount;
  final String? currencySymbol;

  factory CompetitionEntryModel.fromJson(Map<String, dynamic> json) {
    final post = _map(json['post']);
    final photos = post['photos'];
    String? previewUrl;
    if (photos is List && photos.isNotEmpty && photos.first is Map<String, dynamic>) {
      previewUrl = _string((photos.first as Map<String, dynamic>)['source']);
    }
    previewUrl ??= _string(
      json['preview_url'] ??
          json['post_thumbnail'] ??
          post['og_image'] ??
          post['preview_url'] ??
          post['image'],
    );

    return CompetitionEntryModel(
      id: _int(json['id'] ?? json['entry_id'] ?? json['competition_entry_id']),
      userId: _nullableInt(json['user_id'] ?? post['user_id']),
      userName: _string(
        json['user_name'] ??
            post['post_author_name'] ??
            post['user_name'] ??
            post['page_title'] ??
            post['group_title'],
      ),
      userAvatar: _string(
        json['user_avatar'] ??
            post['post_author_picture'] ??
            post['user_picture'] ??
            post['page_picture'] ??
            post['group_picture'],
      ),
      postId: _nullableInt(json['post_id'] ?? post['post_id']),
      postText: _string(json['post_text'] ?? post['text_plain'] ?? post['text']),
      previewUrl: previewUrl,
      mediaType: _string(json['media_type'] ?? post['post_type']),
      publishedAt: _string(json['time'] ?? json['published_at'] ?? post['time']),
      privacy: _string(json['privacy'] ?? post['privacy']),
      likesCount: _nullableInt(
        json['likes_count'] ??
            json['post_likes'] ??
            post['reaction_like_count'] ??
            post['reactions_total_count'],
      ),
      commentsCount: _nullableInt(
        json['comments_count'] ?? json['post_comments'] ?? post['comments'],
      ),
      reactionsCount: _nullableInt(
        json['reactions_count'] ??
            json['post_reactions'] ??
            post['reactions_total_count'],
      ),
      sharesCount: _nullableInt(json['shares_count'] ?? json['post_shares'] ?? post['shares']),
      viewsCount: _nullableInt(json['views_count'] ?? post['views']),
      reviewsCount: _nullableInt(json['reviews_count'] ?? post['reviews_count']),
      totalScore: _double(json['total_score'] ?? json['score']),
      rank: _nullableInt(json['rank'] ?? json['winner_rank']),
      prizeAmount: _double(json['prize_amount']),
      currencySymbol: _string(json['currency_symbol']),
    );
  }
}

class CompetitionLeaderboardModel {
  const CompetitionLeaderboardModel({
    required this.entries,
    this.updatedAt,
  });

  final List<CompetitionEntryModel> entries;
  final DateTime? updatedAt;
}

class UserCompetitionModel {
  const UserCompetitionModel({
    required this.competition,
    this.entry,
    this.currentRank,
    this.prizeWon,
    this.refundStatus,
    this.statusLabel,
  });

  final CompetitionModel competition;
  final CompetitionEntryModel? entry;
  final int? currentRank;
  final double? prizeWon;
  final String? refundStatus;
  final String? statusLabel;

  factory UserCompetitionModel.fromJson(Map<String, dynamic> json) {
    final competitionMap = _map(
      json['competition'] ?? json['item'] ?? json,
    );
    return UserCompetitionModel(
      competition: CompetitionModel.fromJson(competitionMap),
      entry: json['entry'] is Map<String, dynamic>
          ? CompetitionEntryModel.fromJson(json['entry'] as Map<String, dynamic>)
          : null,
      currentRank: _nullableInt(json['current_rank'] ?? json['rank']),
      prizeWon: _double(json['prize_won'] ?? json['prize_amount']),
      refundStatus: _string(json['refund_status']),
      statusLabel: _string(json['status_label']),
    );
  }
}

class CompetitionTagModel {
  const CompetitionTagModel({
    required this.title,
    this.category,
    this.colorHex,
  });

  final String title;
  final String? category;
  final String? colorHex;

  factory CompetitionTagModel.fromJson(Object? json) {
    if (json is Map<String, dynamic>) {
      return CompetitionTagModel(
        title: _string(
              json['title'] ??
                  json['name'] ??
                  json['label'] ??
                  json['tag'],
            ) ??
            '',
        category: _string(json['category']),
        colorHex: _string(json['color_hex'] ?? json['color']),
      );
    }
    return CompetitionTagModel(title: json?.toString() ?? '');
  }
}

class CompetitionWalletBalance {
  const CompetitionWalletBalance({
    required this.balance,
    this.currencySymbol,
    this.currency,
  });

  final double balance;
  final String? currencySymbol;
  final String? currency;

  factory CompetitionWalletBalance.fromJson(Map<String, dynamic> json) {
    final wallet = _map(json['wallet']);
    final balances = _map(json['balances']);
    return CompetitionWalletBalance(
      balance: _double(
            json['balance'] ??
                wallet['balance'] ??
                json['wallet_balance'] ??
                balances['wallet'],
          ) ??
          0,
      currencySymbol: _string(
        json['currency_symbol'] ?? wallet['currency_symbol'],
      ),
      currency: _string(json['currency'] ?? wallet['currency']),
    );
  }
}

class CompetitionModel {
  const CompetitionModel({
    required this.id,
    required this.title,
    this.category,
    this.description,
    this.rules,
    this.bannerUrl,
    this.entryFee,
    this.prizePool,
    this.currencySymbol,
    this.registrationStart,
    this.registrationEnd,
    this.votingEnd,
    this.status = CompetitionStatus.unknown,
    this.allowedMediaType = CompetitionAllowedMediaType.all,
    this.minimumUsersRequired,
    this.totalParticipants,
    this.isJoined = false,
    this.isNotifyEnabled = false,
    this.isCancelled = false,
    this.prizes = const <CompetitionPrizeModel>[],
    this.leaders = const <CompetitionEntryModel>[],
    this.entries = const <CompetitionEntryModel>[],
    this.winners = const <CompetitionWinnerModel>[],
  });

  final int id;
  final String title;
  final String? category;
  final String? description;
  final String? rules;
  final String? bannerUrl;
  final double? entryFee;
  final double? prizePool;
  final String? currencySymbol;
  final DateTime? registrationStart;
  final DateTime? registrationEnd;
  final DateTime? votingEnd;
  final CompetitionStatus status;
  final CompetitionAllowedMediaType allowedMediaType;
  final int? minimumUsersRequired;
  final int? totalParticipants;
  final bool isJoined;
  final bool isNotifyEnabled;
  final bool isCancelled;
  final List<CompetitionPrizeModel> prizes;
  final List<CompetitionEntryModel> leaders;
  final List<CompetitionEntryModel> entries;
  final List<CompetitionWinnerModel> winners;

  bool get isCompleted => status == CompetitionStatus.completed;
  bool get isVotingOngoing => status == CompetitionStatus.voting;
  bool get isRegistrationNotStarted {
    final start = registrationStart;
    return start != null && DateTime.now().isBefore(start);
  }

  bool get isRegistrationOpen {
    if (isCancelled || isCompleted) return false;
    final now = DateTime.now();
    final startOkay = registrationStart == null || !now.isBefore(registrationStart!);
    final endOkay = registrationEnd == null || now.isBefore(registrationEnd!);
    return startOkay &&
        endOkay &&
        (status == CompetitionStatus.live ||
            status == CompetitionStatus.registrationOpen ||
            status == CompetitionStatus.unknown);
  }

  bool get isLive =>
      status == CompetitionStatus.live ||
      status == CompetitionStatus.registrationOpen;

  bool get hasPastWinners => winners.isNotEmpty;

  Duration? get timeUntilRegistrationEnd {
    final end = registrationEnd;
    if (end == null) return null;
    final difference = end.difference(DateTime.now());
    return difference.isNegative ? Duration.zero : difference;
  }

  Duration? get timeUntilRegistrationStarts {
    final start = registrationStart;
    if (start == null) return null;
    final difference = start.difference(DateTime.now());
    return difference.isNegative ? Duration.zero : difference;
  }

  CompetitionModel copyWith({
    int? id,
    String? title,
    String? category,
    String? description,
    String? rules,
    String? bannerUrl,
    double? entryFee,
    double? prizePool,
    String? currencySymbol,
    DateTime? registrationStart,
    DateTime? registrationEnd,
    DateTime? votingEnd,
    CompetitionStatus? status,
    CompetitionAllowedMediaType? allowedMediaType,
    int? minimumUsersRequired,
    int? totalParticipants,
    bool? isJoined,
    bool? isNotifyEnabled,
    bool? isCancelled,
    List<CompetitionPrizeModel>? prizes,
    List<CompetitionEntryModel>? leaders,
    List<CompetitionEntryModel>? entries,
    List<CompetitionWinnerModel>? winners,
  }) {
    return CompetitionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      rules: rules ?? this.rules,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      registrationStart: registrationStart ?? this.registrationStart,
      registrationEnd: registrationEnd ?? this.registrationEnd,
      votingEnd: votingEnd ?? this.votingEnd,
      status: status ?? this.status,
      allowedMediaType: allowedMediaType ?? this.allowedMediaType,
      minimumUsersRequired: minimumUsersRequired ?? this.minimumUsersRequired,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      isJoined: isJoined ?? this.isJoined,
      isNotifyEnabled: isNotifyEnabled ?? this.isNotifyEnabled,
      isCancelled: isCancelled ?? this.isCancelled,
      prizes: prizes ?? this.prizes,
      leaders: leaders ?? this.leaders,
      entries: entries ?? this.entries,
      winners: winners ?? this.winners,
    );
  }

  factory CompetitionModel.fromJson(Map<String, dynamic> json) {
    final prizes = _extractList(
      json,
      const ['prizes', 'prize_distribution', 'awards'],
    ).asMap().entries.map((entry) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        return CompetitionPrizeModel.fromJson(value, fallbackRank: entry.key + 1);
      }
      return CompetitionPrizeModel(rank: entry.key + 1);
    }).toList(growable: false);

    final leaders = _extractList(
      json,
      const ['leaders', 'leaderboard', 'top_leaders'],
    ).whereType<Map<String, dynamic>>()
        .map(CompetitionEntryModel.fromJson)
        .toList(growable: false);

    final userEntry = _extractMap(json, const ['user_entry']);
    final entries = <CompetitionEntryModel>[
      if (userEntry.isNotEmpty) CompetitionEntryModel.fromJson(userEntry),
      ..._extractList(
        json,
        const ['participants', 'competition_entries'],
      ).whereType<Map<String, dynamic>>().map(CompetitionEntryModel.fromJson),
    ];

    final winners = _extractList(
      json,
      const ['past_winners', 'winners', 'winner_users'],
    ).whereType<Map<String, dynamic>>()
        .map(CompetitionWinnerModel.fromJson)
        .toList(growable: false);

    return CompetitionModel(
      id: _int(json['id'] ?? json['competition_id']),
      title: _string(
            json['title'] ?? json['competition_name'] ?? json['name'],
          ) ??
          'Competition',
      category: _string(json['category_name'] ?? json['competition_category']),
      description: _string(json['description']),
      rules: _string(json['rules']),
      bannerUrl: _string(
        json['banner_url'] ?? json['image'] ?? json['banner'] ?? json['cover'],
      ),
      entryFee: _double(json['entry_fee'] ?? json['fee']),
      prizePool: _double(json['prize_pool'] ?? json['total_prize']),
      currencySymbol: _string(
        json['currency_symbol'] ?? json['currency'] ?? json['symbol'],
      ),
      registrationStart: _dateTime(
        json['registration_start'] ?? json['start_date'] ?? json['starts_at'],
      ),
      registrationEnd: _dateTime(
        json['registration_end'] ?? json['end_date'] ?? json['ends_at'],
      ),
      votingEnd: _dateTime(json['voting_end'] ?? json['voting_end_at']),
      status: _competitionStatus(
        json['status'] ?? json['competition_status'] ?? json['state'],
      ),
      allowedMediaType: _allowedMediaType(
        json['allowed_media_type'] ?? json['media_type'],
      ),
      minimumUsersRequired: _nullableInt(
        json['minimum_users_required'] ?? json['min_users'],
      ),
      totalParticipants: _nullableInt(
        json['total_participants'] ?? json['participants_count'],
      ),
      isJoined: _bool(json['is_joined'] ?? json['already_joined']),
      isNotifyEnabled: _bool(
        json['is_notify_enabled'] ?? json['notify_enabled'] ?? json['notified'],
      ),
      isCancelled: _bool(json['is_cancelled']) ||
          _competitionStatus(json['status']) == CompetitionStatus.cancelled,
      prizes: prizes,
      leaders: leaders,
      entries: entries,
      winners: winners,
    );
  }
}

class CompetitionSubmitRequest {
  const CompetitionSubmitRequest({
    this.message,
    this.photos = const <Map<String, dynamic>>[],
    this.video,
    this.mediaType,
    this.postId,
  });

  final String? message;
  final List<Map<String, dynamic>> photos;
  final Map<String, dynamic>? video;
  final String? mediaType;
  final int? postId;

  Map<String, dynamic> toJson() {
    return {
      if ((message ?? '').trim().isNotEmpty) 'message': message!.trim(),
      if (photos.isNotEmpty) 'photos': photos,
      if (video != null) 'video': video,
      if ((mediaType ?? '').trim().isNotEmpty) 'media_type': mediaType,
      if (postId != null) 'post_id': postId,
    };
  }
}

class CompetitionSubmitResponse {
  const CompetitionSubmitResponse({
    required this.success,
    this.message,
    this.entryId,
    this.postId,
    this.walletBalance,
  });

  final bool success;
  final String? message;
  final int? entryId;
  final int? postId;
  final double? walletBalance;

  factory CompetitionSubmitResponse.fromJson(Map<String, dynamic> json) {
    final data = _map(json['data']);
    return CompetitionSubmitResponse(
      success: _bool(json['success']) || json['status'] == 'success',
      message: _string(json['message']),
      entryId: _nullableInt(data['entry_id'] ?? json['entry_id']),
      postId: _nullableInt(data['post_id'] ?? json['post_id']),
      walletBalance: _double(
        data['wallet_balance'] ?? json['wallet_balance'],
      ),
    );
  }
}

CompetitionAllowedMediaType _allowedMediaType(Object? value) {
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  switch (normalized) {
    case 'image':
    case 'image_only':
    case 'image only':
      return CompetitionAllowedMediaType.imageOnly;
    case 'video':
    case 'video_only':
    case 'video only':
      return CompetitionAllowedMediaType.videoOnly;
    case 'text':
    case 'text_only':
    case 'text only':
      return CompetitionAllowedMediaType.textOnly;
    default:
      return CompetitionAllowedMediaType.all;
  }
}

CompetitionStatus _competitionStatus(Object? value) {
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  switch (normalized) {
    case 'live':
      return CompetitionStatus.live;
    case 'upcoming':
      return CompetitionStatus.upcoming;
    case 'registration_open':
    case 'registration open':
      return CompetitionStatus.registrationOpen;
    case 'registration_closed':
    case 'registration closed':
      return CompetitionStatus.registrationClosed;
    case 'voting':
    case 'voting_ongoing':
    case 'voting ongoing':
      return CompetitionStatus.voting;
    case 'completed':
      return CompetitionStatus.completed;
    case 'cancelled':
    case 'canceled':
      return CompetitionStatus.cancelled;
    default:
      return CompetitionStatus.unknown;
  }
}

List<dynamic> _extractList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value;
    }
  }
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      final value = data[key];
      if (value is List) {
        return value;
      }
    }
  }
  return const <dynamic>[];
}

Map<String, dynamic> _extractMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
  }
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      final value = data[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
  }
  return const <String, dynamic>{};
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return const <String, dynamic>{};
}

String? _string(Object? value) {
  if (value == null) return null;
  final stringValue = value.toString().trim();
  return stringValue.isEmpty ? null : stringValue;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on';
  }
  return false;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _nullableInt(Object? value) {
  final parsed = _int(value, fallback: 0);
  if (parsed == 0 && value != 0 && value?.toString().trim() != '0') {
    return null;
  }
  return parsed == 0 ? null : parsed;
}

double? _double(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _dateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
