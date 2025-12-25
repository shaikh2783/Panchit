import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/stories/application/bloc/stories_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Stories section widget for the feed
/// Shows horizontal scrollable stories with create story button
class StorySectionWidget extends StatelessWidget {
  const StorySectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: BlocBuilder<StoriesBloc, StoriesState>(
        builder: (context, state) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: (state is StoriesLoaded ? state.stories.length : 0) + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Create story button
                return _CreateStoryCard();
              }
              
              if (state is StoriesLoaded) {
                final story = state.stories[index - 1];
                return _StoryCard(
                  storyId: story.id,
                  userName: story.authorName,
                  userAvatar: story.authorAvatarUrl,
                  storyImage: story.items.isNotEmpty ? story.items.first.source : null,
                  isViewed: false, // For now, we'll assume not viewed
                );
              }
              
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

class _CreateStoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.8),
                  Theme.of(context).primaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'your_story'.tr,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.storyId,
    required this.userName,
    required this.userAvatar,
    required this.storyImage,
    required this.isViewed,
  });

  final String storyId;
  final String userName;
  final String? userAvatar;
  final String? storyImage;
  final bool isViewed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle story tap - view story
        // context.read<StoriesBloc>().add(ViewStoryEvent(storyId: storyId, userId: 'currentUserId'));
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isViewed 
                      ? Colors.grey.withOpacity(0.5) 
                      : Theme.of(context).primaryColor,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: storyImage != null
                    ? Image.network(
                        storyImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _defaultAvatar(context);
                        },
                      )
                    : _defaultAvatar(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isViewed ? Colors.grey : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        color: Colors.grey[600],
        size: 30,
      ),
    );
  }
}