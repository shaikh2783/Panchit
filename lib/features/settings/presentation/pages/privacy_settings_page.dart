import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/privacy_settings_model.dart';
import '../../data/services/privacy_settings_service.dart';
import '../../../../core/network/api_client.dart';
/// Privacy & Notifications Settings Page (EN + modern UI)
class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key, this.initialTab = 0});
  /// Tab index to open initially (0 = Privacy, 1 = Notifications)
  final int initialTab;
  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}
class _PrivacySettingsPageState extends State<PrivacySettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PrivacySettingsService _service;
  PrivacySettings? _settings;
  bool _isLoading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _service = PrivacySettingsService(context.read<ApiClient>());
    _loadSettings();
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final settings = await _service.getSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  Future<void> _updatePrivacy(String field, String value) async {
    try {
      await _service.updatePrivacyField(field, value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSettings();
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString();
      final isBackendBug =
          errorMsg.contains('getParsedBody') || errorMsg.contains('500');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBackendBug
                ? 'Server error: requires Backend fix\nBackend Bug: getParsedBody() method missing'
                : 'Error: $errorMsg',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: isBackendBug
              ? SnackBarAction(
                  label: 'Details',
                  textColor: Colors.white,
                  onPressed: _showBackendBugDialog,
                )
              : null,
        ),
      );
    }
  }
  Future<void> _toggleNotification(String field, bool value) async {
    try {
      await _service.toggleNotification(field, value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSettings();
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString();
      final isBackendBug =
          errorMsg.contains('getParsedBody') || errorMsg.contains('500');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBackendBug
                ? 'Server error: requires Backend fix\nBackend Bug: getParsedBody() method missing'
                : 'Error: $errorMsg',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: isBackendBug
              ? SnackBarAction(
                  label: 'Details',
                  textColor: Colors.white,
                  onPressed: _showBackendBugDialog,
                )
              : null,
        ),
      );
    }
  }
  void _showBackendBugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Backend Bug'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Issue:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                'The server has a bug at endpoint:\n'
                'POST /data/settings/privacy\n\n'
                'Error: Call to undefined method Request::getParsedBody()',
              ),
              SizedBox(height: 16),
              Text('Fix:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                'The backend should update the code in:\n'
                '• /apis/php/data/settings/privacy.php\n\n'
                'Replace getParsedBody() with:\n'
                r'• json_decode(file_get_contents("php://input"), true)' '\n'
                r'• or use $_POST' '\n\n'
                'See: PRIVACY_SETTINGS_BACKEND_BUG.md',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Privacy'),
            Tab(text: 'Notifications'),
          ],
        ),
      ),
      body: _isLoading
          ? const _LoadingState()
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadSettings)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPrivacyTab(),
                    _buildNotificationsTab(),
                  ],
                ),
    );
  }
  Widget _buildPrivacyTab() {
    if (_settings == null) return const SizedBox.shrink();
    final privacy = _settings!.privacy;
    return RefreshIndicator(
      onRefresh: _loadSettings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Profile Information',
            icon: Icons.person,
            gradient: const [Color(0xFF64B5F6), Color(0xFF1E88E5)],
            children: [
              _PrivacyRow(
                label: 'Basic info',
                value: _safePrivacyValue(privacy.basic),
                onChanged: (v) => _updatePrivacy('user_privacy_basic', v),
              ),
              _PrivacyRow(
                label: 'Work info',
                value: _safePrivacyValue(privacy.work),
                onChanged: (v) => _updatePrivacy('user_privacy_work', v),
              ),
              _PrivacyRow(
                label: 'Location',
                value: _safePrivacyValue(privacy.location),
                onChanged: (v) => _updatePrivacy('user_privacy_location', v),
              ),
              _PrivacyRow(
                label: 'Education',
                value: _safePrivacyValue(privacy.education),
                onChanged: (v) => _updatePrivacy('user_privacy_education', v),
              ),
              _PrivacyRow(
                label: 'Other info',
                value: _safePrivacyValue(privacy.other),
                onChanged: (v) => _updatePrivacy('user_privacy_other', v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Personal Details',
            icon: Icons.info,
            gradient: const [Color(0xFF81C784), Color(0xFF43A047)],
            children: [
              _PrivacyRow(
                label: 'Gender',
                value: _safePrivacyValue(privacy.gender),
                onChanged: (v) => _updatePrivacy('user_privacy_gender', v),
              ),
              _PrivacyRow(
                label: 'Birthdate',
                value: _safePrivacyValue(privacy.birthdate),
                onChanged: (v) => _updatePrivacy('user_privacy_birthdate', v),
              ),
              _PrivacyRow(
                label: 'Relationship status',
                value: _safePrivacyValue(privacy.relationship),
                onChanged: (v) =>
                    _updatePrivacy('user_privacy_relationship', v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Content',
            icon: Icons.photo_library,
            gradient: const [Color(0xFFFFB74D), Color(0xFFF57C00)],
            children: [
              _PrivacyRow(
                label: 'Photos',
                value: _safePrivacyValue(privacy.photos),
                onChanged: (v) => _updatePrivacy('user_privacy_photos', v),
              ),
              _PrivacyRow(
                label: 'Friends',
                value: _safePrivacyValue(privacy.friends),
                onChanged: (v) => _updatePrivacy('user_privacy_friends', v),
              ),
              _PrivacyRow(
                label: 'Followers',
                value: _safePrivacyValue(privacy.followers),
                onChanged: (v) => _updatePrivacy('user_privacy_followers', v),
              ),
              _PrivacyRow(
                label: 'Pages',
                value: _safePrivacyValue(privacy.pages),
                onChanged: (v) => _updatePrivacy('user_privacy_pages', v),
              ),
              _PrivacyRow(
                label: 'Groups',
                value: _safePrivacyValue(privacy.groups),
                onChanged: (v) => _updatePrivacy('user_privacy_groups', v),
              ),
              _PrivacyRow(
                label: 'Events',
                value: _safePrivacyValue(privacy.events),
                onChanged: (v) => _updatePrivacy('user_privacy_events', v),
              ),
              _PrivacyRow(
                label: 'Subscriptions',
                value: _safePrivacyValue(privacy.subscriptions),
                onChanged: (v) =>
                    _updatePrivacy('user_privacy_subscriptions', v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Interactions',
            icon: Icons.chat,
            gradient: const [Color(0xFF9575CD), Color(0xFF5E35B1)],
            children: [
              _PrivacyRow(
                label: 'Post on my wall',
                value: _safePrivacyValue(privacy.wall),
                onChanged: (v) => _updatePrivacy('user_privacy_wall', v),
              ),
              _PrivacyRow(
                label: 'Chat',
                value: _safePrivacyValue(privacy.chat),
                onChanged: (v) => _updatePrivacy('user_privacy_chat', v),
              ),
              _PrivacyRow(
                label: 'Poke',
                value: _safePrivacyValue(privacy.poke),
                onChanged: (v) => _updatePrivacy('user_privacy_poke', v),
              ),
              _PrivacyRow(
                label: 'Gifts',
                value: _safePrivacyValue(privacy.gifts),
                onChanged: (v) => _updatePrivacy('user_privacy_gifts', v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'General Settings',
            icon: Icons.settings,
            gradient: const [Color(0xFF90A4AE), Color(0xFF607D8B)],
            children: [
              _SwitchTile(
                label: 'Enable chat',
                value: privacy.chatEnabled,
                onChanged: (value) => _service
                    .updatePrivacySettings({'user_chat_enabled': value}).then(
                        (_) => _loadSettings()),
              ),
              _SwitchTile(
                label: 'Enable newsletter',
                value: privacy.newsletterEnabled,
                onChanged: (value) => _service
                    .updatePrivacySettings({'user_newsletter_enabled': value})
                    .then((_) => _loadSettings()),
              ),
              _SwitchTile(
                label: 'Enable tips',
                value: privacy.tipsEnabled,
                onChanged: (value) => _service
                    .updatePrivacySettings({'user_tips_enabled': value}).then(
                        (_) => _loadSettings()),
              ),
              _SwitchTile(
                label: 'Hide friend suggestions',
                value: privacy.suggestionsHidden,
                onChanged: (value) => _service
                    .updatePrivacySettings({'user_suggestions_hidden': value})
                    .then((_) => _loadSettings()),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildNotificationsTab() {
    if (_settings == null) return const SizedBox.shrink();
    final notifications = _settings!.notifications;
    return RefreshIndicator(
      onRefresh: _loadSettings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Email notifications',
            icon: Icons.email,
            gradient: const [Color(0xFF64B5F6), Color(0xFF1E88E5)],
            children: [
              _SwitchTile(
                label: 'Post likes',
                value: notifications.emailPostLikes,
                onChanged: (v) => _toggleNotification('email_post_likes', v),
              ),
              _SwitchTile(
                label: 'Post comments',
                value: notifications.emailPostComments,
                onChanged: (v) => _toggleNotification('email_post_comments', v),
              ),
              _SwitchTile(
                label: 'Post shares',
                value: notifications.emailPostShares,
                onChanged: (v) => _toggleNotification('email_post_shares', v),
              ),
              _SwitchTile(
                label: 'Wall posts',
                value: notifications.emailWallPosts,
                onChanged: (v) => _toggleNotification('email_wall_posts', v),
              ),
              _SwitchTile(
                label: 'Mentions',
                value: notifications.emailMentions,
                onChanged: (v) => _toggleNotification('email_mentions', v),
              ),
              _SwitchTile(
                label: 'Profile visits',
                value: notifications.emailProfileVisits,
                onChanged: (v) => _toggleNotification('email_profile_visits', v),
              ),
              _SwitchTile(
                label: 'Friend requests',
                value: notifications.emailFriendRequests,
                onChanged: (v) => _toggleNotification('email_friend_requests', v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Sounds',
            icon: Icons.volume_up,
            gradient: const [Color(0xFFFFB74D), Color(0xFFF57C00)],
            children: [
              _SwitchTile(
                label: 'Notifications sound',
                value: notifications.notificationsSound,
                onChanged: (v) => _toggleNotification('notifications_sound', v),
              ),
              _SwitchTile(
                label: 'Chat sound',
                value: notifications.chatSound,
                onChanged: (v) => _toggleNotification('chat_sound', v),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // ---------- helpers ----------
  static const _validValues = ['public', 'friends', 'me'];
  String _safePrivacyValue(String raw) =>
      _validValues.contains(raw) ? raw : 'public';
}
// =================== Reusable UI Pieces ===================
class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Error: $message',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    required this.gradient,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  final List<Color> gradient;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              children: [
                _GradientIconBadge(icon: icon, gradient: gradient),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._withDividers(children),
          ],
        ),
      ),
    );
  }
  List<Widget> _withDividers(List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i != items.length - 1) {
        result.add(const Divider(height: 14));
      }
    }
    return result;
  }
}
class _GradientIconBadge extends StatelessWidget {
  const _GradientIconBadge({required this.icon, required this.gradient});
  final IconData icon;
  final List<Color> gradient;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: gradient),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  static const _items = [
    DropdownMenuItem(value: 'public', child: Text('Public')),
    DropdownMenuItem(value: 'friends', child: Text('Friends')),
    DropdownMenuItem(value: 'me', child: Text('Only me')),
  ];
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: _items,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
