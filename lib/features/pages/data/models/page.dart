class PageModel {
  PageModel({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.picture,
    required this.cover,
    required this.category,
    required this.likes,
    required this.verified,
    required this.boosted,
    this.iAdmin = false,
    this.iLike = false,
    this.website = '',
    this.company = '',
    this.phone = '',
    this.location = '',
    this.country = '',
    this.language = '',
    this.actionText = '',
    this.actionUrl = '',
    this.actionColor = '',
    this.facebook = '',
    this.twitter = '',
    this.youtube = '',
    this.instagram = '',
    this.linkedin = '',
    this.vkontakte = '',
  });
  final int id;
  final String name;
  final String title;
  final String description;
  final String picture;
  final String cover;
  final String category;
  final int likes;
  final bool verified;
  final bool boosted;
  final bool iAdmin;
  final bool iLike;
  // Info fields
  final String website;
  final String company;
  final String phone;
  final String location;
  final String country;
  final String language;
  // Action button
  final String actionText;
  final String actionUrl;
  final String actionColor;
  // Social links
  final String facebook;
  final String twitter;
  final String youtube;
  final String instagram;
  final String linkedin;
  final String vkontakte;
  String get formattedLikes {
    if (likes >= 1000000) {
      final fixed = (likes / 1000000).toStringAsFixed(1);
      return '${_trimTrailingZero(fixed)}M';
    }
    if (likes >= 1000) {
      final fixed = (likes / 1000).toStringAsFixed(1);
      return '${_trimTrailingZero(fixed)}K';
    }
    return likes.toString();
  }
  static String _trimTrailingZero(String value) {
    return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
  }
  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: _parseInt(json['page_id']),
      name: _parseString(json['page_name']) ?? '',
      title: _parseString(json['page_title']) ?? '',
      description: _parseString(json['page_description']) ?? '',
      picture: _parseString(json['page_picture']) ?? '',
      cover: _parseString(json['page_cover']) ?? '',
      category: _parseString(json['page_category']) ?? '',
      likes: _parseInt(json['page_likes']),
      verified: _parseBool(json['page_verified']),
      boosted: _parseBool(json['page_boosted']),
      iAdmin: _parseBool(json['i_admin']),
      iLike: _parseBool(json['i_like']),
      website: _parseString(json['page_website']) ?? '',
      company: _parseString(json['page_company']) ?? '',
      phone: _parseString(json['page_phone']) ?? '',
      location: _parseString(json['page_location']) ?? '',
      country: _parseString(json['page_country']) ?? '',
      language: _parseString(json['page_language']) ?? '',
      actionText: _parseString(json['page_action_text']) ?? '',
      actionUrl: _parseString(json['page_action_url']) ?? '',
      actionColor: _parseString(json['page_action_color']) ?? '',
      facebook: _parseString(json['page_social_facebook']) ?? '',
      twitter: _parseString(json['page_social_twitter']) ?? '',
      youtube: _parseString(json['page_social_youtube']) ?? '',
      instagram: _parseString(json['page_social_instagram']) ?? '',
      linkedin: _parseString(json['page_social_linkedin']) ?? '',
      vkontakte: _parseString(json['page_social_vkontakte']) ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'page_id': id,
      'page_name': name,
      'page_title': title,
      'page_description': description,
      'page_picture': picture,
      'page_cover': cover,
      'page_category': category,
      'page_likes': likes,
      'page_verified': verified,
      'page_boosted': boosted,
      'i_admin': iAdmin,
      'i_like': iLike,
      'page_website': website,
      'page_company': company,
      'page_phone': phone,
      'page_location': location,
      'page_country': country,
      'page_language': language,
      'page_action_text': actionText,
      'page_action_url': actionUrl,
      'page_action_color': actionColor,
      'page_social_facebook': facebook,
      'page_social_twitter': twitter,
      'page_social_youtube': youtube,
      'page_social_instagram': instagram,
      'page_social_linkedin': linkedin,
      'page_social_vkontakte': vkontakte,
    };
  }
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }
}
