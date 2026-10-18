import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../discover/data/services/homepage_widgets_api_service.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../data/services/friends_api_service.dart';

/// Full screen listing all suggested friends, opened via "View All"
/// from the suggested friends rail on the home feed.
class SuggestedFriendsPage extends StatefulWidget {
  const SuggestedFriendsPage({
    super.key,
    required this.people,
    required this.mediaResolver,
    this.initiallyAdded = const {},
  });

  final List<SuggestedFriend> people;
  final Uri Function(String) mediaResolver;
  final Set<int> initiallyAdded;

  @override
  State<SuggestedFriendsPage> createState() => _SuggestedFriendsPageState();
}

class _SuggestedFriendsPageState extends State<SuggestedFriendsPage> {
  final Set<int> _pending = {};
  late final Set<int> _added = {...widget.initiallyAdded};

  void _checkIfAdded(int userId) {
    if (!_added.contains(userId)) {
      setState(() => _added.add(userId));
    }
  }

  Future<void> _sendFriendRequest(SuggestedFriend person) async {
    if (_pending.contains(person.userId) || _added.contains(person.userId)) {
      return;
    }
    setState(() => _pending.add(person.userId));

    try {
      final api = FriendsApiService(context.read<ApiClient>());
      final result = await api.sendFriendRequest(person.userId);

      if (!mounted) return;

      if (result.success) {
        setState(() => _added.add(person.userId));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: result.success
              ? Colors.green
              : Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('failed_to_send_request'.tr),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _pending.remove(person.userId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredPeople =
        widget.people.where((p) => !_added.contains(p.userId)).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_added);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('suggested_friends_section_title'.tr),
        ),
        body: filteredPeople.isEmpty
            ? Center(
                child: Text(
                  'no_more_suggestions'.tr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: filteredPeople.length,
                itemBuilder: (context, index) {
                  final person = filteredPeople[index];
                  final picture = person.picture;
                  final avatarUrl = picture != null && picture.isNotEmpty
                      ? widget.mediaResolver(picture).toString()
                      : null;

                  final isPending = _pending.contains(person.userId);
                  final isAdded = _added.contains(person.userId);

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProfilePage(username: person.username),
                              ),
                            );
                            if (mounted && result == true) {
                              _checkIfAdded(person.userId);
                            }
                          },
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 34,
                                backgroundImage: avatarUrl != null
                                    ? CachedNetworkImageProvider(avatarUrl)
                                    : null,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.12),
                                child: avatarUrl == null
                                    ? Text(
                                        person.fullName.isNotEmpty
                                            ? person.fullName[0].toUpperCase()
                                            : 'U',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                              ),
                              if (person.verified)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.cardDark
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
                        ),
                        const SizedBox(height: 10),
                        Text(
                          person.fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${person.username}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                        if (person.mutualFriendsCount > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${person.mutualFriendsCount} mutual',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (isPending || isAdded)
                                ? null
                                : () => _sendFriendRequest(person),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAdded
                                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                                  : Theme.of(context).colorScheme.primary,
                              foregroundColor: isAdded
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.65)
                                  : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isPending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isAdded
                                        ? 'friends'.tr
                                        : 'add_friend_button'.tr,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
