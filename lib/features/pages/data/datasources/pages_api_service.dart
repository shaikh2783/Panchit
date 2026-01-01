import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/main.dart' show configCfgP;
import 'package:snginepro/features/pages/data/models/page.dart';
import 'package:snginepro/features/pages/data/models/page_category.dart';
import 'package:snginepro/core/data/models/country.dart';
import 'package:snginepro/core/data/models/language.dart';
import 'package:snginepro/features/feed/data/models/posts_response.dart';

class PagesApiService {
  PagesApiService(this._client);

  final ApiClient _client;

  /// Get my pages (pages I manage)
  Future<List<PageModel>> fetchMyPages() async {

    final response = await _client.get(configCfgP('pages_my'));

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to fetch pages',
        details: response,
      );
    }

    final data = response['data'];
    if (data is! List) {
      throw ApiException('Invalid data format', details: response);
    }

    return data
        .map((json) => PageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get pages I've liked
  Future<List<PageModel>> fetchLikedPages() async {
    final response = await _client.get(configCfgP('pages_liked'));

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to fetch liked pages',
        details: response,
      );
    }

    final data = response['data'];
    if (data is! List) {
      throw ApiException('Invalid data format', details: response);
    }

    return data
        .map((json) => PageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get suggested pages
  Future<List<PageModel>> fetchSuggestedPages({int limit = 10}) async {
    final response = await _client.get(
      configCfgP('pages_suggested'),
      queryParameters: {'limit': '$limit'},
    );

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to fetch suggested pages',
        details: response,
      );
    }

    final data = response['data'];
    if (data is! List) {
      throw ApiException('Invalid data format', details: response);
    }

    return data
        .map((json) => PageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Like or unlike a page
  Future<void> toggleLikePage(int pageId, bool currentlyLiked) async {
    // Get endpoint from config (with fallback to hardcoded)
    final endpoint = currentlyLiked
        ? configCfgP('pages_unlike')
        : configCfgP('pages_like');

    final path = endpoint.replaceAll('{id}', pageId.toString());

    final response = await _client.post(path);

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to toggle like',
        details: response,
      );
    }

  }

  /// Create a new page
  Future<PageModel> createPage({
    required String title,
    required String username,
    required int category,
    required int country,
    required int language,
    String? description,
  }) async {

    // Get endpoint from config with fallback
    final endpoint = configCfgP('pages_create');
    final path = endpoint.isNotEmpty ? endpoint : '/data/pages';

    // Build request body
    final body = <String, dynamic>{
      'title': title,
      'username': username,
      'category': category,
      'country': country,
      'language': language,
    };

    // Add optional description
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description;
    }

    final response = await _client.post(path, body: body);

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to create page',
        details: response,
      );
    }

    final pageData = response['data'];
    if (pageData == null) {
      throw ApiException('No page data returned', details: response);
    }

    final page = PageModel.fromJson(pageData);

    return page;
  }

  /// Update an existing page
  Future<void> updatePage({
    required int pageId,
    required String title,
    required int category,
    required int country,
    required int language,
    String? description,
  }) async {

    // Get endpoint from config with fallback
    final endpoint = configCfgP('pages_edit');
    final path = endpoint.isNotEmpty
        ? endpoint.replaceAll('{id}', pageId.toString())
        : '/data/pages/$pageId';

    // Build request body
    final body = <String, dynamic>{
      'title': title,
      'category': category,
      'country': country,
      'language': language,
    };

    // Add optional description
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description;
    }

    final response = await _client.post(path, body: body);

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to update page',
        details: response,
      );
    }

  }

  /// Update page section (settings/info/action/social/monetization)
  Future<void> updatePageSection({
    required int pageId,
    required String section,
    required Map<String, dynamic> data,
  }) async {

    // Get endpoint from config with fallback
    final endpoint = configCfgP('pages_edit');
    final path = endpoint.isNotEmpty
        ? endpoint.replaceAll('{id}', pageId.toString())
        : '/data/pages/$pageId/edit';

    // Add section to body
    final body = <String, dynamic>{'section': section, ...data};

    final response = await _client.post(path, body: body);

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to update page section',
        details: response,
      );
    }

  }

  /// Fetch page information
  Future<PageModel> fetchPageInfo({
    int? pageId,
    String? pageName,
    String? with_,
  }) async {

    if (pageId == null && pageName == null) {
      throw ApiException('Either page_id or page_name must be specified');
    }

    final queryParams = <String, String>{};
    if (pageId != null) queryParams['page_id'] = '$pageId';
    if (pageName != null) queryParams['page_name'] = pageName;
    if (with_ != null) queryParams['with'] = with_;

    final response = await _client.get(
      configCfgP('pages_info'),
      queryParameters: queryParams,
    );

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to load page information',
        details: response,
      );
    }

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Invalid data format', details: response);
    }

    return PageModel.fromJson(data);
  }

  /// Fetch posts for a specific page
  Future<PostsResponse> fetchPagePosts({
    required int pageId,
    int limit = 10,
    int offset = 0,
  }) async {

    final response = await _client.get(
      configCfgP('pages_posts'),
      queryParameters: {
        'page_id': '$pageId',
        'offset': '$offset',
        'limit': '$limit',
      },
    );

    final postsResponse = PostsResponse.fromJson(response);

    if (!postsResponse.isSuccess) {
      throw ApiException(
        postsResponse.message ?? 'Failed to fetch page posts',
        details: response,
      );
    }

    return postsResponse;
  }

  /// React to a post
  Future<void> reactToPost(int postId, String reaction) async {
    final response = await _client.post(
      configCfgP('posts_react'),
      body: {'post_id': postId, 'reaction': reaction},
    );

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to react to post',
        details: response,
      );
    }
  }

  /// Invite friends to like a page
  Future<void> inviteFriendsToPage({
    required int pageId,
    required List<int> userIds,
  }) async {

    final endpoint = configCfgP('pages_invite');
    final path = endpoint.isNotEmpty
        ? endpoint.replaceAll('{id}', pageId.toString())
        : '/data/pages/$pageId/invite';

    final body = {'users': userIds.map((id) => id.toString()).toList()};

    final response = await _client.post(path, body: body);

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to invite friends',
        details: response,
      );
    }

  }

  /// Add admin to page
  Future<void> addAdmin({required int pageId, required int userId}) async {
    final endpoint = configCfgP('pages_add_admin');
    final path = endpoint.isNotEmpty
        ? endpoint.replaceAll('{id}', pageId.toString())
        : '/data/pages/$pageId/add_admin';

    final body = {'user_id': userId};

    final response = await _client.post(path, body: body);

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to add admin',
        details: response,
      );
    }

  }

  /// Remove admin from page
  Future<void> removeAdmin({required int pageId, required int userId}) async {
    final endpoint = configCfgP('pages_remove_admin');
    final path = endpoint.isNotEmpty
        ? endpoint.replaceAll('{id}', pageId.toString())
        : '/data/pages/$pageId/remove_admin';

    final body = {'user_id': userId};

    final response = await _client.post(path, body: body);

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to remove admin',
        details: response,
      );
    }

  }

  /// Request page verification
  Future<Map<String, dynamic>> requestVerification({
    required int pageId,
    String? photo,
    String? passport,
    String? businessWebsite,
    String? businessAddress,
    String? message,
  }) async {
    final endpoint = configCfgP('pages_request_verification');
    final path = endpoint.isNotEmpty
        ? endpoint.replaceAll('{id}', pageId.toString())
        : '/data/pages/$pageId/request_verification';

    final body = <String, dynamic>{};
    if (photo != null) body['photo'] = photo;
    if (passport != null) body['passport'] = passport;
    if (businessWebsite != null) body['business_website'] = businessWebsite;
    if (businessAddress != null) body['business_address'] = businessAddress;
    if (message != null) body['message'] = message;

    final response = await _client.post(path, body: body);

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to request verification',
        details: response,
      );
    }

    return response['data'] ?? {};
  }

  /// Update page picture (avatar)
  Future<Map<String, dynamic>> updatePagePicture({
    required int pageId,
    required String pictureData, // URL or base64
  }) async {
    final endpoint = configCfgP('pages_update_picture');
    final path = endpoint.isNotEmpty
        ? endpoint.replaceAll('{id}', pageId.toString())
        : '/data/pages/$pageId/picture';

    final body = {'picture': pictureData};

    final response = await _client.post(path, body: body);

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to update page picture',
        details: response,
      );
    }

    return response['data'] ?? {};
  }

  /// Update page cover
  Future<Map<String, dynamic>> updatePageCover({
    required int pageId,
    required String coverData, // URL or base64
  }) async {
    final endpoint = configCfgP('pages_update_cover');
    final path = endpoint.isNotEmpty
        ? endpoint.replaceAll('{id}', pageId.toString())
        : '/data/pages/$pageId/cover';

    final body = {'cover': coverData};

    final response = await _client.post(path, body: body);

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to update page cover',
        details: response,
      );
    }

    return response['data'] ?? {};
  }

  /// Get page categories (public endpoint - no auth required)
  /// Endpoint: GET /data/pages/categories
  Future<List<PageCategory>> getPageCategories() async {
    try {

      final endpoint = configCfgP('pages_categories');
      final response = await _client.get(endpoint.isNotEmpty ? endpoint : '/data/pages/categories');

      if (response['status'] == 'success' && response['data'] != null) {
        final categoriesData = response['data']['categories'] as List<dynamic>;
        return categoriesData.map((json) => PageCategory.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(
          response['message'] ?? 'Failed to get page categories',
          details: response,
        );
      }
    } catch (e) {

      rethrow;
    }
  }

  /// Get countries (public endpoint - no auth required)
  /// Endpoint: GET /data/countries
  Future<List<Country>> getCountries() async {
    try {

      final endpoint = configCfgP('countries');
      final response = await _client.get(endpoint.isNotEmpty ? endpoint : '/data/countries');

      if (response['status'] == 'success' && response['data'] != null) {
        final countriesData = response['data']['countries'] as List<dynamic>;
        return countriesData.map((json) => Country.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(
          response['message'] ?? 'Failed to get countries',
          details: response,
        );
      }
    } catch (e) {

      rethrow;
    }
  }

  /// Get languages (public endpoint - no auth required)
  /// Endpoint: GET /data/languages
  Future<List<Language>> getLanguages() async {
    try {

      final endpoint = configCfgP('languages');
      final response = await _client.get(endpoint.isNotEmpty ? endpoint : '/data/languages');

      if (response['status'] == 'success' && response['data'] != null) {
        final languagesData = response['data']['languages'] as List<dynamic>;
        return languagesData.map((json) => Language.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(
          response['message'] ?? 'Failed to get languages',
          details: response,
        );
      }
    } catch (e) {

      rethrow;
    }
  }

  /// Delete a page
  Future<void> deletePage({required int pageId}) async {
    try {

      final endpoint = configCfgP('pages_delete');
      final response = await _client.post(
        endpoint.isNotEmpty ? endpoint : '/data/pages/delete',
        body: {'page_id': pageId},
      );

      if (response['status'] != 'success') {
        throw ApiException(
          response['message'] ?? 'Failed to delete page',
          details: response,
        );
      }
    } catch (e) {

      rethrow;
    }
  }
}
