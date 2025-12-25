/// نماذج إعدادات الخصوصية والإشعارات
class PrivacySettings {
  final PrivacyOptions privacy;
  final NotificationOptions notifications;

  PrivacySettings({required this.privacy, required this.notifications});

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      privacy: PrivacyOptions.fromJson(json['privacy'] ?? {}),
      notifications: NotificationOptions.fromJson(json['notifications'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privacy': privacy.toJson(),
      'notifications': notifications.toJson(),
    };
  }
}

/// خيارات الخصوصية
class PrivacyOptions {
  // Visibility settings
  final String basic;
  final String work;
  final String location;
  final String education;
  final String other;
  final String friends;
  final String followers;
  final String photos;
  final String pages;
  final String groups;
  final String events;
  final String subscriptions;
  final String gender;
  final String birthdate;
  final String relationship;

  // Interaction settings
  final String wall;
  final String chat;
  final String poke;
  final String gifts;

  // Feature toggles
  final bool chatEnabled;
  final bool newsletterEnabled;
  final bool tipsEnabled;
  final bool suggestionsHidden;

  PrivacyOptions({
    required this.basic,
    required this.work,
    required this.location,
    required this.education,
    required this.other,
    required this.friends,
    required this.followers,
    required this.photos,
    required this.pages,
    required this.groups,
    required this.events,
    required this.subscriptions,
    required this.gender,
    required this.birthdate,
    required this.relationship,
    required this.wall,
    required this.chat,
    required this.poke,
    required this.gifts,
    required this.chatEnabled,
    required this.newsletterEnabled,
    required this.tipsEnabled,
    required this.suggestionsHidden,
  });

  factory PrivacyOptions.fromJson(Map<String, dynamic> json) {
    // Helper function to ensure valid privacy values
    String normalizePrivacyValue(dynamic value) {
      if (value == null || value == '' || value.toString().isEmpty) {
        return 'public'; // Default to public if empty
      }
      final stringValue = value.toString().toLowerCase().trim();
      if (['public', 'friends', 'me'].contains(stringValue)) {
        return stringValue;
      }
      // If invalid value, default to public
      return 'public';
    }

    return PrivacyOptions(
      basic: normalizePrivacyValue(json['user_privacy_basic']),
      work: normalizePrivacyValue(json['user_privacy_work']),
      location: normalizePrivacyValue(json['user_privacy_location']),
      education: normalizePrivacyValue(json['user_privacy_education']),
      other: normalizePrivacyValue(json['user_privacy_other']),
      friends: normalizePrivacyValue(json['user_privacy_friends']),
      followers: normalizePrivacyValue(json['user_privacy_followers']),
      photos: normalizePrivacyValue(json['user_privacy_photos']),
      pages: normalizePrivacyValue(json['user_privacy_pages']),
      groups: normalizePrivacyValue(json['user_privacy_groups']),
      events: normalizePrivacyValue(json['user_privacy_events']),
      subscriptions: normalizePrivacyValue(json['user_privacy_subscriptions']),
      gender: normalizePrivacyValue(json['user_privacy_gender']),
      birthdate: normalizePrivacyValue(json['user_privacy_birthdate']),
      relationship: normalizePrivacyValue(json['user_privacy_relationship']),
      wall: normalizePrivacyValue(json['user_privacy_wall']),
      chat: normalizePrivacyValue(json['user_privacy_chat']),
      poke: normalizePrivacyValue(json['user_privacy_poke']),
      gifts: normalizePrivacyValue(json['user_privacy_gifts']),
      chatEnabled:
          json['user_chat_enabled'] == true ||
          json['user_chat_enabled'] == 1 ||
          json['user_chat_enabled'] == '1',
      newsletterEnabled:
          json['user_newsletter_enabled'] == true ||
          json['user_newsletter_enabled'] == 1 ||
          json['user_newsletter_enabled'] == '1',
      tipsEnabled:
          json['user_tips_enabled'] == true ||
          json['user_tips_enabled'] == 1 ||
          json['user_tips_enabled'] == '1',
      suggestionsHidden:
          json['user_suggestions_hidden'] == true ||
          json['user_suggestions_hidden'] == 1 ||
          json['user_suggestions_hidden'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_privacy_basic': basic,
      'user_privacy_work': work,
      'user_privacy_location': location,
      'user_privacy_education': education,
      'user_privacy_other': other,
      'user_privacy_friends': friends,
      'user_privacy_followers': followers,
      'user_privacy_photos': photos,
      'user_privacy_pages': pages,
      'user_privacy_groups': groups,
      'user_privacy_events': events,
      'user_privacy_subscriptions': subscriptions,
      'user_privacy_gender': gender,
      'user_privacy_birthdate': birthdate,
      'user_privacy_relationship': relationship,
      'user_privacy_wall': wall,
      'user_privacy_chat': chat,
      'user_privacy_poke': poke,
      'user_privacy_gifts': gifts,
      'user_chat_enabled': chatEnabled,
      'user_newsletter_enabled': newsletterEnabled,
      'user_tips_enabled': tipsEnabled,
      'user_suggestions_hidden': suggestionsHidden,
    };
  }

  PrivacyOptions copyWith({
    String? basic,
    String? work,
    String? location,
    String? education,
    String? other,
    String? friends,
    String? followers,
    String? photos,
    String? pages,
    String? groups,
    String? events,
    String? subscriptions,
    String? gender,
    String? birthdate,
    String? relationship,
    String? wall,
    String? chat,
    String? poke,
    String? gifts,
    bool? chatEnabled,
    bool? newsletterEnabled,
    bool? tipsEnabled,
    bool? suggestionsHidden,
  }) {
    return PrivacyOptions(
      basic: basic ?? this.basic,
      work: work ?? this.work,
      location: location ?? this.location,
      education: education ?? this.education,
      other: other ?? this.other,
      friends: friends ?? this.friends,
      followers: followers ?? this.followers,
      photos: photos ?? this.photos,
      pages: pages ?? this.pages,
      groups: groups ?? this.groups,
      events: events ?? this.events,
      subscriptions: subscriptions ?? this.subscriptions,
      gender: gender ?? this.gender,
      birthdate: birthdate ?? this.birthdate,
      relationship: relationship ?? this.relationship,
      wall: wall ?? this.wall,
      chat: chat ?? this.chat,
      poke: poke ?? this.poke,
      gifts: gifts ?? this.gifts,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      newsletterEnabled: newsletterEnabled ?? this.newsletterEnabled,
      tipsEnabled: tipsEnabled ?? this.tipsEnabled,
      suggestionsHidden: suggestionsHidden ?? this.suggestionsHidden,
    );
  }
}

/// خيارات الإشعارات
class NotificationOptions {
  final bool emailPostLikes;
  final bool emailPostComments;
  final bool emailPostShares;
  final bool emailWallPosts;
  final bool emailMentions;
  final bool emailProfileVisits;
  final bool emailFriendRequests;
  final bool notificationsSound;
  final bool chatSound;

  NotificationOptions({
    required this.emailPostLikes,
    required this.emailPostComments,
    required this.emailPostShares,
    required this.emailWallPosts,
    required this.emailMentions,
    required this.emailProfileVisits,
    required this.emailFriendRequests,
    required this.notificationsSound,
    required this.chatSound,
  });

  factory NotificationOptions.fromJson(Map<String, dynamic> json) {
    // Helper function to normalize boolean values from API
    bool normalizeBool(dynamic value, [bool defaultValue = true]) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value == 1 || value == '1' || value == 'true') return true;
      if (value == 0 || value == '0' || value == 'false') return false;
      return defaultValue;
    }

    return NotificationOptions(
      emailPostLikes: normalizeBool(json['email_post_likes']),
      emailPostComments: normalizeBool(json['email_post_comments']),
      emailPostShares: normalizeBool(json['email_post_shares']),
      emailWallPosts: normalizeBool(json['email_wall_posts']),
      emailMentions: normalizeBool(json['email_mentions']),
      emailProfileVisits: normalizeBool(json['email_profile_visits']),
      emailFriendRequests: normalizeBool(json['email_friend_requests']),
      notificationsSound: normalizeBool(json['notifications_sound']),
      chatSound: normalizeBool(json['chat_sound']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email_post_likes': emailPostLikes,
      'email_post_comments': emailPostComments,
      'email_post_shares': emailPostShares,
      'email_wall_posts': emailWallPosts,
      'email_mentions': emailMentions,
      'email_profile_visits': emailProfileVisits,
      'email_friend_requests': emailFriendRequests,
      'notifications_sound': notificationsSound,
      'chat_sound': chatSound,
    };
  }

  NotificationOptions copyWith({
    bool? emailPostLikes,
    bool? emailPostComments,
    bool? emailPostShares,
    bool? emailWallPosts,
    bool? emailMentions,
    bool? emailProfileVisits,
    bool? emailFriendRequests,
    bool? notificationsSound,
    bool? chatSound,
  }) {
    return NotificationOptions(
      emailPostLikes: emailPostLikes ?? this.emailPostLikes,
      emailPostComments: emailPostComments ?? this.emailPostComments,
      emailPostShares: emailPostShares ?? this.emailPostShares,
      emailWallPosts: emailWallPosts ?? this.emailWallPosts,
      emailMentions: emailMentions ?? this.emailMentions,
      emailProfileVisits: emailProfileVisits ?? this.emailProfileVisits,
      emailFriendRequests: emailFriendRequests ?? this.emailFriendRequests,
      notificationsSound: notificationsSound ?? this.notificationsSound,
      chatSound: chatSound ?? this.chatSound,
    );
  }
}

/// استجابة API للإعدادات
class PrivacySettingsResponse {
  final String status;
  final String message;
  final PrivacySettings data;

  PrivacySettingsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PrivacySettingsResponse.fromJson(Map<String, dynamic> json) {
    return PrivacySettingsResponse(
      status: json['status'] ?? 'success',
      message: json['message'] ?? '',
      data: PrivacySettings.fromJson(json['data'] ?? {}),
    );
  }
}
