import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../data/models/models.dart';
import '../../domain/market_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId; // order hash

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Order? _order;
  bool _loading = true;
  String? _error;
  String? _currentUserId;
  late final TextEditingController _trackingLinkController;
  late final TextEditingController _trackingNumberController;

  @override
  void initState() {
    super.initState();
    _trackingLinkController = TextEditingController();
    _trackingNumberController = TextEditingController();
    // Try to load current user id (for seller-only actions)
    try {
      final userMap = context.read<AuthNotifier?>()?.currentUser;
      _currentUserId = userMap != null ? userMap['user_id']?.toString() : null;
    } catch (_) {}
    _fetch();
  }

  @override
  void dispose() {
    _trackingLinkController.dispose();
    _trackingNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<MarketRepository>();
      final data = await repo.getOrderDetails(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = data;
        _loading = false;
        _trackingLinkController.text = data.trackingLink ?? '';
        _trackingNumberController.text = data.trackingNumber ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UI.surfacePage(context),
      appBar: AppBar(
        backgroundColor: Get.isDarkMode
            ? const Color(0xFF1a1f36)
            : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Get.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'market_order_details'.tr,
          style: TextStyle(
            color: Get.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'retry'.tr,
            onPressed: _fetch,
            icon: Icon(
              Icons.refresh,
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: _buildStatusFab(),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return _buildSkeleton();
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              'error'.tr,
              style: TextStyle(color: UI.subtleText(context), fontSize: 16),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: UI.subtleText(context)),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr),
            ),
          ],
        ),
      );
    }
    final order = _order!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(order),
        const SizedBox(height: 16),
        _buildAddressCard(order),
        const SizedBox(height: 16),
        _buildItemsCard(order),
        const SizedBox(height: 16),
        _buildTotalsCard(order),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeaderCard(Order order) {
    return Card(
      color: UI.surfaceCard(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UI.rLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusChip(order.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if ((_currentUserId != null && order.seller?.userId == _currentUserId) &&
                          !(order.isDelivered || order.isCancelled))
                        TextButton.icon(
                          onPressed: _showStatusSheet,
                          icon: const Icon(Icons.edit),
                          label: Text('change_status'.tr),
                        ),
                      Text(
                        '${'market_order_hash'.tr}: #${order.orderHash}',
                        style: TextStyle(color: UI.subtleText(context)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      (order.seller?.userPicture.isNotEmpty ?? false)
                      ? CachedNetworkImageProvider(order.seller!.userPicture)
                      : null,
                  child: (order.seller?.userPicture.isEmpty ?? true)
                      ? const Icon(Icons.store, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${'market_seller'.tr}: ${order.seller?.fullName.isEmpty ?? true ? (order.seller?.userName ?? 'N/A') : order.seller?.fullName ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${'market_buyer'.tr}: ${order.buyer?.fullName.isEmpty ?? true ? (order.buyer?.userName ?? 'N/A') : order.buyer?.fullName ?? 'N/A'}',
                        style: TextStyle(color: UI.subtleText(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${'market_created_at'.tr}: ${order.createdAt.toLocal()}',
              style: TextStyle(color: UI.subtleText(context), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(Order order) {
    final addr = order.shippingAddress;

    if (addr == null) {
      return Card(
        color: UI.surfaceCard(context),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UI.rLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'no_shipping_address'.tr,
                style: TextStyle(color: UI.subtleText(context)),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: UI.surfaceCard(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UI.rLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'market_shipping_address'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _kv('full_name'.tr, addr.name),
            _kv('phone_number'.tr, addr.phone),
            _kv('address'.tr, addr.address),
            if (addr.city != null || addr.zipCode != null)
              Row(
                children: [
                  if (addr.city != null)
                    Expanded(child: _kv('city'.tr, addr.city!)),
                  if (addr.city != null && addr.zipCode != null)
                    const SizedBox(width: 12),
                  if (addr.zipCode != null)
                    Expanded(child: _kv('zip_code'.tr, addr.zipCode!)),
                ],
              ),
            if (addr.country != null) _kv('country'.tr, addr.country!),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(Order order) {
    return Card(
      color: UI.surfaceCard(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UI.rLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'market_items'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 0),
            ...order.items.map((it) => _orderItemTile(it)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _orderItemTile(OrderItem it) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(UI.rSm),
        child: Container(
          width: 56,
          height: 56,
          color: Get.isDarkMode ? Colors.grey[800] : Colors.grey[200],
          child: it.productPicture.isNotEmpty
              ? Image.network(
                  it.productPicture,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imgPh(),
                )
              : _imgPh(),
        ),
      ),
      title: Text(
        it.productName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${'market_quantity'.tr}: ${it.quantity}',
        style: TextStyle(color: UI.subtleText(context)),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            it.productPrice,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(it.total, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(Order order) {
    return Card(
      color: UI.surfaceCard(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UI.rLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'market_order_summary'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _summaryRow('market_items'.tr, '${order.itemsCount}'),
            const Divider(height: 24),
            _summaryRow('market_total'.tr, order.total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: TextStyle(color: UI.subtleText(context))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.green : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    Color base = Get.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    Widget box({double h = 16, double w = double.infinity, double r = 8}) =>
        Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(r),
          ),
        );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: UI.surfaceCard(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    box(h: 24, w: 80, r: 12),
                    const Spacer(),
                    box(h: 16, w: 140),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    box(h: 36, w: 36, r: 18),
                    const SizedBox(width: 8),
                    Expanded(child: box(w: double.infinity)),
                  ],
                ),
                const SizedBox(height: 8),
                box(w: 200),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: UI.surfaceCard(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(children: [box(w: 140)]),
                const SizedBox(height: 12),
                box(w: double.infinity),
                const SizedBox(height: 8),
                box(w: double.infinity),
                const SizedBox(height: 8),
                box(w: 200),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: UI.surfaceCard(context),
          child: Column(
            children: List.generate(
              3,
              (i) => ListTile(
                leading: box(h: 56, w: 56, r: 8),
                title: box(w: double.infinity),
                subtitle: const SizedBox(height: 8),
                trailing: box(w: 60),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildStatusFab() {
    if (_order == null) return null;
    final order = _order!;
    // Seller-only; hide if not seller or final states
    final isSeller = _currentUserId != null && order.seller?.userId == _currentUserId;
    final isFinal = order.isDelivered || order.isCancelled;
    if (!isSeller || isFinal) return null;

    return FloatingActionButton.extended(
      onPressed: _showStatusSheet,
      icon: const Icon(Icons.edit),
      label: Text('change_status'.tr),
    );
  }

  void _showStatusSheet() {
    if (_order == null) return;
    final order = _order!;
    // Ensure controllers are pre-filled
    _trackingLinkController.text = order.trackingLink ?? '';
    _trackingNumberController.text = order.trackingNumber ?? '';
    // Allow full set of backend-supported statuses, excluding current one
    const allStatuses = [
      'pending',
      'processing',
      'shipped',
      'delivered',
      'canceled',
      'refunded',
    ];
    final options = allStatuses.where((s) => s != order.status).toList();

    if (options.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text('change_status'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _trackingLinkController,
                      decoration: InputDecoration(
                        labelText: 'tracking_link'.tr,
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _trackingNumberController,
                      decoration: InputDecoration(
                        labelText: 'tracking_number'.tr,
                        hintText: 'TRK12345',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              ...options.map((s) => ListTile(
                    leading: const Icon(Icons.flag),
                    title: Text(_statusDisplay(s)),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await _updateStatus(s);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(String status) async {
    if (_order == null) return;
    final repo = context.read<MarketRepository>();
    try {
      setState(() => _loading = true);
      final updated = await repo.updateOrderStatus(
        orderHash: _order!.orderHash,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        _order = updated;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('status_updated'.tr)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget _imgPh() => Icon(Icons.image_outlined, color: UI.subtleText(context));

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg = Colors.white;
    switch (status) {
      case 'placed':
        bg = Colors.amber;
        break;
      case 'pending':
        bg = Colors.amber;
        break;
      case 'processing':
        bg = Colors.blue;
        break;
      case 'shipped':
        bg = Colors.indigo;
        break;
      case 'delivered':
        bg = Colors.green;
        break;
      case 'cancelled':
      case 'canceled':
        bg = Colors.red;
        break;
      case 'refunded':
        bg = Colors.teal;
        break;
      default:
        bg = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusDisplay(status),
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  String _statusDisplay(String status) {
    // Localized status text
    switch (status) {
      case 'placed':
        return 'order_status_placed'.tr;
      case 'pending':
        return 'market_status_pending'.tr;
      case 'processing':
        return 'market_status_processing'.tr;
      case 'shipped':
        return 'market_status_shipped'.tr;
      case 'delivered':
        return 'market_status_delivered'.tr;
      case 'cancelled':
      case 'canceled':
        return 'market_status_cancelled'.tr;
      case 'refunded':
        return 'market_status_refunded'.tr;
      default:
        return status;
    }
  }
}
