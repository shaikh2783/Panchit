import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../../../../core/theme/ui_constants.dart';
import '../../domain/jobs_repository.dart';
import '../../data/models/job.dart';
import 'package:cached_network_image/cached_network_image.dart';
class JobEditPage extends StatefulWidget {
  const JobEditPage({super.key});
  @override
  State<JobEditPage> createState() => _JobEditPageState();
}
class _JobEditPageState extends State<JobEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late Job _job;
  bool _init = false;
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _salaryMinCtrl = TextEditingController();
  final _salaryMaxCtrl = TextEditingController();
  final _salaryMinCurrencyCtrl = TextEditingController(text: '24');
  final _salaryMaxCurrencyCtrl = TextEditingController(text: '24');
  int? _categoryId;
  String _payPer = 'per_month';
  String _type = 'full_time';
  bool _submitting = false;
  String? _coverSource;
  String? _coverUrl;
  bool _uploadingCover = false;
  double _uploadProgress = 0;
  List<JobCategory> _categories = [];
  bool _loadingCategories = true;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      _job = Get.arguments as Job;
      _titleCtrl.text = _job.title;
      _locationCtrl.text = _job.location;
      _salaryMinCtrl.text = (_job.salaryMin?.toString() ?? '');
      _salaryMaxCtrl.text = (_job.salaryMax?.toString() ?? '');
      _payPer = _job.paySalaryPer;
      _type = _job.type;
      _categoryId = _job.categoryId;
      _coverUrl = _job.cover.isNotEmpty ? _job.cover : null;
    }
    _loadCategories();
  }
  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _locationCtrl.dispose();
    _salaryMinCtrl.dispose();
    _salaryMaxCtrl.dispose();
    _salaryMinCurrencyCtrl.dispose();
    _salaryMaxCurrencyCtrl.dispose();
    super.dispose();
  }
  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final repo = context.read<JobsRepository>();
      final cats = await repo.getCategories();
      setState(() {
        _categories = cats;
        _loadingCategories = false;
      });
    } catch (_) {
      setState(() => _loadingCategories = false);
    }
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
  void _removeCover() {
    setState(() {
      _coverSource = null;
      _coverUrl = null;
      _uploadProgress = 0;
    });
  }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final repo = context.read<JobsRepository>();
      final body = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        if (_categoryId != null) 'category': _categoryId,
        'location': _locationCtrl.text.trim(),
        if (_salaryMinCtrl.text.isNotEmpty) 'salary_minimum': int.tryParse(_salaryMinCtrl.text),
        if (_salaryMinCurrencyCtrl.text.isNotEmpty) 'salary_minimum_currency': int.tryParse(_salaryMinCurrencyCtrl.text),
        if (_salaryMaxCtrl.text.isNotEmpty) 'salary_maximum': int.tryParse(_salaryMaxCtrl.text),
        if (_salaryMaxCurrencyCtrl.text.isNotEmpty) 'salary_maximum_currency': int.tryParse(_salaryMaxCurrencyCtrl.text),
        'pay_salary_per': _payPer,
        'type': _type,
        if (_coverSource != null && _coverSource!.isNotEmpty) 'cover_image': _coverSource,
      };
      await repo.updateJob(_job.postId, body);
      if (!mounted) return;
      Get.back();
      Get.snackbar('success'.tr, 'job_updated_successfully'.tr);
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
        title: Text('edit_job'.tr),
        actions: [
          TextButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Iconsax.send_2_copy, size: 18),
            label: Text('save'.tr),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(UI.lg),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  child: Row(children: [
                    ElevatedButton.icon(
                      onPressed: _uploadingCover ? null : _pickCover,
                      icon: const Icon(Iconsax.image_copy, size: 18),
                      label: Text(_coverUrl == null ? 'pick_image'.tr : 'replace_image'.tr),
                    ),
                    const SizedBox(width: 12),
                    if (_coverUrl != null)
                      TextButton.icon(
                        onPressed: _removeCover,
                        icon: const Icon(Iconsax.trash_copy, size: 18),
                        label: Text('remove'.tr),
                      ),
                  ]),
                ),
              ]),
            ),
            SizedBox(height: UI.lg),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(labelText: 'job_title'.tr, prefixIcon: const Icon(Iconsax.briefcase_copy)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
            ),
            SizedBox(height: UI.md),
            TextFormField(
              controller: _messageCtrl,
              decoration: InputDecoration(labelText: 'description'.tr, prefixIcon: const Icon(Iconsax.document_text_copy)),
              minLines: 3,
              maxLines: 6,
            ),
            SizedBox(height: UI.md),
            TextFormField(
              controller: _locationCtrl,
              decoration: InputDecoration(labelText: 'location'.tr, prefixIcon: const Icon(Iconsax.location_copy)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
            ),
            SizedBox(height: UI.md),
            InputDecorator(
              decoration: InputDecoration(labelText: 'category'.tr, prefixIcon: const Icon(Iconsax.category_2_copy)),
              child: _loadingCategories
                  ? const LinearProgressIndicator(minHeight: 2)
                  : DropdownButton<int>(
                      isExpanded: true,
                      value: _categoryId,
                      hint: Text('select_category'.tr),
                      underline: const SizedBox.shrink(),
                      items: _categories
                          .map((c) => DropdownMenuItem<int>(value: c.categoryId, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
            ),
            SizedBox(height: UI.md),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _salaryMinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'salary_min'.tr, prefixIcon: const Icon(Iconsax.money_recive_copy)),
                ),
              ),
              SizedBox(width: UI.md),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _salaryMinCurrencyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'currency_id'.tr),
                ),
              ),
            ]),
            SizedBox(height: UI.md),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _salaryMaxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'salary_max'.tr, prefixIcon: const Icon(Iconsax.money_recive_copy)),
                ),
              ),
              SizedBox(width: UI.md),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _salaryMaxCurrencyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'currency_id'.tr),
                ),
              ),
            ]),
            SizedBox(height: UI.md),
            InputDecorator(
              decoration: InputDecoration(labelText: 'pay_salary_per'.tr, prefixIcon: const Icon(Iconsax.calendar_1_copy)),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _payPer,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'per_hour', child: Text('Per Hour')),
                  DropdownMenuItem(value: 'per_day', child: Text('Per Day')),
                  DropdownMenuItem(value: 'per_week', child: Text('Per Week')),
                  DropdownMenuItem(value: 'per_month', child: Text('Per Month')),
                ],
                onChanged: (v) => setState(() => _payPer = v ?? 'per_month'),
              ),
            ),
            SizedBox(height: UI.md),
            InputDecorator(
              decoration: InputDecoration(labelText: 'type'.tr, prefixIcon: const Icon(Iconsax.briefcase_copy)),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _type,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'full_time', child: Text('Full Time')),
                  DropdownMenuItem(value: 'part_time', child: Text('Part Time')),
                  DropdownMenuItem(value: 'contract', child: Text('Contract')),
                  DropdownMenuItem(value: 'temporary', child: Text('Temporary')),
                  DropdownMenuItem(value: 'internship', child: Text('Internship')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'full_time'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
