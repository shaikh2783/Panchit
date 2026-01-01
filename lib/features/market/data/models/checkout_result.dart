import 'package:equatable/equatable.dart';

/// Checkout Result Model - نتيجة عملية الدفع
/// 
/// حسب التوثيق الجديد، API يرجع:
/// ```json
/// {
///   "status": "success",
///   "message": "Checkout completed successfully",
///   "data": {
///     "orders_collection_id": "5f7a3e8c1b2d9",
///     "total": 2029.97
///   }
/// }
/// ```
class CheckoutResult extends Equatable {
  final String ordersCollectionId;
  final String totalAmount;

  const CheckoutResult({
    required this.ordersCollectionId,
    required this.totalAmount,
  });

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    // API الجديد يرجع orders_collection_id و total
    final ordersCollectionId = json['orders_collection_id']?.toString() ?? '';
    final totalAmount = json['total']?.toString() ?? '0.00';

    return CheckoutResult(
      ordersCollectionId: ordersCollectionId,
      totalAmount: totalAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orders_collection_id': ordersCollectionId,
      'total': totalAmount,
    };
  }

  @override
  List<Object?> get props => [ordersCollectionId, totalAmount];
}
