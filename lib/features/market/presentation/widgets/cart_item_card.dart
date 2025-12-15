import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../data/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
/// Cart Item Card Widget - بطاقة منتج في السلة
/// 
/// عرض منتج في السلة مع إمكانية تعديل الكمية أو الحذف
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  const CartItemCard({
    Key? key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Get.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                ),
                child: item.productPicture.isNotEmpty
                    ? Image.network(
                        item.productPicture,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Seller
                  Row(
                    children: [
                      const Icon(Icons.store, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.seller.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: UI.subtleText(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price & Quantity Controls
                  Row(
                    children: [
                      // Price
                      Text(
                        item.productPrice,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      // Quantity Controls
                      _buildQuantityControls(context),
                    ],
                  ),
                  // Total for this item
                  if (item.quantity > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${'market_total'.tr}: ${item.total}',
                        style: TextStyle(
                          fontSize: 13,
                          color: UI.subtleText(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Remove Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showRemoveDialog(context),
              tooltip: 'delete'.tr,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }
  Widget _buildQuantityControls(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease
          InkWell(
            onTap: item.quantity > 1
                ? () => onQuantityChanged(item.quantity - 1)
                : null,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.remove,
                size: 18,
                color: item.quantity > 1 ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
          // Quantity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              item.quantity.toString(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Increase
          InkWell(
            onTap: () => onQuantityChanged(item.quantity + 1),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.add,
                size: 18,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('market_remove_item'.tr),
        content: Text('market_delete_product_confirm'.trParams({'name': item.productName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              onRemove();
              Navigator.pop(dialogContext);
            },
            child: Text(
              'delete'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
