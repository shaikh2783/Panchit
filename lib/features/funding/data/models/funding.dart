import 'funding_author.dart';
class Funding {
  final String postId;
  final String title;
  final String description;
  final double amount;
  final double raisedAmount;
  final int fundingCompletion;
  final int totalDonations;
  final String? cover;
  final String createdTime;
  final FundingAuthor author;
  Funding({
    required this.postId,
    required this.title,
    required this.description,
    required this.amount,
    required this.raisedAmount,
    required this.fundingCompletion,
    required this.totalDonations,
    this.cover,
    required this.createdTime,
    required this.author,
  });
  factory Funding.fromJson(Map<String, dynamic> json) {
    return Funding(
      postId: json['post_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      raisedAmount: double.tryParse(json['raised_amount']?.toString() ?? '0') ?? 0,
      fundingCompletion: int.tryParse(json['funding_completion']?.toString() ?? '0') ?? 0,
      totalDonations: int.tryParse(json['total_donations']?.toString() ?? '0') ?? 0,
      cover: json['cover']?.toString(),
      createdTime: json['created_time']?.toString() ?? json['time']?.toString() ?? '',
      author: FundingAuthor.fromJson(json['author'] ?? {}),
    );
  }
  Map<String, dynamic> toJson() => {
        'post_id': postId,
        'title': title,
        'description': description,
        'amount': amount,
        'raised_amount': raisedAmount,
        'funding_completion': fundingCompletion,
        'total_donations': totalDonations,
        if (cover != null) 'cover': cover,
        'created_time': createdTime,
        'author': author.toJson(),
      };
  double get progress => amount > 0 ? (raisedAmount / amount).clamp(0.0, 1.0) : 0.0;
  double get remainingAmount => (amount - raisedAmount).clamp(0.0, amount);
}
