import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/core/bloc/base_bloc.dart';
import '../../data/models/wallet_paginated.dart';
import '../../data/models/wallet_transaction.dart';
import '../../domain/wallet_repository.dart';
import 'wallet_transactions_event.dart';
import 'wallet_transactions_state.dart';
class WalletTransactionsBloc
    extends BaseBloc<WalletTransactionsEvent, WalletTransactionsState> {
  WalletTransactionsBloc(this._repository)
    : super(const WalletTransactionsState()) {
    on<LoadWalletTransactions>(_onLoadTransactions);
    on<LoadMoreWalletTransactions>(_onLoadMoreTransactions);
    on<RefreshWalletTransactions>(_onRefreshTransactions);
  }
  final WalletRepository _repository;
  Future<void> _onLoadTransactions(
    LoadWalletTransactions event,
    Emitter<WalletTransactionsState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        limit: event.limit,
        offset: 0,
        transactions: const [],
        hasMore: false,
        isLoadingMore: false,
      ),
    );
    try {
      final result = await _repository.fetchTransactions(
        offset: 0,
        limit: event.limit,
      );
      emit(_stateFromResult(result));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
  Future<void> _onLoadMoreTransactions(
    LoadMoreWalletTransactions event,
    Emitter<WalletTransactionsState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    try {
      final result = await _repository.fetchTransactions(
        offset: state.offset,
        limit: state.limit,
      );
      final updated = state.transactions + result.items;
      emit(
        state.copyWith(
          transactions: updated,
          hasMore: result.hasMore,
          isLoadingMore: false,
          clearError: true,
          offset: _calculateNextOffset(result, updated.length),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(isLoadingMore: false, errorMessage: error.toString()),
      );
    }
  }
  Future<void> _onRefreshTransactions(
    RefreshWalletTransactions event,
    Emitter<WalletTransactionsState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        offset: 0,
        isLoadingMore: false,
      ),
    );
    try {
      final result = await _repository.fetchTransactions(
        offset: 0,
        limit: state.limit,
      );
      emit(_stateFromResult(result));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
  WalletTransactionsState _stateFromResult(
    WalletPaginatedResult<WalletTransaction> result,
  ) {
    final nextOffset = _calculateNextOffset(result, result.items.length);
    return state.copyWith(
      transactions: result.items,
      hasMore: result.hasMore,
      isLoading: false,
      isLoadingMore: false,
      clearError: true,
      offset: nextOffset,
    );
  }
  int _calculateNextOffset(
    WalletPaginatedResult<WalletTransaction> result,
    int cumulativeLength,
  ) {
    final baseOffset = result.offset;
    final increment = result.items.length;
    if (increment == 0) {
      return baseOffset;
    }
    // Some endpoints return the requested offset, others return index-based offset.
    // Use whichever is greater between current offset + fetched items and cumulative length.
    final byIncrement = baseOffset + increment;
    final byLength = cumulativeLength;
    return byIncrement > byLength ? byIncrement : byLength;
  }
}
