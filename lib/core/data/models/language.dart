/// Model for language
class Language {
  final int languageId;
  final String languageName;
  final String? languageCode;
  Language({
    required this.languageId,
    required this.languageName,
    this.languageCode,
  });
  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      languageId: _parseInt(json['language_id']),
      // API returns 'title' or 'title_native', not 'language_name'
      languageName: json['title']?.toString() ?? 
                   json['title_native']?.toString() ?? 
                   json['language_name']?.toString() ?? '',
      languageCode: json['code']?.toString() ?? json['language_code']?.toString(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'language_id': languageId,
      'language_name': languageName,
      if (languageCode != null) 'language_code': languageCode,
    };
  }
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
  @override
  String toString() => 'Language(id: $languageId, name: $languageName, code: $languageCode)';
}
