import 'package:equatable/equatable.dart';

/// Cart Item Model - منتج في سلة التسوق
/// 
/// يمثل منتج واحد مضاف إلى سلة التسوق مع تفاصيله الكاملة.
/// يتضمن معلومات المنتج، الكمية، السعر، والبائع.
/// 
/// الاستخدام:
/// ```dart
/// final item = CartItem.fromJson(json);


/// ```
/// 
/// Properties:
/// - [id]: معرف العنصر في السلة (للحذف والتعديل)
/// - [productId]: معرف المنتج الأصلي
/// - [productName]: اسم المنتج
/// - [productPrice]: سعر الوحدة
/// - [quantity]: الكمية المطلوبة
/// - [total]: الإجمالي (price × quantity)
/// - [productPicture]: صورة المنتج
/// - [seller]: معلومات البائع
/// 
/// See also:
/// - [Cart]: سلة التسوق الكاملة
/// - [CartSeller]: معلومات البائع
class CartItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String productPrice;
  final int quantity;
  final String total;
  final String productPicture;
  final CartSeller seller;

  /// Creates a CartItem instance
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.total,
    required this.productPicture,
    required this.seller,
  });

  /// Creates CartItem from JSON response
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'].toString(),
      productId: json['product_id'].toString(),
      productName: json['product_name'].toString(),
      productPrice: json['product_price'].toString(),
      quantity: int.parse(json['quantity'].toString()),
      total: json['total'].toString(),
      productPicture: json['product_picture']?.toString() ?? '',
      seller: CartSeller.fromJson(json['seller'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_price': productPrice,
      'quantity': quantity,
      'total': total,
      'product_picture': productPicture,
      'seller': seller.toJson(),
    };
  }

  /// Creates a copy with modified fields
  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productPrice,
    int? quantity,
    String? total,
    String? productPicture,
    CartSeller? seller,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
      productPicture: productPicture ?? this.productPicture,
      seller: seller ?? this.seller,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        productPrice,
        quantity,
        total,
        productPicture,
        seller,
      ];
}

/// Cart Seller Model - معلومات البائع
/// 
/// يحتوي على المعلومات الأساسية للبائع المرتبط بكل منتج في السلة.
/// 
/// Properties:
/// - [userId]: معرف البائع
/// - [userName]: اسم المستخدم
/// - [userPicture]: صورة الملف الشخصي
class CartSeller extends Equatable {
  final String userId;
  final String userName;
  final String userPicture;

  const CartSeller({
    required this.userId,
    required this.userName,
    required this.userPicture,
  });

  factory CartSeller.fromJson(Map<String, dynamic> json) {
    return CartSeller(
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      userPicture: json['user_picture']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_picture': userPicture,
    };
  }

  @override
  List<Object?> get props => [userId, userName, userPicture];
}
