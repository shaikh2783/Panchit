import '../../../../../settings.dart';

enum AgoraCallType { voice, video }

class AgoraCallService {
  const AgoraCallService();

  bool get isAgoraProvider => isAgoraCallProvider;

  bool get isWebRtcProvider => isWebRtcCallProvider;

  bool get isEnabled => callsEnabled && (isWebRtcProvider || agoraEnabled);

  bool get isAudioEnabled => isEnabled && audioCallsEnabled;

  bool get isVideoEnabled => isEnabled && videoCallsEnabled;

  String get appId => agoraAppId.trim();

  String get token => agoraToken.trim();

  bool get isConfigured => isEnabled && appId.isNotEmpty;

  String buildChannelName({
    required int conversationId,
    required AgoraCallType type,
  }) {
    final mode = type == AgoraCallType.video ? 'video' : 'voice';
    return '$agoraChannelPrefix$mode-$conversationId';
  }
}
