import 'package:flutter/material.dart';

class TwoFactorStatus {
  final bool systemEnabled;
  final String systemType; // google, email, sms
  final bool userEnabled;
  final String? userType;
  final bool canEnable;
  final List<String> requirements;
  final String? googleQrCode;
  final String? googleSecret;

  TwoFactorStatus({
    required this.systemEnabled,
    required this.systemType,
    required this.userEnabled,
    this.userType,
    required this.canEnable,
    required this.requirements,
    this.googleQrCode,
    this.googleSecret,
  });

  factory TwoFactorStatus.fromJson(Map<String, dynamic> json) {
    return TwoFactorStatus(
      systemEnabled: json['system_enabled'] ?? false,
      systemType: json['system_type'] ?? 'google',
      userEnabled: json['user_enabled'] ?? false,
      userType: json['user_type'],
      canEnable: json['can_enable'] ?? false,
      requirements: List<String>.from(json['requirements'] ?? []),
      googleQrCode: json['google_qr_code'],
      googleSecret: json['google_secret'],
    );
  }

  String get typeDisplayName {
    switch (systemType) {
      case 'google':
        return 'Google Authenticator';
      case 'email':
        return 'Email';
      case 'sms':
        return 'SMS';
      default:
        return systemType;
    }
  }

  String get typeDescription {
    switch (systemType) {
      case 'google':
        return 'استخدم تطبيق Google Authenticator لتوليد رموز التحقق';
      case 'email':
        return 'سيتم إرسال رمز التحقق إلى بريدك الإلكتروني';
      case 'sms':
        return 'سيتم إرسال رمز التحقق إلى رقم هاتفك';
      default:
        return '';
    }
  }

  IconData get typeIcon {
    switch (systemType) {
      case 'google':
        return Icons.security;
      case 'email':
        return Icons.email;
      case 'sms':
        return Icons.sms;
      default:
        return Icons.lock;
    }
  }
}
