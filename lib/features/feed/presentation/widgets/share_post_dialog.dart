import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../domain/share_repository.dart';
import '../../data/models/post.dart';

/// Dialog لاختيار نوع المشاركة
class SharePostDialog extends StatefulWidget {
  const SharePostDialog({
    super.key,
    required this.post,
    this.onShareSuccess,
  });

  final Post post;
  final VoidCallback? onShareSuccess;

  @override
  State<SharePostDialog> createState() => _SharePostDialogState();
}

class _SharePostDialogState extends State<SharePostDialog> {
  String _selectedShareType = 'timeline';
  int? _selectedPageId;
  int? _selectedGroupId;
  int? _selectedEventId;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _pages = [];
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadShareOptions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadShareOptions() async {
    final shareRepo = context.read<ShareRepository>();

    try {
      final pages = await shareRepo.getShareablePages();
      final groups = await shareRepo.getShareableGroups();
      final events = await shareRepo.getShareableEvents();

      if (mounted) {
        setState(() {
          _pages = pages;
          _groups = groups;
          _events = events;
        });
      }
    } catch (e) {

    }
  }

  Future<void> _sharePost() async {
    if (_isLoading) return;

    // التحقق من اختيار الصفحة/المجموعة/الحدث عند الحاجة
    if (_selectedShareType == 'page' && _selectedPageId == null) {
      Get.snackbar(
        'error_title'.tr,
        'share_select_page'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedShareType == 'group' && _selectedGroupId == null) {
      Get.snackbar(
        'error_title'.tr,
        'share_select_group'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedShareType == 'event' && _selectedEventId == null) {
      Get.snackbar(
        'error_title'.tr,
        'share_select_event'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final shareRepo = context.read<ShareRepository>();
      final message = _messageController.text.trim();

      Map<String, dynamic> result;

      switch (_selectedShareType) {
        case 'timeline':
          result = await shareRepo.shareToTimeline(
            postId: widget.post.id,
            message: message.isEmpty ? null : message,
          );
          break;
        case 'page':
          result = await shareRepo.shareToPage(
            postId: widget.post.id,
            pageId: _selectedPageId!,
            message: message.isEmpty ? null : message,
          );
          break;
        case 'group':
          result = await shareRepo.shareToGroup(
            postId: widget.post.id,
            groupId: _selectedGroupId!,
            message: message.isEmpty ? null : message,
          );
          break;
        case 'event':
          result = await shareRepo.shareToEvent(
            postId: widget.post.id,
            eventId: _selectedEventId!,
            message: message.isEmpty ? null : message,
          );
          break;
        default:
          throw Exception('Invalid share type');
      }

      if (mounted) {
        Navigator.of(context).pop();
        Get.snackbar(
          'success_title'.tr,
          result['message'] ?? 'share_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        widget.onShareSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'error_title'.tr,
          'share_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.share,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'share_post_title'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // نوع المشاركة
                    Text(
                      'share_to_label'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // خيارات نوع المشاركة
                    _ShareTypeOption(
                      icon: Iconsax.home,
                      title: 'share_to_timeline'.tr,
                      isSelected: _selectedShareType == 'timeline',
                      onTap: () => setState(() => _selectedShareType = 'timeline'),
                    ),
                    const SizedBox(height: 8),
                    _ShareTypeOption(
                      icon: Iconsax.document,
                      title: 'share_to_page'.tr,
                      isSelected: _selectedShareType == 'page',
                      onTap: () => setState(() => _selectedShareType = 'page'),
                    ),
                    const SizedBox(height: 8),
                    _ShareTypeOption(
                      icon: Iconsax.people,
                      title: 'share_to_group'.tr,
                      isSelected: _selectedShareType == 'group',
                      onTap: () => setState(() => _selectedShareType = 'group'),
                    ),
                    const SizedBox(height: 8),
                    _ShareTypeOption(
                      icon: Iconsax.calendar,
                      title: 'share_to_event'.tr,
                      isSelected: _selectedShareType == 'event',
                      onTap: () => setState(() => _selectedShareType = 'event'),
                    ),

                    // اختيار الصفحة إذا كان النوع صفحة
                    if (_selectedShareType == 'page') ...[
                      const SizedBox(height: 16),
                      _buildPageSelector(),
                    ],

                    // اختيار المجموعة إذا كان النوع مجموعة
                    if (_selectedShareType == 'group') ...[
                      const SizedBox(height: 16),
                      _buildGroupSelector(),
                    ],

                    // اختيار الحدث إذا كان النوع حدث
                    if (_selectedShareType == 'event') ...[
                      const SizedBox(height: 16),
                      _buildEventSelector(),
                    ],

                    const SizedBox(height: 16),

                    // حقل الرسالة
                    Text(
                      'share_message_label'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'share_message_hint'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text('cancel_button'.tr),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sharePost,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('share_button'.tr),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageSelector() {
    final theme = Theme.of(context);

    if (_pages.isEmpty) {
      return Text(
        'share_no_pages'.tr,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedPageId,
      decoration: InputDecoration(
        labelText: 'share_select_page'.tr,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: _pages.map((page) {
        return DropdownMenuItem<int>(
          value: page['page_id'] as int,
          child: Text(page['page_title'] as String),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedPageId = value);
      },
    );
  }

  Widget _buildGroupSelector() {
    final theme = Theme.of(context);

    if (_groups.isEmpty) {
      return Text(
        'share_no_groups'.tr,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedGroupId,
      decoration: InputDecoration(
        labelText: 'share_select_group'.tr,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: _groups.map((group) {
        return DropdownMenuItem<int>(
          value: group['group_id'] as int,
          child: Text(group['group_title'] as String),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedGroupId = value);
      },
    );
  }

  Widget _buildEventSelector() {
    final theme = Theme.of(context);

    if (_events.isEmpty) {
      return Text(
        'share_no_events'.tr,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedEventId,
      decoration: InputDecoration(
        labelText: 'share_select_event'.tr,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: _events.map((event) {
        return DropdownMenuItem<int>(
          value: event['event_id'] as int,
          child: Text(event['event_title'] as String),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedEventId = value);
      },
    );
  }
}

class _ShareTypeOption extends StatelessWidget {
  const _ShareTypeOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.05)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
