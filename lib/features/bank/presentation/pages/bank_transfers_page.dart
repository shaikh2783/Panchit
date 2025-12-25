import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/bank/data/models/bank_transfer.dart';
import 'package:snginepro/features/bank/data/services/bank_api_service.dart';
import '../../../../main.dart' show globalApiClient;

class BankTransfersPage extends StatefulWidget {
  const BankTransfersPage({Key? key}) : super(key: key);

  @override
  State<BankTransfersPage> createState() => _BankTransfersPageState();
}

class _BankTransfersPageState extends State<BankTransfersPage>
    with SingleTickerProviderStateMixin {
  late final BankApiService _apiService;
  late Future<Map<String, dynamic>> _transfersFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _apiService = BankApiService(globalApiClient);
    _transfersFuture = _loadTransfers();
    _tabController = TabController(
      length: 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadTransfers() async {
    return await _apiService.getTransfers();
  }

  Future<void> _refreshData() async {
    setState(() {
      _transfersFuture = _loadTransfers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Transfers'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Approved'),
            Tab(text: 'Pending'),
            Tab(text: 'Declined'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransferList(null),
          _buildTransferList(BankTransferStatus.approved),
          _buildTransferList(BankTransferStatus.pending),
          _buildTransferList(BankTransferStatus.declined),
        ],
      ),
    );
  }

  Widget _buildTransferList(BankTransferStatus? filterStatus) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _transfersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?['success'] != true) {
            return _buildErrorWidget();
          }

          final allTransfers = snapshot.data!['data'] as List<BankTransfer>;

          // Filter transfers based on tab
          final transfers = filterStatus == null
              ? allTransfers
              : allTransfers.where((t) => t.status == filterStatus).toList();

          if (transfers.isEmpty) {
            return _buildEmptyWidget(filterStatus);
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: transfers.length,
            itemBuilder: (context, index) {
              return _buildTransferCard(transfers[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTransferCard(BankTransfer transfer) {
    final statusColor = transfer.status == BankTransferStatus.approved
        ? Colors.green
        : transfer.status == BankTransferStatus.pending
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showTransferDetails(transfer),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Header: Type and Status
              Row(
                children: [
                  // Type Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getHandleIcon(transfer.handle),
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Type Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transfer.typeText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Get.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          transfer.handle.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Get.isDarkMode
                                ? Colors.grey[500]
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      transfer.status.statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Divider
              Divider(
                color: statusColor.withOpacity(0.1),
                height: 0,
              ),

              const SizedBox(height: 12),

              // Details: Amount and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 11,
                          color: Get.isDarkMode
                              ? Colors.grey[500]
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${transfer.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 11,
                          color: Get.isDarkMode
                              ? Colors.grey[500]
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(
                          DateTime.parse(transfer.time),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Get.isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransferDetails(BankTransfer transfer) {
    final statusColor = transfer.status == BankTransferStatus.approved
        ? Colors.green
        : transfer.status == BankTransferStatus.pending
            ? Colors.orange
            : Colors.red;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Get.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transfer Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Get.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Iconsax.close_square),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    transfer.status == BankTransferStatus.approved
                        ? Iconsax.tick_circle
                        : transfer.status == BankTransferStatus.pending
                            ? Iconsax.clock
                            : Iconsax.close_circle,
                    color: statusColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    transfer.status.statusText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Details List
            _buildDetailItem('Transfer ID', '${transfer.transferId}'),
            _buildDetailItem('Type', transfer.typeText),
            _buildDetailItem('Handle', transfer.handle.toUpperCase()),
            _buildDetailItem('Amount', '\$${transfer.amount.toStringAsFixed(2)}'),
            _buildDetailItem('Price', '\$${transfer.price.toStringAsFixed(2)}'),
            if (transfer.packageName != null)
              _buildDetailItem('Package', transfer.packageName!),
            _buildDetailItem(
              'Date',
              DateFormat('MMM dd, yyyy hh:mm a').format(
                DateTime.parse(transfer.time),
              ),
            ),
            if (transfer.bankReceipt != null)
              _buildDetailItem('Receipt', transfer.bankReceipt!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Get.isDarkMode ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Get.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(BankTransferStatus? status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.receipt,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            status == null
                ? 'No transfers yet'
                : 'No ${status.statusText.toLowerCase()} transfers',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your bank transfers will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.warning_2,
            size: 48,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to Load',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Iconsax.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  IconData _getHandleIcon(String handle) {
    switch (handle) {
      case 'wallet':
        return Iconsax.wallet;
      case 'packages':
        return Iconsax.box;
      case 'donate':
        return Iconsax.heart;
      case 'subscribe':
        return Iconsax.play;
      case 'paid_post':
        return Iconsax.document;
      case 'movies':
        return Iconsax.video;
      case 'marketplace':
        return Iconsax.shopping_cart;
      default:
        return Iconsax.money;
    }
  }
}
