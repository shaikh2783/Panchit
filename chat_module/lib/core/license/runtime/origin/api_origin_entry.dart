import '../api_runtime_store.dart';

class ApiOriginEntry {
  ApiOriginEntry._();

  static String read() => ApiRuntimeStore.readOrigin();
}
