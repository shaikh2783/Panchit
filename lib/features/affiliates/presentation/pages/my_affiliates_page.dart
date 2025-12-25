import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:snginepro/features/affiliates/data/models/affiliated_user.dart';
import 'package:snginepro/features/affiliates/data/models/affiliates_settings.dart';
import 'package:snginepro/features/affiliates/data/services/affiliates_api_service.dart';
import '../../../../main.dart' show globalApiClient;

class MyAffiliatesPage extends StatefulWidget {
  const MyAffiliatesPage({Key? key}) : super(key: key);

  @override
  State<MyAffiliatesPage> createState() => _MyAffiliatesPageState();
}

class _MyAffiliatesPageState extends State<MyAffiliatesPage> {
  late final AffiliatesApiService _apiService;
  late Future<AffiliatesSettings?> _settingsFuture;
  late Future<List<AffiliatedUser>> _affiliatesFuture;

  @override
  void initState() {
    super.initState();
    _apiService = AffiliatesApiService(globalApiClient);
    _settingsFuture = _loadSettings();
    _affiliatesFuture = _loadAffiliates();
  }

  Future<AffiliatesSettings?> _loadSettings() async {
    final response = await _apiService.getSettings();
    if (response['success'] == true) {
      return AffiliatesSettings.fromJson(response['data']);
    }
    return null;
  }

  Future<List<AffiliatedUser>> _loadAffiliates() async {
    final response = await _apiService.getAffiliatesList();
    if (response['success'] == true) {
      final data = response['data'];
      if (data is List) {
        return data.map((e) => AffiliatedUser.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<void> _refreshData() async {
    setState(() {
      _settingsFuture = _loadSettings();
      _affiliatesFuture = _loadAffiliates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('affiliates'.tr),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<AffiliatesSettings?>(
          future: _settingsFuture,
          builder: (context, settingsSnapshot) {
            if (settingsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final settings = settingsSnapshot.data;

            return ListView(
              children: [
                // Affiliates System Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'affiliates_system'.tr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Get.isDarkMode
                              ? const Color(0xFF6C63FF).withOpacity(0.15)
                              : const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFF6C63FF,
                            ).withOpacity(Get.isDarkMode ? 0.4 : 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'earn_per_referral'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Get.isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'paid_when_register'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                color: Get.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'withdraw_or_transfer'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                color: Get.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Referral Link Section
                if (settings != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'your_affiliate_link'.tr,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Get.isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Get.isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  settings.referralUrl,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Courier',
                                    color: Get.isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('referral_link_copied'.tr),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.copy,
                                    color: const Color(0xFF6C63FF),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('referral_link_share'.tr),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.share),
                            label: Text('share'.tr),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Balance Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'affiliates_money_balance'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF6C63FF).withOpacity(0.9),
                              const Color(0xFF8E7FFF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'total_balance'.tr,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '\$0.00',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${settings?.affiliatesCount ?? 0} ${'referrals'.tr}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Affiliates list header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'your_referrals'.tr,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                FutureBuilder<List<AffiliatedUser>>(
                  future: _affiliatesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError || snapshot.data == null) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'failed_load_data'.tr,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    final affiliates = snapshot.data ?? [];

                    if (affiliates.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'no_affiliates'.tr,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'start_sharing_link'.tr,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: affiliates.length,
                      itemBuilder: (context, index) {
                        final affiliate = affiliates[index];
                        return _buildAffiliateCard(affiliate, index);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAffiliateCard(AffiliatedUser user, int index) {
    return AnimatedSlide(
      duration: Duration(milliseconds: 300 + (index * 50)),
      offset: Offset.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        child: Card(
          elevation: Get.isDarkMode ? 2 : 1,
          color: Get.isDarkMode ? Colors.grey[800] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: user.userPicture.isNotEmpty
                  ? NetworkImage(user.userPicture)
                  : null,
              backgroundColor: Get.isDarkMode
                  ? Colors.grey[700]
                  : Colors.grey[300],
              child: user.userPicture.isEmpty
                  ? Text(
                      user.userFirstname.isNotEmpty
                          ? user.userFirstname[0]
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              user.fullName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Get.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '@${user.userName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${'joined'.tr}: ${DateFormat('dd MMM yyyy', 'en').format(DateTime.parse(user.connectionDate))}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Get.isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Chip(
              label: Text(
                user.levelLabel,
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
              backgroundColor: _getLevelColor(user.referrerLevel),
            ),
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFF6C63FF);
      case 2:
        return const Color(0xFF00B4DB);
      case 3:
        return const Color(0xFF00D4FF);
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
