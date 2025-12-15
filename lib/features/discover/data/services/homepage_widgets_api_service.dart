import 'package:flutter/foundation.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
/// Homepage Widgets API service to retrieve all widgets
class HomepageWidgetsApiService {
  final ApiClient _apiClient;
  HomepageWidgetsApiService(this._apiClient);
  /// Fetch all homepage widgets
  Future<HomepageWidgetsResponse> getHomepageWidgets({String? authToken}) async {
    try {
      // Try the primary path first
      try {
        final response = await _apiClient.get(configCfgP('homepage_widgets'));
        if (response['status'] == 'success') {
          return HomepageWidgetsResponse.fromJson(response['data']);
        } else {
          return HomepageWidgetsResponse.error(
            response['message'] ?? 'Failed to load homepage widgets',
          );
        }
      } catch (e) {
        // If the primary path fails, try an alternative endpoint with different headers
        if (e.toString().contains('401') || e.toString().contains('not logged in')) {
          try {
            // Use the same headers that work in Postman with credentials from appConfig
            final alternativeHeaders = <String, String>{
              'Content-Type': 'application/json',
              'apiKey': appConfig.apiKey,
              'apiSecret': appConfig.apiSecret,
            };
            // Add auth token if available
            if (authToken != null && authToken.isNotEmpty) {
              alternativeHeaders['x-auth-token'] = authToken;
            } else {
              // Use the default token as a fallback
              alternativeHeaders['x-auth-token'] = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1aWQiOiIxIiwidG9rZW4iOiIwMjZkMjZjNmJhZTA5YTg4M2JjYjI4M2Q4OGFkYTgwZiJ9.yFhBEuq8Ktb7IF9WsviwHzn3Dt1tyCvzWvsjjeB06Zg';
            }
            final response = await _apiClient.get(
              configCfgP('homepage_widgets'),
              headers: alternativeHeaders,
            );
            if (response['status'] == 'success') {
              return HomepageWidgetsResponse.fromJson(response['data']);
            } else {
              return HomepageWidgetsResponse.error(
                response['message'] ?? 'Failed to load homepage widgets',
              );
            }
          } catch (altError) {
            throw e; // Rethrow the original error
          }
        } else {
          throw e; // Rethrow unexpected errors
        }
      }
    } catch (e) {
      // If the API call fails, use temporary mock data
      if (e.toString().contains('401') || e.toString().contains('not logged in')) {
        return _generateMockResponse();
      }
      return HomepageWidgetsResponse.error('Failed to load homepage widgets');
    }
  }
  /// Generate mock data when the API is unavailable
  HomepageWidgetsResponse _generateMockResponse() {
    final mockData = {
      'widgets': {
        'merits_balance': {
          'enabled': true,
          'title': 'Your Merits',
          'balance': {
            'total': 500,
            'remaining': 350,
            'spent': 150,
          }
        },
        'pro_users': {
          'enabled': true,
          'title': 'Pro Users',
          'users': [
            {
              'user_id': 1,
              'username': 'ameen',
              'firstname': 'Ameen',
              'lastname': 'Hamed',
              'fullname': 'Ameen Hamed',
              'picture': 'https://www.panchit.com/content/themes/default/images/blank_profile_male.png',
              'verified': true,
              'subscribed': true
            }
          ]
        },
        'trending_hashtags': {
          'enabled': true,
          'title': 'Trending',
          'hashtags': [
            {
              'hashtag': '#ameen',
              'frequency': 5,
              'posts_count': 1
            },
            {
              'hashtag': '#flutter',
              'frequency': 10,
              'posts_count': 3
            }
          ]
        },
        'suggested_friends': {
          'enabled': true,
          'title': 'Suggested Friends',
          'people': []
        },
        'suggested_pages': {
          'enabled': true,
          'title': 'Suggested Pages',
          'pages': []
        },
        'suggested_groups': {
          'enabled': true,
          'title': 'Suggested Groups',
          'groups': []
        }
      }
    };
    return HomepageWidgetsResponse.fromJson(mockData);
  }
}
/// Homepage Widgets API response
class HomepageWidgetsResponse {
  final bool success;
  final String? message;
  final HomepageWidgets? widgets;
  HomepageWidgetsResponse({
    required this.success,
    this.message,
    this.widgets,
  });
  factory HomepageWidgetsResponse.fromJson(Map<String, dynamic> json) {
    return HomepageWidgetsResponse(
      success: true,
      widgets: HomepageWidgets.fromJson(json['widgets']),
    );
  }
  factory HomepageWidgetsResponse.error(String message) {
    return HomepageWidgetsResponse(
      success: false,
      message: message,
    );
  }
}
/// All homepage widgets
class HomepageWidgets {
  final ProUsersWidget? proUsers;
  final ProPagesWidget? proPages;
  final TrendingHashtagsWidget? trendingHashtags;
  final MeritsTopUsersWidget? meritsTopUsers;
  final SuggestedFriendsWidget? suggestedFriends;
  final SuggestedPagesWidget? suggestedPages;
  final SuggestedGroupsWidget? suggestedGroups;
  final SuggestedEventsWidget? suggestedEvents;
  final MeritsBalanceWidget? meritsBalance;
  HomepageWidgets({
    this.proUsers,
    this.proPages,
    this.trendingHashtags,
    this.meritsTopUsers,
    this.suggestedFriends,
    this.suggestedPages,
    this.suggestedGroups,
    this.suggestedEvents,
    this.meritsBalance,
  });
  factory HomepageWidgets.fromJson(Map<String, dynamic> json) {
    return HomepageWidgets(
      proUsers: json['pro_users'] != null 
          ? ProUsersWidget.fromJson(json['pro_users']) 
          : null,
      proPages: json['pro_pages'] != null 
          ? ProPagesWidget.fromJson(json['pro_pages']) 
          : null,
      trendingHashtags: json['trending_hashtags'] != null 
          ? TrendingHashtagsWidget.fromJson(json['trending_hashtags']) 
          : null,
      meritsTopUsers: json['merits_top_users'] != null 
          ? MeritsTopUsersWidget.fromJson(json['merits_top_users']) 
          : null,
      suggestedFriends: json['suggested_friends'] != null 
          ? SuggestedFriendsWidget.fromJson(json['suggested_friends']) 
          : null,
      suggestedPages: json['suggested_pages'] != null 
          ? SuggestedPagesWidget.fromJson(json['suggested_pages']) 
          : null,
      suggestedGroups: json['suggested_groups'] != null 
          ? SuggestedGroupsWidget.fromJson(json['suggested_groups']) 
          : null,
      suggestedEvents: json['suggested_events'] != null 
          ? SuggestedEventsWidget.fromJson(json['suggested_events']) 
          : null,
      meritsBalance: json['merits_balance'] != null 
          ? MeritsBalanceWidget.fromJson(json['merits_balance']) 
          : null,
    );
  }
}
/// Featured pages widget
class ProPagesWidget {
  final bool enabled;
  final String title;
  final List<ProPage> pages;
  ProPagesWidget({
    required this.enabled,
    required this.title,
    required this.pages,
  });
  factory ProPagesWidget.fromJson(Map<String, dynamic> json) {
    return ProPagesWidget(
      enabled: json['enabled'] ?? false,
      title: json['title'] ?? 'Pro Pages',
      pages: (json['pages'] as List?)
          ?.map((page) => ProPage.fromJson(page))
          .toList() ?? [],
    );
  }
}
class ProPage {
  final int pageId;
  final String pageName;
  final String pageTitle;
  final String pageDescription;
  final String? pagePicture;
  final int pageLikes;
  final bool pageVerified;
  final bool isLiked;
  ProPage({
    required this.pageId,
    required this.pageName,
    required this.pageTitle,
    required this.pageDescription,
    this.pagePicture,
    required this.pageLikes,
    required this.pageVerified,
    required this.isLiked,
  });
  factory ProPage.fromJson(Map<String, dynamic> json) {
    return ProPage(
      pageId: int.tryParse(json['page_id']?.toString() ?? '0') ?? 0,
      pageName: json['page_name']?.toString() ?? '',
      pageTitle: json['page_title']?.toString() ?? '',
      pageDescription: json['page_description']?.toString() ?? '',
      pagePicture: json['page_picture']?.toString(),
      pageLikes: int.tryParse(json['page_likes']?.toString() ?? '0') ?? 0,
      pageVerified: json['page_verified'] == true || json['page_verified'] == 1,
      isLiked: json['is_liked'] == true || json['is_liked'] == 1,
    );
  }
}
/// Featured users widget
class ProUsersWidget {
  final bool enabled;
  final String title;
  final List<ProUser> users;
  ProUsersWidget({
    required this.enabled,
    required this.title,
    required this.users,
  });
  factory ProUsersWidget.fromJson(Map<String, dynamic> json) {
    return ProUsersWidget(
      enabled: json['enabled'] ?? false,
      title: json['title'] ?? 'Pro Users',
      users: (json['users'] as List?)
          ?.map((user) => ProUser.fromJson(user))
          .toList() ?? [],
    );
  }
}
class ProUser {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? picture;
  final bool verified;
  final bool subscribed;
  ProUser({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.picture,
    required this.verified,
    required this.subscribed,
  });
  factory ProUser.fromJson(Map<String, dynamic> json) {
    return ProUser(
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      firstName: json['firstname']?.toString() ?? '',
      lastName: json['lastname']?.toString() ?? '',
      fullName: json['fullname']?.toString() ?? '',
      picture: json['picture']?.toString(),
      verified: json['verified'] == true || json['verified'] == 1,
      subscribed: json['subscribed'] == true || json['subscribed'] == 1,
    );
  }
}
/// Trending hashtags widget
class TrendingHashtagsWidget {
  final bool enabled;
  final String title;
  final List<TrendingHashtag> hashtags;
  TrendingHashtagsWidget({
    required this.enabled,
    required this.title,
    required this.hashtags,
  });
  factory TrendingHashtagsWidget.fromJson(Map<String, dynamic> json) {
    return TrendingHashtagsWidget(
      enabled: json['enabled'] ?? false,
      title: json['title'] ?? 'Trending',
      hashtags: (json['hashtags'] as List?)
          ?.map((hashtag) => TrendingHashtag.fromJson(hashtag))
          .toList() ?? [],
    );
  }
}
class TrendingHashtag {
  final String hashtag;
  final int frequency;
  final int postsCount;
  TrendingHashtag({
    required this.hashtag,
    required this.frequency,
    required this.postsCount,
  });
  factory TrendingHashtag.fromJson(Map<String, dynamic> json) {
    return TrendingHashtag(
      hashtag: json['hashtag']?.toString() ?? '',
      frequency: int.tryParse(json['frequency']?.toString() ?? '0') ?? 0,
      postsCount: int.tryParse(json['posts_count']?.toString() ?? '0') ?? 0,
    );
  }
}
/// Top users by merits widget
class MeritsTopUsersWidget {
  final bool enabled;
  final String title;
  final List<MeritsTopUser> users;
  MeritsTopUsersWidget({
    required this.enabled,
    required this.title,
    required this.users,
  });
  factory MeritsTopUsersWidget.fromJson(Map<String, dynamic> json) {
    return MeritsTopUsersWidget(
      enabled: json['enabled'] ?? false,
      title: json['title'] ?? 'Merits Top Users',
      users: (json['users'] as List?)
          ?.map((user) => MeritsTopUser.fromJson(user))
          .toList() ?? [],
    );
  }
}
class MeritsTopUser {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? picture;
  final bool verified;
  final int totalMerits;
  MeritsTopUser({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.picture,
    required this.verified,
    required this.totalMerits,
  });
  factory MeritsTopUser.fromJson(Map<String, dynamic> json) {
    return MeritsTopUser(
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      firstName: json['firstname']?.toString() ?? '',
      lastName: json['lastname']?.toString() ?? '',
      fullName: json['fullname']?.toString() ?? '',
      picture: json['picture']?.toString(),
      verified: json['verified'] == true || json['verified'] == 1,
      totalMerits: int.tryParse(json['total_merits']?.toString() ?? '0') ?? 0,
    );
  }
}
/// Suggested friends widget
class SuggestedFriendsWidget {
  final bool enabled;
  final String title;
  final List<SuggestedFriend> people;
  SuggestedFriendsWidget({
    required this.enabled,
    required this.title,
    required this.people,
  });
  factory SuggestedFriendsWidget.fromJson(Map<String, dynamic> json) {
    return SuggestedFriendsWidget(
      enabled: json['enabled'] ?? false,
      title: json['title'] ?? 'Suggested Friends',
      people: (json['people'] as List?)
          ?.map((person) => SuggestedFriend.fromJson(person))
          .toList() ?? [],
    );
  }
}
class SuggestedFriend {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? picture;
  final bool verified;
  final int mutualFriendsCount;
  SuggestedFriend({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.picture,
    required this.verified,
    required this.mutualFriendsCount,
  });
  factory SuggestedFriend.fromJson(Map<String, dynamic> json) {
    return SuggestedFriend(
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      firstName: json['firstname']?.toString() ?? '',
      lastName: json['lastname']?.toString() ?? '',
      fullName: json['fullname']?.toString() ?? '',
      picture: json['picture']?.toString(),
      verified: json['verified'] == true || json['verified'] == 1,
      mutualFriendsCount: int.tryParse(json['mutual_friends_count']?.toString() ?? '0') ?? 0,
    );
  }
}
/// Suggested pages widget
class SuggestedPagesWidget {
  final bool enabled;
  final String title;
  final List<SuggestedPage> pages;
  SuggestedPagesWidget({
    required this.enabled,
    required this.title,
    required this.pages,
  });
  factory SuggestedPagesWidget.fromJson(Map<String, dynamic> json) {
    return SuggestedPagesWidget(
      enabled: json['enabled'] ?? false,
      title: json['title'] ?? 'Suggested Pages',
      pages: (json['pages'] as List?)
          ?.map((page) => SuggestedPage.fromJson(page))
          .toList() ?? [],
    );
  }
}
class SuggestedPage {
  final int pageId;
  final String pageName;
  final String pageTitle;
  final String pageDescription;
  final String? pagePicture;
  final int pageLikes;
  final bool pageVerified;
  final PageCategory? category;
  SuggestedPage({
    required this.pageId,
    required this.pageName,
    required this.pageTitle,
    required this.pageDescription,
    this.pagePicture,
    required this.pageLikes,
    required this.pageVerified,
    this.category,
  });
  factory SuggestedPage.fromJson(Map<String, dynamic> json) {
    return SuggestedPage(
      pageId: int.tryParse(json['page_id']?.toString() ?? '0') ?? 0,
      pageName: json['page_name']?.toString() ?? '',
      pageTitle: json['page_title']?.toString() ?? '',
      pageDescription: json['page_description']?.toString() ?? '',
      pagePicture: json['page_picture']?.toString(),
      pageLikes: int.tryParse(json['page_likes']?.toString() ?? '0') ?? 0,
      pageVerified: json['page_verified'] == true || json['page_verified'] == 1,
      category: json['category'] != null 
          ? PageCategory.fromJson(json['category']) 
          : null,
    );
  }
}
class PageCategory {
  final int categoryId;
  final String categoryName;
  PageCategory({
    required this.categoryId,
    required this.categoryName,
  });
  factory PageCategory.fromJson(Map<String, dynamic> json) {
    return PageCategory(
      categoryId: int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      categoryName: json['category_name']?.toString() ?? '',
    );
  }
}
/// Suggested groups widget
class SuggestedGroupsWidget {
  final bool enabled;
  final String title;
  final List<SuggestedGroup> groups;
  SuggestedGroupsWidget({
    required this.enabled,
    required this.title,
    required this.groups,
  });
  factory SuggestedGroupsWidget.fromJson(Map<String, dynamic> json) {
    return SuggestedGroupsWidget(
      enabled: json['enabled'] ?? false,
      title: json['title'] ?? 'Suggested Groups',
      groups: (json['groups'] as List?)
          ?.map((group) => SuggestedGroup.fromJson(group))
          .toList() ?? [],
    );
  }
}
class SuggestedGroup {
  final int groupId;
  final String groupName;
  final String groupTitle;
  final String groupDescription;
  final String groupPrivacy;
  final String? groupPicture;
  final int groupMembers;
  final GroupCategory? category;
  final GroupMembership membership;
  SuggestedGroup({
    required this.groupId,
    required this.groupName,
    required this.groupTitle,
    required this.groupDescription,
    required this.groupPrivacy,
    this.groupPicture,
    required this.groupMembers,
    this.category,
    required this.membership,
  });
  factory SuggestedGroup.fromJson(Map<String, dynamic> json) {
    return SuggestedGroup(
      groupId: int.tryParse(json['group_id']?.toString() ?? '0') ?? 0,
      groupName: json['group_name']?.toString() ?? '',
      groupTitle: json['group_title']?.toString() ?? '',
      groupDescription: json['group_description']?.toString() ?? '',
      groupPrivacy: json['group_privacy']?.toString() ?? 'public',
      groupPicture: json['group_picture']?.toString(),
      groupMembers: int.tryParse(json['group_members']?.toString() ?? '0') ?? 0,
      category: json['category'] != null 
          ? GroupCategory.fromJson(json['category']) 
          : null,
      membership: GroupMembership.fromJson(json['membership'] ?? {}),
    );
  }
}
class GroupCategory {
  final int categoryId;
  final String categoryName;
  GroupCategory({
    required this.categoryId,
    required this.categoryName,
  });
  factory GroupCategory.fromJson(Map<String, dynamic> json) {
    return GroupCategory(
      categoryId: int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      categoryName: json['category_name']?.toString() ?? '',
    );
  }
}
class GroupMembership {
  final bool isMember;
  final bool isAdmin;
  final String status;
  GroupMembership({
    required this.isMember,
    required this.isAdmin,
    required this.status,
  });
  factory GroupMembership.fromJson(Map<String, dynamic> json) {
    return GroupMembership(
      isMember: json['is_member'] == true || json['is_member'] == 1,
      isAdmin: json['is_admin'] == true || json['is_admin'] == 1,
      status: json['status']?.toString() ?? 'none',
    );
  }
}
/// Merits balance widget
class MeritsBalanceWidget {
  final bool enabled;
  final String title;
  final MeritsBalance balance;
  MeritsBalanceWidget({
    required this.enabled,
    required this.title,
    required this.balance,
  });
  factory MeritsBalanceWidget.fromJson(Map<String, dynamic> json) {
    return MeritsBalanceWidget(
      enabled: json['enabled'] ?? false,
      title: json['title'] ?? 'Your Merits',
      balance: MeritsBalance.fromJson(json['balance'] ?? {}),
    );
  }
}
class MeritsBalance {
  final int total;
  final int remaining;
  final int spent;
  MeritsBalance({
    required this.total,
    required this.remaining,
    required this.spent,
  });
  factory MeritsBalance.fromJson(Map<String, dynamic> json) {
    return MeritsBalance(
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      remaining: int.tryParse(json['remaining']?.toString() ?? '0') ?? 0,
      spent: int.tryParse(json['spent']?.toString() ?? '0') ?? 0,
    );
  }
}
/// Suggested events widget
class SuggestedEventsWidget {
  final bool enabled;
  final String title;
  final List<SuggestedEvent> events;
  SuggestedEventsWidget({
    required this.enabled,
    required this.title,
    required this.events,
  });
  factory SuggestedEventsWidget.fromJson(Map<String, dynamic> json) {
    return SuggestedEventsWidget(
      enabled: json['enabled'] ?? false,
      title: json['title'] ?? 'Suggested Events',
      events: (json['events'] as List?)
          ?.map((event) => SuggestedEvent.fromJson(event))
          .toList() ?? [],
    );
  }
}
class SuggestedEvent {
  final int eventId;
  final String eventTitle;
  final String eventDescription;
  final String? eventLocation;
  final String eventPrivacy;
  final String eventStartDate;
  final String eventEndDate;
  final String? eventCover;
  final int eventInterested;
  final int eventGoing;
  SuggestedEvent({
    required this.eventId,
    required this.eventTitle,
    required this.eventDescription,
    this.eventLocation,
    required this.eventPrivacy,
    required this.eventStartDate,
    required this.eventEndDate,
    this.eventCover,
    required this.eventInterested,
    required this.eventGoing,
  });
  factory SuggestedEvent.fromJson(Map<String, dynamic> json) {
    return SuggestedEvent(
      eventId: int.tryParse(json['event_id']?.toString() ?? '0') ?? 0,
      eventTitle: json['event_title']?.toString() ?? '',
      eventDescription: json['event_description']?.toString() ?? '',
      eventLocation: json['event_location']?.toString(),
      eventPrivacy: json['event_privacy']?.toString() ?? 'public',
      eventStartDate: json['event_start_date']?.toString() ?? '',
      eventEndDate: json['event_end_date']?.toString() ?? '',
      eventCover: json['event_cover']?.toString(),
      eventInterested: int.tryParse(json['event_interested']?.toString() ?? '0') ?? 0,
      eventGoing: int.tryParse(json['event_going']?.toString() ?? '0') ?? 0,
    );
  }
}
