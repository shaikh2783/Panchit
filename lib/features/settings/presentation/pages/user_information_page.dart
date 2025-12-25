import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../main.dart' show globalApiClient;
import '../../data/models/download_settings.dart';
import '../../data/services/information_api_service.dart';

class UserInformationPage extends StatefulWidget {
  const UserInformationPage({super.key});

  @override
  State<UserInformationPage> createState() => _UserInformationPageState();
}

class _UserInformationPageState extends State<UserInformationPage> {
  late final InformationApiService _apiService;
  DownloadSettings? settings;
  bool isLoading = false;
  bool isDownloading = false;
  Map<String, bool> selectedOptions = {};

  @override
  void initState() {
    super.initState();
    _apiService = InformationApiService(globalApiClient);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => isLoading = true);

    try {
      final result = await _apiService.getDownloadSettings();

      if (mounted) {
        setState(() {
          isLoading = false;
          if (result['success']) {
            settings = result['settings'];
            // Initialize selected options
            for (var key in settings!.availableKeys) {
              selectedOptions[key] = false;
            }
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

  Future<void> _downloadData() async {
    if (selectedOptions.values.every((v) => !v)) {
      _showError('Select which information you would like to download');
      return;
    }

    setState(() => isDownloading = true);

    try {
      final result = await _apiService.downloadUserData(
        options: selectedOptions,
      );

      if (mounted) {
        setState(() => isDownloading = false);

        if (result['success']) {
          _showSuccess(result['message'] ?? 'Data download prepared');
          // HTML content is returned in htmlContent field
          if (result['htmlContent'] != null && result['htmlContent'] is String) {
            _showHtmlPreview(result['htmlContent'] as String);
          }
        } else {
          _showError(result['message'] ?? 'Failed to prepare download');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isDownloading = false);
        _showError('Error during download: ${e.toString()}');
      }
    }
  }

  void _showHtmlPreview(String htmlContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Preview (HTML)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              htmlContent.length > 500 
                ? '${htmlContent.substring(0, 500)}...\n\n[Full HTML content - ${htmlContent.length} characters]'
                : htmlContent,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // In production, save/download the HTML file
              _saveHtmlFile(htmlContent);
              Navigator.pop(context);
            },
            child: const Text('Save File'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveHtmlFile(String htmlContent) async {
    try {
      // Get downloads directory or documents directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        _showError('Could not access storage directory');
        return;
      }

      // Create filename with timestamp
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final filename = 'user_data_$timestamp.html';
      final filepath = '${directory.path}/$filename';

      // Write HTML to file
      final file = File(filepath);
      await file.writeAsString(htmlContent);

      if (mounted) {
        _showSuccess('✅ File saved: $filename\nLocation: ${directory.path}');
      }
    } catch (e) {
      _showError('Failed to save file: ${e.toString()}');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات الحساب'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : settings == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('فشل تحميل البيانات'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSettings,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    if (!settings!.downloadEnabled)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_rounded,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'التحميل معطل',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    settings!.isDemoAccount
                                        ? 'الحسابات التجريبية لا يمكنها تحميل البيانات'
                                        : 'تحميل البيانات معطل من قبل المشرف',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.download_rounded,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'تحميل بيانات الحساب',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'حمّل نسخة كاملة من بيانات حسابك وفقاً لمتطلبات GDPR',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    if (settings!.downloadEnabled) ...[
                      // Options
                      const Text(
                        'اختر البيانات المراد تحميلها:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...settings!.availableKeys.map((key) {
                        final label = settings!.getLabel(key);
                        final description = settings!.getDescription(key);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CheckboxListTile(
                            value: selectedOptions[key] ?? false,
                            onChanged: (value) {
                              setState(() {
                                selectedOptions[key] = value ?? false;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tileColor: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            title: Text(label),
                            subtitle: Text(description),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 24),

                      // Download Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isDownloading ? null : _downloadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isDownloading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.download_rounded),
                                    SizedBox(width: 8),
                                    Text(
                                      'تحميل البيانات',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'سيتم تحميل البيانات بصيغة JSON. يمكنك عرضها وحفظها على جهازك.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
