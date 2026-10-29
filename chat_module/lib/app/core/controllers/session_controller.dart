import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../settings.dart';
import '../../data/api/api_exception.dart';
import '../../data/services/fcm_call_service.dart';
import '../../data/services/one_signal_service.dart';
import '../../features/auth/data/models/auth_flow_state_model.dart';
import '../../features/auth/data/models/login_result_model.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../../features/groups_chat/presentation/controllers/groups_chat_controller.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../storage/app_preferences.dart';
import '../utils/call_trace_logger.dart';

enum SessionViewState { loading, login, home, authFlow, banned }

class SessionController extends GetxController {
  SessionController(
    this._authService,
    this._preferences,
    this._oneSignalService,
    this._fcmCallService,
  );

  final AuthService _authService;
  final ChatAppPreferences _preferences;
  final OneSignalService _oneSignalService;
  final FcmCallService _fcmCallService;

  final state = SessionViewState.loading.obs;
  final authFlowState = Rxn<AuthFlowStateModel>();
  final currentUserName = ''.obs;
  final currentUserEmail = ''.obs;
  final currentUserPicture = ''.obs;
  final bannedMessage = ''.obs;
  final hasTimelineBridgeSession = false.obs;
  final isApplyingTimelineBridge = false.obs;
  final pendingTimelineUserName = ''.obs;
  final pendingTimelineUserPicture = ''.obs;
  final isDeletingAccount = false.obs;

  bool get isActiveTimelineBridgeSession =>
      _preferences.isActiveTimelineBridgeSession();

  @override
  void onInit() {
    super.onInit();
    bootstrap();
  }

  Future<void> bootstrap() async {
    unawaited(
      CallTraceLogger.log(
        'SessionController',
        'bootstrap started hasActiveSession=${_preferences.hasActiveSession()} '
            'hasPendingSession=${_preferences.hasPendingSession()}',
      ),
    );
    state.value = SessionViewState.loading;
    hasTimelineBridgeSession.value = false;
    pendingTimelineUserName.value = '';
    pendingTimelineUserPicture.value = '';
    bannedMessage.value = '';

    if (_preferences.hasActiveSession()) {
      _restoreLocalSessionState();
      unawaited(
        CallTraceLogger.log(
          'SessionController',
          'restored local active session -> state=${state.value}',
        ),
      );
      unawaited(_validateActiveSessionInBackground());
      return;
    }

    if (_preferences.hasPendingSession()) {
      final pendingStep = _preferences.getPendingNextStep() ?? '';
      final hasTimelineBridge = _preferences.hasTimelineBridgeSession();
      hasTimelineBridgeSession.value = hasTimelineBridge;
      if (hasTimelineBridge && pendingStep == 'timeline_sso') {
        pendingTimelineUserName.value =
            _preferences.getPendingUserName()?.trim() ?? '';
        pendingTimelineUserPicture.value =
            _preferences.getPendingUserPicture()?.trim() ?? '';
        state.value = SessionViewState.login;
        unawaited(
          CallTraceLogger.log(
            'SessionController',
            'pending timeline bridge session -> state=${state.value}',
          ),
        );
        return;
      }
      authFlowState.value = AuthFlowStateModel(
        nextStep: pendingStep,
        activationType: '',
        email: _preferences.getPendingEmail() ?? '',
        userName: '',
        userPicture: '',
        message: '',
        isBanned: false,
        bannedMessage: '',
        isActivated: false,
        isApproved: false,
        isStarted: false,
        activationRequired: pendingStep == 'activation',
        approvalRequired: pendingStep == 'approval',
        gettingStartedRequired: pendingStep == 'getting_started',
      );
      _syncOneSignalFromPendingSession(requestPermission: false);
      if (_shouldBypassGettingStarted(pendingStep)) {
        _restoreLocalSessionState();
        return;
      }
      state.value = SessionViewState.authFlow;
      unawaited(
        CallTraceLogger.log(
          'SessionController',
          'pending auth flow -> state=${state.value}',
        ),
      );
      return;
    }

    state.value = SessionViewState.login;
    unawaited(
      CallTraceLogger.log(
        'SessionController',
        'no saved session -> state=${state.value}',
      ),
    );
  }

  Future<void> _validateActiveSessionInBackground() async {
    try {
      final result = await _authService.fetchAuthState();
      await applyAuthFlowState(result);
      return;
    } on ApiException catch (error) {
      if (_isBannedFailure(error)) {
        await markAccountBanned(error.message);
        return;
      }
      if (_isAuthenticationFailure(error)) {
        await _oneSignalService.detachCurrentUser(deleteRemote: false);
        await _preferences.clearSession();
        state.value = SessionViewState.login;
        return;
      }

      _restoreLocalSessionState();
      return;
    } catch (_) {
      await _oneSignalService.detachCurrentUser(deleteRemote: false);
      await _preferences.clearSession();
      state.value = SessionViewState.login;
      return;
    }
  }

  Future<void> applyLoginResult(LoginResultModel result) async {
    if (result.isBanned) {
      await markAccountBanned(result.bannedMessage);
      return;
    }

    hasTimelineBridgeSession.value = false;
    pendingTimelineUserName.value = '';
    pendingTimelineUserPicture.value = '';
    bannedMessage.value = '';
    currentUserName.value = result.user?.name ?? '';
    currentUserEmail.value = result.user?.email ?? '';
    currentUserPicture.value = result.user?.picture ?? '';
    _syncOneSignal(
      userId: result.userId,
      authTokenOverride: result.sessionToken,
      requestPermission: _shouldEnterHome(
        result.resolvedNextStep,
        result.isActivated,
        result.isApproved,
      ),
    );
    _syncFcm(
      userId: result.userId,
      authTokenOverride: result.sessionToken,
      requestPermission: _shouldEnterHome(
        result.resolvedNextStep,
        result.isActivated,
        result.isApproved,
      ),
    );

    if (_shouldEnterHome(
      result.resolvedNextStep,
      result.isActivated,
      result.isApproved,
    )) {
      _refreshHomeScopedData();
      state.value = SessionViewState.home;
      unawaited(
        CallTraceLogger.log(
          'SessionController',
          'applyLoginResult -> state=${state.value}',
        ),
      );
      return;
    }

    authFlowState.value = AuthFlowStateModel(
      nextStep: result.resolvedNextStep,
      activationType: '',
      email: result.user?.email ?? '',
      userName: result.user?.name ?? '',
      userPicture: result.user?.picture ?? '',
      message: '',
      isBanned: false,
      bannedMessage: '',
      isActivated: result.isActivated,
      isApproved: result.isApproved,
      isStarted: result.isStarted,
      activationRequired: result.activationRequired,
      approvalRequired: result.approvalRequired,
      gettingStartedRequired: result.gettingStartedRequired,
    );
    state.value = SessionViewState.authFlow;
    unawaited(
      CallTraceLogger.log(
        'SessionController',
        'applyLoginResult -> state=${state.value}',
      ),
    );
  }

  Future<void> promotePendingSession() async {
    if (!_preferences.hasPendingSession()) {
      return;
    }
    await _preferences.promotePendingSession();
  }

  Future<void> applyAuthFlowState(AuthFlowStateModel result) async {
    if (result.isBanned) {
      await markAccountBanned(result.bannedMessage);
      return;
    }

    hasTimelineBridgeSession.value = false;
    pendingTimelineUserName.value = '';
    pendingTimelineUserPicture.value = '';
    bannedMessage.value = '';
    currentUserName.value = result.userName;
    currentUserEmail.value = result.email;
    currentUserPicture.value = result.userPicture;
    authFlowState.value = result;
    _syncOneSignal(
      userId: _preferences.getUserId() ?? _preferences.getPendingUserId() ?? 0,
      requestPermission: _shouldEnterHome(
        result.resolvedNextStep,
        result.isActivated,
        result.isApproved,
      ),
    );
    _syncFcm(
      userId: _preferences.getUserId() ?? _preferences.getPendingUserId() ?? 0,
      requestPermission: _shouldEnterHome(
        result.resolvedNextStep,
        result.isActivated,
        result.isApproved,
      ),
    );
    if (_shouldEnterHome(
      result.resolvedNextStep,
      result.isActivated,
      result.isApproved,
    )) {
      _refreshHomeScopedData();
      state.value = SessionViewState.home;
      unawaited(
        CallTraceLogger.log(
          'SessionController',
          'applyAuthFlowState -> state=${state.value}',
        ),
      );
      return;
    }
    state.value = SessionViewState.authFlow;
    unawaited(
      CallTraceLogger.log(
        'SessionController',
        'applyAuthFlowState -> state=${state.value}',
      ),
    );
  }

  Future<void> signOut() async {
    try {
      await _fcmCallService.detachCurrentUser();
    } catch (_) {}

    try {
      await _oneSignalService.detachCurrentUser();
    } catch (_) {}

    try {
      await _authService.signOut();
    } catch (_) {
      await _preferences.clearSession();
    } finally {
      _clearSessionState();
      _refreshHomeScopedData();
      _returnToLoginRoot();
    }
  }

  Future<String> deleteAccount() async {
    if (isDeletingAccount.value) {
      return '';
    }

    isDeletingAccount.value = true;
    try {
      final message = await _authService.deleteAccount();
      await _fcmCallService.detachCurrentUser(deleteRemote: false);
      await _oneSignalService.detachCurrentUser(deleteRemote: false);
      _clearSessionState();
      _refreshHomeScopedData();
      _returnToLoginRoot();
      return message;
    } finally {
      isDeletingAccount.value = false;
    }
  }

  Future<void> markAccountBanned(String message) async {
    await _fcmCallService.detachCurrentUser(deleteRemote: false);
    await _oneSignalService.detachCurrentUser(deleteRemote: false);
    await _preferences.clearSession();
    hasTimelineBridgeSession.value = false;
    pendingTimelineUserName.value = '';
    pendingTimelineUserPicture.value = '';
    currentUserName.value = '';
    currentUserEmail.value = '';
    currentUserPicture.value = '';
    authFlowState.value = null;
    bannedMessage.value = message.trim().isEmpty
        ? 'Your account has been banned'
        : message.trim();
    state.value = SessionViewState.banned;
  }

  Future<void> switchConnectedAccount({
    required String token,
    required int userId,
    String? userName,
    String? email,
    String? picture,
  }) async {
    await _preferences.setAuthToken(token);
    await _preferences.setUserId(userId);
    await _preferences.setActiveTimelineBridgeSession(false);
    currentUserName.value = userName?.trim() ?? '';
    currentUserEmail.value = email?.trim() ?? '';
    currentUserPicture.value = picture?.trim() ?? '';
    _syncOneSignal(userId: userId, requestPermission: true);
    _syncFcm(userId: userId, requestPermission: true);
  }

  Future<void> importTimelineSession({
    required String token,
    required int userId,
    String? userName,
    String? userPicture,
  }) async {
    if (token.trim().isEmpty ||
        userId <= 0 ||
        _preferences.hasActiveSession()) {
      return;
    }
    await _preferences.setPendingSession(
      token: token,
      userId: userId,
      nextStep: 'timeline_sso',
      userName: userName,
      userPicture: userPicture,
      timelineBridge: true,
    );
    hasTimelineBridgeSession.value = true;
    pendingTimelineUserName.value = userName?.trim() ?? '';
    pendingTimelineUserPicture.value = userPicture?.trim() ?? '';
    if (state.value != SessionViewState.home) {
      state.value = SessionViewState.login;
    }
  }

  Future<bool> applyTimelineBridgeSession() async {
    if (!_preferences.hasPendingSession() ||
        !_preferences.hasTimelineBridgeSession()) {
      return false;
    }

    isApplyingTimelineBridge.value = true;
    state.value = SessionViewState.loading;
    try {
      await _preferences.promotePendingSession();
      final result = await _authService.fetchAuthState();
      await applyAuthFlowState(result);
      return true;
    } on ApiException catch (error) {
      debugPrint(
        '[applyTimelineBridgeSession] ApiException status=${error.statusCode} message=${error.message}',
      );
      if (_isBannedFailure(error)) {
        await markAccountBanned(error.message);
        return false;
      }
      if (_isAuthenticationFailure(error)) {
        await _fcmCallService.detachCurrentUser(deleteRemote: false);
        await _oneSignalService.detachCurrentUser(deleteRemote: false);
        await _preferences.clearSession();
        hasTimelineBridgeSession.value = false;
        pendingTimelineUserName.value = '';
        pendingTimelineUserPicture.value = '';
        authFlowState.value = null;
        state.value = SessionViewState.login;
        return false;
      }

      _restoreLocalSessionState();
      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '[applyTimelineBridgeSession] unexpected error: $error\n$stackTrace',
      );
      await _fcmCallService.detachCurrentUser(deleteRemote: false);
      await _oneSignalService.detachCurrentUser(deleteRemote: false);
      await _preferences.clearSession();
      hasTimelineBridgeSession.value = false;
      pendingTimelineUserName.value = '';
      pendingTimelineUserPicture.value = '';
      authFlowState.value = null;
      state.value = SessionViewState.login;
      return false;
    } finally {
      isApplyingTimelineBridge.value = false;
    }
  }

  /// In-process sibling of [importTimelineSession] + [applyTimelineBridgeSession]
  /// for a host app embedding this module directly (no deep link involved).
  /// Unlike [importTimelineSession], this always reconciles against the
  /// host's current identity rather than no-op'ing when a session already
  /// exists, so re-opening chat after the host switches accounts attaches
  /// the right user.
  Future<bool> attachExternalSession({
    required String token,
    required int userId,
    String? userName,
    String? userPicture,
  }) async {
    if (token.trim().isEmpty || userId <= 0) {
      return false;
    }

    if (_preferences.hasActiveSession() && _preferences.getUserId() == userId) {
      // The host may have cleared this user's push registration on logout or
      // account switch while the chat session stayed; re-register (deduped).
      _syncOneSignal(userId: userId, requestPermission: false);
      _syncFcm(userId: userId, requestPermission: false);
      return true;
    }

    await _preferences.setPendingSession(
      token: token,
      userId: userId,
      nextStep: 'host_app_sso',
      userName: userName,
      userPicture: userPicture,
      timelineBridge: true,
    );
    hasTimelineBridgeSession.value = true;
    pendingTimelineUserName.value = userName?.trim() ?? '';
    pendingTimelineUserPicture.value = userPicture?.trim() ?? '';

    return applyTimelineBridgeSession();
  }

  bool _isAuthenticationFailure(ApiException error) {
    final statusCode = error.statusCode ?? 0;
    return statusCode == 401 || statusCode == 403;
  }

  bool _isBannedFailure(ApiException error) {
    return error.message.toLowerCase().contains('banned');
  }

  void _restoreLocalSessionState() {
    hasTimelineBridgeSession.value = _preferences.hasTimelineBridgeSession();
    bannedMessage.value = '';
    _syncOneSignal(
      userId: _preferences.getUserId() ?? _preferences.getPendingUserId() ?? 0,
      requestPermission: false,
    );
    _syncFcm(
      userId: _preferences.getUserId() ?? _preferences.getPendingUserId() ?? 0,
      requestPermission: false,
    );
    _refreshHomeScopedData();
    state.value = SessionViewState.home;
  }

  void _refreshHomeScopedData() {
    if (Get.isRegistered<HomeController>()) {
      unawaited(Get.find<HomeController>().load());
    }
    if (Get.isRegistered<GroupsChatController>()) {
      unawaited(Get.find<GroupsChatController>().load());
    }
  }

  bool _shouldEnterHome(String nextStep, bool isActivated, bool isApproved) {
    final normalized = nextStep.trim().toLowerCase();
    if (normalized == 'home') {
      return true;
    }
    return _shouldBypassGettingStarted(normalized) && isActivated && isApproved;
  }

  bool _shouldBypassGettingStarted(String nextStep) {
    return !gettingStartedFlowEnabled &&
        nextStep.trim().toLowerCase() == 'getting_started';
  }

  void _syncOneSignal({
    required int userId,
    String? authTokenOverride,
    required bool requestPermission,
  }) {
    if (userId <= 0) {
      return;
    }

    unawaited(
      _oneSignalService.syncUserSession(
        userId: userId,
        authTokenOverride: authTokenOverride,
        requestPermission: requestPermission,
      ),
    );
  }

  void _syncOneSignalFromPendingSession({required bool requestPermission}) {
    final pendingUserId = _preferences.getPendingUserId() ?? 0;
    final pendingToken = _preferences.getPendingAuthToken();
    _syncOneSignal(
      userId: pendingUserId,
      authTokenOverride: pendingToken,
      requestPermission: requestPermission,
    );
    _syncFcm(
      userId: pendingUserId,
      authTokenOverride: pendingToken,
      requestPermission: requestPermission,
    );
  }

  void _syncFcm({
    required int userId,
    String? authTokenOverride,
    required bool requestPermission,
  }) {
    if (userId <= 0) {
      return;
    }

    unawaited(
      _fcmCallService.syncUserSession(
        userId: userId,
        authTokenOverride: authTokenOverride,
        requestPermission: requestPermission,
      ),
    );
  }

  void _clearSessionState() {
    hasTimelineBridgeSession.value = false;
    pendingTimelineUserName.value = '';
    pendingTimelineUserPicture.value = '';
    currentUserName.value = '';
    currentUserEmail.value = '';
    currentUserPicture.value = '';
    bannedMessage.value = '';
    authFlowState.value = null;
    state.value = SessionViewState.login;
  }

  void _returnToLoginRoot() {
    Get.closeAllSnackbars();
    final navigator = Get.key.currentState;
    if (navigator == null) {
      return;
    }
    navigator.popUntil((route) => route.isFirst);
  }
}
