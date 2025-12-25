import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../domain/market_repository.dart';
import '../widgets/product_card.dart';
import 'product_details_page.dart';
import 'add_product_page.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/skeletons.dart';

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({super.key});

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  String? _error;

  late MarketRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = context.read<MarketRepository>();
    _scrollController.addListener(_onScroll);
    _loadProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      if (refresh) {
        _error = null;
      }
    });

    if (refresh) {
      _offset = 0;
      _products = [];
      _hasMore = true;
    }

    try {
      final results = await _repository.getMyProducts(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        offset: _offset,
        limit: _limit,
      );

      setState(() {
        if (refresh) {
          _products = results;
        } else {
          _products.addAll(results);
        }
        _hasMore = results.length == _limit;
        _offset += results.length;
      });
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    await _loadProducts();
  }

  Future<void> _onAddProduct() async {
    final created = await Navigator.push<Product?>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductPage()),
    );
    if (created != null) {
      // refresh list to include the newly created product at top
      await _loadProducts(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('my_products'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadProducts(refresh: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddProduct,
        icon: const Icon(Icons.add),
        label: Text('market_add_product'.tr),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProducts(refresh: true),
        child: Padding(
          padding: const EdgeInsets.all(UI.md),
          child: Column(
            children: [
              _buildSearchField(),
              const SizedBox(height: UI.md),
              Expanded(
                child: _buildBody(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'market_search_products'.tr,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _loadProducts(refresh: true);
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UI.rMd),
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _loadProducts(refresh: true),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading && _products.isEmpty) {
      return const _GridSkeleton();
    }

    if (_error != null && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadProducts(refresh: true),
              child: Text('retry'.tr),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 48),
            const SizedBox(height: 8),
            Text('market_no_products'.tr),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: UI.sm,
            mainAxisSpacing: UI.sm,
            childAspectRatio: 0.7,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
            return ProductCard(
              product: product,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsPage(
                      productId: product.productId,
                    ),
                  ),
                );
              },
            );
          },
        ),
        if (_isLoadingMore)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(UI.sm),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UI.md,
                    vertical: UI.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black54 : Colors.white,
                    borderRadius: BorderRadius.circular(UI.rSm),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonProductGrid(itemCount: 6);
  }
}
