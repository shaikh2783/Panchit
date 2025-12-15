import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/features/ads/domain/ads_repository.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'dart:io';
import '../widgets/campaign_form_field.dart';
import '../widgets/campaign_date_picker.dart';
import '../widgets/campaign_image_upload.dart';
class CreateCampaignPage extends StatefulWidget {
  const CreateCampaignPage({super.key, this.initialCampaign});
  final Map<String, dynamic>? initialCampaign; // when provided, page works in edit mode
  @override
  State<CreateCampaignPage> createState() => _CreateCampaignPageState();
}
class _CreateCampaignPageState extends State<CreateCampaignPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _adsTitleCtrl = TextEditingController();
  final _adsDescCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  String? _placement = 'newsfeed';
  String? _bidding = 'clicks';
  String? _adsType = 'url';
  final _adsUrlCtrl = TextEditingController();
  final _postUrlCtrl = TextEditingController();
  final _entityIdCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _gender = 'all';
  String? _relationship = 'all';
  List<String> _countries = [];
  String? _imageFilename; // uploaded filename returned by server
  String? _imagePreviewUrl; // absolute url for preview
  bool _submitting = false;
  bool _uploading = false;
  File? _selectedImageFile;
  int? _campaignId; // edit mode id
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    final init = widget.initialCampaign;
    if (init != null) {
      // Prefill fields from existing campaign
      _campaignId = int.tryParse((init['campaign_id'] ?? init['ads_id'] ?? '').toString());
      _titleCtrl.text = (init['campaign_title'] ?? init['ads_title'] ?? '')?.toString() ?? '';
      _adsTitleCtrl.text = (init['ads_title'] ?? '')?.toString() ?? '';
      _adsDescCtrl.text = (init['ads_description'] ?? '')?.toString() ?? '';
      _placement = (init['campaign_placement'] ?? init['placement'] ?? _placement)?.toString();
      // Normalize bidding: backend returns 'click'/'view', dropdown expects 'clicks'/'views'
      final rawBidding = (init['campaign_bidding'] ?? init['ads_bidding'] ?? _bidding)?.toString();
      _bidding = rawBidding == 'click' ? 'clicks' : (rawBidding == 'view' ? 'views' : rawBidding);
      _budgetCtrl.text = (init['campaign_budget'] ?? '')?.toString() ?? '';
      // Dates: expect ISO/date strings
      final start = (init['campaign_start_date'] ?? init['start_date'])?.toString();
      final end = (init['campaign_end_date'] ?? init['end_date'])?.toString();
      if (start != null && start.isNotEmpty) {
        _startDate = DateTime.tryParse(start);
        if (_startDate != null) {
          _startDateCtrl.text = CampaignDatePicker.formatDate(_startDate!);
        }
      }
      if (end != null && end.isNotEmpty) {
        _endDate = DateTime.tryParse(end);
        if (_endDate != null) {
          _endDateCtrl.text = CampaignDatePicker.formatDate(_endDate!);
        }
      }
      // Targeting
      _gender = (init['audience_gender'] ?? init['gender'] ?? _gender)?.toString();
      _relationship = (init['audience_relationship'] ?? init['relationship'] ?? _relationship)?.toString();
      final countries = init['audience_countries'];
      if (countries is List) {
        _countries = countries.map((e) => e.toString()).toList();
      } else if (countries is String && countries.isNotEmpty) {
        _countries = countries.split(',').map((e) => e.trim()).toList();
      }
      // Image
      final img = (init['ads_image'] ?? init['campaign_image'] ?? init['image'])?.toString();
      if (img != null && img.isNotEmpty) {
        _imageFilename = img;
        final config = context.read<AppConfig>();
        _imagePreviewUrl = config.mediaAsset(img).toString();
      }
      // Ad type specifics (best-effort)
      _adsType = (init['ads_type'] ?? _adsType)?.toString();
      _adsUrlCtrl.text = (init['ads_url'] ?? '')?.toString() ?? '';
      _postUrlCtrl.text = (init['ads_post_url'] ?? '')?.toString() ?? '';
      _entityIdCtrl.text = (init['ads_page_id'] ?? init['ads_group_id'] ?? init['ads_event_id'] ?? '')?.toString() ?? '';
    }
  }
  @override
  void dispose() {
    _titleCtrl.dispose();
    _adsTitleCtrl.dispose();
    _adsDescCtrl.dispose();
    _budgetCtrl.dispose();
    _adsUrlCtrl.dispose();
    _postUrlCtrl.dispose();
    _entityIdCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }
  Future<void> _uploadImage() async {
    if (_selectedImageFile == null) return;
    setState(() => _uploading = true);
    try {
      final apiClient = context.read<ApiClient>();
      final res = await apiClient.multipartPost(
        '/data/file/upload',
        body: {},
        filePath: _selectedImageFile!.path,
        fileFieldName: 'file',
        fileName: _selectedImageFile!.path.split('/').last,
      );
      if (res['data'] != null && res['data']['source'] != null) {
        setState(() {
          _imageFilename = res['data']['source'];
          final config = context.read<AppConfig>();
          _imagePreviewUrl = config.mediaAsset(res['data']['url'] ?? res['data']['source']).toString();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('upload_failed'.tr)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Additional validations per requirements
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('select_date'.tr)),
      );
      return;
    }
    final now = DateTime.now();
    if (_endDate!.isBefore(_startDate!) || _endDate!.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('operation_failed'.tr)),
      );
      return;
    }
    // Type-specific validations
    if (_adsType == 'url') {
      final u = _adsUrlCtrl.text.trim();
      final uri = Uri.tryParse(u);
      final uriOk = uri != null && uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
      if (!uriOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('invalid_url'.tr)),
        );
        return;
      }
    } else if (_adsType == 'post') {
      if (_postUrlCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('required'.tr)),
        );
        return;
      }
      // Force placement/newsfeed and no image for post type
      _placement = 'newsfeed';
      _imageFilename = null;
    } else if (_adsType == 'page' || _adsType == 'group' || _adsType == 'event') {
      if (_entityIdCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('required'.tr)),
        );
        return;
      }
    }
    // Image requirement unless post
    if (_adsType != 'post' && (_imageFilename == null || _imageFilename!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('upload_image'.tr)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = context.read<AdsRepository>();
      Map<String, dynamic> res;
      final payloadCommon = {
        'title': _titleCtrl.text.trim(),
        'placement': _placement!,
        'bidding': _bidding!,
        'budget': _budgetCtrl.text.trim(),
        'startDate': _startDate!.toIso8601String().substring(0, 10),
        'endDate': _endDate!.toIso8601String().substring(0, 10),
        'targeting': {
          'countries': _countries,
          'gender': _gender,
          'relationship': _relationship,
        },
        'adsType': _adsType,
        'adsUrl': _adsType == 'url' ? _adsUrlCtrl.text.trim() : null,
        'adsPostUrl': _adsType == 'post' ? _postUrlCtrl.text.trim() : null,
        'adsPageId': _adsType == 'page' ? _entityIdCtrl.text.trim() : null,
        'adsGroupId': _adsType == 'group' ? _entityIdCtrl.text.trim() : null,
        'adsEventId': _adsType == 'event' ? _entityIdCtrl.text.trim() : null,
        'imageFilename': _imageFilename,
        'adsTitle': _adsTitleCtrl.text.trim().isEmpty ? null : _adsTitleCtrl.text.trim(),
        'adsDescription': _adsDescCtrl.text.trim().isEmpty ? null : _adsDescCtrl.text.trim(),
      };
      if (_campaignId != null) {
        // Edit mode: call update
        res = await repo.api.updateCampaign(
          campaignId: _campaignId!,
          title: payloadCommon['title'] as String,
          placement: payloadCommon['placement'] as String,
          bidding: payloadCommon['bidding'] as String,
          budget: num.tryParse(payloadCommon['budget'] as String),
          startDate: payloadCommon['startDate'] as String,
          endDate: payloadCommon['endDate'] as String,
          targeting: payloadCommon['targeting'] as Map<String, dynamic>,
          adsType: payloadCommon['adsType'] as String?,
          adsUrl: payloadCommon['adsUrl'] as String?,
          adsPostUrl: payloadCommon['adsPostUrl'] as String?,
          adsPageId: payloadCommon['adsPageId'] as String?,
          adsGroupId: payloadCommon['adsGroupId'] as String?,
          adsEventId: payloadCommon['adsEventId'] as String?,
          imageFilename: payloadCommon['imageFilename'] as String?,
          adsTitle: payloadCommon['adsTitle'] as String?,
          adsDescription: payloadCommon['adsDescription'] as String?,
        );
      } else {
        // Create mode
        res = await repo.api.createCampaign(
        title: _titleCtrl.text.trim(),
        placement: _placement!,
        bidding: _bidding!,
        budget: _budgetCtrl.text.trim(),
        startDate: _startDate!.toIso8601String().substring(0, 10),
        endDate: _endDate!.toIso8601String().substring(0, 10),
        targeting: {
          'countries': _countries,
          'gender': _gender,
          'relationship': _relationship,
        },
        adsType: _adsType,
        adsUrl: _adsType == 'url' ? _adsUrlCtrl.text.trim() : null,
        adsPostUrl: _adsType == 'post' ? _postUrlCtrl.text.trim() : null,
        adsPageId: _adsType == 'page' ? _entityIdCtrl.text.trim() : null,
        adsGroupId: _adsType == 'group' ? _entityIdCtrl.text.trim() : null,
        adsEventId: _adsType == 'event' ? _entityIdCtrl.text.trim() : null,
        imageFilename: _imageFilename,
        adsTitle: _adsTitleCtrl.text.trim().isEmpty ? null : _adsTitleCtrl.text.trim(),
        adsDescription: _adsDescCtrl.text.trim().isEmpty ? null : _adsDescCtrl.text.trim(),
        );
      }
      final ok = (_campaignId != null ? (res['code'] == 200 || res['success'] == true) : (res['code'] == 201 || res['success'] == true));
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_campaignId != null ? 'ads_campaign_updated'.tr : 'ads_campaign_created'.tr)),
        );
        Get.back(result: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('operation_failed'.tr)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_campaignId != null ? 'edit_campaign'.tr : 'create_campaign'.tr),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Upload Section
            CampaignImageUpload(
              imageUrl: _imagePreviewUrl,
              onImagePicked: (file) {
                setState(() => _selectedImageFile = file);
              },
              onUpload: _uploadImage,
              isUploading: _uploading,
            ),
            const SizedBox(height: 24),
            // Ad Content Section
            CampaignSectionTitle(
              title: 'ads_content'.tr,
              icon: Iconsax.edit_2,
              subtitle: 'ads_content_subtitle'.tr,
            ),
            const SizedBox(height: 16),
            CampaignFormField(
              controller: _adsTitleCtrl,
              label: 'ads_title'.tr,
              hint: 'ads_title_hint'.tr,
              icon: Iconsax.text_block,
            ),
            const SizedBox(height: 16),
            CampaignFormField(
              controller: _adsDescCtrl,
              label: 'ads_description'.tr,
              hint: 'ads_description_hint'.tr,
              icon: Iconsax.document_text,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // Campaign Details Section
            CampaignSectionTitle(
              title: 'campaign_details'.tr,
              icon: Iconsax.setting_2,
              subtitle: 'campaign_details_subtitle'.tr,
            ),
            const SizedBox(height: 16),
            CampaignFormField(
              controller: _titleCtrl,
              label: 'campaign_title'.tr,
              hint: 'campaign_title_hint'.tr,
              icon: Iconsax.note_text,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
            ),
            const SizedBox(height: 16),
            CampaignDropdownField<String>(
              label: 'placement'.tr,
              value: _placement,
              icon: Iconsax.category,
              items: const [
                DropdownMenuItem(value: 'newsfeed', child: Text('Newsfeed')),
                DropdownMenuItem(value: 'sidebar', child: Text('Sidebar')),
              ],
              onChanged: (v) => setState(() => _placement = v),
            ),
            const SizedBox(height: 16),
            CampaignDropdownField<String>(
              label: 'bidding'.tr,
              value: _bidding,
              icon: Iconsax.chart,
              items: const [
                DropdownMenuItem(value: 'clicks', child: Text('Clicks')),
                DropdownMenuItem(value: 'views', child: Text('Views')),
              ],
              onChanged: (v) => setState(() => _bidding = v),
            ),
            const SizedBox(height: 16),
            CampaignDropdownField<String>(
              label: 'ad_type'.tr,
              value: _adsType,
              icon: Iconsax.link_1,
              items: const [
                DropdownMenuItem(value: 'url', child: Text('URL')),
                DropdownMenuItem(value: 'post', child: Text('Post')),
                DropdownMenuItem(value: 'page', child: Text('Page')),
                DropdownMenuItem(value: 'group', child: Text('Group')),
                DropdownMenuItem(value: 'event', child: Text('Event')),
              ],
              onChanged: (v) => setState(() => _adsType = v),
            ),
            const SizedBox(height: 16),
            if (_adsType == 'url')
              CampaignFormField(
                controller: _adsUrlCtrl,
                label: 'ad_url'.tr,
                hint: 'https://example.com',
                icon: Iconsax.link,
                keyboardType: TextInputType.url,
              ),
            if (_adsType == 'post')
              CampaignFormField(
                controller: _postUrlCtrl,
                label: 'post_url'.tr,
                hint: 'post_url_hint'.tr,
                icon: Iconsax.note_text,
              ),
            if (_adsType == 'page' || _adsType == 'group' || _adsType == 'event')
              CampaignFormField(
                controller: _entityIdCtrl,
                label: 'entity_id'.tr,
                hint: 'entity_id_hint'.tr,
                icon: Iconsax.hashtag,
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 16),
            CampaignFormField(
              controller: _budgetCtrl,
              label: 'budget'.tr,
              hint: '100.00',
              icon: Iconsax.money,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
            ),
            const SizedBox(height: 24),
            // Schedule Section
            CampaignSectionTitle(
              title: 'campaign_schedule'.tr,
              icon: Iconsax.calendar,
              subtitle: 'campaign_schedule_subtitle'.tr,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CampaignDatePicker(
                    label: 'start_date'.tr,
                    controller: _startDateCtrl,
                    onTap: () async {
                      final picked = await CampaignDatePicker.pickDate(
                        context,
                        initialDate: _startDate,
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                          _startDateCtrl.text = CampaignDatePicker.formatDate(picked);
                        });
                      }
                    },
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CampaignDatePicker(
                    label: 'end_date'.tr,
                    controller: _endDateCtrl,
                    onTap: () async {
                      final picked = await CampaignDatePicker.pickDate(
                        context,
                        initialDate: _endDate,
                      );
                      if (picked != null) {
                        setState(() {
                          _endDate = picked;
                          _endDateCtrl.text = CampaignDatePicker.formatDate(picked);
                        });
                      }
                    },
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Targeting Section
            CampaignSectionTitle(
              title: 'audience_targeting'.tr,
              icon: Iconsax.profile_2user,
              subtitle: 'audience_targeting_subtitle'.tr,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CampaignDropdownField<String>(
                    label: 'gender'.tr,
                    value: _gender,
                    icon: Iconsax.user,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CampaignDropdownField<String>(
                    label: 'relationship'.tr,
                    value: _relationship,
                    icon: Iconsax.heart,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'single', child: Text('Single')),
                      DropdownMenuItem(value: 'married', child: Text('Married')),
                    ],
                    onChanged: (v) => setState(() => _relationship = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Submit Button
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _submitting ? null : _submit,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.tick_circle, color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                _campaignId != null ? 'update_campaign'.tr : 'create_campaign'.tr,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
