import '../data/models/models.dart';
import '../data/services/market_api_service.dart';

/// Market Repository
/// 
/// طبقة Repository تفصل Business Logic عن طبقة API.
/// توفر واجهة نظيفة للتعامل مع بيانات السوق.
/// 
/// المسؤوليات:
/// - تنسيق المكالمات مع API Service
/// - معالجة الأخطاء بشكل موحد
/// - تحويل البيانات من وإلى Models
/// - إدارة الـ cache (مستقبلاً)
/// 
/// الاستخدام:
/// ```dart
/// final repository = MarketRepository(marketApiService);
/// 
/// // Shopping Cart
/// final cart = await repository.getCart();
/// await repository.addToCart(productId: '123', quantity: 2);
/// 
/// // Checkout
/// final result = await repository.checkout(address: address);
/// 
/// // Orders
/// final orders = await repository.getBuyerOrders();
/// ```
/// 
/// See also:
/// - [MarketApiService]: طبقة API
/// - [Cart], [Order]: النماذج المستخدمة
class MarketRepository {
  final MarketApiService _apiService;

  /// Creates a MarketRepository instance
  /// 
  /// Parameters:
  /// - [apiService]: خدمة API للسوق
  MarketRepository(this._apiService);

  // ========================================
  // Products Methods
  // ========================================

  /// Get list of products
  /// 
  /// Retrieves products with optional filtering.
  /// 
  /// Parameters:
  /// - [categoryId]: Filter by category (optional)
  /// - [search]: Search in product name (optional)
  /// - [offset]: Pagination offset (default: 0)
  /// - [limit]: Items per page (default: 20)
  /// 
  /// Returns:
  /// - List of [Product] objects
  /// 
  /// Example:
  /// ```dart
  /// // Get all products
  /// final products = await repository.getProducts();
  /// 
  /// // Get products in category 6
  /// final phones = await repository.getProducts(categoryId: 6);
  /// 
  /// // Search for products
  /// final results = await repository.getProducts(search: 'iPhone');
  /// 
  /// // Combined filters
  /// final filtered = await repository.getProducts(
  ///   categoryId: 6,
  ///   search: 'phone',
  ///   offset: 0,
  ///   limit: 10,
  /// );
  /// ```
  Future<List<Product>> getProducts({
    int? categoryId,
    String? search,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      return await _apiService.getProducts(
        categoryId: categoryId,
        search: search,
        offset: offset,
        limit: limit,
      );
    } catch (e) {
      throw _handleError('Failed to fetch products', e);
    }
  }

  /// Get product details
  /// 
  /// Retrieves full details of a specific product.
  /// 
  /// Parameters:
  /// - [productId]: Product ID
  /// 
  /// Returns:
  /// - [Product]: Complete product details
  /// 
  /// Throws:
  /// - Exception if product not found
  /// 
  /// Example:
  /// ```dart
  /// final product = await repository.getProductDetails('351');
  /// print('${product.name} - ${product.formattedPrice}');
  /// print('البائع: ${product.seller.fullName}');
  /// ```
  Future<Product> getProductDetails(String productId) async {
    try {
      return await _apiService.getProductDetails(productId);
    } catch (e) {
      throw _handleError('Failed to fetch product details', e);
    }
  }

  /// Get my products (seller)
  ///
  /// Retrieves the authenticated seller's products with optional filters.
  Future<List<Product>> getMyProducts({
    String? search,
    String? status,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      return await _apiService.getMyProducts(
        search: search,
        status: status,
        offset: offset,
        limit: limit,
      );
    } catch (e) {
      throw _handleError('Failed to fetch my products', e);
    }
  }

  /// Create a new product listing
  ///
  /// Wraps the publisher flow for creating products.
  Future<Product> createProduct({
    required String name,
    required double price,
    required int quantity,
    required int categoryId,
    String status = 'new',
    String location = '',
    bool isDigital = false,
    String productUrl = '',
    String productFile = '',
    String description = '',
    List<Map<String, dynamic>> photos = const [],
    bool forAdult = false,
  }) async {
    try {
      return await _apiService.createProduct(
        name: name,
        price: price,
        quantity: quantity,
        categoryId: categoryId,
        status: status,
        location: location,
        isDigital: isDigital,
        productUrl: productUrl,
        productFile: productFile,
        description: description,
        photos: photos,
        forAdult: forAdult,
      );
    } catch (e) {
      throw _handleError('Failed to create product', e);
    }
  }

  // ========================================
  // Shopping Cart Methods
  // ========================================

  /// Get current shopping cart
  /// 
  /// Returns the user's shopping cart with all items.
  /// 
  /// Throws:
  /// - Exception if network error or API error occurs
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   final cart = await repository.getCart();
  ///   print('Items: ${cart.itemsCount}, Total: ${cart.total}');
  /// } catch (e) {
  ///   print('Error: $e');
  /// }
  /// ```
  Future<Cart> getCart() async {
    try {
      return await _apiService.getCart();
    } catch (e) {
      throw _handleError('Failed to fetch cart', e);
    }
  }

  /// Add product to cart
  /// 
  /// Adds a product with specified quantity to shopping cart.
  /// 
  /// Parameters:
  /// - [productId]: Product ID to add
  /// - [quantity]: Number of items (default: 1)
  /// 
  /// Throws:
  /// - Exception if product not found or invalid
  /// 
  /// Example:
  /// ```dart
  /// await repository.addToCart(
  ///   productId: '456',
  ///   quantity: 3,
  /// );
  /// ```
  Future<void> addToCart({
    required String productId,
    int quantity = 1,
  }) async {
    try {
      await _apiService.addToCart(
        productId: productId,
        quantity: quantity,
      );
    } catch (e) {
      throw _handleError('Failed to add to cart', e);
    }
  }

  /// Update cart item quantity
  /// 
  /// Updates the quantity of an existing cart item.
  /// 
  /// Parameters:
  /// - [cartId]: Cart item ID
  /// - [quantity]: New quantity (must be > 0)
  /// 
  /// Throws:
  /// - Exception if cart item not found or invalid quantity
  Future<void> updateCartItem({
    required String cartId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }

    try {
      await _apiService.updateCartItem(
        cartId: cartId,
        quantity: quantity,
      );
    } catch (e) {
      throw _handleError('Failed to update cart item', e);
    }
  }

  /// Remove item from cart
  /// 
  /// Removes a single product from the shopping cart.
  /// 
  /// Parameters:
  /// - [cartId]: Cart item ID to remove
  /// 
  /// Throws:
  /// - Exception if cart item not found
  Future<void> removeFromCart(String cartId) async {
    try {
      await _apiService.removeFromCart(cartId);
    } catch (e) {
      throw _handleError('Failed to remove from cart', e);
    }
  }

  /// Clear entire cart
  /// 
  /// Removes all items from the shopping cart.
  /// 
  /// Throws:
  /// - Exception if operation fails
  Future<void> clearCart() async {
    try {
      await _apiService.clearCart();
    } catch (e) {
      throw _handleError('Failed to clear cart', e);
    }
  }

  // ========================================
  // Checkout Methods
  // ========================================

  /// Process checkout
  /// 
  /// Completes the purchase and creates orders.
  /// If cart contains products from multiple sellers,
  /// separate orders will be created for each seller.
  /// 
  /// Parameters:
  /// - [address]: Shipping address (required)
  /// - [notes]: Delivery notes (optional)
  /// - [paymentMethod]: Payment method (optional, future use)
  /// 
  /// Returns:
  /// - [CheckoutResult]: Contains created orders info
  /// 
  /// Throws:
  /// - Exception if cart is empty or checkout fails
  /// 
  /// Example:
  /// ```dart
  /// final address = ShippingAddress(
  ///   name: 'أحمد محمد',
  ///   phone: '+966501234567',
  ///   location: 'الرياض، شارع الملك فهد',
  /// );
  /// 
  /// final result = await repository.checkout(
  ///   address: address,
  ///   notes: 'التوصيل بين 9 ص - 5 م',
  /// );
  /// 
  /// print('تم إنشاء ${result.totalOrders} طلب');
  /// ```
  Future<CheckoutResult> checkout({
    required ShippingAddress address,
    String? notes,
    String? paymentMethod,
  }) async {
    try {
      return await _apiService.checkout(
        address: address,
        notes: notes,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      throw _handleError('Checkout failed', e);
    }
  }

  // ========================================
  // Orders Methods
  // ========================================

  /// Get buyer orders (purchases)
  /// 
  /// Retrieves all orders where current user is the buyer.
  /// 
  /// Parameters:
  /// - [offset]: Pagination offset (default: 0)
  /// - [limit]: Items per page (default: 20)
  /// 
  /// Returns:
  /// - List of [Order] objects
  Future<List<Order>> getBuyerOrders({
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      return await _apiService.getOrders(
        type: 'buyer',
        offset: offset,
        limit: limit,
      );
    } catch (e) {
      throw _handleError('Failed to fetch buyer orders', e);
    }
  }

  /// Get seller orders (sales)
  /// 
  /// Retrieves all orders where current user is the seller.
  /// 
  /// Parameters:
  /// - [offset]: Pagination offset (default: 0)
  /// - [limit]: Items per page (default: 20)
  /// 
  /// Returns:
  /// - List of [Order] objects
  Future<List<Order>> getSellerOrders({
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      return await _apiService.getOrders(
        type: 'seller',
        offset: offset,
        limit: limit,
      );
    } catch (e) {
      throw _handleError('Failed to fetch seller orders', e);
    }
  }

  /// Get order details
  /// 
  /// Retrieves full details of a specific order.
  /// 
  /// Parameters:
  /// - [orderHash]: Unique order identifier
  /// 
  /// Returns:
  /// - [Order]: Complete order details
  /// 
  /// Throws:
  /// - Exception if order not found or access denied
  Future<Order> getOrderDetails(String orderHash) async {
    try {
      return await _apiService.getOrderDetails(orderHash);
    } catch (e) {
      throw _handleError('Failed to fetch order details', e);
    }
  }

  // ========================================
  // Categories Methods
  // ========================================

  /// Get all product categories
  /// 
  /// Retrieves list of all available product categories.
  /// 
  /// Returns:
  /// - List of [ProductCategory] objects
  /// 
  /// Example:
  /// ```dart
  /// final categories = await repository.getCategories();
  /// for (var cat in categories) {
  ///   print('${cat.categoryId}: ${cat.categoryName}');
  /// }
  /// ```
  Future<List<ProductCategory>> getCategories() async {
    try {
      return await _apiService.getCategories();
    } catch (e) {
      throw _handleError('Failed to fetch categories', e);
    }
  }

  // ========================================
  // Helper Methods
  // ========================================

  /// Handle errors uniformly
  /// 
  /// Wraps errors with context message
  Exception _handleError(String message, dynamic error) {
    return Exception('$message: ${error.toString()}');
  }
}
