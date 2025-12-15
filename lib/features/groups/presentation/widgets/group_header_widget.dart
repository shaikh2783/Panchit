import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import '../../data/models/group.dart';
/// Exclusive header design for basic group information
class GroupHeaderWidget extends StatelessWidget {
  final Group group;
  final String mediaAsset;
  final bool isCollapsed;
  final VoidCallback? onJoinPressed;
  final VoidCallback? onLeavePressed;
  final VoidCallback? onMessagePressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onMorePressed;
  const GroupHeaderWidget({
    super.key,
    required this.group,
    required this.mediaAsset,
    this.isCollapsed = false,
    this.onJoinPressed,
    this.onLeavePressed,
    this.onMessagePressed,
    this.onSharePressed,
    this.onMorePressed,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        // Cover background
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: group.groupCoverFull?.isNotEmpty == true
              ? CachedNetworkImage(
                  imageUrl: group.groupCoverFull!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Iconsax.image,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                )
              : group.groupCover?.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: '$mediaAsset${group.groupCover}',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Iconsax.image,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Iconsax.people,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
        ),
        // Header content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: isCollapsed ? _buildCollapsedHeader() : _buildExpandedHeader(theme),
          ),
        ),
        // Navigation buttons
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  icon: const Icon(
                    Iconsax.arrow_left_2,
                    color: Colors.white,
                  ),
                  onPressed: () => Get.back(),
                ),
              ),
              // Action buttons
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Iconsax.share,
                        color: Colors.white,
                      ),
                      onPressed: onSharePressed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Iconsax.more,
                        color: Colors.white,
                      ),
                      onPressed: onMorePressed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildExpandedHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group image and basic information
        Row(
          children: [
            // Group image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: group.groupPictureFull?.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: group.groupPictureFull!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          child: const Icon(
                            Iconsax.people,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        errorWidget: (context, url, error) => group.groupPicture?.isNotEmpty == true
                            ? CachedNetworkImage(
                                imageUrl: '$mediaAsset${group.groupPicture}',
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  color: theme.colorScheme.primary,
                                  child: const Icon(
                                    Iconsax.people,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              )
                            : Container(
                                color: theme.colorScheme.primary,
                                child: const Icon(
                                  Iconsax.people,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Iconsax.people,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Group information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group name
                  Text(
                    group.groupTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 3,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Additional information
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                        _buildInfoChip(
                          icon: Iconsax.people,
                          text: '${group.groupMembers} member',
                        ),
                        _buildInfoChip(
                          icon: group.groupPrivacy == GroupPrivacy.public 
                              ? Iconsax.global 
                              : group.groupPrivacy == GroupPrivacy.closed
                                  ? Iconsax.lock_1
                                  : Iconsax.eye_slash,
                          text: group.privacyDisplayText,
                        ),
                        if (group.category.name.isNotEmpty)
                          _buildInfoChip(
                            icon: Iconsax.category,
                            text: group.category.name,
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Action buttons
   if(false)     Row(
          children: [
            // Join/Leave button
            Expanded(
              flex: 2,
              child: _buildActionButton(
                text: group.isCurrentUserMember ? 'Leave Group' : 'Join Group',
                icon: group.isCurrentUserMember ? Iconsax.logout : Iconsax.login,
                isPrimary: !group.isCurrentUserMember,
                onPressed: group.isCurrentUserMember ? onLeavePressed : onJoinPressed,
              ),
            ),
            const SizedBox(width: 12),
            // Message button (if member)
            if (group.isCurrentUserMember) ...[
              Expanded(
                child: _buildActionButton(
                  text: 'Message',
                  icon: Iconsax.message,
                  isPrimary: false,
                  onPressed: onMessagePressed,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
  Widget _buildCollapsedHeader() {
    return Row(
      children: [
        // Small image
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: group.groupPictureFull?.isNotEmpty == true
                ? CachedNetworkImage(
                    imageUrl: group.groupPictureFull!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => group.groupPicture?.isNotEmpty == true
                        ? CachedNetworkImage(
                            imageUrl: '$mediaAsset${group.groupPicture}',
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: Colors.blue,
                              child: const Icon(
                                Iconsax.people,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.blue,
                            child: const Icon(
                              Iconsax.people,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                  )
                : group.groupPicture?.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: '$mediaAsset${group.groupPicture}',
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.blue,
                          child: const Icon(
                            Iconsax.people,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.blue,
                        child: const Icon(
                          Iconsax.people,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
          ),
        ),
        const SizedBox(width: 12),
        // Group name
        Expanded(
          child: Text(
            group.groupTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Quick button
        IconButton(
          icon: Icon(
            group.isCurrentUserMember ? Iconsax.logout : Iconsax.login,
            color: Colors.white,
          ),
          onPressed: group.isCurrentUserMember ? onLeavePressed : onJoinPressed,
        ),
      ],
    );
  }
  Widget _buildInfoChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              )
            : null,
        color: isPrimary ? null : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}