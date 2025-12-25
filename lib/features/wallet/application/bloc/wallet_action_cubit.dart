import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/wallet_action_result.dart';
import '../../domain/wallet_repository.dart';

class WalletActionCubit extends Cubit<WalletActionState> {
  WalletActionCubit(this._repository)
    : super(const WalletActionState.initial());

  final WalletRepository _repository;

  Future<void> transfer({required int userId, required double amount}) async {
    await _execute(
      action: WalletActionType.transfer,
      runner: () => _repository.transfer(userId: userId, amount: amount),
    );
  }

  Future<void> tip({required int userId, required double amount}) async {
    await _execute(
      action: WalletActionType.tip,
      runner: () => _repository.sendTip(userId: userId, amount: amount),
    );
  }

  Future<void> withdraw({
    required String source,
    required double amount,
  }) async {
    await _execute(
      action: WalletActionType.withdraw,
      runner: () => _repository.withdraw(source: source, amount: amount),
    );
  }

  Future<void> recharge({
    required double amount,
    String? method,
    String? reference,
    String? note,
  }) async {
    await _execute(
      action: WalletActionType.recharge,
      runner: () => _repository.recharge(
        amount: amount,
        method: method,
        reference: reference,
        note: note,
      ),
    );
  }

  Future<void> _execute({
    required WalletActionType action,
    required Future<WalletActionResult> Function() runner,
  }) async {
    emit(
      state.copyWith(
        status: WalletActionStatus.inProgress,
        lastAction: action,
        clearError: true,
        clearResult: true,
      ),
    );

    try {
      final result = await runner();
      final status = result.success
          ? WalletActionStatus.success
          : WalletActionStatus.failure;
      emit(
        state.copyWith(
          status: status,
          result: result,
          errorMessage: result.success ? null : result.message,
          lastAction: action,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: WalletActionStatus.failure,
          errorMessage: error.toString(),
          lastAction: action,
        ),
      );
    }
  }

  void resetStatus() {
    emit(
      state.copyWith(
        status: WalletActionStatus.idle,
        clearError: true,
        clearResult: true,
        lastAction: null,
      ),
    );
  }
}

class WalletActionState extends Equatable {
  const WalletActionState({
    required this.status,
    this.result,
    this.errorMessage,
    this.lastAction,
  });

  const WalletActionState.initial()
    : status = WalletActionStatus.idle,
      result = null,
      errorMessage = null,
      lastAction = null;

  final WalletActionStatus status;
  final WalletActionResult? result;
  final String? errorMessage;
  final WalletActionType? lastAction;

  WalletActionState copyWith({
    WalletActionStatus? status,
    WalletActionResult? result,
    String? errorMessage,
    WalletActionType? lastAction,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return WalletActionState(
      status: status ?? this.status,
      result: clearResult ? null : result ?? this.result,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastAction: lastAction ?? this.lastAction,
    );
  }

  @override
  List<Object?> get props => [status, result, errorMessage, lastAction];
}

enum WalletActionStatus { idle, inProgress, success, failure }

enum WalletActionType { transfer, tip, withdraw, recharge }
