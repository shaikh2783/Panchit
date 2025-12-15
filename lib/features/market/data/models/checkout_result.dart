import 'package:equatable/equatable.dart';
import 'order.dart';
/// Checkout Result Model - نتيجة عملية الدفع
class CheckoutResult extends Equatable {
  final List<Order> orders;
  final int totalOrders;
  final String totalAmount;
  const CheckoutResult({
    required this.orders,
    required this.totalOrders,
    required this.totalAmount,
  });
  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    final ordersList = json['orders'] as List<dynamic>? ?? [];
    return CheckoutResult(
      orders: ordersList.map((order) => Order.fromJson(order)).toList(),
      totalOrders: int.parse(json['total_orders']?.toString() ?? '0'),
      totalAmount: json['total_amount']?.toString() ?? '0.00',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'orders': orders.map((order) => order.toJson()).toList(),
      'total_orders': totalOrders,
      'total_amount': totalAmount,
    };
  }
  @override
  List<Object?> get props => [orders, totalOrders, totalAmount];
}
