import 'group.dart';

/// نموذج Pagination
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;
  final bool hasMore;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
      hasMore: json['has_more'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'pages': pages,
      'has_more': hasMore,
    };
  }
}

/// استجابة قائمة المجموعات
class GroupsResponse {
  final bool success;
  final String message;
  final List<Group> groups;
  final PaginationInfo? pagination;

  GroupsResponse({
    required this.success,
    required this.message,
    required this.groups,
    this.pagination,
  });

  factory GroupsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    
    return GroupsResponse(
      success: json['status'] == 'success',
      message: json['message'] ?? '',
      groups: (data['groups'] as List<dynamic>?)
          ?.map((e) => Group.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      pagination: data['pagination'] != null 
          ? PaginationInfo.fromJson(data['pagination'])
          : null,
    );
  }
}

/// استجابة مجموعة واحدة
class GroupResponse {
  final bool success;
  final String message;
  final Group? group;

  GroupResponse({
    required this.success,
    required this.message,
    this.group,
  });

  factory GroupResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    
    return GroupResponse(
      success: json['status'] == 'success',
      message: json['message'] ?? '',
      // البيانات موجودة مباشرة في data، ليس في data.group
      group: data != null ? Group.fromJson(data) : null,
    );
  }
}

/// إحصائيات المجموعات
class GroupsStats {
  final int totalJoined;
  final int totalManaged;
  final int pendingRequests;

  GroupsStats({
    required this.totalJoined,
    required this.totalManaged,
    required this.pendingRequests,
  });

  factory GroupsStats.fromJson(Map<String, dynamic> json) {
    return GroupsStats(
      totalJoined: json['total_joined'] ?? 0,
      totalManaged: json['total_managed'] ?? 0,
      pendingRequests: json['pending_requests'] ?? 0,
    );
  }
}

/// استجابة endpoint المجمّع (all-tabs)
class GroupsOverviewResponse {
  final bool success;
  final String message;
  final List<Group> joined;
  final List<Group> managed;
  final List<Group> suggested;
  final GroupsStats stats;

  GroupsOverviewResponse({
    required this.success,
    required this.message,
    required this.joined,
    required this.managed,
    required this.suggested,
    required this.stats,
  });

  factory GroupsOverviewResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    
    return GroupsOverviewResponse(
      success: json['status'] == 'success',
      message: json['message'] ?? '',
      joined: (data['joined'] as List<dynamic>?)
          ?.map((e) => Group.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      managed: (data['managed'] as List<dynamic>?)
          ?.map((e) => Group.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      suggested: (data['suggested'] as List<dynamic>?)
          ?.map((e) => Group.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      stats: data['stats'] != null 
          ? GroupsStats.fromJson(data['stats'])
          : GroupsStats(totalJoined: 0, totalManaged: 0, pendingRequests: 0),
    );
  }
}
