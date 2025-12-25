import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../main.dart' show globalApiClient;
import '../../data/models/two_factor_status.dart';
import '../../data/services/two_factor_api_service.dart';

class TwoFactorAuthPage extends StatefulWidget {
  const TwoFactorAuthPage({super.key});

  @override
  State<TwoFactorAuthPage> createState() => _TwoFactorAuthPageState();
}

class _TwoFactorAuthPageState extends State<TwoFactorAuthPage> {
  late final TwoFactorApiService _apiService;
  TwoFactorStatus? status;
  bool isLoading = false;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiService = TwoFactorApiService(globalApiClient);
    _loadStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() => isLoading = true);

    try {
      final result = await _apiService.getStatus();

      if (mounted) {
        setState(() {
          isLoading = false;
          if (result['success']) {
            status = result['status'];
          } else {
            _showError(result['message']);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showError('حدث خطأ أثناء تحميل البيانات');
      }
    }
  }

  Future<void> _toggleTwoFactor() async {
    if (status == null) return;

    if (status!.userEnabled) {
      _showDisableDialog();
    } else {
      if (status!.systemType == 'google') {
        _showEnableGoogleDialog();
      } else {
        _enableTwoFactor();
      }
    }
  }

  void _showEnableGoogleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل المصادقة الثنائية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'امسح رمز QR باستخدام تطبيق Google Authenticator، ثم أدخل الرمز المكون من 6 أرقام',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 4),
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _enableTwoFactor(code: _codeController.text);
            },
            child: const Text('تفعيل'),
          ),
        ],
      ),
    );
  }

  void _showDisableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعطيل المصادقة الثنائية'),
        content: const Text(
          'هل أنت متأكد من تعطيل المصادقة الثنائية؟ سيقلل ذلك من مستوى أمان حسابك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _disableTwoFactor();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تعطيل'),
          ),
        ],
      ),
    );
  }

  Future<void> _enableTwoFactor({String? code}) async {
    setState(() => isLoading = true);

    try {
      final result = await _apiService.enable(code: code);

      if (mounted) {
        setState(() => isLoading = false);

        if (result['success']) {
          _showSuccess(result['message']);
          _codeController.clear();
          await _loadStatus();
        } else {
          _showError(result['message']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showError('حدث خطأ أثناء التفعيل');
      }
    }
  }

  Future<void> _disableTwoFactor() async {
    setState(() => isLoading = true);

    try {
      final result = await _apiService.disable();

      if (mounted) {
        setState(() => isLoading = false);

        if (result['success']) {
          _showSuccess(result['message']);
          await _loadStatus();
        } else {
          _showError(result['message']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showError('حدث خطأ أثناء التعطيل');
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _copySecret() {
    if (status?.googleSecret != null) {
      Clipboard.setData(ClipboardData(text: status!.googleSecret!));
      _showSuccess('تم نسخ المفتاح');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المصادقة الثنائية'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : status == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('فشل تحميل البيانات'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStatus,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: status!.userEnabled
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : [Colors.grey.shade400, Colors.grey.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (status!.userEnabled
                                        ? Colors.green
                                        : Colors.grey)
                                    .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            status!.userEnabled
                                ? Icons.verified_user
                                : Icons.security,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            status!.userEnabled ? 'مُفعّلة' : 'معطلة',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            status!.userEnabled
                                ? 'حسابك محمي بالمصادقة الثنائية'
                                : 'قم بتفعيل المصادقة الثنائية لحماية أفضل',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // System Info
                    if (!status!.systemEnabled)
                      _buildWarningCard(
                        'المصادقة الثنائية معطلة',
                        'المصادقة الثنائية معطلة من قبل المسؤول',
                        Icons.warning,
                        Colors.orange,
                      )
                    else ...[
                      _buildInfoCard(
                        'نوع المصادقة',
                        status!.typeDisplayName,
                        status!.typeIcon,
                        theme,
                        isDark,
                      ),

                      const SizedBox(height: 16),

                      _buildInfoCard(
                        'الوصف',
                        status!.typeDescription,
                        Icons.info_outline,
                        theme,
                        isDark,
                      ),

                      // Requirements
                      if (status!.requirements.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildWarningCard(
                          'متطلبات التفعيل',
                          status!.requirements.join('\n'),
                          Icons.checklist,
                          Colors.orange,
                        ),
                      ],

                      // QR Code for Google
                      if (status!.systemType == 'google' &&
                          status!.googleQrCode != null &&
                          !status!.userEnabled) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'امسح رمز QR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (status!.googleQrCode != null)
                                QrImageView(
                                  data: _extractOtpAuthUrl(
                                    status!.googleQrCode!,
                                  ),
                                  version: QrVersions.auto,
                                  size: 200,
                                ),
                              const SizedBox(height: 16),
                              if (status!.googleSecret != null) ...[
                                const Text(
                                  'أو أدخل المفتاح يدوياً:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        status!.googleSecret!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 20),
                                      onPressed: _copySecret,
                                      tooltip: 'نسخ',
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Toggle Button
                      if (status!.systemEnabled)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: status!.canEnable || status!.userEnabled
                                ? _toggleTwoFactor
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: status!.userEnabled
                                  ? Colors.red
                                  : Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              status!.userEnabled
                                  ? 'تعطيل المصادقة الثنائية'
                                  : 'تفعيل المصادقة الثنائية',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String content,
    IconData icon,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(content, style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _extractOtpAuthUrl(String qrCodeUrl) {
    // Extract otpauth URL from Google Chart API URL
    final uri = Uri.parse(qrCodeUrl);
    final chl = uri.queryParameters['chl'];
    return chl ?? '';
  }
}
