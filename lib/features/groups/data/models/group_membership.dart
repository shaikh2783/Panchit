/// حالة عضوية المستخدم في المجموعة
enum MembershipStatus {
  approved,    // عضو مقبول
  pending,     // طلب معلق
  notMember,   // ليس عضواً
  left;        // غادر المجموعة

  static MembershipStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return MembershipStatus.approved;
      case 'pending':
        return MembershipStatus.pending;
      case 'left':
        return MembershipStatus.left;
      case 'not_member':
      default:
        return MembershipStatus.notMember;
    }
  }

  String toServerString() {
    switch (this) {
      case MembershipStatus.approved:
        return 'approved';
      case MembershipStatus.pending:
        return 'pending';
      case MembershipStatus.left:
        return 'left';
      case MembershipStatus.notMember:
        return 'not_member';
    }
  }
}

/// نموذج العضوية
class GroupMembership {
  final bool isMember;
  final bool isAdmin;
  final MembershipStatus status;

  GroupMembership({
    required this.isMember,
    required this.isAdmin,
    required this.status,
  });

  factory GroupMembership.fromJson(Map<String, dynamic> json) {
    return GroupMembership(
      isMember: json['is_member'] == true || json['is_member'] == 1,
      isAdmin: json['is_admin'] == true || json['is_admin'] == 1,
      status: MembershipStatus.fromString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_member': isMember,
      'is_admin': isAdmin,
      'status': status.toServerString(),
    };
  }

  /// عضو مقبول
  bool get isApproved => status == MembershipStatus.approved;

  /// طلب معلق
  bool get isPending => status == MembershipStatus.pending;

  /// يمكنه عرض المحتوى
  bool get canViewContent => isMember && isApproved;
}
