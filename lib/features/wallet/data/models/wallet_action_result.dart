import 'package:equatable/equatable.dart';
class WalletActionResult extends Equatable {
  const WalletActionResult({
    required this.success,
    required this.message,
    this.amount,
    this.amountFormatted,
    this.currency,
    this.balance,
    this.balanceFormatted,
    this.payload,
  });
  final bool success;
  final String message;
  final double? amount;
  final String? amountFormatted;
  final String? currency;
  final double? balance;
  final String? balanceFormatted;
  final Map<String, dynamic>? payload;
  factory WalletActionResult.fromResponse(Map<String, dynamic> response) {
    final status = response['status']?.toString().toLowerCase() == 'success';
    final message = response['message']?.toString() ?? '';
    final data = response['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return WalletActionResult(
      success: status,
      message: message,
      amount: _toNullableDouble(map['amount']),
      amountFormatted: map['amount_formatted']?.toString(),
      currency: map['currency']?.toString(),
      balance: _toNullableDouble(map['balance']),
      balanceFormatted: map['balance_formatted']?.toString(),
      payload: map.isEmpty ? null : map,
    );
  }
  @override
  List<Object?> get props => [
    success,
    message,
    amount,
    amountFormatted,
    currency,
    balance,
    balanceFormatted,
    payload,
  ];
}
double? _toNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}
