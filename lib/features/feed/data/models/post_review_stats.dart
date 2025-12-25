import 'package:meta/meta.dart';

@immutable
class ReviewStatsBucket {
  const ReviewStatsBucket({required this.count, required this.percentage});

  final int count;
  final double percentage;

  factory ReviewStatsBucket.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReviewStatsBucket(count: 0, percentage: 0);
    return ReviewStatsBucket(
      count: _int(json['count']),
      percentage: _double(json['percentage']),
    );
  }

  static int _int(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _double(Object? value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

@immutable
class ReviewStats {
  const ReviewStats({
    required this.total,
    required this.average,
    required this.star5,
    required this.star4,
    required this.star3,
    required this.star2,
    required this.star1,
  });

  final int total;
  final double average;
  final ReviewStatsBucket star5;
  final ReviewStatsBucket star4;
  final ReviewStatsBucket star3;
  final ReviewStatsBucket star2;
  final ReviewStatsBucket star1;

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      total: _int(json['total']),
      average: _double(json['average']),
      star5: ReviewStatsBucket.fromJson(json['5_stars'] as Map<String, dynamic>?),
      star4: ReviewStatsBucket.fromJson(json['4_stars'] as Map<String, dynamic>?),
      star3: ReviewStatsBucket.fromJson(json['3_stars'] as Map<String, dynamic>?),
      star2: ReviewStatsBucket.fromJson(json['2_stars'] as Map<String, dynamic>?),
      star1: ReviewStatsBucket.fromJson(json['1_stars'] as Map<String, dynamic>?),
    );
  }

  static int _int(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _double(Object? value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
