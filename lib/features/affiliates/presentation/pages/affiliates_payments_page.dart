import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:snginepro/features/affiliates/data/models/affiliate_payment.dart';
import 'package:snginepro/features/affiliates/data/models/affiliates_settings.dart';
import 'package:snginepro/features/affiliates/data/services/affiliates_api_service.dart';
import '../../../../main.dart' show globalApiClient;

class AffiliatesPaymentsPage extends StatefulWidget {
  const AffiliatesPaymentsPage({Key? key}) : super(key: key);

  @override
  State<AffiliatesPaymentsPage> createState() => _AffiliatesPaymentsPageState();
}

class _AffiliatesPaymentsPageState extends State<AffiliatesPaymentsPage> {
  late final AffiliatesApiService _apiService;
  late Future<AffiliatesSettings?> _settingsFuture;
  late Future<List<AffiliatePayment>> _paymentsFuture;

  final _amountController = TextEditingController();
  final _transferToController = TextEditingController();
  String _selectedPaymentMethod = 'paypal';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _apiService = AffiliatesApiService(globalApiClient);
    _settingsFuture = _loadSettings();
    _paymentsFuture = _loadPayments();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transferToController.dispose();
    super.dispose();
  }

  Future<AffiliatesSettings?> _loadSettings() async {
    final response = await _apiService.getSettings();
    if (response['success'] == true) {
      return AffiliatesSettings.fromJson(response['data']);
    }
    return null;
  }

  Future<List<AffiliatePayment>> _loadPayments() async {
    final response = await _apiService.getPayments();
    if (response['success'] == true) {
      final data = response['data'];
      if (data is List) {
        return data.map((e) => AffiliatePayment.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<void> _submitWithdrawalRequest() async {
    // Validate amount
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('please_enter_amount'.tr)));
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 50) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('minimum_withdrawal_50'.tr)));
      return;
    }

    if (_transferToController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('please_enter_transfer'.tr)));
      return;
    }

    setState(() => _isSubmitting = true);
    // TODO: Call API to submit withdrawal request
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('withdrawal_request_submitted'.tr)),
      );
      _amountController.clear();
      _transferToController.clear();
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _settingsFuture = _loadSettings();
      _paymentsFuture = _loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('affiliates'.tr),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Your Balance Card
            FutureBuilder<AffiliatesSettings?>(
              future: _settingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final settings = snapshot.data;
                final balance = settings?.userAffiliateBalance ?? 0.0;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6C63FF).withOpacity(0.9),
                        const Color(0xFF8E7FFF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'your_balance'.tr,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (settings != null)
                        Text(
                          '${'currency'.tr}: ${settings.currency}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Withdrawal Request Section
            Text(
              'withdrawal_request'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'amount_usd'.tr,
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'minimum_withdrawal_amount'.tr,
              style: TextStyle(fontSize: 12, color: Colors.orange[700]),
            ),
            const SizedBox(height: 16),

            // Payment Method Selection
            Text(
              'payment_method'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['paypal', 'skrill', 'moneypools', 'cash'].map((
                method,
              ) {
                final label = method.replaceFirst(
                  method[0],
                  method[0].toUpperCase(),
                );
                return FilterChip(
                  label: Text(label),
                  selected: _selectedPaymentMethod == method,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedPaymentMethod = method);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Transfer To Field
            TextField(
              controller: _transferToController,
              decoration: InputDecoration(
                labelText: 'transfer_to'.tr,
                hintText: 'transfer_to_hint'.tr,
                prefixIcon: const Icon(Icons.account_box),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitWithdrawalRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF6C63FF),
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'request_withdrawal'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Withdrawal History Section
            Text(
              'withdrawal_history'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            FutureBuilder<List<AffiliatePayment>>(
              future: _paymentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final payments = snapshot.data ?? [];

                if (payments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'no_transactions_yet'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    return _buildPaymentCard(payments[index], index);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(AffiliatePayment payment, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${payment.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: #${payment.paymentId}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(payment.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailColumn('method'.tr, payment.methodText),
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      'date'.tr,
                      DateFormat(
                        'dd MMM yyyy',
                        'en',
                      ).format(DateTime.parse(payment.time)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'paid':
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        label = 'paid'.tr;
        break;
      case 'pending':
        backgroundColor = Colors.orange;
        icon = Icons.access_time;
        label = 'pending'.tr;
        break;
      case 'declined':
        backgroundColor = Colors.red;
        icon = Icons.cancel;
        label = 'declined'.tr;
        break;
      default:
        backgroundColor = Colors.grey;
        icon = Icons.info;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: backgroundColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: backgroundColor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: backgroundColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
