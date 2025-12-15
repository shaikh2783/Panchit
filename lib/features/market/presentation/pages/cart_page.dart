import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../data/models/models.dart';
import '../../application/bloc/cart/cart_bloc.dart';
import '../../application/bloc/cart/cart_event.dart';
import '../../application/bloc/cart/cart_state.dart';
import '../widgets/cart_item_card.dart';
import 'checkout_page.dart';
/// Cart Page - صفحة سلة التسوق
/// 
/// عرض منتجات السلة مع إمكانية التعديل والحذف
class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);
  @override
  State<CartPage> createState() => _CartPageState();
}
class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    // Ensure fresh load every time CartPage opens (no cache)
    // If bloc is in initial state, trigger loading.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<CartBloc>();
      if (bloc.state is CartInitial || bloc.state is CartError || bloc.state is CartEmpty) {
        bloc.add(const LoadCartEvent());
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('market_cart'.tr),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              final hasItems = (state is CartLoaded && state.cart.items.isNotEmpty) ||
                  (state is CartOperationInProgress && state.currentCart.items.isNotEmpty) ||
                  (state is CartOperationSuccess && state.cart.items.isNotEmpty);
              if (hasItems) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'market_clear_cart'.tr,
                  onPressed: () => _showClearCartDialog(context),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartInitial || state is CartLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CartError) {
            return _buildError(context, state.message);
          }
          if (state is CartOperationInProgress) {
            // Show current cart while operation is in progress
            if (state.currentCart.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return Stack(
              children: [
                _buildCartContent(context, state.currentCart),
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(),
                ),
              ],
            );
          }
          if (state is CartOperationSuccess) {
            if (state.cart.items.isEmpty) {
              return _buildEmptyCart(context);
            }
            return _buildCartContent(context, state.cart);
          }
          if (state is CartLoaded) {
            if (state.cart.items.isEmpty) {
              return _buildEmptyCart(context);
            }
            return _buildCartContent(context, state.cart);
          }
          return const SizedBox();
        },
      ),
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoaded && state.cart.items.isNotEmpty) {
            return _buildCheckoutBar(context, state.cart);
          }
          if (state is CartOperationInProgress && state.currentCart.items.isNotEmpty) {
            return _buildCheckoutBar(context, state.currentCart);
          }
          if (state is CartOperationSuccess && state.cart.items.isNotEmpty) {
            return _buildCheckoutBar(context, state.cart);
          }
          return const SizedBox();
        },
      ),
    );
  }
  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('error'.tr, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<CartBloc>().add(const LoadCartEvent());
            },
            child: Text('try_again'.tr),
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'market_cart_empty'.tr,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'market_empty_cart_subtitle'.tr,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
            },
            icon: const Icon(Icons.shopping_bag),
            label: Text('market_browse_products'.tr),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCartContent(BuildContext context, Cart cart) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<CartBloc>().add(const RefreshCartEvent());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cart Items
          ...cart.items.map((item) => CartItemCard(
                item: item,
                onQuantityChanged: (quantity) {
                  context.read<CartBloc>().add(
                        UpdateCartItemEvent(
                          cartId: item.id,
                          quantity: quantity,
                        ),
                      );
                },
                onRemove: () {
                  context.read<CartBloc>().add(
                        RemoveFromCartEvent(item.id),
                      );
                },
              )),
          const SizedBox(height: 16),
          // Summary Card
          _buildSummaryCard(cart),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }
  Widget _buildSummaryCard(Cart cart) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'market_order_summary'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'market_items'.tr,
              '${cart.items.length}',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'market_total'.tr,
              cart.formattedTotal,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }
  Widget _buildCheckoutBar(BuildContext context, Cart cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'market_total'.tr}:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  cart.formattedTotal,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.to(() => const CheckoutPage());
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'market_checkout'.tr,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('market_clear_cart'.tr),
        content: Text('market_clear_cart_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              context.read<CartBloc>().add(const ClearCartEvent());
              Navigator.pop(dialogContext);
            },
            child: Text(
              'market_clear_cart'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
