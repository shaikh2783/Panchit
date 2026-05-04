import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../domain/market_repository.dart';
import 'orders_page.dart';

/// صفحة الدفع عبر WebView
/// 
/// تُستخدم لإتمام الدفع الإلكتروني عبر:
/// - Stripe
/// - PayPal
/// - 2Checkout
/// - وغيرها
class PaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;
  final String ordersCollectionId;
  final String totalAmount;
  final MarketRepository repository;

  const PaymentWebViewPage({
    Key? key,
    required this.paymentUrl,
    required this.ordersCollectionId,
    required this.totalAmount,
    required this.repository,
  }) : super(key: key);

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isCheckingStatus = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWebViewAsync();
  }

  @override
  void dispose() {
    // Properly clean up WebViewController to prevent platform exceptions
    super.dispose();
  }

  Future<void> _initializeWebViewAsync() async {
    // Prevent re-initialization if already initialized
    if (_initialized) {
      return;
    }

    try {
      final targetUrl = await _buildSessionAwareUrl();
      if (!mounted) return;

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              if (mounted) setState(() => _isLoading = false);
              _checkPaymentCompletion(url);
            },
            onWebResourceError: (WebResourceError error) {
            },
          ),
        );

      await _controller.loadRequest(Uri.parse(targetUrl));

      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل صفحة الدفع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// بناء رابط الدفع مع جلسة WebView (إن توفرت) لتجاوز صفحة تسجيل الدخول
  Future<String> _buildSessionAwareUrl() async {
    try {
      final token = await widget.repository.createWebViewSessionToken();
      if (token == null || token.isEmpty) {
        return widget.paymentUrl;
      }

      final paymentUri = Uri.parse(widget.paymentUrl);
      final redirect = '${paymentUri.path}${paymentUri.hasQuery ? '?${paymentUri.query}' : ''}';
      final loginUri = Uri(
        scheme: paymentUri.scheme,
        host: paymentUri.host,
        port: paymentUri.hasPort ? paymentUri.port : null,
        path: '/auth/webview/login',
        queryParameters: {
          'token': token,
          'redirect': redirect,
        },
      );

      return loginUri.toString();
    } catch (e) {
      return widget.paymentUrl;
    }
  }


  /// التحقق من إتمام الدفع بناءً على الـ URL
  void _checkPaymentCompletion(String url) {

    // Check if payment succeeded
    if (url.contains('success') || 
        url.contains('completed') || 
        url.contains('payment-complete')) {
      _handlePaymentSuccess();
    }
    // Check if payment cancelled
    else if (url.contains('cancel') || url.contains('cancelled')) {
      _handlePaymentCancelled();
    }
    // Check if payment failed
    else if (url.contains('error') || url.contains('failed')) {
      _handlePaymentFailed();
    }
  }

  /// معالجة نجاح الدفع
  Future<void> _handlePaymentSuccess() async {
    if (_isCheckingStatus) return;
    
    setState(() => _isCheckingStatus = true);

    try {

      // Wait a moment for backend to process webhook
      await Future.delayed(const Duration(seconds: 2));

      // Fetch orders to verify payment was processed
       final buyerOrders = await widget.repository.getBuyerOrders();

      // Check if our orders collection was created
       final hasOrder = buyerOrders.any((order) => 
        order.orderHash.contains(widget.ordersCollectionId) ||
        order.orderId.toString() == widget.ordersCollectionId
      );

       if (hasOrder || buyerOrders.isNotEmpty) {
        // Payment confirmed!
        if (mounted) {
          Get.back(); // Close WebView
          Get.snackbar(
            'success'.tr,
            'تم إتمام الدفع بنجاح!\nالمبلغ: ${widget.totalAmount}',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            duration: const Duration(seconds: 3),
          );
          // Navigate to orders page
          Get.offAll(() => const OrdersPage());
        }
      } else {
        // Payment may still be processing
        _showPendingDialog();
      }
    } catch (e) {
      _showPendingDialog();
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  /// معالجة إلغاء الدفع
  void _handlePaymentCancelled() {
    Get.back(); // Close WebView
    Get.snackbar(
      'cancelled'.tr,
      'تم إلغاء عملية الدفع',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      icon: const Icon(Icons.cancel, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  /// معالجة فشل الدفع
  void _handlePaymentFailed() {
    Get.back(); // Close WebView
    Get.snackbar(
      'error'.tr,
      'فشل في إتمام الدفع\nيرجى المحاولة مرة أخرى',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  /// عرض dialog للدفع المعلق
  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('payment_pending'.tr),
        content: Text(
          'عملية الدفع قيد المعالجة.\n'
          'ستظهر الطلبات خلال دقائق.\n'
          'يمكنك التحقق من صفحة الطلبات.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.back(); // Close WebView
              Get.to(() => const OrdersPage());
            },
            child: Text('view_orders'.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.back(); // Close WebView
            },
            child: Text('ok'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Get.isDarkMode ? const Color(0xFF1a1f36) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            // Confirm cancellation
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('cancel_payment'.tr),
                content: Text('هل تريد إلغاء عملية الدفع؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('no'.tr),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.back(); // Close WebView
                    },
                    child: Text('yes'.tr),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text(
          'complete_payment'.tr,
          style: TextStyle(
            color: Get.isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _isLoading
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
        ),
      ),
      body: Stack(
        children: [
          if (_initialized)
            WebViewWidget(controller: _controller)
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل صفحة الدفع...'),
                ],
              ),
            ),
          if (_isCheckingStatus)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'جاري التحقق من عملية الدفع...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Get.isDarkMode ? const Color(0xFF1a1f36) : Colors.grey[100],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'total_amount'.tr,
                  style: TextStyle(
                    color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  widget.totalAmount,
                  style: TextStyle(
                    color: Get.isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _initialized ? () => _controller.reload() : null,
              icon: const Icon(Icons.refresh),
              label: Text('refresh'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
