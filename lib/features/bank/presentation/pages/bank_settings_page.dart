import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/bank/data/models/bank_settings.dart';
import 'package:snginepro/features/bank/data/services/bank_api_service.dart';
import '../../../../main.dart' show globalApiClient;
import 'bank_transfers_page.dart';

class BankSettingsPage extends StatefulWidget {
  const BankSettingsPage({Key? key}) : super(key: key);

  @override
  State<BankSettingsPage> createState() => _BankSettingsPageState();
}

class _BankSettingsPageState extends State<BankSettingsPage> {
  late final BankApiService _apiService;
  late Future<Map<String, dynamic>> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _apiService = BankApiService(globalApiClient);
    _settingsFuture = _loadSettings();
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    return await _apiService.getSettings();
  }

  Future<void> _refreshData() async {
    setState(() {
      _settingsFuture = _loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'bank_transfers'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _refreshData,
            tooltip: 'refresh'.tr,
          ),
        ],
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
              return _buildErrorView();
            }

            final settings = snapshot.data!['data'] as BankSettings;

            if (!settings.enabled) {
              return _buildDisabledView();
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Bank Info Card
                _buildBankInfoCard(settings),
                const SizedBox(height: 24),

                // Instructions Card
                _buildInstructionsCard(settings),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(settings),
                const SizedBox(height: 24),

                // Transfer History Button
                _buildTransferHistorySection(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBankInfoCard(BankSettings settings) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1E3A8A), const Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
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
                'bank_information'.tr,
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
                  Iconsax.building,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bank Details
          _buildDetailRow('bank_name'.tr, settings.bankName),
          const SizedBox(height: 12),
          _buildDetailRow('account_name'.tr, settings.accountName),
          const SizedBox(height: 12),
          _buildDetailRow('account_number'.tr, settings.accountNumber),
          const SizedBox(height: 12),
          _buildDetailRow('routing_number'.tr, settings.routing),
          const SizedBox(height: 12),
          _buildDetailRow('country'.tr, settings.country),
          const SizedBox(height: 12),
          _buildDetailRow('currency'.tr, settings.currency),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
        ),
        GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('copied_to_clipboard'.tr),
                duration: const Duration(milliseconds: 1500),
              ),
            );
          },
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard(BankSettings settings) {
    return Container(
      decoration: BoxDecoration(
        color: Get.isDarkMode ? Colors.grey[800] : Colors.blue[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.note_1, color: Colors.blue, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'transfer_instructions'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Get.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            settings.note,
            style: TextStyle(
              fontSize: 13,
              color: Get.isDarkMode ? Colors.grey[300] : Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BankSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quick_actions'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: settings.accountNumber),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('account_number_copied'.tr),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Iconsax.copy),
                label: Text('copy_account'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: settings.routing));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('routing_copied'.tr),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Iconsax.copy),
                label: Text('copy_routing'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransferHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'transfer_history'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BankTransfersPage(),
                ),
              );
            },
            icon: const Icon(Iconsax.arrow_right),
            label: Text('view_all_transfers'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'failed_to_load'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Get.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'check_connection_try_again'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Iconsax.refresh),
            label: Text('retry'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.lock_1, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'bank_transfers_disabled'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Get.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'bank_transfers_not_available'.tr,
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
}
