/// HTML Decoder Utility
/// 
/// Decodes common HTML entities to their text representation
/// Useful for text coming from APIs that may contain HTML entities
class HtmlDecoder {
  /// Decode HTML entities in text (e.g., &amp; → &, &lt; → <, etc.)
  static String decode(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', '/')
        .replaceAll('&#x3D;', '=')
        .replaceAll(RegExp(r'<[^>]*>'), ''); // Remove HTML tags
  }
}
