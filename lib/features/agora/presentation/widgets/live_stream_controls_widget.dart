import 'package:flutter/material.dart';

class LiveStreamControlsWidget extends StatelessWidget {
  final bool isStreaming;
  final bool isCameraEnabled;
  final bool isMicrophoneEnabled;
  final bool isFrontCamera;
  final int viewersCount; // عدد المشاهدين
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleMicrophone;
  final VoidCallback onSwitchCamera;
  final VoidCallback onEndStream;

  const LiveStreamControlsWidget({
    Key? key,
    required this.isStreaming,
    required this.isCameraEnabled,
    required this.isMicrophoneEnabled,
    required this.isFrontCamera,
    this.viewersCount = 0, // افتراضياً 0
    required this.onToggleCamera,
    required this.onToggleMicrophone,
    required this.onSwitchCamera,
    required this.onEndStream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [            
            // أزرار التحكم في الأسفل
            SafeArea(
              top: false,
              child: RepaintBoundary(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Camera toggle
                    _buildControlButton(
                      icon: isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                      label: isCameraEnabled ? 'إيقاف الكاميرا' : 'تشغيل الكاميرا',
                      isActive: isCameraEnabled,
                      onPressed: onToggleCamera,
                    ),

                    // Microphone toggle
                    _buildControlButton(
                      icon: isMicrophoneEnabled ? Icons.mic : Icons.mic_off,
                      label: isMicrophoneEnabled ? 'إيقاف المايك' : 'تشغيل المايك',
                      isActive: isMicrophoneEnabled,
                      onPressed: onToggleMicrophone,
                    ),

                    // Switch camera
                    _buildControlButton(
                      icon: Icons.flip_camera_ios,
                      label: 'تبديل الكاميرا',
                      onPressed: onSwitchCamera,
                    ),

                    // End stream (if streaming)
                    if (isStreaming)
                      _buildControlButton(
                        icon: Icons.stop,
                        label: 'إنهاء البث',
                        isDestructive: true,
                        onPressed: onEndStream,
                      ),
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
    required VoidCallback onPressed,
    bool isActive = true,
    bool isDestructive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDestructive 
                ? Colors.red
                : isActive 
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isDestructive 
                  ? Colors.white
                  : isActive 
                      ? Colors.black
                      : Colors.white,
            ),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
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
}