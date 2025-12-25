/// نوع خصوصية المجموعة
enum GroupPrivacy {
  public,   // عامة - انضمام فوري، مرئية للجميع
  closed,   // مغلقة - طلب انضمام، مرئية في البحث
  secret;   // سرية - طلب انضمام، غير مرئية في البحث

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
        return 'عامة';
      case GroupPrivacy.closed:
        return 'مغلقة';
      case GroupPrivacy.secret:
        return 'سرية';
    }
  }

  /// الوصف
  String get description {
    switch (this) {
      case GroupPrivacy.public:
        return 'انضمام فوري، مرئية للجميع';
      case GroupPrivacy.closed:
        return 'طلب انضمام، مرئية في البحث';
      case GroupPrivacy.secret:
        return 'طلب انضمام، غير مرئية في البحث';
    }
  }

  /// هل تتطلب موافقة للانضمام؟
  bool get requiresApproval => this != GroupPrivacy.public;
}
