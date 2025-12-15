import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../../../../core/theme/ui_constants.dart';
import '../../data/models/funding.dart';
import '../../domain/funding_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
class FundingEditPage extends StatefulWidget {
  final Funding funding;
  const FundingEditPage({super.key, required this.funding});
  @override
  State<FundingEditPage> createState() => _FundingEditPageState();
}
class _FundingEditPageState extends State<FundingEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late TextEditingController _titleCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _amountCtrl;
  bool _submitting = false;
  String? _coverSource;
  String? _coverUrl;
  bool _uploadingCover = false;
  double _uploadProgress = 0;
  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.funding.title);
    _descriptionCtrl = TextEditingController(text: widget.funding.description);
    _amountCtrl = TextEditingController(text: widget.funding.amount.toStringAsFixed(0));
    _coverSource = widget.funding.cover;
    _coverUrl = widget.funding.cover;
  }
  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }
  Future<void> _pickCover() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      setState(() {
        _uploadingCover = true;
        _uploadProgress = 0;
      });
      final client = context.read<ApiClient>();
      final response = await client.multipartPost(
        configCfgP('file_upload'),
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
        setState(() {
          _coverSource = data['source'];
          _coverUrl = (data['url'] ?? '') as String?;
        });
      } else {
        Get.snackbar('error'.tr, response['message']?.toString() ?? 'upload_failed'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coverSource == null) {
      Get.snackbar('error'.tr, 'cover_image_required'.tr);
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = context.read<FundingRepository>();
      final body = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'amount': double.tryParse(_amountCtrl.text) ?? 0,
        'cover_image': _coverSource,
      };
      await repo.updateFunding(int.parse(widget.funding.postId), body);
      if (!mounted) return;
      Get.back(result: true);
      Get.snackbar('success'.tr, 'funding_updated_successfully'.tr);
    } catch (e) {
      if (!mounted) return;
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit_funding'.tr),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _submitting
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'save'.tr,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : Material(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _submit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.tick_circle_copy,
                              size: 18,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'save'.tr,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(UI.lg),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Cover
            Container(
              decoration: BoxDecoration(
                color: UI.surfaceCard(context),
                borderRadius: BorderRadius.circular(UI.rLg),
                boxShadow: UI.softShadow(context),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_coverUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(UI.rLg)),
                    child: Stack(children: [
                      Image.network(_coverUrl!, height: 180, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey[300])),
                      if (_uploadingCover)
                        Positioned.fill(
                          child: Container(color: Colors.black26, child: Center(child: CircularProgressIndicator(value: _uploadProgress))),
                        ),
                    ]),
                  ),
                Padding(
                  padding: EdgeInsets.all(UI.lg),
                  child: ElevatedButton.icon(
                    onPressed: _uploadingCover ? null : _pickCover,
                    icon: const Icon(Iconsax.image_copy, size: 18),
                    label: Text('replace_image'.tr),
                  ),
                ),
              ]),
            ),
            SizedBox(height: UI.lg),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(labelText: 'funding_title'.tr, prefixIcon: const Icon(Iconsax.document_text_1_copy)),
              validator: (v) => (v == null || v.trim().length < 3) ? 'min_3_chars'.tr : null,
            ),
            SizedBox(height: UI.md),
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(labelText: 'goal_amount'.tr, prefixIcon: const Icon(Iconsax.money_recive_copy)),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'required'.tr;
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) return 'amount_must_be_positive'.tr;
                return null;
              },
            ),
            SizedBox(height: UI.md),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: InputDecoration(labelText: 'description'.tr, prefixIcon: const Icon(Iconsax.message_text_copy)),
              minLines: 4,
              maxLines: 8,
              validator: (v) => (v == null || v.trim().length < 16) ? 'min_16_chars'.tr : null,
            ),
          ]),
        ),
      ),
    );
  }
}
