import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide navigator;
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
import '../../data/services/direct_webrtc_session.dart';

class WebRtcCallController extends GetxController {
  static const MethodChannel _callAudioChannel = MethodChannel(
    'messenger/call_audio',
  );
  static const _qualityStatsInterval = Duration(seconds: 5);
  static const _disconnectedRecoveryDelay = Duration(seconds: 5);
  static const _iceRestartRetryDelay = Duration(seconds: 8);
  static const _iceRestartCooldown = Duration(seconds: 12);
  static const _maxIceRestartAttempts = 2;
  static const _audioMaxBitrateBps = 64000;
  static const _videoMaxBitrateBps = 1200000;
  static const _videoMaxFramerate = 24;

  WebRtcCallController({
    required ChatService chatService,
    required this.conversationId,
    required this.recipientUserId,
    required this.conversationTitle,
    required this.avatarUrl,
    required this.callType,
    this.isIncoming = false,
    this.initialCall,
    this.autoAccept = false,
  }) : _chatService = chatService {
    isSpeakerOn.value = callType == AgoraCallType.video;
  }

  static WebRtcCallController? activeInstance;

  final ChatService _chatService;
  final int conversationId;
  final int recipientUserId;
  final String conversationTitle;
  final String avatarUrl;
  final AgoraCallType callType;
  final bool isIncoming;
  final ChatCallModel? initialCall;
  final bool autoAccept;

  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();
  final isInitializing = true.obs;
  final isConnected = false.obs;
  final isMuted = false.obs;
  final isSpeakerOn = false.obs;
  final isLocalPreviewReady = false.obs;
  final hasRemoteStream = false.obs;
  final errorMessage = ''.obs;
  final statusText = ''.obs;
  final callDurationText = '00:00'.obs;
  final isAwaitingIncomingDecision = false.obs;
  final callParticipants = <ChatCallParticipantModel>[].obs;
  final remoteParticipants = <WebRtcRemoteParticipant>[].obs;
  final videoTileOrder = <String>[].obs;
  final enlargedVideoTileId = ''.obs;
  final activeParticipantCount = 0.obs;
  final pendingInviteCount = 0.obs;
  final isInvitingMember = false.obs;

  static const localVideoTileId = 'local';
  static const legacyRemoteVideoTileId = 'remote:legacy';

  bool get isVideoCall => callType == AgoraCallType.video;

  bool get _shouldAbortAsyncWork =>
      _controllerClosing || _isEndingCall || isClosed;

  AudioPlayer? _incomingRingtonePlayer;
  AudioPlayer? _outgoingRingbackPlayer;
  RTCPeerConnection? _publishPeer;
  RTCPeerConnection? _playbackPeer;
  WebSocket? _publishSocket;
  WebSocket? _playbackSocket;
  MediaStream? _localStream;
  DirectWebRtcSession? _directSession;
  Future<MediaStream>? _directRemoteStreamFuture;
  Future<void>? _sfuFallbackFuture;
  Timer? _heartbeatTimer;
  Timer? _participantsTimer;
  Timer? _incomingDecisionTimer;
  Timer? _callDurationTimer;
  Timer? _qualityStatsTimer;
  ChatCallConnectionModel? _activeConnection;
  int? _activeCallId;
  DateTime? _connectedAt;
  bool _renderersInitialized = false;
  bool _isEndingCall = false;
  Future<void>? _disposeWebRtcFuture;
  bool _callWasAnswered = false;
  bool _isHandlingIncomingDecision = false;
  bool _audioSessionConfigured = false;
  bool _qualityStatsRunning = false;
  bool _usingDirectP2p = false;
  bool _usingSfu = false;
  bool _callForegroundServiceStarted = false;
  bool _controllerClosing = false;
  int _ignoredIceCandidateErrors = 0;
  int _skippedIceCandidates = 0;
  Future<MediaStream>? _playbackSyntheticStreamFuture;
  final Map<RTCPeerConnection, _PeerDiagnostics> _peerDiagnostics =
      <RTCPeerConnection, _PeerDiagnostics>{};
  final Map<String, _QualityCounters> _lastQualityCounters =
      <String, _QualityCounters>{};
  final Map<int, _RemoteWebRtcPlayback> _remotePlaybacks =
      <int, _RemoteWebRtcPlayback>{};
  final Set<int> _remotePlaybackConnectionsInFlight = <int>{};
  final Set<WebSocket> _connectingOfferSockets = <WebSocket>{};

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
    _controllerClosing = true;
    if (identical(activeInstance, this)) {
      activeInstance = null;
    }
    _heartbeatTimer?.cancel();
    _participantsTimer?.cancel();
    _incomingDecisionTimer?.cancel();
    _qualityStatsTimer?.cancel();
    _stopCallDurationTimer();
    unawaited(_stopAllCallAudio());
    unawaited(_disposeWebRtc());
    unawaited(_disableWakelock());
    super.onClose();
  }

  Future<void> initialize() async {
    _logWebRtc(
      'initialize incoming=$isIncoming autoAccept=$autoAccept '
      'type=${isVideoCall ? 'video' : 'audio'} provider=$callProvider',
    );
    if (!callsEnabled || !isWebRtcCallProvider) {
      errorMessage.value = AppTranslations.callWebRtcDisabled.tr;
      _logWebRtc(
        'initialize blocked callsEnabled=$callsEnabled provider=$callProvider',
      );
      isInitializing.value = false;
      return;
    }

    try {
      await _initializeRenderers();
      if (_shouldAbortAsyncWork) return;
      if (isIncoming) {
        await _initializeIncomingCall();
        return;
      }

      final granted = await _requestPermissions();
      if (_shouldAbortAsyncWork) return;
      if (!granted) {
        errorMessage.value = AppTranslations.callPermissionDenied.tr;
        return;
      }

      final startResult = await _chatService.startCall(
        toUserId: recipientUserId,
        isVideoCall: isVideoCall,
      );
      if (_shouldAbortAsyncWork) {
        final abandonedCallId = startResult.call?.callId ?? 0;
        if (abandonedCallId > 0) {
          unawaited(_cancelCallById(abandonedCallId));
        }
        return;
      }
      _logWebRtc('startCall response status=${startResult.status}');
      final startedCall = _handleStartResult(startResult);
      if (startedCall == null) {
        _logWebRtc('startCall did not return an active call');
        return;
      }

      _activeCallId = startedCall.callId;
      _logWebRtc('outgoing call started callId=${startedCall.callId}');
      _startHeartbeat();
      await _startOutgoingRingback();

      final connectedCall = await _waitForAnsweredCall(startedCall);
      if (_shouldAbortAsyncWork) return;
      if (connectedCall == null) {
        _logWebRtc(
          'outgoing call was not answered callId=${startedCall.callId}',
        );
        return;
      }

      await _stopAllCallAudio();
      if (_shouldAbortAsyncWork) return;
      await _startWebRtcSession(connectedCall);
    } catch (error) {
      if (!_shouldAbortAsyncWork) {
        errorMessage.value = error.toString();
      }
      _logWebRtc('initialize failed: $error');
    } finally {
      if (_controllerClosing) {
        try {
          await _disposeWebRtcFuture;
        } catch (_) {}
        await _disposeWebRtc();
      } else {
        isInitializing.value = false;
      }
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
      if (_shouldAbortAsyncWork) return;
      if (!granted) {
        try {
          await _chatService.declineCall(callId: callId);
        } catch (_) {}
        errorMessage.value = AppTranslations.callPermissionDenied.tr;
        return;
      }

      final response = await _chatService.answerCall(callId: callId);
      if (_shouldAbortAsyncWork) {
        unawaited(_endCallById(callId));
        return;
      }
      _logWebRtc(
        'answerCall response callId=$callId status=${response.status}',
      );
      final normalizedStatus = response.status.trim().toLowerCase();
      if (response.call == null ||
          (normalizedStatus.isNotEmpty &&
              !<String>{
                'answered',
                'accepted',
                'connected',
                'success',
                'ok',
              }.contains(normalizedStatus))) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : response.status;
        isAwaitingIncomingDecision.value = true;
        return;
      }

      _callWasAnswered = true;
      await _startWebRtcSession(response.call!);
    } catch (error) {
      if (!_shouldAbortAsyncWork) {
        errorMessage.value = error.toString();
      }
      _logWebRtc('acceptIncomingCall failed callId=$callId error=$error');
      if (!_controllerClosing) {
        isAwaitingIncomingDecision.value = true;
      }
    } finally {
      if (_controllerClosing) {
        try {
          await _disposeWebRtcFuture;
        } catch (_) {}
        await _disposeWebRtc();
      } else {
        isInitializing.value = false;
      }
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
      if (shouldClosePage && Get.key.currentState?.canPop() == true) {
        Get.back();
      }
    } finally {
      _isHandlingIncomingDecision = false;
    }
  }

  Future<void> toggleMute() async {
    final stream = _localStream;
    if (stream == null) return;
    final nextValue = !isMuted.value;
    for (final track in stream.getAudioTracks()) {
      track.enabled = !nextValue;
    }
    isMuted.value = nextValue;
  }

  Future<void> toggleSpeaker() async {
    final nextValue = !isSpeakerOn.value;
    await _applyCallAudioRoute(speakerOn: nextValue);
    isSpeakerOn.value = nextValue;
  }

  Future<void> toggleCamera() async {
    final stream = _localStream;
    if (stream == null || !isVideoCall) return;
    final nextEnabled = !isLocalPreviewReady.value;
    for (final track in stream.getVideoTracks()) {
      track.enabled = nextEnabled;
    }
    isLocalPreviewReady.value = nextEnabled;
    _syncVideoTileOrder();
  }

  Future<void> switchCamera() async {
    final stream = _localStream;
    if (stream == null || !isVideoCall) return;
    final tracks = stream.getVideoTracks();
    if (tracks.isEmpty) return;
    await Helper.switchCamera(tracks.first);
  }

  List<WebRtcVideoTile> orderedVideoTiles() {
    final availableIds = _availableVideoTileIds();
    final orderedIds = videoTileOrder.isEmpty
        ? availableIds
        : <String>[
            ...videoTileOrder.where(availableIds.contains),
            ...availableIds.where((id) => !videoTileOrder.contains(id)),
          ];
    final remoteById = <String, WebRtcRemoteParticipant>{
      for (final participant in remoteParticipants)
        _remoteVideoTileId(participant.userId): participant,
    };

    return orderedIds
        .map((id) {
          if (id == localVideoTileId) {
            return const WebRtcVideoTile.local();
          }
          if (id == legacyRemoteVideoTileId) {
            return const WebRtcVideoTile.legacyRemote();
          }
          return WebRtcVideoTile.remote(remoteById[id]!);
        })
        .toList(growable: false);
  }

  void toggleVideoTileFocus(String tileId) {
    if (!isVideoCall || tileId.trim().isEmpty) {
      return;
    }
    _syncVideoTileOrder();
    if (!videoTileOrder.contains(tileId)) {
      return;
    }
    enlargedVideoTileId.value = enlargedVideoTileId.value == tileId
        ? ''
        : tileId;
  }

  void clearVideoTileFocus() {
    enlargedVideoTileId.value = '';
  }

  void moveVideoTileBefore({
    required String draggedId,
    required String targetId,
  }) {
    if (draggedId == targetId ||
        draggedId.trim().isEmpty ||
        targetId.trim().isEmpty) {
      return;
    }
    _syncVideoTileOrder();
    final order = videoTileOrder.toList(growable: true);
    final fromIndex = order.indexOf(draggedId);
    final targetIndex = order.indexOf(targetId);
    if (fromIndex < 0 || targetIndex < 0) {
      return;
    }

    order.removeAt(fromIndex);
    final insertIndex = targetIndex > fromIndex ? targetIndex - 1 : targetIndex;
    order.insert(insertIndex.clamp(0, order.length).toInt(), draggedId);
    videoTileOrder.assignAll(order);
  }

  void _syncVideoTileOrder() {
    if (!isVideoCall) {
      if (videoTileOrder.isNotEmpty) {
        videoTileOrder.clear();
      }
      if (enlargedVideoTileId.value.isNotEmpty) {
        enlargedVideoTileId.value = '';
      }
      return;
    }

    final availableIds = _availableVideoTileIds();
    final nextOrder = <String>[
      ...videoTileOrder.where(availableIds.contains),
      ...availableIds.where((id) => !videoTileOrder.contains(id)),
    ];
    if (!_sameStringOrder(videoTileOrder, nextOrder)) {
      videoTileOrder.assignAll(nextOrder);
    }
    if (enlargedVideoTileId.value.isNotEmpty &&
        !nextOrder.contains(enlargedVideoTileId.value)) {
      enlargedVideoTileId.value = '';
    }
  }

  List<String> _availableVideoTileIds() {
    if (!isVideoCall) {
      return const <String>[];
    }

    final ids = <String>[localVideoTileId];
    if (remoteParticipants.isNotEmpty) {
      ids.addAll(
        remoteParticipants.map(
          (participant) => _remoteVideoTileId(participant.userId),
        ),
      );
    } else if (hasRemoteStream.value) {
      ids.add(legacyRemoteVideoTileId);
    }
    return ids;
  }

  bool _sameStringOrder(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) {
        return false;
      }
    }
    return true;
  }

  static String _remoteVideoTileId(int userId) => 'remote:$userId';

  Future<String> inviteMember(int userId) async {
    final callId = _activeCallId;
    if (callId == null || callId == 0 || userId <= 0) {
      return AppTranslations.callMissingConnection.tr;
    }
    if (callParticipants.any((participant) {
      final status = participant.status.trim().toLowerCase();
      return participant.userId == userId &&
          participant.isActive &&
          status != 'left' &&
          status != 'ended';
    })) {
      return 'User is already in this call';
    }

    isInvitingMember.value = true;
    try {
      final response = await _chatService.inviteWebRtcCallParticipant(
        callId: callId,
        userId: userId,
      );
      await _refreshParticipants(reason: 'invite_member');
      final message = response.message.trim();
      if (message.isNotEmpty) {
        return message;
      }
      switch (response.status.trim().toLowerCase()) {
        case 'recipient_offline':
          return 'Recipient is offline';
        case 'recipient_busy':
          return 'Recipient is busy';
        case 'invite_pending':
          return 'Invite is already pending';
        case 'already_joined':
          return 'User is already in this call';
        case 'invited':
          return 'Invite sent';
        default:
          return response.status.isNotEmpty ? response.status : 'Invite sent';
      }
    } catch (error) {
      _logWebRtc('invite member failed userId=$userId error=$error');
      return error.toString();
    } finally {
      isInvitingMember.value = false;
    }
  }

  Future<void> endCall() async {
    if (_isEndingCall) {
      return;
    }
    _isEndingCall = true;
    _heartbeatTimer?.cancel();
    _participantsTimer?.cancel();
    _incomingDecisionTimer?.cancel();
    _stopQualityStats();
    _stopCallDurationTimer();
    if (isIncoming && isAwaitingIncomingDecision.value) {
      await declineIncomingCall(shouldClosePage: false);
    } else if (_shouldLeaveInsteadOfEnd()) {
      await _stopAllCallAudio();
      await _leaveCurrentWebRtcCall();
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
    await _disposeWebRtc();
    await _disableWakelock();
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
    }
  }

  bool _shouldLeaveInsteadOfEnd() {
    if (!_callWasAnswered) {
      return false;
    }
    return activeParticipantCount.value > 2 ||
        pendingInviteCount.value > 0 ||
        initialCall?.isGroupCallInvite == true ||
        (initialCall?.isGroupCall == true && activeParticipantCount.value > 1);
  }

  Future<void> _leaveCurrentWebRtcCall() async {
    final callId = _activeCallId;
    if (callId == null || callId == 0) {
      return;
    }
    try {
      await _chatService.leaveWebRtcCall(callId: callId);
    } catch (_) {}
  }

  Future<void> handleRemoteLifecycleEvent({
    required int callId,
    required String event,
    String reason = '',
  }) async {
    if (_activeCallId != callId || _isEndingCall) {
      return;
    }

    final normalized = event.trim().toLowerCase();
    if (<String>{
      'call_accepted',
      'call_answered',
      'answered',
      'accepted',
      'connected',
    }.contains(normalized)) {
      await _stopAllCallAudio();
      _callWasAnswered = true;
      statusText.value = AppTranslations.callConnecting.tr;
      unawaited(_refreshParticipants(reason: normalized));
      _logWebRtc('remote accepted callId=$callId reason=$reason');
      return;
    }

    if (<String>{
      'call_participant_joined',
      'call_participant_left',
      'call_participants_changed',
      'call_invite_declined',
      'call_invite_missed',
      'call_invite_cancelled',
    }.contains(normalized)) {
      unawaited(_refreshParticipants(reason: normalized));
      return;
    }

    if (<String>{
      'call_cancelled',
      'call_declined',
      'call_rejected',
      'call_ended',
      'call_missed',
      'cancelled',
      'declined',
      'rejected',
      'ended',
      'missed',
    }.contains(normalized)) {
      await _endCallFromRemote();
    }
  }

  Future<void> _initializeRenderers() async {
    if (_renderersInitialized) {
      return;
    }
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    if (_shouldAbortAsyncWork) {
      try {
        await localRenderer.dispose();
      } catch (_) {}
      try {
        await remoteRenderer.dispose();
      } catch (_) {}
      return;
    }
    _renderersInitialized = true;
  }

  Future<bool> _requestPermissions() async {
    final permissions = <Permission>[
      Permission.microphone,
      if (isVideoCall) Permission.camera,
    ];
    final statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> _configureCallAudioSession() async {
    if (_audioSessionConfigured) {
      return;
    }
    _audioSessionConfigured = Platform.isAndroid || Platform.isIOS;
    if (!_audioSessionConfigured) {
      return;
    }

    if (Platform.isAndroid) {
      try {
        await Helper.setAndroidAudioConfiguration(
          AndroidAudioConfiguration.communication,
        );
        _logWebRtc('Android communication audio session configured');
      } catch (error) {
        _logWebRtc('Android audio session configuration failed: $error');
      }
      return;
    }

    try {
      await Helper.setAppleAudioIOMode(
        AppleAudioIOMode.localAndRemote,
        preferSpeakerOutput: isVideoCall,
      );
      _logWebRtc(
        'iOS playAndRecord audio session configured '
        'mode=${isVideoCall ? 'videoChat' : 'voiceChat'}',
      );
    } catch (error) {
      _logWebRtc('iOS audio session configuration failed: $error');
    }
  }

  Future<void> _activateCallAudioSession() async {
    if (Platform.isIOS) {
      try {
        await Helper.ensureAudioSession();
        _logWebRtc('iOS audio session activated');
      } catch (error) {
        _logWebRtc('iOS audio session activation failed: $error');
      }
    }
    await _applyCallAudioRoute(speakerOn: isSpeakerOn.value);
  }

  Future<void> _applyCallAudioRoute({required bool speakerOn}) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    try {
      if (speakerOn) {
        await Helper.setSpeakerphoneOnButPreferBluetooth();
      } else {
        // Disabling the speaker preserves an active Bluetooth route and falls
        // back to the receiver/earpiece when no Bluetooth device is selected.
        await Helper.setSpeakerphoneOn(false);
      }
      _logWebRtc(
        'audio route applied speaker=$speakerOn bluetoothPreferred=true',
      );
    } catch (error) {
      _logWebRtc('audio route apply failed speaker=$speakerOn error=$error');
    }
  }

  Future<void> _cleanupCallAudioSession() async {
    if (!_audioSessionConfigured) {
      return;
    }
    _audioSessionConfigured = false;

    if (Platform.isAndroid) {
      try {
        await Helper.clearAndroidCommunicationDevice();
      } catch (error) {
        _logWebRtc('Android communication device cleanup failed: $error');
      }
      try {
        await Helper.setAndroidAudioConfiguration(
          AndroidAudioConfiguration.media,
        );
      } catch (error) {
        _logWebRtc('Android media audio session restore failed: $error');
      }
      return;
    }

    if (Platform.isIOS) {
      try {
        await Helper.setSpeakerphoneOn(false);
      } catch (_) {}
      try {
        await Helper.setAppleAudioIOMode(AppleAudioIOMode.none);
      } catch (error) {
        _logWebRtc('iOS audio session cleanup failed: $error');
      }
    }
  }

  Future<void> _startCallForegroundService() async {
    if (!Platform.isAndroid ||
        _callForegroundServiceStarted ||
        _shouldAbortAsyncWork) {
      return;
    }
    try {
      await _callAudioChannel.invokeMethod<void>('startCallService', {
        'isVideo': isVideoCall,
        'title': conversationTitle,
      });
      _callForegroundServiceStarted = true;
      if (_shouldAbortAsyncWork) {
        await _stopCallForegroundService();
        return;
      }
      _logWebRtc('Android call foreground service started');
    } catch (error) {
      _logWebRtc('Android call foreground service start failed: $error');
    }
  }

  Future<void> _stopCallForegroundService() async {
    if (!Platform.isAndroid || !_callForegroundServiceStarted) return;
    _callForegroundServiceStarted = false;
    try {
      await _callAudioChannel.invokeMethod<void>('stopCallService');
      _logWebRtc('Android call foreground service stopped');
    } catch (error) {
      _logWebRtc('Android call foreground service stop failed: $error');
    }
  }

  Future<void> _initializeIncomingCall() async {
    final incomingCall = initialCall;
    if (incomingCall == null || incomingCall.callId == 0) {
      errorMessage.value = AppTranslations.callMissingConnection.tr;
      return;
    }

    _activeCallId = incomingCall.callId;
    isAwaitingIncomingDecision.value = true;
    statusText.value = AppTranslations.callIncoming.tr;
    _startHeartbeat();
    _startIncomingDecisionTimeout();
    if (autoAccept) {
      await _silenceIncomingCallRinging(incomingCall.callId);
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!_shouldAbortAsyncWork) {
          unawaited(acceptIncomingCall());
        }
      });
    } else {
      await _startIncomingRingtone();
    }
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
    final callId = startedCall.callId;
    if (callId == 0) {
      errorMessage.value = AppTranslations.callMissingConnection.tr;
      return null;
    }

    for (var attempt = 0; attempt < 20; attempt++) {
      if (_shouldAbortAsyncWork) return null;
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_shouldAbortAsyncWork) return null;

      _logWebRtc('poll answer callId=$callId attempt=${attempt + 1}');
      final response = await _chatService.checkCallResponse(callId: callId);
      if (_shouldAbortAsyncWork) {
        final status = response.status.trim().toLowerCase();
        if (<String>{'answered', 'accepted', 'connected'}.contains(status)) {
          unawaited(_endCallById(callId));
        }
        return null;
      }
      final normalizedStatus = response.status.trim().toLowerCase();
      _logWebRtc(
        'poll answer status=$normalizedStatus hasCall=${response.call != null}',
      );
      switch (normalizedStatus) {
        case 'answered':
        case 'accepted':
        case 'connected':
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

  Future<void> _startWebRtcSession(ChatCallModel call) async {
    if (_shouldAbortAsyncWork) return;
    final connection = call.connection;
    if (connection == null || !connection.hasWebRtcConnection) {
      errorMessage.value = AppTranslations.callMissingWebRtcConnection.tr;
      _logWebRtc(
        'missing WebRTC connection callId=${call.callId} '
        'provider=${connection?.provider ?? '-'} '
        'publish=${connection?.publishUrl.isNotEmpty == true} '
        'playback=${connection?.playbackUrl.isNotEmpty == true}',
      );
      return;
    }

    _activeCallId = call.callId;
    _activeConnection = connection;
    _callWasAnswered = true;
    _applyParticipants(
      call.participants.isNotEmpty
          ? call.participants
          : connection.allParticipants,
    );
    statusText.value = AppTranslations.callConnecting.tr;
    _logWebRtc(
      'start session callId=${call.callId} room=${connection.room} '
      'publish=${connection.publishUrl.isNotEmpty} '
      'playback=${connection.playbackUrl.isNotEmpty}',
    );

    // Report support immediately so two updated clients can agree on P2P
    // while media permissions/audio-session setup is still in progress.
    final directPreflight = _prepareDirectP2pPreflight(call, connection);
    await _prepareLocalStream();
    if (_shouldAbortAsyncWork || _localStream == null) return;
    await _startCallForegroundService();
    if (_shouldAbortAsyncWork) return;
    final directConnected = await _tryStartDirectP2p(
      call,
      connection,
      preflight: await directPreflight,
    );
    if (_shouldAbortAsyncWork) return;
    if (directConnected) {
      _startParticipantsPolling();
      _connectedAt = DateTime.now();
      _startCallDurationTimer();
      isConnected.value = true;
      statusText.value = AppTranslations.callRemoteJoined.tr;
      _logWebRtc('session connected callId=${call.callId} topology=p2p');
      return;
    }

    final inFlightFallback = _sfuFallbackFuture;
    if (inFlightFallback != null) {
      await inFlightFallback;
    } else {
      await _startSfuMediaWithRetry(
        connection,
        reason: 'initial_or_p2p_unavailable',
      );
    }
    if (_shouldAbortAsyncWork) return;
    _startParticipantsPolling();
    _connectedAt = DateTime.now();
    _startCallDurationTimer();
    isConnected.value = true;
    statusText.value = AppTranslations.callRemoteJoined.tr;
    _logWebRtc('session connected callId=${call.callId} topology=sfu');
  }

  Future<bool> _tryStartDirectP2p(
    ChatCallModel call,
    ChatCallConnectionModel connection, {
    required ChatWebRtcIceConfigModel? preflight,
  }) async {
    if (_shouldAbortAsyncWork ||
        call.isGroupCall ||
        call.isGroupCallInvite ||
        call.participantCount > 2 ||
        call.pendingInviteCount > 0) {
      _logWebRtc(
        'direct P2P skipped enabled=${connection.p2pEnabled} '
        'topology=${connection.mediaTopology} group=${call.isGroupCall} '
        'participants=${call.participantCount} '
        'pending=${call.pendingInviteCount}',
      );
      return false;
    }

    final stream = _localStream;
    if (stream == null) return false;
    var iceServers = connection.iceServers;
    var peerUserId = connection.peerUserId;
    var p2pRole = connection.p2pRole;
    if (preflight != null) {
      if (!preflight.p2pEnabled || preflight.mediaTopology != 'p2p') {
        _logWebRtc(
          'direct P2P cancelled by server topology='
          '${preflight.mediaTopology}',
        );
        return false;
      }
      if (preflight.peerUserId > 0) peerUserId = preflight.peerUserId;
      if (<String>{'offerer', 'answerer'}.contains(preflight.p2pRole)) {
        p2pRole = preflight.p2pRole;
      }
      if (preflight.iceServers.isNotEmpty) {
        iceServers = _mergeIceServers(preflight.iceServers, iceServers);
      }
    } else if (!connection.canUseDirectP2p) {
      _logWebRtc(
        'direct P2P skipped because server capability negotiation is '
        'unavailable',
      );
      return false;
    }
    if (peerUserId <= 0 ||
        !<String>{'offerer', 'answerer'}.contains(p2pRole) ||
        iceServers.isEmpty) {
      _logWebRtc('direct P2P skipped because no ICE servers were provided');
      return false;
    }

    final session = DirectWebRtcSession(
      chatService: _chatService,
      callId: call.callId,
      peerUserId: peerUserId,
      isOfferer: p2pRole == 'offerer',
      localStream: stream,
      iceServers: iceServers,
      refreshIceServers: () async {
        final config = await _chatService.fetchWebRtcIceConfig(
          callId: call.callId,
        );
        return config.iceServers;
      },
      onTrack: (event) {
        unawaited(_attachDirectRemoteTrack(event));
      },
      onFallbackRequested: (reason) =>
          _migrateDirectToSfu(reason: 'remote_or_recovery:$reason'),
      log: _logWebRtc,
    );
    _directSession = session;
    statusText.value = AppTranslations.callConnecting.tr;
    try {
      await session.connect();
      if (_shouldAbortAsyncWork ||
          _directSession != session ||
          !session.isConnected) {
        if (_directSession == session) {
          _directSession = null;
        }
        await session.close();
        return false;
      }
      _usingDirectP2p = true;
      _usingSfu = false;
      _logWebRtc('direct P2P connected peer=$peerUserId role=$p2pRole');
      return true;
    } catch (error) {
      _logWebRtc('direct P2P failed; switching both peers to SFU: $error');
      if (!_shouldAbortAsyncWork) {
        final fallbackReason = error is DirectWebRtcFallbackException
            ? _safeFallbackReason(error.reason)
            : error is TimeoutException
            ? 'ice_timeout'
            : 'p2p_setup_failed';
        try {
          await session
              .announceFallback(fallbackReason)
              .timeout(const Duration(seconds: 2));
        } catch (_) {}
      }
      if (_directSession == session) {
        _directSession = null;
      }
      await session.close();
      _usingDirectP2p = false;
      await _clearDirectRemoteMedia();
      return false;
    }
  }

  Future<ChatWebRtcIceConfigModel?> _prepareDirectP2pPreflight(
    ChatCallModel call,
    ChatCallConnectionModel connection,
  ) async {
    if (call.callId <= 0 ||
        call.isGroupCall ||
        call.isGroupCallInvite ||
        call.participantCount > 2 ||
        call.pendingInviteCount > 0) {
      return null;
    }

    ChatWebRtcIceConfigModel? latest;
    Object? lastError;
    for (var attempt = 0; attempt < 8; attempt++) {
      if (_shouldAbortAsyncWork) return latest;
      try {
        latest = await _chatService
            .fetchWebRtcIceConfig(callId: call.callId, p2pCapability: true)
            .timeout(const Duration(seconds: 2));
        lastError = null;
        if (latest.p2pEnabled && latest.mediaTopology == 'p2p') {
          _logWebRtc(
            'direct capability agreed attempt=${attempt + 1} '
            'role=${latest.p2pRole}',
          );
          return latest;
        }
      } catch (error) {
        lastError = error;
        break;
      }
      if (attempt < 7) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }

    if (lastError != null) {
      _logWebRtc('direct capability negotiation unavailable: $lastError');
      // A connection payload from the same upgraded server is still usable
      // if the refresh endpoint was affected by a transient network failure.
      if (connection.canUseDirectP2p) return null;
      return _withdrawDirectP2pCapability(call.callId, latest);
    }
    _logWebRtc(
      'direct capability peer unavailable; use SFU topology='
      '${latest?.mediaTopology ?? connection.mediaTopology}',
    );
    return _withdrawDirectP2pCapability(call.callId, latest);
  }

  Future<ChatWebRtcIceConfigModel?> _withdrawDirectP2pCapability(
    int callId,
    ChatWebRtcIceConfigModel? fallback,
  ) async {
    try {
      return await _chatService
          .fetchWebRtcIceConfig(callId: callId, p2pCapability: false)
          .timeout(const Duration(seconds: 2));
    } catch (error) {
      _logWebRtc('direct capability withdrawal failed: $error');
      return fallback;
    }
  }

  Future<void> _startSfuMedia(
    ChatCallConnectionModel connection, {
    required String reason,
  }) async {
    if (_usingSfu || _shouldAbortAsyncWork) return;
    _usingSfu = true;
    _usingDirectP2p = false;
    _logWebRtc('starting SFU media reason=$reason');
    try {
      final connectionParticipants = connection.participants
          .where((participant) => participant.playbackUrl.trim().isNotEmpty)
          .toList();
      // Receiving the remote stream does not depend on our publisher being
      // fully registered. Start both paths together to avoid adding the
      // publisher/probe latency to the time before the first remote audio.
      if (connectionParticipants.isNotEmpty) {
        unawaited(
          _connectRemoteParticipants(connection, connectionParticipants),
        );
      } else {
        unawaited(_connectPlaybackWithRetry(connection));
      }
      await _connectPublisher(connection);
      _startQualityStats();
    } catch (_) {
      _usingSfu = false;
      rethrow;
    }
  }

  Future<void> _startSfuMediaWithRetry(
    ChatCallConnectionModel connection, {
    required String reason,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (_shouldAbortAsyncWork) {
        throw StateError('Call closed before SFU startup completed');
      }
      try {
        await _startSfuMedia(connection, reason: reason);
        if (!_usingSfu) {
          throw StateError('SFU startup did not establish a publisher');
        }
        return;
      } catch (error) {
        lastError = error;
        _logWebRtc(
          'SFU startup failed attempt=${attempt + 1} reason=$reason '
          'error=$error',
        );
        await _closePublisher();
        if (attempt < 2 && !_shouldAbortAsyncWork) {
          await Future<void>.delayed(Duration(milliseconds: 600 << attempt));
        }
      }
    }
    if (lastError != null) throw lastError;
  }

  Future<void> _migrateDirectToSfu({required String reason}) {
    final existing = _sfuFallbackFuture;
    if (existing != null) return existing;
    late final Future<void> migration;
    migration = _migrateDirectToSfuOnce(reason: reason).whenComplete(() {
      if (identical(_sfuFallbackFuture, migration)) {
        _sfuFallbackFuture = null;
      }
    });
    _sfuFallbackFuture = migration;
    return migration;
  }

  Future<void> _migrateDirectToSfuOnce({required String reason}) async {
    if (_usingSfu || _shouldAbortAsyncWork) return;
    final connection = _activeConnection;
    if (connection == null) return;
    final direct = _directSession;
    _directSession = null;
    _usingDirectP2p = false;
    try {
      await direct
          ?.announceFallback(_safeFallbackReason(reason))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await direct?.close();
    } catch (_) {}
    await _clearDirectRemoteMedia();
    statusText.value = AppTranslations.callConnecting.tr;
    try {
      await _startSfuMediaWithRetry(connection, reason: reason);
    } catch (error) {
      isConnected.value = false;
      errorMessage.value = error.toString();
      statusText.value = AppTranslations.callConnecting.tr;
      _logWebRtc('P2P to SFU migration failed terminally: $error');
      await _endCallFromRemote();
      return;
    }
    if (_shouldAbortAsyncWork) return;
    statusText.value = AppTranslations.callRemoteJoined.tr;
  }

  Future<void> _clearDirectRemoteMedia() async {
    remoteRenderer.srcObject = null;
    final directRemoteStreamFuture = _directRemoteStreamFuture;
    _directRemoteStreamFuture = null;
    if (directRemoteStreamFuture != null) {
      try {
        await (await directRemoteStreamFuture).dispose();
      } catch (_) {}
    }
    hasRemoteStream.value = false;
    _syncVideoTileOrder();
  }

  String _safeFallbackReason(String reason) {
    final normalized = reason.replaceAll(RegExp(r'[^A-Za-z0-9_.:-]'), '_');
    if (normalized.isEmpty) return 'sfu_required';
    return normalized.length <= 128 ? normalized : normalized.substring(0, 128);
  }

  Future<void> _attachDirectRemoteTrack(RTCTrackEvent event) async {
    try {
      final stream = await _remoteStreamForTrack(
        event,
        syntheticStream: () {
          return _directRemoteStreamFuture ??= createLocalMediaStream(
            'direct_remote',
          );
        },
      );
      if (_directSession == null || _isEndingCall || isClosed) return;
      remoteRenderer.srcObject = stream;
      hasRemoteStream.value = true;
      _syncVideoTileOrder();
      statusText.value = AppTranslations.callRemoteJoined.tr;
      _logWebRtc(
        'direct remote track kind=${event.track.kind} '
        'streams=${event.streams.length} synthetic=${event.streams.isEmpty}',
      );
    } catch (error) {
      _logWebRtc('direct remote track attach failed: $error');
    }
  }

  Future<void> _prepareLocalStream() async {
    if (_localStream != null || _shouldAbortAsyncWork) {
      return;
    }

    await _configureCallAudioSession();
    if (_shouldAbortAsyncWork) {
      await _cleanupCallAudioSession();
      return;
    }
    final audioConstraints = <String, dynamic>{
      'mandatory': <String, dynamic>{
        'echoCancellation': true,
        'googEchoCancellation': true,
        'noiseSuppression': true,
        'googNoiseSuppression': true,
        'autoGainControl': true,
        'googAutoGainControl': true,
        // flutter_webrtc 1.5.x expects RTCMediaConstraints values as strings:
        // Android hard-casts numeric values to Double, while Darwin converts
        // NSNumber values to booleans. Strings are safe on both platforms.
        'channelCount': '1',
        'sampleRate': '48000',
      },
      'optional': <Map<String, dynamic>>[
        <String, dynamic>{'googHighpassFilter': true},
        <String, dynamic>{'googTypingNoiseDetection': true},
      ],
    };
    final videoConstraints = isVideoCall
        ? <String, dynamic>{
            'facingMode': 'user',
            'width': 720,
            'height': 1280,
            'frameRate': _videoMaxFramerate,
          }
        : false;
    final constraints = <String, dynamic>{
      'audio': audioConstraints,
      'video': videoConstraints,
    };
    MediaStream stream;
    try {
      stream = await navigator.mediaDevices.getUserMedia(constraints);
    } catch (error) {
      _logWebRtc(
        'enhanced media constraints failed; retry platform defaults: $error',
      );
      try {
        stream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
          'audio': true,
          'video': videoConstraints,
        });
      } catch (_) {
        await _cleanupCallAudioSession();
        rethrow;
      }
    }
    if (_shouldAbortAsyncWork) {
      await _disposeMediaStream(stream);
      await _cleanupCallAudioSession();
      return;
    }
    if (isVideoCall && stream.getVideoTracks().isEmpty) {
      _logWebRtc('local video missing; retry relaxed camera constraints');
      await _disposeMediaStream(stream);
      stream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
        'audio': audioConstraints,
        'video': <String, dynamic>{
          'facingMode': 'user',
          'width': 720,
          'height': 1280,
          'frameRate': _videoMaxFramerate,
        },
      });
      if (_shouldAbortAsyncWork) {
        await _disposeMediaStream(stream);
        await _cleanupCallAudioSession();
        return;
      }
    }
    await _activateCallAudioSession();
    if (_shouldAbortAsyncWork) {
      await _disposeMediaStream(stream);
      await _cleanupCallAudioSession();
      return;
    }
    _localStream = stream;
    localRenderer.srcObject = stream;
    isLocalPreviewReady.value =
        isVideoCall && stream.getVideoTracks().isNotEmpty;
    _syncVideoTileOrder();
    _logWebRtc(
      'local media ready audio=${stream.getAudioTracks().length} '
      'video=${stream.getVideoTracks().length}',
    );
  }

  Future<void> _connectPublisher(ChatCallConnectionModel connection) async {
    await _closePublisher();
    final stream = _localStream;
    if (stream == null) {
      throw Exception(AppTranslations.callMissingConnection.tr);
    }

    final peer = await createPeerConnection(_peerConfig(connection));
    if (_shouldAbortAsyncWork) {
      try {
        await peer.close();
      } catch (_) {}
      try {
        await peer.dispose();
      } catch (_) {}
      return;
    }
    _publishPeer = peer;
    final diagnostics = _attachPeerDiagnostics(peer, 'publisher');
    for (final track in stream.getTracks()) {
      await peer.addTrack(track, stream);
    }

    await _connectOfferSocket(
      url: connection.publishUrl,
      peer: peer,
      connection: connection,
      diagnostics: diagnostics,
      publish: true,
      onSocketReady: (socket) => _publishSocket = socket,
    );
    await _waitForPeerReady(peer, 'publisher', diagnostics);
    await _waitForOutboundMedia(peer, stream, 'publisher');
    // Availability probing is diagnostic only. Remote playback has its own
    // retry loop, so this must never hold the call in "Connecting".
    unawaited(() async {
      try {
        await _waitForPublishedStreamAvailable(connection);
      } catch (error) {
        _logWebRtc('publisher playback probe skipped after failure: $error');
      }
    }());
    _logWebRtc('publisher connected');
  }

  Future<void> _connectPlaybackWithRetry(
    ChatCallConnectionModel connection,
  ) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      if (isClosed || _isEndingCall || hasRemoteStream.value) {
        return;
      }
      try {
        await _connectPlayback(connection);
        return;
      } catch (error) {
        _logWebRtc('playback retry attempt=${attempt + 1} reason=$error');
        statusText.value = AppTranslations.callWaitingForRemoteMedia.tr;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }

  void _applyParticipants(List<ChatCallParticipantModel> participants) {
    final normalized = participants
        .where((participant) => participant.userId > 0)
        .toList(growable: false);
    callParticipants.assignAll(normalized);
    activeParticipantCount.value = normalized
        .where((participant) => participant.isActive)
        .length;
    pendingInviteCount.value = normalized.where((participant) {
      final status = participant.status.trim().toLowerCase();
      return status == 'invited' || status == 'pending';
    }).length;
  }

  void _startParticipantsPolling() {
    _participantsTimer?.cancel();
    final callId = _activeCallId;
    if (callId == null || callId == 0) {
      return;
    }
    _participantsTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_refreshParticipants(reason: 'timer'));
    });
    unawaited(_refreshParticipants(reason: 'session_start'));
  }

  void _startQualityStats() {
    _qualityStatsTimer?.cancel();
    _qualityStatsTimer = Timer.periodic(_qualityStatsInterval, (_) {
      unawaited(_collectQualityStats());
    });
    unawaited(_collectQualityStats());
  }

  void _stopQualityStats() {
    _qualityStatsTimer?.cancel();
    _qualityStatsTimer = null;
    _lastQualityCounters.clear();
  }

  Future<void> _collectQualityStats() async {
    if (_qualityStatsRunning || _isEndingCall || isClosed) {
      return;
    }
    _qualityStatsRunning = true;
    try {
      final peers = <String, RTCPeerConnection>{};
      final publishPeer = _publishPeer;
      if (publishPeer != null) {
        peers['publisher'] = publishPeer;
      }
      final playbackPeer = _playbackPeer;
      if (playbackPeer != null) {
        peers['playback'] = playbackPeer;
      }
      for (final entry in _remotePlaybacks.entries) {
        final peer = entry.value.peer;
        if (peer != null) {
          peers['participant:${entry.key}'] = peer;
        }
      }

      final summaries = <String>[];
      for (final entry in peers.entries) {
        try {
          final snapshot = await _readPeerQualitySnapshot(entry.value);
          final currentCounters = _QualityCounters(
            packetsReceived: snapshot.packetsReceived,
            packetsLost: snapshot.packetsLost,
          );
          final previousCounters = _lastQualityCounters[entry.key];
          _lastQualityCounters[entry.key] = currentCounters;
          final receivedDelta = previousCounters == null
              ? 0
              : (currentCounters.packetsReceived -
                        previousCounters.packetsReceived)
                    .clamp(0, 1 << 62);
          final lostDelta = previousCounters == null
              ? 0
              : (currentCounters.packetsLost - previousCounters.packetsLost)
                    .clamp(0, 1 << 62);
          final intervalPackets = receivedDelta + lostDelta;
          final intervalLossPercent = intervalPackets > 0
              ? (lostDelta * 100 / intervalPackets)
              : 0.0;
          summaries.add(
            '${entry.key}{audio=${snapshot.hasInboundAudio} '
            'recv=${snapshot.packetsReceived} lost=${snapshot.packetsLost} '
            'loss=${intervalLossPercent.toStringAsFixed(1)}% '
            'jitter=${snapshot.jitterMs.toStringAsFixed(1)}ms '
            'jbuf=${snapshot.jitterBufferMs.toStringAsFixed(1)}ms '
            'concealed=${snapshot.concealedSamples} '
            'conceal=${snapshot.concealmentPercent.toStringAsFixed(1)}% '
            'rtt=${snapshot.rttMs.toStringAsFixed(1)}ms '
            'candidate=${snapshot.localCandidateType}/'
            '${snapshot.remoteCandidateType} '
            'protocol=${snapshot.protocol} network=${snapshot.networkType}}',
          );
        } catch (error) {
          summaries.add('${entry.key}{stats_error=$error}');
        }
      }
      if (summaries.isNotEmpty) {
        _logWebRtc('quality ${summaries.join(' | ')}');
      }
    } finally {
      _qualityStatsRunning = false;
    }
  }

  Future<_PeerQualitySnapshot> _readPeerQualitySnapshot(
    RTCPeerConnection peer,
  ) async {
    final reports = await peer.getStats();
    final reportsById = <String, StatsReport>{
      for (final report in reports) report.id: report,
    };
    var packetsReceived = 0;
    var packetsLost = 0;
    var concealedSamples = 0;
    var totalSamplesReceived = 0;
    var jitterMs = 0.0;
    var jitterBufferMs = 0.0;
    var hasInboundAudio = false;

    for (final report in reports) {
      if (report.type != 'inbound-rtp') {
        continue;
      }
      final kind = _statString(report.values, const ['kind', 'mediaType']);
      if (kind.toLowerCase() != 'audio') {
        continue;
      }
      hasInboundAudio = true;
      packetsReceived += _statInt(report.values, const ['packetsReceived']);
      packetsLost += _statInt(report.values, const ['packetsLost']);
      concealedSamples += _statInt(report.values, const ['concealedSamples']);
      totalSamplesReceived += _statInt(report.values, const [
        'totalSamplesReceived',
      ]);
      final reportJitterMs =
          _statDouble(report.values, const ['jitter']) * 1000;
      if (reportJitterMs > jitterMs) {
        jitterMs = reportJitterMs;
      }
      final jitterBufferDelay = _statDouble(report.values, const [
        'jitterBufferDelay',
      ]);
      final jitterBufferEmittedCount = _statDouble(report.values, const [
        'jitterBufferEmittedCount',
      ]);
      if (jitterBufferDelay > 0 && jitterBufferEmittedCount > 0) {
        final averageMs = jitterBufferDelay * 1000 / jitterBufferEmittedCount;
        if (averageMs > jitterBufferMs) {
          jitterBufferMs = averageMs;
        }
      }
    }

    StatsReport? selectedPair;
    for (final report in reports) {
      if (report.type != 'transport') {
        continue;
      }
      final pairId = _statString(report.values, const [
        'selectedCandidatePairId',
      ]);
      if (pairId.isNotEmpty) {
        selectedPair = reportsById[pairId];
        if (selectedPair != null) {
          break;
        }
      }
    }
    selectedPair ??= reports
        .where((report) {
          if (report.type != 'candidate-pair') {
            return false;
          }
          final selected = _statBool(report.values, const ['selected']);
          final nominated = _statBool(report.values, const ['nominated']);
          final state = _statString(report.values, const [
            'state',
          ]).toLowerCase();
          return selected || (nominated && state == 'succeeded');
        })
        .cast<StatsReport?>()
        .firstWhere((report) => report != null, orElse: () => null);

    final pairValues = selectedPair?.values ?? const <dynamic, dynamic>{};
    final localCandidateId = _statString(pairValues, const [
      'localCandidateId',
    ]);
    final remoteCandidateId = _statString(pairValues, const [
      'remoteCandidateId',
    ]);
    final localCandidate = reportsById[localCandidateId];
    final remoteCandidate = reportsById[remoteCandidateId];
    final localValues = localCandidate?.values ?? const <dynamic, dynamic>{};
    final remoteValues = remoteCandidate?.values ?? const <dynamic, dynamic>{};
    final concealmentPercent = totalSamplesReceived > 0
        ? concealedSamples * 100 / totalSamplesReceived
        : 0.0;

    return _PeerQualitySnapshot(
      hasInboundAudio: hasInboundAudio,
      packetsReceived: packetsReceived,
      packetsLost: packetsLost,
      concealedSamples: concealedSamples,
      concealmentPercent: concealmentPercent,
      jitterMs: jitterMs,
      jitterBufferMs: jitterBufferMs,
      rttMs: _statDouble(pairValues, const ['currentRoundTripTime']) * 1000,
      localCandidateType: _statString(localValues, const ['candidateType']),
      remoteCandidateType: _statString(remoteValues, const ['candidateType']),
      protocol: _statString(localValues, const ['protocol']),
      networkType: _statString(localValues, const ['networkType']),
    );
  }

  Future<void> _refreshParticipants({String reason = 'manual'}) async {
    final callId = _activeCallId;
    final connection = _activeConnection;
    if (callId == null || callId == 0 || connection == null || isClosed) {
      return;
    }

    try {
      final result = await _chatService.fetchWebRtcCallParticipants(
        callId: callId,
      );
      _applyParticipants(result.participants);
      if (_usingDirectP2p) {
        if (result.activeCount > 2 || result.pendingCount > 0) {
          await _migrateDirectToSfu(reason: 'group_membership_changed');
        }
        _logWebRtc(
          'participants refreshed reason=$reason topology=p2p '
          'active=${result.activeCount} pending=${result.pendingCount}',
        );
        return;
      }
      final activeRemote = result.participants
          .where(
            (participant) =>
                participant.isActive &&
                !participant.isCurrentUser &&
                participant.playbackUrl.trim().isNotEmpty,
          )
          .toList();
      await _connectRemoteParticipants(connection, activeRemote);
      await _removeInactiveRemoteParticipants(activeRemote);
      _logWebRtc(
        'participants refreshed reason=$reason active=${result.activeCount} '
        'pending=${result.pendingCount} remote=${activeRemote.length}',
      );
    } catch (error) {
      _logWebRtc('participants refresh failed reason=$reason error=$error');
    }
  }

  Future<void> _connectRemoteParticipants(
    ChatCallConnectionModel connection,
    List<ChatCallParticipantModel> participants,
  ) async {
    for (final participant in participants) {
      final userId = participant.userId;
      if (userId <= 0 ||
          participant.isCurrentUser ||
          _remotePlaybacks.containsKey(userId) ||
          !_remotePlaybackConnectionsInFlight.add(userId)) {
        continue;
      }
      unawaited(
        _connectRemoteParticipantWithRetry(
          connection,
          participant,
        ).whenComplete(() {
          _remotePlaybackConnectionsInFlight.remove(userId);
        }),
      );
    }
  }

  Future<void> _connectRemoteParticipantWithRetry(
    ChatCallConnectionModel connection,
    ChatCallParticipantModel participant,
  ) async {
    for (var attempt = 0; attempt < 12; attempt++) {
      if (isClosed ||
          _isEndingCall ||
          _remotePlaybacks[participant.userId]?.hasStream.value == true) {
        return;
      }
      try {
        await _connectRemoteParticipant(connection, participant);
        return;
      } catch (error) {
        final failedPlayback = _remotePlaybacks[participant.userId];
        if (failedPlayback != null) {
          _remotePlaybacks.remove(participant.userId);
          remoteParticipants.removeWhere(
            (item) => item.userId == participant.userId,
          );
        }
        _syncVideoTileOrder();
        if (failedPlayback != null) {
          _detachPeerDiagnostics(failedPlayback.peer);
          await failedPlayback.dispose();
        }
        _logWebRtc(
          'participant playback retry user=${participant.userId} '
          'attempt=${attempt + 1} reason=$error',
        );
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> _connectRemoteParticipant(
    ChatCallConnectionModel connection,
    ChatCallParticipantModel participant,
  ) async {
    final playbackUrl = participant.playbackUrl.trim();
    if (playbackUrl.isEmpty ||
        _remotePlaybacks.containsKey(participant.userId)) {
      return;
    }

    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    if (_shouldAbortAsyncWork) {
      await renderer.dispose();
      return;
    }
    final view = WebRtcRemoteParticipant(
      userId: participant.userId,
      displayName: participant.displayName,
      avatarUrl: participant.picture,
      renderer: renderer,
    );
    final playback = _RemoteWebRtcPlayback(
      participant: view,
      renderer: renderer,
    );
    _remotePlaybacks[participant.userId] = playback;
    remoteParticipants.add(view);
    _syncVideoTileOrder();

    final peer = await createPeerConnection(_peerConfig(connection));
    if (_shouldAbortAsyncWork ||
        _remotePlaybacks[participant.userId] != playback) {
      if (identical(_remotePlaybacks[participant.userId], playback)) {
        _remotePlaybacks.remove(participant.userId);
        remoteParticipants.removeWhere(
          (item) => item.userId == participant.userId,
        );
      }
      try {
        await peer.close();
      } catch (_) {}
      try {
        await peer.dispose();
      } catch (_) {}
      await playback.dispose();
      return;
    }
    playback.peer = peer;
    final diagnostics = _attachPeerDiagnostics(
      peer,
      'participant:${participant.userId}',
    );
    peer.onTrack = (event) {
      unawaited(_attachParticipantRemoteTrack(playback, event));
    };

    final participantConnection = connection.copyWithPlaybackUrl(playbackUrl);
    await _connectOfferSocket(
      url: playbackUrl,
      peer: peer,
      connection: participantConnection,
      diagnostics: diagnostics,
      publish: false,
      onSocketReady: (socket) => playback.socket = socket,
    );
    await _waitForPeerReady(
      peer,
      'participant:${participant.userId}',
      diagnostics,
    );
    _logWebRtc('participant playback connected user=${participant.userId}');
  }

  Future<void> _removeInactiveRemoteParticipants(
    List<ChatCallParticipantModel> activeRemote,
  ) async {
    final activeIds = activeRemote
        .map((participant) => participant.userId)
        .toSet();
    final staleIds = _remotePlaybacks.keys
        .where((userId) => !activeIds.contains(userId))
        .toList(growable: false);
    for (final userId in staleIds) {
      final playback = _remotePlaybacks.remove(userId);
      if (playback == null) {
        continue;
      }
      remoteParticipants.removeWhere((item) => item.userId == userId);
      _detachPeerDiagnostics(playback.peer);
      await playback.dispose();
    }
    hasRemoteStream.value =
        _remotePlaybacks.values.any((playback) => playback.hasStream.value) ||
        remoteRenderer.srcObject != null;
    _syncVideoTileOrder();
  }

  Future<void> _connectPlayback(ChatCallConnectionModel connection) async {
    await _closePlayback();
    final peer = await createPeerConnection(_peerConfig(connection));
    if (_shouldAbortAsyncWork) {
      try {
        await peer.close();
      } catch (_) {}
      try {
        await peer.dispose();
      } catch (_) {}
      return;
    }
    _playbackPeer = peer;
    final diagnostics = _attachPeerDiagnostics(peer, 'playback');
    peer.onTrack = (event) {
      unawaited(_attachLegacyRemoteTrack(event));
    };

    await _connectOfferSocket(
      url: connection.playbackUrl,
      peer: peer,
      connection: connection,
      diagnostics: diagnostics,
      publish: false,
      onSocketReady: (socket) => _playbackSocket = socket,
    );
    await _waitForPeerReady(peer, 'playback', diagnostics);
    _logWebRtc('playback connected');
  }

  Future<void> _attachParticipantRemoteTrack(
    _RemoteWebRtcPlayback playback,
    RTCTrackEvent event,
  ) async {
    try {
      final stream = await _remoteStreamForTrack(
        event,
        syntheticStream: () {
          return playback.syntheticStreamFuture ??= createLocalMediaStream(
            'remote_participant_${playback.participant.userId}',
          );
        },
      );
      if (_remotePlaybacks[playback.participant.userId] != playback ||
          playback.peer == null) {
        return;
      }
      playback.renderer.srcObject = stream;
      playback.participant.hasStream.value = true;
      hasRemoteStream.value = true;
      _syncVideoTileOrder();
      statusText.value = AppTranslations.callRemoteJoined.tr;
      _logWebRtc(
        'participant track received user=${playback.participant.userId} '
        'kind=${event.track.kind} streams=${event.streams.length} '
        'synthetic=${event.streams.isEmpty}',
      );
    } catch (error) {
      _logWebRtc(
        'participant track attach failed '
        'user=${playback.participant.userId} kind=${event.track.kind} '
        'error=$error',
      );
    }
  }

  Future<void> _attachLegacyRemoteTrack(RTCTrackEvent event) async {
    try {
      final stream = await _remoteStreamForTrack(
        event,
        syntheticStream: () {
          return _playbackSyntheticStreamFuture ??= createLocalMediaStream(
            'remote_playback',
          );
        },
      );
      if (_playbackPeer == null || _isEndingCall || isClosed) {
        return;
      }
      remoteRenderer.srcObject = stream;
      hasRemoteStream.value = true;
      _syncVideoTileOrder();
      statusText.value = AppTranslations.callRemoteJoined.tr;
      _logWebRtc(
        'remote track received kind=${event.track.kind} '
        'streams=${event.streams.length} synthetic=${event.streams.isEmpty}',
      );
    } catch (error) {
      _logWebRtc(
        'remote track attach failed kind=${event.track.kind} error=$error',
      );
    }
  }

  Future<MediaStream> _remoteStreamForTrack(
    RTCTrackEvent event, {
    required Future<MediaStream> Function() syntheticStream,
  }) async {
    if (event.streams.isNotEmpty) {
      return event.streams.first;
    }

    final stream = await syntheticStream();
    if (!stream.getTracks().any((track) => track.id == event.track.id)) {
      await stream.addTrack(event.track);
    }
    return stream;
  }

  Future<WebSocket> _connectOfferSocket({
    required String url,
    required RTCPeerConnection peer,
    required ChatCallConnectionModel connection,
    required _PeerDiagnostics diagnostics,
    required bool publish,
    required void Function(WebSocket socket) onSocketReady,
  }) async {
    final completer = Completer<WebSocket>();
    _logWebRtc('${publish ? 'publisher' : 'playback'} socket connecting');
    final socket = await WebSocket.connect(url);
    if (_shouldAbortAsyncWork) {
      await socket.close();
      throw StateError('Call closed while WebRTC signaling was connecting');
    }
    _connectingOfferSockets.add(socket);
    Timer? timeout;

    Future<void> fail(Object error) async {
      timeout?.cancel();
      _connectingOfferSockets.remove(socket);
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
      try {
        await socket.close();
      } catch (_) {}
    }

    socket.listen(
      (message) {
        unawaited(() async {
          try {
            if (_shouldAbortAsyncWork) {
              await fail(StateError('Call closed during WebRTC signaling'));
              return;
            }
            final payload = _decodeSocketMessage(message);
            if (payload == null) {
              return;
            }
            if (payload['command'] == 'error' ||
                (_parseInt(payload['code']) >= 400)) {
              await fail(
                Exception(
                  payload['message']?.toString() ??
                      payload['reason']?.toString() ??
                      payload['error']?.toString() ??
                      'WebRTC signaling failed',
                ),
              );
              _logWebRtc(
                '${publish ? 'publisher' : 'playback'} socket error '
                'code=${payload['code'] ?? '-'} '
                'message=${payload['message'] ?? payload['reason'] ?? '-'}',
              );
              return;
            }
            if (payload['command'] == 'candidate') {
              await _addSignaledCandidates(
                peer,
                payload,
                label: publish ? 'publisher' : 'playback',
              );
              return;
            }
            if (payload['command'] != 'offer' || payload['sdp'] == null) {
              return;
            }

            await _answerOffer(
              socket: socket,
              peer: peer,
              payload: payload,
              connection: connection,
              diagnostics: diagnostics,
              label: publish ? 'publisher' : 'playback',
            );
            if (_shouldAbortAsyncWork) {
              await fail(
                StateError('Call closed while WebRTC offer was handled'),
              );
              return;
            }
            timeout?.cancel();
            if (!completer.isCompleted) {
              onSocketReady(socket);
              _connectingOfferSockets.remove(socket);
              completer.complete(socket);
            }
            _logWebRtc('${publish ? 'publisher' : 'playback'} offer answered');
            if (publish) {
              statusText.value = AppTranslations.callPublishingMedia.tr;
            }
          } catch (error) {
            _logWebRtc(
              '${publish ? 'publisher' : 'playback'} socket failed: $error',
            );
            await fail(error);
          }
        }());
      },
      onError: (Object error) {
        _logWebRtc(
          '${publish ? 'publisher' : 'playback'} socket onError: $error',
        );
        unawaited(fail(error));
      },
      onDone: () {
        timeout?.cancel();
        _connectingOfferSockets.remove(socket);
        _logWebRtc('${publish ? 'publisher' : 'playback'} socket closed');
        if (!completer.isCompleted) {
          completer.completeError(
            Exception(AppTranslations.callWebRtcSocketClosed.tr),
          );
        }
      },
      cancelOnError: true,
    );

    socket.add(jsonEncode(<String, dynamic>{'command': 'request_offer'}));
    timeout = Timer(const Duration(seconds: 20), () {
      _logWebRtc('${publish ? 'publisher' : 'playback'} socket timed out');
      unawaited(fail(Exception(AppTranslations.callWebRtcTimedOut.tr)));
    });

    return completer.future;
  }

  Future<void> _addSignaledCandidates(
    RTCPeerConnection peer,
    Map<String, dynamic> payload, {
    required String label,
  }) async {
    final batch = payload['candidates'];
    if (batch is List) {
      for (final candidate in batch) {
        await _addCandidate(peer, candidate, label: label);
      }
      _logWebRtc('$label remote ice trickle received batch=${batch.length}');
      return;
    }

    final single = payload['candidate'];
    if (single is List) {
      for (final candidate in single) {
        await _addCandidate(peer, candidate, label: label);
      }
      _logWebRtc('$label remote ice trickle received batch=${single.length}');
      return;
    }

    await _addCandidate(
      peer,
      single is Map || single is String ? single : payload,
      label: label,
    );
  }

  _PeerDiagnostics _attachPeerDiagnostics(
    RTCPeerConnection peer,
    String label,
  ) {
    final diagnostics = _PeerDiagnostics();
    _peerDiagnostics[peer] = diagnostics;
    peer.onConnectionState = (state) {
      diagnostics.connectionState = state;
      _logWebRtc('$label peer connectionState=$state');
      _settlePeerDiagnostics(label, diagnostics);
      _handlePeerRecoveryState(peer, label, diagnostics);
    };
    peer.onIceConnectionState = (state) {
      diagnostics.iceConnectionState = state;
      _logWebRtc('$label peer iceConnectionState=$state');
      _settlePeerDiagnostics(label, diagnostics);
      _handlePeerRecoveryState(peer, label, diagnostics);
    };
    peer.onIceGatheringState = (state) {
      diagnostics.iceGatheringState = state;
      _logWebRtc('$label peer iceGatheringState=$state');
    };
    peer.onIceCandidate = (candidate) {
      diagnostics.localCandidateCount += 1;
      final candidateMap = _candidateMapFromRtcCandidate(candidate);
      if (candidateMap != null) {
        _queueOrSendLocalCandidate(diagnostics, label, candidateMap);
      }
      if (diagnostics.localCandidateCount <= 5) {
        _logWebRtc(
          '$label local ice candidate count=${diagnostics.localCandidateCount} '
          'mid=${candidate.sdpMid ?? '-'} '
          'type=${_candidateType(candidate.candidate ?? '')}',
        );
      }
    };
    return diagnostics;
  }

  void _handlePeerRecoveryState(
    RTCPeerConnection peer,
    String label,
    _PeerDiagnostics diagnostics,
  ) {
    if (diagnostics.disposed || _isEndingCall || isClosed) {
      diagnostics.recoveryTimer?.cancel();
      diagnostics.recoveryTimer = null;
      return;
    }

    final connectionState = diagnostics.connectionState;
    final iceState = diagnostics.iceConnectionState;
    final isConnected =
        connectionState ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnected ||
        iceState == RTCIceConnectionState.RTCIceConnectionStateConnected ||
        iceState == RTCIceConnectionState.RTCIceConnectionStateCompleted;
    if (isConnected) {
      diagnostics.recoveryTimer?.cancel();
      diagnostics.recoveryTimer = null;
      diagnostics.iceRestartAttempts = 0;
      return;
    }

    final peerIsClosed =
        connectionState ==
            RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
        iceState == RTCIceConnectionState.RTCIceConnectionStateClosed;
    if (peerIsClosed) {
      diagnostics.recoveryTimer?.cancel();
      diagnostics.recoveryTimer = null;
      return;
    }

    final isFailed =
        connectionState ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
        iceState == RTCIceConnectionState.RTCIceConnectionStateFailed;
    final isDisconnected =
        connectionState ==
            RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
        iceState == RTCIceConnectionState.RTCIceConnectionStateDisconnected;
    if (!isFailed && !isDisconnected) {
      return;
    }
    if (!diagnostics.hasConnectedOnce || diagnostics.trickleSocket == null) {
      // Initial connection failures are handled by the existing connect retry.
      return;
    }

    diagnostics.recoveryTimer?.cancel();
    diagnostics.recoveryTimer = Timer(
      isFailed ? Duration.zero : _disconnectedRecoveryDelay,
      () => unawaited(_attemptIceRecovery(peer, label, diagnostics)),
    );
  }

  Future<void> _attemptIceRecovery(
    RTCPeerConnection peer,
    String label,
    _PeerDiagnostics diagnostics,
  ) async {
    diagnostics.recoveryTimer = null;
    if (diagnostics.disposed ||
        diagnostics.recoveryInFlight ||
        _isEndingCall ||
        isClosed ||
        _peerDiagnostics[peer] != diagnostics) {
      return;
    }

    try {
      final connectionState = await peer.getConnectionState();
      final iceState = await peer.getIceConnectionState();
      final recovered =
          connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateConnected ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateCompleted;
      if (recovered) {
        diagnostics.iceRestartAttempts = 0;
        return;
      }
    } catch (_) {}

    final now = DateTime.now();
    final lastRestartAt = diagnostics.lastIceRestartAt;
    if (lastRestartAt != null &&
        now.difference(lastRestartAt) < _iceRestartCooldown) {
      final remaining = _iceRestartCooldown - now.difference(lastRestartAt);
      diagnostics.recoveryTimer = Timer(
        remaining,
        () => unawaited(_attemptIceRecovery(peer, label, diagnostics)),
      );
      return;
    }
    if (diagnostics.iceRestartAttempts >= _maxIceRestartAttempts) {
      _logWebRtc(
        '$label ICE recovery exhausted attempts=${diagnostics.iceRestartAttempts}',
      );
      return;
    }

    final socket = diagnostics.trickleSocket;
    if (socket == null) {
      return;
    }
    diagnostics.recoveryInFlight = true;
    diagnostics.iceRestartAttempts += 1;
    diagnostics.lastIceRestartAt = now;
    diagnostics.answerSent = false;
    diagnostics.pendingLocalCandidates.clear();
    try {
      await peer.restartIce();
      socket.add(
        jsonEncode(<String, dynamic>{
          'command': 'request_offer',
          'ice_restart': true,
          if (diagnostics.trickleOfferId != null)
            'id': diagnostics.trickleOfferId,
          if (diagnostics.tricklePeerId != null)
            'peer_id': diagnostics.tricklePeerId,
        }),
      );
      _logWebRtc(
        '$label ICE restart requested '
        'attempt=${diagnostics.iceRestartAttempts}',
      );
    } catch (error) {
      diagnostics.answerSent = true;
      _logWebRtc(
        '$label ICE restart failed attempt=${diagnostics.iceRestartAttempts} '
        'error=$error',
      );
    } finally {
      diagnostics.recoveryInFlight = false;
    }

    if (!diagnostics.disposed &&
        diagnostics.iceRestartAttempts < _maxIceRestartAttempts) {
      diagnostics.recoveryTimer = Timer(
        _iceRestartRetryDelay,
        () => unawaited(_attemptIceRecovery(peer, label, diagnostics)),
      );
    }
  }

  void _detachPeerDiagnostics(RTCPeerConnection? peer) {
    if (peer == null) {
      return;
    }
    final diagnostics = _peerDiagnostics.remove(peer);
    if (diagnostics == null) {
      return;
    }
    diagnostics.disposed = true;
    diagnostics.recoveryTimer?.cancel();
    diagnostics.recoveryTimer = null;
    diagnostics.trickleSocket = null;
    diagnostics.pendingLocalCandidates.clear();
  }

  Future<void> _waitForPeerReady(
    RTCPeerConnection peer,
    String label,
    _PeerDiagnostics diagnostics, {
    Duration timeout = const Duration(seconds: 18),
  }) async {
    await _refreshPeerDiagnostics(peer, label, diagnostics);
    if (diagnostics.ready.isCompleted) {
      return diagnostics.ready.future;
    }

    final timer = Timer(timeout, () {
      if (diagnostics.ready.isCompleted) {
        return;
      }
      diagnostics.ready.completeError(
        Exception(
          '$label peer did not connect '
          'connectionState=${diagnostics.connectionState} '
          'iceConnectionState=${diagnostics.iceConnectionState} '
          'iceGatheringState=${diagnostics.iceGatheringState} '
          'localCandidates=${diagnostics.localCandidateCount}',
        ),
      );
    });

    try {
      await diagnostics.ready.future;
    } finally {
      timer.cancel();
    }
  }

  Future<void> _refreshPeerDiagnostics(
    RTCPeerConnection peer,
    String label,
    _PeerDiagnostics diagnostics,
  ) async {
    try {
      diagnostics.connectionState = await peer.getConnectionState();
      diagnostics.iceConnectionState = await peer.getIceConnectionState();
      diagnostics.iceGatheringState = await peer.getIceGatheringState();
      _logWebRtc(
        '$label peer current connectionState=${diagnostics.connectionState} '
        'iceConnectionState=${diagnostics.iceConnectionState} '
        'iceGatheringState=${diagnostics.iceGatheringState}',
      );
      _settlePeerDiagnostics(label, diagnostics);
    } catch (error) {
      _logWebRtc('$label peer state read failed: $error');
    }
  }

  void _settlePeerDiagnostics(String label, _PeerDiagnostics diagnostics) {
    if (diagnostics.ready.isCompleted) {
      return;
    }
    final connectionState = diagnostics.connectionState;
    final iceConnectionState = diagnostics.iceConnectionState;
    if (connectionState ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnected ||
        iceConnectionState ==
            RTCIceConnectionState.RTCIceConnectionStateConnected ||
        iceConnectionState ==
            RTCIceConnectionState.RTCIceConnectionStateCompleted) {
      diagnostics.hasConnectedOnce = true;
      diagnostics.ready.complete();
      return;
    }
    if (connectionState ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
        connectionState ==
            RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
        iceConnectionState ==
            RTCIceConnectionState.RTCIceConnectionStateFailed ||
        iceConnectionState ==
            RTCIceConnectionState.RTCIceConnectionStateClosed) {
      diagnostics.ready.completeError(
        Exception(
          '$label peer failed '
          'connectionState=$connectionState '
          'iceConnectionState=$iceConnectionState',
        ),
      );
    }
  }

  Future<void> _waitForOutboundMedia(
    RTCPeerConnection peer,
    MediaStream stream,
    String label, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final hasAudio = stream.getAudioTracks().isNotEmpty;
    final hasVideo = stream.getVideoTracks().isNotEmpty;
    if (!hasAudio && !hasVideo) {
      _logWebRtc('$label outbound media skipped no local tracks');
      return;
    }

    final startedAt = DateTime.now();
    _OutboundMediaSnapshot? lastSnapshot;
    var statsReadFailed = false;
    while (DateTime.now().difference(startedAt) < timeout) {
      try {
        lastSnapshot = await _readOutboundMediaSnapshot(peer);
      } catch (error) {
        if (!statsReadFailed) {
          statsReadFailed = true;
          _logWebRtc('$label outbound media stats failed: $error');
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
        continue;
      }
      if (lastSnapshot.hasMedia) {
        _logWebRtc(
          '$label outbound media ready '
          'kind=${lastSnapshot.kind} bytes=${lastSnapshot.bytesSent} '
          'frames=${lastSnapshot.framesEncoded}',
        );
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    _logWebRtc(
      '$label outbound media not confirmed '
      'lastKind=${lastSnapshot?.kind ?? '-'} '
      'lastBytes=${lastSnapshot?.bytesSent ?? 0} '
      'lastFrames=${lastSnapshot?.framesEncoded ?? 0}',
    );
  }

  Future<_OutboundMediaSnapshot> _readOutboundMediaSnapshot(
    RTCPeerConnection peer,
  ) async {
    final reports = await peer.getStats();
    var best = const _OutboundMediaSnapshot();
    for (final report in reports) {
      if (report.type != 'outbound-rtp') {
        continue;
      }
      final kind = _statString(report.values, const ['kind', 'mediaType']);
      final bytesSent = _statInt(report.values, const ['bytesSent']);
      final framesEncoded = _statInt(report.values, const ['framesEncoded']);
      final snapshot = _OutboundMediaSnapshot(
        kind: kind,
        bytesSent: bytesSent,
        framesEncoded: framesEncoded,
      );
      if (snapshot.score > best.score) {
        best = snapshot;
      }
    }
    return best;
  }

  Future<void> _waitForPublishedStreamAvailable(
    ChatCallConnectionModel connection,
  ) async {
    final probeUrl = _playbackProbeUrlForPublishUrl(connection.publishUrl);
    if (probeUrl.isEmpty) {
      _logWebRtc('publisher playback probe skipped missing url');
      return;
    }
    await _waitForPlaybackOfferAvailable(
      url: probeUrl,
      label: 'publisher',
      timeout: const Duration(seconds: 12),
    );
  }

  String _playbackProbeUrlForPublishUrl(String publishUrl) {
    final uri = Uri.tryParse(publishUrl);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return '';
    }
    final query = Map<String, String>.from(uri.queryParameters);
    query['direction'] = 'recv';
    query.putIfAbsent('transport', () => 'all');
    return uri.replace(queryParameters: query).toString();
  }

  Future<void> _waitForPlaybackOfferAvailable({
    required String url,
    required String label,
    required Duration timeout,
  }) async {
    final startedAt = DateTime.now();
    Object? lastError;
    var attempt = 0;
    while (DateTime.now().difference(startedAt) < timeout) {
      attempt += 1;
      try {
        await _probePlaybackOffer(url: url);
        _logWebRtc('$label playback probe ready attempt=$attempt');
        return;
      } catch (error) {
        lastError = error;
        if (attempt <= 3) {
          _logWebRtc(
            '$label playback probe waiting attempt=$attempt reason=$error',
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    throw Exception('$label playback probe failed: $lastError');
  }

  Future<void> _probePlaybackOffer({required String url}) async {
    final socket = await WebSocket.connect(
      url,
    ).timeout(const Duration(seconds: 3));
    final completer = Completer<void>();
    Timer? timeout;

    Future<void> completeError(Object error) async {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
      try {
        await socket.close();
      } catch (_) {}
    }

    socket.listen(
      (message) {
        final payload = _decodeSocketMessage(message);
        if (payload == null) {
          return;
        }
        if (payload['command'] == 'offer' && payload['sdp'] != null) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          unawaited(socket.close());
          return;
        }
        if (payload['command'] == 'error' ||
            _parseInt(payload['code']) >= 400) {
          unawaited(
            completeError(
              Exception(
                payload['message']?.toString() ??
                    payload['reason']?.toString() ??
                    payload['error']?.toString() ??
                    'WebRTC playback probe failed',
              ),
            ),
          );
        }
      },
      onError: (Object error) {
        unawaited(completeError(error));
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception(AppTranslations.callWebRtcSocketClosed.tr),
          );
        }
      },
      cancelOnError: true,
    );

    timeout = Timer(const Duration(milliseconds: 1200), () {
      unawaited(completeError(Exception('WebRTC playback probe timed out')));
    });
    socket.add(jsonEncode(<String, dynamic>{'command': 'request_offer'}));

    try {
      await completer.future;
    } finally {
      timeout.cancel();
      try {
        await socket.close();
      } catch (_) {}
    }
  }

  String _statString(Map<dynamic, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  int _statInt(Map<dynamic, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      final parsed = num.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed.round();
      }
    }
    return 0;
  }

  double _statDouble(Map<dynamic, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key];
      if (value is num) {
        return value.toDouble();
      }
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return 0;
  }

  bool _statBool(Map<dynamic, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key];
      if (value is bool) {
        return value;
      }
      final normalized = value?.toString().trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return false;
  }

  List<Map<String, dynamic>> _iceServersFromOffer(
    Map<String, dynamic> payload,
  ) {
    final raw = payload['iceServers'] ?? payload['ice_servers'];
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((item) => _normalizeIceServer(Map<String, dynamic>.from(item)))
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _normalizeIceServer(Map<String, dynamic> server) {
    final normalized = Map<String, dynamic>.from(server);
    if (!normalized.containsKey('username') &&
        normalized['user_name']?.toString().trim().isNotEmpty == true) {
      normalized['username'] = normalized['user_name'];
    }
    normalized.remove('user_name');

    final urls = normalized['urls'] ?? normalized['url'];
    final hasUrls = urls is List
        ? urls.isNotEmpty
        : urls?.toString().trim().isNotEmpty == true;
    if (!hasUrls) {
      return const <String, dynamic>{};
    }
    return normalized;
  }

  List<Map<String, dynamic>> _mergeIceServers(
    List<Map<String, dynamic>> preferred,
    List<Map<String, dynamic>> fallback,
  ) {
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];
    for (final server in [...preferred, ...fallback]) {
      final normalized = _normalizeIceServer(server);
      if (normalized.isEmpty) {
        continue;
      }
      final key = _iceServerKey(normalized);
      if (seen.add(key)) {
        merged.add(normalized);
      }
    }
    return merged;
  }

  String _iceServerKey(Map<String, dynamic> server) {
    final urls = server['urls'] ?? server['url'];
    final urlText = urls is List ? urls.join('|') : urls?.toString() ?? '';
    return '$urlText|${server['username'] ?? ''}';
  }

  int _sdpCandidateCount(String sdp) {
    if (sdp.isEmpty) {
      return 0;
    }
    return RegExp(
      r'(^|\r?\n)a=candidate:',
      multiLine: true,
    ).allMatches(sdp).length;
  }

  Future<String> _safeIceGatheringState(RTCPeerConnection peer) async {
    try {
      return (await peer.getIceGatheringState()).toString();
    } catch (error) {
      return 'unavailable:$error';
    }
  }

  String _candidateType(String candidate) {
    final parts = candidate.trim().split(RegExp(r'\s+'));
    final typeIndex = parts.indexOf('typ');
    if (typeIndex >= 0 && typeIndex + 1 < parts.length) {
      return parts[typeIndex + 1];
    }
    return 'unknown';
  }

  Future<void> _answerOffer({
    required WebSocket socket,
    required RTCPeerConnection peer,
    required Map<String, dynamic> payload,
    required ChatCallConnectionModel connection,
    required _PeerDiagnostics diagnostics,
    required String label,
  }) async {
    await _applyOfferIceServers(peer, payload, connection, label);
    final remoteDescription = _descriptionFromPayload(payload['sdp']);
    final sdpMidsByIndex = _sdpMidsByIndex(remoteDescription.sdp ?? '');
    await peer.setRemoteDescription(remoteDescription);
    final candidates = payload['candidates'];
    var remoteCandidateCount = 0;
    if (candidates is List) {
      remoteCandidateCount = candidates.length;
      for (final candidate in candidates) {
        await _addCandidate(
          peer,
          candidate,
          sdpMidsByIndex: sdpMidsByIndex,
          label: label,
        );
      }
    }

    final answer = await peer.createAnswer();
    await peer.setLocalDescription(answer);
    final description = await _waitForLocalAnswerDescription(
      peer,
      answer,
      label,
    );
    if (label == 'publisher') {
      await _applyPublisherSenderParameters(peer);
    }
    _logWebRtc(
      '$label answer ready '
      'remoteCandidates=$remoteCandidateCount '
      'localCandidates=${_sdpCandidateCount(description.sdp ?? '')} '
      'iceGatheringState=${await _safeIceGatheringState(peer)}',
    );
    socket.add(
      jsonEncode(<String, dynamic>{
        'command': 'answer',
        'id': payload['id'],
        'peer_id': payload['peer_id'],
        'sdp': <String, dynamic>{
          'type': description.type,
          'sdp': description.sdp,
        },
      }),
    );
    _enableCandidateTrickle(
      diagnostics: diagnostics,
      socket: socket,
      payload: payload,
      label: label,
    );
  }

  Future<void> _applyPublisherSenderParameters(RTCPeerConnection peer) async {
    List<RTCRtpSender> senders;
    try {
      senders = await peer.getSenders();
    } catch (error) {
      _logWebRtc('publisher sender parameters unavailable: $error');
      return;
    }

    for (final sender in senders) {
      final kind = sender.track?.kind?.trim().toLowerCase() ?? '';
      if (kind != 'audio' && kind != 'video') {
        continue;
      }
      final parameters = sender.parameters;
      final encodings = parameters.encodings;
      if (encodings == null || encodings.isEmpty) {
        _logWebRtc('publisher $kind sender has no configurable encodings');
        continue;
      }

      for (final encoding in encodings) {
        if (kind == 'audio') {
          encoding.maxBitrate = _audioMaxBitrateBps;
          encoding.priority = RTCPriorityType.high;
          encoding.networkPriority = RTCPriorityType.high;
        } else {
          encoding.maxBitrate = _videoMaxBitrateBps;
          encoding.maxFramerate = _videoMaxFramerate;
          encoding.priority = RTCPriorityType.medium;
          encoding.networkPriority = RTCPriorityType.medium;
        }
      }
      if (kind == 'video') {
        parameters.degradationPreference = RTCDegradationPreference.BALANCED;
      }

      try {
        final applied = await sender.setParameters(parameters);
        _logWebRtc(
          'publisher $kind sender parameters applied=$applied '
          'maxBitrate=${kind == 'audio' ? _audioMaxBitrateBps : _videoMaxBitrateBps} '
          'maxFps=${kind == 'video' ? _videoMaxFramerate : '-'}',
        );
      } catch (error) {
        _logWebRtc(
          'publisher $kind sender parameters unsupported; using negotiated '
          'defaults: $error',
        );
      }
    }
  }

  void _enableCandidateTrickle({
    required _PeerDiagnostics diagnostics,
    required WebSocket socket,
    required Map<String, dynamic> payload,
    required String label,
  }) {
    diagnostics.trickleSocket = socket;
    diagnostics.tricklePeerId = payload['peer_id'];
    diagnostics.trickleOfferId = payload['id'];
    diagnostics.answerSent = true;
    _flushLocalCandidates(diagnostics, label);
  }

  Map<String, dynamic>? _candidateMapFromRtcCandidate(
    RTCIceCandidate candidate,
  ) {
    final candidateText = _normalizeCandidateText(candidate.candidate ?? '');
    if (candidateText.isEmpty) {
      return null;
    }
    return <String, dynamic>{
      'candidate': candidateText,
      'sdpMid': candidate.sdpMid ?? '0',
      'sdpMLineIndex': candidate.sdpMLineIndex ?? 0,
    };
  }

  void _queueOrSendLocalCandidate(
    _PeerDiagnostics diagnostics,
    String label,
    Map<String, dynamic> candidate,
  ) {
    if (diagnostics.answerSent && diagnostics.trickleSocket != null) {
      _sendCandidateBatch(diagnostics, label, <Map<String, dynamic>>[
        candidate,
      ]);
      return;
    }
    diagnostics.pendingLocalCandidates.add(candidate);
  }

  void _flushLocalCandidates(_PeerDiagnostics diagnostics, String label) {
    if (diagnostics.pendingLocalCandidates.isEmpty) {
      return;
    }
    final candidates = List<Map<String, dynamic>>.from(
      diagnostics.pendingLocalCandidates,
    );
    diagnostics.pendingLocalCandidates.clear();
    _sendCandidateBatch(diagnostics, label, candidates);
  }

  void _sendCandidateBatch(
    _PeerDiagnostics diagnostics,
    String label,
    List<Map<String, dynamic>> candidates,
  ) {
    final socket = diagnostics.trickleSocket;
    final peerId = diagnostics.tricklePeerId;
    if (socket == null || peerId == null || candidates.isEmpty) {
      return;
    }
    socket.add(
      jsonEncode(<String, dynamic>{
        'command': 'candidate',
        if (diagnostics.trickleOfferId != null)
          'id': diagnostics.trickleOfferId,
        'peer_id': peerId,
        'candidates': candidates,
      }),
    );
    diagnostics.trickledCandidateCount += candidates.length;
    if (diagnostics.trickledCandidateCount <= 10) {
      _logWebRtc(
        '$label local ice trickle sent '
        'batch=${candidates.length} total=${diagnostics.trickledCandidateCount}',
      );
    }
  }

  Future<void> _applyOfferIceServers(
    RTCPeerConnection peer,
    Map<String, dynamic> payload,
    ChatCallConnectionModel connection,
    String label,
  ) async {
    final offerIceServers = _iceServersFromOffer(payload);
    if (offerIceServers.isEmpty) {
      _logWebRtc(
        '$label offer iceServers missing fallback=${connection.iceServers.length}',
      );
      return;
    }

    final iceServers = _mergeIceServers(offerIceServers, connection.iceServers);
    try {
      await peer.setConfiguration(_peerConfigForIceServers(iceServers));
      _logWebRtc(
        '$label offer iceServers applied '
        'offer=${offerIceServers.length} total=${iceServers.length}',
      );
    } catch (error) {
      _logWebRtc('$label offer iceServers apply failed: $error');
    }
  }

  Future<RTCSessionDescription> _waitForLocalAnswerDescription(
    RTCPeerConnection peer,
    RTCSessionDescription fallback,
    String label, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final startedAt = DateTime.now();
    RTCSessionDescription? latest;
    var lastCandidateCount = 0;

    while (DateTime.now().difference(startedAt) < timeout) {
      latest = await peer.getLocalDescription();
      final sdp = latest?.sdp ?? fallback.sdp ?? '';
      final candidateCount = _sdpCandidateCount(sdp);
      if (candidateCount > 0) {
        return latest ?? fallback;
      }
      if (candidateCount != lastCandidateCount) {
        lastCandidateCount = candidateCount;
        _logWebRtc('$label waiting local ICE candidates count=$candidateCount');
      }
      final gatheringState = await _safeIceGatheringState(peer);
      if (gatheringState ==
          RTCIceGatheringState.RTCIceGatheringStateComplete.toString()) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    latest ??= await peer.getLocalDescription();
    final description = latest ?? fallback;
    final candidateCount = _sdpCandidateCount(description.sdp ?? '');
    if (candidateCount == 0) {
      throw Exception(
        '$label answer has no local ICE candidates '
        'iceGatheringState=${await _safeIceGatheringState(peer)}',
      );
    }
    return description;
  }

  RTCSessionDescription _descriptionFromPayload(dynamic raw) {
    if (raw is Map) {
      return RTCSessionDescription(
        raw['sdp']?.toString() ?? '',
        raw['type']?.toString() ?? 'offer',
      );
    }
    return RTCSessionDescription(raw?.toString() ?? '', 'offer');
  }

  Map<int, String> _sdpMidsByIndex(String sdp) {
    final mids = <int, String>{};
    var mLineIndex = -1;
    for (final line in sdp.split(RegExp(r'\r?\n'))) {
      if (line.startsWith('m=')) {
        mLineIndex += 1;
        continue;
      }
      if (mLineIndex >= 0 && line.startsWith('a=mid:')) {
        final mid = line.substring(6).trim();
        if (mid.isNotEmpty) {
          mids[mLineIndex] = mid;
        }
      }
    }
    return mids;
  }

  Future<void> _addCandidate(
    RTCPeerConnection peer,
    dynamic rawCandidate, {
    Map<int, String> sdpMidsByIndex = const <int, String>{},
    String? label,
  }) async {
    final candidateMap = _candidatePayload(rawCandidate);
    if (candidateMap == null) {
      return;
    }
    final candidate = _normalizeCandidateText(
      _candidateString(candidateMap, const ['candidate']),
    );
    if (candidate.isEmpty) {
      return;
    }
    if (!candidate.startsWith('candidate:')) {
      _skippedIceCandidates += 1;
      if (_skippedIceCandidates <= 3) {
        _logWebRtc(
          'skip unsupported ice candidate count=$_skippedIceCandidates',
        );
      }
      return;
    }
    final sdpMLineIndex = _candidateInt(candidateMap, const [
      'sdpMLineIndex',
      'sdp_mline_index',
      'sdpMlineIndex',
    ]);
    final sdpMid = _candidateString(candidateMap, const [
      'sdpMid',
      'sdp_mid',
      'mid',
    ]);
    final normalizedSdpMid = sdpMid.isNotEmpty
        ? sdpMid
        : sdpMidsByIndex[sdpMLineIndex];
    final normalizedSdpMLineIndex = sdpMLineIndex >= 0
        ? sdpMLineIndex
        : sdpMidsByIndex.entries
              .firstWhere(
                (entry) => entry.value == normalizedSdpMid,
                orElse: () => const MapEntry(0, ''),
              )
              .key;

    try {
      await peer.addCandidate(
        RTCIceCandidate(candidate, normalizedSdpMid, normalizedSdpMLineIndex),
      );
      if (label != null && sdpMid.isEmpty && normalizedSdpMid != null) {
        _logWebRtc(
          '$label remote ice candidate mid inferred '
          'index=$normalizedSdpMLineIndex mid=$normalizedSdpMid '
          'type=${_candidateType(candidate)}',
        );
      }
    } catch (error) {
      _ignoredIceCandidateErrors += 1;
      if (_ignoredIceCandidateErrors <= 5) {
        _logWebRtc(
          'ignore ice candidate error count=$_ignoredIceCandidateErrors '
          'mid=$normalizedSdpMid index=$normalizedSdpMLineIndex reason=$error',
        );
      }
    }
  }

  Map<String, dynamic>? _candidatePayload(dynamic rawCandidate) {
    if (rawCandidate is Map) {
      final nestedCandidate = rawCandidate['candidate'];
      if (nestedCandidate is Map) {
        return Map<String, dynamic>.from(nestedCandidate);
      }
      return Map<String, dynamic>.from(rawCandidate);
    }
    final candidate = rawCandidate?.toString().trim() ?? '';
    if (candidate.isEmpty) {
      return null;
    }
    return <String, dynamic>{'candidate': candidate, 'sdpMLineIndex': 0};
  }

  String _candidateString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  int _candidateInt(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is int) {
        return value;
      }
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return -1;
  }

  String _normalizeCandidateText(String value) {
    var candidate = value.trim();
    if (candidate.isEmpty || candidate.toLowerCase() == 'null') {
      return '';
    }
    if (candidate.toLowerCase() == 'end-of-candidates') {
      return '';
    }
    if (candidate.startsWith('a=candidate:')) {
      candidate = candidate.substring(2);
    }
    return candidate;
  }

  Map<String, dynamic> _peerConfig(ChatCallConnectionModel connection) {
    return _peerConfigForIceServers(connection.iceServers);
  }

  Map<String, dynamic> _peerConfigForIceServers(
    List<Map<String, dynamic>> iceServers,
  ) {
    return <String, dynamic>{
      'iceServers': iceServers,
      'iceTransportPolicy': 'all',
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    };
  }

  Map<String, dynamic>? _decodeSocketMessage(dynamic message) {
    try {
      final text = message is List<int>
          ? utf8.decode(message)
          : message?.toString() ?? '';
      if (text.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(text);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
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

  Future<void> _endCallById(int callId) async {
    if (callId <= 0) return;
    try {
      await _chatService.endCall(callId: callId);
    } catch (_) {}
  }

  Future<void> _cancelCallById(int callId) async {
    if (callId <= 0) return;
    try {
      await _chatService.cancelCall(callId: callId);
    } catch (_) {}
  }

  Future<void> _cancelOutgoingCall() async {
    final callId = _activeCallId;
    if (callId == null || callId == 0) {
      return;
    }
    await _cancelCallById(callId);
  }

  Future<void> _endCallFromRemote() async {
    if (_isEndingCall) {
      return;
    }
    _isEndingCall = true;
    _heartbeatTimer?.cancel();
    _participantsTimer?.cancel();
    _incomingDecisionTimer?.cancel();
    _stopQualityStats();
    _stopCallDurationTimer();
    await _stopAllCallAudio();
    await _disposeWebRtc();
    await _disableWakelock();
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
    }
  }

  Future<void> _disposeWebRtc() {
    final existing = _disposeWebRtcFuture;
    if (existing != null) return existing;
    late final Future<void> cleanup;
    cleanup = _disposeWebRtcOnce().whenComplete(() {
      if (identical(_disposeWebRtcFuture, cleanup)) {
        _disposeWebRtcFuture = null;
      }
    });
    _disposeWebRtcFuture = cleanup;
    return cleanup;
  }

  Future<void> _disposeWebRtcOnce() async {
    _logWebRtc('dispose WebRTC resources');
    _stopQualityStats();
    final directSession = _directSession;
    _directSession = null;
    _usingDirectP2p = false;
    _usingSfu = false;
    try {
      await directSession?.close();
    } catch (_) {}
    final connectingSockets = _connectingOfferSockets.toList(growable: false);
    _connectingOfferSockets.clear();
    for (final socket in connectingSockets) {
      try {
        await socket.close();
      } catch (_) {}
    }
    await _closePublisher();
    await _closePlayback();
    for (final peer in _peerDiagnostics.keys.toList(growable: false)) {
      _detachPeerDiagnostics(peer);
    }
    final stream = _localStream;
    _localStream = null;
    if (stream != null) {
      await _disposeMediaStream(stream);
    }
    final directRemoteStreamFuture = _directRemoteStreamFuture;
    _directRemoteStreamFuture = null;
    if (directRemoteStreamFuture != null) {
      try {
        await (await directRemoteStreamFuture).dispose();
      } catch (_) {}
    }
    await _stopCallForegroundService();
    await _cleanupCallAudioSession();
    hasRemoteStream.value = false;
    isLocalPreviewReady.value = false;
    videoTileOrder.clear();
    enlargedVideoTileId.value = '';
    if (_renderersInitialized) {
      try {
        localRenderer.srcObject = null;
      } catch (_) {}
      try {
        remoteRenderer.srcObject = null;
      } catch (_) {}
      try {
        await localRenderer.dispose();
      } catch (_) {}
      try {
        await remoteRenderer.dispose();
      } catch (_) {}
      _renderersInitialized = false;
    }
  }

  Future<void> _disposeMediaStream(MediaStream stream) async {
    for (final track in stream.getTracks()) {
      try {
        await track.stop();
      } catch (_) {}
    }
    try {
      await stream.dispose();
    } catch (_) {}
  }

  void _logWebRtc(String message) {
    unawaited(CallTraceLogger.log('CALL WEBRTC', message));
  }

  Future<void> _closePublisher() async {
    final socket = _publishSocket;
    _publishSocket = null;
    try {
      await socket?.close();
    } catch (_) {}
    final peer = _publishPeer;
    _publishPeer = null;
    _detachPeerDiagnostics(peer);
    try {
      await peer?.close();
    } catch (_) {}
    try {
      await peer?.dispose();
    } catch (_) {}
  }

  Future<void> _closePlayback() async {
    final remotePlaybacks = List<_RemoteWebRtcPlayback>.from(
      _remotePlaybacks.values,
    );
    _remotePlaybacks.clear();
    _remotePlaybackConnectionsInFlight.clear();
    remoteParticipants.clear();
    _syncVideoTileOrder();
    for (final playback in remotePlaybacks) {
      _detachPeerDiagnostics(playback.peer);
      await playback.dispose();
    }

    final socket = _playbackSocket;
    _playbackSocket = null;
    try {
      await socket?.close();
    } catch (_) {}
    final peer = _playbackPeer;
    _playbackPeer = null;
    _detachPeerDiagnostics(peer);
    try {
      await peer?.close();
    } catch (_) {}
    try {
      await peer?.dispose();
    } catch (_) {}
    remoteRenderer.srcObject = null;
    final syntheticStreamFuture = _playbackSyntheticStreamFuture;
    _playbackSyntheticStreamFuture = null;
    if (syntheticStreamFuture != null) {
      try {
        await (await syntheticStreamFuture).dispose();
      } catch (_) {}
    }
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
    final callId = _activeCallId;
    if (callId == null || callId == 0) {
      return;
    }
    _incomingDecisionTimer = Timer(incomingCallDecisionTimeout, () {
      if (isClosed || !isAwaitingIncomingDecision.value) {
        return;
      }
      unawaited(_markIncomingCallMissed(callId));
    });
  }

  Future<void> _markIncomingCallMissed(int callId) async {
    try {
      await _chatService.declineCall(
        callId: callId,
        reason: 'receiver_timeout',
      );
    } catch (_) {}
    await _stopAllCallAudio();
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
    }
  }

  void _startCallDurationTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final connectedAt = _connectedAt;
      if (connectedAt == null) {
        callDurationText.value = '00:00';
        return;
      }
      final elapsed = DateTime.now().difference(connectedAt);
      final minutes = elapsed.inMinutes
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final seconds = elapsed.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final hours = elapsed.inHours;
      callDurationText.value = hours > 0
          ? '${hours.toString().padLeft(2, '0')}:$minutes:$seconds'
          : '$minutes:$seconds';
    });
  }

  void _stopCallDurationTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = null;
  }

  Future<void> _startIncomingRingtone() async {
    await _stopAllCallAudio();
    if (_shouldAbortAsyncWork) return;
    final player = AudioPlayer();
    _incomingRingtonePlayer = player;
    try {
      await player.setAsset('assets/audio/incoming_call_ringtone.mp3');
      if (_shouldAbortAsyncWork || _incomingRingtonePlayer != player) {
        if (_incomingRingtonePlayer == player) {
          _incomingRingtonePlayer = null;
        }
        await player.dispose();
        return;
      }
      await player.setLoopMode(LoopMode.one);
      await player.play();
    } catch (_) {
      if (_incomingRingtonePlayer == player) {
        _incomingRingtonePlayer = null;
      }
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  Future<void> _startOutgoingRingback() async {
    await _stopAllCallAudio();
    if (_shouldAbortAsyncWork) return;
    final player = AudioPlayer();
    _outgoingRingbackPlayer = player;
    try {
      await player.setAsset('assets/audio/outgoing_call_ringback.wav');
      if (_shouldAbortAsyncWork || _outgoingRingbackPlayer != player) {
        if (_outgoingRingbackPlayer == player) {
          _outgoingRingbackPlayer = null;
        }
        await player.dispose();
        return;
      }
      await player.setLoopMode(LoopMode.one);
      await player.play();
    } catch (_) {
      if (_outgoingRingbackPlayer == player) {
        _outgoingRingbackPlayer = null;
      }
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  Future<void> _stopAllCallAudio() async {
    final players = [_incomingRingtonePlayer, _outgoingRingbackPlayer];
    _incomingRingtonePlayer = null;
    _outgoingRingbackPlayer = null;
    for (final player in players) {
      if (player == null) continue;
      try {
        await player.stop();
      } catch (_) {}
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  Future<void> _silenceIncomingCallRinging(int callId) async {
    await _stopAllCallAudio();
    try {
      await CallNotificationService.silenceIncomingCallRinging(callId);
    } catch (_) {}
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

  int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _PeerDiagnostics {
  final ready = Completer<void>();
  RTCPeerConnectionState? connectionState;
  RTCIceConnectionState? iceConnectionState;
  RTCIceGatheringState? iceGatheringState;
  int localCandidateCount = 0;
  final pendingLocalCandidates = <Map<String, dynamic>>[];
  WebSocket? trickleSocket;
  dynamic tricklePeerId;
  dynamic trickleOfferId;
  bool answerSent = false;
  bool hasConnectedOnce = false;
  int trickledCandidateCount = 0;
  bool disposed = false;
  bool recoveryInFlight = false;
  int iceRestartAttempts = 0;
  DateTime? lastIceRestartAt;
  Timer? recoveryTimer;
}

enum WebRtcVideoTileKind { local, remote, legacyRemote }

class WebRtcVideoTile {
  const WebRtcVideoTile.local()
    : id = WebRtcCallController.localVideoTileId,
      kind = WebRtcVideoTileKind.local,
      participant = null;

  const WebRtcVideoTile.legacyRemote()
    : id = WebRtcCallController.legacyRemoteVideoTileId,
      kind = WebRtcVideoTileKind.legacyRemote,
      participant = null;

  WebRtcVideoTile.remote(WebRtcRemoteParticipant this.participant)
    : id = WebRtcCallController._remoteVideoTileId(participant.userId),
      kind = WebRtcVideoTileKind.remote;

  final String id;
  final WebRtcVideoTileKind kind;
  final WebRtcRemoteParticipant? participant;

  bool get isLocal => kind == WebRtcVideoTileKind.local;
  bool get isRemote => kind == WebRtcVideoTileKind.remote;
  bool get isLegacyRemote => kind == WebRtcVideoTileKind.legacyRemote;
}

class WebRtcRemoteParticipant {
  WebRtcRemoteParticipant({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.renderer,
  });

  final int userId;
  final String displayName;
  final String avatarUrl;
  final RTCVideoRenderer renderer;
  final hasStream = false.obs;
}

class _RemoteWebRtcPlayback {
  _RemoteWebRtcPlayback({required this.participant, required this.renderer});

  final WebRtcRemoteParticipant participant;
  final RTCVideoRenderer renderer;
  RTCPeerConnection? peer;
  WebSocket? socket;
  Future<MediaStream>? syntheticStreamFuture;

  RxBool get hasStream => participant.hasStream;

  Future<void> dispose() async {
    try {
      await socket?.close();
    } catch (_) {}
    socket = null;
    final currentPeer = peer;
    peer = null;
    try {
      await currentPeer?.close();
    } catch (_) {}
    try {
      await currentPeer?.dispose();
    } catch (_) {}
    renderer.srcObject = null;
    final pendingSyntheticStream = syntheticStreamFuture;
    syntheticStreamFuture = null;
    if (pendingSyntheticStream != null) {
      try {
        await (await pendingSyntheticStream).dispose();
      } catch (_) {}
    }
    try {
      await renderer.dispose();
    } catch (_) {}
  }
}

class _OutboundMediaSnapshot {
  const _OutboundMediaSnapshot({
    this.kind = '',
    this.bytesSent = 0,
    this.framesEncoded = 0,
  });

  final String kind;
  final int bytesSent;
  final int framesEncoded;

  bool get hasMedia => bytesSent > 800 || framesEncoded > 0;

  int get score => bytesSent + (framesEncoded * 10000);
}

class _QualityCounters {
  const _QualityCounters({
    required this.packetsReceived,
    required this.packetsLost,
  });

  final int packetsReceived;
  final int packetsLost;
}

class _PeerQualitySnapshot {
  const _PeerQualitySnapshot({
    required this.hasInboundAudio,
    required this.packetsReceived,
    required this.packetsLost,
    required this.concealedSamples,
    required this.concealmentPercent,
    required this.jitterMs,
    required this.jitterBufferMs,
    required this.rttMs,
    required this.localCandidateType,
    required this.remoteCandidateType,
    required this.protocol,
    required this.networkType,
  });

  final bool hasInboundAudio;
  final int packetsReceived;
  final int packetsLost;
  final int concealedSamples;
  final double concealmentPercent;
  final double jitterMs;
  final double jitterBufferMs;
  final double rttMs;
  final String localCandidateType;
  final String remoteCandidateType;
  final String protocol;
  final String networkType;
}
