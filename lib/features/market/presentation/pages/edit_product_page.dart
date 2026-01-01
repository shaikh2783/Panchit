import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/market/data/services/product_management_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:snginepro/main.dart' show configCfgP;
import 'package:snginepro/features/market/domain/market_repository.dart';
import 'package:snginepro/features/market/data/models/models.dart';
import 'package:snginepro/core/widgets/html_text_widget.dart';

class EditProductPage extends StatefulWidget {
  final Post product;
  final Function(Post)? onProductUpdated;

  const EditProductPage({
    super.key,
    required this.product,
    this.onProductUpdated,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late ProductManagementService _productService;
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _productUrlController;
  late TextEditingController _productFileController;

  String _selectedStatus = 'new';
  bool _isSubmitting = false;
  bool _isDigital = false;

  String? _uploadedFileSource;
  String? _uploadedFileName;
  bool _fileUploading = false;
  double _fileUploadProgress = 0;

  List<ProductCategory> _categories = [];
  bool _categoriesLoading = false;
  String? _categoriesError;
  int? _selectedCategoryId;
  late MarketRepository _repository;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _productService = ProductManagementService(apiClient);
    _repository = context.read<MarketRepository>();

    // Initialize controllers with product data
    _nameController = TextEditingController(text: widget.product.text);
    _priceController = TextEditingController(
      text: widget.product.postPrice?.toString() ?? '',
    );
    _quantityController = TextEditingController(text: '1');
    _locationController = TextEditingController(
      text: widget.product.productLocation ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.product.campaignDescription ?? '',
    );
    _productUrlController = TextEditingController(
      text: widget.product.productUrl ?? '',
    );
    _productFileController = TextEditingController(
      text: widget.product.productFile ?? '',
    );
    
    // Set digital status
    _isDigital = widget.product.isDigital;
    
    // Set status and category
    _selectedStatus = widget.product.productStatus ?? 'new';
    
    // Try to parse category ID if available
    if (widget.product.productCategoryName != null) {
      // Will be matched when categories load
    }

    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _productUrlController.dispose();
    _productFileController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);

    try {
      final price = double.parse(_priceController.text.trim());
      final quantity = int.parse(_quantityController.text.trim());
      final categoryId = _selectedCategoryId;

      final product = await _productService.editProduct(
        postId: widget.product.id,
        name: _nameController.text.trim(),
        price: price,
        quantity: quantity,
        status: _selectedStatus,
        location: _locationController.text.trim(),
        categoryId: categoryId,
        description: _descriptionController.text.trim(),
        isDigital: _isDigital,
        productUrl: _isDigital ? _productUrlController.text.trim() : null,
        productFile: _isDigital
            ? (_uploadedFileSource ?? _productFileController.text.trim())
            : null,
      );

      if (!mounted) return;

      // Update product data using API response
      final updatedProduct = widget.product.copyWith(
        text: product.name.isNotEmpty ? product.name : _nameController.text.trim(),
        postPrice: double.tryParse(product.price) ?? price,
        available: product.status == 'available',
        productName: product.name,
        productStatus: product.status,
        productLocation: _locationController.text.trim(),
        productCategoryName: _categories.firstWhere(
          (cat) => cat.categoryId == categoryId,
          orElse: () => _categories.first,
        ).categoryName,
        isDigital: _isDigital,
        productUrl: _isDigital ? _productUrlController.text.trim() : null,
        productFile: _isDigital ? (_uploadedFileSource ?? _productFileController.text.trim()) : null,
      );

      widget.onProductUpdated?.call(updatedProduct);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('product_updated_successfully'.tr)),
      );

      Navigator.pop(context, updatedProduct);
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'error_updating_product'.tr;
      if (e.toString().contains('Invalid')) {
        errorMessage = 'invalid_product_data'.tr;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty) {
      _showError('product_name_required'.tr);
      return false;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      _showError('valid_price_required'.tr);
      return false;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity < 0) {
      _showError('valid_quantity_required'.tr);
      return false;
    }

    if (_isDigital) {
      final url = _productUrlController.text.trim();
      if (url.isEmpty) {
        _showError('required'.tr);
        return false;
      }
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('edit_product'.tr), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Digital toggle and fields
            _buildDigitalSection(),
            const SizedBox(height: 16),
            // Product Name
            _buildTextField(
              controller: _nameController,
              label: 'product_name'.tr,
              hint: 'enter_product_name'.tr,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Price
            _buildTextField(
              controller: _priceController,
              label: 'price'.tr,
              hint: 'enter_price'.tr,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            // Quantity
            _buildTextField(
              controller: _quantityController,
              label: 'quantity'.tr,
              hint: 'enter_quantity'.tr,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Status
            _buildStatusDropdown(),
            const SizedBox(height: 16),

            // Category Picker
            _buildCategoryPicker(),
            const SizedBox(height: 16),

            // Location
            _buildTextField(
              controller: _locationController,
              label: 'location'.tr,
              hint: 'enter_location'.tr,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'description'.tr,
              hint: 'enter_product_description'.tr,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.grey[700]! : Colors.grey[600]!,
                          ),
                        ),
                      )
                    : Text(
                        'save_changes'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: Text('cancel'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'product_status'.tr,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedStatus,
          items: [
            DropdownMenuItem(value: 'new', child: Text('status_new'.tr)),
            DropdownMenuItem(value: 'old', child: Text('status_old'.tr)),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedStatus = value);
            }
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          value: _isDigital,
          onChanged: (v) => setState(() => _isDigital = v),
          title: Text('market_digital'.tr),
          subtitle: Text('market_digital_hint'.tr),
          contentPadding: EdgeInsets.zero,
        ),
        if (_isDigital) ...[
          _buildTextField(
            controller: _productUrlController,
            label: 'market_download_url'.tr,
            hint: 'market_product_url'.tr,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          _buildFileUploadRow(),
        ],
      ],
    );
  }

  Widget _buildFileUploadRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('market_upload_file'.tr)),
            ElevatedButton.icon(
              onPressed: _fileUploading ? null : _pickAndUploadDigitalFile,
              icon: _fileUploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.attach_file),
              label: Text(
                _fileUploading
                    ? '${('loading'.tr)} ${((_fileUploadProgress * 100).toInt())}%'
                    : 'upload'.tr,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _uploadedFileName ?? 'market_file_none'.tr,
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadDigitalFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'zip', 'json', 'docx', 'pdf'],
        allowMultiple: false,
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      setState(() {
        _fileUploading = true;
        _fileUploadProgress = 0;
      });

      final apiClient = context.read<ApiClient>();
      final endpoint = configCfgP('file_upload');
      final response = await apiClient.multipartPost(
        endpoint,
        body: {'type': 'file'},
        filePath: file.path,
        fileFieldName: 'file',
        onProgress: (sent, total) {
          if (!mounted) return;
          setState(() => _fileUploadProgress = total == 0 ? 0 : sent / total);
        },
      );

      if (response['status'] == 'success') {
        final data = response['data'] as Map<String, dynamic>;
        final source = data['source']?.toString();
        setState(() {
          _uploadedFileSource = source;
          _uploadedFileName = result.files.single.name;
          _productFileController.text = source ?? '';
        });
      } else {
        Get.snackbar(
          'error'.tr,
          response['message']?.toString() ?? 'upload_failed'.tr,
        );
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _fileUploading = false);
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });
    try {
      final list = await _repository.getCategories();
      if (!mounted) return;
      
      // Try to match existing category by name
      int? matchedCategoryId;
      if (widget.product.productCategoryName != null && list.isNotEmpty) {
        final matched = list.firstWhere(
          (cat) => cat.categoryName.toLowerCase() == widget.product.productCategoryName?.toLowerCase(),
          orElse: () => list.first,
        );
        matchedCategoryId = matched.categoryId;
      } else if (list.isNotEmpty) {
        matchedCategoryId = list.first.categoryId;
      }
      
      setState(() {
        _categories = list;
        if (_selectedCategoryId == null) {
          _selectedCategoryId = matchedCategoryId;
        }
      });
    } catch (e) {
      setState(() => _categoriesError = e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  Widget _buildCategoryPicker() {
    if (_categoriesLoading && _categories.isEmpty) {
      return Row(
        children: const [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: InputDecoration(labelText: 'market_category'.tr),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: c.categoryId,
                        child: HtmlTextWidget(htmlContent: c.categoryName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) => v == null ? 'required'.tr : null,
              ),
            ),
            IconButton(
              tooltip: 'refresh'.tr,
              icon: _categoriesLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _categoriesLoading ? null : _loadCategories,
            ),
          ],
        ),
        if (_categoriesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _categoriesError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
