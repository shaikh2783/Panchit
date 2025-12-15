import '../data/models/wallet_action_result.dart';
import '../data/models/wallet_paginated.dart';
import '../data/models/wallet_package.dart';
import '../data/models/wallet_payment.dart';
import '../data/models/wallet_summary.dart';
import '../data/models/wallet_transaction.dart';
import '../data/services/wallet_api_service.dart';
class WalletRepository {
  WalletRepository(this._apiService);
  final WalletApiService _apiService;
  Future<WalletSummary> fetchSummary() {
    return _apiService.fetchSummary();
  }
  Future<WalletPaginatedResult<WalletTransaction>> fetchTransactions({
    int offset = 0,
    int limit = 20,
  }) {
    return _apiService.fetchTransactions(offset: offset, limit: limit);
  }
  Future<WalletPaginatedResult<WalletPayment>> fetchPayments({
    int offset = 0,
    int limit = 20,
  }) {
    return _apiService.fetchPayments(offset: offset, limit: limit);
  }
  Future<List<WalletPackage>> fetchPackages() {
    return _apiService.fetchPackages();
  }
  Future<WalletActionResult> transfer({
    required int userId,
    required double amount,
  }) {
    return _apiService.transfer(userId: userId, amount: amount);
  }
  Future<WalletActionResult> sendTip({
    required int userId,
    required double amount,
  }) {
    return _apiService.sendTip(userId: userId, amount: amount);
  }
  Future<WalletActionResult> withdraw({
    required String source,
    required double amount,
  }) {
    return _apiService.withdraw(source: source, amount: amount);
  }
  Future<WalletActionResult> recharge({
    required double amount,
    String? method,
    String? reference,
    String? note,
  }) {
    return _apiService.recharge(
      amount: amount,
      method: method,
      reference: reference,
      note: note,
    );
  }
  Future<WalletActionResult> purchasePackage({required int packageId}) {
    return _apiService.purchasePackage(packageId: packageId);
  }
}
