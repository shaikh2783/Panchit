/// System Settings Model
/// 
/// This model represents the complete system configuration and feature flags
/// fetched from the backend. It determines which features are enabled/disabled
/// across the entire application.
/// 
/// API Endpoint: GET /data/system/settings
/// 
/// Usage:
/// ```dart
/// final settings = SystemSettings.fromJson(response['data']);
/// if (settings.socialFeatures.friendsEnabled) {
///   // Show friends functionality
/// }
/// ```

class SystemSettings {
  final SiteInfo siteInfo;
  final SocialFeatures socialFeatures;
  final ContentFeatures contentFeatures;
  final CommunityFeatures communityFeatures;
  final MonetizationFeatures monetizationFeatures;
  final CommunicationFeatures communicationFeatures;
  final SystemConfig systemSettings;
  final Limits limits;
  final Security security;

  const SystemSettings({
    required this.siteInfo,
    required this.socialFeatures,
    required this.contentFeatures,
    required this.communityFeatures,
    required this.monetizationFeatures,
    required this.communicationFeatures,
    required this.systemSettings,
    required this.limits,
    required this.security,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      siteInfo: SiteInfo.fromJson(json['site_info'] ?? {}),
      socialFeatures: SocialFeatures.fromJson(json['social_features'] ?? {}),
      contentFeatures: ContentFeatures.fromJson(json['content_features'] ?? {}),
      communityFeatures: CommunityFeatures.fromJson(json['community_features'] ?? {}),
      monetizationFeatures: MonetizationFeatures.fromJson(json['monetization_features'] ?? {}),
      communicationFeatures: CommunicationFeatures.fromJson(json['communication_features'] ?? {}),
      systemSettings: SystemConfig.fromJson(json['system_settings'] ?? {}),
      limits: Limits.fromJson(json['limits'] ?? {}),
      security: Security.fromJson(json['security'] ?? {}),
    );
  }

  /// Default system settings with all features enabled
  /// Used as fallback when API call fails
  factory SystemSettings.defaults() {
    return SystemSettings(
      siteInfo: SiteInfo.defaults(),
      socialFeatures: SocialFeatures.defaults(),
      contentFeatures: ContentFeatures.defaults(),
      communityFeatures: CommunityFeatures.defaults(),
      monetizationFeatures: MonetizationFeatures.defaults(),
      communicationFeatures: CommunicationFeatures.defaults(),
      systemSettings: SystemConfig.defaults(),
      limits: Limits.defaults(),
      security: Security.defaults(),
    );
  }
}

/// Site Information
/// Contains basic site metadata like title, logo, currency
class SiteInfo {
  final String title;
  final String description;
  final String url;
  final String logo;
  final String currency;
  final String currencySymbol;
  final String language;

  const SiteInfo({
    required this.title,
    required this.description,
    required this.url,
    required this.logo,
    required this.currency,
    required this.currencySymbol,
    required this.language,
  });

  factory SiteInfo.fromJson(Map<String, dynamic> json) {
    return SiteInfo(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      logo: json['logo'] ?? '',
      currency: json['currency'] ?? 'USD',
      currencySymbol: json['currency_symbol'] ?? '\$',
      language: json['language'] ?? 'en',
    );
  }

  factory SiteInfo.defaults() {
    return const SiteInfo(
      title: 'Social Network',
      description: '',
      url: '',
      logo: '',
      currency: 'USD',
      currencySymbol: '\$',
      language: 'en',
    );
  }
}

/// Social Features
/// Controls core social networking features like friends, followers, posts
class SocialFeatures {
  final bool friendsEnabled;
  final bool followersEnabled;
  final bool messagingEnabled;
  final bool postsEnabled;
  final bool commentsEnabled;
  final bool reactionsEnabled;
  final bool storiesEnabled;

  const SocialFeatures({
    required this.friendsEnabled,
    required this.followersEnabled,
    required this.messagingEnabled,
    required this.postsEnabled,
    required this.commentsEnabled,
    required this.reactionsEnabled,
    required this.storiesEnabled,
  });

  factory SocialFeatures.fromJson(Map<String, dynamic> json) {
    return SocialFeatures(
      friendsEnabled: json['friends_enabled'] == true,
      followersEnabled: json['followers_enabled'] == true,
      messagingEnabled: json['messaging_enabled'] == true,
      postsEnabled: json['posts_enabled'] == true,
      commentsEnabled: json['comments_enabled'] == true,
      reactionsEnabled: json['reactions_enabled'] == true,
      storiesEnabled: json['stories_enabled'] == true,
    );
  }

  factory SocialFeatures.defaults() {
    return const SocialFeatures(
      friendsEnabled: true,
      followersEnabled: true,
      messagingEnabled: true,
      postsEnabled: true,
      commentsEnabled: true,
      reactionsEnabled: true,
      storiesEnabled: true,
    );
  }
}

/// Content Features
/// Controls content types like photos, videos, blogs, pages
class ContentFeatures {
  final bool photosEnabled;
  final bool videosEnabled;
  final bool blogsEnabled;
  final bool pagesEnabled;
  final bool groupsEnabled;
  final bool eventsEnabled;

  const ContentFeatures({
    required this.photosEnabled,
    required this.videosEnabled,
    required this.blogsEnabled,
    required this.pagesEnabled,
    required this.groupsEnabled,
    required this.eventsEnabled,
  });

  factory ContentFeatures.fromJson(Map<String, dynamic> json) {
    return ContentFeatures(
      photosEnabled: json['photos_enabled'] == true,
      videosEnabled: json['videos_enabled'] == true,
      blogsEnabled: json['blogs_enabled'] == true,
      pagesEnabled: json['pages_enabled'] == true,
      groupsEnabled: json['groups_enabled'] == true,
      eventsEnabled: json['events_enabled'] == true,
    );
  }

  factory ContentFeatures.defaults() {
    return const ContentFeatures(
      photosEnabled: true,
      videosEnabled: true,
      blogsEnabled: true,
      pagesEnabled: true,
      groupsEnabled: true,
      eventsEnabled: true,
    );
  }
}

/// Community Features
/// Controls community tools like forums, marketplace, jobs
class CommunityFeatures {
  final bool forumsEnabled;
  final bool marketplaceEnabled;
  final bool jobsEnabled;
  final bool offersEnabled;
  final bool donationsEnabled;

  const CommunityFeatures({
    required this.forumsEnabled,
    required this.marketplaceEnabled,
    required this.jobsEnabled,
    required this.offersEnabled,
    required this.donationsEnabled,
  });

  factory CommunityFeatures.fromJson(Map<String, dynamic> json) {
    return CommunityFeatures(
      forumsEnabled: json['forums_enabled'] == true,
      marketplaceEnabled: json['marketplace_enabled'] == true,
      jobsEnabled: json['jobs_enabled'] == true,
      offersEnabled: json['offers_enabled'] == true,
      donationsEnabled: json['donations_enabled'] == true,
    );
  }

  factory CommunityFeatures.defaults() {
    return const CommunityFeatures(
      forumsEnabled: true,
      marketplaceEnabled: true,
      jobsEnabled: true,
      offersEnabled: true,
      donationsEnabled: true,
    );
  }
}

/// Monetization Features
/// Controls monetization tools like wallet, points, tips
class MonetizationFeatures {
  final bool walletEnabled;
  final bool pointsEnabled;
  final bool tipsEnabled;
  final bool fundingEnabled;
  final bool adsEnabled;
  final bool packagesEnabled;

  const MonetizationFeatures({
    required this.walletEnabled,
    required this.pointsEnabled,
    required this.tipsEnabled,
    required this.fundingEnabled,
    required this.adsEnabled,
    required this.packagesEnabled,
  });

  factory MonetizationFeatures.fromJson(Map<String, dynamic> json) {
    return MonetizationFeatures(
      walletEnabled: json['wallet_enabled'] == true,
      pointsEnabled: json['points_enabled'] == true,
      tipsEnabled: json['tips_enabled'] == true,
      fundingEnabled: json['funding_enabled'] == true,
      adsEnabled: json['ads_enabled'] == true,
      packagesEnabled: json['packages_enabled'] == true,
    );
  }

  factory MonetizationFeatures.defaults() {
    return const MonetizationFeatures(
      walletEnabled: true,
      pointsEnabled: true,
      tipsEnabled: true,
      fundingEnabled: true,
      adsEnabled: true,
      packagesEnabled: true,
    );
  }
}

/// Communication Features
/// Controls real-time communication features
class CommunicationFeatures {
  final bool callsEnabled;
  final bool videoCallsEnabled;
  final bool liveStreamingEnabled;

  const CommunicationFeatures({
    required this.callsEnabled,
    required this.videoCallsEnabled,
    required this.liveStreamingEnabled,
  });

  factory CommunicationFeatures.fromJson(Map<String, dynamic> json) {
    return CommunicationFeatures(
      callsEnabled: json['calls_enabled'] == true,
      videoCallsEnabled: json['video_calls_enabled'] == true,
      liveStreamingEnabled: json['live_streaming_enabled'] == true,
    );
  }

  factory CommunicationFeatures.defaults() {
    return const CommunicationFeatures(
      callsEnabled: true,
      videoCallsEnabled: true,
      liveStreamingEnabled: true,
    );
  }
}

/// System Configuration
/// Controls core system settings like registration and verification
class SystemConfig {
  final bool registrationEnabled;
  final bool verificationEnabled;
  final bool emailVerificationRequired;

  const SystemConfig({
    required this.registrationEnabled,
    required this.verificationEnabled,
    required this.emailVerificationRequired,
  });

  factory SystemConfig.fromJson(Map<String, dynamic> json) {
    return SystemConfig(
      registrationEnabled: json['registration_enabled'] == true,
      verificationEnabled: json['verification_enabled'] == true,
      emailVerificationRequired: json['email_verification_required'] == true,
    );
  }

  factory SystemConfig.defaults() {
    return const SystemConfig(
      registrationEnabled: true,
      verificationEnabled: true,
      emailVerificationRequired: false,
    );
  }
}

/// Limits
/// System limits for uploads, posts, etc.
class Limits {
  final int maxUploadSize;
  final int postsPerDay;
  final int offlineTime;

  const Limits({
    required this.maxUploadSize,
    required this.postsPerDay,
    required this.offlineTime,
  });

  factory Limits.fromJson(Map<String, dynamic> json) {
    return Limits(
      maxUploadSize: json['max_upload_size'] ?? 52428800, // 50MB default
      postsPerDay: json['posts_per_day'] ?? 0, // 0 = unlimited
      offlineTime: json['offline_time'] ?? 10, // minutes
    );
  }

  factory Limits.defaults() {
    return const Limits(
      maxUploadSize: 52428800,
      postsPerDay: 0,
      offlineTime: 10,
    );
  }
}

/// Security
/// Security-related settings
class Security {
  final bool httpsRequired;
  final bool recaptchaEnabled;

  const Security({
    required this.httpsRequired,
    required this.recaptchaEnabled,
  });

  factory Security.fromJson(Map<String, dynamic> json) {
    return Security(
      httpsRequired: json['https_required'] == true,
      recaptchaEnabled: json['recaptcha_enabled'] == true,
    );
  }

  factory Security.defaults() {
    return const Security(
      httpsRequired: false,
      recaptchaEnabled: false,
    );
  }
}
