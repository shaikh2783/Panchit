import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../main.dart' show globalApiClient;
import '../../data/models/monetization_settings.dart';
import '../../data/services/monetization_api_service.dart';

class MonetizationSettingsPage extends StatefulWidget {
  const MonetizationSettingsPage({super.key});

  @override
  State<MonetizationSettingsPage> createState() =>
      _MonetizationSettingsPageState();
}

class _MonetizationSettingsPageState extends State<MonetizationSettingsPage> {
  late final MonetizationApiService _apiService;

  MonetizationSettings? _settings;
  bool _isLoading = false;
  bool _monetizationEnabled = false;

  final _chatPriceController = TextEditingController();
  final _callPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiService = MonetizationApiService(globalApiClient);
    _loadSettings();
  }

  @override
  void dispose() {
    _chatPriceController.dispose();
    _callPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final result = await _apiService.getMonetizationSettings();

    if (result['success']) {
      final settings = result['settings'] as MonetizationSettings;
      setState(() {
        _settings = settings;
        _monetizationEnabled = settings.monetizationEnabled;
        _chatPriceController.text = settings.chatPrice.toStringAsFixed(2);
        _callPriceController.text = settings.callPrice.toStringAsFixed(2);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _showError(result['message']);
    }
  }

  Future<void> _updateSettings() async {
    if (!_monetizationEnabled) {
      // Disable monetization directly
      final result = await _apiService.updateMonetizationSettings(
        enabled: false,
        chatPrice: 0,
        callPrice: 0,
      );

      _showResult(result);
      if (result['success']) {
        await _loadSettings();
      }
      return;
    }

    final chatPrice = double.tryParse(_chatPriceController.text);
    final callPrice = double.tryParse(_callPriceController.text);

    if (chatPrice == null || callPrice == null) {
      _showError('enter_valid_prices'.tr);
      return;
    }

    if (chatPrice < (_settings?.minPrice ?? 0) ||
        callPrice < (_settings?.minPrice ?? 0)) {
      _showError(
        '${'minimum_price_is'.tr} \$${_settings?.minPrice.toStringAsFixed(2)}',
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _apiService.updateMonetizationSettings(
      enabled: _monetizationEnabled,
      chatPrice: chatPrice,
      callPrice: callPrice,
    );

    setState(() => _isLoading = false);
    _showResult(result);

    if (result['success']) {
      await _loadSettings();
    }
  }

  void _showResult(Map<String, dynamic> result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
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

    if (_isLoading && _settings == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('monetization_settings'.tr),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_settings == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('monetization_settings'.tr),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('failed_load_settings'.tr),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadSettings,
                icon: const Icon(Icons.refresh),
                label: Text('retry'.tr),
              ),
            ],
          ),
        ),
      );
    }

    if (!_settings!.canMonetize) {
      return Scaffold(
        appBar: AppBar(
          title: Text('monetization_settings'.tr),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF5350).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'monetization_not_available'.tr,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'no_permission_monetize'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('monetization_settings'.tr),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _loadSettings,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.grey.shade900, Colors.black]
                : [Colors.grey.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _StatsCard(
                    icon: Icons.subscriptions_rounded,
                    label: 'subscribers'.tr,
                    value: _settings!.subscribersCount.toString(),
                    gradient: const [Color(0xFF66BB6A), Color(0xFF388E3C)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatsCard(
                    icon: Icons.card_membership_rounded,
                    label: 'plans'.tr,
                    value: _settings!.totalPlans.toString(),
                    gradient: const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Enable/Disable Monetization
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              color: isDark ? Colors.grey[850] : Colors.white,
              child: SwitchListTile(
                title: Text(
                  'enable_monetization'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _monetizationEnabled
                      ? 'monetization_active'.tr
                      : 'enable_to_earn'.tr,
                ),
                value: _monetizationEnabled,
                onChanged: (value) {
                  setState(() => _monetizationEnabled = value);
                },
                secondary: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _monetizationEnabled
                          ? const [Color(0xFF66BB6A), Color(0xFF388E3C)]
                          : [Colors.grey.shade400, Colors.grey.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.monetization_on_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            if (_monetizationEnabled) ...[
              const SizedBox(height: 24),

              // System Info
              if (_settings!.systemSettings.verificationRequired)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'verification_required_monetization'.tr,
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Chat Price
              _PriceField(
                controller: _chatPriceController,
                label: 'chat_price'.tr,
                icon: Icons.chat_rounded,
                minPrice: _settings!.minPrice,
                currency: _settings!.systemSettings.currency,
              ),

              const SizedBox(height: 16),

              // Call Price
              _PriceField(
                controller: _callPriceController,
                label: 'call_price'.tr,
                icon: Icons.phone_rounded,
                minPrice: _settings!.minPrice,
                currency: _settings!.systemSettings.currency,
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'save_settings'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],

            if (_monetizationEnabled && !_isLoading) ...[
              const SizedBox(height: 32),

              // Subscription Plans Section
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.card_membership_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'subscription_plans'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (_settings!.plans.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'no_subscription_plans'.tr,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...List.generate(
                  _settings!.plans.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PlanCard(plan: _settings!.plans[index]),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;

  const _StatsCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final double minPrice;
  final String currency;

  const _PriceField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.minPrice,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '$label (\$$currency)',
        hintText: 'Min: \$${minPrice.toStringAsFixed(2)}',
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade800.withOpacity(0.5)
            : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF66BB6A), width: 2),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final MonetizationPlan plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey.shade800, Colors.grey.shade900]
              : [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (plan.customDescription != null &&
                    plan.customDescription!.isNotEmpty)
                  Text(
                    plan.customDescription!,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${plan.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF66BB6A),
                ),
              ),
              Text(
                '${'per'.tr} ${plan.periodText}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
