import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../data/models/models.dart';
import '../../domain/market_repository.dart';
import '../widgets/product_card.dart';
import 'product_details_page.dart';
import 'cart_page.dart';
import 'orders_page.dart';
import 'add_product_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/utils/html_decoder.dart';
import '../../../../core/widgets/skeletons.dart';

/// Products Page - صفحة المنتجات
///
/// عرض قائمة المنتجات مع إمكانية البحث والفلترة حسب الفئة
class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  late MarketRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = context.read<MarketRepository>();
    _loadCategories();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _repository.getCategories();
      if (mounted) {
        setState(() => _categories = categories);
      }
    } catch (e) {
      _showError('${'market_error_loading_categories'.tr}: $e');
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _offset = 0;
        _products.clear();
        _hasMore = true;
      }
    });

    try {
      final products = await _repository.getProducts(
        categoryId: _selectedCategoryId,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        offset: _offset,
        limit: _limit,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _products = products;
          } else {
            _products.addAll(products);
          }
          _hasMore = products.length >= _limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('${'market_error_loading_products'.tr}: $e');
      }
    }
  }

  Future<void> _loadMore() async {
    _offset += _limit;
    await _loadProducts();
  }

  void _onCategoryChanged(int? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _loadProducts(refresh: true);
  }

  void _onSearchChanged() {
    _loadProducts(refresh: true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('market_title'.tr),
        actions: [
          // Add Product
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'market_create_product'.tr,
            onPressed: () {
              Get.to(() => const AddProductPage());
            },
          ),
          // Orders Icon
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Get.to(() => const OrdersPage());
            },
          ),
          // Cart Icon
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Get.to(() => const CartPage());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'market_search_hint'.tr,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UI.rMd),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UI.rMd),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UI.rMd),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (_) => _onSearchChanged(),
            ),
          ),

          // Categories Filter
          if (_categories.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CategoryChip(
                      label: 'market_category_all'.tr,
                      isSelected: _selectedCategoryId == null,
                      onTap: () => _onCategoryChanged(null),
                    );
                  }
                  final category = _categories[index - 1];
                  return _CategoryChip(
                    label: HtmlDecoder.decode(category.categoryName),
                    isSelected: _selectedCategoryId == category.categoryId,
                    onTap: () => _onCategoryChanged(category.categoryId),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Products Grid
          Expanded(
            child: _products.isEmpty
                ? (_isLoading
                      ? const SkeletonProductGrid()
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: UI.subtleText(context),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'market_empty'.tr,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: UI.subtleText(context),
                                ),
                              ),
                            ],
                          ),
                        ))
                : RefreshIndicator(
                    onRefresh: () => _loadProducts(refresh: true),
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _products.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _products.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return ProductCard(
                          product: _products[index],
                          onTap: () {
                            Get.to(
                              () => ProductDetailsPage(
                                productId: _products[index].productId,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppColors.brandGlow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => Get.to(() => const AddProductPage()),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'market_create_product'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Category Chip Widget — pill tab matching the home feed's filter bar.
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final borderColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            gradient: isSelected ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(28),
            boxShadow: isDark ? AppColors.darkShadow : AppColors.lightShadow,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : cs.onSurface.withValues(alpha: 0.75)),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              letterSpacing: isSelected ? 0.1 : 0,
            ),
          ),
        ),
      ),
    );
  }
}
