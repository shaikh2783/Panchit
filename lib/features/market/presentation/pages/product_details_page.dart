import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/utils/html_decoder.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../data/models/models.dart';
import '../../domain/market_repository.dart';
import '../../application/bloc/cart/cart_bloc.dart';
import '../../application/bloc/cart/cart_event.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/messenger/data/services/messenger_api_service.dart';
import 'package:snginepro/features/messenger/presentation/pages/chat_page.dart';

/// Product Details Page - صفحة تفاصيل المنتج
/// 
/// عرض جميع تفاصيل المنتج مع إمكانية الإضافة للسلة
class ProductDetailsPage extends StatefulWidget {
  final String productId;

  const ProductDetailsPage({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  Product? _product;
  bool _isLoading = true;
  String? _error;
  int _quantity = 1;
  int _currentPhotoIndex = 0;

  String _decodeHtml(String s) {
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = context.read<MarketRepository>();
      final product = await repository.getProductDetails(widget.productId);
      
      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _addToCart() {
    if (_product == null || !_product!.isAvailable) return;

    context.read<CartBloc>().add(
      AddToCartEvent(
        productId: _product!.productId,
        quantity: _quantity,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إضافة المنتج للسلة'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _contactSeller() async {
    if (_product == null) return;

    final sellerId = _product!.seller.userId;
    
    // Check if user is trying to chat with themselves
    final authNotifier = context.read<AuthNotifier>();
    final currentUser = authNotifier.currentUser;
    final currentUserId = currentUser?['user_id'] as int?;
    
    if (currentUserId != null && currentUserId == sellerId) {
      Get.snackbar(
        'error'.tr,
        'cannot_chat_with_yourself'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Show loading
    Get.dialog(
      Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // Get or create conversation with seller
      final apiClient = context.read<ApiClient>();
      final messengerService = MessengerApiService(apiClient);

      final conversation = await messengerService.getOrCreateConversation(
        userId: sellerId.toString(),
      );

      Get.back(); // Close loading dialog

      if (conversation == null) {
        Get.snackbar(
          'error'.tr,
          'chat_privacy_settings_prevent'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Navigate to chat page
      Get.to(
        () => ChatPage(
          conversationId: conversation.conversationId,
          otherUser: conversation.otherUser,
        ),
      );
    } catch (e) {
      Get.back(); // Close loading dialog

      // Parse error message
      String errorMessage = 'failed_to_open_chat'.tr;
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('403')) {
        if (errorStr.contains('friends only') ||
            errorStr.contains('صداقة فقط') ||
            errorStr.contains('chat privacy is set to friends')) {
          errorMessage = 'chat_privacy_friends_only'.tr;
        } else if (errorStr.contains('following') ||
            errorStr.contains('متابعين')) {
          errorMessage = 'chat_privacy_following_only'.tr;
        } else if (errorStr.contains('لا يمكنك') || 
            errorStr.contains('cannot') ||
            errorStr.contains('not allowed')) {
          errorMessage = 'chat_seller_privacy_restricted'.tr;
        } else {
          errorMessage = 'chat_privacy_settings_prevent'.tr;
        }
      } else if (errorStr.contains('not found') ||
          errorStr.contains('غير موجود')) {
        errorMessage = 'user_not_found'.tr;
      }

      Get.snackbar(
        'error'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UI.surfacePage(context),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildProductDetails(),
      bottomNavigationBar: _product != null && _product!.isAvailable
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'error'.tr,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(_error ?? '', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProduct,
            child: Text('retry'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          flexibleSpace: const FlexibleSpaceBar(
            background: SkeletonBox(height: 320, radius: 0),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(UI.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 24, width: 220),
                SizedBox(height: UI.sm),
                SkeletonBox(height: 24, width: 100),
                SizedBox(height: UI.xl),
                SkeletonBox(height: 16, width: 160),
                SizedBox(height: UI.sm),
                SkeletonBox(height: 16, width: 140),
                SizedBox(height: UI.sm),
                SkeletonBox(height: 16, width: 120),
                SizedBox(height: UI.sm),
                SkeletonBox(height: 16, width: 180),
                SizedBox(height: UI.xl),
                SkeletonBox(height: 18, width: 120),
                SizedBox(height: UI.sm),
                SkeletonBox(height: 80),
                SizedBox(height: UI.xl),
                SkeletonBox(height: 18, width: 90),
                SizedBox(height: UI.md),
                SkeletonBox(height: 72),
                SizedBox(height: UI.lg),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails() {
    if (_product == null) return const SizedBox();

    final scheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        // App Bar with images
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: UI.surfacePage(context),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildImageGallery(),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _product!.isFavorite 
                    ? Icons.favorite 
                    : Icons.favorite_border,
                color: Colors.redAccent,
              ),
              onPressed: () {
                // Toggle favorite
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Share product
              },
            ),
          ],
        ),

        // Product Details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(UI.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _product!.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Text(
                      _product!.formattedPrice,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: UI.lg),

                // Product Info Cards
                _buildInfoRow(
                  Icons.category,
                  'category'.tr,
                  HtmlDecoder.decode(_product!.categoryName),
                ),
                _buildInfoRow(
                  Icons.check_circle_outline,
                  'condition'.tr,
                  _product!.conditionDisplay,
                ),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'location'.tr,
                  _product!.location,
                ),
                if (_product!.isDigital)
                  _buildInfoRow(
                    Icons.cloud_download,
                    'type'.tr,
                    _product!.productTypeDisplay,
                  ),
                _buildInfoRow(
                  Icons.inventory_2_outlined,
                  'stock'.tr,
                  _product!.quantity > 0
                      ? 'pieces_available'.trParams({'count': _product!.quantity.toString()})
                      : 'not_available'.tr,
                  color: _product!.isInStock ? Colors.green : Colors.red,
                ),

                const Divider(height: UI.xl * 1.5),

                // Description
                Text(
                  'description'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: UI.sm),
                Text(
                  _decodeHtml(_product!.description),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, color: UI.subtleText(context)),
                ),

                const Divider(height: UI.xl * 1.5),

                // Seller Info
                Text(
                  'market_seller'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: UI.md),
                _buildSellerCard(),

                const SizedBox(height: 80), // Space for bottom bar
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    final photos = _product?.photos ?? [];
    
    if (photos.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Icon(
          Icons.image_outlined,
          size: 80,
          color: Colors.grey[400],
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: photos.length,
          onPageChanged: (index) {
            setState(() => _currentPhotoIndex = index);
          },
          itemBuilder: (context, index) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 80),
                    );
                  },
                ),
                // Bottom gradient for readability
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 120,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Photo indicator
        if (photos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photos.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPhotoIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    final subtle = UI.subtleText(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UI.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: subtle),
          const SizedBox(width: UI.md),
          Text(
            '$label: ',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: subtle, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard() {
    final seller = _product!.seller;

    return Container(
      decoration: BoxDecoration(
        color: UI.surfaceCard(context),
        borderRadius: BorderRadius.circular(UI.rLg),
        boxShadow: UI.softShadow(context),
      ),
      padding: const EdgeInsets.all(UI.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: seller.userPicture.isNotEmpty
                ? CachedNetworkImageProvider(seller.userPicture)
                : null,
            child: seller.userPicture.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: UI.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller.userName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('ID: ${seller.userId}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: UI.subtleText(context))),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(UI.rLg),
            onTap: _contactSeller,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: UI.lg, vertical: UI.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(UI.rLg),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                  const SizedBox(width: UI.sm),
                  Text('chat_with_seller'.tr,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(UI.lg),
      decoration: BoxDecoration(
        color: UI.surfaceCard(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity Selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(UI.rMd),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  Text(
                    _quantity.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _quantity < (_product?.quantity ?? 0)
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(width: UI.lg),

            // Add to Cart Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_cart),
                label: Text('market_add_to_cart'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UI.rLg),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
