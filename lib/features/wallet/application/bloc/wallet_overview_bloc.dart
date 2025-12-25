import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/core/bloc/base_bloc.dart';

import '../../data/models/wallet_summary.dart';
import '../../domain/wallet_repository.dart';
import 'wallet_overview_event.dart';
import 'wallet_overview_state.dart';

class WalletOverviewBloc
    extends BaseBloc<WalletOverviewEvent, WalletOverviewState> {
  WalletOverviewBloc(this._repository) : super(const WalletOverviewState()) {
    on<LoadWalletOverview>(_onLoadOverview);
    on<RefreshWalletOverview>(_onRefreshOverview);
  }

  final WalletRepository _repository;
  WalletSummaryCache? _cache;

  Future<void> _onLoadOverview(
    LoadWalletOverview event,
    Emitter<WalletOverviewState> emit,
  ) async {
    if (!event.forceRefresh && _cache != null) {
      emit(state.copyWith(summary: _cache!.summary, clearError: true));
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final summary = await _repository.fetchSummary();
      _cache = WalletSummaryCache(summary: summary, fetchedAt: DateTime.now());
      emit(
        state.copyWith(summary: summary, isLoading: false, clearError: true),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onRefreshOverview(
    RefreshWalletOverview event,
    Emitter<WalletOverviewState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final summary = await _repository.fetchSummary();
      _cache = WalletSummaryCache(summary: summary, fetchedAt: DateTime.now());
      emit(
        state.copyWith(summary: summary, isLoading: false, clearError: true),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
}

class WalletSummaryCache {
  WalletSummaryCache({required this.summary, required this.fetchedAt});

  final WalletSummary summary;
  final DateTime fetchedAt;
}
