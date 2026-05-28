import 'package:get/get.dart';

/// نوع خصوصية المجموعة
enum GroupPrivacy {
  public, // عامة - انضمام فوري، مرئية للجميع
  closed, // مغلقة - طلب انضمام، مرئية في البحث
  secret; // سرية - طلب انضمام، غير مرئية في البحث

  static GroupPrivacy fromString(String? privacy) {
    switch (privacy?.toLowerCase()) {
      case 'public':
        return GroupPrivacy.public;
      case 'closed':
        return GroupPrivacy.closed;
      case 'secret':
        return GroupPrivacy.secret;
      default:
        return GroupPrivacy.public;
    }
  }

  String toServerString() {
    switch (this) {
      case GroupPrivacy.public:
        return 'public';
      case GroupPrivacy.closed:
        return 'closed';
      case GroupPrivacy.secret:
        return 'secret';
    }
  }

  /// النص المعروض للمستخدم
  String get displayName {
    switch (this) {
      case GroupPrivacy.public:
        return 'group_privacy_public'.tr;
      case GroupPrivacy.closed:
        return 'group_privacy_closed'.tr;
      case GroupPrivacy.secret:
        return 'group_privacy_secret'.tr;
    }
  }

  /// الوصف
  String get description {
    switch (this) {
      case GroupPrivacy.public:
        return 'group_privacy_public_desc'.tr;
      case GroupPrivacy.closed:
        return 'group_privacy_closed_desc'.tr;
      case GroupPrivacy.secret:
        return 'group_privacy_secret_desc'.tr;
    }
  }

  /// هل تتطلب موافقة للانضمام؟
  bool get requiresApproval => this != GroupPrivacy.public;
}
