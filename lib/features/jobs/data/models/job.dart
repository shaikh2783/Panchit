import 'job_author.dart';
import 'job_currency.dart';
class JobCategory {
  final int categoryId;
  final int parentId;
  final String name;
  final String description;
  final int order;
  const JobCategory({
    required this.categoryId,
    required this.parentId,
    required this.name,
    required this.description,
    required this.order,
  });
  factory JobCategory.fromJson(Map<String, dynamic> json) => JobCategory(
        categoryId: json['category_id'] is String
            ? int.tryParse(json['category_id']) ?? 0
            : (json['category_id'] ?? 0) as int,
        parentId: json['category_parent_id'] is String
            ? int.tryParse(json['category_parent_id']) ?? 0
            : (json['category_parent_id'] ?? 0) as int,
        name: (json['category_name'] ?? '').toString(),
        description: (json['category_description'] ?? '').toString(),
        order: json['category_order'] is String
            ? int.tryParse(json['category_order']) ?? 0
            : (json['category_order'] ?? 0) as int,
      );
}
class Job {
  final int postId;
  final String title;
  final String location;
  final int categoryId;
  final String cover;
  final num? salaryMin;
  final JobCurrency? salaryMinCurrency;
  final num? salaryMax;
  final JobCurrency? salaryMaxCurrency;
  final String paySalaryPer;
  final String paySalaryPerMeta;
  final String type;
  final String typeMeta;
    final String description;
  final int candidatesCount;
  final String createdTime;
  final JobAuthor author;
    final bool iOwner;
    const Job({
    required this.postId,
    required this.title,
    required this.location,
    required this.categoryId,
    required this.cover,
    required this.salaryMin,
    required this.salaryMinCurrency,
    required this.salaryMax,
    required this.salaryMaxCurrency,
    required this.paySalaryPer,
    required this.paySalaryPerMeta,
    required this.type,
    required this.typeMeta,
        this.description = '',
    required this.candidatesCount,
    required this.createdTime,
    required this.author,
        this.iOwner = false,
  });
    factory Job.fromJson(Map<String, dynamic> json) => Job(
        postId: json['post_id'] is String
            ? int.tryParse(json['post_id']) ?? 0
            : (json['post_id'] ?? 0) as int,
        title: (json['title'] ?? '').toString(),
        location: (json['location'] ?? '').toString(),
        categoryId: json['category_id'] is String
            ? int.tryParse(json['category_id']) ?? 0
            : (json['category_id'] ?? 0) as int,
        cover: (json['cover'] ?? '').toString(),
        salaryMin: json['salary_minimum'] is String
            ? num.tryParse(json['salary_minimum'])
            : json['salary_minimum'] as num?,
        salaryMinCurrency: json['salary_minimum_currency'] is Map<String, dynamic>
            ? JobCurrency.fromJson(json['salary_minimum_currency'])
            : null,
        salaryMax: json['salary_maximum'] is String
            ? num.tryParse(json['salary_maximum'])
            : json['salary_maximum'] as num?,
        salaryMaxCurrency: json['salary_maximum_currency'] is Map<String, dynamic>
            ? JobCurrency.fromJson(json['salary_maximum_currency'])
            : null,
        paySalaryPer: (json['pay_salary_per'] ?? '').toString(),
        paySalaryPerMeta: (json['pay_salary_per_meta'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        typeMeta: (json['type_meta'] ?? '').toString(),
        description: ((json['message'] ?? json['description'] ?? '')).toString(),
        candidatesCount: json['candidates_count'] is String
            ? int.tryParse(json['candidates_count']) ?? 0
            : (json['candidates_count'] ?? 0) as int,
        createdTime: (json['created_time'] ?? '').toString(),
                author: JobAuthor.fromJson(json['author'] as Map<String, dynamic>),
                iOwner: json['i_owner'] == true || json['i_owner'] == 1 || json['i_owner'] == '1',
      );
}
