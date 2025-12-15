import 'package:flutter/foundation.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/reels/domain/reels_repository.dart';
class ReelsNotifier extends ChangeNotifier {
  ReelsNotifier(this._repository);
  final ReelsRepository _repository;
  final List<Post> _reels = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _error;
  int _page = 0;
  final int _limit = 10;
  String _source = 'all';
  List<Post> get reels => List.unmodifiable(_reels);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get source => _source;
  Future<void> loadInitial({String? source}) async {
    if (_isLoading) return;
    _isLoading = true;
    if (source != null && source.isNotEmpty && source != _source) {
      _source = source;
    }
    _error = null;
    notifyListeners();
    try {
      final response = await _repository.fetchReels(
        limit: _limit,
        offset: 0,
        source: _source,
      );
      _reels
        ..clear()
        ..addAll(response.reels);
      _page = 1;
      _hasMore = response.hasMore;
    } on ApiException catch (error) {
      _error = error.message;
    } catch (error, stackTrace) {
      _error = 'تعذر تحميل الريلز، يرجى المحاولة لاحقاً.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _repository.fetchReels(
        limit: _limit,
        offset: 0,
        source: _source,
      );
      _reels
        ..clear()
        ..addAll(response.reels);
      _page = 1;
      _hasMore = response.hasMore;
    } on ApiException catch (error) {
      _error = error.message;
    } catch (error, stackTrace) {
      _error = 'حدث خطأ أثناء تحديث الريلز.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _repository.fetchReels(
        limit: _limit,
        offset: _page,
        source: _source,
      );
      _reels.addAll(response.reels);
      if (response.reels.isNotEmpty) {
        _page += 1;
      }
      _hasMore = response.hasMore;
    } on ApiException catch (error) {
      _error = error.message;
    } catch (error, stackTrace) {
      _error = 'حدث خطأ أثناء جلب المزيد من الريلز.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  void changeSource(String source) {
    if (source == _source) return;
    _source = source;
    clear();
    loadInitial();
  }
  void clear() {
    _reels.clear();
    _page = 0;
    _hasMore = false;
    _isLoading = false;
    _isRefreshing = false;
    _isLoadingMore = false;
    _error = null;
    notifyListeners();
  }
}
