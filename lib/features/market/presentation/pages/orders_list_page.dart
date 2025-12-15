import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order.dart';
import '../../domain/market_repository.dart';
import 'order_details_page.dart';
class OrdersListPage extends StatefulWidget {
  const OrdersListPage({super.key});
  @override
  State<OrdersListPage> createState() => _OrdersListPageState();
}
class _OrdersListPageState extends State<OrdersListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MarketRepository _repository;
  bool _isLoading = true;
  List<Order> _myOrders = [];
  List<Order> _mySalesOrders = [];
  String? _error;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository = Get.find<MarketRepository>();
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Load both my orders (as buyer) and sales orders (as seller)
      final myOrders = await _repository.getBuyerOrders();
      final salesOrders = await _repository.getSellerOrders();
      setState(() {
        _myOrders = myOrders;
        _mySalesOrders = salesOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.isDarkMode ? const Color(0xFF1a1f36) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Get.isDarkMode ? const Color(0xFF1a1f36) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Get.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'طلباتي',
          style: TextStyle(
            color: Get.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Get.isDarkMode ? Colors.white : Colors.black,
          unselectedLabelColor: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          tabs: const [
            Tab(text: 'مشترياتي'),
            Tab(text: 'مبيعاتي'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersList(_myOrders, false),
                    _buildOrdersList(_mySalesOrders, true),
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
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'فشل في تحميل الطلبات',
            style: TextStyle(
              fontSize: 18,
              color: Get.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              'إعادة المحاولة',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildOrdersList(List<Order> orders, bool isSalesOrders) {
    if (orders.isEmpty) {
      return _buildEmptyState(isSalesOrders);
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order, isSalesOrders);
        },
      ),
    );
  }
  Widget _buildEmptyState(bool isSalesOrders) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Get.isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isSalesOrders ? 'لا توجد مبيعات' : 'لا توجد طلبات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSalesOrders
                ? 'لم تقم ببيع أي منتجات بعد'
                : 'لم تقم بشراء أي منتجات بعد',
            style: TextStyle(
              fontSize: 14,
              color: Get.isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildOrderCard(Order order, bool isSalesOrder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF252d48) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Get.to(() => OrderDetailsPage(orderId: order.orderId));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'طلب #${order.orderId}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Get.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 12),
              // Order date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Buyer/Seller info  
              if (isSalesOrder) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'المشتري: ${order.buyer.fullName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(
                      Icons.store,
                      size: 16,
                      color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'البائع: ${order.seller.fullName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 24),
              // Order total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المجموع',
                    style: TextStyle(
                      fontSize: 14,
                      color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    order.total,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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
    Color textColor;
    String displayText;
    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        displayText = 'قيد الانتظار';
        break;
      case 'processing':
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
        displayText = 'قيد المعالجة';
        break;
      case 'shipped':
        backgroundColor = Colors.purple.withOpacity(0.2);
        textColor = Colors.purple;
        displayText = 'تم الشحن';
        break;
      case 'delivered':
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        displayText = 'تم التوصيل';
        break;
      case 'cancelled':
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        displayText = 'ملغي';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        displayText = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
