import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/agora_config.dart';

/// خدمة إدارة البث المباشر باستخدام Agora
class AgoraService extends ChangeNotifier {
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isCameraEnabled = true;
  bool _isSpeakerEnabled = true;
  String? _currentChannel;
  int? _currentUid;
  
  // إحصائيات البث
  final Map<int, bool> _remoteUsers = {};
  RtcStats? _rtcStats;
  
  // Getters
  RtcEngine? get engine => _engine;
  bool get isInitialized => _isInitialized;
  bool get isJoined => _isJoined;
  bool get isMuted => _isMuted;
  bool get isCameraEnabled => _isCameraEnabled;
  bool get isSpeakerEnabled => _isSpeakerEnabled;
  String? get currentChannel => _currentChannel;
  int? get currentUid => _currentUid;
  Map<int, bool> get remoteUsers => Map.unmodifiable(_remoteUsers);
  RtcStats? get rtcStats => _rtcStats;
  bool get hasRemoteUsers => _remoteUsers.isNotEmpty;
  int get remoteUsersCount => _remoteUsers.length;

  /// تهيئة محرك Agora
  Future<bool> initialize() async {
    try {
      if (!AgoraConfig.isConfigured) {

        return false;
      }

      // طلب الصلاحيات مع معالجة محسنة

      final permissionsGranted = await _requestPermissionsImproved();
      
      if (!permissionsGranted) {

        return false;
      }

      // إنشاء محرك Agora
      _engine = createAgoraRtcEngine();
      
      // تهيئة المحرك
      await _engine!.initialize(
        RtcEngineContext(
          appId: AgoraConfig.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // تكوين إعدادات الفيديو
      await _setupVideoConfig();
      
      // تكوين إعدادات الصوت
      await _setupAudioConfig();
      
      // إعداد Event Handlers
      _setupEventHandlers();
      
      _isInitialized = true;
      notifyListeners();

      return true;
      
    } catch (e) {

      return false;
    }
  }

  /// طلب الصلاحيات المطلوبة بطريقة محسنة
  Future<bool> _requestPermissionsImproved() async {
    try {

      // التحقق من حالة الصلاحيات الحالية أولاً
      final cameraCurrentStatus = await Permission.camera.status;
      final micCurrentStatus = await Permission.microphone.status;

      // إذا كانت الصلاحيات ممنوحة مسبقاً، لا نحتاج لطلبها مجدداً
      if (cameraCurrentStatus.isGranted && micCurrentStatus.isGranted) {

        return true;
      }
      
      // طلب صلاحية الكاميرا إذا لم تكن ممنوحة
      if (!cameraCurrentStatus.isGranted) {

        final cameraStatus = await Permission.camera.request();

        if (!cameraStatus.isGranted) {

          if (cameraStatus.isPermanentlyDenied) {

          }
          return false;
        }
      }
      
      // طلب صلاحية المايكروفون إذا لم تكن ممنوحة
      if (!micCurrentStatus.isGranted) {

        final micStatus = await Permission.microphone.request();

        if (!micStatus.isGranted) {

          if (micStatus.isPermanentlyDenied) {

          }
          return false;
        }
      }

      return true;
      
    } catch (e) {

      return false;
    }
  }

  /// تكوين إعدادات الفيديو
  Future<void> _setupVideoConfig() async {
    await _engine!.setVideoEncoderConfiguration(
      VideoEncoderConfiguration(
        dimensions: VideoDimensions(
          width: AgoraConfig.videoWidth,
          height: AgoraConfig.videoHeight,
        ),
        frameRate: AgoraConfig.frameRate,
        bitrate: AgoraConfig.bitrate,
        orientationMode: OrientationMode.orientationModeAdaptive,
        mirrorMode: VideoMirrorModeType.videoMirrorModeAuto,
      ),
    );
    
    // تمكين الفيديو
    await _engine!.enableVideo();
  }

  /// تكوين إعدادات الصوت
  Future<void> _setupAudioConfig() async {
    await _engine!.enableAudio();
    await _engine!.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );
  }

  /// إعداد مستمعي الأحداث
  void _setupEventHandlers() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        // عند الانضمام للقناة بنجاح
        onJoinChannelSuccess: (connection, elapsed) {
          _isJoined = true;
          _currentChannel = connection.channelId;
          _currentUid = connection.localUid;
          notifyListeners();

        },

        // عند مغادرة القناة
        onLeaveChannel: (connection, stats) {
          _isJoined = false;
          _currentChannel = null;
          _currentUid = null;
          _remoteUsers.clear();
          notifyListeners();

        },

        // عند انضمام مستخدم آخر
        onUserJoined: (connection, remoteUid, elapsed) {
          _remoteUsers[remoteUid] = true;
          notifyListeners();

        },

        // عند مغادرة مستخدم آخر
        onUserOffline: (connection, remoteUid, reason) {
          _remoteUsers.remove(remoteUid);
          notifyListeners();

        },

        // عند تحديث إحصائيات الشبكة
        onRtcStats: (connection, stats) {
          _rtcStats = stats;
          notifyListeners();
        },

        // عند حدوث خطأ
        onError: (err, msg) {

        },
      ),
    );
  }

  /// الانضمام لقناة البث
  Future<bool> joinChannel({
    required String channelName,
    required String token,
    int uid = 0,
  }) async {
    if (!_isInitialized || _engine == null) {

      return false;
    }

    try {
      // الانضمام للقناة
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleAudience, // مشاهد فقط
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      return true;
      
    } catch (e) {

      return false;
    }
  }

  /// مغادرة القناة الحالية
  Future<void> leaveChannel() async {
    if (_engine != null && _isJoined) {
      await _engine!.leaveChannel();

    }
  }

  /// تشغيل/إيقاف الصوت المحلي
  Future<void> toggleMute() async {
    if (_engine == null) return;
    
    _isMuted = !_isMuted;
    await _engine!.muteLocalAudioStream(_isMuted);
    notifyListeners();

  }

  /// تشغيل/إيقاف الكاميرا المحلية
  Future<void> toggleCamera() async {
    if (_engine == null) return;
    
    _isCameraEnabled = !_isCameraEnabled;
    await _engine!.muteLocalVideoStream(!_isCameraEnabled);
    notifyListeners();

  }

  /// تشغيل/إيقاف السماعة
  Future<void> toggleSpeaker() async {
    if (_engine == null) return;
    
    _isSpeakerEnabled = !_isSpeakerEnabled;
    await _engine!.setEnableSpeakerphone(_isSpeakerEnabled);
    notifyListeners();

  }

  /// تبديل الكاميرا (أمامية/خلفية)
  Future<void> switchCamera() async {
    if (_engine == null) return;
    
    await _engine!.switchCamera();

  }

  /// الحصول على معرف المستخدم المحلي
  int getLocalUid() {
    return _currentUid ?? 0;
  }

  /// التحقق من وجود مستخدم عن بُعد
  bool hasRemoteUser(int uid) {
    return _remoteUsers.containsKey(uid);
  }

  /// تنظيف الموارد
  Future<void> dispose() async {
    if (_isJoined) {
      await leaveChannel();
    }
    
    if (_engine != null) {
      await _engine!.release();
      _engine = null;
    }
    
    _isInitialized = false;
    _isJoined = false;
    _remoteUsers.clear();
    
    super.dispose();

  }
}