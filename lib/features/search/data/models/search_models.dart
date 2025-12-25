/// نماذج البحث لجميع أنواع النتائج

/// نتيجة البحث العامة
abstract class SearchResult {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final bool verified;

  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.verified = false,
  });
}

/// نتيجة البحث للمستخدمين
class SearchUser extends SearchResult {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? profilePicture;
  final bool isVerified;
  final bool isSubscribed;
  final String connectionStatus; // "none", "friends", "pending", etc.
  final int mutualFriendsCount;

  const SearchUser({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.profilePicture,
    required this.isVerified,
    required this.isSubscribed,
    required this.connectionStatus,
    required this.mutualFriendsCount,
  }) : super(
          id: username,
          type: 'user',
          title: fullName,
          subtitle: '@$username',
          imageUrl: profilePicture,
          verified: isVerified,
        );

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    final firstName = json['user_firstname']?.toString() ?? '';
    final lastName = json['user_lastname']?.toString() ?? '';
    final fullName = json['name']?.toString() ?? '$firstName $lastName'.trim();
    
    return SearchUser(
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      username: json['user_name']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      fullName: fullName.isNotEmpty ? fullName : '@${json['user_name'] ?? ''}',
      profilePicture: json['user_picture']?.toString(),
      isVerified: json['user_verified'] == true || json['user_verified'] == 1,
      isSubscribed: json['user_subscribed'] == true || json['user_subscribed'] == 1,
      connectionStatus: json['connection']?.toString() ?? 'none',
      mutualFriendsCount: int.tryParse(json['mutual_friends_count']?.toString() ?? '0') ?? 0,
    );
  }
}

/// نتيجة البحث للصفحات
class SearchPageResult extends SearchResult {
  final int pageId;
  final String pageName;
  final String pageTitle;
  final String pageDescription;
  final String? pagePicture;
  final String? pageCover;
  final int pageCategory;
  final int pageLikes;
  final bool isVerified;
  final bool isBoosted;
  final bool iLiked;

  SearchPageResult({
    required this.pageId,
    required this.pageName,
    required this.pageTitle,
    required this.pageDescription,
    this.pagePicture,
    this.pageCover,
    required this.pageCategory,
    required this.pageLikes,
    required this.isVerified,
    required this.isBoosted,
    required this.iLiked,
  }) : super(
          id: pageId.toString(),
          type: 'page',
          title: pageTitle,
          subtitle: pageDescription.length > 100 
            ? '${pageDescription.substring(0, 100)}...' 
            : pageDescription,
          imageUrl: pagePicture,
          verified: isVerified,
        );

  factory SearchPageResult.fromJson(Map<String, dynamic> json) {
    return SearchPageResult(
      pageId: int.tryParse(json['page_id']?.toString() ?? '0') ?? 0,
      pageName: json['page_name']?.toString() ?? '',
      pageTitle: json['page_title']?.toString() ?? '',
      pageDescription: json['page_description']?.toString() ?? '',
      pagePicture: json['page_picture']?.toString(),
      pageCover: json['page_cover']?.toString(),
      pageCategory: int.tryParse(json['page_category']?.toString() ?? '0') ?? 0,
      pageLikes: int.tryParse(json['page_likes']?.toString() ?? '0') ?? 0,
      isVerified: json['page_verified'] == true || json['page_verified'] == 1,
      isBoosted: json['page_boosted'] == true || json['page_boosted'] == 1,
      iLiked: json['i_like'] == true || json['i_like'] == 1,
    );
  }
}

/// نتيجة البحث للمجموعات
class SearchGroup extends SearchResult {
  final int groupId;
  final String groupName;
  final String groupTitle;
  final String groupDescription;
  final String? groupPicture;
  final String? groupCover;
  final int groupCategory;
  final int groupMembers;
  final String groupPrivacy; // "public", "closed", "secret"
  final bool iJoined;

  SearchGroup({
    required this.groupId,
    required this.groupName,
    required this.groupTitle,
    required this.groupDescription,
    this.groupPicture,
    this.groupCover,
    required this.groupCategory,
    required this.groupMembers,
    required this.groupPrivacy,
    required this.iJoined,
  }) : super(
          id: groupId.toString(),
          type: 'group',
          title: groupTitle,
          subtitle: groupDescription.length > 100 
            ? '${groupDescription.substring(0, 100)}...' 
            : groupDescription,
          imageUrl: groupPicture,
          verified: false,
        );

  factory SearchGroup.fromJson(Map<String, dynamic> json) {
    return SearchGroup(
      groupId: int.tryParse(json['group_id']?.toString() ?? '0') ?? 0,
      groupName: json['group_name']?.toString() ?? '',
      groupTitle: json['group_title']?.toString() ?? '',
      groupDescription: json['group_description']?.toString() ?? '',
      groupPicture: json['group_picture']?.toString(),
      groupCover: json['group_cover']?.toString(),
      groupCategory: int.tryParse(json['group_category']?.toString() ?? '0') ?? 0,
      groupMembers: int.tryParse(json['group_members']?.toString() ?? '0') ?? 0,
      groupPrivacy: json['group_privacy']?.toString() ?? 'public',
      iJoined: json['i_joined'] == true || json['i_joined'] == 1,
    );
  }
}

/// نتيجة البحث للفعاليات
class SearchEvent extends SearchResult {
  final int eventId;
  final String eventTitle;
  final String eventDescription;
  final String? eventCover;
  final String eventLocation;
  final String eventStart;
  final String eventEnd;
  final int eventCategory;
  final String eventPrivacy;
  final bool iGoing;

  SearchEvent({
    required this.eventId,
    required this.eventTitle,
    required this.eventDescription,
    this.eventCover,
    required this.eventLocation,
    required this.eventStart,
    required this.eventEnd,
    required this.eventCategory,
    required this.eventPrivacy,
    required this.iGoing,
  }) : super(
          id: eventId.toString(),
          type: 'event',
          title: eventTitle,
          subtitle: eventLocation.isNotEmpty ? eventLocation : eventDescription,
          imageUrl: eventCover,
          verified: false,
        );

  factory SearchEvent.fromJson(Map<String, dynamic> json) {
    return SearchEvent(
      eventId: int.tryParse(json['event_id']?.toString() ?? '0') ?? 0,
      eventTitle: json['event_title']?.toString() ?? '',
      eventDescription: json['event_description']?.toString() ?? '',
      eventCover: json['event_cover']?.toString(),
      eventLocation: json['event_location']?.toString() ?? '',
      eventStart: json['event_start']?.toString() ?? '',
      eventEnd: json['event_end']?.toString() ?? '',
      eventCategory: int.tryParse(json['event_category']?.toString() ?? '0') ?? 0,
      eventPrivacy: json['event_privacy']?.toString() ?? 'public',
      iGoing: json['i_going'] == true || json['i_going'] == 1,
    );
  }
}

/// Factory لتحويل JSON إلى النوع المناسب حسب tab
class SearchResultFactory {
  static List<SearchResult> fromJsonList(List<Map<String, dynamic>> results, String tab) {
    switch (tab.toLowerCase()) {
      case 'users':
        return results.map((json) => SearchUser.fromJson(json)).toList();
      case 'pages':
        return results.map((json) => SearchPageResult.fromJson(json)).toList();
      case 'groups':
        return results.map((json) => SearchGroup.fromJson(json)).toList();
      case 'events':
        return results.map((json) => SearchEvent.fromJson(json)).toList();
      case 'posts':
      case 'blogs':
      default:
        // للمنشورات والمدونات سنبقي البيانات كما هي لأننا سنستخدم PostCard
        return [];
    }
  }
}

/// أنواع البحث المتاحة
enum SearchType {
  posts('posts', 'Posts', 'المنشورات'),
  users('users', 'Users', 'المستخدمين'), 
  pages('pages', 'Pages', 'الصفحات'),
  groups('groups', 'Groups', 'المجموعات'),
  events('events', 'Events', 'الفعاليات'),
  blogs('blogs', 'Blogs', 'المدونات');

  const SearchType(this.key, this.title, this.titleAr);
  
  final String key;
  final String title;
  final String titleAr;

  static SearchType fromString(String value) {
    for (SearchType type in SearchType.values) {
      if (type.key == value.toLowerCase()) {
        return type;
      }
    }
    return SearchType.posts;
  }
}
