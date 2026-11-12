import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/messenger_design.dart';

class MessengerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MessengerAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showDivider;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 58 : 64);

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return AppBar(
      leading: leading,
      centerTitle: centerTitle,
      titleSpacing: leading == null ? MessengerDesign.pagePadding : 0,
      shape: showDivider
          ? Border(bottom: BorderSide(color: palette.divider, width: 0.7))
          : const Border(),
      title: subtitle == null
          ? Text(title)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
      actions: actions,
    );
  }
}

class MessengerPageTitle extends StatelessWidget {
  const MessengerPageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(16, 18, 16, 14),
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: palette.muted),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );
  }
}

class MessengerSearchField extends StatelessWidget {
  const MessengerSearchField({
    super.key,
    this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final hasText = controller?.text.isNotEmpty ?? false;
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          fillColor: palette.field,
          prefixIcon: const Icon(Icons.search_rounded, size: 21),
          suffixIcon: hasText && onClear != null
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.cancel_rounded, size: 18),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class MessengerSection extends StatelessWidget {
  const MessengerSection({
    super.key,
    this.title,
    this.caption,
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.padding = EdgeInsets.zero,
  });

  final String? title;
  final String? caption;
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final titleText = title?.trim() ?? '';
    final captionText = caption?.trim() ?? '';

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titleText.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                titleText,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          Container(
            clipBehavior: Clip.antiAlias,
            padding: padding,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(
                MessengerDesign.sectionRadius,
              ),
              border: Border.all(color: palette.divider, width: 0.7),
            ),
            child: child,
          ),
          if (captionText.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                captionText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MessengerRow extends StatelessWidget {
  const MessengerRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = false,
    this.destructive = false,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final effectiveColor = destructive
        ? MessengerDesign.destructive
        : palette.text;
    final resolvedLeading =
        leading ??
        (icon == null
            ? null
            : Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: destructive
                      ? MessengerDesign.destructive.withValues(alpha: 0.10)
                      : palette.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 19,
                  color: destructive
                      ? MessengerDesign.destructive
                      : MessengerDesign.primary,
                ),
              ));

    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 14),
            child: Row(
              children: [
                if (resolvedLeading != null) ...[
                  resolvedLeading,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 58),
                    padding: const EdgeInsetsDirectional.only(
                      top: 10,
                      bottom: 10,
                      end: 12,
                    ),
                    decoration: showDivider
                        ? BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: palette.divider,
                                width: 0.7,
                              ),
                            ),
                          )
                        : null,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: effectiveColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              if (subtitle != null &&
                                  subtitle!.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: palette.muted),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        trailing ??
                            (onTap == null
                                ? const SizedBox.shrink()
                                : Icon(
                                    Icons.chevron_right_rounded,
                                    size: 22,
                                    color: palette.subtle,
                                  )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MessengerEmptyState extends StatelessWidget {
  const MessengerEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: MessengerDesign.primary, size: 29),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.muted,
                  height: 1.45,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MessengerAvatar extends StatelessWidget {
  const MessengerAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 24,
    this.online = false,
    this.heroTag,
  });

  final String name;
  final String? imageUrl;
  final double radius;
  final bool online;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    final normalizedUrl = imageUrl?.trim() ?? '';
    final initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part.characters.first.toUpperCase())
              .join();

    Widget avatar = Container(
      width: radius * 2,
      height: radius * 2,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.primarySoft,
        shape: BoxShape.circle,
        border: Border.all(color: palette.divider, width: 0.7),
      ),
      child: normalizedUrl.isEmpty
          ? Center(
              child: Text(
                initials,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: MessengerDesign.primary,
                  fontSize: radius * 0.58,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: normalizedUrl,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 160),
              placeholder: (_, _) => ColoredBox(color: palette.softSurface),
              errorWidget: (_, _, _) => Center(
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MessengerDesign.primary,
                    fontSize: radius * 0.58,
                  ),
                ),
              ),
            ),
    );

    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: avatar);
    }

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (online)
            PositionedDirectional(
              end: -1,
              bottom: -1,
              child: Container(
                width: radius * 0.48,
                height: radius * 0.48,
                decoration: BoxDecoration(
                  color: MessengerDesign.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MessengerSheetHeader extends StatelessWidget {
  const MessengerSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = MessengerDesign.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
