import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../data/models/models.dart';
import '../../domain/market_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  void initState() {
    super.initState();
    _fetch();
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
            icon: Icon(Icons.refresh, color: Get.isDarkMode ? Colors.white : Colors.black),
          ),
        ],
      ),
      body: _buildBody(context),
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
            Text('error'.tr, style: TextStyle(color: UI.subtleText(context), fontSize: 16)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: UI.subtleText(context))),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: _fetch, icon: const Icon(Icons.refresh), label: Text('retry'.tr)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UI.rLg)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusChip(order.status),
                const Spacer(),
                Text('${'market_order_hash'.tr}: #${order.orderHash}', style: TextStyle(color: UI.subtleText(context))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: order.seller.userPicture.isNotEmpty ? CachedNetworkImageProvider(order.seller.userPicture) : null,
                  child: order.seller.userPicture.isEmpty ? const Icon(Icons.store, color: Colors.white) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${'market_seller'.tr}: ${order.seller.fullName.isEmpty ? order.seller.userName : order.seller.fullName}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${'market_buyer'.tr}: ${order.buyer.fullName.isEmpty ? order.buyer.userName : order.buyer.fullName}',
                          style: TextStyle(color: UI.subtleText(context))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${'market_created_at'.tr}: ${order.createdAt.toLocal()}', style: TextStyle(color: UI.subtleText(context), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(Order order) {
    final addr = order.shippingAddress;
    return Card(
      color: UI.surfaceCard(context),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UI.rLg)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.green),
                const SizedBox(width: 8),
                Text('market_shipping_address'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _kv('full_name'.tr, addr.name),
            _kv('phone_number'.tr, addr.phone),
            _kv('address'.tr, addr.address ?? addr.location),
            Row(
              children: [
                Expanded(child: _kv('city'.tr, addr.city ?? '-')),
                const SizedBox(width: 12),
                Expanded(child: _kv('zip_code'.tr, addr.zip ?? '-')),
              ],
            ),
            _kv('country'.tr, addr.country ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(Order order) {
    return Card(
      color: UI.surfaceCard(context),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UI.rLg)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text('market_items'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              ? Image.network(it.productPicture, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgPh())
              : _imgPh(),
        ),
      ),
      title: Text(it.productName, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${'market_quantity'.tr}: ${it.quantity}', style: TextStyle(color: UI.subtleText(context))),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(it.productPrice, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UI.rLg)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('market_order_summary'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          SizedBox(width: 120, child: Text(k, style: TextStyle(color: UI.subtleText(context)))),
          const SizedBox(width: 8),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500))),
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
        Container(height: h, width: w, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(r)));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(color: UI.surfaceCard(context), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Row(children: [box(h: 24, w: 80, r: 12), const Spacer(), box(h: 16, w: 140)]),
          const SizedBox(height: 12),
          Row(children: [box(h: 36, w: 36, r: 18), const SizedBox(width: 8), Expanded(child: box(w: double.infinity))]),
          const SizedBox(height: 8),
          box(w: 200),
        ]))),
        const SizedBox(height: 16),
        Card(color: UI.surfaceCard(context), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Row(children: [box(w: 140),]),
          const SizedBox(height: 12),
          box(w: double.infinity), const SizedBox(height: 8), box(w: double.infinity), const SizedBox(height: 8), box(w: 200),
        ]))),
        const SizedBox(height: 16),
        Card(color: UI.surfaceCard(context), child: Column(children: List.generate(3, (i) => ListTile(
          leading: box(h: 56, w: 56, r: 8),
          title: box(w: double.infinity),
          subtitle: const SizedBox(height: 8),
          trailing: box(w: 60),
        )))),
      ],
    );
  }

  Widget _imgPh() => Icon(Icons.image_outlined, color: UI.subtleText(context));

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg = Colors.white;
    switch (status) {
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
        bg = Colors.red;
        break;
      default:
        bg = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(_statusDisplay(status), style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  String _statusDisplay(String status) {
    // Localized status text
    switch (status) {
      case 'pending':
        return 'market_status_pending'.tr;
      case 'processing':
        return 'market_status_processing'.tr;
      case 'shipped':
        return 'market_status_shipped'.tr;
      case 'delivered':
        return 'market_status_delivered'.tr;
      case 'cancelled':
        return 'market_status_cancelled'.tr;
      default:
        return status;
    }
  }
}
