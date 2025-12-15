class PostCourse {
  PostCourse({
    required this.courseId,
    required this.postId,
    required this.title,
    this.categoryId,
    this.location,
    this.fees,
    this.feesCurrency,
    this.startDate,
    this.endDate,
    this.coverImage,
    this.available = true,
    this.candidatesCount = 0,
    this.iOwner = false,
  });
  final String courseId;
  final String postId;
  final String title;
  final String? categoryId;
  final String? location;
  final String? fees;
  final CourseCurrency? feesCurrency;
  final String? startDate;
  final String? endDate;
  final String? coverImage;
  final bool available;
  final int candidatesCount;
  final bool iOwner;
  bool get isFree => fees == null || fees == '0' || fees!.isEmpty;
  bool get hasStarted {
    if (startDate == null) return false;
    try {
      final start = DateTime.parse(startDate!);
      return DateTime.now().isAfter(start);
    } catch (e) {
      return false;
    }
  }
  bool get hasEnded {
    if (endDate == null) return false;
    try {
      final end = DateTime.parse(endDate!);
      return DateTime.now().isAfter(end);
    } catch (e) {
      return false;
    }
  }
  bool get isOngoing => hasStarted && !hasEnded;
  factory PostCourse.fromJson(Map<String, dynamic> json) {
    return PostCourse(
      courseId: json['course_id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      title: json['title'] ?? '',
      categoryId: json['category_id']?.toString(),
      location: json['location'],
      fees: json['fees']?.toString(),
      feesCurrency: json['fees_currency'] != null
          ? CourseCurrency.fromJson(json['fees_currency'] as Map<String, dynamic>)
          : null,
      startDate: json['start_date'],
      endDate: json['end_date'],
      coverImage: json['cover_image'],
      available: json['available']?.toString() == '1' || json['available'] == true,
      candidatesCount: int.tryParse(json['candidates_count']?.toString() ?? '0') ?? 0,
      iOwner: json['i_owner'] == true || json['i_owner'] == 1 || json['i_owner'] == '1',
    );
  }
  static PostCourse? maybeFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    if (json.isEmpty) return null;
    try {
      return PostCourse.fromJson(json);
    } catch (e) {
      return null;
    }
  }
  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'post_id': postId,
      'title': title,
      if (categoryId != null) 'category_id': categoryId,
      if (location != null) 'location': location,
      if (fees != null) 'fees': fees,
      if (feesCurrency != null) 'fees_currency': feesCurrency!.toJson(),
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (coverImage != null) 'cover_image': coverImage,
      'available': available ? '1' : '0',
      'candidates_count': candidatesCount.toString(),
      'i_owner': iOwner ? '1' : '0',
    };
  }
}
class CourseCurrency {
  CourseCurrency({
    required this.currencyId,
    required this.name,
    required this.code,
    required this.symbol,
    this.dir = 'left',
    this.isDefault = false,
    this.enabled = true,
  });
  final String currencyId;
  final String name;
  final String code;
  final String symbol;
  final String dir; // 'left' or 'right'
  final bool isDefault;
  final bool enabled;
  factory CourseCurrency.fromJson(Map<String, dynamic> json) {
    return CourseCurrency(
      currencyId: json['currency_id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      symbol: json['symbol'] ?? '',
      dir: json['dir'] ?? 'left',
      isDefault: json['default']?.toString() == '1' || json['default'] == true,
      enabled: json['enabled']?.toString() == '1' || json['enabled'] == true,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'currency_id': currencyId,
      'name': name,
      'code': code,
      'symbol': symbol,
      'dir': dir,
      'default': isDefault ? '1' : '0',
      'enabled': enabled ? '1' : '0',
    };
  }
}
