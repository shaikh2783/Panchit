import 'package:snginepro/core/bloc/base_bloc.dart';

import '../../data/models/wallet_transaction.dart';

class WalletTransactionsState extends BaseState {
  const WalletTransactionsState({
    this.transactions = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.offset = 0,
    this.limit = 20,
    bool isLoading = false,
    String? errorMessage,
  }) : super(isLoading: isLoading, errorMessage: errorMessage);

  final List<WalletTransaction> transactions;
  final bool hasMore;
  final bool isLoadingMore;
  final int offset;
  final int limit;

  WalletTransactionsState copyWith({
    List<WalletTransaction>? transactions,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    int? offset,
    int? limit,
  }) {
    return WalletTransactionsState(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [
    transactions,
    hasMore,
    isLoading,
    isLoadingMore,
    errorMessage,
    offset,
    limit,
  ];
}
