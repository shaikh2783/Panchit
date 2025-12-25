import 'package:equatable/equatable.dart';
import 'cart_item.dart';

/// Shopping Cart Model - سلة التسوق
/// 
/// نموذج يمثل سلة التسوق الخاصة بالمستخدم.
/// يحتوي على قائمة المنتجات المضافة مع حساب المجموع الكلي تلقائياً.
/// 
/// الاستخدام:
/// ```dart
/// final cart = Cart.fromJson(response['data']['cart']);
/// if (cart.isNotEmpty) {
///   print('عدد المنتجات: ${cart.itemsCount}');
///   print('المجموع: ${cart.total}');
/// }
/// ```
/// 
/// Properties:
/// - [items]: قائمة المنتجات في السلة
/// - [total]: المبلغ الإجمالي
/// - [itemsCount]: عدد المنتجات
/// 
/// See also:
/// - [CartItem]: عنصر منتج في السلة
/// - [MarketApiService.getCart]: للحصول على السلة من API
class Cart extends Equatable {
  final List<CartItem> items;
  final String total;
  final int itemsCount;

  /// Creates a Cart instance
  /// 
  /// Parameters:
  /// - [items]: قائمة المنتجات
  /// - [total]: المبلغ الإجمالي
  /// - [itemsCount]: عدد المنتجات
  const Cart({
    required this.items,
    required this.total,
    required this.itemsCount,
  });

  /// Creates Cart from JSON response
  /// 
  /// يتم استخدامه لتحويل response من API إلى Cart object
  /// 
  /// Example JSON:
  /// ```json
  /// {
  ///   "items": [...],
  ///   "total": "999.00",
  ///   "items_count": 3
  /// }
  /// ```
  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    
    return Cart(
      items: itemsList.map((item) => CartItem.fromJson(item)).toList(),
      total: json['total']?.toString() ?? '0.00',
      itemsCount: int.parse(json['items_count']?.toString() ?? '0'),
    );
  }

  /// Creates an empty cart
  /// 
  /// مفيد عند تهيئة السلة أو بعد مسحها
  factory Cart.empty() {
    return const Cart(
      items: [],
      total: '0.00',
      itemsCount: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'items_count': itemsCount,
    };
  }

  /// Checks if cart is empty
  /// 
  /// Returns `true` if no items in cart
  bool get isEmpty => items.isEmpty;
  
  /// Checks if cart has items
  /// 
  /// Returns `true` if cart contains at least one item
  bool get isNotEmpty => items.isNotEmpty;

  /// Get formatted total with currency
  /// 
  /// Returns total amount formatted with USD currency
  String get formattedTotal => '$total USD';

  /// Creates a copy with modified fields
  Cart copyWith({
    List<CartItem>? items,
    String? total,
    int? itemsCount,
  }) {
    return Cart(
      items: items ?? this.items,
      total: total ?? this.total,
      itemsCount: itemsCount ?? this.itemsCount,
    );
  }

  @override
  List<Object?> get props => [items, total, itemsCount];
}
