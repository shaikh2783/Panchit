/// نموذج فئة الإبلاغ من الـ API
class ReportCategoryModel {
  final int id;
  final String name;
  final String description;
  const ReportCategoryModel({
    required this.id,
    required this.name,
    required this.description,
  });
  factory ReportCategoryModel.fromJson(Map<String, dynamic> json) {
    return ReportCategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
/// نموذج أسباب الإبلاغ
class ReportReason {
  final int id;  // تغيير من String إلى int
  final String title;
  final String description;
  final String icon;
  const ReportReason({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}
/// فئات الإبلاغ
enum ReportCategory {
  spam('spam', 'Spam'),
  harassment('harassment', 'Harassment & Bullying'),
  inappropriate('inappropriate', 'Inappropriate Content'),
  violence('violence', 'Violence & Threats'),
  copyright('copyright', 'Copyright Violation'),
  misinformation('misinformation', 'Misinformation'),
  other('other', 'Other');
  const ReportCategory(this.id, this.title);
  final String id;
  final String title;
}
/// أسباب الإبلاغ المحددة مسبقاً
class ReportReasons {
  static const List<ReportReason> reasons = [
    // Spam
    ReportReason(
      id: 1,
      title: 'Spam or unwanted content',
      description: 'This post contains spam, scam, or unwanted content',
      icon: '🚫',
    ),
    ReportReason(
      id: 2,
      title: 'Repetitive content',
      description: 'This post is being posted repeatedly',
      icon: '🔄',
    ),
    // Harassment
    ReportReason(
      id: 3,
      title: 'Harassment or bullying',
      description: 'This post contains harassment, bullying, or intimidation',
      icon: '😢',
    ),
    ReportReason(
      id: 4,
      title: 'Hate speech',
      description: 'This post promotes hatred against individuals or groups',
      icon: '💬',
    ),
    // Inappropriate Content
    ReportReason(
      id: 5,
      title: 'Nudity or sexual content',
      description: 'This post contains inappropriate nudity or sexual content',
      icon: '🔞',
    ),
    ReportReason(
      id: 6,
      title: 'Disturbing content',
      description: 'This post contains disturbing or graphic content',
      icon: '⚠️',
    ),
    // Violence
    ReportReason(
      id: 7,
      title: 'Violence or threats',
      description: 'This post contains threats of violence or promotes violence',
      icon: '🔪',
    ),
    // Copyright
    ReportReason(
      id: 8,
      title: 'Copyright violation',
      description: 'This post violates copyright or intellectual property rights',
      icon: '©️',
    ),
    // Misinformation
    ReportReason(
      id: 9,
      title: 'False information',
      description: 'This post contains false or misleading information',
      icon: '❌',
    ),
    // Other
    ReportReason(
      id: 10,
      title: 'Something else',
      description: 'This post violates community guidelines in another way',
      icon: '🤔',
    ),
  ];
}
