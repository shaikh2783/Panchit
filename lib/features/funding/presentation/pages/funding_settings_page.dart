import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/funding/data/models/funding_settings.dart';
import 'package:snginepro/features/funding/data/models/funding_stats.dart';
import 'package:snginepro/features/funding/data/services/funding_settings_api_service.dart';
import '../../../../main.dart' show globalApiClient;
import 'funding_payments_page.dart';

class FundingSettingsPage extends StatefulWidget {
  const FundingSettingsPage({Key? key}) : super(key: key);

  @override
  State<FundingSettingsPage> createState() => _FundingSettingsPageState();
}

class _FundingSettingsPageState extends State<FundingSettingsPage> {
  late final FundingSettingsApiService _apiService;
  late Future<Map<String, dynamic>> _settingsFuture;
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _apiService = FundingSettingsApiService(globalApiClient);
    _settingsFuture = _loadSettings();
    _statsFuture = _loadStats();
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    return await _apiService.getSettings();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    return await _apiService.getStats();
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
          'funding_settings'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _settingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data?['success'] != true) {
              return _buildErrorCard('failed_load_funding'.tr);
            }

            final settings = snapshot.data!['data'] as FundingSettings;

            if (!settings.canRaiseFunding) {
              return _buildDisabledCard('funding_disabled'.tr);
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildBalanceCard(settings),
                const SizedBox(height: 16),
                _buildQuickActions(settings),
                const SizedBox(height: 16),
                _buildPaymentMethods(settings),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, dynamic>>(
                  future: _statsFuture,
                  builder: (context, statSnap) {
                    if (statSnap.data?['success'] != true) {
                      return const SizedBox.shrink();
                    }
                    final stats = statSnap.data!['data'] as FundingStats;
                    return _buildStats(stats, settings.currency);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceCard(FundingSettings settings) {
    final canWithdraw = settings.canWithdrawMoney;
    final color = canWithdraw ? const Color(0xFF8E24AA) : const Color(0xFFFFA000);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.12)!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
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
                'funding_balance'.tr,
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
            '${settings.currency} ${settings.userFundingBalance.toStringAsFixed(2)}',
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
                : '${Get.locale?.languageCode == 'ar' ? 'الحد الأدنى المطلوب' : 'Need'} ${settings.currency} ${(settings.minWithdrawal - settings.userFundingBalance).clamp(0, double.infinity).toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
          if (settings.canTransferToWallet && settings.fundingMoneyTransferEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'transfer_wallet_enabled'.tr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(FundingSettings settings) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: settings.canWithdrawMoney
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FundingPaymentsPage(),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Iconsax.arrow_up_3),
            label: Text('withdraw'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8E24AA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (settings.canTransferToWallet && settings.fundingMoneyTransferEnabled)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showTransferDialog(settings);
              },
              icon: const Icon(Iconsax.repeat),
              label: Text('transfer'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3949AB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentMethods(FundingSettings settings) {
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
          children: settings.paymentMethods.map(_buildMethodChip).toList(),
        ),
        if (settings.paymentMethodCustom != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Get.isDarkMode ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.info_circle, size: 16, color: Color(0xFF8E24AA)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${'custom'.tr}: ${settings.paymentMethodCustom}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Get.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMethodChip(String method) {
    final map = {
      'paypal': ('paypal'.tr, const Color(0xFF003087), Iconsax.card),
      'skrill': ('skrill'.tr, const Color(0xFF3D9970), Iconsax.wallet),
      'bank': ('bank'.tr, const Color(0xFF1E3A8A), Iconsax.building),
      'custom': ('custom'.tr, const Color(0xFF8E24AA), Iconsax.money),
      'moneypoolscash': ('moneypoolscash'.tr, const Color(0xFFEF6C00), Iconsax.money),
    };
    final info = map[method] ?? (method.toUpperCase(), const Color(0xFF6B7280), Iconsax.wallet);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: info.$2.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.$2.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.$3, size: 14, color: info.$2),
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

  Widget _buildStats(FundingStats stats, String currency) {
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
              color: const Color(0xFF43A047),
              icon: Iconsax.arrow_up_3,
            ),
            _buildStatTile(
              label: 'total_paid'.tr,
              value: '$currency ${stats.totalPaid.toStringAsFixed(2)}',
              color: const Color(0xFF1E88E5),
              icon: Iconsax.wallet,
            ),
            _buildStatTile(
              label: 'pending'.tr,
              value: '$currency ${stats.totalPending.toStringAsFixed(2)}',
              color: const Color(0xFFFFA000),
              icon: Iconsax.clock,
            ),
            _buildStatTile(
              label: 'current_balance'.tr,
              value: '$currency ${stats.currentBalance.toStringAsFixed(2)}',
              color: const Color(0xFF8E24AA),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.lock_1,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Funding Disabled',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Get.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
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

  void _showTransferDialog(FundingSettings settings) {
    final controller = TextEditingController();
    final maxAmount = settings.userFundingBalance;

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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('invalid_amount'.tr)),
                );
                return;
              }
              Navigator.pop(context);
              _performTransfer(amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3949AB),
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
