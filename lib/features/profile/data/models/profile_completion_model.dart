import 'package:flutter/material.dart';

class ProfileCompletionResponse {
  final String status;
  final String message;
  final ProfileCompletionData data;

  ProfileCompletionResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ProfileCompletionResponse.fromJson(Map<String, dynamic> json) {
    return ProfileCompletionResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? '',
      data: ProfileCompletionData.fromJson(json['data'] ?? {}),
    );
  }
}

class ProfileCompletionData {
  final int completionPercentage;
  final int totalSteps;
  final int completedSteps;
  final int missingSteps;
  final bool isComplete;
  final List<MissingField> missingFields;
  final List<String> completedFields;

  ProfileCompletionData({
    required this.completionPercentage,
    required this.totalSteps,
    required this.completedSteps,
    required this.missingSteps,
    required this.isComplete,
    required this.missingFields,
    required this.completedFields,
  });

  factory ProfileCompletionData.fromJson(Map<String, dynamic> json) {
    return ProfileCompletionData(
      completionPercentage: json['completion_percentage'] ?? 0,
      totalSteps: json['total_steps'] ?? 9,
      completedSteps: json['completed_steps'] ?? 0,
      missingSteps: json['missing_steps'] ?? 0,
      isComplete: json['is_complete'] ?? false,
      missingFields:
          (json['missing_fields'] as List<dynamic>?)
              ?.map(
                (field) => MissingField.fromJson(field as Map<String, dynamic>),
              )
              .toList() ??
          [],
      completedFields:
          (json['completed_fields'] as List<dynamic>?)
              ?.map((field) => field.toString())
              .toList() ??
          [],
    );
  }
}

class MissingField {
  final String field;
  final String label;
  final String type;
  final bool required;
  final Map<String, bool>? subFields;

  MissingField({
    required this.field,
    required this.label,
    required this.type,
    required this.required,
    this.subFields,
  });

  factory MissingField.fromJson(Map<String, dynamic> json) {
    return MissingField(
      field: json['field'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? 'text',
      required: json['required'] ?? false,
      subFields: json['sub_fields'] != null
          ? Map<String, bool>.from(json['sub_fields'] as Map)
          : null,
    );
  }

  // Field labels in English
  String get labelAr {
    const translations = {
      'profile_picture': 'Profile Picture',
      'cover_picture': 'Cover Photo',
      'biography': 'Biography',
      'birthdate': 'Birthdate',
      'relationship': 'Relationship Status',
      'work': 'Work Information',
      'location': 'Location',
      'education': 'Education',
      'verified': 'Verification',
      'Cover Picture': 'Cover Photo',
      'Biography': 'Biography',
      'Work Information': 'Work Information',
    };
    return translations[label] ?? translations[field] ?? label;
  }

  // Get icon for field type
  IconData get icon {
    switch (field) {
      case 'profile_picture':
        return Icons.account_circle;
      case 'cover_picture':
        return Icons.photo_library;
      case 'biography':
        return Icons.description;
      case 'birthdate':
        return Icons.cake;
      case 'relationship':
        return Icons.favorite;
      case 'work':
        return Icons.work;
      case 'location':
        return Icons.location_on;
      case 'education':
        return Icons.school;
      case 'verified':
        return Icons.verified;
      default:
        return Icons.edit;
    }
  }
}
