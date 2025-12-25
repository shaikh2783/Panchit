import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../../../../core/theme/ui_constants.dart';
import '../../domain/blog_repository.dart';
import '../../data/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BlogEditPage extends StatefulWidget {
  const BlogEditPage({super.key});
  @override
  State<BlogEditPage> createState() => _BlogEditPageState();
}

class _BlogEditPageState extends State<BlogEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _htmlCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final List<String> _tags = [];
  int? _selectedCategoryId;
  String? _coverSource;
  String? _coverUrl;
  bool _uploadingCover = false;
  double _uploadProgress = 0;
  bool _submitting = false;
  List<BlogCategory> _categories = [];
  final ImagePicker _picker = ImagePicker();
  BlogPost? _originalPost;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _originalPost = Get.arguments as BlogPost?;
    if (_originalPost != null) {
      _titleCtrl.text = _originalPost!.title;
      _htmlCtrl.text = _originalPost!.textHtml;
      _tags.addAll(_originalPost!.tags);
      _selectedCategoryId = _originalPost!.categoryId;
      _coverUrl = _originalPost!.cover;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final repo = context.read<BlogRepository>();
      final cats = await repo.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _pickCover() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    setState(() {
      _uploadingCover = true;
      _uploadProgress = 0;
    });
    try {
      final client = context.read<ApiClient>();
      final result = await client.multipartPost(
        configCfgP('file_upload'),
        body: {'type': 'photo'},
        filePath: img.path,
        fileFieldName: 'file',
        onProgress: (sent, total) {
          if (mounted) setState(() => _uploadProgress = total == 0 ? 0 : sent / total);
        },
      );
      final source = result['data']?['source']?.toString();
      final full = result['data']?['url']?.toString();
      if (mounted) {
        setState(() {
          _coverSource = source;
          _coverUrl = full ?? source;
          _uploadingCover = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingCover = false);
        Get.snackbar('error'.tr, e.toString());
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final repo = context.read<BlogRepository>();
      final body = {
        'title': _titleCtrl.text.trim(),
        'text': _htmlCtrl.text.trim(),
        if (_coverSource != null && _coverSource!.isNotEmpty) 'cover': _coverSource,
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        if (_tags.isNotEmpty) 'tags': _tags,
      };
      await repo.updatePost(_originalPost!.postId, body);
      if (mounted) {
        Get.back(); // Return to post page
        Get.snackbar('success'.tr, 'blog_updated_successfully'.tr);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        Get.snackbar('error'.tr, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: UI.surfacePage(context),
      appBar: AppBar(
        title: Text('edit_blog'.tr),
        actions: [
          TextButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Iconsax.tick_circle_copy, size:18),
            label: Text('save'.tr),
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
            // Cover Picker
            _label('blog_cover'.tr),
            Container(
              decoration: BoxDecoration(
                color: UI.surfaceCard(context),
                borderRadius: BorderRadius.circular(UI.rMd),
                border: Border.all(color: UI.subtleText(context).withOpacity(0.15)),
              ),
              padding: EdgeInsets.all(UI.md),
              child: Column(
                children: [
                  if (_coverUrl != null && _coverUrl!.isNotEmpty)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(UI.rSm),
                          child: Image.network(_coverUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                        if (_uploadingCover)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black54,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(value: _uploadProgress),
                                    SizedBox(height: UI.sm),
                                    Text('${'uploading'.tr} ${(_uploadProgress*100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(UI.rSm),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.gallery_copy, size: 32, color: UI.subtleText(context)),
                            SizedBox(height: UI.sm),
                            Text('no_cover_selected'.tr, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: UI.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _uploadingCover ? null : _pickCover,
                          icon: Icon(_coverUrl == null ? Iconsax.gallery_add_copy : Iconsax.gallery_edit_copy, size: 18),
                          label: Text(_coverUrl == null ? 'pick_image'.tr : 'replace_image'.tr),
                        ),
                      ),
                      if (_coverUrl != null) ...[
                        SizedBox(width: UI.sm),
                        IconButton(
                          onPressed: ()=>setState((){_coverUrl=null; _coverSource=null;}),
                          icon: const Icon(Iconsax.trash_copy, size: 18),
                          style: IconButton.styleFrom(foregroundColor: scheme.error),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: UI.lg),
            // HTML Content
            _label('blog_content'.tr, requiredField: true),
            TextFormField(
              controller: _htmlCtrl,
              decoration: _inputDecoration(icon: Iconsax.code_copy, hint: 'blog_content_hint'.tr),
              maxLines: 12,
              validator: (v) => (v==null || v.trim().isEmpty) ? 'required'.tr : null,
            ),
            SizedBox(height: UI.lg),
            // Tags
            _label('blog_tags'.tr),
            Wrap(
              spacing: UI.sm,
              children: [
                ..._tags.map((t) => Chip(
                  label: Text(t),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: ()=>setState(()=>_tags.remove(t)),
                )),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text('add_tag'.tr),
                  onPressed: _addTag,
                ),
              ],
            ),
            SizedBox(height: UI.xl),
          ],
        ),
      ),
    );
  }

  void _addTag() {
    Get.dialog(
      AlertDialog(
        title: Text('add_tag'.tr),
        content: TextField(
          controller: _tagsCtrl,
          decoration: InputDecoration(hintText: 'add_tag_hint'.tr),
        ),
        actions: [
          TextButton(onPressed: ()=>Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: (){
              final newTags = _tagsCtrl.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();
              setState(()=>_tags.addAll(newTags));
              _tagsCtrl.clear();
              Get.back();
            },
            child: Text('add'.tr),
          ),
        ],
      ),
    );
  }

  Widget _label(String txt, {bool requiredField = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: UI.sm),
      child: Row(
        children: [
          Text(txt, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          if (requiredField) Text(' *', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({IconData? icon, String? hint}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      hintText: hint,
      filled: true,
      fillColor: UI.surfaceCard(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UI.rMd),
        borderSide: BorderSide(color: UI.subtleText(context).withOpacity(0.15)),
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
}
