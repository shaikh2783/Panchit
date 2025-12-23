import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/market/data/models/market_settings.dart';
import 'package:snginepro/features/market/data/models/market_stats.dart';
import 'package:snginepro/features/market/data/services/market_settings_api_service.dart';
import '../../../../main.dart' show globalApiClient;
import 'market_withdrawals_page.dart';

class MarketSettingsPage extends StatefulWidget {
  const MarketSettingsPage({Key? key}) : super(key: key);

  @override
  State<MarketSettingsPage> createState() => _MarketSettingsPageState();
}

class _MarketSettingsPageState extends State<MarketSettingsPage> {
  late final MarketSettingsApiService _apiService;
  late Future<Map<String, dynamic>> _settingsFuture;
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _apiService = MarketSettingsApiService(globalApiClient);
    _settingsFuture = _loadSettings();
    _statsFuture = _loadStats();
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    final response = await _apiService.getSettings();
    return response;
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final response = await _apiService.getStats();
    return response;
  }

  Future<void> _refreshData() async {
    setState(() {
      _settingsFuture = _loadSettings();
      _statsFuture = _loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'market_settings'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Main Balance Card
            FutureBuilder<Map<String, dynamic>>(
              future: _settingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data?['success'] != true) {
                  return _buildErrorCard('Failed to load settings');
                }

                final settings = snapshot.data!['data'] as MarketSettings;

                // Check permissions
                if (!settings.marketEnabled || !settings.canSellProducts) {
                  return _buildDisabledCard();
                }

                return Column(
                  children: [
                    // Balance Card
                    _buildBalanceCard(settings),
                    const SizedBox(height: 16),

                    // Quick Actions
                    if (settings.canWithdrawMoney) _buildQuickActions(settings),
                    const SizedBox(height: 16),

                    // Payment Methods
                    _buildPaymentMethods(settings),
                    const SizedBox(height: 16),

                    // Stats
                    FutureBuilder<Map<String, dynamic>>(
                      future: _statsFuture,
                      builder: (context, statSnapshot) {
                        if (statSnapshot.data?['success'] != true) {
                          return const SizedBox.shrink();
                        }
                        final stats = statSnapshot.data!['data'] as MarketStats;
                        return _buildStats(stats, settings.currency);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(MarketSettings settings) {
    final canWithdraw = settings.canWithdrawMoney;
    final color = canWithdraw
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF9800);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.15)!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'market_balance'.tr,
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
          const SizedBox(height: 16),
          Text(
            '${settings.currency} ${settings.userMarketBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            canWithdraw
                ? 'ready_to_withdraw'.tr
                : '${'need_more'.tr} \$${(settings.minWithdrawal - settings.userMarketBalance).toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          if (settings.canTransferToWallet) ...[
            const SizedBox(height: 12),
            Text(
              'can_transfer_to_wallet'.tr,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(MarketSettings settings) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarketWithdrawalsPage(),
                ),
              );
            },
            icon: const Icon(Iconsax.arrow_up_3),
            label: Text('withdraw'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (settings.canTransferToWallet)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showTransferDialog(settings);
              },
              icon: const Icon(Iconsax.repeat),
              label: Text('transfer'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentMethods(MarketSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'payment_methods'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: settings.paymentMethods
              .map((method) => _buildMethodChip(method))
              .toList(),
        ),
        if (settings.paymentMethodCustom != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.info_circle, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${'custom'.tr}: ${settings.paymentMethodCustom}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Get.isDarkMode
                          ? Colors.grey[300]
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMethodChip(String method) {
    final methodNames = {
      'paypal': ('paypal'.tr, Color(0xFF003087)),
      'skrill': ('skrill'.tr, Color(0xFF3D9970)),
      'bank': ('bank_transfer'.tr, Color(0xFF1E3A8A)),
      'stripe': ('stripe'.tr, Color(0xFF635BFF)),
      'custom': ('custom'.tr, Color(0xFF6366F1)),
    };

    final info =
        methodNames[method] ?? (method.toUpperCase(), Color(0xFF6B7280));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: info.$2.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.$2.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getMethodIcon(method), size: 14, color: info.$2),
          const SizedBox(width: 6),
          Text(
            info.$1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: info.$2,
            ),
          ),
        ],
      ),
    );
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
      default:
        return Iconsax.money;
    }
  }

  Widget _buildStats(MarketStats stats, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'statistics'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatTile(
              label: 'total_earned'.tr,
              value: '$currency ${stats.totalEarned.toStringAsFixed(2)}',
              color: Colors.green,
              icon: Iconsax.arrow_up_3,
            ),
            _buildStatTile(
              label: 'total_paid'.tr,
              value: '$currency ${stats.totalPaid.toStringAsFixed(2)}',
              color: Colors.blue,
              icon: Iconsax.arrow_up_3,
            ),
            _buildStatTile(
              label: 'pending'.tr,
              value: '$currency ${stats.totalPending.toStringAsFixed(2)}',
              color: Colors.orange,
              icon: Iconsax.clock,
            ),
            _buildStatTile(
              label: 'current_balance'.tr,
              value: '$currency ${stats.currentBalance.toStringAsFixed(2)}',
              color: const Color(0xFF00BCD4),
              icon: Iconsax.wallet_2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Get.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Iconsax.lock_1, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'market_not_enabled'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Get.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'no_market_permission'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(MarketSettings settings) {
    final controller = TextEditingController();
    final maxAmount = settings.userMarketBalance;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('transfer_to_wallet'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${'available'.tr}: ${settings.currency} ${maxAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: 'enter_amount'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: settings.currency,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount <= 0 || amount > maxAmount) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('invalid_amount'.tr)));
                return;
              }

              Navigator.pop(context);
              _performTransfer(amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            child: Text('transfer'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _performTransfer(double amount) async {
    final result = await _apiService.transferToWallet(amount);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'transfer_successful'.tr),
          backgroundColor: Colors.green,
        ),
      );
      _refreshData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'transfer_failed'.tr),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
