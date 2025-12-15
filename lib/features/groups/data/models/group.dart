import 'package:equatable/equatable.dart';
/// Group Privacy Levels
enum GroupPrivacy {
  public('public'),
  closed('closed'),
  secret('secret');
  const GroupPrivacy(this.value);
  final String value;
  static GroupPrivacy fromString(String value) {
    return GroupPrivacy.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GroupPrivacy.public,
    );
  }
}
/// Group Member Status
enum MemberStatus {
  approved('approved'),
  pending('pending'),
  rejected('rejected');
  const MemberStatus(this.value);
  final String value;
  static MemberStatus fromString(String value) {
    return MemberStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MemberStatus.approved,
    );
  }
}
/// Group Category Model
class GroupCategory extends Equatable {
  final int categoryId;
  final String categoryName;
  final String categoryDescription;
  final int categoryOrder;
  final int categoryTotalGroups;
  const GroupCategory({
    required this.categoryId,
    required this.categoryName,
    this.categoryDescription = '',
    this.categoryOrder = 0,
    this.categoryTotalGroups = 0,
  });
  // Legacy constructor for backward compatibility
  factory GroupCategory.fromLegacy({
    required int id,
    required String name,
  }) {
    return GroupCategory(
      categoryId: id,
      categoryName: name,
    );
  }
  factory GroupCategory.fromJson(Map<String, dynamic> json) {
    // Check if it's the new format from /data/groups/categories
    if (json.containsKey('category_id')) {
      return GroupCategory(
        categoryId: json['category_id'] as int,
        categoryName: (json['category_name'] as String?) ?? '',
        categoryDescription: (json['category_description'] as String?) ?? '',
        categoryOrder: json['category_order'] as int? ?? 0,
        categoryTotalGroups: json['category_total_groups'] as int? ?? 0,
      );
    }
    // Legacy format from group responses
    return GroupCategory(
      categoryId: json['id'] as int,
      categoryName: (json['name'] as String?) ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'category_description': categoryDescription,
      'category_order': categoryOrder,
      'category_total_groups': categoryTotalGroups,
    };
  }
  /// Default category when data is missing
  factory GroupCategory.defaultCategory() {
    return const GroupCategory(
      categoryId: 0,
      categoryName: 'عام',
      categoryDescription: 'فئة عامة',
      categoryOrder: 0,
      categoryTotalGroups: 0,
    );
  }
  // Legacy getter for backward compatibility
  int get id => categoryId;
  String get name => categoryName;
  @override
  List<Object> get props => [categoryId, categoryName, categoryDescription, categoryOrder, categoryTotalGroups];
}
/// Group Admin Model
class GroupAdmin extends Equatable {
  final int userId;
  final String username;
  final String firstname;
  final String lastname;
  final String fullname;
  final String picture;
  final bool verified;
  const GroupAdmin({
    required this.userId,
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.fullname,
    required this.picture,
    required this.verified,
  });
  factory GroupAdmin.fromJson(Map<String, dynamic> json) {
    return GroupAdmin(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      fullname: json['fullname'] as String,
      picture: json['picture'] as String,
      verified: (json['verified'] as bool?) ?? false,
    );
  }
  /// Default admin when data is missing (for newly created groups)
  factory GroupAdmin.defaultAdmin() {
    return const GroupAdmin(
      userId: 0,
      username: 'unknown',
      firstname: 'مجهول',
      lastname: '',
      fullname: 'مجهول',
      picture: '',
      verified: false,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'firstname': firstname,
      'lastname': lastname,
      'fullname': fullname,
      'picture': picture,
      'verified': verified,
    };
  }
  @override
  List<Object> get props => [
        userId,
        username,
        firstname,
        lastname,
        fullname,
        picture,
        verified,
      ];
}
/// Group Membership Status Model
class GroupMembershipStatus extends Equatable {
  final bool isMember;
  final String status;
  final bool isAdmin;
  const GroupMembershipStatus({
    required this.isMember,
    required this.status,
    required this.isAdmin,
  });
  factory GroupMembershipStatus.fromJson(Map<String, dynamic> json) {
    return GroupMembershipStatus(
      isMember: (json['is_member'] as bool?) ?? false,
      status: (json['status'] as String?) ?? 'not_member',
      isAdmin: (json['is_admin'] as bool?) ?? false,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'is_member': isMember,
      'status': status,
      'is_admin': isAdmin,
    };
  }
  /// Default membership for creator when data is missing
  factory GroupMembershipStatus.defaultMembership() {
    return const GroupMembershipStatus(
      isMember: true,
      status: 'approved',
      isAdmin: true, // Creator is admin by default
    );
  }
  @override
  List<Object> get props => [isMember, status, isAdmin];
}
/// Detailed Group Membership for Members List
class GroupMembership extends Equatable {
  final bool approved;
  final String timeAdded;
  final bool isAdmin;
  const GroupMembership({
    required this.approved,
    required this.timeAdded,
    required this.isAdmin,
  });
  factory GroupMembership.fromJson(Map<String, dynamic> json) {
    return GroupMembership(
      approved: (json['approved'] as bool?) ?? false,
      timeAdded: (json['time_added'] as String?) ?? '',
      isAdmin: (json['is_admin'] as bool?) ?? false,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'approved': approved,
      'time_added': timeAdded,
      'is_admin': isAdmin,
    };
  }
  @override
  List<Object> get props => [approved, timeAdded, isAdmin];
}
/// Group Member Model
class GroupMember extends Equatable {
  final int userId;
  final String username;
  final String firstname;
  final String lastname;
  final String fullname;
  final String picture;
  final String? pictureFull;
  final bool verified;
  final bool subscribed;
  final GroupMembership membership;
  const GroupMember({
    required this.userId,
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.fullname,
    required this.picture,
    this.pictureFull,
    required this.verified,
    required this.subscribed,
    required this.membership,
  });
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'] as int,
      username: (json['username'] as String?) ?? '',
      firstname: (json['firstname'] as String?) ?? '',
      lastname: (json['lastname'] as String?) ?? '',
      fullname: (json['fullname'] as String?) ?? '',
      picture: (json['picture'] as String?) ?? '',
      pictureFull: json['picture_full'] as String?,
      verified: (json['verified'] as bool?) ?? false,
      subscribed: (json['subscribed'] as bool?) ?? false,
      membership: GroupMembership.fromJson(json['membership'] as Map<String, dynamic>),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'firstname': firstname,
      'lastname': lastname,
      'fullname': fullname,
      'picture': picture,
      'picture_full': pictureFull,
      'verified': verified,
      'subscribed': subscribed,
      'membership': membership.toJson(),
    };
  }
  @override
  List<Object?> get props => [
        userId,
        username,
        firstname,
        lastname,
        fullname,
        picture,
        pictureFull,
        verified,
        subscribed,
        membership,
      ];
}
/// Main Group Model
class Group extends Equatable {
  final int groupId;
  final String groupName;
  final String groupTitle;
  final String groupDescription;
  final GroupPrivacy groupPrivacy;
  final String? groupPicture;
  final String? groupPictureFull;
  final String? groupCover;
  final String? groupCoverFull;
  final String? groupCoverPosition;
  final int groupMembers;
  final double groupRate;
  final String groupDate;
  final bool groupPublishEnabled;
  final bool groupPublishApprovalEnabled;
  final bool groupMonetizationEnabled;
  final double groupMonetizationMinPrice;
  final bool chatboxEnabled;
  final bool isFake;
  final GroupAdmin admin;
  final GroupCategory category;
  final GroupMembershipStatus? membership;
  const Group({
    required this.groupId,
    required this.groupName,
    required this.groupTitle,
    required this.groupDescription,
    required this.groupPrivacy,
    this.groupPicture,
    this.groupPictureFull,
    this.groupCover,
    this.groupCoverFull,
    this.groupCoverPosition,
    required this.groupMembers,
    required this.groupRate,
    required this.groupDate,
    required this.groupPublishEnabled,
    required this.groupPublishApprovalEnabled,
    required this.groupMonetizationEnabled,
    required this.groupMonetizationMinPrice,
    required this.chatboxEnabled,
    required this.isFake,
    required this.admin,
    required this.category,
    this.membership,
  });
  factory Group.fromJson(Map<String, dynamic> json) {
    // Handle different picture formats from API
    String? groupPictureValue;
    String? groupPictureFullValue;
    String? groupCoverValue;
    String? groupCoverFullValue;
    // Check if group_picture is an object (new format) or string (old format)
    if (json['group_picture'] is Map<String, dynamic>) {
      final pictureData = json['group_picture'] as Map<String, dynamic>;
      groupPictureValue = pictureData['original'] as String?;
      groupPictureFullValue = pictureData['full'] as String?;
    } else if (json['group_picture'] is String) {
      groupPictureValue = json['group_picture'] as String?;
      groupPictureFullValue = json['group_picture_full'] as String?;
    }
    // Check if group_cover is an object (new format) or string (old format)
    if (json['group_cover'] is Map<String, dynamic>) {
      final coverData = json['group_cover'] as Map<String, dynamic>;
      groupCoverValue = coverData['original'] as String?;
      groupCoverFullValue = coverData['full'] as String?;
    } else if (json['group_cover'] is String) {
      groupCoverValue = json['group_cover'] as String?;
      groupCoverFullValue = json['group_cover_full'] as String?;
    }
    return Group(
      groupId: json['group_id'] as int,
      groupName: (json['group_name'] as String?) ?? '',
      groupTitle: (json['group_title'] as String?) ?? '',
      groupDescription: (json['group_description'] as String?) ?? '',
      groupPrivacy: GroupPrivacy.fromString((json['group_privacy'] as String?) ?? 'public'),
      groupPicture: groupPictureValue,
      groupPictureFull: groupPictureFullValue,
      groupCover: groupCoverValue,
      groupCoverFull: groupCoverFullValue,
      groupCoverPosition: json['group_cover_position'] as String?,
      groupMembers: (json['group_members'] as int?) ?? 1, // Default to 1 for creator
      groupRate: (json['group_rate'] as num?)?.toDouble() ?? 0.0,
      groupDate: (json['group_date'] as String?) ?? DateTime.now().toIso8601String(),
      groupPublishEnabled: json['group_publish_enabled'] as bool? ?? true,
      groupPublishApprovalEnabled: json['group_publish_approval_enabled'] as bool? ?? false,
      groupMonetizationEnabled: json['group_monetization_enabled'] as bool? ?? false,
      groupMonetizationMinPrice: (json['group_monetization_min_price'] as num?)?.toDouble() ?? 0.0,
      chatboxEnabled: json['chatbox_enabled'] as bool? ?? false,
      isFake: json['is_fake'] as bool? ?? false,
      admin: json['admin'] != null 
          ? GroupAdmin.fromJson(json['admin'] as Map<String, dynamic>)
          : GroupAdmin.defaultAdmin(), // Create default admin if missing
      category: json['category'] != null 
          ? GroupCategory.fromJson(json['category'] as Map<String, dynamic>)
          : GroupCategory.defaultCategory(), // Create default category if missing
      membership: json['membership'] != null
          ? GroupMembershipStatus.fromJson(json['membership'] as Map<String, dynamic>)
          : GroupMembershipStatus.defaultMembership(), // Create default membership for creator
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'group_name': groupName,
      'group_title': groupTitle,
      'group_description': groupDescription,
      'group_privacy': groupPrivacy.value,
      'group_picture': groupPicture,
      'group_picture_full': groupPictureFull,
      'group_cover': groupCover,
      'group_cover_full': groupCoverFull,
      'group_cover_position': groupCoverPosition,
      'group_members': groupMembers,
      'group_rate': groupRate,
      'group_date': groupDate,
      'group_publish_enabled': groupPublishEnabled,
      'group_publish_approval_enabled': groupPublishApprovalEnabled,
      'group_monetization_enabled': groupMonetizationEnabled,
      'group_monetization_min_price': groupMonetizationMinPrice,
      'chatbox_enabled': chatboxEnabled,
      'is_fake': isFake,
      'admin': admin.toJson(),
      'category': category.toJson(),
      'membership': membership?.toJson(),
    };
  }
  Group copyWith({
    int? groupId,
    String? groupName,
    String? groupTitle,
    String? groupDescription,
    GroupPrivacy? groupPrivacy,
    String? groupPicture,
    String? groupPictureFull,
    String? groupCover,
    String? groupCoverFull,
    String? groupCoverPosition,
    int? groupMembers,
    double? groupRate,
    String? groupDate,
    bool? groupPublishEnabled,
    bool? groupPublishApprovalEnabled,
    bool? groupMonetizationEnabled,
    double? groupMonetizationMinPrice,
    bool? chatboxEnabled,
    bool? isFake,
    GroupAdmin? admin,
    GroupCategory? category,
    GroupMembershipStatus? membership,
  }) {
    return Group(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupTitle: groupTitle ?? this.groupTitle,
      groupDescription: groupDescription ?? this.groupDescription,
      groupPrivacy: groupPrivacy ?? this.groupPrivacy,
      groupPicture: groupPicture ?? this.groupPicture,
      groupPictureFull: groupPictureFull ?? this.groupPictureFull,
      groupCover: groupCover ?? this.groupCover,
      groupCoverFull: groupCoverFull ?? this.groupCoverFull,
      groupCoverPosition: groupCoverPosition ?? this.groupCoverPosition,
      groupMembers: groupMembers ?? this.groupMembers,
      groupRate: groupRate ?? this.groupRate,
      groupDate: groupDate ?? this.groupDate,
      groupPublishEnabled: groupPublishEnabled ?? this.groupPublishEnabled,
      groupPublishApprovalEnabled: groupPublishApprovalEnabled ?? this.groupPublishApprovalEnabled,
      groupMonetizationEnabled: groupMonetizationEnabled ?? this.groupMonetizationEnabled,
      groupMonetizationMinPrice: groupMonetizationMinPrice ?? this.groupMonetizationMinPrice,
      chatboxEnabled: chatboxEnabled ?? this.chatboxEnabled,
      isFake: isFake ?? this.isFake,
      admin: admin ?? this.admin,
      category: category ?? this.category,
      membership: membership ?? this.membership,
    );
  }
  /// Get member count formatted text
  String get membersCountText {
    if (groupMembers == 1) return '$groupMembers عضو';
    if (groupMembers <= 10) return '$groupMembers أعضاء';
    if (groupMembers <= 100) return '$groupMembers عضو';
    if (groupMembers <= 1000) return '${(groupMembers / 100).round()}ه عضو';
    return '${(groupMembers / 1000).toStringAsFixed(1)}ك عضو';
  }
  /// Get privacy display text
  String get privacyDisplayText {
    switch (groupPrivacy) {
      case GroupPrivacy.public:
        return 'مجموعة عامة';
      case GroupPrivacy.closed:
        return 'مجموعة مغلقة';
      case GroupPrivacy.secret:
        return 'مجموعة سرية';
    }
  }
  /// Check if user can join
  bool get canJoin {
    return membership == null || !membership!.isMember;
  }
  /// Check if user is admin
  bool get isCurrentUserAdmin {
    return membership?.isAdmin ?? false;
  }
  /// Check if user is member
  bool get isCurrentUserMember {
    return membership?.isMember ?? false;
  }
  @override
  List<Object?> get props => [
        groupId,
        groupName,
        groupTitle,
        groupDescription,
        groupPrivacy,
        groupPicture,
        groupPictureFull,
        groupCover,
        groupCoverFull,
        groupCoverPosition,
        groupMembers,
        groupRate,
        groupDate,
        groupPublishEnabled,
        groupPublishApprovalEnabled,
        groupMonetizationEnabled,
        groupMonetizationMinPrice,
        chatboxEnabled,
        isFake,
        admin,
        category,
        membership,
      ];
}
/// Pagination Model
class Pagination extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int pages;
  final bool hasMore;
  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.hasMore,
  });
  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      pages: json['pages'] as int,
      hasMore: (json['has_more'] as bool?) ?? false,
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
  @override
  List<Object> get props => [page, limit, total, pages, hasMore];
}
/// Group Members Response
class GroupMembersResponse extends Equatable {
  final List<GroupMember> members;
  final Pagination pagination;
  const GroupMembersResponse({
    required this.members,
    required this.pagination,
  });
  factory GroupMembersResponse.fromJson(Map<String, dynamic> json) {
    return GroupMembersResponse(
      members: (json['members'] as List)
          .map((member) => GroupMember.fromJson(member as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] != null 
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : const Pagination(page: 1, limit: 20, total: 0, pages: 1, hasMore: false),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'members': members.map((member) => member.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
  @override
  List<Object> get props => [members, pagination];
}
/// Groups List Response
class GroupsResponse extends Equatable {
  final List<Group> groups;
  final Pagination pagination;
  final Map<String, dynamic> filters;
  const GroupsResponse({
    required this.groups,
    required this.pagination,
    required this.filters,
  });
  factory GroupsResponse.fromJson(Map<String, dynamic> json) {
    return GroupsResponse(
      groups: (json['groups'] as List)
          .map((group) => Group.fromJson(group as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
      filters: json['filters'] as Map<String, dynamic>,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'groups': groups.map((group) => group.toJson()).toList(),
      'pagination': pagination.toJson(),
      'filters': filters,
    };
  }
  @override
  List<Object> get props => [groups, pagination, filters];
}