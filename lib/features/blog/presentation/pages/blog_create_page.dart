import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snginepro/features/pages/domain/pages_repository.dart';
import 'package:snginepro/features/pages/data/models/page.dart';
import 'package:snginepro/features/groups/domain/groups_repository.dart';
import 'package:snginepro/features/groups/data/models/group.dart';
import 'package:snginepro/features/events/data/services/events_service.dart';
import 'package:snginepro/features/events/data/models/event.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../../../../core/theme/ui_constants.dart';
import '../../domain/blog_repository.dart';
import '../../data/models/models.dart';
import 'blog_post_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
class BlogCreatePage extends StatefulWidget {
  const BlogCreatePage({super.key});
  @override
  State<BlogCreatePage> createState() => _BlogCreatePageState();
}
class _BlogCreatePageState extends State<BlogCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _htmlCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final List<String> _tags = [];
  int? _selectedCategoryId;
  String _publishTo = 'timeline';
  int? _pageId; int? _groupId; int? _eventId;
  bool _tipsEnabled = false;
  bool _forSubscriptions = false;
  bool _isPaid = false;
  double _postPrice = 0;
  final _paidTextCtrl = TextEditingController();
  String? _coverSource; // relative source for API
  String? _coverUrl; // full URL for preview
  bool _uploadingCover = false;
  double _uploadProgress = 0;
  bool _submitting = false;
  List<BlogCategory> _categories = [];
  // Loaded entities for selection
  List<PageModel> _myPages = [];
  List<Group> _myGroups = [];
  List<Event> _myEvents = [];
  bool _loadingPages = false;
  bool _loadingGroups = false;
  bool _loadingEvents = false;
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  Future<void> _loadCategories() async {
    try {
      final repo = context.read<BlogRepository>();
      final cats = await repo.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }
  Future<void> _loadMyPages() async {
    if (_myPages.isNotEmpty || _loadingPages) return;
    setState(() => _loadingPages = true);
    try {
      final pagesRepo = context.read<PagesRepository>();
      final pages = await pagesRepo.fetchMyPages();
      if (mounted) setState(() => _myPages = pages);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally { if (mounted) setState(() => _loadingPages = false); }
  }
  Future<void> _loadMyGroups() async {
    if (_myGroups.isNotEmpty || _loadingGroups) return;
    setState(() => _loadingGroups = true);
    try {
      final groupsRepo = context.read<GroupsRepository>();
      final resp = await groupsRepo.getMyGroups();
      if (mounted) setState(() => _myGroups = resp.groups);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally { if (mounted) setState(() => _loadingGroups = false); }
  }
  Future<void> _loadMyEvents() async {
    if (_myEvents.isNotEmpty || _loadingEvents) return;
    setState(() => _loadingEvents = true);
    try {
      final eventsService = context.read<EventsService>();
      final resp = await eventsService.getMyEvents();
      if (resp['status'] == 'success') {
        final events = (resp['events'] as List?)?.cast<Event>() ?? [];
        if (mounted) setState(() => _myEvents = events);
      } else {
        Get.snackbar('error'.tr, resp['message']?.toString() ?? 'error'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally { if (mounted) setState(() => _loadingEvents = false); }
  }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final repo = context.read<BlogRepository>();
      final body = {
        'publish_to': _publishTo,
        if (_publishTo == 'page' && _pageId != null) 'page_id': _pageId,
        if (_publishTo == 'group' && _groupId != null) 'group_id': _groupId,
        if (_publishTo == 'event' && _eventId != null) 'event_id': _eventId,
        'title': _titleCtrl.text.trim(),
        'text': _htmlCtrl.text.trim(),
        if (_coverSource != null && _coverSource!.isNotEmpty) 'cover': _coverSource,
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        if (_tags.isNotEmpty) 'tags': _tags,
        'tips_enabled': _tipsEnabled,
        'for_subscriptions': _forSubscriptions,
        'is_paid': _isPaid,
        if (_isPaid) 'post_price': _postPrice,
        if (_isPaid && _paidTextCtrl.text.isNotEmpty) 'paid_text': _paidTextCtrl.text.trim(),
      };
      final post = await repo.createPost(body);
      if (!mounted) return;
      Get.snackbar('success'.tr, 'blog_created_successfully'.tr);
      Get.off(() => BlogPostPage(postId: post.postId));
    } catch (e) {
      if (!mounted) return;
      Get.snackbar('error'.tr, e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _submitting = false);
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
        Get.snackbar('error'.tr, response['message']?.toString() ?? 'upload_failed'.tr, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
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
  void _addTagFromInput() {
    final raw = _tagsCtrl.text.trim();
    if (raw.isEmpty) return;
    final parts = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    for (final p in parts) {
      if (!_tags.contains(p)) _tags.add(p);
    }
    _tagsCtrl.clear();
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('create_blog'.tr),
        actions: [
          TextButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Iconsax.send_2_copy, size:18),
            label: Text('publish'.tr),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(UI.lg),
          children: [
            // Title
            _label('blog_title'.tr, requiredField: true),
            TextFormField(
              controller: _titleCtrl,
              decoration: _inputDecoration(icon: Iconsax.text_block_copy, hint: 'blog_title_hint'.tr),
              validator: (v) => (v==null || v.trim().isEmpty) ? 'required'.tr : null,
            ),
            SizedBox(height: UI.lg),
            // Category
            _label('blog_category'.tr),
            DropdownButtonFormField<int>(
              decoration: _inputDecoration(icon: Iconsax.category_copy),
              items: _categories.map((c)=>DropdownMenuItem(value:c.categoryId, child: Text(c.categoryName))).toList(),
              value: _selectedCategoryId,
              onChanged: (v)=>setState(()=>_selectedCategoryId=v),
            ),
            SizedBox(height: UI.lg),
            // Publish To
            _label('publish_to'.tr),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration(icon: Iconsax.send_copy),
              value: _publishTo,
              items: ['timeline','page','group','event'].map((e)=>DropdownMenuItem(value:e, child: Text(e.tr))).toList(),
              onChanged: (v){
                final target = v ?? 'timeline';
                setState(()=>_publishTo = target);
                if (target=='page') _loadMyPages();
                else if (target=='group') _loadMyGroups();
                else if (target=='event') _loadMyEvents();
              },
            ),
            if (_publishTo=='page') _entitySelector(
              loading: _loadingPages,
              onLoad: _loadMyPages,
              label: 'select_page'.tr,
              items: _myPages.map((p)=>DropdownMenuItem(value: p.id, child: Text(p.title.isEmpty ? p.name : p.title))).toList(),
              value: _pageId,
              onChanged: (v)=>setState(()=>_pageId=v),
              emptyText: 'no_pages'.tr,
            ),
            if (_publishTo=='group') _entitySelector(
              loading: _loadingGroups,
              onLoad: _loadMyGroups,
              label: 'select_group'.tr,
              items: _myGroups.map((g)=>DropdownMenuItem(value: g.groupId, child: Text(g.groupTitle))).toList(),
              value: _groupId,
              onChanged: (v)=>setState(()=>_groupId=v),
              emptyText: 'no_groups'.tr,
            ),
            if (_publishTo=='event') _entitySelector(
              loading: _loadingEvents,
              onLoad: _loadMyEvents,
              label: 'select_event'.tr,
              items: _myEvents.map((e)=>DropdownMenuItem(value: e.eventId, child: Text(e.eventTitle))).toList(),
              value: _eventId,
              onChanged: (v)=>setState(()=>_eventId=v),
              emptyText: 'no_events'.tr,
            ),
            SizedBox(height: UI.lg),
            // Cover Picker
            _label('blog_cover'.tr),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: UI.surfaceCard(context),
                borderRadius: BorderRadius.circular(UI.rMd),
                border: Border.all(color: UI.subtleText(context).withOpacity(0.15)),
              ),
              child: AspectRatio(
                aspectRatio: 16/9,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _coverUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(UI.rMd),
                              child: Image.network(
                                _coverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(Iconsax.image_copy, size: 48, color: UI.subtleText(context)),
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Iconsax.image_copy, size: 48, color: UI.subtleText(context)),
                                  SizedBox(height: UI.sm),
                                  Text('no_cover_selected'.tr, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: UI.subtleText(context))),
                                ],
                              ),
                            ),
                    ),
                    if (_uploadingCover) Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(UI.rMd),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: UI.sm),
                              Text('${('uploading'.tr)} ${( _uploadProgress*100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Row(
                        children: [
                          if (_coverSource != null && !_uploadingCover)
                            ElevatedButton.icon(
                              onPressed: _removeCover,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.85),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Iconsax.trash_copy, size:16),
                              label: Text('remove'.tr),
                            ),
                          if (_coverSource != null) SizedBox(width: UI.sm),
                          ElevatedButton.icon(
                            onPressed: _uploadingCover ? null : _pickCover,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Iconsax.add_copy, size:16),
                            label: Text(_coverSource == null ? 'pick_image'.tr : 'replace_image'.tr),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: UI.sm),
            Text('blog_cover_hint'.tr, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: UI.subtleText(context))),
            SizedBox(height: UI.lg),
            // HTML Content
            _label('blog_content'.tr, requiredField: true),
            TextFormField(
              controller: _htmlCtrl,
              decoration: _inputDecoration(icon: Iconsax.document_text_copy, hint: 'blog_content_hint'.tr),
              maxLines: 10,
              validator: (v) => (v==null || v.trim().isEmpty) ? 'required'.tr : null,
            ),
            SizedBox(height: UI.lg),
            // Tags
            _label('blog_tags'.tr),
            TextFormField(
              controller: _tagsCtrl,
              decoration: _inputDecoration(icon: Iconsax.hashtag_copy, hint: 'add_tag_hint'.tr, suffix: IconButton(icon: const Icon(Iconsax.add_copy),onPressed: _addTagFromInput)),
              onFieldSubmitted: (_)=>_addTagFromInput(),
            ),
            Wrap(
              spacing: UI.sm,
              children: _tags.map((t)=>Chip(label: Text('#$t'), onDeleted: (){setState(()=>_tags.remove(t));})).toList(),
            ),
            SizedBox(height: UI.lg),
            // Toggles
            SwitchListTile(
              title: Text('tips_enabled'.tr),
              value: _tipsEnabled,
              onChanged: (v)=>setState(()=>_tipsEnabled=v),
            ),
            SwitchListTile(
              title: Text('for_subscriptions'.tr),
              value: _forSubscriptions,
              onChanged: (v)=>setState(()=>_forSubscriptions=v),
            ),
            SwitchListTile(
              title: Text('is_paid'.tr),
              value: _isPaid,
              onChanged: (v)=>setState(()=>_isPaid=v),
            ),
            if (_isPaid) ...[
              _label('post_price'.tr, requiredField: true),
              TextFormField(
                initialValue: _postPrice.toString(),
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(icon: Iconsax.dollar_circle_copy),
                onChanged: (v)=>_postPrice = double.tryParse(v) ?? 0,
              ),
              SizedBox(height: UI.md),
              _label('paid_text'.tr),
              TextFormField(
                controller: _paidTextCtrl,
                decoration: _inputDecoration(icon: Iconsax.lock_copy),
                maxLines: 3,
              ),
            ],
            SizedBox(height: UI.xl),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Iconsax.send_1_copy),
              label: Text('publish'.tr),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: UI.md),
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UI.rMd)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _label(String text, {bool requiredField=false}) => Padding(
    padding: EdgeInsets.only(bottom: UI.xs),
    child: Row(
      children: [
        Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        if (requiredField) Text(' *', style: TextStyle(color: Colors.red[600]))
      ],
    ),
  );
  InputDecoration _inputDecoration({required IconData icon, String? hint, Widget? suffix}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      prefixIcon: Icon(icon, size:18),
      suffixIcon: suffix,
      hintText: hint,
      filled: true,
      fillColor: UI.surfaceCard(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UI.rMd),
        borderSide: BorderSide(color: scheme.primary.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UI.rMd),
        borderSide: BorderSide(color: UI.subtleText(context).withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UI.rMd),
        borderSide: BorderSide(color: scheme.primary),
      ),
    );
  }
  // Legacy numeric ID field removed (now using entity selectors)
  Widget _entitySelector({
    required bool loading,
    required VoidCallback onLoad,
    required String label,
    required List<DropdownMenuItem<int>> items,
    required int? value,
    required ValueChanged<int?> onChanged,
    required String emptyText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (items.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: UI.md),
            child: Row(
              children: [
                Expanded(child: Text(emptyText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: UI.subtleText(context)))),
                TextButton.icon(
                  onPressed: onLoad,
                  icon: const Icon(Iconsax.refresh_copy, size:16),
                  label: Text('reload'.tr),
                )
              ],
            ),
          )
        else
          DropdownButtonFormField<int>(
            value: value,
            items: items,
            decoration: _inputDecoration(icon: Iconsax.tick_circle_copy),
            onChanged: onChanged,
          ),
        SizedBox(height: UI.lg),
      ],
    );
  }
}
