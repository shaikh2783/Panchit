import 'dart:io';
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/profile_update_models.dart';
/// خدمة تعديل الملف الشخصي - تحتوي على جميع endpoints التعديل
class ProfileUpdateService {
  final ApiClient _apiClient;
  ProfileUpdateService(this._apiClient);
  /// 1. تعديل المعلومات الأساسية
  Future<ProfileUpdateResponse> updateBasicInfo(
      BasicInfoUpdateRequest request) async {
    try {
      final response = await _apiClient.post(
        configCfgP('profile_update_basic'),
        data: request.toJson(),
      );
      return ProfileUpdateResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  /// 2. تعديل معلومات العمل
  Future<ProfileUpdateResponse> updateWorkInfo(
      WorkInfoUpdateRequest request) async {
    try {
      final response = await _apiClient.post(
        configCfgP('profile_update_work'),
        data: request.toJson(),
      );
      return ProfileUpdateResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  /// 3. تعديل معلومات الموقع
  Future<ProfileUpdateResponse> updateLocation(
      LocationUpdateRequest request) async {
    try {
      final response = await _apiClient.post(
        configCfgP('profile_update_location'),
        data: request.toJson(),
      );
      return ProfileUpdateResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  /// 4. تعديل معلومات التعليم
  Future<ProfileUpdateResponse> updateEducation(
      EducationUpdateRequest request) async {
    try {
      final response = await _apiClient.post(
        configCfgP('profile_update_education'),
        data: request.toJson(),
      );
      return ProfileUpdateResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  /// 5. تعديل روابط التواصل الاجتماعي
  Future<ProfileUpdateResponse> updateSocialLinks(
      SocialLinksUpdateRequest request) async {
    try {
      final response = await _apiClient.post(
        configCfgP('profile_update_social'),
        data: request.toJson(),
      );
      return ProfileUpdateResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  /// 6. تعديل تصميم الملف الشخصي
  Future<ProfileUpdateResponse> updateDesign(
      DesignUpdateRequest request) async {
    try {
      final response = await _apiClient.post(
        configCfgP('profile_update_design'),
        data: request.toJson(),
      );
      return ProfileUpdateResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  /// 7. تغيير كلمة المرور
  Future<ProfileUpdateResponse> updatePassword(
      PasswordUpdateRequest request) async {
    try {
      final response = await _apiClient.post(
        configCfgP('profile_update_password'),
        data: request.toJson(),
      );
      return ProfileUpdateResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  /// 8. رفع الصورة الشخصية
  Future<ProfileUpdateResponse> uploadProfilePicture(File imageFile) async {
    try {
      final response = await _apiClient.multipartPost(
        configCfgP('profile_picture'),
        body: {},
        filePath: imageFile.path,
        fileFieldName: 'photo',
        contentType: MediaType('image', 'jpeg'),
      );
      return ProfileUpdateResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  /// 9. رفع صورة الغلاف
  Future<ProfileUpdateResponse> uploadCoverPhoto(File imageFile) async {
    try {
      final response = await _apiClient.multipartPost(
        configCfgP('profile_cover'),
        body: {},
        filePath: imageFile.path,
        fileFieldName: 'photo',
        contentType: MediaType('image', 'jpeg'),
      );
      return ProfileUpdateResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
