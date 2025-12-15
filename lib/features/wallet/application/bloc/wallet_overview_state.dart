import 'package:snginepro/core/bloc/base_bloc.dart';
import '../../data/models/wallet_summary.dart';
class WalletOverviewState extends BaseState {
  const WalletOverviewState({
    this.summary,
    bool isLoading = false,
    String? errorMessage,
  }) : super(isLoading: isLoading, errorMessage: errorMessage);
  final WalletSummary? summary;
  WalletOverviewState copyWith({
    WalletSummary? summary,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WalletOverviewState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
  @override
  List<Object?> get props => [summary, isLoading, errorMessage];
}
