import 'package:flutter/foundation.dart';

import '../../../../settings.dart';

class GroupsChatLogger {
  GroupsChatLogger._();

  static void log(String scope, String message) {
    if (!groupsChatLoggingEnabled) {
      return;
    }
    debugPrint('[GroupsChat][$scope] $message');
  }

  static void error(String scope, Object error, [StackTrace? stackTrace]) {
    if (!groupsChatLoggingEnabled) {
      return;
    }
    debugPrint('[GroupsChat][$scope][ERROR] $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
