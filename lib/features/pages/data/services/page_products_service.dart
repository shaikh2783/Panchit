import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/market/data/models/product.dart';
import 'package:flutter/foundation.dart';

class PageProductsResult {
  final List<Product> products;
  final bool hasMore;
  const PageProductsResult({required this.products, required this.hasMore});
}

/// Fetches products for a given page using /data/pages/products
class PageProductsService {
  final ApiClient _apiClient;

  PageProductsService(this._apiClient);

  Future<PageProductsResult> getPageProducts({
    int? pageId,
    String? pageName,
    String? username,
    String? search,
    int? categoryId,
    String? status,
    int offset = 0,
    int limit = 20,
  }) async {
    if (pageId == null && 
        (pageName == null || pageName.isEmpty) && 
        (username == null || username.isEmpty)) {
      throw Exception('Target page is required (page_id or page_name/username)');
    }

    final query = <String, String>{
      if (pageId != null) 'page_id': pageId.toString(),
      if (pageName != null && pageName.isNotEmpty) 'page_name': pageName,
      if (username != null && username.isNotEmpty) 'username': username,
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final resp = await _apiClient.get(
      '/data/pages/products',
      queryParameters: query,
    );

    
    final data = resp['data'] as Map<String, dynamic>? ?? {};
    
    final productsList = data['products'] as List<dynamic>? ?? [];
    
    final hasMore = data['has_more'] == true;
    final products = productsList.map((e) => Product.fromJson(e)).toList();


    return PageProductsResult(products: products, hasMore: hasMore);
  }
}