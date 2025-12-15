import 'package:equatable/equatable.dart';
import 'order_item.dart';
import 'order_user.dart';
import 'shipping_address.dart';
/// Order Model - نموذج الطلب
/// 
/// يمثل طلب شراء كامل مع جميع التفاصيل المتعلقة به.
/// كل طلب يخص بائع واحد، وإذا كانت السلة تحتوي على منتجات من بائعين مختلفين
/// سيتم إنشاء طلب منفصل لكل بائع.
/// 
/// الاستخدام:
/// ```dart
/// final order = Order.fromJson(json);
/// 
/// 
/// 
/// 
/// ```
/// 
/// Order Status Flow:
/// 1. **pending** - قيد الانتظار (تم إنشاء الطلب)
/// 2. **processing** - قيد المعالجة (البائع يجهز الطلب)
/// 3. **shipped** - تم الشحن (في الطريق)
/// 4. **delivered** - تم التسليم (وصل للمشتري)
/// 5. **cancelled** - ملغي (تم إلغاء الطلب)
/// 
/// Properties:
/// - [orderHash]: معرف فريد للطلب (للتتبع)
/// - [orderId]: رقم الطلب في قاعدة البيانات
/// - [status]: حالة الطلب الحالية
/// - [total]: المبلغ الإجمالي
/// - [shippingAddress]: عنوان الشحن
/// - [buyer]: معلومات المشتري
/// - [seller]: معلومات البائع
/// - [items]: المنتجات في الطلب
/// 
/// See also:
/// - [OrderItem]: منتج في الطلب
/// - [OrderUser]: معلومات المستخدم
/// - [ShippingAddress]: عنوان الشحن
class Order extends Equatable {
  final String orderHash;
  final String orderId;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String total;
  final int itemsCount;
  final ShippingAddress shippingAddress;
  final String? notes;
  final OrderUser buyer;
  final OrderUser seller;
  final List<OrderItem> items;
  /// Creates an Order instance
  const Order({
    required this.orderHash,
    required this.orderId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.total,
    required this.itemsCount,
    required this.shippingAddress,
    this.notes,
    required this.buyer,
    required this.seller,
    required this.items,
  });
  /// Creates Order from JSON response
  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return Order(
      orderHash: json['order_hash'].toString(),
      orderId: json['order_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      total: json['total'].toString(),
      itemsCount: int.parse(json['items_count']?.toString() ?? '0'),
      shippingAddress: ShippingAddress.fromJson(json['shipping_address'] ?? {}),
      notes: json['notes']?.toString(),
      buyer: OrderUser.fromJson(json['buyer'] ?? {}),
      seller: OrderUser.fromJson(json['seller'] ?? {}),
      items: itemsList.map((item) => OrderItem.fromJson(item)).toList(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'order_hash': orderHash,
      'order_id': orderId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'total': total,
      'items_count': itemsCount,
      'shipping_address': shippingAddress.toJson(),
      if (notes != null) 'notes': notes,
      'buyer': buyer.toJson(),
      'seller': seller.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
  /// Status helper - checks if order is pending
  /// 
  /// Returns `true` if order status is 'pending'
  bool get isPending => status == 'pending';
  /// Status helper - checks if order is being processed
  bool get isProcessing => status == 'processing';
  /// Status helper - checks if order has been shipped
  bool get isShipped => status == 'shipped';
  /// Status helper - checks if order is delivered
  bool get isDelivered => status == 'delivered';
  /// Status helper - checks if order is cancelled
  bool get isCancelled => status == 'cancelled';
  /// Format status for display in Arabic
  /// 
  /// Converts English status to Arabic for UI display
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'قيد المعالجة';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
  @override
  List<Object?> get props => [
        orderHash,
        orderId,
        status,
        createdAt,
        updatedAt,
        total,
        itemsCount,
        shippingAddress,
        notes,
        buyer,
        seller,
        items,
      ];
}
