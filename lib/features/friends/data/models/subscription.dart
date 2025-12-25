class Subscription {
  final int planId;
  final String nodeType;

  // For profile subscriptions
  final int? userId;
  final String? userName;
  final String? name;
  final String? userPicture;
  final bool? isVerified;

  // For page subscriptions
  final int? pageId;
  final String? pageName;
  final String? pageTitle;
  final String? pagePicture;
  final bool? pageVerified;

  // For group subscriptions
  final int? groupId;
  final String? groupName;
  final String? groupTitle;
  final String? groupPicture;

  Subscription({
    required this.planId,
    required this.nodeType,
    this.userId,
    this.userName,
    this.name,
    this.userPicture,
    this.isVerified,
    this.pageId,
    this.pageName,
    this.pageTitle,
    this.pagePicture,
    this.pageVerified,
    this.groupId,
    this.groupName,
    this.groupTitle,
    this.groupPicture,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      planId: json['plan_id'] ?? 0,
      nodeType: json['node_type'] ?? '',
      userId: json['user_id'],
      userName: json['user_name'],
      name: json['name'],
      userPicture: json['user_picture'],
      isVerified: json['user_verified'],
      pageId: json['page_id'],
      pageName: json['page_name'],
      pageTitle: json['page_title'],
      pagePicture: json['page_picture'],
      pageVerified: json['page_verified'],
      groupId: json['group_id'],
      groupName: json['group_name'],
      groupTitle: json['group_title'],
      groupPicture: json['group_picture'],
    );
  }

  /// Get display name based on subscription type
  String get displayName {
    switch (nodeType) {
      case 'profile':
        return name ?? userName ?? 'Unknown User';
      case 'page':
        return pageTitle ?? pageName ?? 'Unknown Page';
      case 'group':
        return groupTitle ?? groupName ?? 'Unknown Group';
      default:
        return 'Subscription';
    }
  }

  /// Get display picture based on subscription type
  String? get displayPicture {
    switch (nodeType) {
      case 'profile':
        return userPicture;
      case 'page':
        return pagePicture;
      case 'group':
        return groupPicture;
      default:
        return null;
    }
  }
}
