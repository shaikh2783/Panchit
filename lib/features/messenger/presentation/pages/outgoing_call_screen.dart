import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/call_model.dart';
import '../../data/models/conversation_model.dart';
import '../managers/call_manager.dart';
import 'active_call_screen.dart';

class OutgoingCallScreen extends StatefulWidget {
  final CallModel callData;
  final CallManager callManager;
  final UserPreview otherUser;

  const OutgoingCallScreen({
    Key? key,
    required this.callData,
    required this.callManager,
    required this.otherUser,
  }) : super(key: key);

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _statusCheckTimer;
  bool _hasJoined = false;
  int _notFoundCount = 0; // Count consecutive times call was not found

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Setup Agora event handlers
    _setupAgoraHandlers();
    
    // Start monitoring call status
    _startStatusMonitoring();
  }

  void _setupAgoraHandlers() {
    widget.callManager.registerEventHandlers(
      onJoinChannelSuccess: (connection, elapsed) {
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        if (!_hasJoined && mounted) {
          _hasJoined = true;
          _navigateToActiveCall();
        }
      },
      onUserOffline: (connection, remoteUid, reason) {
      },
      onError: (err, msg) {
      },
    );
  }

  void _startStatusMonitoring() {
    // Wait 3 seconds before starting monitoring
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        try {
          final currentCall = await widget.callManager.callsApiService.getCallStatus(
            callId: widget.callData.callId,
          );

          if (currentCall == null) {
            // Call not found - but give it some time (maybe backend delay)
            _notFoundCount++;
            
            // Only end call if not found 3 consecutive times (6 seconds of not finding it)
            if (_notFoundCount >= 3) {
              timer.cancel();
              _handleCallEnded('المستخدم مشغول', isBusy: true);
            }
            return;
          }

          // Reset counter if call was found
          _notFoundCount = 0;


          // Check if declined
          if (currentCall.declined || currentCall.callStatus == 'declined') {
            timer.cancel();
            _handleCallEnded('المستخدم مشغول', isBusy: true);
            return;
          }

          // Check if cancelled
          if (currentCall.callStatus == 'cancelled') {
            timer.cancel();
            _handleCallEnded('تم إلغاء المكالمة');
            return;
          }

          // Check if ended
          if (currentCall.callStatus == 'ended') {
            timer.cancel();
            _handleCallEnded('المستخدم مشغول', isBusy: true);
            return;
          }

          // Check if answered (status becomes 'active')
          if (currentCall.callStatus == 'active' && currentCall.answered) {
            timer.cancel();
            if (!_hasJoined && mounted) {
              _hasJoined = true;
              _navigateToActiveCall();
            }
            return;
          }
        } catch (e) {
        }
      });
    });
  }

  void _navigateToActiveCall() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ActiveCallScreen(
          callData: widget.callData,
          callManager: widget.callManager,
        ),
      ),
    );
  }

  void _handleCallEnded(String message, {bool isBusy = false}) {
    if (!mounted) return;

    Get.back();

    Future.delayed(const Duration(milliseconds: 300), () {
      Get.snackbar(
        isBusy ? 'user_busy'.tr : 'call_ended'.tr,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: isBusy ? Colors.orange : Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: Icon(
          isBusy ? Icons.phone_disabled : Icons.call_end,
          color: Colors.white,
        ),
      );
    });
  }

  Future<void> _cancelCall() async {
    try {
      await widget.callManager.cancelCall();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  String _buildImageUrl(String? picture) {
    if (picture == null || picture.isEmpty) {
      return 'https://sngine.fluttercrafters.com/content/themes/default/images/blank_profile_male.png';
    }
    if (picture.startsWith('http')) return picture;
    if (picture.startsWith('content/')) {
      return 'https://sngine.fluttercrafters.com/$picture';
    }
    return 'https://sngine.fluttercrafters.com/content/uploads/$picture';
  }

  @override
  Widget build(BuildContext context) {
    final isVideoCall = widget.callData.callType == 'video';

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _cancelCall,
                  ),
                  const Spacer(),
                  Text(
                    isVideoCall ? 'video_call'.tr : 'audio_call'.tr,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(),

            // User avatar with pulse animation
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 160 + (_pulseController.value * 20),
                  height: 160 + (_pulseController.value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3 * _pulseController.value),
                        blurRadius: 40,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.otherUser.avatarFull ?? widget.otherUser.avatar ?? _buildImageUrl(null),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // User name
            Text(
              widget.otherUser.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Status text with animated dots
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final dots = '.' * ((_pulseController.value * 3).round() + 1);
                return Text(
                  '${'calling'.tr}$dots',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 18,
                  ),
                );
              },
            ),

            const Spacer(),

            // Cancel button
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      backgroundColor: Colors.red,
                      elevation: 0,
                      onPressed: _cancelCall,
                      child: const Icon(
                        Icons.call_end,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'cancel'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
