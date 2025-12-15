import 'package:equatable/equatable.dart';
import '../../../data/models/models.dart';
/// Cart States
/// 
/// جميع الحالات المتعلقة بسلة التسوق
abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}
/// Cart initial state
/// 
/// الحالة الأولية قبل جلب البيانات
class CartInitial extends CartState {
  const CartInitial();
}
/// Cart loading state
/// 
/// حالة التحميل
class CartLoading extends CartState {
  const CartLoading();
}
/// Cart loaded state
/// 
/// حالة نجاح جلب السلة
class CartLoaded extends CartState {
  final Cart cart;
  const CartLoaded(this.cart);
  @override
  List<Object?> get props => [cart];
  /// Helper getters
  bool get isEmpty => cart.isEmpty;
  bool get isNotEmpty => cart.isNotEmpty;
  int get itemsCount => cart.itemsCount;
  String get total => cart.total;
  List<CartItem> get items => cart.items;
}
/// Cart operation in progress
/// 
/// حالة أثناء تنفيذ عملية (إضافة، تحديث، حذف)
class CartOperationInProgress extends CartState {
  final Cart currentCart;
  final String operation; // 'adding', 'updating', 'removing', 'clearing'
  const CartOperationInProgress({
    required this.currentCart,
    required this.operation,
  });
  @override
  List<Object?> get props => [currentCart, operation];
}
/// Cart operation success
/// 
/// حالة نجاح العملية
class CartOperationSuccess extends CartState {
  final Cart cart;
  final String message;
  const CartOperationSuccess({
    required this.cart,
    required this.message,
  });
  @override
  List<Object?> get props => [cart, message];
}
/// Cart error state
/// 
/// حالة فشل في أي عملية
class CartError extends CartState {
  final String message;
  final Cart? currentCart; // للحفاظ على البيانات الحالية
  const CartError({
    required this.message,
    this.currentCart,
  });
  @override
  List<Object?> get props => [message, currentCart];
}
/// Cart empty state
/// 
/// حالة السلة الفارغة
class CartEmpty extends CartState {
  const CartEmpty();
}
/// Cart checkout success state
/// 
/// حالة نجاح إتمام الطلب
class CartCheckoutSuccess extends CartState {
  final String orderId;
  final String message;
  const CartCheckoutSuccess({
    required this.orderId,
    this.message = 'تم تقديم الطلب بنجاح',
  });
  @override
  List<Object?> get props => [orderId, message];
}
/// Cart checkout error state
/// 
/// حالة فشل إتمام الطلب
class CartCheckoutError extends CartState {
  final String message;
  const CartCheckoutError(this.message);
  @override
  List<Object?> get props => [message];
}
