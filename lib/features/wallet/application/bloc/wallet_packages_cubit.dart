import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:snginepro/core/network/api_exception.dart';

import '../../data/models/wallet_action_result.dart';
import '../../data/models/wallet_package.dart';
import '../../domain/wallet_repository.dart';

class WalletPackagesCubit extends Cubit<WalletPackagesState> {
  WalletPackagesCubit(this._repository) : super(const WalletPackagesState());

  final WalletRepository _repository;

  Future<void> fetchPackages({bool forceRefresh = false}) async {
    if (state.status == WalletPackagesStatus.loading && !forceRefresh) {
      return;
    }

    emit(
      state.copyWith(
        status: WalletPackagesStatus.loading,
        clearError: true,
        clearPurchaseError: true,
        clearPurchaseResult: true,
      ),
    );

    try {
      final packages = await _repository.fetchPackages();
      emit(
        state.copyWith(
          status: WalletPackagesStatus.success,
          packages: List<WalletPackage>.unmodifiable(packages),
          purchasingPackageId: null,
          purchaseStatus: WalletPackagePurchaseStatus.idle,
          clearPurchaseError: true,
          clearPurchaseResult: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: WalletPackagesStatus.failure,
          errorMessage: _mapErrorMessage(error),
          purchasingPackageId: null,
          purchaseStatus: WalletPackagePurchaseStatus.idle,
        ),
      );
    }
  }

  Future<WalletActionResult?> purchasePackage(int packageId) async {
    emit(
      state.copyWith(
        purchaseStatus: WalletPackagePurchaseStatus.inProgress,
        purchasingPackageId: packageId,
        clearPurchaseError: true,
        clearPurchaseResult: true,
      ),
    );

    try {
      final result = await _repository.purchasePackage(packageId: packageId);
      final status = result.success
          ? WalletPackagePurchaseStatus.success
          : WalletPackagePurchaseStatus.failure;
      emit(
        state.copyWith(
          purchaseStatus: status,
          lastPurchaseResult: result,
          purchaseError: result.success ? null : result.message,
          purchasingPackageId: packageId,
        ),
      );
      return result;
    } catch (error) {
      emit(
        state.copyWith(
          purchaseStatus: WalletPackagePurchaseStatus.failure,
          purchaseError: _mapErrorMessage(error),
          purchasingPackageId: packageId,
        ),
      );
      return null;
    }
  }

  String _mapErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }

  void resetPurchaseStatus() {
    emit(
      state.copyWith(
        purchaseStatus: WalletPackagePurchaseStatus.idle,
        purchasingPackageId: null,
        clearPurchaseError: true,
        clearPurchaseResult: true,
      ),
    );
  }
}

class WalletPackagesState extends Equatable {
  const WalletPackagesState({
    this.status = WalletPackagesStatus.initial,
    this.packages = const [],
    this.errorMessage,
    this.purchaseStatus = WalletPackagePurchaseStatus.idle,
    this.purchaseError,
    this.lastPurchaseResult,
    this.purchasingPackageId,
  });

  final WalletPackagesStatus status;
  final List<WalletPackage> packages;
  final String? errorMessage;
  final WalletPackagePurchaseStatus purchaseStatus;
  final String? purchaseError;
  final WalletActionResult? lastPurchaseResult;
  final int? purchasingPackageId;

  bool get isLoading => status == WalletPackagesStatus.loading;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  bool get hasPackages => packages.isNotEmpty;

  WalletPackagesState copyWith({
    WalletPackagesStatus? status,
    List<WalletPackage>? packages,
    String? errorMessage,
    WalletPackagePurchaseStatus? purchaseStatus,
    String? purchaseError,
    WalletActionResult? lastPurchaseResult,
    int? purchasingPackageId,
    bool clearError = false,
    bool clearPurchaseError = false,
    bool clearPurchaseResult = false,
  }) {
    return WalletPackagesState(
      status: status ?? this.status,
      packages: packages != null
          ? List<WalletPackage>.unmodifiable(packages)
          : this.packages,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      purchaseStatus: purchaseStatus ?? this.purchaseStatus,
      purchaseError: clearPurchaseError
          ? null
          : purchaseError ?? this.purchaseError,
      lastPurchaseResult: clearPurchaseResult
          ? null
          : lastPurchaseResult ?? this.lastPurchaseResult,
      purchasingPackageId: purchasingPackageId ?? this.purchasingPackageId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    packages,
    errorMessage,
    purchaseStatus,
    purchaseError,
    lastPurchaseResult,
    purchasingPackageId,
  ];
}

enum WalletPackagesStatus { initial, loading, success, failure }

enum WalletPackagePurchaseStatus { idle, inProgress, success, failure }
