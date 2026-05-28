import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snginepro/features/pages/presentation/pages/page_profile_page.dart';
// Groups module removed; discover page no longer links to groups
import 'package:snginepro/features/profile/presentation/pages/profile_page.dart';
import 'package:snginepro/features/merits/data/services/merits_api_service.dart';
import 'package:snginepro/features/merits/data/models/merit_models.dart';
import 'package:snginepro/features/friends/data/services/user_relationships_service.dart';
import '../controllers/discover_controller.dart';
import '../../data/services/homepage_widgets_api_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Discover content and recommendations page
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late final DiscoverController controller;
  late final MeritsApiService _meritsApiService;
  late final UserRelationshipsService _userRelationshipsService;

  /// Build image URL correctly
  String _buildImageUrl(String imageUrl) {
    // If the URL is already complete, return it as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // If the URL has a domain but no protocol
    if (imageUrl.contains('panchit.fluttercrafters.com')) {
      return 'https://$imageUrl';
    }

    // Build the URL using appConfig
    return appConfig.mediaAsset(imageUrl).toString();
  }

  /// Navigate to the user profile page
  void _navigateToUserProfile(int userId, String username) {

    Get.to(ProfilePage(userId: userId,username: username,));
  }

  /// Navigate to a page profile with pageId only
  void _navigateToPageById(int pageId, [String? pageName]) {
    Get.to(() => PageProfilePage.fromId(pageId: pageId));
  }

  /// Navigate to the group profile
  void _navigateToGroup(String groupId, String groupName) {
    // Get.to(() => GroupPage.byId(groupId: int.tryParse(groupId) ?? 0));
  }

  /// Navigate to the event details page
  void _navigateToEvent(String eventId, String eventName) {
    // Perform navigation to the event details page
    Get.toNamed(
      '/event_details',
      arguments: {'eventId': eventId, 'eventName': eventName},
    );
  }

  @override
  void initState() {
    super.initState();
    controller = Get.put(DiscoverController());
    _meritsApiService = MeritsApiService(Get.find<ApiClient>());
    _userRelationshipsService = UserRelationshipsService(Get.find<ApiClient>());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Get.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.discover, color: Colors.blue, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'discover'.tr,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.grey[900],
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Iconsax.refresh,
              color: isDarkMode ? Colors.white : Colors.grey[700],
            ),
            onPressed: () => controller.refresh(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }

        if (controller.errorMessage.isNotEmpty) {
          // Determine error type
          bool isAuthError =
              controller.errorMessage.toLowerCase().contains('log in') ||
              controller.errorMessage.toLowerCase().contains('authenticated');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAuthError ? Iconsax.user : Iconsax.wifi_square,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isAuthError
                      ? 'login_required'.tr
                      : 'failed_to_load_content'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAuthError
                      ? 'login_personalized_content'.tr
                      : controller.errorMessage,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isAuthError
                      ? () {
                          // Navigate to the login page
                          Get.offAllNamed('/login');
                        }
                      : () => controller.refresh(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isAuthError ? 'login'.tr : 'try_again'.tr),
                ),
              ],
            ),
          );
        }

        final widgets = controller.widgets;
        if (widgets == null) {
          return Center(child: Text('no_data'.tr));
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Merits Balance Section
                if (widgets.meritsBalance != null &&
                    widgets.meritsBalance!.enabled)
                  _buildMeritsSection(widgets.meritsBalance!),

                if (widgets.meritsBalance != null &&
                    widgets.meritsBalance!.enabled)
                  const SizedBox(height: 24),

                // Pro Users Section
                if (widgets.proUsers != null && widgets.proUsers!.enabled)
                  _buildProUsersSection(widgets.proUsers!),

                if (widgets.proUsers != null && widgets.proUsers!.enabled)
                  const SizedBox(height: 24),

                // Pro Pages Section
                if (widgets.proPages != null && widgets.proPages!.enabled)
                  _buildProPagesSection(widgets.proPages!),

                if (widgets.proPages != null && widgets.proPages!.enabled)
                  const SizedBox(height: 24),

                // Trending Section
                if (widgets.trendingHashtags != null &&
                    widgets.trendingHashtags!.enabled)
                  _buildTrendingSection(widgets.trendingHashtags!),

                if (widgets.trendingHashtags != null &&
                    widgets.trendingHashtags!.enabled)
                  const SizedBox(height: 24),

                // Suggested Friends Section
                if (widgets.suggestedFriends != null &&
                    widgets.suggestedFriends!.enabled)
                  _buildSuggestedFriendsSection(widgets.suggestedFriends!),

                if (widgets.suggestedFriends != null &&
                    widgets.suggestedFriends!.enabled)
                  const SizedBox(height: 24),

                // Suggested Pages Section
                if (widgets.suggestedPages != null &&
                    widgets.suggestedPages!.enabled)
                  _buildSuggestedPagesSection(widgets.suggestedPages!),

                if (widgets.suggestedPages != null &&
                    widgets.suggestedPages!.enabled)
                  const SizedBox(height: 24),

                // Suggested Groups Section
                if (widgets.suggestedGroups != null &&
                    widgets.suggestedGroups!.enabled)
                  _buildSuggestedGroupsSection(widgets.suggestedGroups!),

                if (widgets.suggestedGroups != null &&
                    widgets.suggestedGroups!.enabled)
                  const SizedBox(height: 24),

                // Suggested Events Section
                if (widgets.suggestedEvents != null &&
                    widgets.suggestedEvents!.enabled)
                  _buildSuggestedEventsSection(widgets.suggestedEvents!),

                 SizedBox(height: Get.height *0.10),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Build merits balance section
  Widget _buildMeritsSection(MeritsBalanceWidget widget) {
    final isDarkMode = Get.isDarkMode;
    
    return Column(
      children: [
        // Merits Balance Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade400, Colors.orange.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Iconsax.medal_star, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'merits_section_title'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'merits_remaining_message'.trArgs([
                        widget.balance.remaining.toString(),
                      ]),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMeritsStat('merits_total', widget.balance.total),
                        const SizedBox(width: 20),
                        _buildMeritsStat('merits_spent', widget.balance.spent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Send Merits Button
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Show Send Merits dialog
                _showSendMeritsDialog(widget);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade300,
                            Colors.orange.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Iconsax.send,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'send_merits_title'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'send_merits_subtitle'.tr,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Iconsax.arrow_right,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Show Send Merits Dialog
  void _showSendMeritsDialog(MeritsBalanceWidget widget) {
    final isDarkMode = Get.isDarkMode;
    late List<MeritCategory> categories;
    int? selectedCategoryId;
    final messageController = TextEditingController();
    bool isLoading = false;
    List<int> selectedFriendIds = [];
    String friendSearchQuery = '';
    // Store future to prevent multiple calls on setState
    late Future<Map<String, dynamic>> friendsFuture;
    late Future<List<MeritCategory>> categoriesFuture;
    String? selectedImagePath;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomContext) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'send_merits_title'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: isDarkMode ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'merits_available'.trArgs([
                    widget.balance.remaining.toString(),
                  ]),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        color: Colors.amber[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'send_merits_info'.tr,
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Initialize futures once to prevent multiple calls
                ...[
                  () {
                    categoriesFuture = _meritsApiService.getMeritsCategories();
                    friendsFuture = _userRelationshipsService.getFriends(limit: 50);
                    return SizedBox.shrink();
                  }()
                ],

                // Load categories and friends in parallel
                FutureBuilder<List<MeritCategory>>(
                  future: categoriesFuture,
                  builder: (context, categoriesSnapshot) {
                    if (categoriesSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (categoriesSnapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'merit_categories_load_error'.tr,
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      );
                    }

                    if (!categoriesSnapshot.hasData || categoriesSnapshot.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'merit_no_categories'.tr,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }

                    categories = categoriesSnapshot.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category dropdown
                        Text(
                          'merit_category_select'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: selectedCategoryId,
                            hint: Text(
                              'merit_category_hint'.tr,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            items: categories
                                .map((cat) => DropdownMenuItem<int>(
                                      value: cat.categoryId,
                                      child: Text(
                                        cat.categoryName,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.grey[800],
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCategoryId = value;
                              });
                            },
                            underline: const SizedBox(),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.grey[800],
                            ),
                            dropdownColor: isDarkMode
                                ? const Color(0xFF2A2A2A)
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Friends selection
                        Text(
                          'merit_recipients_select'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Search field for friends
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              friendSearchQuery = value;
                            });
                          },
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.grey[800],
                          ),
                          decoration: InputDecoration(
                            hintText: 'merit_search_friend'.tr,
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: Icon(
                              Iconsax.search_normal_1,
                              color: Colors.amber[700],
                              size: 20,
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.amber.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.amber.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.amber.shade400,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Friends list with checkboxes
                        FutureBuilder<Map<String, dynamic>>(
                          future: friendsFuture,
                          builder: (context, friendsSnapshot) {
                            if (friendsSnapshot.connectionState == ConnectionState.waiting) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.amber[700]!,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'merit_friends_loading'.tr,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (friendsSnapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'merit_friends_load_error'.tr,
                                  style: TextStyle(color: Colors.red[600]),
                                ),
                              );
                            }

                            final friends = friendsSnapshot.data?['friends'] as List? ?? [];
                            
                            if (friends.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'merit_no_friends_available'.tr,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              );
                            }

                            // Filter friends by search query
                            final filteredFriends = friendSearchQuery.isEmpty
                                ? friends
                                : friends
                                    .where((friend) =>
                                        friend.name
                                            .toLowerCase()
                                            .contains(friendSearchQuery.toLowerCase()) ||
                                        friend.userName
                                            .toLowerCase()
                                            .contains(friendSearchQuery.toLowerCase()))
                                    .toList();

                            return Container(
                              constraints: const BoxConstraints(maxHeight: 250),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                ),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredFriends.length,
                                itemBuilder: (context, index) {
                                  final friend = filteredFriends[index];
                                  final isSelected = selectedFriendIds.contains(friend.userId);

                                  return CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedFriendIds.add(friend.userId);
                                        } else {
                                          selectedFriendIds.remove(friend.userId);
                                        }
                                      });
                                    },
                                    title: Text(
                                      friend.name,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.grey[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '@${friend.userName}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    secondary: CachedNetworkImage(
                                      imageUrl: friend.userPicture,
                                      imageBuilder: (context, imageProvider) =>
                                          CircleAvatar(
                                        backgroundImage: imageProvider,
                                        radius: 16,
                                      ),
                                      placeholder: (context, url) =>
                                          CircleAvatar(
                                        backgroundColor: Colors.grey[400],
                                        radius: 16,
                                        child: Icon(
                                          Iconsax.profile_circle,
                                          color: Colors.grey[600],
                                          size: 18,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          CircleAvatar(
                                        backgroundColor: Colors.grey[400],
                                        radius: 16,
                                        child: Icon(
                                          Iconsax.profile_circle,
                                          color: Colors.grey[600],
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    activeColor: Colors.amber[700],
                                    checkColor: Colors.white,
                                    tileColor: isDarkMode
                                        ? (isSelected
                                            ? Colors.amber.withValues(alpha: 0.1)
                                            : Colors.transparent)
                                        : (isSelected
                                            ? Colors.amber.withValues(alpha: 0.05)
                                            : Colors.transparent),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        
                        // Selected friends count
                        if (selectedFriendIds.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'merit_selected_friends'.trArgs(['${selectedFriendIds.length}']),
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Image selection
                        Text(
                          'merit_image_label'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (pickedFile != null) {
                              setState(() {
                                selectedImagePath = pickedFile.path;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selectedImagePath != null
                                      ? Iconsax.image
                                      : Iconsax.gallery,
                                  color: selectedImagePath != null
                                      ? Colors.green
                                      : Colors.amber[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedImagePath != null
                                            ? 'merit_image_selected'.tr
                                            : 'merit_image_hint'.tr,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.grey[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (selectedImagePath != null)
                                        Text(
                                          selectedImagePath!
                                              .split('/')
                                              .last,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                if (selectedImagePath != null)
                                  IconButton(
                                    icon: Icon(
                                      Iconsax.close_circle,
                                      color: Colors.red[400],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        selectedImagePath = null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Message field
                        Text(
                          'merit_message_label'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: messageController,
                          maxLines: 3,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.grey[800],
                          ),
                          decoration: InputDecoration(
                            hintText: 'merit_message_hint'.tr,
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: isDarkMode
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.amber.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.amber.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.amber.shade400,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.grey[800],
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'cancel'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: isLoading
                                  ? ElevatedButton(
                                      onPressed: null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber.shade300,
                                        elevation: 0,
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: () async {
                                        if (selectedCategoryId == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text('merit_error_no_category'.tr),
                                              backgroundColor: Colors.red[600],
                                            ),
                                          );
                                          return;
                                        }

                                        if (selectedFriendIds.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text('merit_error_no_friends'.tr),
                                              backgroundColor: Colors.red[600],
                                            ),
                                          );
                                          return;
                                        }

                                        setState(() => isLoading = true);

                                        try {
                                          // Upload image if selected
                                          String? imageSource;
                                          if (selectedImagePath != null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text('uploading_image'.tr),
                                                duration: const Duration(seconds: 60),
                                              ),
                                            );

                                            try {
                                              final uploadResponse = await Get.find<ApiClient>().multipartPost(
                                                '/data/file/upload',
                                                body: {'type': 'photo'},
                                                filePath: selectedImagePath!,
                                                fileFieldName: 'file',
                                              );

                                              if (uploadResponse['status'] == 'success' &&
                                                  uploadResponse['data'] != null) {
                                                imageSource =
                                                    uploadResponse['data']['source'];
                                                ScaffoldMessenger.of(context)
                                                    .removeCurrentSnackBar();
                                              } else {
                                                throw Exception(
                                                  uploadResponse['message'] ??
                                                      'failed_to_upload_image'.tr,
                                                );
                                              }
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .removeCurrentSnackBar();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'failed_to_upload_image'.tr),
                                                  backgroundColor: Colors.red[600],
                                                ),
                                              );
                                              setState(() => isLoading = false);
                                              return;
                                            }
                                          }

                                          // Get selected friends from the filtered list
                                          final friendsResponse =
                                              await _userRelationshipsService
                                                  .getFriends(limit: 50);
                                          final allFriends =
                                              friendsResponse['friends'] as List;

                                          final recipients = selectedFriendIds
                                              .map((friendId) {
                                                try {
                                                  final friend = allFriends
                                                      .firstWhere(
                                                          (f) =>
                                                              f.userId ==
                                                              friendId);
                                                  return MeritRecipient(
                                                    id: friend.userId,
                                                    name: friend.name,
                                                  );
                                                } catch (e) {
                                                  return null;
                                                }
                                              })
                                              .where((r) => r != null)
                                              .cast<MeritRecipient>()
                                              .toList();

                                          final result = await _meritsApiService
                                              .sendMerit(
                                            recipients: recipients,
                                            categoryId: selectedCategoryId!,
                                            message: messageController.text,
                                            image: imageSource,
                                          );

                                          setState(() => isLoading = false);

                                          if (mounted) {
                                            if (result['success']) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content:
                                                      Text(result['message']),
                                                  backgroundColor:
                                                      Colors.green[600],
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content:
                                                      Text(result['message']),
                                                  backgroundColor:
                                                      Colors.red[600],
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          setState(() => isLoading = false);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(e.toString()),
                                                backgroundColor:
                                                    Colors.red[600],
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber[700],
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'send_now'.tr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeritsStat(String labelKey, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelKey.tr,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// Build featured users section
  Widget _buildProUsersSection(ProUsersWidget widget) {
    final isDarkMode = Get.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          widget.title,
          titleKey: 'pro_users_section_title',
          subtitleKey: 'premium_members_subtitle',
        ),
        const SizedBox(height: 12),
        SizedBox(
                 height: Get.height *0.32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.users.length,
            itemBuilder: (context, index) {
              final user = widget.users[index];
              return GestureDetector(
                onTap: () => _navigateToUserProfile(user.userId, user.username),
                child: Container(
                  width: 170,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.purple.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (user.subscribed)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Profile content
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: user.picture != null
                                      ? CachedNetworkImageProvider(
                                          _buildImageUrl(user.picture!),
                                        )
                                      : null,
                                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                  child: user.picture == null
                                      ? Text(
                                          user.fullName.isNotEmpty
                                              ? user.fullName[0]
                                              : 'U',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                          ),
                                        )
                                      : null,
                                ),
                                if (user.verified)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDarkMode
                                              ? const Color(0xFF1A1A1A)
                                              : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Iconsax.verify,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                                  ),
                                if (user.subscribed)
                                  Positioned(
                                    top: -2,
                                    right: -5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'PRO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.grey[900],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '@${user.username}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _navigateToUserProfile(
                                  user.userId,
                                  user.username,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'view_profile_button'.tr,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build featured pages section
  Widget _buildProPagesSection(ProPagesWidget widget) {
    final isDarkMode = Get.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          widget.title,
          titleKey: 'pro_pages_section_title',
          subtitleKey: 'premium_pages_subtitle',
        ),
        const SizedBox(height: 12),
        SizedBox(
               height: Get.height *0.32,

          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.pages.length,
            itemBuilder: (context, index) {
              final page = widget.pages[index];
              return GestureDetector(
                onTap: () => _navigateToPageById(page.pageId),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Cover area with gradient
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.indigo.shade400,
                              Colors.blue.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Page content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              // Page picture positioned to overlap
                              Transform.translate(
                                offset: const Offset(0, -25),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDarkMode
                                              ? const Color(0xFF1A1A1A)
                                              : Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 28,
                                        backgroundImage:
                                            page.pagePicture != null
                                            ? CachedNetworkImageProvider(
                                                _buildImageUrl(
                                                  page.pagePicture!,
                                                ),
                                              )
                                            : null,
                                        backgroundColor: Colors.indigo
                                            .withValues(alpha: 0.1),
                                        child: page.pagePicture == null
                                            ? Icon(
                                                Iconsax.building,
                                                color: Colors.indigo,
                                                size: 20,
                                              )
                                            : null,
                                      ),
                                    ),
                                    if (page.pageVerified)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDarkMode
                                                  ? const Color(0xFF1A1A1A)
                                                  : Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Iconsax.verify,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Page info
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      page.pageTitle,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.grey[900],
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Iconsax.heart,
                                          size: 12,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${page.pageLikes} likes',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => _navigateToPageById(
                                          page.pageId
                                    
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'visit_page_button'.tr,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build trending hashtags section
  Widget _buildTrendingSection(TrendingHashtagsWidget widget) {
    final isDarkMode = Get.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          widget.title,
          titleKey: 'trending_section_title',
          subtitleKey: 'trending_section_subtitle',
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: widget.hashtags.asMap().entries.map((entry) {
              final index = entry.key;
              final hashtag = entry.value;
              final isLast = index == widget.hashtags.length - 1;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Navigate to the hashtag page
                    Get.toNamed(
                      '/hashtag',
                      arguments: {'hashtag': hashtag.hashtag},
                    );
                  },
                  borderRadius: BorderRadius.circular(
                    isLast && index == 0 ? 20 : 0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Trending rank
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getTrendingColor(index),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${hashtag.hashtag}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.grey[900],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${hashtag.postsCount} posts',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Trending indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.arrow_up_2,
                                color: Colors.green,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'trending_badge_label'.tr,
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getTrendingColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey[600]!;
      case 2:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  /// Build suggested friends section
  Widget _buildSuggestedFriendsSection(SuggestedFriendsWidget widget) {
    final isDarkMode = Get.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          widget.title,
          titleKey: 'suggested_friends_section_title',
          subtitleKey: 'people_you_may_know_subtitle',
        ),
        const SizedBox(height: 12),
        SizedBox(
              height: Get.height *0.31,

          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.people.length,
            itemBuilder: (context, index) {
              final person = widget.people[index];
              return GestureDetector(
                onTap: () =>
                    _navigateToUserProfile(person.userId, person.username),
                child: Container(
                  width: 170,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile section
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade300,
                                        Colors.purple.shade300,
                                      ],
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 35,
                                    backgroundImage: person.picture != null
                                        ? CachedNetworkImageProvider(
                                            _buildImageUrl(person.picture!),
                                          )
                                        : null,
                                    backgroundColor: Colors.blue.withValues(alpha:
                                      0.1,
                                    ),
                                    child: person.picture == null
                                        ? Text(
                                            person.fullName.isNotEmpty
                                                ? person.fullName[0]
                                                : 'U',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                if (person.verified)
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDarkMode
                                              ? const Color(0xFF1A1A1A)
                                              : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Iconsax.verify,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              person.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.grey[900],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${person.username}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (person.mutualFriendsCount > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${person.mutualFriendsCount} mutual',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Add friend logic
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:  Text(
                                  'add_friend_button'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build suggested pages section
  Widget _buildSuggestedPagesSection(SuggestedPagesWidget widget) {
    final isDarkMode = Get.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          widget.title,
          titleKey: 'suggested_pages_section_title',
          subtitleKey: 'pages_to_discover_subtitle',
        ),
        const SizedBox(height: 12),
        SizedBox(
        height: Get.height *0.26,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.pages.length,
            itemBuilder: (context, index) {
              final page = widget.pages[index];
              return GestureDetector(
                onTap: () => _navigateToPageById(page.pageId, page.pageName),
                child: Container(
                  width: 170,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: page.pagePicture != null
                                        ? CachedNetworkImageProvider(
                                            _buildImageUrl(page.pagePicture!),
                                          )
                                        : null,
                                    backgroundColor: Colors.indigo.withValues(alpha:
                                      0.1,
                                    ),
                                    child: page.pagePicture == null
                                        ? Icon(
                                            Iconsax.building,
                                            color: Colors.indigo,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                  if (page.pageVerified)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDarkMode
                                                ? const Color(0xFF1A1A1A)
                                                : Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Iconsax.verify,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                page.pageTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.grey[900],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (page.category != null)
                                Text(
                                  page.category!.categoryName,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.heart,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${page.pageLikes}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                _navigateToPageById(page.pageId, page.pageName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'like_page_button'.tr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build suggested groups section
  Widget _buildSuggestedGroupsSection(SuggestedGroupsWidget widget) {
    final isDarkMode = Get.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          widget.title,
          titleKey: 'suggested_groups_section_title',
          subtitleKey: 'groups_to_join_subtitle',
        ),
        const SizedBox(height: 12),
        SizedBox(
        height: Get.height *0.3,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.groups.length,
            itemBuilder: (context, index) {
              final group = widget.groups[index];
              return GestureDetector(
                onTap: () =>
                    _navigateToGroup(group.groupId.toString(), group.groupName),
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Group Cover Image
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.withValues(alpha: 0.8),
                              Colors.purple.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Iconsax.people,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                      // Group Avatar overlapping cover
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: isDarkMode
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage: group.groupPicture != null
                                ? CachedNetworkImageProvider(
                                    _buildImageUrl(group.groupPicture!),
                                  )
                                : null,
                            backgroundColor: Colors.purple.withValues(alpha: 0.1),
                            child: group.groupPicture == null
                                ? Icon(
                                    Iconsax.people,
                                    color: Colors.purple,
                                    size: 20,
                                  )
                                : null,
                          ),
                        ),
                      ),

                      // Group Info
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: Column(
                          children: [
                            Text(
                              group.groupTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.grey[900],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),

                            // Privacy indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: group.groupPrivacy == 1
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                group.groupPrivacy == 1 ? 'privacy_public'.tr : 'privacy_private'.tr,
                                style: TextStyle(
                                  color: group.groupPrivacy == 1
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Members count
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.profile_2user,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'group_members_label'.trArgs([group.groupMembers.toString()]),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Join button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _navigateToGroup(
                                  group.groupId.toString(),
                                  group.groupName,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  group.groupPrivacy == 1
                                      ? 'join_group_button'.tr
                                      : 'request_to_join_button'.tr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build suggested events section
  Widget _buildSuggestedEventsSection(SuggestedEventsWidget widget) {
    final isDarkMode = Get.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          widget.title,
          titleKey: 'suggested_events_section_title',
          subtitleKey: 'events_to_attend_subtitle',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: Get.height *0.28,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.events.length,
            itemBuilder: (context, index) {
              final event = widget.events[index];
              return GestureDetector(
                onTap: () => _navigateToEvent(
                  event.eventId.toString(),
                  event.eventTitle,
                ),
                child: Container(
                  width: 190,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Event Cover Image
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyan.withValues(alpha: 0.8),
                              Colors.blue.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Iconsax.calendar_1,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),

                      // Event Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Event Date
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.cyan.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Iconsax.calendar,
                                    size: 14,
                                    color: Colors.cyan[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.eventStartDate.split(
                                      ' ',
                                    )[0], // Date only
                                    style: TextStyle(
                                      color: Colors.cyan[700],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Event Title
                            Text(
                              event.eventTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.grey[900],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 6),

                            // Event Location
                            if (event.eventLocation != null &&
                                event.eventLocation!.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.location,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.eventLocation!,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 10),

                            // Going count and button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${event.eventGoing} going',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.cyan,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child:  Text(
                                 'interested_button'.tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, {String? subtitleKey, String? titleKey}) {
    final isDarkMode = Get.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleKey != null ? titleKey.tr : title,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.grey[900],
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitleKey != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitleKey.tr,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
