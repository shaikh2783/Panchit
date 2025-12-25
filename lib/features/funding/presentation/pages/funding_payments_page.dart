import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/funding/data/models/funding_payment.dart';
import 'package:snginepro/features/funding/data/models/funding_settings.dart';
import 'package:snginepro/features/funding/data/services/funding_settings_api_service.dart';
import '../../../../main.dart' show globalApiClient;

class FundingPaymentsPage extends StatefulWidget {
  const FundingPaymentsPage({Key? key}) : super(key: key);

  @override
  State<FundingPaymentsPage> createState() => _FundingPaymentsPageState();
}

class _FundingPaymentsPageState extends State<FundingPaymentsPage> {
  late final FundingSettingsApiService _apiService;
  late Future<Map<String, dynamic>> _settingsFuture;
  late Future<Map<String, dynamic>> _paymentsFuture;

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _apiService = FundingSettingsApiService(globalApiClient);
    _settingsFuture = _apiService.getSettings();
    _paymentsFuture = _apiService.getPayments();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitWithdrawal(FundingSettings settings) async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      _showSnack('Enter a valid amount', isError: true);
      return;
    }
    if (amount < settings.minWithdrawal) {
      _showSnack('Minimum withdrawal is ${settings.currency} ${settings.minWithdrawal.toStringAsFixed(2)}', isError: true);
      return;
    }
    if (amount > settings.userFundingBalance) {
      _showSnack('Amount exceeds available balance', isError: true);
      return;
    }
    if (_selectedMethod == null) {
      _showSnack('Select a payment method', isError: true);
      return;
    }

    final response = await _apiService.submitWithdrawal(
      amount: amount,
      method: _selectedMethod!,
      methodValue: _notesController.text.trim(),
      bankDetails:
          _selectedMethod == 'bank' ? _notesController.text.trim() : null,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      _showSnack(response['message'] ?? 'Withdrawal request submitted');
      setState(() {
        _paymentsFuture = _apiService.getPayments();
      });
    } else {
      _showSnack(response['message'] ?? 'Request failed', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('withdraw_funds_title'.tr),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data?['success'] != true) {
            return const Center(child: Text('Unable to load funding settings'));
          }
          final settings = snapshot.data!['data'] as FundingSettings;
          _selectedMethod ??= settings.paymentMethods.isNotEmpty ? settings.paymentMethods.first : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildBalanceHeader(settings),
              const SizedBox(height: 16),
              _buildForm(settings),
              const SizedBox(height: 24),
              _buildHistory(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceHeader(FundingSettings settings) {
    final canWithdraw = settings.canWithdrawMoney;
    final color = canWithdraw ? const Color(0xFF8E24AA) : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Iconsax.wallet, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available',
                    style: TextStyle(
                      color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  Text(
                    '${settings.currency} ${settings.userFundingBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Get.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Min withdraw',
                    style: TextStyle(
                      fontSize: 12,
                      color: Get.isDarkMode ? Colors.grey[500] : Colors.grey[700],
                    ),
                  ),
                  Text(
                    '${settings.currency} ${settings.minWithdrawal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!canWithdraw)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'You need at least ${settings.currency} ${settings.minWithdrawal.toStringAsFixed(2)} to withdraw',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[400],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm(FundingSettings settings) {
    final enabled = settings.canWithdrawMoney;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Withdrawal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: enabled,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '${settings.currency} ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        _buildMethodSelector(settings.paymentMethods, enabled),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          enabled: enabled,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Payment details / notes',
            hintText: 'Account or email to receive payment',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: enabled ? () => _submitWithdrawal(settings) : null,
            icon: const Icon(Iconsax.send_2),
            label: Text('submit_request_button'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8E24AA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodSelector(List<String> methods, bool enabled) {
    if (methods.isEmpty) {
      return Text(
        'No payment methods configured',
        style: TextStyle(color: Colors.red[400]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 13,
            color: Get.isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: methods.map((method) {
            final selected = _selectedMethod == method;
            return ChoiceChip(
              label: Text(method.toUpperCase()),
              selected: selected,
              onSelected: enabled
                  ? (_) {
                      setState(() {
                        _selectedMethod = method;
                      });
                    }
                  : null,
              selectedColor: const Color(0xFF8E24AA).withOpacity(0.15),
              labelStyle: TextStyle(
                color: selected ? const Color(0xFF8E24AA) : (Get.isDarkMode ? Colors.white : Colors.black87),
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Get.isDarkMode ? Colors.grey[850] : Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: selected ? const Color(0xFF8E24AA) : Colors.grey.withOpacity(0.3),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
          future: _paymentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data?['success'] != true) {
              return Center(child: Text('unable_to_load_history'.tr));
            }
            final payments = snapshot.data!['data'] as List<FundingPayment>;
            if (payments.isEmpty) {
              return Center(child: Text('no_payments_yet'.tr));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _buildPaymentTile(payment);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentTile(FundingPayment payment) {
    final color = switch (payment.status) {
      FundingPaymentStatus.approved => const Color(0xFF43A047),
      FundingPaymentStatus.pending => const Color(0xFFFFA000),
      FundingPaymentStatus.declined => Colors.red,
    };
    final methodLabel = payment.methodDisplay ?? payment.method.toUpperCase();
    final subtitle = payment.time.isNotEmpty
        ? '${payment.time} · ${payment.methodValue}'
        : payment.methodValue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.note_1, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  methodLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Get.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Get.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment.status.statusText.toUpperCase(),
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
