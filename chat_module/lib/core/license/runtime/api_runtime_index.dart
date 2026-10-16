import 'api_runtime_slot.dart';

class ApiRuntimeIndex {
  ApiRuntimeIndex._();

  static const List<int> _shuffledIndexes = <int>[1, 2, 0];

  static int resolve(ApiRuntimeSlot slot) {
    return _shuffledIndexes[slot.index];
  }
}
