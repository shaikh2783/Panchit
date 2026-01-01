import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/core/bloc/base_bloc.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/features/feed/data/models/story.dart';
import 'package:snginepro/features/stories/domain/stories_repository.dart';

// Events
abstract class StoriesEvent extends BaseEvent {}

class LoadStoriesEvent extends StoriesEvent {}

class RefreshStoriesEvent extends StoriesEvent {}

class CreateStoryEvent extends StoriesEvent {
  final String? imagePath;
  final String? videoPath;
  final String? text;
  final Duration? duration;

  CreateStoryEvent({
    this.imagePath,
    this.videoPath,
    this.text,
    this.duration,
  });

  @override
  List<Object?> get props => [imagePath, videoPath, text, duration];
}

class ViewStoryEvent extends StoriesEvent {
  final String storyId;
  final String userId;

  ViewStoryEvent({required this.storyId, required this.userId});

  @override
  List<Object?> get props => [storyId, userId];
}

class DeleteStoryEvent extends StoriesEvent {
  final String mediaId;
  final String storyId; // معرف القصة للحذف المحلي

  DeleteStoryEvent({required this.mediaId, required this.storyId});

  @override
  List<Object?> get props => [mediaId, storyId];
}

class ReactToStoryEvent extends StoriesEvent {
  final String storyId;
  final String reaction;

  ReactToStoryEvent({required this.storyId, required this.reaction});

  @override
  List<Object?> get props => [storyId, reaction];
}

// States
abstract class StoriesState extends BaseState {
  const StoriesState({
    super.isLoading,
    super.errorMessage,
    this.stories = const [],
    this.myStories = const [],
    this.currentStoryIndex = 0,
    this.isCreatingStory = false,
  });

  final List<Story> stories;
  final List<Story> myStories;
  final int currentStoryIndex;
  final bool isCreatingStory;

  @override
  List<Object?> get props => [
        ...super.props,
        stories,
        myStories,
        currentStoryIndex,
        isCreatingStory,
      ];
}

class StoriesInitial extends StoriesState {
  const StoriesInitial();
}

class StoriesLoading extends StoriesState {
  const StoriesLoading({
    super.stories,
    super.myStories,
    super.currentStoryIndex,
  }) : super(isLoading: true);
}

class StoriesCreating extends StoriesState {
  const StoriesCreating({
    required super.stories,
    required super.myStories,
    required super.currentStoryIndex,
  }) : super(isCreatingStory: true);
}

class StoriesLoaded extends StoriesState {
  const StoriesLoaded({
    required super.stories,
    required super.myStories,
    super.currentStoryIndex,
  });
}

class StoriesError extends StoriesState {
  const StoriesError(
    String message, {
    super.stories,
    super.myStories,
    super.currentStoryIndex,
  }) : super(errorMessage: message);
}

class StoryCreated extends StoriesState {
  final Story newStory;

  const StoryCreated({
    required this.newStory,
    required super.stories,
    required super.myStories,
    super.currentStoryIndex,
  });

  @override
  List<Object?> get props => [...super.props, newStory];
}

class StoryViewed extends StoriesState {
  final String viewedStoryId;

  const StoryViewed({
    required this.viewedStoryId,
    required super.stories,
    required super.myStories,
    super.currentStoryIndex,
  });

  @override
  List<Object?> get props => [...super.props, viewedStoryId];
}

class StoryDeleted extends StoriesState {
  final String deletedStoryId;

  const StoryDeleted({
    required this.deletedStoryId,
    required super.stories,
    required super.myStories,
    super.currentStoryIndex,
  });

  @override
  List<Object?> get props => [...super.props, deletedStoryId];
}

// Bloc
class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  StoriesBloc(this._repository) : super(const StoriesInitial()) {
    on<LoadStoriesEvent>(_onLoadStories);
    on<RefreshStoriesEvent>(_onRefreshStories);
    on<CreateStoryEvent>(_onCreateStory);
    on<ViewStoryEvent>(_onViewStory);
    on<DeleteStoryEvent>(_onDeleteStory);
    on<ReactToStoryEvent>(_onReactToStory);
  }

  final StoriesRepository _repository;

  Future<void> _onLoadStories(
    LoadStoriesEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(StoriesLoading(
      stories: state.stories,
      myStories: state.myStories,
      currentStoryIndex: state.currentStoryIndex,
    ));

    try {
      final response = await _repository.fetchStories();
      
      // Convert stories from StoriesResponse to feed Story models
      final feedStories = <Story>[];
      for (var story in response.stories) {
        final items = <StoryItem>[];
        for (var media in story.media) {
          // تخطي الميديا الفارغة أو غير الصالحة
          if (media.source.isEmpty || !media.isValid) {
            continue;
          }
          items.add(StoryItem(
            id: media.id,
            type: media.type,
            source: media.source,
            linkText: '',
          ));
        }
        
        // تخطي القصص التي لا تحتوي على أي عناصر صالحة
        if (items.isEmpty) {
          continue;
        }
        
        feedStories.add(Story(
          id: story.id,
          authorName: story.authorName,
          authorId: story.authorId,
          authorAvatarUrl: story.authorAvatarUrl,
          items: items,
          isOwner: story.isOwner,
        ));
      }

      emit(StoriesLoaded(
        stories: feedStories,
        myStories: const [], // No separate my stories endpoint available
        currentStoryIndex: 0,
      ));
    } on ApiException catch (e) {
      emit(StoriesError(
        e.message,
        stories: state.stories,
        myStories: state.myStories,
        currentStoryIndex: state.currentStoryIndex,
      ));
    } catch (e) {
      emit(StoriesError(
        e.toString(),
        stories: state.stories,
        myStories: state.myStories,
        currentStoryIndex: state.currentStoryIndex,
      ));
    }
  }

  Future<void> _onRefreshStories(
    RefreshStoriesEvent event,
    Emitter<StoriesState> emit,
  ) async {
    // Same as load for now since no separate refresh endpoint
    add(LoadStoriesEvent());
  }

  Future<void> _onCreateStory(
    CreateStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(StoriesCreating(
      stories: state.stories,
      myStories: state.myStories,
      currentStoryIndex: state.currentStoryIndex,
    ));

    try {
      // ✅ استخدام API الحقيقي لإنشاء القصة
      await _repository.createStory(
        imagePath: event.imagePath,
        videoPath: event.videoPath,
        text: event.text,
      );

      // إعادة تحميل القصص بعد الإنشاء
      add(LoadStoriesEvent());

      emit(StoriesLoaded(
        stories: state.stories,
        myStories: state.myStories,
        currentStoryIndex: state.currentStoryIndex,
      ));
    } on ApiException catch (e) {
      emit(StoriesError(
        e.message,
        stories: state.stories,
        myStories: state.myStories,
        currentStoryIndex: state.currentStoryIndex,
      ));
    } catch (e) {
      emit(StoriesError(
        'خطأ في إنشاء القصة: $e',
        stories: state.stories,
        myStories: state.myStories,
        currentStoryIndex: state.currentStoryIndex,
      ));
    }
  }

  Future<void> _onViewStory(
    ViewStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    // Simple local state update since view API isn't available
    emit(StoryViewed(
      viewedStoryId: event.storyId,
      stories: state.stories,
      myStories: state.myStories,
      currentStoryIndex: state.currentStoryIndex,
    ));
  }

  Future<void> _onDeleteStory(
    DeleteStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(StoriesLoading(
      stories: state.stories,
      myStories: state.myStories,
      currentStoryIndex: state.currentStoryIndex,
    ));

    try {
      // ✅ استخدام API الحقيقي لحذف القصة باستخدام media_id
      await _repository.deleteStory(mediaId: event.mediaId);

      // إزالة القصة من القائمة المحلية
      final updatedStories = state.stories
          .where((story) => story.id != event.storyId)
          .toList();
      final updatedMyStories = state.myStories
          .where((story) => story.id != event.storyId)
          .toList();

      emit(StoryDeleted(
        deletedStoryId: event.storyId,
        stories: updatedStories,
        myStories: updatedMyStories,
        currentStoryIndex: state.currentStoryIndex,
      ));
    } on ApiException catch (e) {
      emit(StoriesError(
        e.message,
        stories: state.stories,
        myStories: state.myStories,
        currentStoryIndex: state.currentStoryIndex,
      ));
    } catch (e) {
      emit(StoriesError(
        'خطأ في حذف القصة: $e',
        stories: state.stories,
        myStories: state.myStories,
        currentStoryIndex: state.currentStoryIndex,
      ));
    }
  }

  Future<void> _onReactToStory(
    ReactToStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    // Simple local state update since reaction API isn't available
    emit(StoriesLoaded(
      stories: state.stories,
      myStories: state.myStories,
      currentStoryIndex: state.currentStoryIndex,
    ));
  }
}