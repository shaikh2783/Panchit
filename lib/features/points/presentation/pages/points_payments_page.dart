import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:snginepro/features/points/data/models/points_payment.dart';
import 'package:snginepro/features/points/data/services/points_api_service.dart';
import '../../../../main.dart' show globalApiClient;

class PointsPaymentsPage extends StatefulWidget {
  const PointsPaymentsPage({Key? key}) : super(key: key);

  @override
  State<PointsPaymentsPage> createState() => _PointsPaymentsPageState();
}

class _PointsPaymentsPageState extends State<PointsPaymentsPage> {
  late final PointsApiService _apiService;
  late Future<Map<String, dynamic>> _settingsFuture;
  late Future<List<PointsPayment>> _paymentsFuture;

  final _amountController = TextEditingController();
  final _transferToController = TextEditingController();
  String _selectedPaymentMethod = 'paypal';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _apiService = PointsApiService(globalApiClient);
    _settingsFuture = _loadSettings();
    _paymentsFuture = _loadPayments();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transferToController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    final response = await _apiService.getSettings();
    if (response['success'] == true) {
      return response;
    }
    return {'success': false};
  }

  Future<List<PointsPayment>> _loadPayments() async {
    final response = await _apiService.getPayments();
    if (response['success'] == true) {
      return response['data'] as List<PointsPayment>;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('minimum_withdrawal_amount_50'.tr)),
      );
      return;
    }

    if (_transferToController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_enter_transfer_details'.tr)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final response = await _apiService.submitWithdrawal(
      amount: amount,
      method: _selectedPaymentMethod,
      methodValue: _transferToController.text,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'request_submitted'.tr),
          ),
        );
        _amountController.clear();
        _transferToController.clear();
        setState(() {
          _paymentsFuture = _loadPayments();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'failed_to_submit_request'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: Text('points'.tr),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Your Balance Card
            FutureBuilder<Map<String, dynamic>>(
              future: _settingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final data = snapshot.data?['data'];
                final balance = data?['money_balance'] ?? 0.0;
                final minWithdraw = data?['min_withdrawal'] ?? 50.0;

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
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${double.tryParse(balance.toString())?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'minimum_withdrawal'.tr}: \$${minWithdraw.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
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
              style: TextStyle(
                color: Get.isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'amount_usd'.tr,
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Get.isDarkMode
                        ? Colors.grey[700]!
                        : Colors.grey[300]!,
                  ),
                ),
                fillColor: Get.isDarkMode ? Colors.grey[800] : Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'minimum_withdrawal_request_info'.tr,
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
              children: ['paypal', 'skrill'].map((method) {
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
              style: TextStyle(
                color: Get.isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'transfer_to'.tr,
                hintText: 'enter_payment_details'.tr,
                prefixIcon: const Icon(Icons.account_box),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Get.isDarkMode
                        ? Colors.grey[700]!
                        : Colors.grey[300]!,
                  ),
                ),
                fillColor: Get.isDarkMode ? Colors.grey[800] : Colors.white,
                filled: true,
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

            FutureBuilder<List<PointsPayment>>(
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
                            'no_withdrawals_yet'.tr,
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

  Widget _buildPaymentCard(PointsPayment payment, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: Get.isDarkMode ? 2 : 1,
        color: Get.isDarkMode ? Colors.grey[800] : Colors.white,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Get.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'id'.tr}: #${payment.paymentId}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Get.isDarkMode
                                ? Colors.grey[500]
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(payment.status),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: Get.isDarkMode ? Colors.grey[700] : Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailColumn(
                      'method'.tr,
                      payment.methodDisplay,
                    ),
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

    switch (status) {
      case '1':
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        label = 'paid'.tr;
        break;
      case '0':
        backgroundColor = Colors.orange;
        icon = Icons.access_time;
        label = 'pending'.tr;
        break;
      case '-1':
        backgroundColor = Colors.red;
        icon = Icons.cancel;
        label = 'declined'.tr;
        break;
      default:
        backgroundColor = Colors.grey;
        icon = Icons.info;
        label = 'unknown'.tr;
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
          style: TextStyle(
            fontSize: 10,
            color: Get.isDarkMode ? Colors.grey[500] : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
