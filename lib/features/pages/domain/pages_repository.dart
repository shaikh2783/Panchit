import 'package:snginepro/features/pages/data/datasources/pages_api_service.dart';
import 'package:snginepro/features/pages/data/models/page.dart';
import 'package:snginepro/features/pages/data/models/page_category.dart';
import 'package:snginepro/core/data/models/country.dart';
import 'package:snginepro/core/data/models/language.dart';
import 'package:snginepro/features/feed/data/models/posts_response.dart';

class PagesRepository {
  PagesRepository(this._apiService);

  final PagesApiService _apiService;

  Future<List<PageModel>> fetchMyPages() {
    return _apiService.fetchMyPages();
  }

  Future<List<PageModel>> fetchLikedPages() {
    return _apiService.fetchLikedPages();
  }

  Future<List<PageModel>> fetchSuggestedPages({int limit = 10}) {
    return _apiService.fetchSuggestedPages(limit: limit);
  }

  Future<void> toggleLikePage(int pageId, bool currentlyLiked) {
    return _apiService.toggleLikePage(pageId, currentlyLiked);
  }

  Future<PageModel> createPage({
    required String title,
    required String username,
    required int category,
    required int country,
    required int language,
    String? description,
  }) {
    return _apiService.createPage(
      title: title,
      username: username,
      category: category,
      country: country,
      language: language,
      description: description,
    );
  }

  Future<void> updatePage({
    required int pageId,
    required String title,
    required int category,
    required int country,
    required int language,
    String? description,
  }) {
    return _apiService.updatePage(
      pageId: pageId,
      title: title,
      category: category,
      country: country,
      language: language,
      description: description,
    );
  }

  Future<void> updatePageSection({
    required int pageId,
    required String section,
    required Map<String, dynamic> data,
  }) {
    return _apiService.updatePageSection(
      pageId: pageId,
      section: section,
      data: data,
    );
  }

  Future<PageModel> fetchPageInfo({
    int? pageId,
    String? pageName,
    String? with_,
  }) {
    return _apiService.fetchPageInfo(
      pageId: pageId,
      pageName: pageName,
      with_: with_,
    );
  }

  Future<PostsResponse> fetchPagePosts({
    required String pageId,
    int limit = 10,
    int offset = 0,
  }) {
    return _apiService.fetchPagePosts(
      pageId: int.parse(pageId),
      limit: limit,
      offset: offset,
    );
  }

  Future<void> reactToPost(int postId, String reaction) {
    return _apiService.reactToPost(postId, reaction);
  }

  Future<void> inviteFriendsToPage({
    required int pageId,
    required List<int> userIds,
  }) {
    return _apiService.inviteFriendsToPage(
      pageId: pageId,
      userIds: userIds,
    );
  }

  Future<void> addAdmin({
    required int pageId,
    required int userId,
  }) {
    return _apiService.addAdmin(
      pageId: pageId,
      userId: userId,
    );
  }

  Future<void> removeAdmin({
    required int pageId,
    required int userId,
  }) {
    return _apiService.removeAdmin(
      pageId: pageId,
      userId: userId,
    );
  }

  Future<Map<String, dynamic>> requestVerification({
    required int pageId,
    String? photo,
    String? passport,
    String? businessWebsite,
    String? businessAddress,
    String? message,
  }) {
    return _apiService.requestVerification(
      pageId: pageId,
      photo: photo,
      passport: passport,
      businessWebsite: businessWebsite,
      businessAddress: businessAddress,
      message: message,
    );
  }

  Future<Map<String, dynamic>> updatePagePicture({
    required int pageId,
    required String pictureData,
  }) {
    return _apiService.updatePagePicture(
      pageId: pageId,
      pictureData: pictureData,
    );
  }

  Future<Map<String, dynamic>> updatePageCover({
    required int pageId,
    required String coverData,
  }) {
    return _apiService.updatePageCover(
      pageId: pageId,
      coverData: coverData,
    );
  }

  Future<List<PageCategory>> getPageCategories() {
    return _apiService.getPageCategories();
  }

  Future<List<Country>> getCountries() {
    return _apiService.getCountries();
  }

  Future<List<Language>> getLanguages() {
    return _apiService.getLanguages();
  }

  Future<void> deletePage({required int pageId}) {
    return _apiService.deletePage(pageId: pageId);
  }
}
