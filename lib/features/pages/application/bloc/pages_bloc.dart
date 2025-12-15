import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/core/bloc/base_bloc.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/features/pages/data/models/page.dart';
import 'package:snginepro/features/pages/domain/pages_repository.dart';
// Events
abstract class PagesEvent extends BaseEvent {}
class LoadPagesEvent extends PagesEvent {
  final String? category;
  LoadPagesEvent({this.category});
  @override
  List<Object?> get props => [category];
}
class LoadMyPagesEvent extends PagesEvent {}
class RefreshPagesEvent extends PagesEvent {}
class LoadPageDetailsEvent extends PagesEvent {
  final String pageId;
  LoadPageDetailsEvent(this.pageId);
  @override
  List<Object?> get props => [pageId];
}
class LoadPagePostsEvent extends PagesEvent {
  final String pageId;
  LoadPagePostsEvent(this.pageId);
  @override
  List<Object?> get props => [pageId];
}
class LikePageEvent extends PagesEvent {
  final String pageId;
  LikePageEvent(this.pageId);
  @override
  List<Object?> get props => [pageId];
}
class UnlikePageEvent extends PagesEvent {
  final String pageId;
  UnlikePageEvent(this.pageId);
  @override
  List<Object?> get props => [pageId];
}
class SearchPagesEvent extends PagesEvent {
  final String query;
  SearchPagesEvent(this.query);
  @override
  List<Object?> get props => [query];
}
// States
abstract class PagesState extends BaseState {
  const PagesState({
    super.isLoading,
    super.errorMessage,
    this.pages = const [],
    this.myPages = const [],
    this.currentPage,
    this.searchResults = const [],
  });
  final List<PageModel> pages;
  final List<PageModel> myPages;
  final PageModel? currentPage;
  final List<PageModel> searchResults;
  @override
  List<Object?> get props => [
        ...super.props,
        pages,
        myPages,
        currentPage,
        searchResults,
      ];
}
class PagesInitial extends PagesState {
  const PagesInitial();
}
class PagesLoading extends PagesState {
  const PagesLoading({
    super.pages,
    super.myPages,
    super.currentPage,
    super.searchResults,
  }) : super(isLoading: true);
}
class PagesLoaded extends PagesState {
  const PagesLoaded({
    required super.pages,
    required super.myPages,
    super.currentPage,
    super.searchResults,
  });
}
class PagesError extends PagesState {
  const PagesError(
    String message, {
    super.pages,
    super.myPages,
    super.currentPage,
    super.searchResults,
  }) : super(errorMessage: message);
}
class PageDetailsLoaded extends PagesState {
  const PageDetailsLoaded({
    required super.pages,
    required super.myPages,
    required super.currentPage,
    super.searchResults,
  });
}
class PageLiked extends PagesState {
  const PageLiked({
    required super.pages,
    required super.myPages,
    super.currentPage,
    super.searchResults,
  });
}
class PageUnliked extends PagesState {
  const PageUnliked({
    required super.pages,
    required super.myPages,
    super.currentPage,
    super.searchResults,
  });
}
class PagesSearched extends PagesState {
  const PagesSearched({
    required super.pages,
    required super.myPages,
    super.currentPage,
    required super.searchResults,
  });
}
// Bloc
class PagesBloc extends Bloc<PagesEvent, PagesState> {
  PagesBloc(this._repository) : super(const PagesInitial()) {
    on<LoadPagesEvent>(_onLoadPagesEvent);
    on<LoadMyPagesEvent>(_onLoadMyPages);
    on<RefreshPagesEvent>(_onRefreshPages);
    on<LoadPageDetailsEvent>(_onLoadPageDetails);
    on<LoadPagePostsEvent>(_onLoadPagePosts);
    on<LikePageEvent>(_onLikePageEvent);
    on<UnlikePageEvent>(_onUnlikePageEvent);
    on<SearchPagesEvent>(_onSearchPagesEvent);
  }
  final PagesRepository _repository;
  Future<void> _onLoadPagesEvent(
    LoadPagesEvent event,
    Emitter<PagesState> emit,
  ) async {
    emit(PagesLoading(
      pages: state.pages,
      myPages: state.myPages,
      currentPage: state.currentPage,
      searchResults: state.searchResults,
    ));
    try {
      final pages = await _repository.fetchSuggestedPages();
      emit(PagesLoaded(
        pages: pages,
        myPages: state.myPages,
        currentPage: state.currentPage,
        searchResults: state.searchResults,
      ));
    } on ApiException catch (e) {
      emit(PagesError(
        e.message,
        pages: state.pages,
        myPages: state.myPages,
        currentPage: state.currentPage,
        searchResults: state.searchResults,
      ));
    }
  }
  Future<void> _onLoadMyPages(
    LoadMyPagesEvent event,
    Emitter<PagesState> emit,
  ) async {
    try {
      final myPages = await _repository.fetchMyPages();
      emit(PagesLoaded(
        pages: state.pages,
        myPages: myPages,
        currentPage: state.currentPage,
        searchResults: state.searchResults,
      ));
    } on ApiException catch (e) {
      emit(PagesError(
        e.message,
        pages: state.pages,
        myPages: state.myPages,
        currentPage: state.currentPage,
        searchResults: state.searchResults,
      ));
    }
  }
  Future<void> _onRefreshPages(
    RefreshPagesEvent event,
    Emitter<PagesState> emit,
  ) async {
    try {
      final pages = await _repository.fetchSuggestedPages();
      final myPages = await _repository.fetchMyPages();
      emit(PagesLoaded(
        pages: pages,
        myPages: myPages,
        currentPage: state.currentPage,
        searchResults: state.searchResults,
      ));
    } on ApiException catch (e) {
      emit(PagesError(
        e.message,
        pages: state.pages,
        myPages: state.myPages,
        currentPage: state.currentPage,
        searchResults: state.searchResults,
      ));
    }
  }
  Future<void> _onLoadPageDetails(
    LoadPageDetailsEvent event,
    Emitter<PagesState> emit,
  ) async {
    emit(PagesLoading(
      pages: state.pages,
      myPages: state.myPages,
      currentPage: state.currentPage,
      searchResults: state.searchResults,
    ));
    try {
      final page = await _repository.fetchPageInfo(pageId: int.tryParse(event.pageId));
      emit(PageDetailsLoaded(
        pages: state.pages,
        myPages: state.myPages,
        currentPage: page,
        searchResults: state.searchResults,
      ));
    } on ApiException catch (e) {
      emit(PagesError(
        e.message,
        pages: state.pages,
        myPages: state.myPages,
        currentPage: state.currentPage,
        searchResults: state.searchResults,
      ));
    }
  }
  Future<void> _onLoadPagePosts(
    LoadPagePostsEvent event,
    Emitter<PagesState> emit,
  ) async {
    // Simple implementation - just emit current state since post loading is complex
    emit(PagesLoaded(
      pages: state.pages,
      myPages: state.myPages,
      currentPage: state.currentPage,
      searchResults: state.searchResults,
    ));
  }
  Future<void> _onLikePageEvent(
    LikePageEvent event,
    Emitter<PagesState> emit,
  ) async {
    try {
      await _repository.toggleLikePage(int.tryParse(event.pageId) ?? 0, false);
      emit(PageLiked(
        pages: state.pages,
        myPages: state.myPages,
        currentPage: state.currentPage,
        searchResults: state.searchResults,
      ));
    } on ApiException catch (e) {
      emit(PagesError(
        e.message,
        pages: state.pages,
        myPages: state.myPages,
        currentPage: state.currentPage,
        searchResults: state.searchResults,
      ));
    }
  }
  Future<void> _onUnlikePageEvent(
    UnlikePageEvent event,
    Emitter<PagesState> emit,
  ) async {
    try {
      await _repository.toggleLikePage(int.tryParse(event.pageId) ?? 0, true);
      emit(PageUnliked(
        pages: state.pages,
        myPages: state.myPages,
        currentPage: state.currentPage,
        searchResults: state.searchResults,
      ));
    } on ApiException catch (e) {
      emit(PagesError(
        e.message,
        pages: state.pages,
        myPages: state.myPages,
        currentPage: state.currentPage,
        searchResults: state.searchResults,
      ));
    }
  }
  Future<void> _onSearchPagesEvent(
    SearchPagesEvent event,
    Emitter<PagesState> emit,
  ) async {
    try {
      // Use suggested pages as search results since search API isn't available
      final searchResults = await _repository.fetchSuggestedPages();
      emit(PagesSearched(
        pages: state.pages,
        myPages: state.myPages,
        currentPage: state.currentPage,
        searchResults: searchResults,
      ));
    } on ApiException catch (e) {
      emit(PagesError(
        e.message,
        pages: state.pages,
        myPages: state.myPages,
        currentPage: state.currentPage,
        searchResults: state.searchResults,
      ));
    }
  }
}