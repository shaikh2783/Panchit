import 'package:snginepro/core/bloc/base_bloc.dart';
abstract class WalletOverviewEvent extends BaseEvent {
  const WalletOverviewEvent();
}
class LoadWalletOverview extends WalletOverviewEvent {
  const LoadWalletOverview({this.forceRefresh = false});
  final bool forceRefresh;
  @override
  List<Object?> get props => [forceRefresh];
}
class RefreshWalletOverview extends WalletOverviewEvent {
  const RefreshWalletOverview();
}
