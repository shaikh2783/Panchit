import 'package:flutter/material.dart';
import 'dart:io';

import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/main.dart' show configCfgP;

import '../../domain/market_repository.dart';
import '../../data/models/models.dart';
import '../../../../core/theme/ui_constants.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _productUrlCtrl = TextEditingController();
  final _productFileCtrl = TextEditingController();
  final _photosCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<String> _uploadedSources = [];
  bool _uploading = false;
  double _uploadProgress = 0;

  String? _uploadedFileSource;
  String? _uploadedFileName;
  bool _fileUploading = false;
  double _fileUploadProgress = 0;

  List<ProductCategory> _categories = [];
  bool _categoriesLoading = false;
  String? _categoriesError;
  int? _selectedCategoryId;

  String _status = 'new';
  bool _isDigital = false;
  bool _forAdult = false;
  bool _isSubmitting = false;

  late MarketRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = context.read<MarketRepository>();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _quantityCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _productUrlCtrl.dispose();
    _productFileCtrl.dispose();
    _photosCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _uploading = true;
        _uploadProgress = 0;
      });

      final apiClient = context.read<ApiClient>();
      final endpoint = configCfgP('file_upload');
      final response = await apiClient.multipartPost(
        endpoint,
        body: {'type': 'photo'},
        filePath: picked.path,
        fileFieldName: 'file',
        onProgress: (sent, total) {
          if (!mounted) return;
          setState(() => _uploadProgress = total == 0 ? 0 : sent / total);
        },
      );

      if (response['status'] == 'success') {
        final data = response['data'] as Map<String, dynamic>;
        final source = data['source']?.toString();
        if (source != null && source.isNotEmpty) {
          setState(() => _uploadedSources.add(source));
        }
      } else {
        Get.snackbar('error'.tr, response['message']?.toString() ?? 'upload_failed'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
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
      setState(() {
        _categories = list;
        if (_selectedCategoryId == null && list.isNotEmpty) {
          _selectedCategoryId = list.first.categoryId;
        }
      });
    } catch (e) {
      setState(() => _categoriesError = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text.trim());
    final quantity = int.tryParse(_quantityCtrl.text.trim());
    final categoryId = _selectedCategoryId;

    if (price == null || quantity == null || categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('market_invalid_fields'.tr)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final photos = _parsePhotos(_photosCtrl.text.trim());

      // Combine manually entered photos with uploaded ones
      final combinedPhotos = [
        ..._uploadedSources.map((s) => {'source': s}),
        ...photos,
      ];

      final product = await _repository.createProduct(
        name: _nameCtrl.text.trim(),
        price: price,
        quantity: quantity,
        categoryId: categoryId,
        status: _status,
        location: _locationCtrl.text.trim(),
        isDigital: _isDigital,
        productUrl: _isDigital ? _productUrlCtrl.text.trim() : '',
        productFile: _isDigital
            ? (_uploadedFileSource ?? _productFileCtrl.text.trim())
            : '',
        description: _descriptionCtrl.text.trim(),
        photos: combinedPhotos,
        forAdult: _forAdult,
      );

      if (!mounted) return;
      Navigator.pop<Product>(context, product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('market_product_created'.tr)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<Map<String, dynamic>> _parsePhotos(String input) {
    if (input.isEmpty) return const [];
    final parts = input
        .split(RegExp('[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.map((url) => {'source': url}).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('market_add_product'.tr),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(UI.lg),
            child: Column(
              children: [
                _buildDigitalSection(),
                _buildTextField(
                  controller: _nameCtrl,
                  label: 'market_product_name'.tr,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'required'.tr
                      : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _quantityCtrl,
                        label: 'market_quantity'.tr,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || int.tryParse(v) == null
                            ? 'required'.tr
                            : null,
                      ),
                    ),
                    const SizedBox(width: UI.sm),
                    Expanded(
                      child: _buildTextField(
                        controller: _priceCtrl,
                        label: 'market_price'.tr,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v == null || double.tryParse(v) == null
                            ? 'required'.tr
                            : null,
                      ),
                    ),
                  ],
                ),
                _buildCategoryPicker(),
                _buildStatusRow(),
                _buildTextField(
                  controller: _locationCtrl,
                  label: 'market_location'.tr,
                ),
                _buildTextField(
                  controller: _descriptionCtrl,
                  label: 'market_description'.tr,
                  maxLines: 3,
                ),
                _buildUploadRow(),
                _buildUploadedChips(),
                _buildTextField(
                  controller: _photosCtrl,
                  label: 'market_photos'.tr + ' (URLs, comma or newline separated)',
                  maxLines: 2,
                ),
                const SizedBox(height: UI.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSubmitting
                          ? 'loading'.tr
                          : 'market_submit_product'.tr,
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UI.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDigitalSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: UI.md),
      child: Column(
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
              controller: _productUrlCtrl,
              label: 'market_download_url'.tr,
            ),
            _buildFileUploadRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: UI.md),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(labelText: 'market_status'.tr),
              items: const [
                DropdownMenuItem(value: 'new', child: Text('New')),
                DropdownMenuItem(value: 'used', child: Text('Used')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'new'),
            ),
          ),
          const SizedBox(width: UI.sm),
          Expanded(
            child: SwitchListTile.adaptive(
              value: _forAdult,
              onChanged: (v) => setState(() => _forAdult = v),
              title: Text('market_for_adult'.tr),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker() {
    if (_categoriesLoading && _categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: UI.md),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: UI.sm),
            Text('loading'.tr),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: UI.md),
      child: Column(
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
                          child: Text(c.categoryName),
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
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: UI.md),
      child: Row(
        children: [
          Expanded(
            child: Text('market_photos'.tr),
          ),
          ElevatedButton.icon(
            onPressed: _uploading ? null : _pickAndUploadPhoto,
            icon: _uploading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_upload),
            label: Text(_uploading
                ? '${('loading'.tr)} ${( (_uploadProgress * 100).toInt())}%'
                : 'upload'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: UI.md),
      child: Column(
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.attach_file),
                label: Text(
                  _fileUploading
                      ? '${('loading'.tr)} ${( (_fileUploadProgress * 100).toInt())}%'
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
          const SizedBox(height: 4),
          Text(
            'market_file_types'.tr,
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedChips() {
    if (_uploadedSources.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: UI.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _uploadedSources
              .map(
                (src) => Chip(
                  label: Text(src.split('/').last),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () {
                    setState(() => _uploadedSources.remove(src));
                  },
                ),
              )
              .toList(),
        ),
      ),
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
          _productFileCtrl.text = source ?? '';
        });
      } else {
        Get.snackbar('error'.tr, response['message']?.toString() ?? 'upload_failed'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _fileUploading = false);
    }
  }
}
