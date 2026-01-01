import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get/get.dart';
import '../../data/models/call_model.dart';
import '../managers/call_manager.dart';

class ActiveCallScreen extends StatefulWidget {
  final CallModel callData;
  final CallManager callManager;

  const ActiveCallScreen({
    Key? key,
    required this.callData,
    required this.callManager,
  }) : super(key: key);

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  int? _remoteUid;
  Timer? _durationTimer;
  Timer? _statusCheckTimer;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeCallScreen();
    _startDurationTimer();
    _startStatusMonitoring();
  }

  void _initializeCallScreen() {
    widget.callManager.registerEventHandlers(
      onJoinChannelSuccess: (connection, elapsed) {
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        setState(() {
          _remoteUid = remoteUid;
        });
        
        // Stop status monitoring when remote user joins - call is now active
        if (_statusCheckTimer != null && _statusCheckTimer!.isActive) {
          _statusCheckTimer!.cancel();
        }
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (_remoteUid == remoteUid) {
          setState(() {
            _remoteUid = null;
          });
          _endCall();
        }
      },
      onError: (err, msg) {
      },
    );
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration += const Duration(seconds: 1);
      });
    });
  }

  void _startStatusMonitoring() {
    // Wait 5 seconds before starting monitoring to allow call to be fully created
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      
      // Check call status every 3 seconds
      _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        try {
          // Get updated call status from API
          final currentCall = await widget.callManager.callsApiService.getCallStatus(
            callId: widget.callData.callId,
          );

          if (currentCall == null) {
            // Call not found in backend, but check if remote user is still connected
            if (_remoteUid != null) {
              return; // Don't close if remote user is still in the call
            }
            
            // No remote user and call not found - end the call
            timer.cancel();
            _handleCallEnded('call_user_busy'.tr);
            return;
          }


          // Only close if explicitly declined, cancelled, or ended (NOT if still pending/active)
          if (currentCall.declined) {
            timer.cancel();
            _handleCallEnded('call_user_busy'.tr);
            return;
          }

          if (currentCall.callStatus == 'cancelled') {
            timer.cancel();
            _handleCallEnded('call_user_busy'.tr);
            return;
          }

          if (currentCall.callStatus == 'ended') {
            timer.cancel();
            _handleCallEnded('call_ended'.tr);
            return;
          }

          // Don't close if status is 'pending' or 'active' - these are normal states
        } catch (e) {
          // Don't close on error, just log it
        }
      });
    });
  }

  void _handleCallEnded(String message) {
    if (!mounted) return;

    // Show message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );

    // Close screen after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Future<void> _toggleMicrophone() async {
    setState(() => _isMuted = !_isMuted);
    await widget.callManager.toggleMicrophone(_isMuted);
  }

  Future<void> _toggleCamera() async {
    if (widget.callData.callType != 'video') return;
    
    setState(() => _isCameraOff = !_isCameraOff);
    await widget.callManager.toggleCamera(_isCameraOff);
  }

  Future<void> _switchCamera() async {
    if (widget.callData.callType != 'video') return;
    await widget.callManager.switchCamera();
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    await widget.callManager.agoraEngine?.setEnableSpeakerphone(_isSpeakerOn);
  }

  Future<void> _endCall() async {
    try {
      await widget.callManager.endCall();
      
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideoCall = widget.callData.callType == 'video';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video views (for video calls)
            if (isVideoCall) ...[
              // Remote video (full screen)
              if (_remoteUid != null)
                AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: widget.callManager.agoraEngine!,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(
                      channelId: widget.callData.providerData!.channelName,
                    ),
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:  [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        'waiting_for_participant'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

              // Local video (small window)
              if (!_isCameraOff)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: widget.callManager.agoraEngine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      ),
                    ),
                  ),
                ),
            ] else ...[
              // Audio call UI
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[800],
                      child: Icon(
                        Icons.person,
                        size: 70,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      widget.callData.fromUserName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Top info bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isVideoCall ? 'video_call'.tr : 'audio_call'.tr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute button
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'unmute'.tr : 'mute'.tr,
                      isActive: _isMuted,
                      onPressed: _toggleMicrophone,
                    ),

                    // Speaker button (audio only)
                    if (!isVideoCall)
                      _buildControlButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                        label: 'speaker'.tr,
                        isActive: _isSpeakerOn,
                        onPressed: _toggleSpeaker,
                      ),

                    // Camera toggle (video only)
                    if (isVideoCall)
                      _buildControlButton(
                        icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                        label: _isCameraOff ? 'turn_on_camera'.tr : 'turn_off_camera'.tr,
                        isActive: _isCameraOff,
                        onPressed: _toggleCamera,
                      ),

                    // Switch camera (video only)
                    if (isVideoCall)
                      _buildControlButton(
                        icon: Icons.switch_camera,
                        label: 'switch_camera'.tr,
                        onPressed: _switchCamera,
                      ),

                    // End call button
                    _buildEndCallButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: isActive ? Colors.red : Colors.grey[800],
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.all(15),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.red,
            elevation: 0,
            onPressed: _endCall,
            child: const Icon(
              Icons.call_end,
              size: 35,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'end_call'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
