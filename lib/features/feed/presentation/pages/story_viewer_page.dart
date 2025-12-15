import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/services/video_precache_service.dart';
import 'package:snginepro/features/feed/data/models/story.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
class StoryViewerPage extends StatefulWidget {
  const StoryViewerPage({
    super.key,
    required this.stories,
    required this.initialStoryIndex,
  });
  final List<Story> stories;
  final int initialStoryIndex;
  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}
class _StoryViewerPageState extends State<StoryViewerPage> {
  late final PageController _pageController;
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialStoryIndex);
    // Pre-cache الفيديوهات في الستوريز
    _precacheVideoStories();
  }
  /// Pre-cache جميع فيديوهات الستوريز
  void _precacheVideoStories() {
    try {
      final mediaAsset = context.read<AppConfig>().mediaAsset;
      final precacheService = VideoPrecacheService();
      for (final story in widget.stories) {
        for (final item in story.items) {
          if (item.type == 'video') {
            final url = mediaAsset(item.source).toString();
            precacheService.precacheVideo(url);
          }
        }
      }
    } catch (e) {
      // تجاهل الأخطاء
    }
  }
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.stories.length,
        itemBuilder: (context, index) {
          final story = widget.stories[index];
          return StoryView(story: story, onComplete: () {
            if (_pageController.page!.toInt() < widget.stories.length - 1) {
              _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
            } else {
              Navigator.of(context).pop();
            }
          });
        },
      ),
    );
  }
}
class StoryView extends StatefulWidget {
  const StoryView({super.key, required this.story, required this.onComplete});
  final Story story;
  final VoidCallback onComplete;
  @override
  State<StoryView> createState() => _StoryViewState();
}
class _StoryViewState extends State<StoryView> with TickerProviderStateMixin {
  late final PageController _pageController;
  CachedVideoPlayerPlus? _videoController;
  AnimationController? _animationController;
  int _currentItemIndex = 0;
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.story.items.isNotEmpty) {
      _playStoryItem(0);
    }
  }
  Future<void> _playStoryItem(int index) async {
    // إيقاف الأنيميشن
    _animationController?.stop();
    _animationController?.dispose();
    _animationController = null;
    // التخلص من الفيديو بشكل آمن
    if (_videoController != null) {
      try {
        await _videoController!.controller.pause();
        await _videoController!.controller.dispose();
        _videoController = null;
      } catch (e) {
        // تجاهل أخطاء التخلص من المحتوى
        _videoController = null;
      }
    }
    if (!mounted) return;
    final item = widget.story.items[index];
    if (item.type == 'video') {
      final mediaAsset = context.read<AppConfig>().mediaAsset;
      _videoController = CachedVideoPlayerPlus.networkUrl(
        mediaAsset(item.source),
        invalidateCacheIfOlderThan: const Duration(days: 7),
      );
      try {
        await _videoController!.initialize();
        if (!mounted) return;
        // انتظار حتى يكون الفيديو جاهز للتشغيل
        final controller = _videoController!.controller;
        // التأكد من أن الفيديو محمل بالكامل
        if (!controller.value.isInitialized) {
          // استخدام مدة افتراضية إذا فشل التحميل
          _startAnimation(const Duration(seconds: 10));
        } else {
          final videoDuration = controller.value.duration;
          // التأكد من أن المدة صحيحة
          if (videoDuration.inSeconds > 0) {
            _startAnimation(videoDuration);
          } else {
            // مدة افتراضية إذا كانت المدة = 0
            _startAnimation(const Duration(seconds: 10));
          }
        }
        if (mounted) {
          setState(() {});
        }
        // تشغيل الفيديو
        if (mounted && controller.value.isInitialized) {
          await controller.play();
        }
      } catch (e) {
        // في حالة الخطأ، استخدم مدة افتراضية وانتقل للتالي
        _startAnimation(const Duration(seconds: 10));
        setState(() {});
      }
    } else {
      _startAnimation(const Duration(seconds: 5));
    }
    setState(() {
      _currentItemIndex = index;
    });
  }
  void _startAnimation(Duration duration) {
    _animationController = AnimationController(vsync: this, duration: duration);
    _animationController!.forward();
    _animationController!.addListener(() {
        setState(() {});
    });
    _animationController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
            _nextItem();
        }
    });
  }
  void _nextItem() {
    if (_currentItemIndex < widget.story.items.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      widget.onComplete();
    }
  }
  void _previousItem() {
    if (_currentItemIndex > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
    }
  }
  void _pause() {
    if (!mounted) return;
    _animationController?.stop();
    if (_videoController?.controller.value.isInitialized ?? false) {
      _videoController?.controller.pause();
    }
  }
  void _resume() {
    if (!mounted) return;
    _animationController?.forward();
    if (_videoController?.controller.value.isInitialized ?? false) {
      _videoController?.controller.play();
    }
  }
  @override
  void dispose() {
    _pageController.dispose();
    _animationController?.dispose();
    // التخلص من الفيديو بشكل آمن
    if (_videoController != null) {
      try {
        _videoController!.controller.dispose();
      } catch (e) {
        // تجاهل أخطاء التخلص
      }
    }
    super.dispose();
  }
  void _onPageChanged(int index) {
    _playStoryItem(index);
  }
  @override
  Widget build(BuildContext context) {
    final mediaAsset = context.read<AppConfig>().mediaAsset;
    if (widget.story.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, color: Colors.white.withOpacity(0.5), size: 80),
            const SizedBox(height: 16),
            Text(
              'No content in this story',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTapUp: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dx = details.globalPosition.dx;
        if (dx < screenWidth * 0.3) {
          _previousItem();
        } else if (dx > screenWidth * 0.7) {
          _nextItem();
        }
      },
      onLongPressStart: (_) => _pause(),
      onLongPressEnd: (_) => _resume(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // المحتوى الرئيسي
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.story.items.length,
              physics: const NeverScrollableScrollPhysics(), // منع السحب اليدوي
              itemBuilder: (context, index) {
                final item = widget.story.items[index];
                if (item.type == 'video' &&
                    _videoController != null &&
                    _videoController!.controller.value.isInitialized) {
                  return Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.controller.value.aspectRatio,
                      child: VideoPlayer(_videoController!.controller),
                    ),
                  );
                } else {
                  // التحقق من وجود الصورة
                  if (item.source.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.broken_image_outlined, 
                              color: Colors.white.withOpacity(0.6), 
                              size: 60,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No image available',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return CachedNetworkImage(
                    imageUrl: mediaAsset(item.source).toString(),
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.error_outline, 
                                color: Colors.white.withOpacity(0.6), 
                                size: 60,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to skip',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
            // Gradient overlay للقراءة الأفضل
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Progress bars والمعلومات العلوية
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Progress bars
                      Row(
                        children: List.generate(widget.story.items.length, (index) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: (_currentItemIndex > index)
                                      ? 1.0
                                      : (_currentItemIndex == index
                                          ? (_animationController?.value ?? 0.0)
                                          : 0.0),
                                  backgroundColor: Colors.white.withOpacity(0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  minHeight: 3,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      // معلومات المستخدم
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: widget.story.authorAvatarUrl != null
                                  ? CachedNetworkImageProvider(
                                      mediaAsset(widget.story.authorAvatarUrl!).toString(),
                                    )
                                  : null,
                              child: widget.story.authorAvatarUrl == null
                                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.story.authorName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // زر الإغلاق
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close, color: Colors.white, size: 24),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Link text في الأسفل
            if (widget.story.items[_currentItemIndex].linkText.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(30),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.link,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      widget.story.items[_currentItemIndex].linkText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
