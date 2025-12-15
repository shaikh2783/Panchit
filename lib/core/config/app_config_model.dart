import 'colored_pattern_model.dart';
import 'reaction_model.dart';
import 'upload_settings_model.dart';
/// نموذج البيانات الرئيسي لإعدادات التطبيق
class AppConfig {
  final AppInfo appInfo;
  final UiSettings uiSettings;
  final Features features;
  final UserPermissions userPermissions;
  final List<ColoredPattern> coloredPatterns;
  final List<Reaction> reactions;
  final UploadSettings uploadSettings;
  final List<Map<String, dynamic>> feelings;
  final List<Map<String, dynamic>> activities;
  final Map<String, dynamic>? expandable;
  final String timestamp;
  const AppConfig({
    required this.appInfo,
    required this.uiSettings,
    required this.features,
    required this.userPermissions,
    required this.coloredPatterns,
    required this.reactions,
    required this.uploadSettings,
    required this.feelings,
    required this.activities,
    this.expandable,
    required this.timestamp,
  });
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return AppConfig(
      appInfo: AppInfo.fromJson(data['app_info'] ?? {}),
      uiSettings: UiSettings.fromJson(data['ui_settings'] ?? {}),
      features: Features.fromJson(data['features'] ?? {}),
      userPermissions: UserPermissions.fromJson(data['user_permissions'] ?? {}),
      coloredPatterns: (data['colored_patterns'] as List<dynamic>?)
          ?.map((e) => ColoredPattern.fromJson(e))
          .toList() ?? [],
      reactions: (data['reactions'] as List<dynamic>?)
          ?.map((e) => Reaction.fromJson(e))
          .toList() ?? [],
      uploadSettings: UploadSettings.fromJson(data['upload_settings'] ?? {}),
      feelings: (data['feelings'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
      activities: (data['activities'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
      expandable: data['expandable'] as Map<String, dynamic>?,
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'data': {
        'app_info': appInfo.toJson(),
        'ui_settings': uiSettings.toJson(),
        'features': features.toJson(),
        'user_permissions': userPermissions.toJson(),
        'colored_patterns': coloredPatterns.map((e) => e.toJson()).toList(),
        'reactions': reactions.map((e) => e.toJson()).toList(),
        'upload_settings': uploadSettings.toJson(),
        'feelings': feelings,
        'activities': activities,
        if (expandable != null) 'expandable': expandable,
      },
      'timestamp': timestamp,
    };
  }
}
/// معلومات التطبيق الأساسية
class AppInfo {
  final String version;
  final String sngineVersion;
  final String lastUpdated;
  final String serverTime;
  const AppInfo({
    required this.version,
    required this.sngineVersion,
    required this.lastUpdated,
    required this.serverTime,
  });
  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      version: json['version']?.toString() ?? '1.0.0',
      sngineVersion: json['sngine_version']?.toString() ?? '4.0.0',
      lastUpdated: json['last_updated']?.toString() ?? '',
      serverTime: json['server_time']?.toString() ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'sngine_version': sngineVersion,
      'last_updated': lastUpdated,
      'server_time': serverTime,
    };
  }
}
/// إعدادات واجهة المستخدم
class UiSettings {
  final String appName;
  final String appDescription;
  final String? logo;
  final String? favicon;
  final String themeColor;
  final String language;
  final String timezone;
  final String dateFormat;
  final int newsfeedResults;
  final int offlineTime;
  const UiSettings({
    required this.appName,
    required this.appDescription,
    this.logo,
    this.favicon,
    required this.themeColor,
    required this.language,
    required this.timezone,
    required this.dateFormat,
    required this.newsfeedResults,
    required this.offlineTime,
  });
  factory UiSettings.fromJson(Map<String, dynamic> json) {
    return UiSettings(
      appName: json['app_name']?.toString() ?? 'Panchit',
      appDescription: json['app_description']?.toString() ?? '',
      logo: json['logo']?.toString(),
      favicon: json['favicon']?.toString(),
      themeColor: json['theme_color']?.toString() ?? '#1877f2',
      language: json['language']?.toString() ?? 'en_us',
      timezone: json['timezone']?.toString() ?? 'UTC',
      dateFormat: json['date_format']?.toString() ?? 'd/m/Y',
      newsfeedResults: int.tryParse(json['newsfeed_results']?.toString() ?? '') ?? 10,
      offlineTime: int.tryParse(json['offline_time']?.toString() ?? '') ?? 5,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'app_name': appName,
      'app_description': appDescription,
      if (logo != null) 'logo': logo,
      if (favicon != null) 'favicon': favicon,
      'theme_color': themeColor,
      'language': language,
      'timezone': timezone,
      'date_format': dateFormat,
      'newsfeed_results': newsfeedResults,
      'offline_time': offlineTime,
    };
  }
}
/// ميزات التطبيق
class Features {
  final PostsFeatures posts;
  final SocialFeatures social;
  final MonetizationFeatures monetization;
  final ContentFeatures content;
  const Features({
    required this.posts,
    required this.social,
    required this.monetization,
    required this.content,
  });
  factory Features.fromJson(Map<String, dynamic> json) {
    return Features(
      posts: PostsFeatures.fromJson(json['posts'] ?? {}),
      social: SocialFeatures.fromJson(json['social'] ?? {}),
      monetization: MonetizationFeatures.fromJson(json['monetization'] ?? {}),
      content: ContentFeatures.fromJson(json['content'] ?? {}),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'posts': posts.toJson(),
      'social': social.toJson(),
      'monetization': monetization.toJson(),
      'content': content.toJson(),
    };
  }
}
/// ميزات المنشورات
class PostsFeatures {
  final bool enabled;
  final bool coloredPosts;
  final bool polls;
  final bool feelings;
  final bool photos;
  final bool videos;
  final bool audio;
  final bool liveVideos;
  final bool stories;
  final bool schedulePosts;
  const PostsFeatures({
    required this.enabled,
    required this.coloredPosts,
    required this.polls,
    required this.feelings,
    required this.photos,
    required this.videos,
    required this.audio,
    required this.liveVideos,
    required this.stories,
    required this.schedulePosts,
  });
  factory PostsFeatures.fromJson(Map<String, dynamic> json) {
    return PostsFeatures(
      enabled: json['enabled'] == true || json['enabled']?.toString() == '1',
      coloredPosts: json['colored_posts'] == true || json['colored_posts']?.toString() == '1',
      polls: json['polls'] == true || json['polls']?.toString() == '1',
      feelings: json['feelings'] == true || json['feelings']?.toString() == '1',
      photos: json['photos'] == true || json['photos']?.toString() == '1',
      videos: json['videos'] == true || json['videos']?.toString() == '1',
      audio: json['audio'] == true || json['audio']?.toString() == '1',
      liveVideos: json['live_videos'] == true || json['live_videos']?.toString() == '1',
      stories: json['stories'] == true || json['stories']?.toString() == '1',
      schedulePosts: json['schedule_posts'] == true || json['schedule_posts']?.toString() == '1',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'colored_posts': coloredPosts,
      'polls': polls,
      'feelings': feelings,
      'photos': photos,
      'videos': videos,
      'audio': audio,
      'live_videos': liveVideos,
      'stories': stories,
      'schedule_posts': schedulePosts,
    };
  }
}
/// ميزات التواصل الاجتماعي
class SocialFeatures {
  final bool friendsEnabled;
  final bool followersEnabled;
  final bool pages;
  final bool groups;
  final bool events;
  final bool chat;
  final bool voiceCalls;
  final bool videoCalls;
  const SocialFeatures({
    required this.friendsEnabled,
    required this.followersEnabled,
    required this.pages,
    required this.groups,
    required this.events,
    required this.chat,
    required this.voiceCalls,
    required this.videoCalls,
  });
  factory SocialFeatures.fromJson(Map<String, dynamic> json) {
    return SocialFeatures(
      friendsEnabled: json['friends_enabled'] == true || json['friends_enabled']?.toString() == '1',
      followersEnabled: json['followers_enabled'] == true || json['followers_enabled']?.toString() == '1',
      pages: json['pages'] == true || json['pages']?.toString() == '1',
      groups: json['groups'] == true || json['groups']?.toString() == '1',
      events: json['events'] == true || json['events']?.toString() == '1',
      chat: json['chat'] == true || json['chat']?.toString() == '1',
      voiceCalls: json['voice_calls'] == true || json['voice_calls']?.toString() == '1',
      videoCalls: json['video_calls'] == true || json['video_calls']?.toString() == '1',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'friends_enabled': friendsEnabled,
      'followers_enabled': followersEnabled,
      'pages': pages,
      'groups': groups,
      'events': events,
      'chat': chat,
      'voice_calls': voiceCalls,
      'video_calls': videoCalls,
    };
  }
}
/// ميزات تحقيق الدخل
class MonetizationFeatures {
  final bool packages;
  final bool wallet;
  final bool points;
  final bool tips;
  final bool funding;
  final bool market;
  final bool offers;
  final bool jobs;
  const MonetizationFeatures({
    required this.packages,
    required this.wallet,
    required this.points,
    required this.tips,
    required this.funding,
    required this.market,
    required this.offers,
    required this.jobs,
  });
  factory MonetizationFeatures.fromJson(Map<String, dynamic> json) {
    return MonetizationFeatures(
      packages: json['packages'] == true || json['packages']?.toString() == '1',
      wallet: json['wallet'] == true || json['wallet']?.toString() == '1',
      points: json['points'] == true || json['points']?.toString() == '1',
      tips: json['tips'] == true || json['tips']?.toString() == '1',
      funding: json['funding'] == true || json['funding']?.toString() == '1',
      market: json['market'] == true || json['market']?.toString() == '1',
      offers: json['offers'] == true || json['offers']?.toString() == '1',
      jobs: json['jobs'] == true || json['jobs']?.toString() == '1',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'packages': packages,
      'wallet': wallet,
      'points': points,
      'tips': tips,
      'funding': funding,
      'market': market,
      'offers': offers,
      'jobs': jobs,
    };
  }
}
/// ميزات المحتوى
class ContentFeatures {
  final bool blogs;
  final bool forums;
  final bool movies;
  final bool games;
  final bool courses;
  const ContentFeatures({
    required this.blogs,
    required this.forums,
    required this.movies,
    required this.games,
    required this.courses,
  });
  factory ContentFeatures.fromJson(Map<String, dynamic> json) {
    return ContentFeatures(
      blogs: json['blogs'] == true || json['blogs']?.toString() == '1',
      forums: json['forums'] == true || json['forums']?.toString() == '1',
      movies: json['movies'] == true || json['movies']?.toString() == '1',
      games: json['games'] == true || json['games']?.toString() == '1',
      courses: json['courses'] == true || json['courses']?.toString() == '1',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'blogs': blogs,
      'forums': forums,
      'movies': movies,
      'games': games,
      'courses': courses,
    };
  }
}
/// صلاحيات المستخدم
class UserPermissions {
  final bool canCreatePages;
  final bool canCreateGroups;
  final bool canBoostPosts;
  final bool canBoostPages;
  final bool canSchedulePosts;
  final bool isVerified;
  final bool isSubscribed;
  final bool isAdult;
  const UserPermissions({
    required this.canCreatePages,
    required this.canCreateGroups,
    required this.canBoostPosts,
    required this.canBoostPages,
    required this.canSchedulePosts,
    required this.isVerified,
    required this.isSubscribed,
    required this.isAdult,
  });
  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      canCreatePages: json['can_create_pages'] == true || json['can_create_pages']?.toString() == '1',
      canCreateGroups: json['can_create_groups'] == true || json['can_create_groups']?.toString() == '1',
      canBoostPosts: json['can_boost_posts'] == true || json['can_boost_posts']?.toString() == '1',
      canBoostPages: json['can_boost_pages'] == true || json['can_boost_pages']?.toString() == '1',
      canSchedulePosts: json['can_schedule_posts'] == true || json['can_schedule_posts']?.toString() == '1',
      isVerified: json['is_verified'] == true || json['is_verified']?.toString() == '1',
      isSubscribed: json['is_subscribed'] == true || json['is_subscribed']?.toString() == '1',
      isAdult: json['is_adult'] == true || json['is_adult']?.toString() == '1',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'can_create_pages': canCreatePages,
      'can_create_groups': canCreateGroups,
      'can_boost_posts': canBoostPosts,
      'can_boost_pages': canBoostPages,
      'can_schedule_posts': canSchedulePosts,
      'is_verified': isVerified,
      'is_subscribed': isSubscribed,
      'is_adult': isAdult,
    };
  }
}