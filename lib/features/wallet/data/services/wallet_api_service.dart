import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/main.dart' show configCfgP;

import '../models/wallet_action_result.dart';
import '../models/wallet_paginated.dart';
import '../models/wallet_package.dart';
import '../models/wallet_payment.dart';
import '../models/wallet_summary.dart';
import '../models/wallet_transaction.dart';

class WalletApiService {
  WalletApiService(this._client);

  final ApiClient _client;

  Future<WalletSummary> fetchSummary() async {
    final response = await _client.get(configCfgP('wallet_base'));
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return WalletSummary.fromJson(data);
    }
    return WalletSummary.fromJson(const {});
  }

  Future<WalletPaginatedResult<WalletTransaction>> fetchTransactions({
    int offset = 0,
    int limit = 20,
  }) async {
    final response = await _client.get(
      configCfgP('wallet_transactions'),
      queryParameters: {'offset': offset.toString(), 'limit': limit.toString()},
    );
    return WalletPaginatedResult.fromJson<WalletTransaction>(
      response,
      itemsKey: 'transactions',
      itemBuilder: (json) => WalletTransaction.fromJson(json),
    );
  }

  Future<WalletPaginatedResult<WalletPayment>> fetchPayments({
    int offset = 0,
    int limit = 20,
  }) async {
    final response = await _client.get(
      configCfgP('wallet_payments'),
      queryParameters: {'offset': offset.toString(), 'limit': limit.toString()},
    );
    return WalletPaginatedResult.fromJson<WalletPayment>(
      response,
      itemsKey: 'payments',
      itemBuilder: (json) => WalletPayment.fromJson(json),
    );
  }

  Future<WalletActionResult> transfer({
    required int userId,
    required double amount,
  }) async {
    final response = await _client.post(
      configCfgP('wallet_transfer'),
      body: {'user_id': userId, 'amount': amount},
    );
    return WalletActionResult.fromResponse(response);
  }

  Future<WalletActionResult> sendTip({
    required int userId,
    required double amount,
  }) async {
    final response = await _client.post(
      configCfgP('wallet_tip'),
      body: {'user_id': userId, 'amount': amount},
    );
    return WalletActionResult.fromResponse(response);
  }

  Future<WalletActionResult> withdraw({
    required String source,
    required double amount,
  }) async {
    final response = await _client.post(
      configCfgP('wallet_withdraw'),
      body: {'source': source, 'amount': amount},
    );
    return WalletActionResult.fromResponse(response);
  }

  Future<WalletActionResult> recharge({
    required double amount,
    String? method,
    String? reference,
    String? note,
  }) async {
    final body = <String, dynamic>{'amount': amount};
    if (method != null && method.isNotEmpty) {
      body['method'] = method;
    }
    if (reference != null && reference.isNotEmpty) {
      body['reference'] = reference;
    }
    if (note != null && note.isNotEmpty) {
      body['note'] = note;
    }

    final response = await _client.post(configCfgP('wallet_recharge'), body: body);
    return WalletActionResult.fromResponse(response);
  }

  Future<List<WalletPackage>> fetchPackages() async {
    Map<String, dynamic> response;

    try {
      response = await _client.get(configCfgP('wallet_packages'));
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        // Older API builds expose membership packages at `/data/packages`.
        response = await _client.get(configCfgP('packages_legacy'));
      } else {
        rethrow;
      }
    }

    final data = response['data'] ?? response;
    final packagesData = _extractPackages(data);
    return packagesData
        .whereType<Map<String, dynamic>>()
        .map(WalletPackage.fromJson)
        .toList(growable: false);
  }

  Future<WalletActionResult> purchasePackage({required int packageId}) async {
    final response = await _client.post(
      configCfgP('wallet_packages_purchase'),
      body: {'package_id': packageId, 'id': packageId},
    );
    return WalletActionResult.fromResponse(response);
  }
}

List<dynamic> _extractPackages(Object? data) {
  if (data is List) {
    return data;
  }
  if (data is Map<String, dynamic>) {
    for (final key in ['packages', 'data', 'items', 'results']) {
      final value = data[key];
      if (value is List) {
        return value;
      }
    }
  }
  return const [];
}
