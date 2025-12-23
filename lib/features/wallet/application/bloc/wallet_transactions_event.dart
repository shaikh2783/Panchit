import 'package:snginepro/core/bloc/base_bloc.dart';

abstract class WalletTransactionsEvent extends BaseEvent {
  const WalletTransactionsEvent();
}

class LoadWalletTransactions extends WalletTransactionsEvent {
  const LoadWalletTransactions({this.limit = 20});

  final int limit;

  @override
  List<Object?> get props => [limit];
}

class LoadMoreWalletTransactions extends WalletTransactionsEvent {
  const LoadMoreWalletTransactions();
}

class RefreshWalletTransactions extends WalletTransactionsEvent {
  const RefreshWalletTransactions();
}
