import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../data/models/live_stream_models.dart';
import '../data/api_service/live_stream_api_service.dart';

/// Events للتعليقات المباشرة
abstract class LiveCommentsEvent extends Equatable {
  const LiveCommentsEvent();

  @override
  List<Object?> get props => [];
}

class LoadLiveComments extends LiveCommentsEvent {
  final String postId;
  final int page;

  const LoadLiveComments({
    required this.postId,
    this.page = 1,
  });

  @override
  List<Object> get props => [postId, page];
}

class AddLiveComment extends LiveCommentsEvent {
  final String postId;
  final String text;
  final String? imageUrl;
  final String? voiceUrl;
  final String? videoUrl;
  final String? gifUrl;
  final String? stickerUrl;

  const AddLiveComment({
    required this.postId,
    required this.text,
    this.imageUrl,
    this.voiceUrl,
    this.videoUrl,
    this.gifUrl,
    this.stickerUrl,
  });

  @override
  List<Object?> get props => [
        postId,
        text,
        imageUrl,
        voiceUrl,
        videoUrl,
        gifUrl,
        stickerUrl,
      ];
}

class ReactToLiveComment extends LiveCommentsEvent {
  final String commentId;
  final String reactionType;

  const ReactToLiveComment({
    required this.commentId,
    required this.reactionType,
  });

  @override
  List<Object> get props => [commentId, reactionType];
}

class StartLiveCommentsPolling extends LiveCommentsEvent {
  final String postId;

  const StartLiveCommentsPolling({required this.postId});

  @override
  List<Object> get props => [postId];
}

class StopLiveCommentsPolling extends LiveCommentsEvent {}

class RefreshLiveComments extends LiveCommentsEvent {
  final String postId;

  const RefreshLiveComments({required this.postId});

  @override
  List<Object> get props => [postId];
}

/// States للتعليقات المباشرة
abstract class LiveCommentsState extends Equatable {
  const LiveCommentsState();

  @override
  List<Object?> get props => [];
}

class LiveCommentsInitial extends LiveCommentsState {}

class LiveCommentsLoading extends LiveCommentsState {}

class LiveCommentsLoaded extends LiveCommentsState {
  final List<LiveCommentModel> comments;
  final LiveCommentsMetadata metadata;
  final bool isPolling;
  final String? error;

  const LiveCommentsLoaded({
    required this.comments,
    required this.metadata,
    this.isPolling = false,
    this.error,
  });

  @override
  List<Object?> get props => [comments, metadata, isPolling, error];

  LiveCommentsLoaded copyWith({
    List<LiveCommentModel>? comments,
    LiveCommentsMetadata? metadata,
    bool? isPolling,
    String? error,
  }) {
    return LiveCommentsLoaded(
      comments: comments ?? this.comments,
      metadata: metadata ?? this.metadata,
      isPolling: isPolling ?? this.isPolling,
      error: error ?? this.error,
    );
  }
}

class LiveCommentsError extends LiveCommentsState {
  final String message;

  const LiveCommentsError({required this.message});

  @override
  List<Object> get props => [message];
}

class LiveCommentAdding extends LiveCommentsState {
  final List<LiveCommentModel> currentComments;

  const LiveCommentAdding({required this.currentComments});

  @override
  List<Object> get props => [currentComments];
}

/// Bloc للتعليقات المباشرة
class LiveCommentsBloc extends Bloc<LiveCommentsEvent, LiveCommentsState> {
  final LiveStreamApiService _apiService;
  Timer? _pollingTimer;
  String? _currentPostId;

  LiveCommentsBloc({required LiveStreamApiService apiService})
      : _apiService = apiService,
        super(LiveCommentsInitial()) {
    on<LoadLiveComments>(_onLoadLiveComments);
    on<AddLiveComment>(_onAddLiveComment);
    on<ReactToLiveComment>(_onReactToLiveComment);
    on<StartLiveCommentsPolling>(_onStartPolling);
    on<StopLiveCommentsPolling>(_onStopPolling);
    on<RefreshLiveComments>(_onRefreshLiveComments);
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadLiveComments(
    LoadLiveComments event,
    Emitter<LiveCommentsState> emit,
  ) async {
    try {
      if (event.page == 1) {
        emit(LiveCommentsLoading());
      }

      final result = await _apiService.getLiveComments(
        postId: event.postId, // استخدام postId بدلاً من liveId
        page: event.page,
      );

      if (result['status'] == 'success') {
        // Parse comments directly from data.comments بشكل آمن
        final commentsRaw = result['data']?['comments'];
        List<LiveCommentModel> comments = [];
        
        if (commentsRaw is List) {
          comments = commentsRaw
              .map((commentJson) => LiveCommentModel.fromJson(commentJson))
              .toList();
          
          // ترتيب التعليقات بحسب الوقت - الأقدم أولاً في القائمة
          comments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }
        
        final metadata = LiveCommentsMetadata(
          currentPage: event.page,
          totalPages: 1,
          totalComments: comments.length,
          limit: 20,
          hasMore: false,
          nextPageToken: null,
        );
        
        emit(LiveCommentsLoaded(
          comments: comments,
          metadata: metadata,
        ));
      } else {
        emit(LiveCommentsError(message: result['message'] ?? 'خطأ في تحميل التعليقات'));
      }
    } catch (e) {
      emit(LiveCommentsError(message: 'خطأ في تحميل التعليقات: ${e.toString()}'));
    }
  }

  Future<void> _onAddLiveComment(
    AddLiveComment event,
    Emitter<LiveCommentsState> emit,
  ) async {
    try {
      // Show loading state with current comments
      if (state is LiveCommentsLoaded) {
        final currentState = state as LiveCommentsLoaded;
        emit(LiveCommentAdding(currentComments: currentState.comments));
      }

      final result = await _apiService.addLiveComment(
        postId: event.postId, // استخدام postId 
        text: event.text,
        // يمكن إضافة دعم للوسائط لاحقاً:
        // imageUrl: event.imageUrl,
        // voiceUrl: event.voiceUrl,
        // videoUrl: event.videoUrl,
        // gifUrl: event.gifUrl,
        // stickerUrl: event.stickerUrl,
      );

      
      // API التعليقات يرجع comment object مباشرة (وليس status: success)
      if (result['comment'] != null || result['callback'] == 'commentCreated') {
        // Refresh comments after adding new one
        add(RefreshLiveComments(postId: event.postId));
      } else if (result['status'] == 'success') {
        // Fallback للـ API الذي يستخدم status: success
        add(RefreshLiveComments(postId: event.postId));
      } else {
        emit(LiveCommentsError(
          message: result['message'] ?? 'خطأ في إضافة التعليق',
        ));
      }
    } catch (e) {
      emit(LiveCommentsError(message: 'خطأ في إضافة التعليق: ${e.toString()}'));
    }
  }

  Future<void> _onReactToLiveComment(
    ReactToLiveComment event,
    Emitter<LiveCommentsState> emit,
  ) async {
    try {
      final result = await _apiService.reactToLiveComment(
        commentId: event.commentId,
        reactionType: event.reactionType,
      );

      if (result['status'] == 'success') {
        // Update local comment reaction count
        if (state is LiveCommentsLoaded) {
          final currentState = state as LiveCommentsLoaded;
          final updatedComments = currentState.comments.map((comment) {
            if (comment.commentId == event.commentId) {
              final updatedReactions = Map<String, int>.from(comment.reactions);
              updatedReactions[event.reactionType] = 
                  (updatedReactions[event.reactionType] ?? 0) + 1;
              
              return LiveCommentModel(
                commentId: comment.commentId,
                liveId: comment.liveId,
                userId: comment.userId,
                userName: comment.userName,
                userAvatar: comment.userAvatar,
                isVerified: comment.isVerified,
                text: comment.text,
                imageUrl: comment.imageUrl,
                voiceUrl: comment.voiceUrl,
                timestamp: comment.timestamp,
                reactions: updatedReactions,
                canEdit: comment.canEdit,
                canDelete: comment.canDelete,
              );
            }
            return comment;
          }).toList();

          emit(currentState.copyWith(comments: updatedComments));
        }
      } else {
        if (state is LiveCommentsLoaded) {
          final currentState = state as LiveCommentsLoaded;
          emit(currentState.copyWith(
            error: result['message'] ?? 'خطأ في التفاعل مع التعليق',
          ));
        }
      }
    } catch (e) {
      if (state is LiveCommentsLoaded) {
        final currentState = state as LiveCommentsLoaded;
        emit(currentState.copyWith(
          error: 'خطأ في التفاعل: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> _onStartPolling(
    StartLiveCommentsPolling event,
    Emitter<LiveCommentsState> emit,
  ) async {
    _currentPostId = event.postId;
    _pollingTimer?.cancel();
    
    // Update state to indicate polling is active
    if (state is LiveCommentsLoaded) {
      final currentState = state as LiveCommentsLoaded;
      emit(currentState.copyWith(isPolling: true));
    }

    // Start polling every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPostId != null && !isClosed) {
        add(RefreshLiveComments(postId: _currentPostId!));
      }
    });
  }

  Future<void> _onStopPolling(
    StopLiveCommentsPolling event,
    Emitter<LiveCommentsState> emit,
  ) async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _currentPostId = null;

    if (state is LiveCommentsLoaded) {
      final currentState = state as LiveCommentsLoaded;
      emit(currentState.copyWith(isPolling: false));
    }
  }

  Future<void> _onRefreshLiveComments(
    RefreshLiveComments event,
    Emitter<LiveCommentsState> emit,
  ) async {
    try {
      final result = await _apiService.getLiveComments(
        postId: event.postId,
        page: 1,
      );

      if (result['status'] == 'success') {
        // Parse comments directly from data.comments بشكل آمن
        final commentsRaw = result['data']?['comments'];
        List<LiveCommentModel> comments = [];
        
        if (commentsRaw is List) {
          comments = commentsRaw
              .map((commentJson) => LiveCommentModel.fromJson(commentJson))
              .toList();
        }
        
        final metadata = LiveCommentsMetadata(
          currentPage: 1,
          totalPages: 1,
          totalComments: comments.length,
          limit: 20,
          hasMore: false,
          nextPageToken: null,
        );
        
        if (state is LiveCommentsLoaded) {
          final currentState = state as LiveCommentsLoaded;
          emit(currentState.copyWith(
            comments: comments,
            metadata: metadata,
            error: null,
          ));
        } else {
          emit(LiveCommentsLoaded(
            comments: comments,
            metadata: metadata,
            isPolling: true,
          ));
        }
      }
    } catch (e) {
      // Silent error for polling - don't emit error state
    }
  }
}

/// Events للإحصائيات المباشرة
abstract class LiveStatsEvent extends Equatable {
  const LiveStatsEvent();

  @override
  List<Object?> get props => [];
}

class LoadLiveStats extends LiveStatsEvent {
  final String liveId;

  const LoadLiveStats({required this.liveId});

  @override
  List<Object> get props => [liveId];
}

class StartLiveStatsPolling extends LiveStatsEvent {
  final String liveId;

  const StartLiveStatsPolling({required this.liveId});

  @override
  List<Object> get props => [liveId];
}

class StopLiveStatsPolling extends LiveStatsEvent {}

/// States للإحصائيات المباشرة
abstract class LiveStatsState extends Equatable {
  const LiveStatsState();

  @override
  List<Object?> get props => [];
}

class LiveStatsInitial extends LiveStatsState {}

class LiveStatsLoading extends LiveStatsState {}

class LiveStatsLoaded extends LiveStatsState {
  final LiveStatsModel stats;
  final bool isPolling;

  const LiveStatsLoaded({
    required this.stats,
    this.isPolling = false,
  });

  @override
  List<Object> get props => [stats, isPolling];

  LiveStatsLoaded copyWith({
    LiveStatsModel? stats,
    bool? isPolling,
  }) {
    return LiveStatsLoaded(
      stats: stats ?? this.stats,
      isPolling: isPolling ?? this.isPolling,
    );
  }
}

class LiveStatsError extends LiveStatsState {
  final String message;

  const LiveStatsError({required this.message});

  @override
  List<Object> get props => [message];
}

/// Bloc للإحصائيات المباشرة
class LiveStatsBloc extends Bloc<LiveStatsEvent, LiveStatsState> {
  final LiveStreamApiService _apiService;
  Timer? _pollingTimer;

  LiveStatsBloc({required LiveStreamApiService apiService})
      : _apiService = apiService,
        super(LiveStatsInitial()) {
    on<LoadLiveStats>(_onLoadLiveStats);
    on<StartLiveStatsPolling>(_onStartPolling);
    on<StopLiveStatsPolling>(_onStopPolling);
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadLiveStats(
    LoadLiveStats event,
    Emitter<LiveStatsState> emit,
  ) async {
    try {
      emit(LiveStatsLoading());

      final result = await _apiService.getLiveStats(postId: event.liveId);

      if (result['status'] == 'success') {
        final statsData = result['data'];
        final stats = LiveStatsModel.fromJson(statsData);
        emit(LiveStatsLoaded(stats: stats));
      } else {
        emit(LiveStatsError(message: result['message'] ?? 'خطأ في تحميل الإحصائيات'));
      }
    } catch (e) {
      emit(LiveStatsError(message: 'خطأ في تحميل الإحصائيات: ${e.toString()}'));
    }
  }

  Future<void> _onStartPolling(
    StartLiveStatsPolling event,
    Emitter<LiveStatsState> emit,
  ) async {
    _pollingTimer?.cancel();

    // Update state to indicate polling is active
    if (state is LiveStatsLoaded) {
      final currentState = state as LiveStatsLoaded;
      emit(currentState.copyWith(isPolling: true));
    }

    // Start polling every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isClosed) {
        add(LoadLiveStats(liveId: event.liveId));
      }
    });
  }

  Future<void> _onStopPolling(
    StopLiveStatsPolling event,
    Emitter<LiveStatsState> emit,
  ) async {
    _pollingTimer?.cancel();
    _pollingTimer = null;

    if (state is LiveStatsLoaded) {
      final currentState = state as LiveStatsLoaded;
      emit(currentState.copyWith(isPolling: false));
    }
  }
}

/// Metadata for live comments pagination and stats
class LiveCommentsMetadata extends Equatable {
  final int currentPage;
  final int totalPages;
  final int totalComments;
  final int limit;
  final bool hasMore;
  final String? nextPageToken;
  final int? liveCount;

  const LiveCommentsMetadata({
    required this.currentPage,
    required this.totalPages,
    required this.totalComments,
    required this.limit,
    required this.hasMore,
    this.nextPageToken,
    this.liveCount,
  });

  @override
  List<Object?> get props => [
    currentPage,
    totalPages,
    totalComments,
    limit,
    hasMore,
    nextPageToken,
    liveCount,
  ];

  LiveCommentsMetadata copyWith({
    int? currentPage,
    int? totalPages,
    int? totalComments,
    int? limit,
    bool? hasMore,
    String? nextPageToken,
    int? liveCount,
  }) {
    return LiveCommentsMetadata(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalComments: totalComments ?? this.totalComments,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
      nextPageToken: nextPageToken ?? this.nextPageToken,
      liveCount: liveCount ?? this.liveCount,
    );
  }
}
