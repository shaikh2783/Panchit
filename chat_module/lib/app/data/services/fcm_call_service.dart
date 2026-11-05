import '../../core/storage/app_preferences.dart';
import '../api/api_client.dart';

/// Phase 1 stub: FCM/VoIP push for background incoming-call delivery is
/// deferred (requires adding Firebase to the host app). In-app incoming
/// calls while chat is foregrounded are still detected via REST polling
/// elsewhere (see `incomingCallPollingEnabled` in settings.dart).
class FcmCallService {
  FcmCallService(this._apiClient, this._preferences);

  // ignore: unused_field
  final ChatModuleApiClient _apiClient;
  // ignore: unused_field
  final ChatAppPreferences _preferences;

  static void registerBackgroundHandler() {}

  Future<void> initialize() async {}

  Future<void> retryPendingIncomingCallPayload({String reason = 'manual'}) async {}

  Future<void> syncUserSession({
    required int userId,
    String? authTokenOverride,
    bool requestPermission = false,
  }) async {}

  Future<void> detachCurrentUser({bool deleteRemote = true}) async {}
}
