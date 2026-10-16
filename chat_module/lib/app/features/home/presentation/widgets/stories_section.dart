import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/controllers/session_controller.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/theme/messenger_design.dart';
import '../../data/models/stories_response_model.dart';
import '../../data/models/story_group_model.dart';
import '../../data/services/stories_service.dart';
import '../pages/story_viewer_page.dart';

const double _kStoryItemWidth = 62;
const double _kStoryAvatarSize = 52;
const double _kStoriesHeight = 84;

class StoriesSection extends StatefulWidget {
  const StoriesSection({super.key});

  @override
  State<StoriesSection> createState() => _StoriesSectionState();
}

class _StoriesSectionState extends State<StoriesSection> {
  late Future<StoriesResponseModel> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _storiesFuture = Get.find<StoriesService>().loadStories();
  }

  Future<void> _reloadStories() async {
    setState(() {
      _storiesFuture = Get.find<StoriesService>().loadStories();
    });
    await _storiesFuture;
  }

  Future<void> _createStory() async {
    // Story creation is deferred pending vs_story_designer fork
    // reconciliation between the host app and this module.
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Story creation is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StoriesResponseModel>(
      future: _storiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StoriesLoadingView();
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _StoriesErrorView(onRetry: _reloadStories);
        }

        final response = snapshot.data!;
        final stories = response.items;
        return SizedBox(
          height: _kStoriesHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: stories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _MyStoryItem(
                  hasStory: response.hasMyStory,
                  onTap: _createStory,
                );
              }

              final story = stories[index - 1];
              return _StoryItem(
                story: story,
                onTap: () async {
                  await Get.to<void>(
                    () => StoryViewerPage(
                      story: story,
                      stories: stories,
                      initialGroupIndex: index - 1,
                    ),
                  );
                  if (mounted) {
                    await _reloadStories();
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _MyStoryItem extends StatelessWidget {
  const _MyStoryItem({required this.hasStory, required this.onTap});

  final bool hasStory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    return Obx(() {
      final name = session.currentUserName.value.trim();
      final displayName = name.isEmpty ? AppTranslations.addStory.tr : name;
      return _StoryItemShell(
        onTap: onTap,
        label: displayName.split(' ').first,
        child: _StoryAvatar(
          imageUrl: session.currentUserPicture.value,
          name: displayName,
          showRing: hasStory,
          showAdd: !hasStory,
        ),
      );
    });
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({required this.story, this.onTap});

  final StoryGroupModel story;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _StoryItemShell(
      onTap: onTap,
      label: story.name,
      child: _StoryAvatar(
        imageUrl: story.photo,
        name: story.name,
        showRing: true,
      ),
    );
  }
}

class _StoryItemShell extends StatelessWidget {
  const _StoryItemShell({required this.child, required this.label, this.onTap});

  final Widget child;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: _kStoryItemWidth,
        child: Column(
          children: [
            child,
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.text,
                fontSize: 10.5,
                height: 1.05,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({
    required this.imageUrl,
    required this.name,
    required this.showRing,
    this.showAdd = false,
  });

  final String imageUrl;
  final String name;
  final bool showRing;
  final bool showAdd;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return SizedBox(
      width: _kStoryAvatarSize,
      height: _kStoryAvatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _kStoryAvatarSize,
            height: _kStoryAvatarSize,
            padding: EdgeInsets.all(showRing ? 2 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: showRing
                  ? Border.all(color: MessengerDesign.primary, width: 2)
                  : null,
            ),
            child: Container(
              padding: EdgeInsets.all(showRing ? 2 : 0),
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: imageUrl.trim().isEmpty
                    ? _StoryInitial(name: name)
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _StoryInitial(name: name),
                      ),
              ),
            ),
          ),
          if (showAdd)
            PositionedDirectional(
              end: -1,
              bottom: -1,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: MessengerDesign.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.surface, width: 1.5),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: MessengerDesign.canvas,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryInitial extends StatelessWidget {
  const _StoryInitial({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    return ColoredBox(
      color: MessengerDesign.primary.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: MessengerDesign.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StoriesLoadingView extends StatelessWidget {
  const _StoriesLoadingView();

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return SizedBox(
      height: _kStoriesHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, _) => SizedBox(
          width: _kStoryItemWidth,
          child: Column(
            children: [
              Container(
                width: _kStoryAvatarSize,
                height: _kStoryAvatarSize,
                decoration: BoxDecoration(
                  color: palette.softSurface,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                width: 38,
                height: 7,
                decoration: BoxDecoration(
                  color: palette.softSurface,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoriesErrorView extends StatelessWidget {
  const _StoriesErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kStoriesHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(AppTranslations.storiesLoadFailed.tr),
        ),
      ),
    );
  }
}
