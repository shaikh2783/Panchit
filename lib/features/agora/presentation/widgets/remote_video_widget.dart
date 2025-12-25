import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../application/agora_service.dart';

class RemoteVideoWidget extends StatefulWidget {
  const RemoteVideoWidget({
    super.key,
    required this.uid,
    required this.channelName,
    required this.agoraService, // إضافة AgoraService كمعامل
  });

  final int uid;
  final String channelName;
  final AgoraService agoraService; // معامل مباشر

  @override
  State<RemoteVideoWidget> createState() => _RemoteVideoWidgetState();
}

class _RemoteVideoWidgetState extends State<RemoteVideoWidget> {
  late AgoraService _agoraService;

  @override
  void initState() {
    super.initState();
    _agoraService = widget.agoraService; // استخدام المعامل المُمرر
  }

  @override
  Widget build(BuildContext context) {
    // التحقق من وجود محرك Agora
    if (_agoraService.engine == null) {
      return _buildNoEngineWidget();
    }

    // عرض فيديو المستخدم البعيد باستخدام AgoraVideoView
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _agoraService.engine!,
          canvas: VideoCanvas(
            uid: widget.uid,
            renderMode: RenderModeType.renderModeHidden,
            mirrorMode: VideoMirrorModeType.videoMirrorModeAuto,
          ),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      ),
    );
  }

  Widget _buildNoEngineWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );
  }
}