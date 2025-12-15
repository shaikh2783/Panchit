import 'package:equatable/equatable.dart';
/// Order Item Model - منتج في الطلب
class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final String productPrice;
  final int quantity;
  final String total;
  final String productPicture;
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.total,
    required this.productPicture,
  });
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'].toString(),
      productName: json['product_name'].toString(),
      productPrice: json['product_price'].toString(),
      quantity: int.parse(json['quantity'].toString()),
      total: json['total'].toString(),
      productPicture: json['product_picture']?.toString() ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'product_price': productPrice,
      'quantity': quantity,
      'total': total,
      'product_picture': productPicture,
    };
  }
  @override
  List<Object?> get props => [
        productId,
        productName,
        productPrice,
        quantity,
        total,
        productPicture,
      ];
}
