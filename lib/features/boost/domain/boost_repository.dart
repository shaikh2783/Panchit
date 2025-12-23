import '../data/services/boost_api_service.dart';

class BoostRepository {
  final BoostApiService _apiService;

  BoostRepository(this._apiService);

  // ==================== Posts ====================

  Future<BoostResult> boostPost(int postId) async {
    try {
      final response = await _apiService.boostPost(postId);
      return BoostResult.fromJson(response);
    } catch (e) {
      throw BoostException(_parseError(e));
    }
  }

  Future<BoostResult> unboostPost(int postId) async {
    try {
      final response = await _apiService.unboostPost(postId);
      return BoostResult.fromJson(response);
    } catch (e) {
      throw BoostException(_parseError(e));
    }
  }

  Future<BoostedPostsResponse> getBoostedPosts({
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.getBoostedPosts(
        offset: offset,
        limit: limit,
      );
      return BoostedPostsResponse.fromJson(response);
    } catch (e) {
      throw BoostException(_parseError(e));
    }
  }

  // ==================== Pages ====================

  Future<BoostResult> boostPage(int pageId) async {
    try {
      final response = await _apiService.boostPage(pageId);
      return BoostResult.fromJson(response);
    } catch (e) {
      throw BoostException(_parseError(e));
    }
  }

  Future<BoostResult> unboostPage(int pageId) async {
    try {
      final response = await _apiService.unboostPage(pageId);
      return BoostResult.fromJson(response);
    } catch (e) {
      throw BoostException(_parseError(e));
    }
  }

  Future<BoostedPagesResponse> getBoostedPages({
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.getBoostedPages(
        offset: offset,
        limit: limit,
      );
      return BoostedPagesResponse.fromJson(response);
    } catch (e) {
      throw BoostException(_parseError(e));
    }
  }

  String _parseError(dynamic error) {
    if (error is Map) {
      final message = error['message']?.toString();
      final errorCode = error['error_code']?.toString();
      if (errorCode != null && message != null) {
        return '$message (Error: $errorCode)';
      }
      if (message != null) {
        return message;
      }
    }
    return error?.toString() ?? 'Unknown error';
  }
}

// ==================== Models ====================

class BoostResult {
  final bool success;
  final String message;
  final bool? boosted;
  final int? remainingBoosts;
  final bool? canBoostMore;

  BoostResult({
    required this.success,
    required this.message,
    this.boosted,
    this.remainingBoosts,
    this.canBoostMore,
  });

  factory BoostResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return BoostResult(
      success: json['status'] == 'success',
      message: json['message']?.toString() ?? '',
      boosted: data?['boosted'] == true || data?['boosted'] == 1 || data?['boosted'] == '1',
      remainingBoosts: data?['remaining_boosts'] != null 
          ? int.tryParse(data!['remaining_boosts'].toString())
          : null,
      canBoostMore: data?['can_boost_more'] == true || data?['can_boost_more'] == 1,
    );
  }
}

class BoostedPostsResponse {
  final List<Map<String, dynamic>> posts;
  final PaginationInfo pagination;
  final BoostInfo boostInfo;

  BoostedPostsResponse({
    required this.posts,
    required this.pagination,
    required this.boostInfo,
  });

  factory BoostedPostsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    
    // Handle pagination at root level of data
    final total = data['total'] != null ? int.tryParse(data['total'].toString()) ?? 0 : 0;
    final limit = data['limit'] != null ? int.tryParse(data['limit'].toString()) ?? 10 : 10;
    final offset = data['offset'] != null ? int.tryParse(data['offset'].toString()) ?? 0 : 0;
    
    return BoostedPostsResponse(
      posts: (data['posts'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      pagination: PaginationInfo(
        total: total,
        limit: limit,
        offset: offset,
        hasMore: (offset + limit) < total,
      ),
      boostInfo: BoostInfo(
        canBoostMore: true,
        remainingBoosts: 0,
        boostLimit: 0,
        boostedCount: total,
      ),
    );
  }
}

class BoostedPagesResponse {
  final List<Map<String, dynamic>> pages;
  final PaginationInfo pagination;
  final BoostInfo boostInfo;

  BoostedPagesResponse({
    required this.pages,
    required this.pagination,
    required this.boostInfo,
  });

  factory BoostedPagesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    
    // Handle pagination at root level of data
    final total = data['total'] != null ? int.tryParse(data['total'].toString()) ?? 0 : 0;
    final limit = data['limit'] != null ? int.tryParse(data['limit'].toString()) ?? 10 : 10;
    final offset = data['offset'] != null ? int.tryParse(data['offset'].toString()) ?? 0 : 0;
    
    return BoostedPagesResponse(
      pages: (data['pages'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      pagination: PaginationInfo(
        total: total,
        limit: limit,
        offset: offset,
        hasMore: (offset + limit) < total,
      ),
      boostInfo: BoostInfo(
        canBoostMore: true,
        remainingBoosts: 0,
        boostLimit: 0,
        boostedCount: total,
      ),
    );
  }
}

class PaginationInfo {
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  PaginationInfo({
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      limit: int.tryParse(json['limit']?.toString() ?? '10') ?? 10,
      offset: int.tryParse(json['offset']?.toString() ?? '0') ?? 0,
      hasMore: json['has_more'] == true || json['has_more'] == 1,
    );
  }
}

class BoostInfo {
  final bool canBoostMore;
  final int remainingBoosts;
  final int boostLimit;
  final int boostedCount;

  BoostInfo({
    required this.canBoostMore,
    required this.remainingBoosts,
    required this.boostLimit,
    required this.boostedCount,
  });

  factory BoostInfo.fromJson(Map<String, dynamic> json) {
    return BoostInfo(
      canBoostMore: json['can_boost_more'] == true || json['can_boost_more'] == 1,
      remainingBoosts: int.tryParse(json['remaining_boosts']?.toString() ?? '0') ?? 0,
      boostLimit: int.tryParse(json['boost_limit']?.toString() ?? '0') ?? 0,
      boostedCount: int.tryParse(json['boosted_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class BoostException implements Exception {
  final String message;
  BoostException(this.message);

  @override
  String toString() => message;
}
