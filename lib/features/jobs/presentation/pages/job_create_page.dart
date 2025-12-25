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
import '../../data/models/job_currency.dart';
import 'job_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class JobCreatePage extends StatefulWidget {
  const JobCreatePage({super.key});

  @override
  State<JobCreatePage> createState() => _JobCreatePageState();
}

class _JobCreatePageState extends State<JobCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _salaryMinCtrl = TextEditingController();
  final _salaryMaxCtrl = TextEditingController();
  final _salaryMinCurrencyCtrl = TextEditingController();
  final _salaryMaxCurrencyCtrl = TextEditingController();

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
  List<JobCurrency> _currencies = [];
  bool _loadingCurrencies = true;
  int? _salaryMinCurrencyId;
  int? _salaryMaxCurrencyId;

  @override
  void initState() {
    super.initState();
    _prime();
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

  Future<void> _loadCurrencies() async {
    setState(() => _loadingCurrencies = true);
    try {
      final repo = context.read<JobsRepository>();
      final list = await repo.getCurrencies();
      setState(() {
        _currencies = list;
        _loadingCurrencies = false;
      });
    } catch (_) {
      setState(() => _loadingCurrencies = false);
    }
  }

  Future<void> _prime() async {
    await Future.wait([_loadCategories(), _loadCurrencies()]);
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
    // Extra guard: if salary provided, currency must be provided
    if (_salaryMinCtrl.text.trim().isNotEmpty && _salaryMinCurrencyId == null) {
      Get.snackbar('error'.tr, 'currency_id'.tr + ' ' + 'required'.tr);
      return;
    }
    if (_salaryMaxCtrl.text.trim().isNotEmpty && _salaryMaxCurrencyId == null) {
      Get.snackbar('error'.tr, 'currency_id'.tr + ' ' + 'required'.tr);
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = context.read<JobsRepository>();
      final body = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        if (_categoryId != null) 'category': _categoryId,
        'location': _locationCtrl.text.trim(),
        if (_salaryMinCtrl.text.isNotEmpty) 'salary_minimum': int.tryParse(_salaryMinCtrl.text),
        if (_salaryMinCurrencyId != null) 'salary_minimum_currency': _salaryMinCurrencyId,
        if (_salaryMaxCtrl.text.isNotEmpty) 'salary_maximum': int.tryParse(_salaryMaxCtrl.text),
        if (_salaryMaxCurrencyId != null) 'salary_maximum_currency': _salaryMaxCurrencyId,
        'pay_salary_per': _payPer,
        'type': _type,
        if (_coverSource != null && _coverSource!.isNotEmpty) 'cover_image': _coverSource,
      };
      final created = await repo.createJob(body);
      if (!mounted) return;
      Get.snackbar('success'.tr, 'job_created_successfully'.tr);
      Get.off(() => JobDetailPage(jobId: created.postId));
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
        title: Text('create_job'.tr),
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
                          'publish'.tr,
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
                              Iconsax.send_2_copy,
                              size: 18,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'publish'.tr,
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

            // Category selector
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
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(labelText: 'currency_id'.tr),
                  child: _loadingCurrencies
                      ? const LinearProgressIndicator(minHeight: 2)
                      : DropdownButton<int?>(
                          isExpanded: true,
                          value: _salaryMinCurrencyId,
                          underline: const SizedBox.shrink(),
                          hint: Text('select_currency'.tr),
                          items: _currencies
                              .map((c) => DropdownMenuItem<int>(
                                    value: int.tryParse(c.id),
                                    child: Text('${c.code} (${c.symbol})'),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _salaryMinCurrencyId = v;
                            // If max salary is present but currency not chosen, mirror
                            if (_salaryMaxCtrl.text.trim().isNotEmpty && _salaryMaxCurrencyId == null) {
                              _salaryMaxCurrencyId = v;
                            }
                          }),
                        ),
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
                width: 160,
                child: InputDecorator(
                  decoration: InputDecoration(labelText: 'currency_id'.tr),
                  child: _loadingCurrencies
                      ? const LinearProgressIndicator(minHeight: 2)
                      : DropdownButton<int?>(
                          isExpanded: true,
                          value: _salaryMaxCurrencyId,
                          underline: const SizedBox.shrink(),
                          hint: Text('select_currency'.tr),
                          items: _currencies
                              .map((c) => DropdownMenuItem<int>(
                                    value: int.tryParse(c.id),
                                    child: Text('${c.code} (${c.symbol})'),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _salaryMaxCurrencyId = v),
                        ),
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
