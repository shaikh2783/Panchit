// Bank Transfer Model - سجل التحويلات البنكية

enum BankTransferStatus {
  pending('0'),
  approved('1'),
  declined('-1');

  final String value;
  const BankTransferStatus(this.value);

  String get statusText {
    switch (this) {
      case BankTransferStatus.pending:
        return 'Pending';
      case BankTransferStatus.approved:
        return 'Approved';
      case BankTransferStatus.declined:
        return 'Declined';
    }
  }

  static BankTransferStatus fromValue(dynamic value) {
    final strValue = value.toString();
    return BankTransferStatus.values.firstWhere(
      (e) => e.value == strValue,
      orElse: () => BankTransferStatus.pending,
    );
  }
}

class BankTransfer {
  final int transferId;
  final String handle;
  final String typeText;
  final double amount;
  final double price;
  final String? bankReceipt;
  final String time;
  final int? timeUnix;
  final BankTransferStatus status;
  
  // Optional fields based on handle
  final int? packageId;
  final String? packageName;
  final double? packagePrice;
  final int? postId;
  final int? planId;
  final int? movieId;
  final int? ordersCollectionId;

  BankTransfer({
    required this.transferId,
    required this.handle,
    required this.typeText,
    required this.amount,
    required this.price,
    this.bankReceipt,
    required this.time,
    this.timeUnix,
    required this.status,
    this.packageId,
    this.packageName,
    this.packagePrice,
    this.postId,
    this.planId,
    this.movieId,
    this.ordersCollectionId,
  });

  factory BankTransfer.fromJson(Map<String, dynamic> json) {
    return BankTransfer(
      transferId: json['transfer_id'] is int ? json['transfer_id'] : int.tryParse(json['transfer_id']?.toString() ?? '0') ?? 0,
      handle: json['handle']?.toString() ?? '',
      typeText: json['type_text']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      price: _toDouble(json['price']),
      bankReceipt: json['bank_receipt']?.toString(),
      time: json['time']?.toString() ?? '',
      timeUnix: json['time_unix'] is int ? json['time_unix'] : int.tryParse(json['time_unix']?.toString() ?? ''),
      status: BankTransferStatus.fromValue(json['status']),
      packageId: json['package_id'] is int ? json['package_id'] : int.tryParse(json['package_id']?.toString() ?? ''),
      packageName: json['package_name']?.toString(),
      packagePrice: _toDouble(json['package_price']),
      postId: json['post_id'] is int ? json['post_id'] : int.tryParse(json['post_id']?.toString() ?? ''),
      planId: json['plan_id'] is int ? json['plan_id'] : int.tryParse(json['plan_id']?.toString() ?? ''),
      movieId: json['movie_id'] is int ? json['movie_id'] : int.tryParse(json['movie_id']?.toString() ?? ''),
      ordersCollectionId: json['orders_collection_id'] is int ? json['orders_collection_id'] : int.tryParse(json['orders_collection_id']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transfer_id': transferId,
      'handle': handle,
      'type_text': typeText,
      'amount': amount,
      'price': price,
      'bank_receipt': bankReceipt,
      'time': time,
      'time_unix': timeUnix,
      'status': status.value,
      'package_id': packageId,
      'package_name': packageName,
      'package_price': packagePrice,
      'post_id': postId,
      'plan_id': planId,
      'movie_id': movieId,
      'orders_collection_id': ordersCollectionId,
    };
  }

  /// الحصول على أيقونة مناسبة للـ handle
  String get handleIcon {
    switch (handle) {
      case 'wallet':
        return '💳';
      case 'packages':
        return '📦';
      case 'donate':
        return '❤️';
      case 'subscribe':
        return '📺';
      case 'paid_post':
        return '📝';
      case 'movies':
        return '🎬';
      case 'marketplace':
        return '🛒';
      default:
        return '💰';
    }
  }

  /// الحصول على لون مناسب للحالة
  String get statusColor {
    switch (status) {
      case BankTransferStatus.approved:
        return '#4CAF50'; // أخضر
      case BankTransferStatus.pending:
        return '#FF9800'; // برتقالي
      case BankTransferStatus.declined:
        return '#F44336'; // أحمر
    }
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
