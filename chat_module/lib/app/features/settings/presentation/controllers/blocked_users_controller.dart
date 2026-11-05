import 'package:get/get.dart';

import '../../data/models/blocked_users_models.dart';
import '../../data/services/blocked_users_service.dart';

class BlockedUsersController extends GetxController {
  BlockedUsersController(this._service);

  final BlockedUsersService _service;

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final isUpdating = <int, bool>{}.obs;
  final errorMessage = ''.obs;
  final items = <BlockedUserModel>[].obs;

  int? _nextOffset;
  bool _hasMore = false;
  final Set<int> _loadedIds = <int>{};

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({bool reset = true}) async {
    if (reset) {
      isLoading.value = true;
      errorMessage.value = '';
      items.clear();
      _loadedIds.clear();
      _nextOffset = null;
      _hasMore = false;
    } else {
      if (isLoading.value || isLoadingMore.value || !_hasMore) {
        return;
      }
      isLoadingMore.value = true;
    }

    try {
      final response = await _service.fetchBlockedUsers(
        offset: reset ? 0 : (_nextOffset ?? 0),
      );
      _nextOffset = response.nextOffset;
      _hasMore = response.hasMore;
      final freshItems = response.items.where(
        (item) => _loadedIds.add(item.id),
      );
      if (reset) {
        items.assignAll(freshItems.toList(growable: false));
      } else {
        items.addAll(freshItems);
      }
    } catch (error) {
      if (reset) {
        errorMessage.value = error.toString();
      }
    } finally {
      if (reset) {
        isLoading.value = false;
      } else {
        isLoadingMore.value = false;
      }
    }
  }

  Future<void> loadMore() => load(reset: false);

  Future<String> unblockUser(BlockedUserModel user) async {
    isUpdating[user.id] = true;
    try {
      final message = await _service.unblockUser(userId: user.id);
      items.removeWhere((item) => item.id == user.id);
      _loadedIds.remove(user.id);
      return message;
    } finally {
      isUpdating.remove(user.id);
    }
  }
}
