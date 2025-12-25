import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/theme/ui_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../data/models/offer.dart';
import '../../data/models/offer_category.dart';
import '../../domain/offers_repository.dart';
import '../../data/services/offers_api_service.dart';

class OfferEditPage extends StatefulWidget {
  final Offer offer;
  const OfferEditPage({super.key, required this.offer});

  @override
  State<OfferEditPage> createState() => _OfferEditPageState();
}

class _OfferEditPageState extends State<OfferEditPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _discountPercentCtrl;
  late final TextEditingController _discountAmountCtrl;
  late final TextEditingController _endDateCtrl;
  
  List<OfferCategory> _categories = [];
  int? _categoryId;
  String _discountType = 'discount_percent';
  bool _loading = false;
  List<File> _selectedImages = [];
  List<Map<String, dynamic>> _uploadedPhotos = [];
  bool _uploadingPhotos = false;
  double _uploadProgress = 0;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.offer.title);
    _descCtrl = TextEditingController(text: widget.offer.description);
    _priceCtrl = TextEditingController(text: widget.offer.price?.toString() ?? '');
    _discountPercentCtrl = TextEditingController(text: widget.offer.discountPercent?.toString() ?? '');
    _discountAmountCtrl = TextEditingController(text: widget.offer.discountAmount?.toString() ?? '');
    _endDateCtrl = TextEditingController(text: widget.offer.endDate ?? '');
    _categoryId = widget.offer.categoryId;
    _discountType = widget.offer.discountType ?? 'discount_percent';
    if (widget.offer.endDate != null) {
      try {
        _selectedDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(widget.offer.endDate!);
      } catch (_) {}
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountPercentCtrl.dispose();
    _discountAmountCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final repo = context.read<OffersRepository>();
      final cats = await repo.getCategories();
      setState(() => _categories = cats);
    } catch (e) {
      if (mounted) {
        Get.snackbar('error'.tr, 'Failed to load categories: $e');
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages = pickedFiles.map((p) => File(p.path)).toList();
        });
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'Failed to pick images: $e');
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
      );
      if (time != null) {
        final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        setState(() {
          _selectedDate = combined;
          _endDateCtrl.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(combined);
        });
      }
    }
  }

  Future<void> _uploadPhotos() async {
    if (_selectedImages.isEmpty) {
      Get.snackbar('info'.tr, 'Please select images first');
      return;
    }

    setState(() => _uploadingPhotos = true);
    try {
      final apiService = OffersApiService(context.read());

      for (int i = 0; i < _selectedImages.length; i++) {
        try {
          final result = await apiService.uploadImage(
            _selectedImages[i],
            onProgress: (sent, total) {
              if (mounted) {
                setState(() => _uploadProgress = (i + (sent / total)) / _selectedImages.length);
              }
            },
          );
          setState(() {
            _uploadedPhotos.add(result);
          });
        } catch (e) {
          Get.snackbar('error'.tr, 'Failed to upload image ${i + 1}: $e');
        }
      }

      if (_uploadedPhotos.isNotEmpty) {
        Get.snackbar('success'.tr, '${_uploadedPhotos.length} images uploaded');
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhotos = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'Title is required');
      return;
    }
    if (_categoryId == null || _categoryId == 0) {
      Get.snackbar('error'.tr, 'category'.tr + ' ' + 'is_required'.tr);
      return;
    }

    // Validate discount values
    if (_discountType == 'discount_percent') {
      final discountValue = double.tryParse(_discountPercentCtrl.text.trim());
      if (discountValue == null || discountValue <= 0 || discountValue > 100) {
        Get.snackbar('error'.tr, 'Discount percent must be between 1-100');
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final repo = context.read<OffersRepository>();
      final body = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _categoryId,
        'discount_type': _discountType,
        if (_discountType == 'discount_percent' && _discountPercentCtrl.text.isNotEmpty)
          'discount_percent': int.tryParse(_discountPercentCtrl.text.trim()),
        if (_discountType == 'discount_amount' && _discountAmountCtrl.text.isNotEmpty)
          'discount_amount': _discountAmountCtrl.text.trim(),
        if (_priceCtrl.text.isNotEmpty) 'price': _priceCtrl.text.trim(),
        if (_endDateCtrl.text.isNotEmpty) 'end_date': _endDateCtrl.text.trim(),
        'photos': _uploadedPhotos.isNotEmpty
            ? _uploadedPhotos.map((p) => {'source': p['source'] ?? p['file'], 'blur': 0}).toList()
            : [],
      };
      await repo.updateOffer(int.parse(widget.offer.postId), body);
      Get.back();
      Get.snackbar('success'.tr, 'offer_updated_successfully'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit_offer'.tr),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('save'.tr),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(UI.lg),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(labelText: 'offer_title'.tr, border: const OutlineInputBorder()),
          ),
          SizedBox(height: UI.md),
          TextField(
            controller: _descCtrl,
            decoration: InputDecoration(labelText: 'description'.tr, border: const OutlineInputBorder()),
            maxLines: 4,
          ),
          SizedBox(height: UI.md),
          DropdownButtonFormField<int>(
            value: _categoryId,
            decoration: InputDecoration(
              labelText: 'category'.tr + ' *',
              border: const OutlineInputBorder(),
              helperText: _categories.isEmpty ? 'loading'.tr : null,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Select Category')),
              ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title))).toList(),
            ],
            onChanged: (val) => setState(() => _categoryId = val),
            validator: (val) => val == null || val == 0 ? 'category'.tr + ' ' + 'is_required'.tr : null,
          ),
          SizedBox(height: UI.md),
          DropdownButtonFormField<String>(
            value: _discountType,
            decoration: InputDecoration(labelText: 'discount_type'.tr, border: const OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'discount_percent', child: Text('Discount Percent')),
              DropdownMenuItem(value: 'discount_amount', child: Text('Discount Amount')),
              DropdownMenuItem(value: 'free_shipping', child: Text('Free Shipping')),
            ],
            onChanged: (val) => setState(() => _discountType = val!),
          ),
          SizedBox(height: UI.md),
          if (_discountType == 'discount_percent')
            TextField(
              controller: _discountPercentCtrl,
              decoration: InputDecoration(labelText: 'discount_percent'.tr, border: const OutlineInputBorder(), suffixText: '%'),
              keyboardType: TextInputType.number,
            ),
          if (_discountType == 'discount_amount')
            TextField(
              controller: _discountAmountCtrl,
              decoration: InputDecoration(labelText: 'discount_amount'.tr, border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          SizedBox(height: UI.md),
          TextField(
            controller: _priceCtrl,
            decoration: InputDecoration(labelText: 'price'.tr, border: const OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: UI.md),
          TextField(
            controller: _endDateCtrl,
            decoration: InputDecoration(
              labelText: 'end_date'.tr,
              border: const OutlineInputBorder(),
              hintText: 'YYYY-MM-DD HH:MM:SS',
              suffixIcon: IconButton(
                icon:  Icon(Iconsax.cloud_plus),
                onPressed: _pickDate,
              ),
            ),
            readOnly: true,
          ),
          SizedBox(height: UI.md),
          Card(
            child: Padding(
              padding: EdgeInsets.all(UI.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('photos'.tr, style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: UI.sm),
                  if (_selectedImages.isEmpty && _uploadedPhotos.isEmpty)
                    OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: Icon(Iconsax.image_copy),
                      label: Text('add_photos'.tr),
                    )
                  else if (_selectedImages.isNotEmpty && _uploadedPhotos.isEmpty)
                    Column(
                      children: [
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (_, i) => Padding(
                              padding: EdgeInsets.only(right: UI.sm),
                              child: Stack(
                                children: [
                                  Image.file(_selectedImages[i], width: 120, height: 120, fit: BoxFit.cover),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedImages.removeAt(i)),
                                      child: Container(
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        padding: EdgeInsets.all(UI.xs),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: UI.sm),
                        if (_uploadingPhotos)
                          Column(
                            children: [
                              LinearProgressIndicator(value: _uploadProgress),
                              SizedBox(height: UI.sm),
                              Text('${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _uploadPhotos,
                            icon: const Icon(Icons.cloud_upload),
                            label: Text('upload_photos'.tr),
                          ),
                        SizedBox(height: UI.sm),
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add),
                          label: Text('add_more'.tr),
                        ),
                      ],
                    )
                  else if (_uploadedPhotos.isNotEmpty)
                    Column(
                      children: [
                        Text('${_uploadedPhotos.length} photos uploaded',
                            style: const TextStyle(color: Colors.green)),
                        SizedBox(height: UI.sm),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _uploadedPhotos.length,
                            itemBuilder: (_, i) => Padding(
                              padding: EdgeInsets.only(right: UI.sm),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.green, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 50),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        color: Colors.black45,
                                        padding: EdgeInsets.all(UI.xs),
                                        child: Text(
                                          'photo ${i + 1}',
                                          style: const TextStyle(color: Colors.white, fontSize: 10),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: UI.sm),
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add),
                          label: Text('add_more'.tr),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
