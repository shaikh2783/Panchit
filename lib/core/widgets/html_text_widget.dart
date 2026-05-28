import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/features/profile/presentation/pages/profile_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Common widget for displaying HTML text
/// Supports mentions (@), links, and formatting
/// Supports limited text display with "Show more" option
class HtmlTextWidget extends StatefulWidget {
  const HtmlTextWidget({
    super.key,
    required this.htmlContent,
    this.maxLength = 300,
    this.fontSize = 15.0,
    this.lineHeight = 1.45,
    this.textColor,
    this.linkColor,
    this.onMentionTap,
    this.showMoreText = 'Show more',
    this.showLessText = 'Hide',
    this.textAlign = TextAlign.start, // إضافة دعم للمحاذاة
    this.fontWeight,
    this.maxLines,
    this.overflow,
  });

  /// HTML content to display
  final String htmlContent;

  /// Maximum number of characters before showing "Show more" (default: 300)
  final int maxLength;

  /// Font size (default: 15)
  final double fontSize;

  /// Line height (default: 1.45)
  final double lineHeight;

  /// Text color (if null, will use theme color)
  final Color? textColor;

  /// Link color (if null, will use theme primary color)
  final Color? linkColor;

  /// Function called when a mention (@mention) is tapped
  final void Function(String username)? onMentionTap;

  /// "Show more" button text
  final String showMoreText;

  /// "Hide" button text
  final String showLessText;

  /// Text alignment (default: TextAlign.start)
  final TextAlign textAlign;

  /// Optional font weight for the rendered text
  final FontWeight? fontWeight;

  /// Optional max lines for the rendered HTML
  final int? maxLines;

  /// Optional overflow behavior when maxLines is set
  final TextOverflow? overflow;

  @override
  State<HtmlTextWidget> createState() => _HtmlTextWidgetState();
}

class _HtmlTextWidgetState extends State<HtmlTextWidget> {
  bool _isExpanded = false;

  /// Extract plain text from HTML
  String _getPlainText(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextColor =
        widget.textColor ?? theme.colorScheme.onSurface.withOpacity(0.85);
    final effectiveLinkColor = widget.linkColor ?? theme.colorScheme.primary;

    // Extract plain text to check length
    final plainText = _getPlainText(widget.htmlContent);
    final isLongText = plainText.length > widget.maxLength;
    final effectiveMaxLines =
        widget.maxLines ?? (isLongText && !_isExpanded ? 10 : null);
    final effectiveOverflow = widget.overflow ??
        ((widget.maxLines != null || (isLongText && !_isExpanded))
            ? TextOverflow.ellipsis
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Html(
          data: widget.htmlContent,
          style: {
            "body": Style(
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
              fontSize: FontSize(widget.fontSize),
              lineHeight: LineHeight(widget.lineHeight),
              fontWeight: widget.fontWeight,
              color: effectiveTextColor,
              textAlign: widget.textAlign, // استخدام محاذاة النص المخصصة
              maxLines: effectiveMaxLines,
              textOverflow: effectiveOverflow,
            ),
            "a": Style(
              color: effectiveLinkColor,
              textDecoration: TextDecoration.none,
              fontWeight: FontWeight.w500,
            ),
            "span": Style(
              color: effectiveLinkColor,
              fontWeight: FontWeight.w500,
            ),
            "span.js_user-popover": Style(
              color: effectiveLinkColor,
              fontWeight: FontWeight.w500,
            ),
            "p": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
            "div": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
          },
          onLinkTap: (url, attributes, element) {
            if (url == null) return;
            //flutter: 🔗 Link tapped: https://sngine.fluttercrafters.com/search/hashtag/ameen
            final appConfig = context.read<AppConfig>();
            // Extract username from the link
            final uri = Uri.tryParse(url);
            if (uri != null && uri.pathSegments.isNotEmpty) {
              final username = uri.pathSegments.last;

              // التحقق من وجود data-uid في الـ attributes (يعني أنها mention)
              final dataUid = attributes['data-uid'];
              if (dataUid != null) {
                if (widget.onMentionTap != null) {
                  widget.onMentionTap!(username);
                }
                return;
              }
            }

            // التحقق من نوع الرابط
            if (url.startsWith(appConfig.baseUrl)) {
              String username = url
                  .replaceFirst(appConfig.baseUrl, '')
                  .replaceAll('/', '');
              
              if (username.startsWith('searchhashta')) {
                //go to hashtag page
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(username: username),
                  ),
                );
              }
            } else {
              //go to external link
              launchUrl(Uri.parse(url));
            }
          },
        ),

        // زر "إظهار المزيد" / "إخفاء"
        if (isLongText)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Text(
                _isExpanded ? widget.showLessText : widget.showMoreText,
                style: TextStyle(
                  color: effectiveLinkColor,
                  fontWeight: FontWeight.w600,
                  fontSize: widget.fontSize - 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
