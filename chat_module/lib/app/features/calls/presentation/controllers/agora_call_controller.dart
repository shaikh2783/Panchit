import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock/wakelock.dart';

import '../../../../../settings.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/utils/call_trace_logger.dart';
import '../../../../data/services/call_notification_service.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../data/models/chat_call_models.dart';
import '../../data/services/agora_call_service.dart';

class AgoraCallController extends GetxController {
  static const MethodChannel _callAudioChannel = MethodChannel(
    'messenger/call_audio',
  );
  static const AndroidAudioAttributes _incomingRingtoneAttributes =
      AndroidAudioAttributes(
        contentType: AndroidAudioContentType.sonification,
        usage: AndroidAudioUsage.notificationRingtone,
      );
  static const AndroidAudioAttributes _outgoingRingbackAttributes =
      AndroidAudioAttributes(
        contentType: AndroidAudioContentType.sonification,
        usage: AndroidAudioUsage.voiceCommunicationSignalling,
      );

  AgoraCallController({
    required AgoraCallService callService,
    required ChatService chatService,
    required this.conversationId,
    required this.recipientUserId,
    required this.conversationTitle,
    required this.avatarUrl,
    required this.callType,
    this.isIncoming = false,
    this.initialCall,
    this.autoAccept = false,
  }) : _callService = callService,
       _chatService = chatService {
    isSpeakerOn.value = callType == AgoraCallType.video;
  }

  final AgoraCallService _callService;
  final ChatService _chatService;
  final int conversationId;
  final int recipientUserId;
  final String conversationTitle;
  final String avatarUrl;
  final AgoraCallType callType;
  final bool isIncoming;
  final ChatCallModel? initialCall;
  final bool autoAccept;

  final isInitializing = true.obs;
  final isConnected = false.obs;
  final isMuted = false.obs;
  final isCameraOff = false.obs;
  final isSpeakerOn = false.obs;
  final hasLocalUserJoined = false.obs;
  final remoteUid = RxnInt();
  final errorMessage = ''.obs;
  final statusText = ''.obs;
  final callDurationText = '00:00'.obs;
  final isLocalPreviewReady = false.obs;
  final isAwaitingIncomingDecision = false.obs;

  AudioPlayer? _incomingRingtonePlayer;
  AudioPlayer? _outgoingRingbackPlayer;
  static AgoraCallController? activeInstance;
  RtcEngine? _engine;
  Timer? _heartbeatTimer;
  Timer? _incomingDecisionTimer;
  Timer? _callDurationTimer;
  int? _activeCallId;
  bool _isEngineInitialized = false;
  bool _isEventHandlerRegistered = false;
  bool _isEndingCall = false;
  bool _callWasAnswered = false;
  bool _isHandlingIncomingDecision = false;
  int _incomingRingtoneGeneration = 0;
  int _outgoingRingbackGeneration = 0;

  bool get isVideoCall => callType == AgoraCallType.video;
  String get channelName => _connectedCall?.connection?.room ?? '';

  RtcEngine? get engine => _engine;
  ChatCallModel? _connectedCall;

  @override
  void onInit() {
    super.onInit();
    activeInstance = this;
    statusText.value = AppTranslations.callConnecting.tr;
    unawaited(_enableWakelock());
    unawaited(initialize());
  }

  @override
  void onClose() {
    if (identical(activeInstance, this)) {
      activeInstance = null;
    }
    _heartbeatTimer?.cancel();
    _incomingDecisionTimer?.cancel();
    _callDurationTimer?.cancel();
    unawaited(_stopAllCallAudio());
    unawaited(_disableWakelock());
    unawaited(_disposeEngine());
    super.onClose();
  }

  Future<void> initialize() async {
    if (!_callService.isEnabled) {
      errorMessage.value = AppTranslations.callAgoraDisabled.tr;
      isInitializing.value = false;
      return;
    }

    try {
      if (isIncoming) {
        await _initializeIncomingCall();
        return;
      }

      final granted = await _requestPermissions();
      if (!granted) {
        errorMessage.value = AppTranslations.callPermissionDenied.tr;
        return;
      }

      final startResult = await _chatService.startCall(
        toUserId: recipientUserId,
        isVideoCall: isVideoCall,
      );
      final startedCall = _handleStartResult(startResult);
      if (startedCall == null) {
        return;
      }

      if (isVideoCall) {
        final previewAppId =
            startedCall.connection?.appId.trim().isNotEmpty == true
            ? startedCall.connection!.appId.trim()
            : _callService.appId;
        if (previewAppId.isNotEmpty) {
          await _prepareLocalVideoPreview(appId: previewAppId);
        }
      }

      _activeCallId = startedCall.callId;
      _startHeartbeat();
      await _startOutgoingRingback();

      final connectedCall = await _waitForAnsweredCall(startedCall);
      if (connectedCall == null) {
        return;
      }

      await _stopIncomingRingtone();
      await _joinAgoraCall(connectedCall);
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> toggleMute() async {
    final engine = _engine;
    if (engine == null) return;
    final nextValue = !isMuted.value;
    await engine.muteLocalAudioStream(nextValue);
    isMuted.value = nextValue;
  }

  Future<void> toggleSpeaker() async {
    final engine = _engine;
    if (engine == null) return;
    final nextValue = !isSpeakerOn.value;
    if (hasLocalUserJoined.value) {
      await engine.setEnableSpeakerphone(nextValue);
    } else {
      await engine.setDefaultAudioRouteToSpeakerphone(nextValue);
    }
    await _syncNativeAudioRoute(speakerOn: nextValue);
    isSpeakerOn.value = nextValue;
  }

  Future<void> toggleCamera() async {
    final engine = _engine;
    if (engine == null || !isVideoCall) return;
    final nextValue = !isCameraOff.value;
    await engine.muteLocalVideoStream(nextValue);
    isCameraOff.value = nextValue;
  }

  Future<void> switchCamera() async {
    final engine = _engine;
    if (engine == null || !isVideoCall) return;
    await engine.switchCamera();
  }

  Future<void> endCall() async {
    if (_isEndingCall) {
      return;
    }
    _isEndingCall = true;
    _heartbeatTimer?.cancel();
    _incomingDecisionTimer?.cancel();
    _stopCallDurationTimer();
    if (isIncoming && isAwaitingIncomingDecision.value) {
      await declineIncomingCall(shouldClosePage: false);
    } else if (_callWasAnswered) {
      await _stopAllCallAudio();
      await _notifyCallEnded();
    } else if (!isIncoming) {
      await _stopAllCallAudio();
      await _cancelOutgoingCall();
    } else {
      await _stopAllCallAudio();
      await _notifyCallEnded();
    }
    await _disposeEngine();
    await _disableWakelock();
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
    }
  }

  Future<void> acceptIncomingCall() async {
    if (_isHandlingIncomingDecision || !isAwaitingIncomingDecision.value) {
      return;
    }

    final callId = _activeCallId;
    if (callId == null || callId == 0) {
      errorMessage.value = AppTranslations.callMissingConnection.tr;
      return;
    }

    _isHandlingIncomingDecision = true;
    isAwaitingIncomingDecision.value = false;
    isInitializing.value = true;
    try {
      _incomingDecisionTimer?.cancel();
      await _silenceIncomingCallRinging(callId);

      final granted = await _requestPermissions();
      if (!granted) {
        try {
          await _chatService.declineCall(callId: callId);
        } catch (_) {}
        errorMessage.value = AppTranslations.callPermissionDenied.tr;
        return;
      }

      statusText.value = AppTranslations.callConnecting.tr;
      final response = await _chatService.answerCall(callId: callId);
      final normalizedStatus = response.status.trim().toLowerCase();
      final answeredStatuses = <String>{
        'answered',
        'accepted',
        'connected',
        'success',
        'ok',
      };
      if (response.call == null) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : response.status;
        isAwaitingIncomingDecision.value = true;
        return;
      }
      if (normalizedStatus.isNotEmpty &&
          !answeredStatuses.contains(normalizedStatus)) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : response.status;
        isAwaitingIncomingDecision.value = true;
        return;
      }
      _callWasAnswered = true;
      await _joinAgoraCall(response.call!);
    } catch (error) {
      errorMessage.value = error.toString();
      isAwaitingIncomingDecision.value = true;
    } finally {
      isInitializing.value = false;
      _isHandlingIncomingDecision = false;
    }
  }

  Future<void> declineIncomingCall({bool shouldClosePage = true}) async {
    final callId = _activeCallId;
    if (_isHandlingIncomingDecision && shouldClosePage) {
      return;
    }

    _isHandlingIncomingDecision = true;
    isAwaitingIncomingDecision.value = false;
    _incomingDecisionTimer?.cancel();
    try {
      if (callId != null && callId != 0) {
        await _silenceIncomingCallRinging(callId);
        try {
          await _chatService.declineCall(callId: callId);
        } catch (_) {}
      } else {
        await _stopAllCallAudio();
      }
      if (shouldClosePage && Get.isOverlaysOpen == true) {
        Get.back();
      } else if (shouldClosePage && Get.key.currentState?.canPop() == true) {
        Get.back();
      }
    } finally {
      _isHandlingIncomingDecision = false;
    }
  }

  Future<void> _notifyCallEnded() async {
    final callId = _activeCallId;
    if (callId == null || callId == 0) {
      return;
    }

    try {
      await _chatService.endCall(callId: callId);
    } catch (_) {}
  }

  Future<void> _cancelOutgoingCall() async {
    final callId = _activeCallId;
    if (callId == null || callId == 0) {
      return;
    }

    try {
      await _chatService.cancelCall(callId: callId);
    } catch (_) {}
  }

  Future<void> _endCallFromRemote() async {
    if (_isEndingCall) {
      return;
    }
    _isEndingCall = true;
    _heartbeatTimer?.cancel();
    _incomingDecisionTimer?.cancel();
    _stopCallDurationTimer();
    await _stopAllCallAudio();
    await _disposeEngine();
    await _disableWakelock();
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
    }
  }

  Future<bool> _requestPermissions() async {
    final permissions = <Permission>[
      Permission.microphone,
      if (isVideoCall) Permission.camera,
    ];
    final statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> _initializeIncomingCall() async {
    final incomingCall = initialCall;
    if (incomingCall == null || incomingCall.callId == 0) {
      errorMessage.value = AppTranslations.callMissingConnection.tr;
      return;
    }

    _activeCallId = incomingCall.callId;
    _connectedCall = incomingCall;
    isAwaitingIncomingDecision.value = true;
    statusText.value = AppTranslations.callIncoming.tr;
    _startHeartbeat();
    _startIncomingDecisionTimeout();
    if (autoAccept) {
      await _silenceIncomingCallRinging(incomingCall.callId);
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!isClosed) {
          unawaited(acceptIncomingCall());
        }
      });
    } else {
      await _startIncomingRingtone();
    }
  }

  Future<void> _disposeEngine() async {
    final engine = _engine;
    _engine = null;
    _isEngineInitialized = false;
    _isEventHandlerRegistered = false;
    isLocalPreviewReady.value = false;
    await _deactivateNativeAudioRoute();
    if (engine == null) return;
    try {
      await engine.leaveChannel();
    } catch (_) {}
    try {
      if (isVideoCall) {
        await engine.stopPreview();
      }
    } catch (_) {}
    try {
      await engine.release();
    } catch (_) {}
  }

  ChatCallModel? _handleStartResult(ChatCallStartResult result) {
    switch (result.status) {
      case 'calling':
        statusText.value = AppTranslations.callRinging.tr;
        return result.call;
      case 'recipient_offline':
        errorMessage.value = AppTranslations.callRecipientOffline.tr;
        return null;
      case 'recipient_busy':
        errorMessage.value = AppTranslations.callRecipientBusy.tr;
        return null;
      case 'caller_busy':
        errorMessage.value = AppTranslations.callCallerBusy.tr;
        return null;
      default:
        errorMessage.value = result.message.isNotEmpty
            ? result.message
            : result.status;
        return null;
    }
  }

  Future<ChatCallModel?> _waitForAnsweredCall(ChatCallModel startedCall) async {
    if (startedCall.connection?.hasAgoraCredentials == true) {
      await _stopAllCallAudio();
      return startedCall;
    }

    final callId = startedCall.callId;
    if (callId == 0) {
      errorMessage.value = AppTranslations.callMissingConnection.tr;
      return null;
    }

    for (var attempt = 0; attempt < 20; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 2));

      final response = await _chatService.checkCallResponse(callId: callId);
      final normalizedStatus = response.status.trim().toLowerCase();
      switch (normalizedStatus) {
        case 'answered':
        case 'accepted':
        case 'connected':
          await _stopAllCallAudio();
          _callWasAnswered = true;
          return response.call;
        case 'declined':
        case 'call_declined':
          await _stopAllCallAudio();
          errorMessage.value = AppTranslations.callDeclined.tr;
          return null;
        case 'calling':
        case 'ringing':
        case 'pending':
        case 'waiting':
          statusText.value = AppTranslations.callRinging.tr;
          continue;
        case 'no_answer':
        case 'missed':
        case 'timeout':
          await _stopAllCallAudio();
          errorMessage.value = AppTranslations.callNoAnswer.tr;
          return null;
        case 'cancelled':
        case 'call_cancelled':
          await _stopAllCallAudio();
          errorMessage.value = AppTranslations.callNoAnswer.tr;
          return null;
        default:
          await _stopAllCallAudio();
          errorMessage.value = response.message.isNotEmpty
              ? response.message
              : response.status;
          return null;
      }
    }

    await _stopAllCallAudio();
    errorMessage.value = AppTranslations.callNoAnswer.tr;
    return null;
  }

  Future<void> _joinAgoraCall(ChatCallModel call) async {
    await _stopAllCallAudio();

    final connection = call.connection;
    final appId = connection?.appId.trim().isNotEmpty == true
        ? connection!.appId.trim()
        : _callService.appId;
    final token = connection?.token.trim().isNotEmpty == true
        ? connection!.token.trim()
        : _callService.token;
    final room = connection?.room.trim().isNotEmpty == true
        ? connection!.room.trim()
        : call.room.trim();

    if (appId.isEmpty) {
      errorMessage.value = AppTranslations.callAgoraMissingAppId.tr;
      return;
    }
    if (room.isEmpty) {
      errorMessage.value = AppTranslations.callMissingConnection.tr;
      return;
    }
    final uid = connection?.userId ?? 0;
    if (uid == 0) {
      errorMessage.value = AppTranslations.callMissingConnection.tr;
      return;
    }

    _connectedCall = call;
    _callWasAnswered = true;
    _logAgora(
      'join params appId=$appId room=$room uid=$uid tokenPresent=${token.trim().isNotEmpty} isVideoCall=$isVideoCall',
    );

    final engine = await _ensureEngine(appId: appId);

    try {
      await engine.enableAudio();
      _logAgora('enableAudio success');
    } catch (error, stackTrace) {
      _logAgora('enableAudio failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
    await _activateNativeAudioRoute();
    try {
      await engine.setDefaultAudioRouteToSpeakerphone(isSpeakerOn.value);
      _logAgora(
        'setDefaultAudioRouteToSpeakerphone success value=${isSpeakerOn.value}',
      );
    } catch (error, stackTrace) {
      _logAgora('setDefaultAudioRouteToSpeakerphone failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
    if (isVideoCall && !isLocalPreviewReady.value) {
      try {
        await engine.enableVideo();
        _logAgora('enableVideo success');
      } catch (error, stackTrace) {
        _logAgora('enableVideo failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }
      try {
        await engine.startPreview();
        isLocalPreviewReady.value = true;
        _logAgora('startPreview success');
      } catch (error, stackTrace) {
        _logAgora('startPreview failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }
    } else if (!isVideoCall) {
      try {
        await engine.disableVideo();
        _logAgora('disableVideo success');
      } catch (error, stackTrace) {
        _logAgora('disableVideo failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }
    }

    try {
      _logAgora('joinChannel start');
      await engine.joinChannel(
        token: token,
        channelId: room,
        uid: uid,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: isVideoCall,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
      _logAgora('joinChannel success');
    } catch (error, stackTrace) {
      _logAgora('joinChannel failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _prepareLocalVideoPreview({required String appId}) async {
    final engine = await _ensureEngine(appId: appId);
    try {
      await engine.enableVideo();
      _logAgora('preview enableVideo success');
    } catch (error, stackTrace) {
      _logAgora('preview enableVideo failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
    try {
      await engine.startPreview();
      isLocalPreviewReady.value = true;
      _logAgora('preview startPreview success');
    } catch (error, stackTrace) {
      _logAgora('preview startPreview failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<RtcEngine> _ensureEngine({required String appId}) async {
    final existingEngine = _engine;
    if (existingEngine != null && _isEngineInitialized) {
      return existingEngine;
    }

    final engine = existingEngine ?? createAgoraRtcEngine();
    _engine = engine;
    if (!_isEngineInitialized) {
      _logAgora('engine created');
      try {
        await engine.initialize(
          RtcEngineContext(
            appId: appId,
            channelProfile: ChannelProfileType.channelProfileCommunication,
          ),
        );
        _isEngineInitialized = true;
        _logAgora('initialize success');
      } catch (error, stackTrace) {
        _logAgora('initialize failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }
    }

    if (!_isEventHandlerRegistered) {
      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _logAgora(
              'onJoinChannelSuccess channelId=${connection.channelId} localUid=${connection.localUid} elapsed=$elapsed',
            );
            unawaited(_stopAllCallAudio());
            hasLocalUserJoined.value = true;
            statusText.value = AppTranslations.callWaiting.tr;
            unawaited(_applySpeakerphoneRoute());
          },
          onFirstLocalVideoFrame:
              (VideoSourceType source, int width, int height, int elapsed) {
                _logAgora(
                  'onFirstLocalVideoFrame source=$source width=$width height=$height elapsed=$elapsed',
                );
              },
          onFirstLocalVideoFramePublished: (RtcConnection connection, int elapsed) {
            _logAgora(
              'onFirstLocalVideoFramePublished channelId=${connection.channelId} localUid=${connection.localUid} elapsed=$elapsed',
            );
          },
          onLocalVideoStateChanged:
              (
                VideoSourceType source,
                LocalVideoStreamState state,
                LocalVideoStreamReason reason,
              ) {
                _logAgora(
                  'onLocalVideoStateChanged source=$source state=$state reason=$reason',
                );
              },
          onUserJoined:
              (RtcConnection connection, int remoteUidValue, int elapsed) {
                _logAgora(
                  'onUserJoined remoteUid=$remoteUidValue channelId=${connection.channelId} elapsed=$elapsed',
                );
                unawaited(_stopAllCallAudio());
                remoteUid.value = remoteUidValue;
                isConnected.value = true;
                _callWasAnswered = true;
                statusText.value = AppTranslations.callRemoteJoined.tr;
                _startCallDurationTimer();
              },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUidValue,
                UserOfflineReasonType reason,
              ) {
                _logAgora(
                  'onUserOffline remoteUid=$remoteUidValue reason=$reason channelId=${connection.channelId}',
                );
                remoteUid.value = null;
                isConnected.value = false;
                _stopCallDurationTimer();
                statusText.value = AppTranslations.callDeclined.tr;
                unawaited(_endCallFromRemote());
              },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            _logAgora(
              'onLeaveChannel channelId=${connection.channelId} localUid=${connection.localUid}',
            );
            hasLocalUserJoined.value = false;
            isConnected.value = false;
            remoteUid.value = null;
            _stopCallDurationTimer();
          },
          onConnectionStateChanged:
              (
                RtcConnection connection,
                ConnectionStateType state,
                ConnectionChangedReasonType reason,
              ) {
                _logAgora(
                  'onConnectionStateChanged state=$state reason=$reason channelId=${connection.channelId}',
                );
              },
          onRemoteVideoStateChanged:
              (
                RtcConnection connection,
                int remoteUidValue,
                RemoteVideoState state,
                RemoteVideoStateReason reason,
                int elapsed,
              ) {
                _logAgora(
                  'onRemoteVideoStateChanged remoteUid=$remoteUidValue state=$state '
                  'reason=$reason elapsed=$elapsed channelId=${connection.channelId}',
                );
              },
          onUserEnableVideo:
              (RtcConnection connection, int remoteUidValue, bool enabled) {
                _logAgora(
                  'onUserEnableVideo remoteUid=$remoteUidValue enabled=$enabled '
                  'channelId=${connection.channelId}',
                );
              },
          onError: (ErrorCodeType err, String msg) {
            _logAgora('onError err=$err msg=$msg');
            errorMessage.value = msg.trim().isEmpty ? err.name : msg;
          },
        ),
      );
      _isEventHandlerRegistered = true;
      _logAgora('event handler registered');
    }

    return engine;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    final callId = _activeCallId;
    if (!agoraHeartbeatEnabled || callId == null || callId == 0) {
      return;
    }
    _heartbeatTimer = Timer.periodic(agoraHeartbeatInterval, (_) async {
      try {
        await _chatService.updateCall(callId: callId);
      } catch (_) {}
    });
  }

  void _startIncomingDecisionTimeout() {
    _incomingDecisionTimer?.cancel();
    _incomingDecisionTimer = Timer(incomingCallDecisionTimeout, () {
      if (!isAwaitingIncomingDecision.value || _isEndingCall) {
        return;
      }
      unawaited(declineIncomingCall());
    });
  }

  void _startCallDurationTimer() {
    if (_callDurationTimer != null) {
      return;
    }
    callDurationText.value = '00:00';
    final startedAt = DateTime.now();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(startedAt);
      final minutes = elapsed.inMinutes
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final seconds = elapsed.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final hours = elapsed.inHours;
      if (hours > 0) {
        callDurationText.value =
            '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
      } else {
        callDurationText.value = '$minutes:$seconds';
      }
    });
  }

  void _stopCallDurationTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = null;
    callDurationText.value = '00:00';
  }

  void _logAgora(String message) {
    unawaited(CallTraceLogger.log('CALL AGORA', message));
  }

  Future<void> _applySpeakerphoneRoute() async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.setEnableSpeakerphone(isSpeakerOn.value);
      await _syncNativeAudioRoute(speakerOn: isSpeakerOn.value);
      _logAgora(
        'post-join setEnableSpeakerphone success value=${isSpeakerOn.value}',
      );
    } catch (error, stackTrace) {
      _logAgora('post-join setEnableSpeakerphone failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _activateNativeAudioRoute() async {
    try {
      await _callAudioChannel.invokeMethod<void>('activateCallAudio', {
        'speakerOn': isSpeakerOn.value,
      });
      _logAgora('native activateCallAudio success value=${isSpeakerOn.value}');
    } catch (error, stackTrace) {
      _logAgora('native activateCallAudio failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _syncNativeAudioRoute({required bool speakerOn}) async {
    try {
      await _callAudioChannel.invokeMethod<void>('setSpeakerphone', {
        'speakerOn': speakerOn,
      });
      _logAgora('native setSpeakerphone success value=$speakerOn');
    } catch (error, stackTrace) {
      _logAgora('native setSpeakerphone failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _deactivateNativeAudioRoute() async {
    try {
      await _callAudioChannel.invokeMethod<void>('deactivateCallAudio');
      _logAgora('native deactivateCallAudio success');
    } catch (error, stackTrace) {
      _logAgora('native deactivateCallAudio failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _enableWakelock() async {
    try {
      await Wakelock.enable();
    } catch (_) {}
  }

  Future<void> _disableWakelock() async {
    try {
      await Wakelock.disable();
    } catch (_) {}
  }

  Future<void> _startIncomingRingtone() async {
    final generation = ++_incomingRingtoneGeneration;
    try {
      await _stopOutgoingRingback();
      final player =
          _incomingRingtonePlayer ?? AudioPlayer(handleInterruptions: false);
      _incomingRingtonePlayer = player;
      await player.setAndroidAudioAttributes(_incomingRingtoneAttributes);
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(1);
      await player.setAsset('assets/audio/incoming_call_ringtone.mp3');
      if (generation != _incomingRingtoneGeneration ||
          !isAwaitingIncomingDecision.value ||
          isClosed) {
        await _stopIncomingRingtone();
        return;
      }
      unawaited(player.play());
    } catch (_) {}
  }

  Future<void> _startOutgoingRingback() async {
    final generation = ++_outgoingRingbackGeneration;
    try {
      await _stopIncomingRingtone();
      final player =
          _outgoingRingbackPlayer ?? AudioPlayer(handleInterruptions: false);
      _outgoingRingbackPlayer = player;
      await player.setAndroidAudioAttributes(_outgoingRingbackAttributes);
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(1);
      await player.setAsset('assets/audio/outgoing_call_ringback.wav');
      if (generation != _outgoingRingbackGeneration || isClosed) {
        await _stopOutgoingRingback();
        return;
      }
      unawaited(player.play());
    } catch (_) {}
  }

  Future<void> _stopIncomingRingtone() async {
    _incomingRingtoneGeneration++;
    final player = _incomingRingtonePlayer;
    _incomingRingtonePlayer = null;
    if (player == null) {
      return;
    }
    try {
      await player.setVolume(0);
    } catch (_) {}
    try {
      await player.pause();
    } catch (_) {}
    try {
      await player.seek(Duration.zero);
    } catch (_) {}
    try {
      await player.stop();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
  }

  Future<void> _stopOutgoingRingback() async {
    _outgoingRingbackGeneration++;
    final player = _outgoingRingbackPlayer;
    _outgoingRingbackPlayer = null;
    if (player == null) {
      return;
    }
    try {
      await player.setVolume(0);
    } catch (_) {}
    try {
      await player.pause();
    } catch (_) {}
    try {
      await player.seek(Duration.zero);
    } catch (_) {}
    try {
      await player.stop();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
  }

  Future<void> _stopAllCallAudio() async {
    await _stopIncomingRingtone();
    await _stopOutgoingRingback();
  }

  Future<void> _silenceIncomingCallRinging(int callId) async {
    await _stopAllCallAudio();
    await CallNotificationService.silenceIncomingCallRinging(callId);
  }

  Future<bool> handleRemoteLifecycleEvent({
    required int callId,
    required String event,
    String? reason,
    String? displayStatus,
  }) async {
    if (_activeCallId != callId || callId == 0) {
      return false;
    }

    final normalizedEvent = event.trim().toLowerCase();
    switch (normalizedEvent) {
      case 'call_accepted':
      case 'call_answered':
      case 'answered':
      case 'accepted':
      case 'connected':
        await _stopAllCallAudio();
        _callWasAnswered = true;
        isAwaitingIncomingDecision.value = false;
        statusText.value = AppTranslations.callConnecting.tr;
        return true;
      case 'call_cancelled':
      case 'cancelled':
        await _stopAllCallAudio();
        isAwaitingIncomingDecision.value = false;
        errorMessage.value = AppTranslations.callNoAnswer.tr;
        await _endCallFromRemote();
        return true;
      case 'call_declined':
      case 'call_rejected':
      case 'declined':
      case 'rejected':
        await _stopAllCallAudio();
        isAwaitingIncomingDecision.value = false;
        errorMessage.value = AppTranslations.callDeclined.tr;
        await _endCallFromRemote();
        return true;
      case 'call_ended':
      case 'ended':
        await _stopAllCallAudio();
        isAwaitingIncomingDecision.value = false;
        await _endCallFromRemote();
        return true;
      case 'call_missed':
      case 'missed':
        await _stopAllCallAudio();
        isAwaitingIncomingDecision.value = false;
        errorMessage.value = AppTranslations.callNoAnswer.tr;
        await _endCallFromRemote();
        return true;
      default:
        return false;
    }
  }
}
