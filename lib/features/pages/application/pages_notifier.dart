import 'package:flutter/foundation.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/features/pages/data/models/page.dart';
import 'package:snginepro/features/pages/domain/pages_repository.dart';
enum PagesTab {
  myPages,
  likedPages,
  suggestedPages,
}
class PagesNotifier extends ChangeNotifier {
  PagesNotifier(this._repository);
  final PagesRepository _repository;
  final List<PageModel> _myPages = [];
  final List<PageModel> _likedPages = [];
  final List<PageModel> _suggestedPages = [];
  bool _isLoadingMyPages = false;
  bool _isLoadingLikedPages = false;
  bool _isLoadingSuggestedPages = false;
  String? _errorMyPages;
  String? _errorLikedPages;
  String? _errorSuggestedPages;
  PagesTab _currentTab = PagesTab.myPages;
  // Getters
  List<PageModel> get myPages => List.unmodifiable(_myPages);
  List<PageModel> get likedPages => List.unmodifiable(_likedPages);
  List<PageModel> get suggestedPages => List.unmodifiable(_suggestedPages);
  bool get isLoadingMyPages => _isLoadingMyPages;
  bool get isLoadingLikedPages => _isLoadingLikedPages;
  bool get isLoadingSuggestedPages => _isLoadingSuggestedPages;
  String? get errorMyPages => _errorMyPages;
  String? get errorLikedPages => _errorLikedPages;
  String? get errorSuggestedPages => _errorSuggestedPages;
  PagesTab get currentTab => _currentTab;
  bool get isLoading {
    switch (_currentTab) {
      case PagesTab.myPages:
        return _isLoadingMyPages;
      case PagesTab.likedPages:
        return _isLoadingLikedPages;
      case PagesTab.suggestedPages:
        return _isLoadingSuggestedPages;
    }
  }
  String? get error {
    switch (_currentTab) {
      case PagesTab.myPages:
        return _errorMyPages;
      case PagesTab.likedPages:
        return _errorLikedPages;
      case PagesTab.suggestedPages:
        return _errorSuggestedPages;
    }
  }
  List<PageModel> get currentPages {
    switch (_currentTab) {
      case PagesTab.myPages:
        return myPages;
      case PagesTab.likedPages:
        return likedPages;
      case PagesTab.suggestedPages:
        return suggestedPages;
    }
  }
  void setTab(PagesTab tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    notifyListeners();
    // Auto-load if empty
    switch (tab) {
      case PagesTab.myPages:
        if (_myPages.isEmpty && !_isLoadingMyPages) loadMyPages();
        break;
      case PagesTab.likedPages:
        if (_likedPages.isEmpty && !_isLoadingLikedPages) loadLikedPages();
        break;
      case PagesTab.suggestedPages:
        if (_suggestedPages.isEmpty && !_isLoadingSuggestedPages) {
          loadSuggestedPages();
        }
        break;
    }
  }
  Future<void> loadMyPages() async {
    if (_isLoadingMyPages) return;
    _isLoadingMyPages = true;
    _errorMyPages = null;
    notifyListeners();
    try {
      final pages = await _repository.fetchMyPages();
      _myPages
        ..clear()
        ..addAll(pages);
    } on ApiException catch (e) {
      _errorMyPages = e.message;
    } catch (e) {
      _errorMyPages = 'Failed to load my pages';
    } finally {
      _isLoadingMyPages = false;
      notifyListeners();
    }
  }
  Future<void> loadLikedPages() async {
    if (_isLoadingLikedPages) return;
    _isLoadingLikedPages = true;
    _errorLikedPages = null;
    notifyListeners();
    try {
      final pages = await _repository.fetchLikedPages();
      _likedPages
        ..clear()
        ..addAll(pages);
    } on ApiException catch (e) {
      _errorLikedPages = e.message;
    } catch (e) {
      _errorLikedPages = 'Failed to load liked pages';
    } finally {
      _isLoadingLikedPages = false;
      notifyListeners();
    }
  }
  Future<void> loadSuggestedPages({int limit = 10}) async {
    if (_isLoadingSuggestedPages) return;
    _isLoadingSuggestedPages = true;
    _errorSuggestedPages = null;
    notifyListeners();
    try {
      final pages = await _repository.fetchSuggestedPages(limit: limit);
      _suggestedPages
        ..clear()
        ..addAll(pages);
    } on ApiException catch (e) {
      _errorSuggestedPages = e.message;
      
    } catch (e) {
      _errorSuggestedPages = 'Failed to load suggested pages';
    } finally {
      _isLoadingSuggestedPages = false;
      notifyListeners();
    }
  }
  Future<void> refresh() async {
    switch (_currentTab) {
      case PagesTab.myPages:
        return loadMyPages();
      case PagesTab.likedPages:
        return loadLikedPages();
      case PagesTab.suggestedPages:
        return loadSuggestedPages();
    }
  }
  Future<void> toggleLikePage(PageModel page) async {
    try {
      await _repository.toggleLikePage(page.id, page.iLike);
      // Update local state optimistically
      if (page.iLike) {
        // Remove from liked pages
        _likedPages.removeWhere((p) => p.id == page.id);
      } else {
        // Add to liked pages (create updated copy)
        final updatedPage = PageModel(
          id: page.id,
          name: page.name,
          title: page.title,
          description: page.description,
          picture: page.picture,
          cover: page.cover,
          category: page.category,
          likes: page.likes + 1,
          verified: page.verified,
          boosted: page.boosted,
          iAdmin: page.iAdmin,
          iLike: true,
        );
        _likedPages.add(updatedPage);
      }
      // Update in suggested pages if present
      final suggIdx = _suggestedPages.indexWhere((p) => p.id == page.id);
      if (suggIdx != -1) {
        final p = _suggestedPages[suggIdx];
        _suggestedPages[suggIdx] = PageModel(
          id: p.id,
          name: p.name,
          title: p.title,
          description: p.description,
          picture: p.picture,
          cover: p.cover,
          category: p.category,
          likes: p.iLike ? p.likes - 1 : p.likes + 1,
          verified: p.verified,
          boosted: p.boosted,
          iAdmin: p.iAdmin,
          iLike: !p.iLike,
        );
      }
      notifyListeners();
    } catch (e) {
      // Could show snackbar error here
    }
  }
}
