import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/market/data/models/product.dart';
import 'package:flutter/foundation.dart';

class ProductManagementService {
  final ApiClient _apiClient;

  ProductManagementService(this._apiClient);

  /// تعديل بيانات المنتج
  Future<Product> editProduct({
    required int postId,
    String? name,
    double? price,
    int? quantity,
    String? status,
    String? location,
    int? categoryId,
    String? description,
    bool? isDigital,
    String? productUrl,
    String? productFile,
  }) async {
    final body = <String, dynamic>{
      'post_id': postId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (quantity != null) 'quantity': quantity,
      if (status != null) 'status': status,
      if (location != null) 'location': location,
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
      if (isDigital != null) 'is_digital': isDigital,
      if (productUrl != null) 'product_url': productUrl,
      if (productFile != null) 'product_file': productFile,
    };


    final resp = await _apiClient.post(
      '/data/market/products/edit',
      body: body,
    );


    final data = resp['data'] as Map<String, dynamic>? ?? {};
    return Product.fromJson(data);
  }

  /// تعليم المنتج كمباع
  Future<void> markProductSold(int postId) async {
    final body = {'post_id': postId};


    final resp = await _apiClient.post(
      '/data/market/products/mark-sold',
      body: body,
    );

  }

  /// إعادة المنتج متاح (unsold)
  Future<void> markProductUnsold(int postId) async {
    final body = {'post_id': postId};


    final resp = await _apiClient.post(
      '/data/market/products/mark-unsold',
      body: body,
    );

  }
}