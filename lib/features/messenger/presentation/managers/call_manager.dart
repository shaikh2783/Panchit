import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/messenger/data/models/call_model.dart';
import 'package:snginepro/features/messenger/data/services/calls_api_service.dart';


class CallManager extends ChangeNotifier {
  final CallsApiService _callsApiService;
  
  RtcEngine? _agoraEngine;
  Timer? _pollTimer;
  CallModel? _currentCall;
  bool _isInitialized = false;
  final Set<int> _shownCallIds = {}; // Track shown calls

  CallManager(this._callsApiService);

  CallModel? get currentCall => _currentCall;
  bool get isInitialized => _isInitialized;
  bool get isInCall => _currentCall != null;
  RtcEngine? get agoraEngine => _agoraEngine;
  CallsApiService get callsApiService => _callsApiService;

  /// Initialize Agora engine
  Future<void> initializeAgora(String appId) async {
    if (_isInitialized) return;

    try {
      _agoraEngine = createAgoraRtcEngine();
      await _agoraEngine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Request camera and microphone permissions
  Future<bool> requestPermissions({required bool isVideoCall}) async {
    try {
      final permissions = <Permission>[Permission.microphone];
      if (isVideoCall) {
        permissions.add(Permission.camera);
      }

      final statuses = await permissions.request();
      
      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      return allGranted;
    } catch (e) {
      return false;
    }
  }

  /// Start a new call
  Future<Map<String, dynamic>> startCall({
    required int toUserId,
    required String callType, // 'audio' or 'video'
  }) async {
    try {
      // Request permissions
      final hasPermissions = await requestPermissions(
        isVideoCall: callType == 'video',
      );
      
      if (!hasPermissions) {
        throw Exception('required_permissions_not_granted'.tr);
      }

      // Start call via API
      final callData = await _callsApiService.startCall(
        toUserId: toUserId,
        callType: callType,
      );


      // Create call model
      _currentCall = CallModel(
        callId: callData['call_id'] ?? 0,
        callType: callData['call_type'] ?? callType,
        callStatus: callData['call_status'] ?? 'pending',
        answered: false,
        declined: false,
        toUserId: callData['to_user']?['user_id'] ?? toUserId,
        fromUserId: 0, // Current user
        fromUserName: '',
        room: callData['room'] ?? '',
        createdTime: DateTime.now(),
        provider: callData['provider'] ?? 'agora',
        providerData: callData['provider_data'] != null
            ? AgoraProviderData.fromJson(callData['provider_data'])
            : null,
      );


      // Join Agora channel as host
      await _joinAgoraChannel(
        providerData: _currentCall!.providerData!,
        isHost: true,
        isVideoCall: callType == 'video',
      );

      notifyListeners();
      return callData;
    } catch (e) {
      rethrow;
    }
  }

  /// Answer an incoming call
  Future<Map<String, dynamic>> answerCall(CallModel incomingCall) async {
    try {
      // Request permissions
      final hasPermissions = await requestPermissions(
        isVideoCall: incomingCall.callType == 'video',
      );
      
      if (!hasPermissions) {
        throw Exception('required_permissions_not_granted'.tr);
      }

      // Answer call via API
      final callData = await _callsApiService.answerCall(
        callId: incomingCall.callId,
      );

      
      // Use provider_data from response if available, otherwise from incomingCall
      AgoraProviderData? providerData;
      if (callData['provider_data'] != null) {
        providerData = AgoraProviderData.fromJson(callData['provider_data']);
      } else if (incomingCall.providerData != null) {
        providerData = incomingCall.providerData;
      } else {
        throw Exception('no_provider_data_available'.tr);
      }

      // Update current call
      _currentCall = incomingCall.copyWith(
        callStatus: 'active',
        answered: true,
        providerData: providerData,
      );

      // Join Agora channel as broadcaster (both users are broadcasters in 1-1 call)
      await _joinAgoraChannel(
        providerData: _currentCall!.providerData!,
        isHost: true, // Both should be broadcasters in 1-1 call
        isVideoCall: incomingCall.callType == 'video',
      );

      notifyListeners();
      return callData;
    } catch (e) {
      rethrow;
    }
  }

  /// Decline an incoming call
  Future<void> declineCall(int callId) async {
    try {
      await _callsApiService.declineCall(callId: callId);
      
      if (_currentCall?.callId == callId) {
        _currentCall = null;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// End current call
  Future<void> endCall() async {
    if (_currentCall == null) return;

    try {
      await _callsApiService.endCall(callId: _currentCall!.callId);
      await _leaveAgoraChannel();
      
      _currentCall = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel outgoing call
  Future<void> cancelCall() async {
    if (_currentCall == null) return;

    try {
      await _callsApiService.cancelCall(callId: _currentCall!.callId);
      await _leaveAgoraChannel();
      
      _currentCall = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Join Agora channel
  Future<void> _joinAgoraChannel({
    required AgoraProviderData providerData,
    required bool isHost,
    required bool isVideoCall,
  }) async {
    try {
      // Validate provider data
      if (providerData.appId.isEmpty) {
        throw Exception('app_id_empty'.tr);
      }
      if (providerData.channelName.isEmpty) {
        throw Exception('channel_name_empty'.tr);
      }
      if (providerData.token.isEmpty) {
        throw Exception('token_empty'.tr);
      }
      if (providerData.uid == 0) {
        throw Exception('uid_zero'.tr);
      }

      // Always leave any existing channel first to avoid -17 error
      if (_agoraEngine != null) {
        try {
          await _agoraEngine!.leaveChannel();
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
        }
      }

      // Initialize or re-initialize Agora if needed
      if (_agoraEngine == null || !_isInitialized) {
        await initializeAgora(providerData.appId);
        // Wait for engine to be fully ready
        await Future.delayed(const Duration(milliseconds: 800));
      }

      if (_agoraEngine == null) {
        throw Exception('agora_engine_null'.tr);
      }

      
      // Enable audio first
      await _agoraEngine!.enableAudio();

      // Enable video if video call (before joining)
      if (isVideoCall) {
        await _agoraEngine!.enableVideo();
      }

      // Wait to ensure audio/video are ready
      await Future.delayed(const Duration(milliseconds: 300));

      // Join channel with proper role
      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        autoSubscribeAudio: true,
        autoSubscribeVideo: isVideoCall,
        publishCameraTrack: isVideoCall,
        publishMicrophoneTrack: true,
      );

      
      await _agoraEngine!.joinChannel(
        token: providerData.token,
        channelId: providerData.channelName,
        uid: providerData.uid,
        options: options,
      );


      // Configure audio settings AFTER joining (Android requirement)
      try {
        await Future.delayed(const Duration(milliseconds: 300));
        await _agoraEngine!.setEnableSpeakerphone(true);
        await _agoraEngine!.setDefaultAudioRouteToSpeakerphone(true);
        await _agoraEngine!.adjustRecordingSignalVolume(100);
        await _agoraEngine!.adjustPlaybackSignalVolume(100);
      } catch (e) {
        // Don't rethrow - audio might still work with default settings
      }

      // Start video preview if video call (after joining)
      if (isVideoCall) {
        try {
          await _agoraEngine!.startPreview();
        } catch (e) {
        }
      }
    } catch (e) {
      if (e.toString().contains('-3')) {
      } else if (e.toString().contains('-2')) {
      } else if (e.toString().contains('-17')) {
      }
      rethrow;
    }
  }

  /// Leave Agora channel
  Future<void> _leaveAgoraChannel() async {
    if (_agoraEngine == null) return;

    try {
      
      // Stop preview first
      try {
        await _agoraEngine!.stopPreview();
      } catch (e) {
      }
      
      // Leave channel
      await _agoraEngine!.leaveChannel();
      
      // Wait a bit to ensure cleanup
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
    }
  }

  /// Toggle microphone
  Future<void> toggleMicrophone(bool muted) async {
    await _agoraEngine?.muteLocalAudioStream(muted);
  }

  /// Toggle camera
  Future<void> toggleCamera(bool off) async {
    await _agoraEngine?.muteLocalVideoStream(off);
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    await _agoraEngine?.switchCamera();
  }

  /// Register event handlers
  void registerEventHandlers({
    Function(RtcConnection connection, int elapsed)? onJoinChannelSuccess,
    Function(RtcConnection connection, int remoteUid, int elapsed)? onUserJoined,
    Function(RtcConnection connection, int remoteUid, UserOfflineReasonType reason)? onUserOffline,
    Function(ErrorCodeType err, String msg)? onError,
  }) {
    _agoraEngine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: onJoinChannelSuccess,
        onUserJoined: onUserJoined,
        onUserOffline: onUserOffline,
        onError: onError,
      ),
    );
  }

  /// Start polling for incoming calls
  void startPollingForCalls({
    required Function(CallModel) onIncomingCall,
    Duration interval = const Duration(seconds: 3),
  }) {
    _pollTimer?.cancel();
    
    _pollTimer = Timer.periodic(interval, (timer) async {
      try {
        final calls = await _callsApiService.getIncomingCalls();
        
        if (calls.isNotEmpty) {
          for (var call in calls) {
          }
        }
        
        for (final call in calls) {
          // Only show if pending and not already shown
          if (call.callStatus == 'pending' && 
              !call.answered && 
              !call.declined &&
              !_shownCallIds.contains(call.callId)) {
            _shownCallIds.add(call.callId);
            onIncomingCall(call);
          }
        }
        
        // Clean up old shown calls (keep only pending ones)
        final oldShownCount = _shownCallIds.length;
        _shownCallIds.removeWhere((id) => 
          !calls.any((call) => call.callId == id && call.callStatus == 'pending')
        );
        if (oldShownCount != _shownCallIds.length) {
        }
      } catch (e) {
      }
    });
  }

  /// Stop polling for incoming calls
  void stopPollingForCalls() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    
    // Leave channel and cleanup
    if (_agoraEngine != null) {
      _leaveAgoraChannel().then((_) {
        _agoraEngine?.release();
      }).catchError((e) {
      });
    }
    
    super.dispose();
  }
}
