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
/// تصميم احترافي وحديث مع animations
class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<CartBloc>();
      if (bloc.state is CartInitial || bloc.state is CartError) {
        bloc.add(const LoadCartEvent());
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : Colors.grey[50],
      appBar: _buildAppBar(context, isDark),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartInitial || state is CartLoading) {
            return _buildLoadingState();
          }

          if (state is CartError) {
            return _buildErrorState(context, state.message);
          }

          if (state is CartEmpty ||
              (state is CartLoaded && state.cart.items.isEmpty) ||
              (state is CartOperationSuccess && state.cart.items.isEmpty)) {
            return _buildEmptyState(context);
          }

          if (state is CartLoaded && state.cart.items.isNotEmpty) {
            return _buildCartContent(context, state.cart);
          }

          if (state is CartOperationSuccess && state.cart.items.isNotEmpty) {
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
          if (state is CartOperationSuccess && state.cart.items.isNotEmpty) {
            return _buildCheckoutBar(context, state.cart);
          }
          // Hide checkout bar when cart is empty or in CartEmpty state
          return const SizedBox();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'shopping_cart'.tr,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              String itemCount = '0';
              if (state is CartLoaded) {
                itemCount = state.cart.items.length.toString();
              } else if (state is CartOperationSuccess) {
                itemCount = state.cart.items.length.toString();
              }
              return Text(
                '$itemCount ${'product'.tr}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              );
            },
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final hasItems = (state is CartLoaded && state.cart.items.isNotEmpty) ||
                (state is CartOperationSuccess && state.cart.items.isNotEmpty);
            
            if (hasItems) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text('clear_cart'.tr),
                        content: Text('are_you_sure_clear_cart'.tr),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text('cancel'.tr),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              context.read<CartBloc>().add(const ClearCartEvent());
                            },
                            child: Text(
                              'clear'.tr,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red[isDark ? 400 : 600],
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    final isDark = Get.isDarkMode;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.blue[isDark ? 400 : 600]!,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'loading_cart'.tr,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final isDark = Get.isDarkMode;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[isDark ? 400 : 600],
          ),
          const SizedBox(height: 16),
          Text(
            'error'.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<CartBloc>().add(const LoadCartEvent());
            },
            icon: const Icon(Icons.refresh),
            label: Text('try_again'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[isDark ? 400 : 600],
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Get.isDarkMode;
    
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[isDark ? 400 : 500]!.withOpacity(0.2),
                    Colors.blue[isDark ? 300 : 600]!.withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Colors.blue[isDark ? 400 : 600],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'your_cart_is_empty'.tr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'no_products_added'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text('explore_products'.tr),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                backgroundColor: Colors.blue[isDark ? 400 : 600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, Cart cart) {
    final isDark = Get.isDarkMode;
    
    return RefreshIndicator(
      onRefresh: () async {
        context.read<CartBloc>().add(const LoadCartEvent());
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < cart.items.length) {
                    final item = cart.items[index];
                    return BlocBuilder<CartBloc, CartState>(
                      builder: (context, state) {
                        final isLoading = state is CartOperationInProgress;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CartItemCard(
                            item: item,
                            isLoading: isLoading,
                            onQuantityChanged: (quantity) {
                              if (quantity > 0) {
                                context.read<CartBloc>().add(
                                      UpdateCartItemEvent(
                                        cartId: item.id,
                                        quantity: quantity,
                                      ),
                                    );
                              }
                            },
                            onRemove: () {
                              context.read<CartBloc>().add(
                                    RemoveFromCartEvent(item.id),
                                  );
                            },
                          ),
                        );
                      },
                    );
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildSummaryCard(context, cart, isDark),
                  );
                },
                childCount: cart.items.length + 1,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverToBoxAdapter(
              child: SizedBox.fromSize(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Cart cart, bool isDark) {
    // حساب البيانات الصحيحة من items
    int totalQuantity = 0;
    double totalPrice = 0.0;
    
    for (final item in cart.items) {
      totalQuantity += item.quantity;
      try {
        final price = double.parse(item.productPrice);
        totalPrice += (price * item.quantity);
      } catch (e) {
        // تجاهل الأخطاء في التحويل
      }
    }
    
    final formattedTotal = totalPrice.toStringAsFixed(2);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: isDark ? Colors.grey[850] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                height: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                margin: const EdgeInsets.only(bottom: 20),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'order_summary'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'number_of_products'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    '$totalQuantity ${'product'.tr}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'total'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  Text(
                    '$formattedTotal USD',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[isDark ? 400 : 600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context, Cart cart) {
    final isDark = Get.isDarkMode;
    
    // حساب البيانات الصحيحة من items
    double totalPrice = 0.0;
    
    for (final item in cart.items) {
      try {
        final price = double.parse(item.productPrice);
        totalPrice += (price * item.quantity);
      } catch (e) {
        // تجاهل الأخطاء في التحويل
      }
    }
    
    final formattedTotal = totalPrice.toStringAsFixed(2);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'total'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$formattedTotal USD',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[isDark ? 400 : 600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: BlocBuilder<CartBloc, CartState>(
                  builder: (context, state) {
                    final isLoading = state is CartOperationInProgress;
                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CheckoutPage(),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green[isDark ? 400 : 600],
                        disabledBackgroundColor: isDark ? Colors.grey[800] : Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isLoading ? 0 : 4,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.green[isDark ? 200 : 600]!,
                                ),
                              ),
                            )
                          : Text(
                              'checkout'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

