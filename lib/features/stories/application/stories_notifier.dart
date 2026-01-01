import 'package:flutter/foundation.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/features/stories/data/models/story.dart';
import 'package:snginepro/features/stories/domain/stories_repository.dart';

class StoriesNotifier extends ChangeNotifier {
  StoriesNotifier(this._repository);

  final StoriesRepository _repository;

  final List<Story> _stories = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  String _format = 'both';

  List<Story> get stories => List.unmodifiable(_stories);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  String get format => _format;

  /// Get user's own stories
  List<Story> get myStories => _stories.where((s) => s.isOwner).toList();

  /// Get other users' stories
  List<Story> get otherStories => _stories.where((s) => !s.isOwner).toList();

  Future<void> loadInitial({String? format}) async {
    if (_isLoading) return;
    _isLoading = true;
    if (format != null && format.isNotEmpty && format != _format) {
      _format = format;
    }
    _error = null;
    notifyListeners();
    try {
      final response = await _repository.fetchStories(format: _format);
      _stories
        ..clear()
        ..addAll(response.stories);
    } on ApiException catch (error) {
      _error = error.message;
    } catch (error, stackTrace) {
      _error = 'تعذر تحميل القصص، يرجى المحاولة لاحقاً.';
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
      final response = await _repository.fetchStories(format: _format);
      _stories
        ..clear()
        ..addAll(response.stories);
    } on ApiException catch (error) {
      _error = error.message;
    } catch (error, stackTrace) {
      _error = 'حدث خطأ أثناء تحديث القصص.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void changeFormat(String format) {
    if (format == _format) return;
    _format = format;
    clear();
    loadInitial();
  }

  void clear() {
    _stories.clear();
    _isLoading = false;
    _isRefreshing = false;
    _error = null;
    notifyListeners();
  }
}
