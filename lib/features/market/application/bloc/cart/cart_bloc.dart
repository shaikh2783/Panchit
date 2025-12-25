import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../../../domain/market_repository.dart';
import '../../../data/models/models.dart';

/// Cart Bloc
/// 
/// يدير حالة سلة التسوق باستخدام Bloc pattern.
/// يتعامل مع جميع العمليات: جلب، إضافة، تحديث، حذف، مسح.
/// 
/// الاستخدام:
/// ```dart
/// // في main.dart أو app.dart
/// BlocProvider(
///   create: (context) => CartBloc(marketRepository)..add(LoadCartEvent()),
///   child: CartPage(),
/// )
/// 
/// // في الصفحة
/// context.read<CartBloc>().add(AddToCartEvent(productId: '123'));
/// 
/// // في UI
/// BlocBuilder<CartBloc, CartState>(
///   builder: (context, state) {
///     if (state is CartLoaded) {
///       return ListView.builder(...);
///     }
///     return LoadingIndicator();
///   },
/// )
/// ```
/// 
/// Events:
/// - [LoadCartEvent]: جلب السلة
/// - [AddToCartEvent]: إضافة منتج
/// - [UpdateCartItemEvent]: تحديث كمية
/// - [RemoveFromCartEvent]: حذف منتج
/// - [ClearCartEvent]: مسح السلة
/// - [RefreshCartEvent]: تحديث البيانات
/// 
/// States:
/// - [CartInitial]: حالة أولية
/// - [CartLoading]: جاري التحميل
/// - [CartLoaded]: تم التحميل بنجاح
/// - [CartOperationInProgress]: عملية قيد التنفيذ
/// - [CartOperationSuccess]: نجاح العملية
/// - [CartError]: خطأ
/// - [CartEmpty]: سلة فارغة
class CartBloc extends Bloc<CartEvent, CartState> {
  final MarketRepository _repository;

  /// Creates a CartBloc instance
  /// 
  /// Parameters:
  /// - [repository]: Market repository للتعامل مع البيانات
  CartBloc(this._repository) : super(const CartInitial()) {
    // Register event handlers
    on<LoadCartEvent>(_onLoadCart);
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateCartItemEvent>(_onUpdateCartItem);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<ClearCartEvent>(_onClearCart);
    on<RefreshCartEvent>(_onRefreshCart);
    on<CheckoutCartEvent>(_onCheckoutCart);
  }

  /// Handle load cart event
  Future<void> _onLoadCart(
    LoadCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      emit(const CartLoading());

      final cart = await _repository.getCart();

      if (cart.isEmpty) {
        emit(const CartEmpty());
      } else {
        emit(CartLoaded(cart));
      }
    } catch (e) {
      emit(CartError(message: 'فشل في جلب سلة التسوق: ${e.toString()}'));
    }
  }

  /// Handle add to cart event
  Future<void> _onAddToCart(
    AddToCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      // Get current cart for optimistic update
      final currentCart = state is CartLoaded
          ? (state as CartLoaded).cart
          : state is CartOperationSuccess
              ? (state as CartOperationSuccess).cart
              : Cart.empty();

      emit(CartOperationInProgress(
        currentCart: currentCart,
        operation: 'adding',
      ));

      await _repository.addToCart(
        productId: event.productId,
        quantity: event.quantity,
      );

      // Reload cart to get updated data
      final updatedCart = await _repository.getCart();

      emit(CartOperationSuccess(
        cart: updatedCart,
        message: 'تمت إضافة المنتج إلى السلة',
      ));

      // Auto-transition to loaded state
      emit(CartLoaded(updatedCart));
    } catch (e) {
      final currentCart = state is CartOperationInProgress
          ? (state as CartOperationInProgress).currentCart
          : null;

      emit(CartError(
        message: 'فشل في إضافة المنتج: ${e.toString()}',
        currentCart: currentCart,
      ));

      // Return to previous state if possible
      if (currentCart != null && currentCart.isNotEmpty) {
        emit(CartLoaded(currentCart));
      }
    }
  }

  /// Handle update cart item event
  Future<void> _onUpdateCartItem(
    UpdateCartItemEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      final currentCart = state is CartLoaded
          ? (state as CartLoaded).cart
          : Cart.empty();

      emit(CartOperationInProgress(
        currentCart: currentCart,
        operation: 'updating',
      ));

      await _repository.updateCartItem(
        cartId: event.cartId,
        quantity: event.quantity,
      );

      final updatedCart = await _repository.getCart();

      emit(CartOperationSuccess(
        cart: updatedCart,
        message: 'تم تحديث الكمية',
      ));

      emit(CartLoaded(updatedCart));
    } catch (e) {
      final currentCart = state is CartOperationInProgress
          ? (state as CartOperationInProgress).currentCart
          : null;

      emit(CartError(
        message: 'فشل في تحديث الكمية: ${e.toString()}',
        currentCart: currentCart,
      ));

      if (currentCart != null) {
        emit(CartLoaded(currentCart));
      }
    }
  }

  /// Handle remove from cart event
  Future<void> _onRemoveFromCart(
    RemoveFromCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      final currentCart = state is CartLoaded
          ? (state as CartLoaded).cart
          : Cart.empty();

      emit(CartOperationInProgress(
        currentCart: currentCart,
        operation: 'removing',
      ));

      await _repository.removeFromCart(event.cartId);

      final updatedCart = await _repository.getCart();

      emit(CartOperationSuccess(
        cart: updatedCart,
        message: 'تم حذف المنتج من السلة',
      ));

      if (updatedCart.isEmpty) {
        emit(const CartEmpty());
      } else {
        emit(CartLoaded(updatedCart));
      }
    } catch (e) {
      final currentCart = state is CartOperationInProgress
          ? (state as CartOperationInProgress).currentCart
          : null;

      emit(CartError(
        message: 'فشل في حذف المنتج: ${e.toString()}',
        currentCart: currentCart,
      ));

      if (currentCart != null) {
        emit(CartLoaded(currentCart));
      }
    }
  }

  /// Handle clear cart event
  Future<void> _onClearCart(
    ClearCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      final currentCart = state is CartLoaded
          ? (state as CartLoaded).cart
          : Cart.empty();

      emit(CartOperationInProgress(
        currentCart: currentCart,
        operation: 'clearing',
      ));

      await _repository.clearCart();

      emit(CartOperationSuccess(
        cart: Cart.empty(),
        message: 'تم مسح السلة',
      ));

      emit(const CartEmpty());
    } catch (e) {
      final currentCart = state is CartOperationInProgress
          ? (state as CartOperationInProgress).currentCart
          : null;

      emit(CartError(
        message: 'فشل في مسح السلة: ${e.toString()}',
        currentCart: currentCart,
      ));

      if (currentCart != null) {
        emit(CartLoaded(currentCart));
      }
    }
  }

  /// Handle refresh cart event
  Future<void> _onRefreshCart(
    RefreshCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      final cart = await _repository.getCart();

      if (cart.isEmpty) {
        emit(const CartEmpty());
      } else {
        emit(CartLoaded(cart));
      }
    } catch (e) {
      emit(CartError(message: 'فشل في تحديث السلة: ${e.toString()}'));
    }
  }

  /// Handle checkout cart event
  Future<void> _onCheckoutCart(
    CheckoutCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      // Show loading while processing
      emit(const CartLoading());

      // Call checkout API with shipping address
      final result = await _repository.checkout(
        address: event.shippingAddress,
        notes: event.notes.isNotEmpty ? event.notes : null,
        paymentMethod: event.paymentMethod,
      );

      // Check if orders were created
      if (result.totalOrders > 0 && result.orders.isNotEmpty) {
        // Get first order ID
        final orderId = result.orders.first.orderId;
        
        emit(CartCheckoutSuccess(
          orderId: orderId,
          message: 'تم تقديم ${result.totalOrders} طلب بنجاح',
        ));
      } else {
        emit(const CartCheckoutError('فشل في إتمام الطلب'));
      }
    } catch (e) {
      emit(CartCheckoutError('فشل في إتمام الطلب: ${e.toString()}'));
    }
  }
}