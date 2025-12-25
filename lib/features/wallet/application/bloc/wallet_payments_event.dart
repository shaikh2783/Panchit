import 'package:snginepro/core/bloc/base_bloc.dart';

abstract class WalletPaymentsEvent extends BaseEvent {
  const WalletPaymentsEvent();
}

class LoadWalletPayments extends WalletPaymentsEvent {
  const LoadWalletPayments({this.limit = 20});

  final int limit;

  @override
  List<Object?> get props => [limit];
}

class LoadMoreWalletPayments extends WalletPaymentsEvent {
  const LoadMoreWalletPayments();
}

class RefreshWalletPayments extends WalletPaymentsEvent {
  const RefreshWalletPayments();
}
