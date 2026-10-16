import 'dart:async';

import 'package:get/get.dart';

import '../../../../../settings.dart';
import '../../../../core/controllers/session_controller.dart';
import '../../../../core/utils/call_trace_logger.dart';
import '../../data/models/chat_call_models.dart';
import '../../data/services/agora_call_service.dart';
import '../../../../data/services/call_notification_service.dart';
import '../../../../data/services/fcm_call_service.dart';
import '../../../chat/data/services/chat_service.dart';
import '../pages/agora_call_page.dart';
import '../pages/webrtc_call_page.dart';

class IncomingCallController extends GetxController {
  IncomingCallController({
    required ChatService chatService,
    required SessionController sessionController,
  }) : _chatService = chatService,
       _sessionController = sessionController;

  final ChatService _chatService;
  final SessionController _sessionController;

  Timer? _pollTimer;
  Worker? _sessionWorker;
  bool _isChecking = false;
  bool _isShowingIncomingCall = false;
  int? _activeIncomingCallId;

  @override
  void onInit() {
    super.onInit();
    unawaited(
      CallTraceLogger.log(
        'IncomingCallController',
        'onInit state=${_sessionController.state.value}',
      ),
    );
    _sessionWorker = ever<SessionViewState>(_sessionController.state, (state) {
      unawaited(
        CallTraceLogger.log(
          'IncomingCallController',
          'session changed to $state',
        ),
      );
      _syncPolling();
    });
    _syncPolling();
    if (Get.isRegistered<FcmCallService>()) {
      unawaited(
        Get.find<FcmCallService>().retryPendingIncomingCallPayload(
          reason: 'incoming_controller_on_init',
        ),
      );
    }
  }

  @override
  void onClose() {
    _sessionWorker?.dispose();
    _pollTimer?.cancel();
    super.onClose();
  }

  void _syncPolling() {
    final shouldPoll =
        incomingCallPollingEnabled &&
        _sessionController.state.value == SessionViewState.home;
    unawaited(
      CallTraceLogger.log(
        'IncomingCallController',
        '_syncPolling shouldPoll=$shouldPoll state=${_sessionController.state.value}',
      ),
    );
    if (!shouldPoll) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    _pollTimer ??= Timer.periodic(
      incomingCallPollingInterval,
      (_) => unawaited(_checkIncomingCall()),
    );
    unawaited(_checkIncomingCall());
    if (Get.isRegistered<FcmCallService>()) {
      unawaited(
        Get.find<FcmCallService>().retryPendingIncomingCallPayload(
          reason: 'incoming_controller_sync_polling_home',
        ),
      );
    }
  }

  Future<void> _checkIncomingCall() async {
    if (_isChecking || _isShowingIncomingCall) {
      return;
    }

    _isChecking = true;
    try {
      final result = await _chatService.checkNewCall();
      final call = result.call;
      if (!result.hasNewCall || call == null || call.callId == 0) {
        return;
      }
      if (_activeIncomingCallId == call.callId) {
        return;
      }
      await presentIncomingCall(call);
    } catch (_) {
    } finally {
      _isChecking = false;
    }
  }

  Future<bool> presentIncomingCall(
    ChatCallModel call, {
    bool autoAccept = false,
  }) async {
    if (_activeIncomingCallId == call.callId) {
      await CallTraceLogger.log(
        'IncomingCallController',
        'presentIncomingCall consumed duplicate callId=${call.callId} '
            'isShowing=$_isShowingIncomingCall active=$_activeIncomingCallId',
      );
      return true;
    }

    if (_isShowingIncomingCall) {
      await CallTraceLogger.log(
        'IncomingCallController',
        'presentIncomingCall ignored busy callId=${call.callId} '
            'active=$_activeIncomingCallId',
      );
      return false;
    }

    final sessionState = _sessionController.state.value;
    if (sessionState == SessionViewState.login ||
        sessionState == SessionViewState.banned) {
      await CallTraceLogger.log(
        'IncomingCallController',
        'presentIncomingCall blocked by sessionState=$sessionState callId=${call.callId}',
      );
      return false;
    }

    final navigationContext =
        Get.context ?? Get.overlayContext ?? Get.key.currentContext;
    if (navigationContext == null) {
      await CallTraceLogger.log(
        'IncomingCallController',
        'presentIncomingCall blocked because navigationContext is null '
            'callId=${call.callId} state=$sessionState',
      );
      return false;
    }

    await CallTraceLogger.log(
      'IncomingCallController',
      'presentIncomingCall opening AgoraCallPage callId=${call.callId} '
          'autoAccept=$autoAccept state=$sessionState',
    );

    _activeIncomingCallId = call.callId;
    _isShowingIncomingCall = true;

    try {
      try {
        await CallNotificationService.cancelIncomingCallNotification(
          call.callId,
        );
      } catch (error) {
        await CallTraceLogger.log(
          'IncomingCallController',
          'cancelIncomingCallNotification failed for callId=${call.callId}: $error',
        );
      }
      final useWebRtc =
          call.connection?.isWebRtc == true || isWebRtcCallProvider;
      await Get.to<void>(
        () => useWebRtc
            ? WebRtcCallPage(
                conversationId: call.callId,
                recipientUserId: call.fromUserId,
                conversationTitle: call.callerName.isEmpty
                    ? 'Caller'
                    : call.callerName,
                avatarUrl: call.callerPicture,
                callType: call.isVideoCall
                    ? AgoraCallType.video
                    : AgoraCallType.voice,
                isIncoming: true,
                initialCall: call,
                autoAccept: autoAccept,
              )
            : AgoraCallPage(
                conversationId: call.callId,
                recipientUserId: call.fromUserId,
                conversationTitle: call.callerName.isEmpty
                    ? 'Caller'
                    : call.callerName,
                avatarUrl: call.callerPicture,
                callType: call.isVideoCall
                    ? AgoraCallType.video
                    : AgoraCallType.voice,
                isIncoming: true,
                initialCall: call,
                autoAccept: autoAccept,
              ),
        preventDuplicates: false,
      );
      await CallTraceLogger.log(
        'IncomingCallController',
        'AgoraCallPage closed for callId=${call.callId}',
      );
      return true;
    } finally {
      _isShowingIncomingCall = false;
      _activeIncomingCallId = null;
      await CallTraceLogger.log(
        'IncomingCallController',
        'presentIncomingCall cleanup callId=${call.callId}',
      );
    }
  }
}
