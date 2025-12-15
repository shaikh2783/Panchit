import 'package:flutter/material.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:snginepro/App_Settings.dart';
class PayPalPaymentHandler {
  /// Process a PayPal payment.
  /// Adjusted to accept dynamic map to avoid runtime type casting errors
  /// from the flutter_paypal_payment package returning Map<dynamic, dynamic>.
  static Future<void> processPayment({
    required BuildContext context,
    required double amount,
    required String currency,
    required String description,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
    required VoidCallback onCancel,
  }) async {
    // Validate configuration first
    final configError = AppSettings.validatePayPalConfig();
    if (configError != null) {
      onError(configError);
      return;
    }
    // Debug credential info (masked)
    final clientId = AppSettings.paypalClientId;
    final secret = AppSettings.paypalSecretKey;
    
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => PaypalCheckoutView(
            sandboxMode: AppSettings.paypalUseSandbox,
            clientId: clientId,
            secretKey: secret,
            transactions: [
              {
                "amount": {
                  "total": amount.toStringAsFixed(2),
                  "currency": currency,
                  "details": {
                    "subtotal": amount.toStringAsFixed(2),
                    "shipping": '0',
                    "shipping_discount": 0,
                  },
                },
                "description": description,
                "item_list": {
                  "items": [
                    {
                      "name": "Wallet Recharge",
                      "quantity": 1,
                      "price": amount.toStringAsFixed(2),
                      "currency": currency,
                    },
                  ],
                },
              },
            ],
            note: "Contact us for any questions on your order.",
            onSuccess: (dynamic params) async {
              // params can be Map<dynamic,dynamic>; normalize safely
              try {
                final normalized = (params is Map)
                    ? params.map((k, v) => MapEntry(k.toString(), v))
                    : <String, dynamic>{};
                onSuccess(normalized);
              } catch (e) {
                onError('Failed to process PayPal response');
              }
            },
            onError: (error) {
              onError(error.toString());
            },
            onCancel: () {
              onCancel();
            },
          ),
        ),
      );
    } catch (e) {
      onError('Failed to start PayPal checkout: $e');
    }
  }
  static String extractTransactionId(Map<String, dynamic> params) {
    try {
      // Extract transaction ID from PayPal response
      if (params.containsKey('data')) {
        final data = params['data'];
        if (data is Map && data.containsKey('id')) {
          return data['id'].toString();
        }
      }
      if (params.containsKey('id')) {
        return params['id'].toString();
      }
      return '';
    } catch (e) {
      return '';
    }
  }
  static String extractPayerId(Map<String, dynamic> params) {
    try {
      if (params.containsKey('data')) {
        final data = params['data'];
        if (data is Map && data.containsKey('payer')) {
          final payer = data['payer'];
          if (payer is Map && payer.containsKey('payer_info')) {
            final payerInfo = payer['payer_info'];
            if (payerInfo is Map && payerInfo.containsKey('payer_id')) {
              return payerInfo['payer_id'].toString();
            }
          }
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}
