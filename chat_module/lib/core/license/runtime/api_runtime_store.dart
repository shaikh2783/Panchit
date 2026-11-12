import 'api_runtime_index.dart';
import 'api_runtime_nodes.dart';
import 'api_runtime_slot.dart';

class ApiRuntimeStore {
  ApiRuntimeStore._();

  static String readOrigin() => _read(ApiRuntimeSlot.origin);

  static String readCredential() => _read(ApiRuntimeSlot.credential);

  static String readSignatureSeed() => _read(ApiRuntimeSlot.signatureSeed);

  static String _read(ApiRuntimeSlot slot) {
    final index = ApiRuntimeIndex.resolve(slot);
    return ApiRuntimeNodes.values[index]();
  }
}
