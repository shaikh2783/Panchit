import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:video_player/video_player.dart';

class CampaignCard extends StatefulWidget {
  const CampaignCard({
    super.key,
    required this.title,
    required this.budget,
    required this.spend,
    required this.views,
    required this.clicks,
    required this.active,
    this.imageUrl,
    this.videoUrl,
    this.bidding,
    this.status,
    this.createdAt,
    this.isApproved = false,
    this.onTap,
    this.onToggleActive,
  });

  final String title;
  final String budget;
  final String spend;
  final String views;
  final String clicks;
  final bool active;
  final String? imageUrl;
  final String? videoUrl;
  final String? bidding;
  final String? status;
  final String? createdAt;
  final bool isApproved;
  final VoidCallback? onTap;
  final VoidCallback? onToggleActive;

  @override
  State<CampaignCard> createState() => _CampaignCardState();
}

class _CampaignCardState extends State<CampaignCard> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(CampaignCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _initializeVideo();
    }
  }

  void _initializeVideo() {
    _videoController?.dispose();
    _videoController = null;

    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!))
        ..setLooping(true)
        ..setVolume(0)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController?.play();
          }
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              theme.cardColor.withOpacity(0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: widget.active
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.dividerColor.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Media Header with Overlay (Image or Video)
              if (widget.imageUrl != null || widget.videoUrl != null)
                Stack(
                  children: [
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: _buildMediaPreview(theme),
                    ),
                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Status Badge
                    if (widget.status != null && widget.status!.isNotEmpty)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _StatusBadge(
                          text: widget.status!,
                          isApproved: widget.isApproved,
                        ),
                      ),
                    // Active Indicator
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.active
                              ? Colors.green.withOpacity(0.9)
                              : Colors.grey.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (widget.active ? Colors.green : Colors.grey)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.active ? 'active'.tr : 'paused'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with Action Button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (widget.onToggleActive != null && widget.isApproved)
                          IconButton(
                            tooltip: widget.active
                                ? 'pause_campaign'.tr
                                : 'activate_campaign'.tr,
                            icon: Icon(
                              widget.active ? Iconsax.pause : Iconsax.play,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: widget.onToggleActive,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stats Grid
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  icon: Iconsax.wallet_money,
                                  label: 'budget'.tr,
                                  value: widget.budget,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: theme.dividerColor.withOpacity(0.3),
                              ),
                              Expanded(
                                child: _StatItem(
                                  icon: Iconsax.chart_21,
                                  label: 'spent'.tr,
                                  value: widget.spend,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(
                            color: theme.dividerColor.withOpacity(0.3),
                            height: 1,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  icon: Iconsax.eye,
                                  label: 'views'.tr,
                                  value: widget.views,
                                  color: Colors.blue,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: theme.dividerColor.withOpacity(0.3),
                              ),
                              Expanded(
                                child: _StatItem(
                                  icon: Iconsax.mouse_1,
                                  label: 'clicks'.tr,
                                  value: widget.clicks,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Bidding & Created
                    if (widget.bidding != null || widget.createdAt != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (widget.bidding != null && widget.bidding!.isNotEmpty)
                            _InfoChip(
                              icon: Iconsax.chart_1,
                              text: widget.bidding!,
                              color: Colors.purple,
                            ),
                          if (widget.createdAt != null && widget.createdAt!.isNotEmpty)
                            _InfoChip(
                              icon: Iconsax.clock,
                              text: widget.createdAt!,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildMediaPreview(ThemeData theme) {
    // Show video if available
    if (_videoController != null && _videoController!.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
          // Video icon indicator
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      );
    }

    // Show image if available
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.3),
                theme.colorScheme.secondary.withOpacity(0.3),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.primary,
            size: 32,
          ),
        ),
      );
    }

    // Fallback placeholder
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.3),
            theme.colorScheme.secondary.withOpacity(0.3),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: theme.colorScheme.primary,
        size: 32,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.isApproved,
  });

  final String text;
  final bool isApproved;

  @override
  Widget build(BuildContext context) {
    final color = isApproved ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved ? Iconsax.tick_circle : Iconsax.clock,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
