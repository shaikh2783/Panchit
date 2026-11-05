import '../api_runtime_store.dart';

class ApiSignatureEntry {
  ApiSignatureEntry._();

  static String read() => ApiRuntimeStore.readSignatureSeed();
}
