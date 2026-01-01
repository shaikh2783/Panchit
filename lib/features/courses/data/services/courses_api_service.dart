import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../../../feed/data/models/post.dart';

/// خدمة API للدورات التعليمية
class CoursesApiService {
  final ApiClient _apiClient;

  CoursesApiService(this._apiClient);

  /// جلب جميع الدورات
  /// 
  /// Parameters:
  /// - [limit]: عدد الدورات في كل صفحة (افتراضي: 20)
  /// - [offset]: رقم الصفحة للبدء منها (افتراضي: 0)
  /// - [categoryId]: معرف الفئة للتصفية (اختياري)
  /// - [status]: حالة الدورة: 'all', 'available', 'ongoing', 'ended' (افتراضي: 'all')
  Future<CoursesResponse> getCourses({
    int limit = 20,
    int offset = 0,
    String? categoryId,
    String status = 'all',
  }) async {
    try {
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (categoryId != null) 'category_id': categoryId,
        if (status != 'all') 'status': status,
      };

      final response = await _apiClient.get(
        configCfgP('courses_base'),
        queryParameters: params,
      );

      return CoursesResponse.fromJson(response);
    } catch (e) {

      rethrow;
    }
  }

  /// جلب تفاصيل دورة معينة
  Future<Post> getCourseDetails(String courseId) async {
    try {
      final response = await _apiClient.get(
        '${configCfgP('courses_base')}/$courseId',
      );

      return Post.fromJson(response['data']);
    } catch (e) {

      rethrow;
    }
  }

  /// التسجيل في دورة
  Future<CourseEnrollmentResult> enrollInCourse(
    String courseId, {
    required String name,
    required String location,
    required String phone,
    required String email,
  }) async {
    try {
      final response = await _apiClient.post(
        configCfgP('course_apply'),
        body: {
          'course_id': courseId,
          'name': name,
          'location': location,
          'phone': phone,
          'email': email,
        },
      );

      return CourseEnrollmentResult(
        success: response['status'] == 'success',
        message: response['message'] ?? 'تم التسجيل في الدورة بنجاح',
      );
    } catch (e) {

      return CourseEnrollmentResult(
        success: false,
        message: 'فشل التسجيل في الدورة',
      );
    }
  }

  /// إلغاء التسجيل من دورة
  Future<CourseEnrollmentResult> unenrollFromCourse(String courseId) async {
    try {
      final response = await _apiClient.post(
        configCfgP('course_unenroll'),
        body: {'course_id': courseId},
      );

      return CourseEnrollmentResult(
        success: response['status'] == 'success',
        message: response['message'] ?? 'تم إلغاء التسجيل من الدورة',
      );
    } catch (e) {

      return CourseEnrollmentResult(
        success: false,
        message: 'فشل إلغاء التسجيل من الدورة',
      );
    }
  }

  /// حذف دورة (للمنشئ فقط)
  Future<CourseEnrollmentResult> deleteCourse(String courseId) async {
    try {
      final response = await _apiClient.post(
        '${configCfgP('courses_base')}/$courseId',
        body: {'_method': 'DELETE'},
      );

      return CourseEnrollmentResult(
        success: response['status'] == 'success',
        message: response['message'] ?? 'تم حذف الدورة بنجاح',
      );
    } catch (e) {

      return CourseEnrollmentResult(
        success: false,
        message: 'فشل حذف الدورة',
      );
    }
  }
}

/// نتيجة استجابة قائمة الدورات
class CoursesResponse {
  final List<Post> courses;
  final bool hasMore;
  final int totalCount;

  CoursesResponse({
    required this.courses,
    required this.hasMore,
    this.totalCount = 0,
  });

  factory CoursesResponse.fromJson(Map<String, dynamic> json) {
    // API returns: { data: { courses: [...] } }
    final dataObject = json['data'] as Map<String, dynamic>? ?? {};
    final coursesList = dataObject['courses'] as List<dynamic>? ?? [];
    
    final courses = coursesList
        .map((item) => Post.fromJson(item as Map<String, dynamic>))
        .where((post) => post.isCoursePost)
        .toList();

    return CoursesResponse(
      courses: courses,
      hasMore: json['has_more'] ?? false,
      totalCount: json['total_count'] ?? courses.length,
    );
  }
}

/// نتيجة عملية التسجيل/إلغاء التسجيل
class CourseEnrollmentResult {
  final bool success;
  final String message;

  CourseEnrollmentResult({
    required this.success,
    required this.message,
  });
}
