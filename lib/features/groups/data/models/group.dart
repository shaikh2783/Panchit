import 'group_admin.dart';
import 'group_category.dart';
import 'group_membership.dart';
import 'group_privacy.dart';

/// نموذج المجموعة الرئيسي
class Group {
  final int groupId;
  final String groupName;
  final String groupTitle;
  final String? groupDescription;
  final GroupPrivacy groupPrivacy;
  final String? groupPicture;
  final String? groupPictureFull;
  final String? groupCover;
  final String? groupCoverFull;
  final String? groupCoverPosition;
  final int groupMembers;
  final String groupDate;
  final bool groupPublishEnabled;
  final bool groupPublishApprovalEnabled;
  final bool? groupMonetizationEnabled;
  final double? groupMonetizationMinPrice;
  final bool? chatboxEnabled;
  final bool isFake;
  final double groupRate;
  final GroupAdmin admin;
  final GroupCategory category;
  final GroupMembership? membership;
  final int? pendingRequests; // فقط للمجموعات المُدارة

  Group({
    required this.groupId,
    required this.groupName,
    required this.groupTitle,
    this.groupDescription,
    required this.groupPrivacy,
    this.groupPicture,
    this.groupPictureFull,
    this.groupCover,
    this.groupCoverFull,
    this.groupCoverPosition,
    required this.groupMembers,
    required this.groupDate,
    this.groupPublishEnabled = true,
    this.groupPublishApprovalEnabled = false,
    this.groupMonetizationEnabled,
    this.groupMonetizationMinPrice,
    this.chatboxEnabled,
    this.isFake = false,
    this.groupRate = 0.0,
    required this.admin,
    required this.category,
    this.membership,
    this.pendingRequests,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['group_id'] ?? 0,
      groupName: json['group_name'] ?? '',
      groupTitle: json['group_title'] ?? '',
      groupDescription: json['group_description'],
      groupPrivacy: GroupPrivacy.fromString(json['group_privacy']),
      groupPicture: json['group_picture'],
      groupPictureFull: json['group_picture_full'] ?? json['group_picture'],
      groupCover: json['group_cover'],
      groupCoverFull: json['group_cover_full'] ?? json['group_cover'],
      groupCoverPosition: json['group_cover_position'],
      groupMembers: json['group_members'] ?? 0,
      groupDate: json['group_date'] ?? '',
      groupPublishEnabled: json['group_publish_enabled'] == true || json['group_publish_enabled'] == 1,
      groupPublishApprovalEnabled: json['group_publish_approval_enabled'] == true || json['group_publish_approval_enabled'] == 1,
      groupMonetizationEnabled: json['group_monetization_enabled'] == true || json['group_monetization_enabled'] == 1,
      groupMonetizationMinPrice: (json['group_monetization_min_price'] ?? 0).toDouble(),
      chatboxEnabled: json['chatbox_enabled'] == true || json['chatbox_enabled'] == 1,
      isFake: json['is_fake'] == true || json['is_fake'] == 1,
      groupRate: (json['group_rate'] ?? 0).toDouble(),
      admin: GroupAdmin.fromJson(json['admin'] ?? {}),
      category: GroupCategory.fromJson(json['category'] ?? {}),
      membership: json['membership'] != null ? GroupMembership.fromJson(json['membership']) : null,
      pendingRequests: json['pending_requests'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'group_name': groupName,
      'group_title': groupTitle,
      if (groupDescription != null) 'group_description': groupDescription,
      'group_privacy': groupPrivacy.toServerString(),
      if (groupPicture != null) 'group_picture': groupPicture,
      if (groupPictureFull != null) 'group_picture_full': groupPictureFull,
      if (groupCover != null) 'group_cover': groupCover,
      if (groupCoverFull != null) 'group_cover_full': groupCoverFull,
      if (groupCoverPosition != null) 'group_cover_position': groupCoverPosition,
      'group_members': groupMembers,
      'group_date': groupDate,
      'group_publish_enabled': groupPublishEnabled,
      'group_publish_approval_enabled': groupPublishApprovalEnabled,
      if (groupMonetizationEnabled != null) 'group_monetization_enabled': groupMonetizationEnabled,
      if (groupMonetizationMinPrice != null) 'group_monetization_min_price': groupMonetizationMinPrice,
      if (chatboxEnabled != null) 'chatbox_enabled': chatboxEnabled,
      'is_fake': isFake,
      'group_rate': groupRate,
      'admin': admin.toJson(),
      'category': category.toJson(),
      if (membership != null) 'membership': membership!.toJson(),
      if (pendingRequests != null) 'pending_requests': pendingRequests,
    };
  }

  /// نسخة محدثة من المجموعة
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
    String? groupDate,
    bool? groupPublishEnabled,
    bool? groupPublishApprovalEnabled,
    bool? groupMonetizationEnabled,
    double? groupMonetizationMinPrice,
    bool? chatboxEnabled,
    bool? isFake,
    double? groupRate,
    GroupAdmin? admin,
    GroupCategory? category,
    GroupMembership? membership,
    int? pendingRequests,
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
      groupDate: groupDate ?? this.groupDate,
      groupPublishEnabled: groupPublishEnabled ?? this.groupPublishEnabled,
      groupPublishApprovalEnabled: groupPublishApprovalEnabled ?? this.groupPublishApprovalEnabled,
      groupMonetizationEnabled: groupMonetizationEnabled ?? this.groupMonetizationEnabled,
      groupMonetizationMinPrice: groupMonetizationMinPrice ?? this.groupMonetizationMinPrice,
      chatboxEnabled: chatboxEnabled ?? this.chatboxEnabled,
      isFake: isFake ?? this.isFake,
      groupRate: groupRate ?? this.groupRate,
      admin: admin ?? this.admin,
      category: category ?? this.category,
      membership: membership ?? this.membership,
      pendingRequests: pendingRequests ?? this.pendingRequests,
    );
  }

  /// هل المستخدم عضو؟
  bool get isMember => membership?.isMember ?? false;

  /// هل المستخدم مشرف؟
  bool get isAdmin => membership?.isAdmin ?? false;

  /// هل يمكن عرض المحتوى؟
  bool get canViewContent => membership?.canViewContent ?? false;
}
