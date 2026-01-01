/// مودل فئة الجدارة
class MeritCategory {
  final int categoryId;
  final String categoryName;
  final String categoryDescription;

  MeritCategory({
    required this.categoryId,
    required this.categoryName,
    required this.categoryDescription,
  });

  factory MeritCategory.fromJson(Map<String, dynamic> json) {
    return MeritCategory(
      categoryId: _toInt(json['category_id']),
      categoryName: json['category_name'] ?? '',
      categoryDescription: json['category_description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'category_name': categoryName,
        'category_description': categoryDescription,
      };

  /// تحويل آمن إلى int
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}

/// مودل رصيد الجدارة
class MeritBalance {
  final int maxMerits;
  final int sentMerits;
  final int remainingMerits;
  final int receivedMerits;

  MeritBalance({
    required this.maxMerits,
    required this.sentMerits,
    required this.remainingMerits,
    required this.receivedMerits,
  });

  factory MeritBalance.fromJson(Map<String, dynamic> json) {
    return MeritBalance(
      maxMerits: _toInt(json['max_merits']),
      sentMerits: _toInt(json['sent_merits']),
      remainingMerits: _toInt(json['remaining_merits']),
      receivedMerits: _toInt(json['received_merits']),
    );
  }

  Map<String, dynamic> toJson() => {
        'max_merits': maxMerits,
        'sent_merits': sentMerits,
        'remaining_merits': remainingMerits,
        'received_merits': receivedMerits,
      };

  /// تحويل آمن إلى int
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}

/// مودل أفضل المستخدمين في الجدارات
class TopMeritUser {
  final int userId;
  final String userName;
  final String userFirstName;
  final String userLastName;
  final String userPicture;
  final int meritsCount;
  final String categoryName;
  final int categoryId;

  TopMeritUser({
    required this.userId,
    required this.userName,
    required this.userFirstName,
    required this.userLastName,
    required this.userPicture,
    required this.meritsCount,
    required this.categoryName,
    required this.categoryId,
  });

  factory TopMeritUser.fromJson(Map<String, dynamic> json) {
    return TopMeritUser(
      userId: _toInt(json['top_user']?['user_id']),
      userName: json['top_user']?['user_name'] ?? '',
      userFirstName: json['top_user']?['user_firstname'] ?? '',
      userLastName: json['top_user']?['user_lastname'] ?? '',
      userPicture: json['top_user']?['user_picture'] ?? '',
      meritsCount: _toInt(json['top_user']?['merits_count']),
      categoryName: json['category']?['name'] ?? '',
      categoryId: _toInt(json['category']?['id']),
    );
  }

  String get fullName => '$userFirstName $userLastName'.trim();

  /// تحويل آمن إلى int
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}

/// مودل المستقبل للجدارة
class MeritRecipient {
  final int id;
  final String name;

  MeritRecipient({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

/// مودل طلب إرسال الجدارة
class SendMeritRequest {
  final List<MeritRecipient> recipients;
  final int categoryId;
  final String message;
  final String? image;

  SendMeritRequest({
    required this.recipients,
    required this.categoryId,
    required this.message,
    this.image,
  });

  Map<String, dynamic> toJson() => {
        'recipients': recipients.map((r) => r.toJson()).toList(),
        'category_id': categoryId,
        'message': message,
        'image': image ?? '',
      };
}

/// مودل عرض الجدارة في الـ post
class Merit {
  final String meritId;
  final String postId;
  final int categoryId;
  final String message;
  final String? image;
  final String categoryName;
  final String? categoryImage;

  Merit({
    required this.meritId,
    required this.postId,
    required this.categoryId,
    required this.message,
    this.image,
    required this.categoryName,
    this.categoryImage,
  });

  factory Merit.fromJson(Map<String, dynamic> json) {
    return Merit(
      meritId: json['merit_id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      categoryId: _toInt(json['category_id']),
      message: json['message'] ?? '',
      image: json['image'],
      categoryName: json['category_name'] ?? '',
      categoryImage: json['category_image'],
    );
  }

  Map<String, dynamic> toJson() => {
        'merit_id': meritId,
        'post_id': postId,
        'category_id': categoryId,
        'message': message,
        'image': image,
        'category_name': categoryName,
        'category_image': categoryImage,
      };

  /// تحويل آمن إلى int
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}
