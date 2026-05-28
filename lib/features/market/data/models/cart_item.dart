import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

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
  /// 
  /// البنية الحقيقية للـ API:
  /// ```json
  /// {
  ///   "id": 47,
  ///   "product_post_id": 351,
  ///   "quantity": 4,
  ///   "post": {
  ///     "post_id": 351,
  ///     "text": "Product description",
  ///     "user_name": "seller_name",
  ///     "user_picture": "avatar.jpg",
  ///     "product": {
  ///       "name": "Product Name",
  ///       "price": 99.99
  ///     }
  ///   }
  /// }
  /// ```
  factory CartItem.fromJson(Map<String, dynamic> json) {
    // البيانات موجودة في post object وليس product مباشرة
    final post = json['post'] as Map<String, dynamic>? ?? {};
    
    // المنتج داخل post.product
    final product = post['product'] as Map<String, dynamic>? ?? {};
    
    // Get product name
    final productName = product['name']?.toString() ?? 
                       post['text']?.toString() ?? 
                       'منتج بدون اسم';
    
    // Get price from product.price
    var priceValue = product['price'];
    
    // Fallback to post_price if product.price not found
    if (priceValue == null || priceValue == 0 || priceValue == '0') {
      priceValue = post['post_price'];
    }
    
    double price = 0;
    if (priceValue != null && priceValue != 0 && priceValue != '0') {
      if (priceValue is String) {
        var cleanPrice = priceValue.replaceAll(RegExp(r'[^\d.]'), '');
        price = double.tryParse(cleanPrice) ?? 0;
      } else if (priceValue is num) {
        price = priceValue.toDouble();
      }
    }
    
    final quantity = int.tryParse(json['quantity']?.toString() ?? '1') ?? 1;
    final total = (quantity * price).toStringAsFixed(2);
    
    // Get product image from multiple possible sources
    String productPicture = '';
    if (post['og_image'] != null && post['og_image'].toString().isNotEmpty) {
      productPicture = post['og_image'].toString();
    } else if (product['image'] != null && product['image'].toString().isNotEmpty) {
      productPicture = product['image'].toString();
    } else if (post['post_cover'] != null && post['post_cover'].toString().isNotEmpty) {
      productPicture = post['post_cover'].toString();
    } else if (post['photos'] != null && post['photos'] is List && (post['photos'] as List).isNotEmpty) {
      final firstPhoto = (post['photos'] as List).first as Map<String, dynamic>?;
      if (firstPhoto?['source'] != null) {
        productPicture = 'https://sngine.fluttercrafters.com/content/uploads/${firstPhoto!['source']}';
      }
    }
    
    // Get seller info from post
    final sellerId = post['user_id']?.toString() ?? '';
    final sellerName = post['user_name']?.toString() ?? 
                      post['post_author_name']?.toString() ?? 
                      'بائع';
    final sellerPicture = post['user_picture']?.toString() ?? 
                         post['post_author_picture']?.toString() ?? '';
    
    return CartItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_post_id']?.toString() ?? 
                post['post_id']?.toString() ?? '',
      productName: productName,
      productPrice: price.toStringAsFixed(2),
      quantity: quantity,
      total: total,
      productPicture: productPicture,
      seller: CartSeller(
        userId: sellerId,
        userName: sellerName,
        userPicture: sellerPicture,
      ),
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