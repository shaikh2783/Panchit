import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:snginepro/features/points/data/models/points_settings.dart';
import 'package:snginepro/features/points/data/models/points_transaction.dart';
import 'package:snginepro/features/points/data/services/points_api_service.dart';
import '../../../../main.dart' show globalApiClient;
import 'package:iconsax_flutter/iconsax_flutter.dart';

class MyPointsPage extends StatefulWidget {
  const MyPointsPage({Key? key}) : super(key: key);

  @override
  State<MyPointsPage> createState() => _MyPointsPageState();
}

class _MyPointsPageState extends State<MyPointsPage> {
  late final PointsApiService _apiService;
  late Future<Map<String, dynamic>> _settingsFuture;
  late Future<List<PointsTransaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _apiService = PointsApiService(globalApiClient);
    _settingsFuture = _loadSettings();
    _transactionsFuture = _loadTransactions();
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    final response = await _apiService.getSettings();
    if (response['success'] == true) {
      return {'success': true, 'data': response['data']};
    }
    return {'success': false};
  }

  Future<List<PointsTransaction>> _loadTransactions() async {
    final response = await _apiService.getTransactions();
    if (response['success'] == true) {
      return response['data'] as List<PointsTransaction>;
    }
    return [];
  }

  Future<void> _refreshData() async {
    setState(() {
      _settingsFuture = _loadSettings();
      _transactionsFuture = _loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'points_rewards'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _settingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.data?['success'] != true) {
                    return const SizedBox.shrink();
                  }
                  final data = snapshot.data!['data'];
                  final settings = PointsSettings.fromJson(
                    data is Map<String, dynamic> ? data : {},
                  );
                  return Text(
                    '${settings.userPoints.toStringAsFixed(0)} ${'pts'.tr}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00BCD4),
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Main Balance Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _settingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.data?['success'] != true) {
                    return const SizedBox.shrink();
                  }
                  final data = snapshot.data!['data'];
                  final settings = PointsSettings.fromJson(
                    data is Map<String, dynamic> ? data : {},
                  );

                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF00BCD4),
                          const Color(0xFF0097A7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00BCD4).withOpacity(0.3),
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
                              'total_points'.tr,
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
                                Iconsax.star,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${settings.userPoints.toStringAsFixed(3)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${'equivalent_to'.tr} \$${settings.moneyBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.clock,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${'today'.tr}: ${settings.remainingPointsToday}/${settings.dailyLimit}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Points Information Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _settingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.data?['success'] != true) {
                    return const SizedBox.shrink();
                  }
                  final data = snapshot.data!['data'];
                  final settings = PointsSettings.fromJson(
                    data is Map<String, dynamic> ? data : {},
                  );

                  final pointsItems = [
                    {
                      'icon': Iconsax.eye,
                      'label': 'post_view'.tr,
                      'points': 0.001,
                      'color': const Color(0xFF1ABC9C),
                    },
                    {
                      'icon': Iconsax.message,
                      'label': 'post_comment'.tr,
                      'points': settings.systemSettings.pointsPerPostComment,
                      'color': const Color(0xFF9C27B0),
                    },
                    {
                      'icon': Iconsax.heart,
                      'label': 'post_reaction'.tr,
                      'points': settings.systemSettings.pointsPerPostReaction,
                      'color': const Color(0xFFE74C3C),
                    },
                    {
                      'icon': Iconsax.message_circle,
                      'label': 'comment'.tr,
                      'points': settings.systemSettings.pointsPerComment,
                      'color': const Color(0xFF3498DB),
                    },
                    {
                      'icon': Iconsax.like_1,
                      'label': 'reaction'.tr,
                      'points': settings.systemSettings.pointsPerReaction,
                      'color': const Color(0xFF9B59B6),
                    },
                    {
                      'icon': Iconsax.people,
                      'label': 'follower'.tr,
                      'points': settings.systemSettings.pointsPerFollow,
                      'color': const Color(0xFFFF6B35),
                    },
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'how_to_earn'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Get.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: pointsItems.length,
                        itemBuilder: (context, index) {
                          final item = pointsItems[index];
                          return _buildEarnCard(
                            icon: item['icon'] as IconData,
                            label: item['label'] as String,
                            points: item['points'] as double,
                            color: item['color'] as Color,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Quick Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'your_stats'.tr,
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
                        child: _buildStatBox(
                          icon: Iconsax.arrow_up_3,
                          label: 'can_withdraw'.tr,
                          value: 'yes'.tr,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          icon: Iconsax.wallet_2,
                          label: 'min_amount'.tr,
                          value: '\$50',
                          color: const Color(0xFF00BCD4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Transactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'recent_transactions'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Get.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<PointsTransaction>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
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
                            'no_transactions_yet_points'.tr,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'start_earning_points'.tr,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.take(10).length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _buildTransactionTile(transaction, index);
                  },
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnCard({
    required IconData icon,
    required String label,
    required double points,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            points.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Get.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[700],
              height: 1.1,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
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

  Widget _buildTransactionTile(PointsTransaction transaction, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.06),
            Colors.green.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.15), width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Iconsax.arrow_down_1,
              color: Colors.green,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Get.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat(
                    'MMM dd, hh:mm a',
                  ).format(DateTime.parse(transaction.time)),
                  style: TextStyle(
                    fontSize: 10,
                    color: Get.isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${transaction.points.toStringAsFixed(3)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
