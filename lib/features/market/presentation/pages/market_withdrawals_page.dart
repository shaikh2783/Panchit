import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/market/data/models/market_settings.dart';
import 'package:snginepro/features/market/data/models/market_payment.dart';
import 'package:snginepro/features/market/data/services/market_settings_api_service.dart';
import '../../../../main.dart' show globalApiClient;

class MarketWithdrawalsPage extends StatefulWidget {
  const MarketWithdrawalsPage({Key? key}) : super(key: key);

  @override
  State<MarketWithdrawalsPage> createState() => _MarketWithdrawalsPageState();
}

class _MarketWithdrawalsPageState extends State<MarketWithdrawalsPage>
    with SingleTickerProviderStateMixin {
  late final MarketSettingsApiService _apiService;
  late Future<Map<String, dynamic>> _settingsFuture;
  late Future<Map<String, dynamic>> _paymentsFuture;
  late TabController _tabController;

  final _amountController = TextEditingController();
  final _emailController = TextEditingController();
  final _bankDetailsController = TextEditingController();
  String _selectedMethod = 'paypal';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _apiService = MarketSettingsApiService(globalApiClient);
    _settingsFuture = _loadSettings();
    _paymentsFuture = _loadPayments();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _emailController.dispose();
    _bankDetailsController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    return await _apiService.getSettings();
  }

  Future<Map<String, dynamic>> _loadPayments() async {
    return await _apiService.getPayments();
  }

  Future<void> _refreshData() async {
    setState(() {
      _settingsFuture = _loadSettings();
      _paymentsFuture = _loadPayments();
    });
  }

  Future<void> _submitWithdrawal(MarketSettings settings) async {
    final amount = double.tryParse(_amountController.text) ?? 0;

    // Validation
    if (amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (amount < settings.minWithdrawal) {
      _showError('Minimum withdrawal is ${settings.currency} ${settings.minWithdrawal}');
      return;
    }

    if (amount > settings.userMarketBalance) {
      _showError('Insufficient balance');
      return;
    }

    if (_emailController.text.isEmpty && ['paypal', 'skrill'].contains(_selectedMethod)) {
      _showError('Please enter email for $_selectedMethod');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _apiService.submitWithdrawal(
        amount: amount,
        method: _selectedMethod,
        methodValue: _emailController.text.isNotEmpty
            ? _emailController.text
            : '',
        bankDetails: _bankDetailsController.text.isNotEmpty
            ? _bankDetailsController.text
            : null,
      );

      if (result['success'] == true) {
        _showSuccess(result['message'] ?? 'Withdrawal request submitted');
        _clearForm();
        _refreshData();
      } else {
        _showError(result['message'] ?? 'Withdrawal failed');
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _amountController.clear();
    _emailController.clear();
    _bankDetailsController.clear();
    _selectedMethod = 'paypal';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('market_withdrawals_title'.tr),
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Withdraw'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Withdraw Tab
          _buildWithdrawTab(),
          // History Tab
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildWithdrawTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _settingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data?['success'] != true) {
              return _buildErrorCard('Failed to load settings');
            }

            final settings = snapshot.data!['data'] as MarketSettings;

            if (!settings.marketMoneyWithdrawEnabled) {
              return _buildDisabledCard('Withdrawals are not enabled for your account');
            }

            if (!settings.canWithdraw) {
              return _buildDisabledCard('You do not have permission to withdraw');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                _buildBalanceCard(settings),
                const SizedBox(height: 24),

                // Withdrawal Form
                _buildWithdrawalForm(settings),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWithdrawTab_() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _settingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data?['success'] != true) {
              return _buildErrorCard('Failed to load settings');
            }

            final settings = snapshot.data!['data'] as MarketSettings;

            if (!settings.marketMoneyWithdrawEnabled) {
              return _buildDisabledCard('Withdrawals are not enabled for your account');
            }

            if (!settings.canWithdraw) {
              return _buildDisabledCard('You do not have permission to withdraw');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                _buildBalanceCard(settings),
                const SizedBox(height: 24),

                // Withdrawal Form
                _buildWithdrawalForm(settings),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?['success'] != true) {
            return _buildErrorCard('Failed to load payment history');
          }

          final payments = snapshot.data!['data'] as List<MarketPayment>;

          if (payments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.receipt,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No withdrawal history',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentTile(payment);
            },
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(MarketSettings settings) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4CAF50),
            Color.lerp(const Color(0xFF4CAF50), Colors.black, 0.15)!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${settings.currency} ${settings.userMarketBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Minimum: ${settings.currency} ${settings.minWithdrawal.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalForm(MarketSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Withdrawal Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Amount
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount (${settings.currency})',
            hintText: 'Enter amount to withdraw',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Iconsax.money),
          ),
        ),
        const SizedBox(height: 16),

        // Payment Method
        Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: settings.paymentMethods
              .map((method) => ChoiceChip(
                    label: Text(_getMethodLabel(method)),
                    selected: _selectedMethod == method,
                    onSelected: (selected) {
                      setState(() => _selectedMethod = method);
                      _emailController.clear();
                      _bankDetailsController.clear();
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),

        // Email/Account
        if (['paypal', 'skrill', 'stripe'].contains(_selectedMethod))
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: _getEmailLabel(_selectedMethod),
              hintText: 'Enter your $_selectedMethod email',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Iconsax.sms),
            ),
          ),
        if (['bank'].contains(_selectedMethod)) ...[
          TextField(
            controller: _bankDetailsController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Bank Details',
              hintText: 'IBAN / Account Number\nBank Name\nHolders Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Iconsax.building),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (['custom'].contains(_selectedMethod)) ...[
          TextField(
            controller: _bankDetailsController,
            decoration: InputDecoration(
              labelText: 'Account Details',
              hintText: 'Enter your account information',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Iconsax.note),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : () => _submitWithdrawal(settings),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Iconsax.arrow_up_3),
            label: Text(_isSubmitting ? 'Processing...' : 'Request Withdrawal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.info_circle, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Withdrawals are processed within 3-5 business days',
                  style: TextStyle(
                    fontSize: 12,
                    color: Get.isDarkMode ? Colors.blue[300] : Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTile(MarketPayment payment) {
    final statusColor = payment.status == PaymentStatus.approved
        ? Colors.green
        : payment.status == PaymentStatus.pending
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.08),
            statusColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.15), width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMethodIcon(payment.method),
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.methodDisplay ??
                          payment.method.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Get.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payment.methodValue,
                      style: TextStyle(
                        fontSize: 11,
                        color: Get.isDarkMode ? Colors.grey[500] : Colors.grey[600],
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
                      fontSize: 13,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      payment.status.statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMM dd, yyyy hh:mm a').format(
              DateTime.parse(payment.time),
            ),
            style: TextStyle(
              fontSize: 10,
              color: Get.isDarkMode ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.warning_2, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledCard(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Iconsax.lock_1,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMethodLabel(String method) {
    switch (method) {
      case 'paypal':
        return 'PayPal';
      case 'skrill':
        return 'Skrill';
      case 'bank':
        return 'Bank';
      case 'stripe':
        return 'Stripe';
      case 'custom':
        return 'Custom';
      default:
        return method;
    }
  }

  String _getEmailLabel(String method) {
    switch (method) {
      case 'paypal':
        return 'PayPal Email';
      case 'skrill':
        return 'Skrill Email';
      case 'stripe':
        return 'Stripe Email';
      default:
        return 'Email';
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'paypal':
        return Iconsax.card;
      case 'skrill':
        return Iconsax.wallet;
      case 'bank':
        return Iconsax.building;
      case 'stripe':
        return Iconsax.card;
      case 'custom':
        return Iconsax.money;
      default:
        return Iconsax.wallet;
    }
  }
}
