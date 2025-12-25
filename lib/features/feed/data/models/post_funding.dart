class PostFunding {
  PostFunding({
    required this.fundingId,
    required this.postId,
    required this.title,
    required this.amount,
    required this.raisedAmount,
    required this.totalDonations,
    this.coverImage,
    this.fundingCompletion = 0,
  });

  final String fundingId;
  final String postId;
  final String title;
  final double amount;        // المبلغ المطلوب
  final double raisedAmount;  // المبلغ المجمع
  final int totalDonations;   // عدد التبرعات
  final String? coverImage;   // صورة الحملة
  final double fundingCompletion; // نسبة الإنجاز (0-100)

  // حساب النسبة المئوية للتبرعات
  double get completionPercentage {
    if (amount <= 0) return 0;
    return (raisedAmount / amount * 100).clamp(0, 100);
  }

  // حساب المبلغ المتبقي
  double get remainingAmount {
    return (amount - raisedAmount).clamp(0, amount);
  }

  // التحقق من اكتمال الهدف
  bool get isGoalReached {
    return raisedAmount >= amount;
  }

  factory PostFunding.fromJson(Map<String, dynamic> json) {
    return PostFunding(
      fundingId: json['funding_id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      raisedAmount: double.tryParse(json['raised_amount']?.toString() ?? '0') ?? 0,
      totalDonations: int.tryParse(json['total_donations']?.toString() ?? '0') ?? 0,
      coverImage: json['cover_image']?.toString(),
      fundingCompletion: double.tryParse(json['funding_completion']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'funding_id': fundingId,
      'post_id': postId,
      'title': title,
      'amount': amount.toString(),
      'raised_amount': raisedAmount.toString(),
      'total_donations': totalDonations.toString(),
      'cover_image': coverImage,
      'funding_completion': fundingCompletion,
    };
  }

  static PostFunding? maybeFromJson(Object? value) {
    if (value is Map<String, dynamic>) {
      return PostFunding.fromJson(value);
    }
    return null;
  }

  PostFunding copyWith({
    String? fundingId,
    String? postId,
    String? title,
    double? amount,
    double? raisedAmount,
    int? totalDonations,
    String? coverImage,
    double? fundingCompletion,
  }) {
    return PostFunding(
      fundingId: fundingId ?? this.fundingId,
      postId: postId ?? this.postId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      raisedAmount: raisedAmount ?? this.raisedAmount,
      totalDonations: totalDonations ?? this.totalDonations,
      coverImage: coverImage ?? this.coverImage,
      fundingCompletion: fundingCompletion ?? this.fundingCompletion,
    );
  }

  @override
  String toString() {
    return 'PostFunding(fundingId: $fundingId, title: $title, amount: $amount, raisedAmount: $raisedAmount, completion: ${completionPercentage.toStringAsFixed(1)}%)';
  }
}