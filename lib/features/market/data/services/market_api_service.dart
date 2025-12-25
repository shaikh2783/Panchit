import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/cart.dart';
import '../models/checkout_result.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/shipping_address.dart';

/// Market API Service - خدمة API للسوق
/// 
/// يوفر جميع وظائف السوق:
/// - إدارة سلة التسوق
/// - عملية الدفع
/// - إدارة الطلبات
/// - الفئات
class MarketApiService {
  final ApiClient _apiClient;

  MarketApiService(this._apiClient);

  // ========================================
  // Products Methods
  // ========================================

  /// جلب قائمة المنتجات
  /// 
  /// [categoryId] - تصفية حسب الفئة (اختياري)
  /// [search] - البحث في اسم المنتج (اختياري)
  /// [offset] - رقم البداية للصفحات
  /// [limit] - عدد النتائج في الصفحة
  Future<List<Product>> getProducts({
    int? categoryId,
    String? search,
    int offset = 0,
    int limit = 20,
  }) async {
    try {

      final queryParams = <String, String>{
        'offset': offset.toString(),
        'limit': limit.toString(),
      };

      if (categoryId != null) {
        queryParams['category_id'] = categoryId.toString();
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get(
        configCfgP('market_products'),
        queryParameters: queryParams,
      );


      final productsList = response['data']['products'] as List<dynamic>? ?? [];
      return productsList.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// جلب تفاصيل منتج معين
  /// 
  /// [productId] - معرف المنتج
  Future<Product> getProductDetails(String productId) async {
    try {

      final response = await _apiClient.get(
        configCfgP('market_products') + '/$productId',
      );


      return Product.fromJson(response['data']['product']);
    } catch (e) {
      rethrow;
    }
  }

  /// جلب منتجاتي (البائع الحالي)
  ///
  /// [search] - فلترة بالاسم/الوصف (اختياري)
  /// [status] - فلترة بالحالة (اختياري)
  /// [offset] - رقم البداية للصفحات
  /// [limit] - عدد النتائج في الصفحة
  Future<List<Product>> getMyProducts({
    String? search,
    String? status,
    int offset = 0,
    int limit = 20,
  }) async {
    try {

      final queryParams = <String, String>{
        'offset': offset.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final endpoint = configCfgP('market_my_products');
      final response = await _apiClient.get(
        endpoint.isNotEmpty ? endpoint : '/data/market/my/products',
        queryParameters: queryParams,
      );

      final productsList = response['data']['products'] as List<dynamic>? ?? [];
      return productsList.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// إنشاء منتج جديد
  ///
  /// يستخدم تدفق الناشر لإضافة منتج.
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

      final body = <String, dynamic>{
        'name': name,
        'price': price,
        'quantity': quantity,
        'category_id': categoryId,
        'status': status,
        'location': location,
        'is_digital': isDigital,
        'product_url': productUrl,
        'product_file': productFile,
        'description': description,
      };

      if (photos.isNotEmpty) {
        body['photos'] = photos;
      }

      if (forAdult) {
        body['for_adult'] = true;
      }

      // إزالة الحقول الفارغة حتى لا نرسلها للـ API
      body.removeWhere((key, value) => value == null || value == '' || value == false && key == 'for_adult');

      final endpoint = configCfgP('market_product_create');
      final response = await _apiClient.post(
        endpoint.isNotEmpty ? endpoint : '/data/market/products/create',
        body: body,
      );

      return Product.fromJson(response['data']['product']);
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // Shopping Cart Methods
  // ========================================

  /// جلب سلة التسوق الحالية
  Future<Cart> getCart() async {
    try {

      final response = await _apiClient.get(configCfgP('market_cart'));


      return Cart.fromJson(response['data']['cart']);
    } catch (e) {
      rethrow;
    }
  }

  /// إضافة منتج إلى السلة
  /// 
  /// [productId] - معرف المنتج
  /// [quantity] - الكمية (افتراضي: 1)
  Future<Map<String, dynamic>> addToCart({
    required String productId,
    int quantity = 1,
  }) async {
    try {

      final response = await _apiClient.post(
        configCfgP('market_cart_add'),
        body: {
          'product_id': productId,
          'quantity': quantity,
        },
      );

      return response['data'];
    } catch (e) {
      rethrow;
    }
  }

  /// تحديث كمية منتج في السلة
  /// 
  /// [cartId] - معرف العنصر في السلة
  /// [quantity] - الكمية الجديدة
  Future<Map<String, dynamic>> updateCartItem({
    required String cartId,
    required int quantity,
  }) async {
    try {

      final response = await _apiClient.put(
        configCfgP('market_cart_update'),
        body: {
          'cart_id': cartId,
          'quantity': quantity,
        },
      );

      return response['data'];
    } catch (e) {
      rethrow;
    }
  }

  /// حذف منتج من السلة
  /// 
  /// [cartId] - معرف العنصر في السلة
  Future<Map<String, dynamic>> removeFromCart(String cartId) async {
    try {

      final response = await _apiClient.post(
        configCfgP('market_cart') + '/remove/$cartId',
        body: {},
      );

      return response['data'];
    } catch (e) {
      rethrow;
    }
  }

  /// مسح جميع العناصر من السلة
  Future<Map<String, dynamic>> clearCart() async {
    try {

      final response = await _apiClient.post(
        configCfgP('market_cart_clear'),
        body: {},
      );

      return response['data'];
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // Checkout Methods
  // ========================================

  /// إتمام عملية الدفع وإنشاء طلبات
  /// 
  /// [address] - عنوان الشحن
  /// [notes] - ملاحظات إضافية (اختياري)
  /// [paymentMethod] - طريقة الدفع (اختياري)
  Future<CheckoutResult> checkout({
    required ShippingAddress address,
    String? notes,
    String? paymentMethod,
  }) async {
    try {

      final response = await _apiClient.post(
        configCfgP('market_checkout'),
        body: {
          'address': address.toJson(),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (paymentMethod != null) 'payment_method': paymentMethod,
        },
      );


      return CheckoutResult.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // Orders Methods
  // ========================================

  /// جلب قائمة الطلبات
  /// 
  /// [type] - نوع الطلبات: 'buyer' (المشتريات) أو 'seller' (المبيعات)
  /// [offset] - رقم البداية للصفحات
  /// [limit] - عدد النتائج في الصفحة
  Future<List<Order>> getOrders({
    String type = 'buyer',
    int offset = 0,
    int limit = 20,
  }) async {
    try {

      final response = await _apiClient.get(
        configCfgP('market_orders'),
        queryParameters: {
          'type': type,
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );


      final ordersList = response['data']['orders'] as List<dynamic>;
      return ordersList.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// جلب تفاصيل طلب معين
  /// 
  /// [orderHash] - معرف الطلب الفريد
  Future<Order> getOrderDetails(String orderHash) async {
    try {

      final response = await _apiClient.get(
        configCfgP('market_orders') + '/$orderHash',
      );


      return Order.fromJson(response['data']['order']);
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // Categories Methods
  // ========================================

  /// جلب جميع فئات المنتجات
  Future<List<ProductCategory>> getCategories() async {
    try {

      final response = await _apiClient.get(configCfgP('market_categories'));


      final categoriesList = response['data']['categories'] as List<dynamic>;
      return categoriesList
          .map((json) => ProductCategory.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}

/// Order Type Enum - نوع الطلبات
enum OrderType {
  buyer,  // المشتريات
  seller, // المبيعات
}
