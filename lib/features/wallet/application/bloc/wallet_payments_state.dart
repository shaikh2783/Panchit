import 'package:snginepro/core/bloc/base_bloc.dart';

import '../../data/models/wallet_payment.dart';

class WalletPaymentsState extends BaseState {
  const WalletPaymentsState({
    this.payments = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.offset = 0,
    this.limit = 20,
    bool isLoading = false,
    String? errorMessage,
  }) : super(isLoading: isLoading, errorMessage: errorMessage);

  final List<WalletPayment> payments;
  final bool hasMore;
  final bool isLoadingMore;
  final int offset;
  final int limit;

  WalletPaymentsState copyWith({
    List<WalletPayment>? payments,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    int? offset,
    int? limit,
  }) {
    return WalletPaymentsState(
      payments: payments ?? this.payments,
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
    payments,
    hasMore,
    isLoading,
    isLoadingMore,
    errorMessage,
    offset,
    limit,
  ];
}
