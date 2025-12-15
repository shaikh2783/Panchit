import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/core/bloc/base_bloc.dart';
import '../../data/models/wallet_paginated.dart';
import '../../data/models/wallet_payment.dart';
import '../../domain/wallet_repository.dart';
import 'wallet_payments_event.dart';
import 'wallet_payments_state.dart';
class WalletPaymentsBloc
    extends BaseBloc<WalletPaymentsEvent, WalletPaymentsState> {
  WalletPaymentsBloc(this._repository) : super(const WalletPaymentsState()) {
    on<LoadWalletPayments>(_onLoadPayments);
    on<LoadMoreWalletPayments>(_onLoadMorePayments);
    on<RefreshWalletPayments>(_onRefreshPayments);
  }
  final WalletRepository _repository;
  Future<void> _onLoadPayments(
    LoadWalletPayments event,
    Emitter<WalletPaymentsState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        limit: event.limit,
        offset: 0,
        payments: const [],
        hasMore: false,
        isLoadingMore: false,
      ),
    );
    try {
      final result = await _repository.fetchPayments(
        offset: 0,
        limit: event.limit,
      );
      emit(_stateFromResult(result));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
  Future<void> _onLoadMorePayments(
    LoadMoreWalletPayments event,
    Emitter<WalletPaymentsState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    try {
      final result = await _repository.fetchPayments(
        offset: state.offset,
        limit: state.limit,
      );
      final updated = state.payments + result.items;
      emit(
        state.copyWith(
          payments: updated,
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
  Future<void> _onRefreshPayments(
    RefreshWalletPayments event,
    Emitter<WalletPaymentsState> emit,
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
      final result = await _repository.fetchPayments(
        offset: 0,
        limit: state.limit,
      );
      emit(_stateFromResult(result));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
  WalletPaymentsState _stateFromResult(
    WalletPaginatedResult<WalletPayment> result,
  ) {
    final nextOffset = _calculateNextOffset(result, result.items.length);
    return state.copyWith(
      payments: result.items,
      hasMore: result.hasMore,
      isLoading: false,
      isLoadingMore: false,
      clearError: true,
      offset: nextOffset,
    );
  }
  int _calculateNextOffset(
    WalletPaginatedResult<WalletPayment> result,
    int cumulativeLength,
  ) {
    final baseOffset = result.offset;
    final increment = result.items.length;
    if (increment == 0) {
      return baseOffset;
    }
    final byIncrement = baseOffset + increment;
    final byLength = cumulativeLength;
    return byIncrement > byLength ? byIncrement : byLength;
  }
}
