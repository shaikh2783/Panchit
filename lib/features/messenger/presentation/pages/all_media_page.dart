import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/messenger/data/models/message_model.dart';
import 'package:snginepro/features/messenger/data/services/messenger_api_service.dart';
import 'package:audioplayers/audioplayers.dart';

/// صفحة عرض جميع الوسائط (الصور والصوتيات) من كل المحادثات
class AllMediaPage extends StatefulWidget {
  final String currentUserId;
  final String? conversationId; // إذا تم تمريرها، نجلب وسائط محادثة محددة

  const AllMediaPage({
    required this.currentUserId,
    this.conversationId,
    super.key,
  });

  @override
  State<AllMediaPage> createState() => _AllMediaPageState();
}

class _AllMediaPageState extends State<AllMediaPage>
    with SingleTickerProviderStateMixin {
  late MessengerApiService _messengerService;
  late TabController _tabController;
  bool _loadingMedia = true;
  bool _hasMore = false;
  int _offset = 0;
  static const int _pageSize = 30;
  late final bool _isConversationScoped;

  final List<MessageModel> _imageMessages = [];
  final List<MessageModel> _voiceMessages = [];

  @override
  void initState() {
    super.initState();
    _messengerService = MessengerApiService(context.read<ApiClient>());
    _tabController = TabController(length: 2, vsync: this);
    _isConversationScoped = (widget.conversationId != null && widget.conversationId!.isNotEmpty);
    _loadMedia(reset: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia({bool reset = false}) async {
    if (reset) {
      _offset = 0;
      _imageMessages.clear();
      _voiceMessages.clear();
    }
    setState(() => _loadingMedia = true);

    try {
      final resp = _isConversationScoped
          ? await _messengerService.getConversationMedia(
              conversationId: widget.conversationId!,
              offset: _offset,
              limit: _pageSize,
              currentUserId: widget.currentUserId,
            )
          : await _messengerService.getAllMedia(
              offset: _offset,
              limit: _pageSize,
              currentUserId: widget.currentUserId,
            );
      final items = (resp['items'] as List<MessageModel>? ?? []);
      final hasMore = resp['has_more'] == true || items.length >= _pageSize;

      for (final m in items) {
        if (m.image != null && m.image!.isNotEmpty) {
          _imageMessages.add(m);
        }
        if (m.voiceNote != null && m.voiceNote!.isNotEmpty) {
          _voiceMessages.add(m);
        }
      }

      setState(() {
        _hasMore = hasMore;
        _loadingMedia = false;
      });
    } catch (e) {
      setState(() => _loadingMedia = false);
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMedia) return;
    _offset++;
    await _loadMedia();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              stretch: true,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              title: Text(_isConversationScoped ? 'shared_media_conversation'.tr : 'shared_media'.tr),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                stretchModes: const [
                  StretchMode.fadeTitle,
                  StretchMode.blurBackground,
                  StretchMode.zoomBackground,
                ],
                background: _buildHeroSection(theme, isDark),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(72),
                child: _buildTabBarContainer(theme, isDark),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildImagesTab(),
              _buildVoiceTab(),
            ],
          ),
        ),
        floatingActionButton: _hasMore ? _buildLoadMoreButton(theme) : null,
      ),
    );
  }

  Widget _buildLoadMoreButton(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: _loadMore,
      backgroundColor: theme.colorScheme.primary,
      icon: const Icon(Icons.expand_more),
      label: Text('show_more'.tr),
    );
  }

  Widget _buildHeroSection(ThemeData theme, bool isDark) {
    final gradient = LinearGradient(
      colors: isDark
          ? [const Color(0xFF1F1B2C), theme.colorScheme.primary]
          : [theme.colorScheme.primary, theme.colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: 20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: 20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 50, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.perm_media, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                  'shared_media'.tr.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.4,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.photo_library_outlined,
            label: 'shared_images'.tr,
            count: _imageMessages.length,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.graphic_eq,
            label: 'shared_voice_notes'.tr,
            count: _voiceMessages.length,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 10),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarContainer(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor:
            theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        indicator: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        indicatorPadding: EdgeInsets.zero,
        tabs: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Tab(text: 'shared_images'.tr, icon: const Icon(Icons.photo_outlined, size: 20)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Tab(text: 'shared_voice_notes'.tr, icon: const Icon(Icons.mic_none, size: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesTab() {
    if (_loadingMedia && _imageMessages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_imageMessages.isEmpty) {
      return _buildEmptyState(Icons.photo_library_outlined, 'no_media_found'.tr);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _imageMessages.length,
      itemBuilder: (context, index) {
        final msg = _imageMessages[index];
        return GestureDetector(
          onTap: () => _showImageFullscreen(msg.image!),
          child: Hero(
            tag: 'media_${msg.messageId}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: msg.image!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceTab() {
    if (_loadingMedia && _voiceMessages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_voiceMessages.isEmpty) {
      return _buildEmptyState(Icons.mic_none, 'no_media_found'.tr);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _voiceMessages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final msg = _voiceMessages[index];
        return _VoiceMediaItem(
          url: msg.voiceNote!,
          sentAt: msg.sentAt,
          senderName: '${msg.firstName} ${msg.lastName}'.trim(),
          senderAvatar: msg.avatar,
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showImageFullscreen(String imageUrl) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error, color: Colors.white),
            ),
          ),
        ),
      ),
      fullscreenDialog: true,
    );
  }
}

class _VoiceMediaItem extends StatefulWidget {
  final String url;
  final DateTime sentAt;
  final String senderName;
  final String? senderAvatar;

  const _VoiceMediaItem({
    required this.url,
    required this.sentAt,
    required this.senderName,
    this.senderAvatar,
  });

  @override
  State<_VoiceMediaItem> createState() => _VoiceMediaItemState();
}

class _VoiceMediaItemState extends State<_VoiceMediaItem> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerComplete.listen((_) => setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        }));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      try {
        await _audioPlayer.play(UrlSource(widget.url));
        setState(() => _isPlaying = true);
      } catch (e) {
        Get.snackbar('error'.tr, 'failed_to_play_audio'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: widget.senderAvatar != null
                    ? CachedNetworkImageProvider(widget.senderAvatar!)
                    : null,
                child: widget.senderAvatar == null
                    ? Text(
                        widget.senderName.isNotEmpty
                            ? widget.senderName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 14),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.senderName.isNotEmpty
                          ? widget.senderName
                          : 'unknown'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.sentAt.day}/${widget.sentAt.month}/${widget.sentAt.year} - ${widget.sentAt.hour.toString().padLeft(2, '0')}:${widget.sentAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: theme.colorScheme.primary,
                        inactiveTrackColor: isDark ? Colors.grey[700] : Colors.grey[300],
                        thumbColor: theme.colorScheme.primary,
                      ),
                      child: Slider(
                        value: _duration.inMilliseconds > 0
                            ? _position.inMilliseconds.toDouble()
                            : 0,
                        max: _duration.inMilliseconds > 0
                            ? _duration.inMilliseconds.toDouble()
                            : 1,
                        onChanged: (v) async {
                          await _audioPlayer.seek(Duration(milliseconds: v.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
