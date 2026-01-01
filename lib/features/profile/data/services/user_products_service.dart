import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/market/data/models/product.dart';

class UserProductsResult {
  final List<Product> products;
  final bool hasMore;
  const UserProductsResult({required this.products, required this.hasMore});
}

/// Fetches public products for a given user profile using /data/users/products
class UserProductsService {
  final ApiClient _apiClient;

  UserProductsService(this._apiClient);

  Future<UserProductsResult> getUserProducts({
    int? userId,
    String? username,
    String? search,
    int? categoryId,
    String? status,
    int offset = 0,
    int limit = 20,
  }) async {
    if (userId == null && (username == null || username.isEmpty)) {
      throw Exception('Target user is required (user_id or username)');
    }

    final query = <String, String>{
      if (userId != null) 'user_id': userId.toString(),
      if (username != null && username.isNotEmpty) 'username': username,
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final resp = await _apiClient.get(
      '/data/users/products',
      queryParameters: query,
    );

    final data = resp['data'] as Map<String, dynamic>? ?? {};
    final productsList = data['products'] as List<dynamic>? ?? [];
    final hasMore = data['has_more'] == true;
    final products = productsList.map((e) => Product.fromJson(e)).toList();

    return UserProductsResult(products: products, hasMore: hasMore);
  }
}
