import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../../../core/utils/timeline_launcher.dart';
import '../../../../core/utils/video_cache_warmer.dart';
import '../../../../core/widgets/messenger_ui.dart';
import '../../../chat/data/models/chat_reaction_types_response.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../data/models/story_group_model.dart';
import '../../data/models/story_media_model.dart';
import '../../data/models/story_reactions_response_model.dart';
import '../../data/models/story_viewers_response_model.dart';
import '../../data/services/stories_service.dart';

class StoryViewerPage extends StatefulWidget {
  const StoryViewerPage({
    super.key,
    required this.story,
    this.stories = const [],
    this.initialGroupIndex = 0,
    this.initialItemIndex = 0,
  });

  final StoryGroupModel story;
  final List<StoryGroupModel> stories;
  final int initialGroupIndex;
  final int initialItemIndex;

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _progressController;
  late final TextEditingController _replyController;
  late final FocusNode _replyFocusNode;

  VideoPlayerController? _videoController;
  VideoPlayerController? _prefetchedVideoController;
  Timer? _videoPollingTimer;
  late final List<StoryGroupModel> _stories;
  late final int _currentUserId;
  late int _currentGroupIndex;
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _isPreparingVideo = false;
  bool _didCompleteCurrentVideo = false;
  bool _isLoadingReactions = false;
  bool _isSendingReply = false;
  bool _isSendingReaction = false;
  String? _prefetchedVideoItemId;
  List<ChatReactionTypeModel> _availableReactions =
      const <ChatReactionTypeModel>[];
  final Map<int, String> _selectedStoryReactions = <int, String>{};
  final Set<int> _markedViewedStoryMediaIds = <int>{};
  final Map<int, int> _storyViewsCount = <int, int>{};
  final Map<int, bool> _storyCurrentUserViewed = <int, bool>{};

  bool get _hasCurrentItem =>
      _stories.isNotEmpty &&
      _currentGroupIndex >= 0 &&
      _currentGroupIndex < _stories.length &&
      _stories[_currentGroupIndex].items.isNotEmpty &&
      _currentIndex >= 0 &&
      _currentIndex < _stories[_currentGroupIndex].items.length;

  StoryGroupModel get _currentStory => _stories[_currentGroupIndex];
  StoryMediaModel get _currentItem => _currentStory.items[_currentIndex];

  bool _isCurrentItem(StoryMediaModel item) =>
      _hasCurrentItem && identical(_currentItem, item);

  ChatReactionTypeModel? get _currentReaction {
    final key =
        _selectedStoryReactions[_currentItem.storyMediaId] ??
        _currentItem.currentUserReaction;
    if (key.isEmpty) {
      return null;
    }
    for (final reaction in _availableReactions) {
      if (reaction.key.toLowerCase() == key.toLowerCase()) {
        return reaction;
      }
    }
    return null;
  }

  bool get _isOwnStory {
    final ownerId = _currentItem.ownerUserId > 0
        ? _currentItem.ownerUserId
        : _currentStory.ownerUserId;
    return ownerId > 0 && ownerId == _currentUserId;
  }

  int get _currentViewsCount =>
      _storyViewsCount[_currentItem.storyMediaId] ?? _currentItem.viewsCount;

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController()..addListener(_onReplyChanged);
    _replyFocusNode = FocusNode()
      ..addListener(() {
        if (_replyFocusNode.hasFocus) {
          _pauseStory();
        } else {
          _resumeStory();
        }
        if (mounted) {
          setState(() {});
        }
      });
    _currentUserId = Get.find<ChatAppPreferences>().getUserId() ?? 0;
    final sourceStories = widget.stories.isNotEmpty
        ? widget.stories
        : <StoryGroupModel>[widget.story];
    final requestedGroupIndex =
        widget.initialGroupIndex >= 0 &&
            widget.initialGroupIndex < sourceStories.length
        ? widget.initialGroupIndex
        : 0;
    final nonEmptyEntries = sourceStories.indexed
        .where((entry) => entry.$2.items.isNotEmpty)
        .toList(growable: false);
    _stories = nonEmptyEntries.map((entry) => entry.$2).toList(growable: false);
    if (nonEmptyEntries.isEmpty) {
      _currentGroupIndex = 0;
      _currentIndex = 0;
    } else {
      var selectedEntryIndex = nonEmptyEntries.indexWhere(
        (entry) => entry.$1 >= requestedGroupIndex,
      );
      if (selectedEntryIndex < 0) {
        selectedEntryIndex = nonEmptyEntries.length - 1;
      }
      _currentGroupIndex = selectedEntryIndex;
      final initialItems = _stories[_currentGroupIndex].items;
      _currentIndex =
          nonEmptyEntries[selectedEntryIndex].$1 == requestedGroupIndex &&
              widget.initialItemIndex >= 0 &&
              widget.initialItemIndex < initialItems.length
          ? widget.initialItemIndex
          : 0;
    }
    _pageController = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(vsync: this)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goNext();
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _hasCurrentItem) {
        unawaited(_activateCurrentItem());
      }
    });
    unawaited(_loadReactions());
  }

  @override
  void dispose() {
    _videoPollingTimer?.cancel();
    _progressController.dispose();
    _videoController?.dispose();
    _prefetchedVideoController?.dispose();
    _replyController
      ..removeListener(_onReplyChanged)
      ..dispose();
    _replyFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onReplyChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadReactions() async {
    setState(() {
      _isLoadingReactions = true;
    });
    try {
      final response = await Get.find<ChatService>().fetchReactionTypes();
      if (!mounted) {
        return;
      }
      setState(() {
        _availableReactions = response.types;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _availableReactions = const <ChatReactionTypeModel>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReactions = false;
        });
      }
    }
  }

  Future<void> _activateCurrentItem() async {
    if (!_hasCurrentItem) {
      return;
    }
    _videoPollingTimer?.cancel();
    _didCompleteCurrentVideo = false;
    _progressController.stop();
    _progressController.reset();

    final item = _currentItem;
    if (item.isVideo && item.url.trim().isNotEmpty) {
      await _prepareVideo(item);
      unawaited(_prefetchUpcomingVideo());
      unawaited(_markCurrentStoryViewed());
      return;
    }

    await _disposeVideoController();
    _startPhotoProgress(item);
    unawaited(_prefetchUpcomingVideo());
    unawaited(_markCurrentStoryViewed());
  }

  Future<void> _prepareVideo(StoryMediaModel item) async {
    final prefetchedController = _takePrefetchedVideoController(item.id);
    await _disposeVideoController();

    setState(() {
      _isPreparingVideo = true;
    });

    final controller =
        prefetchedController ??
        await VideoCacheWarmer.createImmediateController(item.url);
    _videoController = controller;

    try {
      if (!controller.value.isInitialized) {
        await controller.initialize();
      }
      await controller.setLooping(false);

      if (!mounted || !_isCurrentItem(item)) {
        await controller.dispose();
        return;
      }

      setState(() {
        _isPreparingVideo = false;
      });

      if (!_isPaused) {
        await controller.play();
      }

      _videoPollingTimer = Timer.periodic(const Duration(milliseconds: 120), (
        timer,
      ) {
        final activeController = _videoController;
        if (!mounted ||
            activeController == null ||
            !activeController.value.isInitialized) {
          return;
        }

        final position = activeController.value.position;
        final duration = activeController.value.duration;
        if (!_didCompleteCurrentVideo &&
            duration > Duration.zero &&
            position >= duration - const Duration(milliseconds: 160)) {
          _didCompleteCurrentVideo = true;
          timer.cancel();
          _goNext();
          return;
        }

        if (mounted) {
          setState(() {});
        }
      });

      unawaited(_prefetchUpcomingVideo());
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPreparingVideo = false;
      });
      _startPhotoProgress(item);
      unawaited(_prefetchUpcomingVideo());
    }
  }

  Future<void> _disposeVideoController() async {
    _videoPollingTimer?.cancel();
    _videoPollingTimer = null;
    final controller = _videoController;
    _videoController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  VideoPlayerController? _takePrefetchedVideoController(String itemId) {
    if (_prefetchedVideoItemId != itemId) {
      return null;
    }

    final controller = _prefetchedVideoController;
    _prefetchedVideoController = null;
    _prefetchedVideoItemId = null;
    return controller;
  }

  Future<void> _disposePrefetchedVideoController() async {
    final controller = _prefetchedVideoController;
    _prefetchedVideoController = null;
    _prefetchedVideoItemId = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _prefetchUpcomingVideo() async {
    final next = _nextStoryItem();
    if (next == null || !next.isVideo || next.url.trim().isEmpty) {
      await _disposePrefetchedVideoController();
      return;
    }

    if (_prefetchedVideoItemId == next.id &&
        _prefetchedVideoController?.value.isInitialized == true) {
      return;
    }

    await _disposePrefetchedVideoController();

    VideoPlayerController? controller;
    try {
      await VideoCacheWarmer.warm(next.url);
      controller = await VideoCacheWarmer.createImmediateController(next.url);
      await controller.initialize();
      await controller.setLooping(false);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _prefetchedVideoController = controller;
      _prefetchedVideoItemId = next.id;
    } catch (_) {
      await controller?.dispose();
    }
  }

  StoryMediaModel? _nextStoryItem() {
    if (!_hasCurrentItem) {
      return null;
    }
    if (_currentIndex < _currentStory.items.length - 1) {
      return _currentStory.items[_currentIndex + 1];
    }

    if (_currentGroupIndex < _stories.length - 1) {
      final nextStory = _stories[_currentGroupIndex + 1];
      if (nextStory.items.isNotEmpty) {
        return nextStory.items.first;
      }
    }

    return null;
  }

  void _startPhotoProgress(StoryMediaModel item) {
    final seconds = item.lengthSeconds > 0 ? item.lengthSeconds : 5;
    _progressController.duration = Duration(seconds: seconds);
    if (!_isPaused) {
      _progressController.forward(from: 0);
    }
  }

  Future<void> _goTo(int index) async {
    if (!_hasCurrentItem || index < 0 || index >= _currentStory.items.length) {
      return;
    }

    setState(() {
      _currentIndex = index;
      _isPreparingVideo = false;
    });

    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );

    await _activateCurrentItem();
  }

  Future<void> _goNext() async {
    if (!_hasCurrentItem) {
      return;
    }
    if (_currentIndex >= _currentStory.items.length - 1) {
      if (_currentGroupIndex >= _stories.length - 1) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      await _goToStoryGroup(_currentGroupIndex + 1);
      return;
    }

    await _goTo(_currentIndex + 1);
  }

  Future<void> _goPrevious() async {
    if (!_hasCurrentItem) {
      return;
    }
    if (_currentIndex <= 0) {
      if (_currentGroupIndex > 0) {
        await _goToStoryGroup(
          _currentGroupIndex - 1,
          itemIndex: _stories[_currentGroupIndex - 1].items.length - 1,
        );
        return;
      }

      _progressController.forward(from: 0);
      if (_videoController?.value.isInitialized == true && !_isPaused) {
        await _videoController?.seekTo(Duration.zero);
        await _videoController?.play();
      }
      return;
    }

    await _goTo(_currentIndex - 1);
  }

  Future<void> _goToStoryGroup(int groupIndex, {int itemIndex = 0}) async {
    if (groupIndex < 0 || groupIndex >= _stories.length) {
      return;
    }

    final nextStory = _stories[groupIndex];
    if (nextStory.items.isEmpty) {
      return;
    }

    final safeItemIndex = itemIndex < 0
        ? 0
        : (itemIndex >= nextStory.items.length
              ? nextStory.items.length - 1
              : itemIndex);

    setState(() {
      _currentGroupIndex = groupIndex;
      _currentIndex = safeItemIndex;
      _isPreparingVideo = false;
    });

    _pageController.jumpToPage(safeItemIndex);
    await _activateCurrentItem();
  }

  void _pauseStory() {
    if (_isPaused) {
      return;
    }

    _isPaused = true;
    _progressController.stop();
    _videoController?.pause();
  }

  void _resumeStory() {
    if (!_isPaused || !_hasCurrentItem) {
      return;
    }

    _isPaused = false;
    if (_currentItem.isVideo) {
      _videoController?.play();
    } else {
      _progressController.forward();
    }
  }

  double _segmentProgress(int index) {
    if (index < _currentIndex) {
      return 1;
    }

    if (index > _currentIndex) {
      return 0;
    }

    if (_currentItem.isVideo) {
      final controller = _videoController;
      if (controller == null || !controller.value.isInitialized) {
        return _isPreparingVideo ? 0 : _progressController.value;
      }

      final duration = controller.value.duration;
      if (duration <= Duration.zero) {
        return 0;
      }

      final progress =
          controller.value.position.inMilliseconds / duration.inMilliseconds;
      return progress.clamp(0, 1);
    }

    return _progressController.value;
  }

  Future<void> _showReactionPicker() async {
    if (_availableReactions.isEmpty || _isSendingReaction) {
      return;
    }
    _pauseStory();
    final selectedReaction = await showGeneralDialog<ChatReactionTypeModel>(
      context: context,
      barrierLabel: 'reaction_picker',
      barrierDismissible: true,
      barrierColor: MessengerDesign.ink.withValues(alpha: 0.14),
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
              ),
            ),
            PositionedDirectional(
              start: 18,
              bottom: 84,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: MessengerDesign.of(context).surface,
                    borderRadius: BorderRadius.circular(
                      MessengerDesign.sectionRadius,
                    ),
                    boxShadow: MessengerDesign.floatingShadow(
                      Theme.of(context).brightness,
                    ),
                  ),
                  child: _StoryReactionPickerBar(
                    reactions: _availableReactions,
                    onSelected: (reaction) =>
                        Navigator.of(context).pop(reaction),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
            child: child,
          ),
        );
      },
    );
    if (!_replyFocusNode.hasFocus) {
      _resumeStory();
    }
    if (selectedReaction == null) {
      return;
    }
    await _submitReaction(selectedReaction);
  }

  Future<void> _submitReaction(ChatReactionTypeModel reaction) async {
    if (!_hasCurrentItem) {
      return;
    }
    final item = _currentItem;
    final storyId = item.storyId;
    final storyMediaId = item.storyMediaId;
    if (storyId <= 0 || storyMediaId <= 0) {
      return;
    }
    final hadPreviousReaction = _selectedStoryReactions.containsKey(
      storyMediaId,
    );
    final previousReaction = _selectedStoryReactions[storyMediaId];
    setState(() {
      _isSendingReaction = true;
      _selectedStoryReactions[storyMediaId] = reaction.key;
    });
    try {
      await Get.find<StoriesService>().reactToStory(
        storyId: storyId,
        storyMediaId: storyMediaId,
        reactionKey: reaction.key,
      );
      if (!mounted) {
        return;
      }
      if (_isCurrentItem(item)) {
        Get.snackbar(
          AppTranslations.commonStory.tr,
          AppTranslations.storyReactionSent.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_selectedStoryReactions[storyMediaId] == reaction.key) {
          if (hadPreviousReaction && previousReaction != null) {
            _selectedStoryReactions[storyMediaId] = previousReaction;
          } else {
            _selectedStoryReactions.remove(storyMediaId);
          }
        }
      });
      if (_isCurrentItem(item)) {
        Get.snackbar(
          AppTranslations.commonStory.tr,
          AppTranslations.unableToReactToStory.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingReaction = false;
        });
      }
    }
  }

  Future<void> _sendReply() async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty || _isSendingReply || !_hasCurrentItem) {
      return;
    }
    final item = _currentItem;
    final storyId = item.storyId;
    final storyMediaId = item.storyMediaId;
    if (storyId <= 0) {
      return;
    }
    setState(() {
      _isSendingReply = true;
    });
    try {
      await Get.find<StoriesService>().replyToStory(
        storyId: storyId,
        storyMediaId: storyMediaId > 0 ? storyMediaId : null,
        message: reply,
      );
      if (_replyController.text.trim() == reply) {
        _replyController.clear();
      }
      _replyFocusNode.unfocus();
      if (!mounted) {
        return;
      }
      Get.snackbar(
        AppTranslations.replyToStory.tr,
        AppTranslations.storyReplySent.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      Get.snackbar(
        AppTranslations.replyToStory.tr,
        AppTranslations.unableToReplyToStory.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingReply = false;
        });
      }
    }
  }

  Future<void> _markCurrentStoryViewed() async {
    if (!_hasCurrentItem) {
      return;
    }
    final story = _currentStory;
    final item = _currentItem;
    final storyId = item.storyId;
    final storyMediaId = item.storyMediaId;
    final ownerId = item.ownerUserId > 0 ? item.ownerUserId : story.ownerUserId;
    final isOwnStory = ownerId > 0 && ownerId == _currentUserId;
    if (isOwnStory ||
        storyId <= 0 ||
        storyMediaId <= 0 ||
        _markedViewedStoryMediaIds.contains(storyMediaId) ||
        _storyCurrentUserViewed[storyMediaId] == true ||
        item.currentUserViewed) {
      return;
    }

    _markedViewedStoryMediaIds.add(storyMediaId);
    try {
      final result = await Get.find<StoriesService>().markStoryViewed(
        storyId: storyId,
        storyMediaId: storyMediaId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _storyViewsCount[storyMediaId] = result.viewsCount;
        _storyCurrentUserViewed[storyMediaId] = true;
      });
    } catch (_) {
      _markedViewedStoryMediaIds.remove(storyMediaId);
    }
  }

  Future<void> _showStoryViewers() async {
    if (!_hasCurrentItem || !_isOwnStory) {
      return;
    }
    final item = _currentItem;
    final storyId = item.storyId;
    final storyMediaId = item.storyMediaId;
    if (storyId <= 0 || storyMediaId <= 0) {
      return;
    }

    _pauseStory();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _StoryInsightsSheet(
          storyId: storyId,
          storyMediaId: storyMediaId,
        );
      },
    );
    if (!_replyFocusNode.hasFocus) {
      _resumeStory();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCurrentItem) {
      return Scaffold(
        backgroundColor: MessengerDesign.darkCanvas,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    AppTranslations.storiesLoadFailed.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: MessengerDesign.darkInk,
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 8,
                end: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: MessengerDesign.darkInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final itemCount = _currentStory.items.length;
    final videoController = _videoController;
    final theme = Theme.of(context);
    final darkPalette = MessengerPalette.dark;

    return Scaffold(
      backgroundColor: darkPalette.canvas,
      body: SafeArea(
        child: GestureDetector(
          onLongPressStart: (_) => _pauseStory(),
          onLongPressEnd: (_) => _resumeStory(),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final pageItem = _currentStory.items[index];
                  final imageUrl = pageItem.displayImageUrl;
                  final isCurrent = index == _currentIndex;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isCurrent &&
                          pageItem.isVideo &&
                          videoController != null &&
                          videoController.value.isInitialized)
                        FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: videoController.value.size.width,
                            height: videoController.value.size.height,
                            child: VideoPlayer(videoController),
                          ),
                        )
                      else if (imageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholderFadeInDuration: Duration.zero,
                          filterQuality: FilterQuality.medium,
                          memCacheWidth: MediaQuery.sizeOf(
                            context,
                          ).width.toInt(),
                          maxWidthDiskCache: MediaQuery.sizeOf(
                            context,
                          ).width.toInt(),
                          progressIndicatorBuilder: (_, _, _) =>
                              const SizedBox.shrink(),
                          errorWidget: (_, _, _) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: MessengerDesign.darkMuted,
                              size: 40,
                            ),
                          ),
                        )
                      else
                        ColoredBox(color: MessengerDesign.darkCanvas),
                      if (isCurrent && pageItem.isVideo && _isPreparingVideo)
                        const Center(child: CircularProgressIndicator()),
                      if (pageItem.isVideo &&
                          (!isCurrent ||
                              videoController == null ||
                              !videoController.value.isInitialized))
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: darkPalette.surface.withValues(
                                alpha: 0.90,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: MessengerDesign.canvas,
                              size: 39,
                            ),
                          ),
                        ),
                      if (pageItem.text.trim().isNotEmpty ||
                          pageItem.linkText.trim().isNotEmpty)
                        PositionedDirectional(
                          start: 16,
                          end: 16,
                          bottom: _isOwnStory ? 78 : 104,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: darkPalette.surface.withValues(
                                alpha: 0.92,
                              ),
                              borderRadius: BorderRadius.circular(
                                MessengerDesign.controlRadius,
                              ),
                            ),
                            child: Text(
                              pageItem.text.trim().isNotEmpty
                                  ? pageItem.text
                                  : pageItem.linkText,
                              textAlign: TextAlign.start,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: darkPalette.text,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              Positioned.fill(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _goPrevious,
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _goNext,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                top: 12,
                start: 12,
                end: 12,
                child: Column(
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: List.generate(itemCount, (index) {
                          return Expanded(
                            child: Container(
                              height: 3,
                              margin: EdgeInsets.only(
                                right: index == itemCount - 1 ? 0 : 5,
                              ),
                              decoration: BoxDecoration(
                                color: darkPalette.subtle.withValues(
                                  alpha: 0.55,
                                ),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _segmentProgress(index),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: MessengerDesign.canvas,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(99),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 4, 6),
                      decoration: BoxDecoration(
                        color: darkPalette.surface.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(
                          MessengerDesign.controlRadius,
                        ),
                      ),
                      child: Row(
                        children: [
                          MessengerAvatar(
                            name: _currentStory.name,
                            imageUrl: _currentStory.photo,
                            radius: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentStory.name.trim().isEmpty
                                      ? AppTranslations.commonStory.tr
                                      : _currentStory.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: darkPalette.text,
                                  ),
                                ),
                                if (_currentItem.timeAgo.trim().isNotEmpty)
                                  Text(
                                    _currentItem.timeAgo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: darkPalette.muted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: darkPalette.text,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isOwnStory)
                PositionedDirectional(
                  start: 12,
                  end: 12,
                  bottom: 12,
                  child: _StoryActionBar(
                    reactions: _availableReactions,
                    currentReaction: _currentReaction,
                    isLoadingReactions: _isLoadingReactions,
                    isSendingReaction: _isSendingReaction,
                    isSendingReply: _isSendingReply,
                    replyController: _replyController,
                    replyFocusNode: _replyFocusNode,
                    onReact: _submitReaction,
                    onPickReaction: _showReactionPicker,
                    onSendReply: _sendReply,
                  ),
                ),
              if (_isOwnStory)
                PositionedDirectional(
                  start: 16,
                  bottom: 16,
                  child: _OwnStoryInsightsBar(
                    viewsCount: _currentViewsCount,
                    onTap: _showStoryViewers,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerAvatar extends StatelessWidget {
  const _ViewerAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final trimmed = name.trim();
    final first = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
    return ColoredBox(
      color: palette.primarySoft,
      child: Center(
        child: Text(
          first.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: MessengerDesign.primary,
          ),
        ),
      ),
    );
  }
}

class _OwnStoryInsightsBar extends StatelessWidget {
  const _OwnStoryInsightsBar({required this.viewsCount, required this.onTap});

  final int viewsCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerPalette.dark;
    return Material(
      color: palette.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(MessengerDesign.controlRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MessengerDesign.controlRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MessengerDesign.controlRadius),
            border: Border.all(color: palette.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_outlined,
                color: MessengerDesign.darkInk,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '$viewsCount ${AppTranslations.storyViews.tr}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryActionBar extends StatelessWidget {
  const _StoryActionBar({
    required this.reactions,
    required this.currentReaction,
    required this.isLoadingReactions,
    required this.isSendingReaction,
    required this.isSendingReply,
    required this.replyController,
    required this.replyFocusNode,
    required this.onReact,
    required this.onPickReaction,
    required this.onSendReply,
  });

  final List<ChatReactionTypeModel> reactions;
  final ChatReactionTypeModel? currentReaction;
  final bool isLoadingReactions;
  final bool isSendingReaction;
  final bool isSendingReply;
  final TextEditingController replyController;
  final FocusNode replyFocusNode;
  final ValueChanged<ChatReactionTypeModel> onReact;
  final VoidCallback onPickReaction;
  final VoidCallback onSendReply;

  @override
  Widget build(BuildContext context) {
    final canSendReply =
        replyController.text.trim().isNotEmpty && !isSendingReply;
    final visibleReactions = reactions.take(4).toList();
    final isTyping = replyFocusNode.hasFocus;
    final palette = MessengerPalette.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(MessengerDesign.sectionRadius),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          if (!isTyping) ...[
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: palette.softSurface,
                borderRadius: BorderRadius.circular(
                  MessengerDesign.compactRadius,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoadingReactions || isSendingReaction)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    ...visibleReactions.map((reaction) {
                      final isSelected =
                          currentReaction?.key.toLowerCase() ==
                          reaction.key.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          onTap: () => onReact(reaction),
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? palette.primarySoft
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: reaction.hasIconUrl
                                ? CachedNetworkImage(
                                    imageUrl: reaction.iconUrl,
                                    width: 22,
                                    height: 22,
                                    errorWidget: (_, _, _) =>
                                        _ReactionFallback(reaction: reaction),
                                  )
                                : _ReactionFallback(reaction: reaction),
                          ),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: onPickReaction,
                      onLongPress: onPickReaction,
                      child: Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsetsDirectional.only(start: 4),
                        decoration: BoxDecoration(
                          color: MessengerDesign.darkDivider,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: MessengerDesign.darkInk,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: palette.field,
                borderRadius: BorderRadius.circular(
                  MessengerDesign.compactRadius,
                ),
                border: Border.all(color: palette.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyController,
                      focusNode: replyFocusNode,
                      textInputAction: TextInputAction.send,
                      style: TextStyle(
                        color: MessengerDesign.darkInk,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration().copyWith(
                        hintText: AppTranslations.replyToStory.tr,
                        hintStyle: TextStyle(color: MessengerDesign.darkMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => onSendReply(),
                    ),
                  ),
                  IconButton(
                    onPressed: canSendReply ? onSendReply : null,
                    icon: isSendingReply
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    color: MessengerDesign.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryReactionPickerBar extends StatefulWidget {
  const _StoryReactionPickerBar({
    required this.reactions,
    required this.onSelected,
  });

  final List<ChatReactionTypeModel> reactions;
  final ValueChanged<ChatReactionTypeModel> onSelected;

  @override
  State<_StoryReactionPickerBar> createState() =>
      _StoryReactionPickerBarState();
}

class _StoryReactionPickerBarState extends State<_StoryReactionPickerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.reactions.length, (index) {
        final reaction = widget.reactions[index];
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: _controller,
            curve: Interval(
              index / (widget.reactions.length * 1.3),
              1,
              curve: Curves.elasticOut,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => widget.onSelected(reaction),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: reaction.hasIconUrl
                    ? CachedNetworkImage(
                        imageUrl: reaction.iconUrl,
                        width: 34,
                        height: 34,
                        errorWidget: (_, _, _) =>
                            _ReactionFallback(reaction: reaction),
                      )
                    : _ReactionFallback(reaction: reaction),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ReactionFallback extends StatelessWidget {
  const _ReactionFallback({required this.reaction});

  final ChatReactionTypeModel reaction;

  @override
  Widget build(BuildContext context) {
    final fallback = reaction.emoji.trim().isNotEmpty
        ? reaction.emoji.trim()
        : _emojiForReaction(reaction.key);
    return Text(fallback, style: const TextStyle(fontSize: 28));
  }

  String _emojiForReaction(String key) {
    switch (key.toLowerCase()) {
      case 'love':
        return '❤️';
      case 'haha':
        return '😂';
      case 'yay':
        return '🥳';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😡';
      default:
        return '👍';
    }
  }
}

class _StoryInsightsSheet extends StatefulWidget {
  const _StoryInsightsSheet({
    required this.storyId,
    required this.storyMediaId,
  });

  final int storyId;
  final int storyMediaId;

  @override
  State<_StoryInsightsSheet> createState() => _StoryInsightsSheetState();
}

class _StoryInsightsSheetState extends State<_StoryInsightsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<StoryViewersResponseModel> _viewersFuture;
  late Future<StoryReactionsResponseModel> _reactionsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewersFuture = Get.find<StoriesService>().fetchStoryViewers(
      storyId: widget.storyId,
      storyMediaId: widget.storyMediaId,
    );
    _reactionsFuture = Get.find<StoriesService>().fetchStoryReactions(
      storyId: widget.storyId,
      storyMediaId: widget.storyMediaId,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reloadViewers() async {
    setState(() {
      _viewersFuture = Get.find<StoriesService>().fetchStoryViewers(
        storyId: widget.storyId,
        storyMediaId: widget.storyMediaId,
      );
    });
    await _viewersFuture;
  }

  Future<void> _reloadReactions() async {
    setState(() {
      _reactionsFuture = Get.find<StoriesService>().fetchStoryReactions(
        storyId: widget.storyId,
        storyMediaId: widget.storyMediaId,
      );
    });
    await _reactionsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = MessengerDesign.of(context);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.62,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: palette.divider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppTranslations.storyViews.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: palette.softSurface,
                  borderRadius: BorderRadius.circular(
                    MessengerDesign.controlRadius,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: MessengerDesign.primary,
                    borderRadius: BorderRadius.circular(
                      MessengerDesign.compactRadius,
                    ),
                  ),
                  labelColor: MessengerDesign.canvas,
                  unselectedLabelColor: palette.muted,
                  tabs: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Tab(text: AppTranslations.storyViewers.tr),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Tab(text: AppTranslations.storyReactions.tr),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  FutureBuilder<StoryViewersResponseModel>(
                    future: _viewersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _InsightsErrorState(
                          message: AppTranslations.unableToLoadStoryViewers.tr,
                          onRetry: _reloadViewers,
                        );
                      }
                      return _buildViewersList(context, snapshot.data);
                    },
                  ),
                  FutureBuilder<StoryReactionsResponseModel>(
                    future: _reactionsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _InsightsErrorState(
                          message:
                              AppTranslations.unableToLoadStoryReactions.tr,
                          onRetry: _reloadReactions,
                        );
                      }
                      return _buildReactionsList(context, snapshot.data);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewersList(
    BuildContext context,
    StoryViewersResponseModel? response,
  ) {
    final items = response?.items ?? const [];
    if (items.isEmpty) {
      return Center(
        child: Text(
          AppTranslations.noStoryViewers.tr,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _reloadViewers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final viewer = items[index];
          final displayName = viewer.userFullname.trim().isNotEmpty
              ? viewer.userFullname
              : viewer.userName;
          return _InsightUserRow(
            userId: viewer.userId,
            displayName: displayName,
            userPicture: viewer.userPicture,
            time: viewer.time,
            isVerified: viewer.userVerified,
          );
        },
      ),
    );
  }

  Widget _buildReactionsList(
    BuildContext context,
    StoryReactionsResponseModel? response,
  ) {
    final items = response?.items ?? const [];
    if (items.isEmpty) {
      return Center(
        child: Text(
          AppTranslations.noStoryReactions.tr,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _reloadReactions,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final reaction = items[index];
          final displayName = reaction.userFullname.trim().isNotEmpty
              ? reaction.userFullname
              : reaction.userName;
          return _InsightUserRow(
            userId: reaction.userId,
            displayName: displayName,
            userPicture: reaction.userPicture,
            time: reaction.time,
            isVerified: reaction.userVerified,
            trailing: _StoryReactionBadge(
              imageUrl: reaction.reactionImageUrl,
              reactionKey: reaction.reactionKey,
              reactionTitle: reaction.reactionTitle,
            ),
          );
        },
      ),
    );
  }
}

class _InsightsErrorState extends StatelessWidget {
  const _InsightsErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(AppTranslations.retry.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightUserRow extends StatelessWidget {
  const _InsightUserRow({
    required this.userId,
    required this.displayName,
    required this.userPicture,
    required this.time,
    required this.isVerified,
    this.trailing,
  });

  final int userId;
  final String displayName;
  final String userPicture;
  final String time;
  final bool isVerified;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final resolvedName = displayName.trim().isEmpty ? '-' : displayName;
    final palette = MessengerDesign.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: userId > 0
            ? () => TimelineLauncher.openUser(context, userId: userId)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: userPicture.trim().isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: userPicture,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            _ViewerAvatar(name: resolvedName),
                      )
                    : _ViewerAvatar(name: resolvedName),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (time.trim().isNotEmpty)
                      Text(
                        time,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: palette.muted),
                      ),
                  ],
                ),
              ),
              if (isVerified)
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.verified_rounded,
                    color: MessengerDesign.primary,
                    size: 18,
                  ),
                ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryReactionBadge extends StatelessWidget {
  const _StoryReactionBadge({
    required this.imageUrl,
    required this.reactionKey,
    required this.reactionTitle,
  });

  final String imageUrl;
  final String reactionKey;
  final String reactionTitle;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Tooltip(
      message: reactionTitle.trim().isNotEmpty ? reactionTitle : reactionKey,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: palette.softSurface,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: imageUrl.trim().isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) =>
                      Center(child: Text(_fallbackEmoji(reactionKey))),
                )
              : Center(child: Text(_fallbackEmoji(reactionKey))),
        ),
      ),
    );
  }

  String _fallbackEmoji(String key) {
    switch (key.toLowerCase()) {
      case 'love':
        return '❤️';
      case 'haha':
        return '😂';
      case 'yay':
        return '🥳';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😡';
      default:
        return '👍';
    }
  }
}
