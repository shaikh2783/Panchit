import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:snginepro/App_Settings.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:fwfh_webview/fwfh_webview.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// عارض الفيديوهات المضمنة (YouTube, TikTok, Vimeo, إلخ)
class EmbeddedVideoPlayer extends StatefulWidget {
  final String sourceUrl; // رابط الفيديو الأصلي
  final String? sourceProvider; // YouTube, TikTok, Vimeo, إلخ
  final String? sourceTitle;
  final String? sourceThumbnail;
  final String? sourceHtml; // HTML مدمج من OEmbed (اختياري)

  const EmbeddedVideoPlayer({
    super.key,
    required this.sourceUrl,
    this.sourceProvider,
    this.sourceTitle,
    this.sourceThumbnail,
    this.sourceHtml,
  });

  @override
  State<EmbeddedVideoPlayer> createState() => _EmbeddedVideoPlayerState();
}

class _EmbeddedVideoPlayerState extends State<EmbeddedVideoPlayer> {
  YoutubePlayerController? _youtubeController;
  WebViewController? _webViewController;
  WebViewController? _vimeoWebViewController;
  String? _error;
  int _retryCount = 0;
  final int _maxRetries = 3;
  bool _isYouTube = false;
  bool _isTikTok = false;
  bool _isVimeo = false;
  bool _useHtmlWidget = false;

  @override
  void initState() {
    super.initState();

    final provider = (widget.sourceProvider ?? '').toLowerCase();
    _isYouTube =
        provider.contains('youtube') || widget.sourceUrl.contains('youtube');
    _isTikTok =
        provider.contains('tiktok') || widget.sourceUrl.contains('tiktok');
    _isVimeo = provider.contains('vimeo') || widget.sourceUrl.contains('vimeo');

    if (_isYouTube) {
      // استخدام youtube_player_flutter مباشرة
      if (AppSettings.playYouTubeInApp) {
        final videoId = _getYouTubeEmbedUrl();
        if (videoId != null && videoId.length >= 5) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              enableCaption: false,
              loop: false,
              showLiveFullscreenButton: true,
            ),
          );
        }
      }
    } else if (_isTikTok) {
      // استخدام WebView لـ TikTok
      if (AppSettings.playTikTokInApp) {
        _initializeTikTokWebView();
      }
    } else if (_isVimeo) {
      // استخدام WebView لـ Vimeo
      if (AppSettings.playVimeoInApp) {
        _initializeVimeoWebView();
      }
    } else if (widget.sourceHtml != null && widget.sourceHtml!.isNotEmpty) {
      // استخدام HTML Widget للفيديوهات الأخرى
      _useHtmlWidget = true;
    } else {
      setState(() => _error = 'لا يمكن تشغيل هذا الفيديو');
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  void _initializeTikTokWebView() {
    // استخراج معرف الفيديو من الرابط أو HTML
    String? videoId;

    if (widget.sourceUrl.contains('/video/')) {
      videoId = widget.sourceUrl.split('/video/').last.split('?').first;
    } else if (widget.sourceHtml != null &&
        widget.sourceHtml!.contains('data-video-id')) {
      final match = RegExp(
        r'data-video-id="(\d+)"',
      ).firstMatch(widget.sourceHtml!);
      if (match != null) {
        videoId = match.group(1);
      }
    }

    if (videoId == null || videoId.isEmpty) {
      setState(() => _error = 'لا يمكن استخراج معرف فيديو TikTok');
      return;
    }


    // إنشاء HTML مع TikTok embed iframe
    final htmlContent =
        '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        html, body {
          height: 100%;
          width: 100%;
          background-color: #000;
          overflow: hidden;
        }
        iframe {
          border: none;
          width: 100%;
          height: 100%;
        }
      </style>
    </head>
    <body>
      <iframe src="https://www.tiktok.com/embed/v2/$videoId" 
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              allowfullscreen>
      </iframe>
    </body>
    </html>
    ''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..loadHtmlString(htmlContent);
  }

  String? _getYouTubeEmbedUrl() {
    try {
      var videoId = '';
      final url = widget.sourceUrl;


      // صيغة: https://youtu.be/VIDEO_ID
      if (url.contains('youtu.be/')) {
        videoId = url.split('youtu.be/').last.split('?').first.split('&').first;
      }
      // صيغة: https://www.youtube.com/watch?v=VIDEO_ID
      else if (url.contains('youtube.com/watch')) {
        if (url.contains('v=')) {
          videoId = url.split('v=').last.split('&').first;
        }
      }
      // صيغة: https://www.youtube.com/embed/VIDEO_ID
      else if (url.contains('youtube.com/embed/')) {
        videoId = url.split('embed/').last.split('?').first;
      }
      // صيغة: https://www.youtube.com/v/VIDEO_ID
      else if (url.contains('youtube.com/v/')) {
        videoId = url.split('v/').last.split('?').first;
      }
      // صيغة: https://youtu.be/VIDEO_ID (مختصرة)
      else if (url.contains('/vi/')) {
        videoId = url.split('/vi/').last.split('/').first;
      }

      // تنظيف معرف الفيديو
      videoId = videoId.trim();


      if (videoId.isEmpty) {
        return null;
      }

      // التحقق من صحة معرف الفيديو (11 حرف عادة)
      if (videoId.length < 5 || videoId.length > 15) {
        // محاولة استخراج من HTML كخيار احتياطي
        if (widget.sourceHtml != null) {
          return _extractYouTubeFromHtml(widget.sourceHtml!);
        }
        return null;
      }

      return videoId; // نرجع معرف الفيديو فقط للـ YouTube player
    } catch (e) {
      // محاولة استخراج من HTML كخيار احتياطي
      if (widget.sourceHtml != null) {
        return _extractYouTubeFromHtml(widget.sourceHtml!);
      }
      return null;
    }
  }

  String? _extractYouTubeFromHtml(String html) {
    try {
      // فك تشفير HTML entities أولاً
      var decodedHtml = html
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#039;', "'")
          .replaceAll('&amp;', '&');


      // البحث عن معرف الفيديو في src attribute
      final regex = RegExp(r'src="(https://www\.youtube\.com/embed/([^"?&]+))');
      final match = regex.firstMatch(decodedHtml);

      if (match != null && match.groupCount >= 2) {
        final videoId = match.group(2);
        return videoId;
      }

    } catch (e) {
    }
    return null;
  }

  Future<void> _openInExternalApp() async {
    final url = Uri.parse(widget.sourceUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح هذا الرابط')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // إذا كان YouTube
    if (_isYouTube) {
      if (_error != null) {
        // عرض خطأ مع زر فتح في YouTube
        return _buildYouTubeErrorWidget();
      } else if (_youtubeController != null && AppSettings.playYouTubeInApp) {
        return _buildYoutubePlayer();
      } else if (!AppSettings.playYouTubeInApp) {
        return _buildThumbnailButton();
      }
    }

    // إذا كان TikTok ولدينا WebView controller
    if (_isTikTok) {
      if (_error != null) {
        return _buildErrorWidget();
      } else if (_webViewController != null && AppSettings.playTikTokInApp) {
        return _buildTikTokWebView();
      } else if (!AppSettings.playTikTokInApp) {
        return _buildThumbnailButton();
      }
    }

    // إذا كان Vimeo ولدينا WebView controller
    if (_isVimeo) {
      if (_error != null) {
        return _buildErrorWidget();
      } else if (_vimeoWebViewController != null &&
          AppSettings.playVimeoInApp) {
        return _buildVimeoWebView();
      } else if (!AppSettings.playVimeoInApp) {
        return _buildThumbnailButton();
      }
    }

    // إذا كان لدينا HTML للعرض
    if (_useHtmlWidget && widget.sourceHtml != null) {
      return _buildHtmlWidget();
    }

    // للفيديوهات الأخرى
    if (_error != null) {
      return _buildErrorWidget();
    }

    // Loading state
    return _buildLoadingWidget();
  }

  Widget _buildLoadingWidget() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 250,
        color: Colors.grey[900],
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildYoutubePlayer() {
    if (_youtubeController == null) {
      return _buildLoadingWidget();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
      ),
    );
  }

  Widget _buildYouTubeErrorWidget() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة YouTube
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_circle_outline,
                size: 48,
                color: Color(0xFFFF0000),
              ),
            ),
            const SizedBox(height: 16),
            // رسالة الخطأ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error ?? 'لا يمكن تشغيل هذا الفيديو',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // زر فتح في YouTube
            ElevatedButton.icon(
              onPressed: _openInExternalApp,
              icon: const Icon(Icons.open_in_new),
              label: const Text('فتح في YouTube'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTikTokWebView() {
    if (_webViewController == null) {
      return _buildLoadingWidget();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 700, // TikTok عمودي
        color: Colors.black,
        child: Stack(
          children: [
            WebViewWidget(controller: _webViewController!),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _openInExternalApp,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.link,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHtmlWidget() {
    // فك تشفير HTML entities
    var decodedHtml = widget.sourceHtml!
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: (widget.sourceProvider ?? '').toLowerCase().contains('tiktok')
            ? 700
            : 400,
        color: Colors.black,
        child: Stack(
          children: [
            HtmlWidget(
              decodedHtml,
              factoryBuilder: () => _WidgetFactory(),
              onLoadingBuilder: (context, element, loadingProgress) {
                return Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _openInExternalApp,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.link,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _initializeVimeoWebView() {
    final vimeoId = _extractVimeoId(widget.sourceUrl);

    if (vimeoId == null || vimeoId.isEmpty) {
      setState(() => _error = 'لا يمكن استخراج معرف فيديو Vimeo');
      return;
    }


    // إنشاء HTML مع Vimeo embed iframe
    final htmlContent =
        '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        html, body {
          height: 100%;
          width: 100%;
          background-color: #000;
          overflow: hidden;
        }
        iframe {
          border: none;
          width: 100%;
          height: 100%;
        }
      </style>
    </head>
    <body>
      <iframe src="https://player.vimeo.com/video/$vimeoId?autoplay=0&muted=0" 
              allow="autoplay; fullscreen; picture-in-picture"
              allowfullscreen>
      </iframe>
    </body>
    </html>
    ''';

    _vimeoWebViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..loadHtmlString(htmlContent);
  }

  Widget _buildVimeoWebView() {
    if (_vimeoWebViewController == null) {
      return _buildLoadingWidget();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 250,
        color: Colors.black,
        child: Stack(
          children: [
            WebViewWidget(controller: _vimeoWebViewController!),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _openInExternalApp,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.link,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _extractVimeoId(String url) {
    try {

      // Extract Vimeo ID from various URL formats
      // https://vimeo.com/123456789
      // https://player.vimeo.com/video/123456789
      final patterns = [
        RegExp(r'vimeo\.com/(\d+)'),
        RegExp(r'player\.vimeo\.com/video/(\d+)'),
      ];

      for (var pattern in patterns) {
        final match = pattern.firstMatch(url);
        if (match != null && match.groupCount >= 1) {
          final vimeoId = match.group(1);
          return vimeoId;
        }
      }

      // محاولة استخراج من HTML كخيار احتياطي
      if (widget.sourceHtml != null) {
        return _extractVimeoFromHtml(widget.sourceHtml!);
      }

      return null;
    } catch (e) {
      // محاولة استخراج من HTML كخيار احتياطي
      if (widget.sourceHtml != null) {
        return _extractVimeoFromHtml(widget.sourceHtml!);
      }
      return null;
    }
  }

  String? _extractVimeoFromHtml(String html) {
    try {
      // فك تشفير HTML entities أولاً
      var decodedHtml = html
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#039;', "'")
          .replaceAll('&amp;', '&');


      // البحث عن معرف الفيديو في src attribute
      final patterns = [
        RegExp(r'player\.vimeo\.com/video/(\d+)'),
        RegExp(r'vimeo\.com/(\d+)'),
      ];

      for (var pattern in patterns) {
        final match = pattern.firstMatch(decodedHtml);
        if (match != null && match.groupCount >= 1) {
          final vimeoId = match.group(1);
          return vimeoId;
        }
      }

    } catch (e) {
    }
    return null;
  }

  Widget _buildThumbnailButton() {
    final isTikTok = (widget.sourceProvider ?? '').toLowerCase().contains(
      'tiktok',
    );
    final height = isTikTok ? 400.0 : 250.0; // TikTok أطول للهاتف العمودي

    return GestureDetector(
      onTap: _openInExternalApp,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // الصورة المصغرة
              if (widget.sourceThumbnail != null)
                Image.network(
                  widget.sourceThumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey[800]),
                )
              else
                Container(
                  color: Colors.grey[800],
                  child: Icon(
                    _getProviderIcon(),
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              // طبقة داكنة
              Container(color: Colors.black.withOpacity(0.4)),
              // زر التشغيل
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getProviderColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.play, color: Colors.white, size: 40),
                ),
              ),
              // العنوان
              if (widget.sourceTitle != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.6),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      widget.sourceTitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final isTikTok = (widget.sourceProvider ?? '').toLowerCase().contains(
      'tiktok',
    );
    final height = isTikTok ? 400.0 : 250.0; // TikTok أطول

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        color: Colors.grey[900],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 48, color: Colors.red[400]),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error ?? 'خطأ في تشغيل الفيديو',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_retryCount < _maxRetries)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'محاولة ${_retryCount + 1} من $_maxRetries',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _retryCount < _maxRetries ? _retryLoad : null,
                  icon: Icon(Iconsax.refresh),
                  label: Text(
                    _retryCount < _maxRetries
                        ? 'إعادة محاولة'
                        : 'اكتملت المحاولات',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    disabledBackgroundColor: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openInExternalApp,
                  icon: Icon(Iconsax.link),
                  label: const Text('فتح في المتصفح'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _retryLoad() {
    setState(() {
      _retryCount++;
      _error = null;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (_isYouTube) {
          // إعادة إنشاء YouTube controller
          final videoId = _getYouTubeEmbedUrl();
          if (videoId != null && videoId.length >= 5) {
            _youtubeController?.dispose();
            _youtubeController = YoutubePlayerController(
              initialVideoId: videoId,
              flags: const YoutubePlayerFlags(
                autoPlay: false,
                mute: false,
                enableCaption: false,
                loop: false,
                showLiveFullscreenButton: true,
              ),
            );
            setState(() {});
          }
        } else if (_isTikTok) {
          // إعادة تهيئة TikTok WebView
          _initializeTikTokWebView();
          setState(() {});
        } else if (_isVimeo) {
          // إعادة تهيئة Vimeo WebView
          _initializeVimeoWebView();
          setState(() {});
        } else if (_useHtmlWidget) {
          // إعادة بناء HTML Widget
          setState(() {});
        }
      }
    });
  }

  IconData _getProviderIcon() {
    final provider = (widget.sourceProvider ?? '').toLowerCase();
    if (provider.contains('youtube')) return Iconsax.video;
    if (provider.contains('tiktok')) return Iconsax.video;
    if (provider.contains('vimeo')) return Iconsax.video;
    if (provider.contains('instagram')) return Iconsax.instagram;
    return Iconsax.play;
  }

  Color _getProviderColor() {
    final provider = (widget.sourceProvider ?? '').toLowerCase();
    if (provider.contains('youtube')) return const Color(0xFFFF0000);
    if (provider.contains('tiktok')) return const Color(0xFF000000);
    if (provider.contains('vimeo')) return const Color(0xFF1ab7ea);
    if (provider.contains('instagram')) return const Color(0xFFE1306C);
    return const Color(0xFF6366f1);
  }
}

/// WidgetFactory مخصص لدعم WebView في HtmlWidget
class _WidgetFactory extends WidgetFactory with WebViewFactory {}
