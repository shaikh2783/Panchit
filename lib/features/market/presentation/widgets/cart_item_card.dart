import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/models.dart';

/// Cart Item Card Widget - بطاقة منتج في السلة
/// تصميم احترافي وحديث مع دعم كامل للـ Dark Mode و Light Mode
class CartItemCard extends StatefulWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final bool isLoading;

  const CartItemCard({
    Key? key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Get price display text with proper formatting
  String _getPriceDisplay(String priceStr) {
    try {
      final price = double.parse(priceStr);
      if (price <= 0) {
        return 'free'.tr;
      }
      return '$priceStr USD';
    } catch (e) {
      return 'price'.tr;
    }
  }

  /// Get price color based on value
  Color _getPriceColor(bool isDark, String priceStr) {
    try {
      final price = double.parse(priceStr);
      if (price <= 0) {
        return Colors.orange[isDark ? 400 : 600]!;
      }
      return Colors.green[isDark ? 400 : 600]!;
    } catch (e) {
      return Colors.blue[isDark ? 400 : 600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: _buildCardContent(isDark),
    );
  }

  Widget _buildCardContent(bool isDark) {
    final bgColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                color: bgColor,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: 0.8,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Product Image with badge
                        Stack(
                          children: [
                            _buildProductImage(isDark),
                            // Quantity badge
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[isDark ? 400 : 600],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${widget.item.quantity}x',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 14),

                        // Product Details
                        Expanded(
                          child: _buildProductDetails(
                            textColor,
                            subtleColor,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Remove Button
                        _buildRemoveButton(isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Loading Overlay
            if (widget.isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.black.withOpacity(0.2),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue[isDark ? 400 : 600]!,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(bool isDark) {
    final placeholderColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final placeholderIconColor =
        isDark ? Colors.grey[600] : Colors.grey[400];

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: placeholderColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: widget.item.productPicture.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: widget.item.productPicture,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: placeholderColor,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        placeholderIconColor!,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    _buildPlaceholder(isDark),
              )
            : _buildPlaceholder(isDark),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? Colors.grey[800] : Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildProductDetails(
    Color textColor,
    Color? subtleColor,
  ) {
    final isDark = Get.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Product Name
        Text(
          widget.item.productName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 8),

        // Seller Name
        Row(
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 14,
              color: subtleColor,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.item.seller.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: subtleColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Price and Quantity Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'price'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: subtleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getPriceDisplay(widget.item.productPrice),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _getPriceColor(isDark, widget.item.productPrice),
                  ),
                ),
              ],
            ),

            // Quantity Controls
            _buildQuantityControls(isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityControls(bool isDark) {
    final borderColor = isDark ? Colors.grey[700] : Colors.grey[300];
    final bgColor = isDark ? Colors.grey[800] : Colors.grey[50];
    final iconColor = isDark ? Colors.grey[200] : Colors.black87;
    final disabledColor = isDark ? Colors.grey[600] : Colors.grey[400];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: bgColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease Button
          InkWell(
            onTap: (widget.isLoading || widget.item.quantity <= 1)
                ? null
                : () {
                    widget.onQuantityChanged(widget.item.quantity - 1);
                  },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              child: Icon(
                Icons.remove,
                size: 18,
                color: (widget.isLoading || widget.item.quantity <= 1)
                    ? disabledColor
                    : iconColor,
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 20,
            color: borderColor,
          ),

          // Quantity Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              widget.item.quantity.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 20,
            color: borderColor,
          ),

          // Increase Button
          InkWell(
            onTap: widget.isLoading
                ? null
                : () {
                    widget.onQuantityChanged(widget.item.quantity + 1);
                  },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              child: Icon(
                Icons.add,
                size: 18,
                color: widget.isLoading ? disabledColor : iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton(bool isDark) {
    final bgColor = Colors.red.withOpacity(isDark ? 0.15 : 0.08);
    final iconColor = Colors.red[isDark ? 400 : 600];

    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onRemove,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: bgColor,
            ),
            child: Icon(
              Icons.close_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

