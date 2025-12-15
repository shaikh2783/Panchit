import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/feed/application/posts_notifier.dart';
import 'package:snginepro/core/config/dynamic_app_config_provider.dart';
import 'package:snginepro/core/config/colored_pattern_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});
  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}
class _CreatePostPageState extends State<CreatePostPage> {
  final _textController = TextEditingController();
  final _feelingValueController = TextEditingController();
  final _images = <File>[];
  bool _isLoading = false;
  ColoredPattern? _selectedColoredPattern;
  bool _showColoredPatterns = false;
  bool _feelingsEnabled = false;
  bool _feelingsSynced = false;
  List<Map<String, dynamic>> _feelings = [];
  List<Map<String, dynamic>> _activities = [];
  String? _selectedFeelingAction;
  String? _selectedActivity;
  bool _feelingsLoading = false;
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
        // إخفاء الأنماط الملونة عند إضافة صور
        _showColoredPatterns = false;
        _selectedColoredPattern = null;
      });
    }
  }
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }
  void _toggleColoredPatterns() {
    setState(() {
      _showColoredPatterns = !_showColoredPatterns;
      if (_showColoredPatterns) {
        // إزالة الصور عند تفعيل الأنماط الملونة
        _images.clear();
      } else {
        _selectedColoredPattern = null;
      }
    });
  }
  List<Map<String, dynamic>> get _availableActivities {
    if (_selectedFeelingAction == null) {
      return [];
    }
    return _activities
        .where((activity) => activity['action'] == _selectedFeelingAction)
        .toList();
  }
  void _syncFeelingsFromConfig(BuildContext context, DynamicAppConfigProvider provider) {
    if (_feelingsSynced && _feelingsEnabled == (provider.features?.posts.feelings ?? false)) {
      return;
    }
    final expandable = provider.appConfig?.expandable ?? {};
    final rawFeelings = _normalizeList(expandable['feelings']);
    final rawActivities = _normalizeList(expandable['activities']);
    final enabled = provider.features?.posts.feelings ?? false;
    final hasLocalData = rawFeelings.isNotEmpty || rawActivities.isNotEmpty;
    final shouldUpdate = !_feelingsSynced ||
        _feelingsEnabled != enabled ||
        const DeepCollectionEquality().equals(_feelings, rawFeelings) == false ||
        const DeepCollectionEquality().equals(_activities, rawActivities) == false;
    if (hasLocalData && shouldUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _feelings = rawFeelings;
          _activities = rawActivities;
          _feelingsEnabled = enabled;
          _feelingsSynced = true;
        });
      });
      return;
    }
    if (!hasLocalData && enabled) {
      _loadFeelingsFromAppConfig(context);
    }
  }
  List<Map<String, dynamic>> _normalizeList(dynamic data) {
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        }
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return {'text': item.toString()};
      }).toList();
    }
    return [];
  }
  Future<void> _loadFeelingsFromAppConfig(BuildContext context) async {
    if (_feelingsLoading) return;
    _feelingsLoading = true;
    try {
      final client = context.read<ApiClient>();
      final response = await client.get('data/app/config');
      final configData = response['data'] ?? response;
      final features = (configData['features'] as Map?)?['posts'] as Map?;
      final enabled = features?['feelings'] == true || features?['feelings']?.toString() == '1';
      final rawFeelings = _normalizeList(configData['feelings']);
      final rawActivities = _normalizeList(configData['activities'] ?? configData['feeling_activities']);
      if (!mounted) return;
      setState(() {
        _feelings = rawFeelings;
        _activities = rawActivities;
        _feelingsEnabled = enabled;
        _feelingsSynced = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _feelingsEnabled = true;
        });
      }
    } finally {
      _feelingsLoading = false;
    }
  }
  void _selectColoredPattern(ColoredPattern? pattern) {
    setState(() {
      _selectedColoredPattern = pattern;
    });
  }
  Color _getPatternBackground() {
    if (_selectedColoredPattern == null) return Colors.transparent;
    if (_selectedColoredPattern!.backgroundColors != null) {
      // استخدام اللون الأساسي
      final colorStr = _selectedColoredPattern!.backgroundColors!.primary.replaceAll('#', '');
      return Color(int.parse('0xFF$colorStr'));
    }
    // لون افتراضي
    return const Color(0xFF6C5CE7);
  }
  Widget _buildPostTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPostTypeButton(
            icon: Icons.photo_library_outlined,
            label: 'Photos',
            isSelected: _images.isNotEmpty,
            onTap: _pickImage,
          ),
          _buildPostTypeButton(
            icon: Icons.color_lens_outlined,
            label: 'Colored',
            isSelected: _showColoredPatterns,
            onTap: _toggleColoredPatterns,
          ),
        ],
      ),
    );
  }
  Widget _buildPostTypeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Theme.of(context).primaryColor) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildColoredPatternsGrid() {
    return Consumer<DynamicAppConfigProvider>(
      builder: (context, configProvider, child) {
        final patterns = configProvider.coloredPatterns ?? [];
        if (patterns.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.color_lens_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No colored patterns available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.color_lens, color: Colors.grey[700]),
                const SizedBox(width: 8),
                const Text(
                  'Choose a background',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _selectColoredPattern(null),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: patterns.length,
              itemBuilder: (context, index) {
                final pattern = patterns[index];
                final isSelected = _selectedColoredPattern?.id == pattern.id;
                return InkWell(
                  onTap: () => _selectColoredPattern(pattern),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected 
                          ? Border.all(color: Theme.of(context).primaryColor, width: 3)
                          : Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildPatternPreview(pattern),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
  Widget _buildFeelingsSection(BuildContext context, DynamicAppConfigProvider provider) {
    _syncFeelingsFromConfig(context, provider);
    if (!_feelingsEnabled || _feelings.isEmpty) {
      return const SizedBox.shrink();
    }
    final availableActivities = _availableActivities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
            const SizedBox(width: 8),
            const Text(
              'Feeling & Activity',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedFeelingAction,
          isExpanded: true,
          hint: const Text('Choose a feeling'),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _feelings.map((feeling) {
            final label = feeling['text']?.toString() ??
                feeling['action']?.toString() ??
                'Feeling';
            return DropdownMenuItem<String>(
              value: feeling['action']?.toString(),
              child: Text(label),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFeelingAction = value;
              _selectedActivity = null;
              _feelingValueController.clear();
            });
          },
        ),
        const SizedBox(height: 12),
        if (availableActivities.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _selectedActivity,
            isExpanded: true,
            hint: const Text('Select activity'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: availableActivities.map((activity) {
              final label = activity['text']?.toString() ??
                  activity['value']?.toString() ??
                  activity['action']?.toString() ??
                  'Activity';
              return DropdownMenuItem<String>(
                value: activity['value']?.toString() ?? activity['action']?.toString(),
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedActivity = value),
          )
        else
          TextField(
            controller: _feelingValueController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Describe what you are doing',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
      ],
    );
  }
  Widget _buildPatternPreview(ColoredPattern pattern) {
    if (pattern.backgroundImage != null && pattern.backgroundImage!.full.isNotEmpty) {
      // صورة خلفية
      return Image.network(
        pattern.backgroundImage!.full,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildColorPreview(pattern);
        },
      );
    } else {
      // لون خلفية
      return _buildColorPreview(pattern);
    }
  }
  Widget _buildColorPreview(ColoredPattern pattern) {
    if (pattern.backgroundColors != null) {
      final primary = Color(int.parse('0xFF${pattern.backgroundColors!.primary.replaceAll('#', '')}'));
      if (pattern.backgroundColors!.secondary != null) {
        // تدرج لوني
        final secondary = Color(int.parse('0xFF${pattern.backgroundColors!.secondary!.replaceAll('#', '')}'));
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      } else {
        // لون واحد
        return Container(color: primary);
      }
    }
    // لون افتراضي
    return Container(
      color: const Color(0xFF6C5CE7),
      child: const Icon(Icons.color_lens, color: Colors.white),
    );
  }
  @override
  void dispose() {
    _textController.dispose();
    _feelingValueController.dispose();
    super.dispose();
  }
  Future<void> _createPost() async {
    if (_textController.text.isEmpty &&
        _images.isEmpty &&
        _selectedColoredPattern == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await context.read<PostsNotifier>().createPost(
            _textController.text,
            photos: _images.isNotEmpty ? _images : null,
            coloredPattern: _selectedColoredPattern?.id,
            feelingAction: _selectedFeelingAction,
            feelingValue: _selectedActivity ??
                (_feelingValueController.text.isNotEmpty
                    ? _feelingValueController.text
                    : null),
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Post', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // نص المنشور
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedColoredPattern != null 
                    ? _getPatternBackground() 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _textController,
                autofocus: true,
                maxLines: null,
                style: TextStyle(
                  color: _selectedColoredPattern != null 
                      ? Colors.white 
                      : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: 'What\'s on your mind?',
                  hintStyle: TextStyle(
                    color: _selectedColoredPattern != null 
                        ? Colors.white70 
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<DynamicAppConfigProvider>(
            builder: (context, configProvider, child) {
              return _buildFeelingsSection(context, configProvider);
              },
            ),
            const SizedBox(height: 16),
            // خيارات نوع المنشور
            _buildPostTypeSelector(),
            const SizedBox(height: 16),
            // الأنماط الملونة
            if (_showColoredPatterns) ...[
              _buildColoredPatternsGrid(),
              const SizedBox(height: 16),
            ],
            // شبكة الصور
            if (_images.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_images[index], fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          onPressed: () => _removeImage(index),
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: _showColoredPatterns ? null : FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
