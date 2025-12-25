class Country {
  final int id;
  final String name;
  final String code;

  Country({
    required this.id,
    required this.name,
    required this.code,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }
}

class WorkInfo {
  final String? title;
  final String? place;
  final String? website;

  WorkInfo({this.title, this.place, this.website});

  factory WorkInfo.fromJson(Map<String, dynamic> json) {
    return WorkInfo(
      title: json['title'],
      place: json['place'],
      website: json['website'],
    );
  }

  bool get isEmpty => title == null && place == null && website == null;
}

class LocationInfo {
  final String? currentCity;
  final String? hometown;

  LocationInfo({this.currentCity, this.hometown});

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      currentCity: json['current_city'],
      hometown: json['hometown'],
    );
  }

  bool get isEmpty => currentCity == null && hometown == null;
}

class EducationInfo {
  final String? school;
  final String? major;
  final String? classYear;

  EducationInfo({this.school, this.major, this.classYear});

  factory EducationInfo.fromJson(Map<String, dynamic> json) {
    return EducationInfo(
      school: json['school'],
      major: json['major'],
      classYear: json['class'],
    );
  }

  bool get isEmpty => school == null && major == null && classYear == null;
}

class SocialLinks {
  final String? website;
  final String? facebook;
  final String? x;
  final String? youtube;
  final String? instagram;
  final String? twitch;
  final String? linkedin;
  final String? vkontakte;

  SocialLinks({
    this.website,
    this.facebook,
    this.x,
    this.youtube,
    this.instagram,
    this.twitch,
    this.linkedin,
    this.vkontakte,
  });

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      website: json['website'],
      facebook: json['facebook'],
      x: json['x'],
      youtube: json['youtube'],
      instagram: json['instagram'],
      twitch: json['twitch'],
      linkedin: json['linkedin'],
      vkontakte: json['vkontakte'],
    );
  }

  bool get isEmpty =>
      website == null &&
      facebook == null &&
      x == null &&
      youtube == null &&
      instagram == null &&
      twitch == null &&
      linkedin == null &&
      vkontakte == null;
}

class UserProfile {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String gender;
  final String picture;
  final String? cover;
  final bool isVerified;
  final bool isSubscribed;
  final bool? isOnline;
  final String? lastSeen;
  final String? birthDate;
  final Country? country;
  final String? about;
  final String? website;
  final String? relationship;
  final WorkInfo work;
  final LocationInfo location;
  final EducationInfo education;
  final SocialLinks socialLinks;

  UserProfile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.gender,
    required this.picture,
    this.cover,
    required this.isVerified,
    required this.isSubscribed,
    this.isOnline,
    this.lastSeen,
    this.birthDate,
    this.country,
    this.about,
    this.website,
    this.relationship,
    required this.work,
    required this.location,
    required this.education,
    required this.socialLinks,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] ?? json;
    return UserProfile(
      id: profile['id']?.toString() ?? '',
      username: profile['username'] ?? '',
      firstName: profile['first_name'] ?? '',
      lastName: profile['last_name'] ?? '',
      fullName: profile['full_name'] ?? '',
      gender: profile['gender'] ?? 'male',
      picture: profile['picture'] ?? '',
      cover: profile['cover'],
      isVerified: profile['is_verified'] == true,
      isSubscribed: profile['is_subscribed'] == true,
      isOnline: profile['is_online'],
      lastSeen: profile['last_seen'],
      birthDate: profile['birth_date'],
      country: profile['country'] != null
          ? Country.fromJson(profile['country'])
          : null,
      about: profile['about'],
      website: profile['website'],
      relationship: profile['relationship_status'],
      work: WorkInfo.fromJson(profile['work'] ?? {}),
      location: LocationInfo.fromJson(profile['location'] ?? {}),
      education: EducationInfo.fromJson(profile['education'] ?? {}),
      socialLinks: SocialLinks.fromJson(profile['social_links'] ?? {}),
    );
  }
}

class ProfileStats {
  final int friends;
  final int followers;
  final int followings;
  final int posts;
  final int photos;
  final int videos;

  ProfileStats({
    required this.friends,
    required this.followers,
    required this.followings,
    required this.posts,
    required this.photos,
    required this.videos,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      friends: json['friends'] ?? 0,
      followers: json['followers'] ?? 0,
      followings: json['followings'] ?? 0,
      posts: json['posts'] ?? 0,
      photos: json['photos'] ?? 0,
      videos: json['videos'] ?? 0,
    );
  }
}

class ProfileRelationship {
  final bool isSelf;
  final String connection;
  final bool isFollowing;
  final bool isFollowedBy;

  ProfileRelationship({
    required this.isSelf,
    required this.connection,
    required this.isFollowing,
    required this.isFollowedBy,
  });

  factory ProfileRelationship.fromJson(Map<String, dynamic> json) {
    return ProfileRelationship(
      isSelf: json['is_self'] == true,
      connection: json['connection'] ?? 'add',
      isFollowing: json['is_following'] == true,
      isFollowedBy: json['is_followed_by'] == true,
    );
  }

  bool get isFriend => connection == 'friend';
  bool get canAddFriend => connection == 'add';
  bool get hasPendingRequest => connection == 'request';
  bool get canCancelRequest => connection == 'cancel';
  bool get isBlocked => connection == 'block';
}

class Address {
  final int id;
  final String title;
  final String country;
  final String city;
  final String zipCode;
  final String phone;
  final String details;

  Address({
    required this.id,
    required this.title,
    required this.country,
    required this.city,
    required this.zipCode,
    required this.phone,
    required this.details,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      zipCode: json['zip_code'] ?? '',
      phone: json['phone'] ?? '',
      details: json['details'] ?? '',
    );
  }
}

class UserProfileResponse {
  final UserProfile profile;
  final ProfileStats stats;
  final ProfileRelationship relationship;
  final Map<String, dynamic> privacy;
  final List<Address> addresses;
  final Map<String, String?> socialLinks;

  UserProfileResponse({
    required this.profile,
    required this.stats,
    required this.relationship,
    required this.privacy,
    required this.addresses,
    required this.socialLinks,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return UserProfileResponse(
      profile: UserProfile.fromJson(data),
      stats: ProfileStats.fromJson(data['stats'] ?? {}),
      relationship: ProfileRelationship.fromJson(data['relationship'] ?? {}),
      privacy: Map<String, dynamic>.from(data['privacy'] ?? {}),
      addresses: (data['addresses'] as List?)
              ?.map((a) => Address.fromJson(a))
              .toList() ??
          [],
      socialLinks: Map<String, String?>.from(data['social_links'] ?? {}),
    );
  }
}
