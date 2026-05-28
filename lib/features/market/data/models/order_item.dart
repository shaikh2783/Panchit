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
      productId: json['product_id']?.toString() ?? '0',
      productName: json['product_name']?.toString() ?? 'Unknown Product',
      productPrice: json['product_price']?.toString() ?? '0',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      total: json['total']?.toString() ?? '0',
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
