import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
/// خدمة البحث الشاملة لجميع أنواع المحتوى
class SearchApiService {
  final ApiClient _apiClient;
  SearchApiService(this._apiClient);
  /// البحث الشامل في جميع المحتويات
  /// 
  /// [query] - نص البحث المطلوب
  /// [tab] - نوع المحتوى: posts|blogs|users|pages|groups|events
  /// [page] - رقم الصفحة (افتراضي: 1)
  /// [limit] - عدد النتائج (افتراضي: 20، أقصى: 50)
  Future<SearchApiResponse> search({
    required String query,
    String tab = 'posts',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return SearchApiResponse.empty();
      }
      final response = await _apiClient.get(
        configCfgP('search'),
        queryParameters: {
          'q': query.trim(),
          'tab': tab,
          'page': page.toString(),
          'limit': limit.clamp(1, 50).toString(),
        },
      );
      if (response['status'] == 'success') {
        return SearchApiResponse.fromJson(response['data']);
      } else {
        return SearchApiResponse.error(
          response['message'] ?? 'Search failed',
        );
      }
    } catch (e) {
      return SearchApiResponse.error('Failed to perform search');
    }
  }
  /// البحث في المنشورات فقط
  Future<SearchApiResponse> searchPosts({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    return search(query: query, tab: 'posts', page: page, limit: limit);
  }
  /// البحث في المستخدمين فقط
  Future<SearchApiResponse> searchUsers({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    return search(query: query, tab: 'users', page: page, limit: limit);
  }
  /// البحث في الصفحات فقط
  Future<SearchApiResponse> searchPages({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    return search(query: query, tab: 'pages', page: page, limit: limit);
  }
  /// البحث في المجموعات فقط
  Future<SearchApiResponse> searchGroups({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    return search(query: query, tab: 'groups', page: page, limit: limit);
  }
  /// البحث في الفعاليات فقط
  Future<SearchApiResponse> searchEvents({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    return search(query: query, tab: 'events', page: page, limit: limit);
  }
  /// البحث في المدونات فقط
  Future<SearchApiResponse> searchBlogs({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    return search(query: query, tab: 'blogs', page: page, limit: limit);
  }
}
/// نموذج استجابة البحث
class SearchApiResponse {
  final bool success;
  final String? message;
  final String query;
  final String tab;
  final List<Map<String, dynamic>> results;
  final SearchPagination pagination;
  const SearchApiResponse({
    required this.success,
    this.message,
    required this.query,
    required this.tab,
    required this.results,
    required this.pagination,
  });
  factory SearchApiResponse.fromJson(Map<String, dynamic> json) {
    return SearchApiResponse(
      success: true,
      query: json['query'] ?? '',
      tab: json['tab'] ?? 'posts',
      results: (json['results'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      pagination: SearchPagination.fromJson(json['pagination'] ?? {}),
    );
  }
  factory SearchApiResponse.empty() {
    return const SearchApiResponse(
      success: true,
      query: '',
      tab: 'posts',
      results: [],
      pagination: SearchPagination(currentPage: 1, hasMore: false),
    );
  }
  factory SearchApiResponse.error(String message) {
    return SearchApiResponse(
      success: false,
      message: message,
      query: '',
      tab: 'posts',
      results: const [],
      pagination: const SearchPagination(currentPage: 1, hasMore: false),
    );
  }
  bool get isEmpty => results.isEmpty;
  bool get isNotEmpty => results.isNotEmpty;
  int get resultsCount => results.length;
}
/// نموذج pagination لنتائج البحث
class SearchPagination {
  final int currentPage;
  final bool hasMore;
  const SearchPagination({
    required this.currentPage,
    required this.hasMore,
  });
  factory SearchPagination.fromJson(Map<String, dynamic> json) {
    return SearchPagination(
      currentPage: json['current_page'] ?? 1,
      hasMore: json['has_more'] ?? false,
    );
  }
  int get nextPage => hasMore ? currentPage + 1 : currentPage;
}
