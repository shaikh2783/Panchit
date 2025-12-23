import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../application/agora_service.dart';

class LiveStreamControls extends StatelessWidget {
  const LiveStreamControls({
    super.key,
    required this.agoraService,
    required this.broadcasterName,
    required this.onLeave,
  });

  final AgoraService agoraService;
  final String broadcasterName;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // معلومات المذيع
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.user,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        broadcasterName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // عدد المشاهدين
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.eye,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${agoraService.remoteUsersCount + 1}', // +1 للمذيع
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // أدوات التحكم
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // كتم الصوت
                _ControlButton(
                  icon: agoraService.isMuted ? Iconsax.volume_slash : Iconsax.volume_high,
                  label: agoraService.isMuted ? 'إلغاء الكتم' : 'كتم',
                  isActive: !agoraService.isMuted,
                  onTap: agoraService.toggleMute,
                ),
                
                // السماعة
                _ControlButton(
                  icon: agoraService.isSpeakerEnabled ? Iconsax.volume_high : Iconsax.headphone,
                  label: agoraService.isSpeakerEnabled ? 'سماعة' : 'سماعة أذن',
                  isActive: agoraService.isSpeakerEnabled,
                  onTap: agoraService.toggleSpeaker,
                ),
                
                // مغادرة البث
                _ControlButton(
                  icon: Iconsax.logout,
                  label: 'مغادرة',
                  isActive: true,
                  isDestructive: true,
                  onTap: onLeave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = true,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDestructive
        ? Colors.red.withOpacity(0.8)
        : isActive
            ? Colors.white.withOpacity(0.2)
            : Colors.black.withOpacity(0.5);
    
    final foregroundColor = isActive ? Colors.white : Colors.white60;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: foregroundColor,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}