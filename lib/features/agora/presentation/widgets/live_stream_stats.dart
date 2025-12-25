import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../application/agora_service.dart';

class LiveStreamStats extends StatelessWidget {
  const LiveStreamStats({
    super.key,
    required this.agoraService,
  });

  final AgoraService agoraService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // حالة الاتصال
        _StatCard(
          icon: agoraService.isJoined ? Iconsax.tick_circle : Iconsax.close_circle,
          color: agoraService.isJoined ? Colors.green : Colors.red,
          tooltip: agoraService.isJoined ? 'متصل' : 'غير متصل',
        ),
        
        const SizedBox(height: 8),
        
        // جودة الشبكة
        if (agoraService.rtcStats != null)
          _StatCard(
            icon: _getNetworkQualityIcon(agoraService.rtcStats!),
            color: _getNetworkQualityColor(agoraService.rtcStats!),
            tooltip: 'جودة الشبكة',
            text: '${agoraService.rtcStats!.lastmileDelay}ms',
          ),
      ],
    );
  }

  IconData _getNetworkQualityIcon(rtcStats) {
    // تحديد أيقونة جودة الشبكة بناءً على زمن الاستجابة
    final delay = rtcStats.lastmileDelay ?? 0;
    if (delay < 50) return Iconsax.wifi; // ممتاز
    if (delay < 100) return Iconsax.wifi; // جيد
    if (delay < 200) return Iconsax.wifi; // متوسط
    return Iconsax.close_circle; // ضعيف
  }

  Color _getNetworkQualityColor(rtcStats) {
    // تحديد لون جودة الشبكة بناءً على زمن الاستجابة
    final delay = rtcStats.lastmileDelay ?? 0;
    if (delay < 50) return Colors.green; // ممتاز
    if (delay < 100) return Colors.lime; // جيد
    if (delay < 200) return Colors.orange; // متوسط
    return Colors.red; // ضعيف
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.text,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            if (text != null) ...[
              const SizedBox(height: 2),
              Text(
                text!,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}