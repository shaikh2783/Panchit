import '../api_runtime_store.dart';

class ApiCredentialEntry {
  ApiCredentialEntry._();

  static String read() => ApiRuntimeStore.readCredential();
}
