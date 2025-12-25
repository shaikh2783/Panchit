import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/friendship_model.dart';
import '../../data/services/friends_api_service.dart';

/// Widget زر إضافة الصديق القابل لإعادة الاستخدام
class AddFriendButton extends StatefulWidget {
  const AddFriendButton({
    super.key,
    required this.userId,
    required this.initialStatus,
    this.size = AddFriendButtonSize.medium,
    this.style = AddFriendButtonStyle.filled,
    this.onStatusChanged,
    this.friendsApiService,
    this.showText = true,
    this.customText,
  });

  /// معرف المستخدم المراد إضافته كصديق
  final int userId;
  
  /// حالة الصداقة الأولية
  final FriendshipStatus initialStatus;
  
  /// حجم الزر
  final AddFriendButtonSize size;
  
  /// نمط الزر
  final AddFriendButtonStyle style;
  
  /// callback عند تغيير حالة الصداقة
  final void Function(FriendshipStatus newStatus)? onStatusChanged;
  
  /// خدمة API (اختيارية - ستستخدم خدمة افتراضية إذا لم تُمرر)
  final FriendsApiService? friendsApiService;
  
  /// إظهار النص مع الأيقونة
  final bool showText;
  
  /// نص مخصص بدلاً من النص الافتراضي
  final String? customText;

  @override
  State<AddFriendButton> createState() => _AddFriendButtonState();
}

class _AddFriendButtonState extends State<AddFriendButton> {
  FriendshipStatus _currentStatus = FriendshipStatus.none;
  bool _isLoading = false;
  late FriendsApiService _apiService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // إنشاء الخدمة باستخدام ApiClient من Provider
    if (widget.friendsApiService != null) {
      _apiService = widget.friendsApiService!;
    } else {
      final apiClient = context.read<ApiClient>();
      _apiService = FriendsApiService(apiClient);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
  }

  @override
  void didUpdateWidget(AddFriendButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatus != widget.initialStatus) {
      _currentStatus = widget.initialStatus;
    }
  }

  Future<void> _handleAction() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      FriendActionResult result;
      
      switch (_currentStatus) {
        case FriendshipStatus.none:
          result = await _apiService.sendFriendRequest(widget.userId);
          break;
        case FriendshipStatus.pending:
          result = await _apiService.cancelFriendRequest(widget.userId);
          break;
        case FriendshipStatus.requested:
          // في هذه الحالة نحتاج لإظهار dialog للقبول أو الرفض
          result = await _showAcceptDeclineDialog();
          break;
        case FriendshipStatus.friends:
          result = await _showRemoveFriendDialog();
          break;
        case FriendshipStatus.following:
          result = await _apiService.unfollowUser(widget.userId);
          break;
        case FriendshipStatus.blocked:
          // لا نعرض زر للمحظورين
          return;
      }

      if (result.success) {
        setState(() => _currentStatus = result.newStatus);
        widget.onStatusChanged?.call(result.newStatus);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<FriendActionResult> _showAcceptDeclineDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('friend_request_title'.tr),
        content: Text('accept_or_decline'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'decline'),
            child: Text('decline_button'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'accept'),
            child: Text('accept_button'.tr),
          ),
        ],
      ),
    );

    if (result == 'accept') {
      return await _apiService.acceptFriendRequest(widget.userId);
    } else if (result == 'decline') {
      return await _apiService.declineFriendRequest(widget.userId);
    } else {
      return FriendActionResult.error('Action cancelled', _currentStatus);
    }
  }

  Future<FriendActionResult> _showRemoveFriendDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('remove_friend_title'.tr),
        content: Text('are_you_sure_remove'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('remove_button'.tr),
          ),
        ],
      ),
    );

    if (result == true) {
      return await _apiService.removeFriend(widget.userId);
    } else {
      return FriendActionResult.error('Action cancelled', _currentStatus);
    }
  }

  ButtonConfig _getButtonConfig() {
    switch (_currentStatus) {
      case FriendshipStatus.none:
        return ButtonConfig(
          text: widget.customText ?? 'Add Friend',
          textAr: 'إضافة صديق',
          icon: Iconsax.user_add,
          color: AppColors.primary,
          backgroundColor: Colors.transparent,
          borderColor: AppColors.primary,
        );
      case FriendshipStatus.pending:
        return ButtonConfig(
          text: widget.customText ?? 'Cancel Request',
          textAr: 'إلغاء الطلب',
          icon: Iconsax.user_minus,
          color: Colors.orange,
          backgroundColor: Colors.transparent,
          borderColor: Colors.orange,
        );
      case FriendshipStatus.requested:
        return ButtonConfig(
          text: widget.customText ?? 'Respond',
          textAr: 'الرد',
          icon: Iconsax.user_tick,
          color: Colors.green,
          backgroundColor: Colors.green.withOpacity(0.1),
          borderColor: Colors.green,
        );
      case FriendshipStatus.friends:
        return ButtonConfig(
          text: widget.customText ?? 'Friends',
          textAr: 'أصدقاء',
          icon: Iconsax.user_tick,
          color: Colors.green,
          backgroundColor: Colors.green.withOpacity(0.1),
          borderColor: Colors.green,
        );
      case FriendshipStatus.following:
        return ButtonConfig(
          text: widget.customText ?? 'Following',
          textAr: 'متابع',
          icon: Iconsax.user_minus,
          color: AppColors.primary,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          borderColor: AppColors.primary,
        );
      case FriendshipStatus.blocked:
        return ButtonConfig(
          text: widget.customText ?? 'Blocked',
          textAr: 'محظور',
          icon: Iconsax.user_remove,
          color: Colors.red,
          backgroundColor: Colors.transparent,
          borderColor: Colors.red,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // لا نعرض زر للمحظورين
    if (_currentStatus == FriendshipStatus.blocked) {
      return const SizedBox.shrink();
    }

    final config = _getButtonConfig();
    final buttonSize = _getButtonSize();
    
    Widget buttonChild;
    
    if (_isLoading) {
      buttonChild = SizedBox(
        width: buttonSize.iconSize,
        height: buttonSize.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(config.color),
        ),
      );
    } else {
      if (widget.showText) {
        buttonChild = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: buttonSize.iconSize, color: config.color),
            SizedBox(width: buttonSize.spacing),
            Flexible(
              child: Text(
                config.text,
                style: TextStyle(
                  color: config.color,
                  fontSize: buttonSize.fontSize,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        );
      } else {
        buttonChild = Icon(
          config.icon,
          size: buttonSize.iconSize,
          color: config.color,
        );
      }
    }

    switch (widget.style) {
      case AddFriendButtonStyle.filled:
        return FilledButton(
          onPressed: _isLoading ? null : _handleAction,
          style: FilledButton.styleFrom(
            backgroundColor: config.backgroundColor,
            foregroundColor: config.color,
            padding: EdgeInsets.symmetric(
              horizontal: buttonSize.paddingH,
              vertical: buttonSize.paddingV,
            ),
            minimumSize: Size(buttonSize.minWidth, buttonSize.minHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonSize.borderRadius),
              side: BorderSide(color: config.borderColor),
            ),
          ),
          child: buttonChild,
        );

      case AddFriendButtonStyle.outlined:
        return OutlinedButton(
          onPressed: _isLoading ? null : _handleAction,
          style: OutlinedButton.styleFrom(
            foregroundColor: config.color,
            side: BorderSide(color: config.borderColor),
            padding: EdgeInsets.symmetric(
              horizontal: buttonSize.paddingH,
              vertical: buttonSize.paddingV,
            ),
            minimumSize: Size(buttonSize.minWidth, buttonSize.minHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonSize.borderRadius),
            ),
          ),
          child: buttonChild,
        );

      case AddFriendButtonStyle.text:
        return TextButton(
          onPressed: _isLoading ? null : _handleAction,
          style: TextButton.styleFrom(
            foregroundColor: config.color,
            padding: EdgeInsets.symmetric(
              horizontal: buttonSize.paddingH,
              vertical: buttonSize.paddingV,
            ),
            minimumSize: Size(buttonSize.minWidth, buttonSize.minHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonSize.borderRadius),
            ),
          ),
          child: buttonChild,
        );

      case AddFriendButtonStyle.iconOnly:
        return IconButton(
          onPressed: _isLoading ? null : _handleAction,
          icon: buttonChild,
          style: IconButton.styleFrom(
            backgroundColor: config.backgroundColor,
            foregroundColor: config.color,
            side: BorderSide(color: config.borderColor),
            minimumSize: Size(buttonSize.minHeight, buttonSize.minHeight),
          ),
        );
    }
  }

  ButtonSize _getButtonSize() {
    switch (widget.size) {
      case AddFriendButtonSize.small:
        return const ButtonSize(
          iconSize: 16,
          fontSize: 12,
          paddingH: 12,
          paddingV: 6,
          minWidth: 80,
          minHeight: 32,
          borderRadius: 6,
          spacing: 4,
        );
      case AddFriendButtonSize.medium:
        return const ButtonSize(
          iconSize: 18,
          fontSize: 14,
          paddingH: 16,
          paddingV: 8,
          minWidth: 100,
          minHeight: 36,
          borderRadius: 8,
          spacing: 6,
        );
      case AddFriendButtonSize.large:
        return const ButtonSize(
          iconSize: 20,
          fontSize: 16,
          paddingH: 20,
          paddingV: 12,
          minWidth: 120,
          minHeight: 44,
          borderRadius: 10,
          spacing: 8,
        );
    }
  }
}

// تكوين الزر
class ButtonConfig {
  final String text;
  final String textAr;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;

  const ButtonConfig({
    required this.text,
    required this.textAr,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
  });
}

// أحجام الزر
class ButtonSize {
  final double iconSize;
  final double fontSize;
  final double paddingH;
  final double paddingV;
  final double minWidth;
  final double minHeight;
  final double borderRadius;
  final double spacing;

  const ButtonSize({
    required this.iconSize,
    required this.fontSize,
    required this.paddingH,
    required this.paddingV,
    required this.minWidth,
    required this.minHeight,
    required this.borderRadius,
    required this.spacing,
  });
}

// أحجام الزر المتاحة
enum AddFriendButtonSize { small, medium, large }

// أنماط الزر المتاحة
enum AddFriendButtonStyle { filled, outlined, text, iconOnly }