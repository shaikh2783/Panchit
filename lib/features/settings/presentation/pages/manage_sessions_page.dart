import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../main.dart' show globalApiClient;
import '../../data/models/session_model.dart';
import '../../data/services/sessions_api_service.dart';

class ManageSessionsPage extends StatefulWidget {
  const ManageSessionsPage({super.key});

  @override
  State<ManageSessionsPage> createState() => _ManageSessionsPageState();
}

class _ManageSessionsPageState extends State<ManageSessionsPage> {
  late final SessionsApiService _apiService;
  List<UserSession> sessions = [];
  bool isLoading = false;
  int? currentSessionId;

  @override
  void initState() {
    super.initState();
    _apiService = SessionsApiService(globalApiClient);
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => isLoading = true);

    try {
      final result = await _apiService.getSessions();

      if (mounted) {
        setState(() {
          isLoading = false;
          if (result['success']) {
            sessions = result['sessions'];
            currentSessionId = result['currentSessionId'];
          } else {
            _showSnackBar(result['message'], isError: true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar('failed_load_sessions'.tr, isError: true);
      }
    }
  }

  Future<void> _deleteSession(UserSession session) async {
    final confirm = await _showConfirmDialog(
      title: 'sign_out_device'.tr,
      message: '${'sign_out_device_confirm'.tr} ${session.deviceLabel}?',
    );

    if (confirm == true) {
      setState(() => isLoading = true);

      final result = await _apiService.deleteSession(
        sessionId: session.sessionId,
      );

      if (mounted) {
        setState(() => isLoading = false);

        if (result['success']) {
          setState(() {
            sessions.removeWhere((s) => s.sessionId == session.sessionId);
          });
          _showSnackBar(result['message']);
        } else {
          _showSnackBar(result['message'], isError: true);
        }
      }
    }
  }

  Future<void> _deleteAllOthers() async {
    final confirm = await _showConfirmDialog(
      title: 'sign_out_all_title'.tr,
      message:
          '${'sign_out_all_confirm'.tr} ${sessions.length - 1} ${'active_sessions_text'.tr}.',
      isDanger: true,
    );

    if (confirm == true) {
      setState(() => isLoading = true);

      final result = await _apiService.deleteAllOtherSessions();

      if (mounted) {
        setState(() => isLoading = false);

        if (result['success']) {
          await _loadSessions(); // Reload to show only current session
          _showSnackBar(
            '${result['deletedCount']} ${'sessions_signed_out'.tr}',
          );
        } else {
          _showSnackBar(result['message'], isError: true);
        }
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDanger ? Colors.red : Colors.orange).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isDanger ? Icons.warning_rounded : Icons.info_outline_rounded,
                color: isDanger ? Colors.red : Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('cancel'.tr),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: isDanger ? Colors.red : Colors.orange,
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(isDanger ? 'sign_out_all'.tr : 'sign_out'.tr),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  IconData _getDeviceIcon(String sessionType) {
    switch (sessionType) {
      case 'W':
        return Icons.computer_rounded;
      case 'A':
        return Icons.phone_android_rounded;
      case 'I':
        return Icons.phone_iphone_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  Color _getDeviceColor(String sessionType, bool isCurrent) {
    if (isCurrent) return const Color(0xFF43A047);
    switch (sessionType) {
      case 'W':
        return const Color(0xFF42A5F5);
      case 'A':
        return const Color(0xFF66BB6A);
      case 'I':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'just_now'.tr;
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}${'minutes_ago'.tr}';
      } else if (diff.inDays < 1) {
        return '${diff.inHours}${'hours_ago'.tr}';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}${'days_ago'.tr}';
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final otherSessionsCount = sessions.where((s) => !s.isCurrent).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'manage_sessions_title'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
        centerTitle: true,
        actions: [
          if (otherSessionsCount > 0)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'sign_out_all_devices'.tr,
              onPressed: _deleteAllOthers,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading && sessions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSessions,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Header Card
                  _buildHeaderCard(theme, isDark, otherSessionsCount),
                  const SizedBox(height: 24),

                  // Sessions Info
                  if (sessions.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'active_sessions'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${sessions.length} ${sessions.length == 1 ? 'device'.tr : 'devices'.tr}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sessions List
                    ...sessions.map(
                      (session) => _buildSessionCard(theme, session, isLoading),
                    ),
                  ],

                  if (sessions.isEmpty && !isLoading) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.devices_other_rounded,
                            size: 80,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'no_active_sessions'.tr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (isLoading && sessions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(
    ThemeData theme,
    bool isDark,
    int otherSessionsCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF388E3C).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.devices_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'active_sessions'.tr,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            otherSessionsCount > 0
                ? '${'signed_in_on_other'.tr} $otherSessionsCount ${'other'.tr} ${otherSessionsCount == 1 ? 'device'.tr : 'devices'.tr}'
                : 'signed_in_only_this'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.95),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    ThemeData theme,
    UserSession session,
    bool isDisabled,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: session.isCurrent
              ? const Color(0xFF43A047).withOpacity(0.3)
              : theme.dividerColor.withOpacity(0.2),
          width: session.isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Device Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getDeviceColor(
                  session.sessionType,
                  session.isCurrent,
                ).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getDeviceIcon(session.sessionType),
                size: 28,
                color: _getDeviceColor(session.sessionType, session.isCurrent),
              ),
            ),
            const SizedBox(width: 16),

            // Device Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.deviceLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (session.isCurrent)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF43A047).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'current'.tr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF43A047),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.deviceTypeLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(session.sessionDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.6,
                          ),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          session.userIp,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete Button
            if (!session.isCurrent)
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                color: Colors.red,
                iconSize: 22,
                onPressed: isDisabled ? null : () => _deleteSession(session),
                tooltip: 'sign_out'.tr,
              ),
          ],
        ),
      ),
    );
  }
}
