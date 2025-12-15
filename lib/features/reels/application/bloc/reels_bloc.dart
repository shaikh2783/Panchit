import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/reels/domain/reels_repository.dart';
import 'package:snginepro/core/network/api_exception.dart';
// Events
abstract class ReelsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}
class LoadReelsEvent extends ReelsEvent {
  final String source;
  LoadReelsEvent({this.source = 'all'});
  @override
  List<Object?> get props => [source];
}
class RefreshReelsEvent extends ReelsEvent {
  final String source;
  RefreshReelsEvent({this.source = 'all'});
  @override
  List<Object?> get props => [source];
}
class LoadMoreReelsEvent extends ReelsEvent {}
class ChangeReelsSourceEvent extends ReelsEvent {
  final String source;
  ChangeReelsSourceEvent(this.source);
  @override
  List<Object?> get props => [source];
}
class UpdateReelEvent extends ReelsEvent {
  final Post reel;
  UpdateReelEvent(this.reel);
  @override
  List<Object?> get props => [reel];
}
class DeleteReelEvent extends ReelsEvent {
  final int reelId;
  DeleteReelEvent(this.reelId);
  @override
  List<Object?> get props => [reelId];
}
// States
abstract class ReelsState extends Equatable {
  @override
  List<Object?> get props => [];
}
class ReelsInitialState extends ReelsState {}
class ReelsLoadingState extends ReelsState {}
class ReelsLoadedState extends ReelsState {
  final List<Post> reels;
  final String source;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;
  ReelsLoadedState({
    required this.reels,
    required this.source,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });
  ReelsLoadedState copyWith({
    List<Post>? reels,
    String? source,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return ReelsLoadedState(
      reels: reels ?? this.reels,
      source: source ?? this.source,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
  @override
  List<Object?> get props => [reels, source, hasMore, isLoadingMore, isRefreshing];
}
class ReelsErrorState extends ReelsState {
  final String message;
  final String source;
  ReelsErrorState(this.message, {this.source = 'all'});
  @override
  List<Object?> get props => [message, source];
}
// Bloc
class ReelsBloc extends Bloc<ReelsEvent, ReelsState> {
  ReelsBloc(this._repository) : super(ReelsInitialState()) {
    on<LoadReelsEvent>(_onLoadReels);
    on<RefreshReelsEvent>(_onRefreshReels);
    on<LoadMoreReelsEvent>(_onLoadMoreReels);
    on<ChangeReelsSourceEvent>(_onChangeReelsSource);
    on<UpdateReelEvent>(_onUpdateReel);
    on<DeleteReelEvent>(_onDeleteReel);
  }
  final ReelsRepository _repository;
  int _currentPage = 0;
  final int _pageSize = 10;
  String _currentSource = 'all';
  Future<void> _onLoadReels(LoadReelsEvent event, Emitter<ReelsState> emit) async {
    try {
      emit(ReelsLoadingState());
      _currentPage = 0;
      _currentSource = event.source;
      final response = await _repository.fetchReels(
        limit: _pageSize,
        offset: _currentPage,
        source: _currentSource,
      );
      emit(ReelsLoadedState(
        reels: response.reels,
        source: _currentSource,
        hasMore: response.hasMore,
      ));
    } on ApiException catch (e) {
      emit(ReelsErrorState(e.message, source: _currentSource));
    } catch (e) {
      emit(ReelsErrorState('تعذر تحميل الريلز، يرجى المحاولة لاحقاً.', source: _currentSource));
    }
  }
  Future<void> _onRefreshReels(RefreshReelsEvent event, Emitter<ReelsState> emit) async {
    if (state is! ReelsLoadedState) return;
    final currentState = state as ReelsLoadedState;
    try {
      emit(currentState.copyWith(isRefreshing: true));
      _currentPage = 0;
      _currentSource = event.source;
      final response = await _repository.fetchReels(
        limit: _pageSize,
        offset: _currentPage,
        source: _currentSource,
      );
      emit(ReelsLoadedState(
        reels: response.reels,
        source: _currentSource,
        hasMore: response.hasMore,
      ));
    } on ApiException catch (e) {
      emit(currentState.copyWith(isRefreshing: false));
      emit(ReelsErrorState(e.message, source: _currentSource));
    } catch (e) {
      emit(currentState.copyWith(isRefreshing: false));
      emit(ReelsErrorState('حدث خطأ أثناء تحديث الريلز.', source: _currentSource));
    }
  }
  Future<void> _onLoadMoreReels(LoadMoreReelsEvent event, Emitter<ReelsState> emit) async {
    if (state is! ReelsLoadedState) return;
    final currentState = state as ReelsLoadedState;
    if (!currentState.hasMore || currentState.isLoadingMore) return;
    try {
      emit(currentState.copyWith(isLoadingMore: true));
      _currentPage++;
      final response = await _repository.fetchReels(
        limit: _pageSize,
        offset: _currentPage,
        source: _currentSource,
      );
      final updatedReels = List<Post>.from(currentState.reels)..addAll(response.reels);
      emit(ReelsLoadedState(
        reels: updatedReels,
        source: _currentSource,
        hasMore: response.hasMore,
      ));
    } on ApiException catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
      emit(ReelsErrorState(e.message, source: _currentSource));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
      emit(ReelsErrorState('حدث خطأ أثناء جلب المزيد من الريلز.', source: _currentSource));
    }
  }
  Future<void> _onChangeReelsSource(ChangeReelsSourceEvent event, Emitter<ReelsState> emit) async {
    if (event.source == _currentSource) return;
    add(LoadReelsEvent(source: event.source));
  }
  Future<void> _onUpdateReel(UpdateReelEvent event, Emitter<ReelsState> emit) async {
    if (state is! ReelsLoadedState) return;
    final currentState = state as ReelsLoadedState;
    final updatedReels = currentState.reels.map((reel) {
      return reel.id == event.reel.id ? event.reel : reel;
    }).toList();
    emit(currentState.copyWith(reels: updatedReels));
  }
  Future<void> _onDeleteReel(DeleteReelEvent event, Emitter<ReelsState> emit) async {
    if (state is! ReelsLoadedState) return;
    final currentState = state as ReelsLoadedState;
    final updatedReels = currentState.reels.where((reel) => reel.id != event.reelId).toList();
    emit(currentState.copyWith(reels: updatedReels));
  }
}