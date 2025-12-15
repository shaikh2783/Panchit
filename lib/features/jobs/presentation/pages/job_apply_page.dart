import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../domain/jobs_repository.dart';
class JobApplyPage extends StatefulWidget {
  final int jobId;
  const JobApplyPage({super.key, required this.jobId});
  @override
  State<JobApplyPage> createState() => _JobApplyPageState();
}
class _JobApplyPageState extends State<JobApplyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _workCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _workCtrl.dispose();
    _positionCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final repo = context.read<JobsRepository>();
      final ok = await repo.applyToJob(widget.jobId, {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        if (_workCtrl.text.trim().isNotEmpty) 'where_did_you_work': _workCtrl.text.trim(),
        if (_positionCtrl.text.trim().isNotEmpty) 'position': _positionCtrl.text.trim(),
        if (_fromCtrl.text.trim().isNotEmpty) 'from': _fromCtrl.text.trim(),
        if (_toCtrl.text.trim().isNotEmpty) 'to': _toCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      });
      if (ok) {
        Get.back();
        Get.snackbar('success'.tr, 'job_applied_successfully'.tr);
      } else {
        Get.snackbar('error'.tr, 'operation_failed'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('apply_now'.tr)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(UI.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: 'name'.tr, prefixIcon: const Icon(Iconsax.user_copy)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
              ),
              SizedBox(height: UI.md),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: 'email'.tr, prefixIcon: const Icon(Iconsax.sms_copy)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
              ),
              SizedBox(height: UI.md),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: 'phone'.tr, prefixIcon: const Icon(Iconsax.call_copy)),
              ),
              SizedBox(height: UI.md),
              TextFormField(
                controller: _locationCtrl,
                decoration: InputDecoration(labelText: 'location'.tr, prefixIcon: const Icon(Iconsax.location_copy)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
              ),
              SizedBox(height: UI.lg),
              Text('where_did_you_work'.tr, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: UI.sm),
              TextField(
                controller: _workCtrl,
                decoration: const InputDecoration(prefixIcon: Icon(Iconsax.buildings_copy)),
              ),
              SizedBox(height: UI.md),
              Text('position_job'.tr, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: UI.sm),
              TextField(
                controller: _positionCtrl,
                decoration: const InputDecoration(prefixIcon: Icon(Iconsax.briefcase_copy)),
              ),
              SizedBox(height: UI.md),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _fromCtrl,
                    decoration: InputDecoration(labelText: 'from'.tr, prefixIcon: const Icon(Iconsax.calendar_1_copy)),
                  ),
                ),
                SizedBox(width: UI.md),
                Expanded(
                  child: TextField(
                    controller: _toCtrl,
                    decoration: InputDecoration(labelText: 'to'.tr, prefixIcon: const Icon(Iconsax.calendar_1_copy)),
                  ),
                ),
              ]),
              SizedBox(height: UI.md),
              Text('description'.tr, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: UI.sm),
              TextField(
                controller: _descCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(prefixIcon: Icon(Iconsax.document_text_copy)),
              ),
              SizedBox(height: UI.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Iconsax.send_2_copy, size: 18),
                  label: Text('apply_now'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
