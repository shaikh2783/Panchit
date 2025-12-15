/// طلب تعديل المعلومات الأساسية للملف الشخصي
class BasicInfoUpdateRequest {
  final String? firstname;
  final String? lastname;
  final String? gender; // "1" for male, "2" for female
  final String? birthMonth;
  final String? birthDay;
  final String? birthYear;
  final String? country; // Country ID
  final String? relationship; // Relationship status
  final String? biography;
  final String? website;
  BasicInfoUpdateRequest({
    this.firstname,
    this.lastname,
    this.gender,
    this.birthMonth,
    this.birthDay,
    this.birthYear,
    this.country,
    this.relationship,
    this.biography,
    this.website,
  });
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (firstname != null) map['firstname'] = firstname;
    if (lastname != null) map['lastname'] = lastname;
    if (gender != null) map['gender'] = gender;
    if (birthMonth != null) map['birth_month'] = birthMonth;
    if (birthDay != null) map['birth_day'] = birthDay;
    if (birthYear != null) map['birth_year'] = birthYear;
    if (country != null) map['country'] = country;
    if (relationship != null) map['relationship'] = relationship;
    if (biography != null) map['biography'] = biography;
    if (website != null) map['website'] = website;
    return map;
  }
}
/// طلب تعديل معلومات العمل
class WorkInfoUpdateRequest {
  final String? workTitle;
  final String? workPlace;
  final String? workUrl;
  WorkInfoUpdateRequest({
    this.workTitle,
    this.workPlace,
    this.workUrl,
  });
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (workTitle != null) map['work_title'] = workTitle;
    if (workPlace != null) map['work_place'] = workPlace;
    if (workUrl != null) map['work_url'] = workUrl;
    return map;
  }
}
/// طلب تعديل معلومات الموقع
class LocationUpdateRequest {
  final String? city;
  final String? hometown;
  LocationUpdateRequest({
    this.city,
    this.hometown,
  });
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (city != null) map['city'] = city;
    if (hometown != null) map['hometown'] = hometown;
    return map;
  }
}
/// طلب تعديل معلومات التعليم
class EducationUpdateRequest {
  final String? eduMajor;
  final String? eduSchool;
  final String? eduClass;
  EducationUpdateRequest({
    this.eduMajor,
    this.eduSchool,
    this.eduClass,
  });
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (eduMajor != null) map['edu_major'] = eduMajor;
    if (eduSchool != null) map['edu_school'] = eduSchool;
    if (eduClass != null) map['edu_class'] = eduClass;
    return map;
  }
}
/// طلب تعديل روابط التواصل الاجتماعي
class SocialLinksUpdateRequest {
  final String? facebook;
  final String? twitter;
  final String? youtube;
  final String? instagram;
  final String? twitch;
  final String? linkedin;
  final String? vkontakte;
  SocialLinksUpdateRequest({
    this.facebook,
    this.twitter,
    this.youtube,
    this.instagram,
    this.twitch,
    this.linkedin,
    this.vkontakte,
  });
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (facebook != null) map['facebook'] = facebook;
    if (twitter != null) map['twitter'] = twitter;
    if (youtube != null) map['youtube'] = youtube;
    if (instagram != null) map['instagram'] = instagram;
    if (twitch != null) map['twitch'] = twitch;
    if (linkedin != null) map['linkedin'] = linkedin;
    if (vkontakte != null) map['vkontakte'] = vkontakte;
    return map;
  }
}
/// طلب تعديل تصميم الملف الشخصي
class DesignUpdateRequest {
  final String profileBackground;
  DesignUpdateRequest({required this.profileBackground});
  Map<String, dynamic> toJson() {
    return {'user_profile_background': profileBackground};
  }
}
/// طلب تغيير كلمة المرور
class PasswordUpdateRequest {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  PasswordUpdateRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });
  Map<String, dynamic> toJson() {
    return {
      'current': currentPassword,
      'new': newPassword,
      'confirm': confirmPassword,
    };
  }
}
/// استجابة عامة لعمليات التعديل
class ProfileUpdateResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  ProfileUpdateResponse({
    required this.success,
    required this.message,
    this.data,
  });
  factory ProfileUpdateResponse.fromJson(Map<String, dynamic> json) {
    return ProfileUpdateResponse(
      success: json['success'] == true,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}
