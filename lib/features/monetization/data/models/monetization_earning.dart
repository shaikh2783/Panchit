class MonetizationEarning {
  final String id;
  final String subscriberId;
  final String nodeId;
  final String nodeType;
  final String planId;
  final double price;
  final double commission;
  final double earning;
  final String createdTime;
  final String userId;
  final String userName;
  final String userFullname;
  final String userGender;
  final String userPicture;
  final bool userVerified;

  MonetizationEarning({
    required this.id,
    required this.subscriberId,
    required this.nodeId,
    required this.nodeType,
    required this.planId,
    required this.price,
    required this.commission,
    required this.earning,
    required this.createdTime,
    required this.userId,
    required this.userName,
    required this.userFullname,
    required this.userGender,
    required this.userPicture,
    required this.userVerified,
  });

  factory MonetizationEarning.fromJson(Map<String, dynamic> json) {
    return MonetizationEarning(
      id: json['id'] ?? '',
      subscriberId: json['subscriber_id'] ?? '',
      nodeId: json['node_id'] ?? '',
      nodeType: json['node_type'] ?? '',
      planId: json['plan_id'] ?? '',
      price: double.parse(json['price']?.toString() ?? '0'),
      commission: double.parse(json['commission']?.toString() ?? '0'),
      earning: double.parse(json['earning']?.toString() ?? '0'),
      createdTime: json['created_time'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userFullname: json['user_fullname'] ?? '',
      userGender: json['user_gender'] ?? '',
      userPicture: json['user_picture'] ?? '',
      userVerified: json['user_verified'] == '1',
    );
  }
}
