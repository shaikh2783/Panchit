import 'package:get/get.dart';

import '../../../../../settings.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../data/models/chat_call_models.dart';
import '../../../chat/data/services/chat_service.dart';

class CallsController extends GetxController {
  CallsController(this._chatService, this._preferences);

  final ChatService _chatService;
  final ChatAppPreferences _preferences;

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;
  final calls = <ChatCallModel>[].obs;
  final Set<int> _loadedCallIds = <int>{};
  int? _nextOffset;
  int? _lastRequestedOffset;
  bool _hasMore = false;

  bool get hasMore => _hasMore;

  @override
  void onInit() {
    super.onInit();
    if (!_preferences.hasActiveSession()) {
      isLoading.value = false;
      return;
    }
    load();
  }

  Future<void> load({bool reset = true}) async {
    if (!_preferences.hasActiveSession()) {
      isLoading.value = false;
      isLoadingMore.value = false;
      errorMessage.value = '';
      calls.clear();
      _loadedCallIds.clear();
      _nextOffset = null;
      _lastRequestedOffset = null;
      _hasMore = false;
      return;
    }
    if (reset) {
      isLoading.value = true;
      errorMessage.value = '';
      calls.clear();
      _loadedCallIds.clear();
      _nextOffset = null;
      _lastRequestedOffset = null;
      _hasMore = false;
    } else {
      if (isLoading.value ||
          isLoadingMore.value ||
          !_hasMore ||
          _nextOffset == null ||
          _lastRequestedOffset == _nextOffset) {
        return;
      }
      isLoadingMore.value = true;
    }

    try {
      final requestedOffset = reset ? 0 : _nextOffset!;
      _lastRequestedOffset = requestedOffset;
      final response = await _chatService.fetchCalls(offset: requestedOffset);
      _nextOffset = response.nextOffset;
      _hasMore = response.hasMore;
      final freshItems = response.items.where((item) {
        return _loadedCallIds.add(item.callId);
      }).toList();
      if (reset) {
        calls.assignAll(freshItems);
      } else if (freshItems.isNotEmpty) {
        calls.addAll(freshItems);
      } else {
        // The backend reported more pages, but this page only repeated items
        // we already have. Stop pagination locally to avoid endless requests.
        _hasMore = false;
      }
    } catch (error) {
      if (reset) {
        errorMessage.value = AppRuntimeSettings.resolveRuntimeApiMessage(
          error.toString(),
        );
        calls.clear();
        _loadedCallIds.clear();
      } else {
        // Allow the same page to be requested again after a transient error.
        _lastRequestedOffset = null;
      }
    } finally {
      if (reset) {
        isLoading.value = false;
      } else {
        isLoadingMore.value = false;
      }
    }
  }

  Future<void> loadMore() {
    return load(reset: false);
  }
}
