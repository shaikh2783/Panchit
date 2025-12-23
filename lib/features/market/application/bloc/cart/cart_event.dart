import 'package:equatable/equatable.dart';
import '../../../data/models/shipping_address.dart';

/// Cart Events
/// 
/// جميع الأحداث المتعلقة بسلة التسوق

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// Load cart event
/// 
/// حدث جلب سلة التسوق
class LoadCartEvent extends CartEvent {
  const LoadCartEvent();
}

/// Add to cart event
/// 
/// حدث إضافة منتج إلى السلة
class AddToCartEvent extends CartEvent {
  final String productId;
  final int quantity;

  const AddToCartEvent({
    required this.productId,
    this.quantity = 1,
  });

  @override
  List<Object?> get props => [productId, quantity];
}

/// Update cart item event
/// 
/// حدث تحديث كمية منتج في السلة
class UpdateCartItemEvent extends CartEvent {
  final String cartId;
  final int quantity;

  const UpdateCartItemEvent({
    required this.cartId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [cartId, quantity];
}

/// Remove from cart event
/// 
/// حدث حذف منتج من السلة
class RemoveFromCartEvent extends CartEvent {
  final String cartId;

  const RemoveFromCartEvent(this.cartId);

  @override
  List<Object?> get props => [cartId];
}

/// Clear cart event
/// 
/// حدث مسح جميع المنتجات من السلة
class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}

/// Refresh cart event
/// 
/// حدث تحديث السلة (بعد أي عملية)
class RefreshCartEvent extends CartEvent {
  const RefreshCartEvent();
}

/// Checkout cart event
/// 
/// حدث إتمام الطلب من السلة
class CheckoutCartEvent extends CartEvent {
  final ShippingAddress shippingAddress;
  final String paymentMethod;
  final String notes;

  const CheckoutCartEvent({
    required this.shippingAddress,
    required this.paymentMethod,
    this.notes = '',
  });

  @override
  List<Object?> get props => [shippingAddress, paymentMethod, notes];
}
