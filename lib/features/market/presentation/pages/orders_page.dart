import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/order.dart';
import '../../domain/market_repository.dart';
import './order_details_page.dart';

/// Orders Page - صفحة الطلبات
/// عرض قائمة طلبات المستخدم
class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MarketRepository _repository;

  bool _isLoading = true;
  List<Order> _buyerOrders = [];
  List<Order> _sellerOrders = [];

  @override
  void initState() {
    super.initState();
    _repository = context.read<MarketRepository>();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {

      // Load buyer and seller orders in parallel
      final results = await Future.wait([
        _repository.getBuyerOrders(limit: 50),
        _repository.getSellerOrders(limit: 50),
      ]);


      if (mounted) {
        setState(() {
          _buyerOrders = results[0];
          _sellerOrders = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_loading_orders'.tr + ': $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'orders'.tr,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue[isDark ? 400 : 600],
          labelColor: Colors.blue[isDark ? 400 : 600],
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'my_orders'.tr),
            Tab(text: 'my_sales'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(_buyerOrders, 'buyer'),
          _buildOrdersList(_sellerOrders, 'seller'),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders, String type) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _OrderCard(order: order);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    final isDark = Get.isDarkMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.blue[isDark ? 400 : 600]!,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'loading_orders'.tr,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Get.isDarkMode;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[isDark ? 400 : 500]!.withOpacity(0.2),
                    Colors.blue[isDark ? 300 : 600]!.withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 60,
                color: Colors.blue[isDark ? 400 : 600],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'no_orders_found'.tr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'no_orders_message'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text('explore_products'.tr),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                backgroundColor: Colors.blue[isDark ? 400 : 600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Order Card Widget - بطاقة الطلب
class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.to(() => OrderDetailsPage(orderId: order.orderHash));
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: bgColor,
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 16),
                  _buildDetails(isDark),
                  const SizedBox(height: 16),
                  _buildFooter(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'order_number'.tr}:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.orderHash,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildStatusBadge(isDark),
      ],
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    Color statusColor;
    String statusText;

    switch (order.status.toLowerCase()) {
      case 'placed':
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'order_status_placed'.tr;
        break;
      case 'shipped':
        statusColor = Colors.blue;
        statusText = 'order_status_shipped'.tr;
        break;
      case 'delivered':
        statusColor = Colors.green;
        statusText = 'order_status_delivered'.tr;
        break;
      case 'cancelled':
      case 'canceled':
        statusColor = Colors.red;
        statusText = 'order_status_cancelled'.tr;
        break;
      case 'refunded':
        statusColor = Colors.teal;
        statusText = 'order_status_refunded'.tr;
        break;
      default:
        statusColor = Colors.grey;
        statusText = order.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildDetails(bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Column(
      children: [
        _buildDetailRow(
          isDark,
          icon: Icons.calendar_today_outlined,
          label: 'order_placed'.tr,
          value: dateFormat.format(order.createdAt.toLocal()),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          isDark,
          icon: Icons.shopping_bag_outlined,
          label: 'items'.tr,
          value: '${order.itemsCount} ${'product'.tr}',
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'total'.tr,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${order.total} USD',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[isDark ? 400 : 600],
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () {
            Get.to(() => OrderDetailsPage(orderId: order.orderHash));
          },
          icon: Icon(
            Icons.arrow_forward,
            size: 18,
            color: Colors.blue[isDark ? 400 : 600],
          ),
          label: Text(
            'view_details'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue[isDark ? 400 : 600],
            ),
          ),
        ),
      ],
    );
  }
}
