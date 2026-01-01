import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../main.dart' show configCfgP;
import '../models/cart.dart';
import '../models/checkout_result.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/shipping_address.dart';
import 'package:flutter/foundation.dart';

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

      if (productsList.isNotEmpty) {
      }

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
    String? handle,
    int? handleId,
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

      // سياق النشر (user/page/group/event)
      if (handle != null && handle.isNotEmpty) {
        body['handle'] = handle;
      }

      // أرسل كل الحقول المحتملة للمعرّف لضمان التوافق مع الـ backend
      // معرّف الصفحة/المجموعة/الحدث حسب الدليل الرسمي (id)
      if (handleId != null) {
        body['id'] = handleId;
      }

      // إزالة الحقول الفارغة حتى لا نرسلها للـ API
      // تخلص من الحقول الفارغة/الافتراضية لتجنب رفض الـ API
      body.removeWhere(
        (key, value) =>
        value == null ||
        value == '' ||
        (value == false && (key == 'for_adult' || key == 'is_digital')),
      );

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


      if (response['data'] != null) {
        if (response['data']['cart'] != null) {
          if (response['data']['cart']['items'] is List) {
            final items = response['data']['cart']['items'] as List;
            if (items.isNotEmpty) {
            }
          }
        }
      }

      return Cart.fromJson(response['data']['cart']);
    } catch (e) {
      rethrow;
    }
  }

  /// إضافة منتج إلى السلة
  ///
  /// [productId] - معرف المنتج (يُرسل كـ product_post_id)
  /// [quantity] - الكمية (افتراضي: 1)
  Future<Cart> addToCart({
    required String productId,
    int quantity = 1,
  }) async {
    try {

      final response = await _apiClient.post(
        configCfgP('market_cart_add'),
        body: {'product_post_id': productId, 'quantity': quantity},
      );

      
   
      if (response['data'] != null) {
        if (response['data']['cart'] != null) {
          if (response['data']['cart']['items'] is List) {
            final items = response['data']['cart']['items'] as List;
            if (items.isNotEmpty) {
            }
          }
        }
      }
      
      // الـ API الجديد يرجع السلة الكاملة بعد الإضافة
      return Cart.fromJson(response['data']['cart']);
    } catch (e) {
      rethrow;
    }
  }

  /// تحديث كمية منتج في السلة
  ///
  /// [cartId] - معرف العنصر في السلة
  /// [quantity] - الكمية الجديدة
  Future<Cart> updateCartItem({
    required String cartId,
    required int quantity,
  }) async {
    try {

      final response = await _apiClient.put(
        configCfgP('market_cart_update'),
        body: {'cart_id': cartId, 'quantity': quantity},
      );

      // الـ API الجديد يرجع السلة الكاملة بعد التحديث
      return Cart.fromJson(response['data']['cart']);
    } catch (e) {
      rethrow;
    }
  }

  /// حذف منتج من السلة
  ///
  /// [cartId] - معرف العنصر في السلة
  Future<Cart> removeFromCart(String cartId) async {
    try {

      final response = await _apiClient.delete(
        configCfgP('market_cart') + '/remove/$cartId',
      );

      // الـ API الجديد يرجع السلة الكاملة بعد الحذف
      return Cart.fromJson(response['data']['cart']);
    } catch (e) {
      rethrow;
    }
  }

  /// مسح جميع العناصر من السلة
  Future<Cart> clearCart() async {
    try {

      final response = await _apiClient.delete(
        configCfgP('market_cart_clear'),
      );

      // الـ API الجديد يرجع سلة فارغة بعد المسح
      return Cart.fromJson(response['data']['cart']);
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // Checkout Methods
  // ========================================

  /// إتمام عملية الدفع وإنشاء طلبات
  ///
  /// [address] - عنوان الشحن الجديد (اختياري)
  /// [shippingAddressId] - معرف عنوان موجود (اختياري)
  /// يجب توفير واحد على الأقل: address أو shippingAddressId
  Future<CheckoutResult> checkout({
    ShippingAddress? address,
    int? shippingAddressId,
    String? paymentMethod,
  }) async {
    try {
      if (address == null && shippingAddressId == null) {
        throw Exception('يجب توفير عنوان الشحن أو معرف عنوان موجود');
      }

      
      final body = <String, dynamic>{};
      
      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        body['payment_method'] = paymentMethod;
      }

      if (shippingAddressId != null) {
        body['shipping_address_id'] = shippingAddressId;
      } else if (address != null) {
        body['address'] = {
          'name': address.name,
          'phone': address.phone,
          'location': address.address,
          if (address.country != null) 'country': address.country,
          if (address.city != null) 'city': address.city,
          if (address.zipCode != null) 'zip_code': address.zipCode,
        };
      }

      final response = await _apiClient.post(
        configCfgP('market_checkout'),
        body: body,
      );

      
      final ordersCollectionId = response['data']?['orders_collection_id'];
      final total = response['data']?['total'];
      
      if (ordersCollectionId != null) {
      }
      if (total != null) {
      }

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
      final endpoint = configCfgP('market_orders');
      final debugUri = '$endpoint?type=$type&offset=$offset&limit=$limit&include_details=true';

      final response = await _apiClient.get(
        endpoint,
        queryParameters: {
          'type': type,
          'offset': offset.toString(),
          'limit': limit.toString(),
          'include_details': 'true', // ✅ جلب التفاصيل الكاملة
        },
      );


      final ordersList = response['data']['orders'] as List<dynamic>;

      if (ordersList.isNotEmpty) {
        final firstOrder = ordersList.first as Map<String, dynamic>;
        firstOrder.forEach((key, value) {
        });
      }

      final parsedOrders = ordersList.map((json) {
        try {
          return Order.fromJson(json);
        } catch (e) {
          rethrow;
        }
      }).toList();

      // Deduplicate by orderHash in case the backend returns duplicates
      final Map<String, Order> uniqueByHash = {
        for (final o in parsedOrders) o.orderHash: o,
      };
      return uniqueByHash.values.toList();
    } catch (e) {
      rethrow;
    }
  }

  /// جلب تفاصيل طلب معين
  ///
  /// [orderHash] - معرف الطلب الفريد
  Future<Order> getOrderDetails(String orderHash) async {
    final base = configCfgP('market_orders');
    final configured = configCfgP('market_order_details');

    // Try configured endpoint first (if present), then default /orders/{hash}, then minimal fallback
    final endpoints = <String>{
      if (configured.isNotEmpty)
        configured.replaceAll('{order_hash}', orderHash),
      '$base/$orderHash', // canonical: /orders/{hash}
      base, // fallback: /orders?order_hash=...
    }.toList();

    // Primary call uses include_details=true; fallback without it if backend ignores the flag
    final queryVariants = <Map<String, String>>[
      {'include_details': 'true'},
      {'order_hash': orderHash, 'include_details': 'true'},
      {'order_hash': orderHash},
      const {},
    ];

    ApiException? apiError;
    Object? lastError;

    for (final endpoint in endpoints) {
      for (final params in queryVariants) {
        try {
          final response = await _apiClient.get(
            endpoint,
            queryParameters: params.isEmpty ? null : params,
          );


          final data = response['data'];
          if (data is Map<String, dynamic>) {
            if (data['order'] is Map<String, dynamic>) {
              return Order.fromJson(data['order'] as Map<String, dynamic>);
            }
            // Fallback if API returns the order directly under data
            return Order.fromJson(data);
          }
          throw ApiException(
            'Unexpected response shape for order details',
            statusCode: 500,
          );
        } on ApiException catch (e) {
          apiError = e;
        } catch (e) {
          lastError = e;
        }
      }
    }

    // If all attempts failed, bubble up the most relevant error
    if (apiError != null) throw apiError;
    if (lastError != null) throw lastError;
    throw ApiException('Failed to fetch order details', statusCode: 500);
  }

  /// تحديث حالة الطلب (Seller only)
  ///
  /// [orderHash] - معرف الطلب الفريد
  /// [status] - الحالة الجديدة: 'processing' | 'shipped' | 'delivered' | 'cancelled'
  Future<Order> updateOrderStatus({
    required String orderHash,
    required String status,
  }) async {
    try {

      final response = await _apiClient.post(
        configCfgP('market_orders') + '/status',
        body: {
          'order_hash': orderHash,
          'status': status,
        },
      );


      final data = response['data'];
      if (data is Map<String, dynamic>) {
        if (data.containsKey('order') && data['order'] is Map<String, dynamic>) {
          return Order.fromJson(data['order'] as Map<String, dynamic>);
        }
        return Order.fromJson(data);
      }

      // إذا لم يرجع الطلب، نحضره من الـ API
      return await getOrderDetails(orderHash);
    } catch (e) {
      rethrow;
    }
  }

  /// جلب عدد الطلبات حسب النوع (مشتري/بائع)
  Future<int> getOrdersCount({String type = 'buyer'}) async {
    try {
      final cfg = configCfgP('market_orders_count');
      final endpoint = cfg.isNotEmpty ? cfg : '/data/market/orders/count';
      final response = await _apiClient.get(
        endpoint,
        queryParameters: {
          'type': type,
        },
      );
      final count = int.tryParse(response['data']?['count']?.toString() ?? '')
          ?? response['data']?['orders_count'] as int? // alt key from docs
          ?? 0;
      return count;
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // WebView Session Token
  // ========================================

  /// إنشاء توكن جلسة للـ WebView لتجاوز شاشة تسجيل الدخول
  Future<String> createWebViewSessionToken() async {
    try {
      final response = await _apiClient.post('/data/auth/webview-token');
      final token = response['data']?['session_token']?.toString() ?? '';
      return token;
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
  buyer, // المشتريات
  seller, // المبيعات
}