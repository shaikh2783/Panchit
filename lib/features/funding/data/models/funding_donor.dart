class FundingDonor {
  final String donorId;
  final String donorName;
  final String? donorPicture;
  final double amount;
  final String time;

  FundingDonor({
    required this.donorId,
    required this.donorName,
    this.donorPicture,
    required this.amount,
    required this.time,
  });

  factory FundingDonor.fromJson(Map<String, dynamic> json) {
    return FundingDonor(
      donorId: json['user_id']?.toString() ?? json['donor_id']?.toString() ?? '',
      donorName: json['user_name']?.toString() ?? json['donor_name']?.toString() ?? '',
      donorPicture: json['user_picture']?.toString() ?? json['donor_picture']?.toString(),
      amount: double.tryParse(
                (json['donation_amount'] ?? json['amount'])?.toString() ?? '0')
              ?? 0,
      time: json['time']?.toString() 
            ?? json['donation_time']?.toString() 
            ?? json['created_time']?.toString() 
            ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'donor_id': donorId,
        'donor_name': donorName,
        if (donorPicture != null) 'donor_picture': donorPicture,
        'amount': amount,
        'time': time,
      };
}
