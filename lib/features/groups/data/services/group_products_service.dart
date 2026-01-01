import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/market/data/models/product.dart';
import 'package:flutter/foundation.dart';

class GroupProductsResult {
  final List<Product> products;
  final bool hasMore;
  const GroupProductsResult({required this.products, required this.hasMore});
}

/// Fetches products for a given group using /data/groups/products
class GroupProductsService {
  final ApiClient _apiClient;

  GroupProductsService(this._apiClient);

  Future<GroupProductsResult> getGroupProducts({
    required int groupId,
    String? search,
    int? categoryId,
    String? status,
    int offset = 0,
    int limit = 20,
  }) async {
    final query = <String, String>{
      'group_id': groupId.toString(),
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
    };


    final resp = await _apiClient.get(
      '/data/groups/products',
      queryParameters: query,
    );


    final data = resp['data'] as Map<String, dynamic>? ?? {};

    final productsList = data['products'] as List<dynamic>? ?? [];

    final hasMore = data['has_more'] == true;
    final products = productsList.map((e) => Product.fromJson(e)).toList();


    return GroupProductsResult(products: products, hasMore: hasMore);
  }
}