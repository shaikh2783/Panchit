import 'package:equatable/equatable.dart';

/// نموذج اللغة
class Language extends Equatable {
  final String languageId;
  final String languageName;
  final String languageCode;

  const Language({
    required this.languageId,
    required this.languageName,
    required this.languageCode,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      languageId: json['language_id']?.toString() ?? '',
      languageName: json['title']?.toString() ?? json['title_native']?.toString() ?? '',
      languageCode: json['code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language_id': languageId,
      'language_name': languageName,
      'language_code': languageCode,
    };
  }

  @override
  List<Object?> get props => [languageId, languageName, languageCode];
}
