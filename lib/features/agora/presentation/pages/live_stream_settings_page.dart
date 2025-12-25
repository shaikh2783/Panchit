import 'package:flutter/material.dart';

class LiveStreamSettingsPage extends StatefulWidget {
  const LiveStreamSettingsPage({Key? key}) : super(key: key);

  @override
  State<LiveStreamSettingsPage> createState() => _LiveStreamSettingsPageState();
}

class _LiveStreamSettingsPageState extends State<LiveStreamSettingsPage> {
  String _selectedQuality = 'HD';
  bool _isPrivate = false;
  bool _allowComments = true;
  bool _allowReactions = true;
  bool _recordStream = false;
  bool _enableTips = false;
  bool _forSubscribers = false;
  String _selectedCategory = 'عام';
  
  final List<String> _qualityOptions = ['480p', 'HD', 'Full HD', 'UHD'];
  final List<String> _categories = [
    'عام',
    'ألعاب',
    'تعليم',
    'رياضة',
    'طبخ',
    'موسيقى',
    'تقنية',
    'فن',
    'سفر',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'إعدادات البث المباشر',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'حفظ',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoSettings(),
            const SizedBox(height: 24),
            _buildPrivacySettings(),
            const SizedBox(height: 24),
            _buildInteractionSettings(),
            const SizedBox(height: 24),
            _buildMonetizationSettings(),
            const SizedBox(height: 24),
            _buildCategorySettings(),
            const SizedBox(height: 24),
            _buildAdvancedSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSettings() {
    return _buildSettingsSection(
      title: 'إعدادات الفيديو',
      icon: Icons.videocam,
      children: [
        _buildQualitySelector(),
        _buildSwitchTile(
          title: 'تسجيل البث',
          subtitle: 'احفظ البث للمشاهدة لاحقاً',
          value: _recordStream,
          onChanged: (value) => setState(() => _recordStream = value),
          icon: Icons.video_library,
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return _buildSettingsSection(
      title: 'إعدادات الخصوصية',
      icon: Icons.privacy_tip,
      children: [
        _buildSwitchTile(
          title: 'بث خاص',
          subtitle: 'محدود للمدعوين فقط',
          value: _isPrivate,
          onChanged: (value) => setState(() => _isPrivate = value),
          icon: Icons.lock,
        ),
        _buildSwitchTile(
          title: 'للمشتركين فقط',
          subtitle: 'متاح للمشتركين في قناتك فقط',
          value: _forSubscribers,
          onChanged: (value) => setState(() => _forSubscribers = value),
          icon: Icons.subscriptions,
        ),
      ],
    );
  }

  Widget _buildInteractionSettings() {
    return _buildSettingsSection(
      title: 'إعدادات التفاعل',
      icon: Icons.chat,
      children: [
        _buildSwitchTile(
          title: 'السماح بالتعليقات',
          subtitle: 'المشاهدون يمكنهم التعليق',
          value: _allowComments,
          onChanged: (value) => setState(() => _allowComments = value),
          icon: Icons.chat_bubble,
        ),
        _buildSwitchTile(
          title: 'السماح بالتفاعلات',
          subtitle: 'إعجاب، حب، غضب، إلخ',
          value: _allowReactions,
          onChanged: (value) => setState(() => _allowReactions = value),
          icon: Icons.thumb_up,
        ),
      ],
    );
  }

  Widget _buildMonetizationSettings() {
    return _buildSettingsSection(
      title: 'إعدادات الربح',
      icon: Icons.monetization_on,
      children: [
        _buildSwitchTile(
          title: 'تفعيل النصائح',
          subtitle: 'المشاهدون يمكنهم إرسال نصائح مالية',
          value: _enableTips,
          onChanged: (value) => setState(() => _enableTips = value),
          icon: Icons.attach_money,
        ),
        if (_enableTips) ...[
          const SizedBox(height: 12),
          _buildInfoCard(
            'سيتم استلام النصائح في محفظتك الإلكترونية. يمكنك سحبها في أي وقت من إعدادات الحساب.',
            Icons.info,
            Colors.blue,
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySettings() {
    return _buildSettingsSection(
      title: 'تصنيف البث',
      icon: Icons.category,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.category, color: Colors.white70),
            ),
            style: const TextStyle(color: Colors.white),
            dropdownColor: const Color(0xFF2A2A2A),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return _buildSettingsSection(
      title: 'إعدادات متقدمة',
      icon: Icons.settings,
      children: [
        _buildActionTile(
          title: 'إدارة المحظورين',
          subtitle: 'قائمة المستخدمين المحظورين من البث',
          icon: Icons.block,
          onTap: () {
            // Navigate to blocked users management
            _showComingSoonDialog('إدارة المحظورين');
          },
        ),
        _buildActionTile(
          title: 'مفاتيح البث',
          subtitle: 'إعداد البث من برامج خارجية',
          icon: Icons.key,
          onTap: () {
            // Navigate to stream keys
            _showComingSoonDialog('مفاتيح البث');
          },
        ),
        _buildActionTile(
          title: 'إحصائيات مفصلة',
          subtitle: 'تحليل أداء البثوث السابقة',
          icon: Icons.analytics,
          onTap: () {
            // Navigate to detailed analytics
            _showComingSoonDialog('الإحصائيات المفصلة');
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQualitySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'جودة البث',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _qualityOptions.map((quality) {
              final isSelected = quality == _selectedQuality;
              return ChoiceChip(
                label: Text(quality),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedQuality = quality);
                  }
                },
                backgroundColor: Colors.white.withOpacity(0.1),
                selectedColor: Colors.blue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // Here you would save settings to backend/local storage
    Navigator.of(context).pop({
      'quality': _selectedQuality,
      'isPrivate': _isPrivate,
      'allowComments': _allowComments,
      'allowReactions': _allowReactions,
      'recordStream': _recordStream,
      'enableTips': _enableTips,
      'forSubscribers': _forSubscribers,
      'category': _selectedCategory,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الإعدادات بنجاح'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'قريباً',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'ميزة "$feature" ستكون متاحة في التحديث القادم.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}