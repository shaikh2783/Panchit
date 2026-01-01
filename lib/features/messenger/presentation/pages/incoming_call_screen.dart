import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/call_model.dart';
import '../managers/call_manager.dart';
import 'active_call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final CallModel callData;
  final CallManager callManager;

  const IncomingCallScreen({
    Key? key,
    required this.callData,
    required this.callManager,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isAnswering = false;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _startStatusMonitoring();
  }

  void _startStatusMonitoring() {
    // Wait 3 seconds before starting monitoring
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      // Check if call was cancelled every 3 seconds
      _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        try {
          // Get updated call status from API
          final currentCall = await widget.callManager.callsApiService.getCallStatus(
            callId: widget.callData.callId,
          );

          if (currentCall == null) {
            // Call not found, might be cancelled
            timer.cancel();
            _handleCallCancelled('call_cancelled'.tr);
            return;
          }


          // Check if call was cancelled or ended
          if (currentCall.callStatus == 'cancelled' || currentCall.callStatus == 'ended') {
            timer.cancel();
            _handleCallCancelled('call_cancelled'.tr);
            return;
          }

          // Don't close if status is 'pending' - waiting for answer is normal
        } catch (e) {
          // Don't close on error, just log it
        }
      });
    });
  }

  void _handleCallCancelled(String message) {
    if (!mounted) return;

    // Show message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );

    // Close screen after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  String _buildImageUrl(String? picture) {
    if (picture == null || picture.isEmpty) {
      return 'https://sngine.fluttercrafters.com/content/themes/default/images/blank_profile_male.png';
    }
    
    if (picture.startsWith('http')) {
      return picture;
    }
    
    if (picture.startsWith('content/')) {
      return 'https://sngine.fluttercrafters.com/$picture';
    }
    
    return 'https://sngine.fluttercrafters.com/content/uploads/$picture';
  }

  Future<void> _answerCall() async {
    if (_isAnswering) return;
    
    setState(() => _isAnswering = true);

    try {
      await widget.callManager.answerCall(widget.callData);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveCallScreen(
            callData: widget.callManager.currentCall!,
            callManager: widget.callManager,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isAnswering = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('failed_to_answer_call_with_error'.trParams({'error': '$e'})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _declineCall() async {
    try {
      await widget.callManager.declineCall(widget.callData.callId);
      
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('failed_to_decline_call_with_error'.trParams({'error': '$e'})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.callData.callType == 'video';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  isVideo ? 'incoming_video_call'.tr : 'incoming_audio_call'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Caller Info
              Column(
                children: [
                  // Animated avatar
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20 + (20 * _animationController.value),
                              spreadRadius: 5 + (10 * _animationController.value),
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 67,
                        backgroundImage: NetworkImage(
                          _buildImageUrl(widget.callData.fromUserPicture),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Caller name
                  Text(
                    widget.callData.fromUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Call type indicator with animation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.5 + (0.5 * _animationController.value),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isVideo ? Icons.videocam : Icons.phone,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isVideo ? 'video_call_in_progress'.tr : 'audio_call_in_progress'.tr,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline Button
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: FloatingActionButton(
                            heroTag: 'decline',
                            backgroundColor: Colors.red,
                            elevation: 0,
                            onPressed: _isAnswering ? null : _declineCall,
                            child: const Icon(
                              Icons.call_end,
                              size: 35,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'decline'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    // Answer Button
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: FloatingActionButton(
                            heroTag: 'answer',
                            backgroundColor: Colors.green,
                            elevation: 0,
                            onPressed: _isAnswering ? null : _answerCall,
                            child: _isAnswering
                                ? const SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Icon(
                                    isVideo ? Icons.videocam : Icons.call,
                                    size: 35,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'answer'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
