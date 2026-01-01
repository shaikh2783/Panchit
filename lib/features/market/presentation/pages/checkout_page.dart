import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../application/bloc/cart/cart.dart';
import '../../data/models/models.dart';
import '../../data/models/shipping_address.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../settings/data/services/addresses_api_service.dart';
import '../../../settings/data/models/address.dart';
import '../../data/services/market_settings_api_service.dart';
import '../../data/models/market_settings.dart';
import '../../../../main.dart' show globalApiClient;
import 'payment_webview_page.dart';
import 'orders_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';
import '../../../wallet/domain/wallet_repository.dart';
import '../../../wallet/data/services/wallet_api_service.dart';
import '../../domain/market_repository.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController();

  String _selectedPaymentMethod = 'wallet';
  bool _isProcessing = false;
  bool _loadingAddresses = false;
  List<Address> _savedAddresses = [];
  String? _selectedAddressId;
  bool _showManualForm = false;
  bool _loadingPaymentMethods = true;
  List<String> _availablePaymentMethods = [];
  MarketSettings? _marketSettings;
  double? _walletBalance;
  String? _walletCurrency;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final apiService = AddressesApiService(globalApiClient);
      final result = await apiService.getUserAddresses();
      
      
      if (result['success'] == true && mounted) {
        final addresses = (result['addresses'] as List?)?.cast<Address>() ?? [];
        if (addresses.isNotEmpty) {
        }
        
        setState(() {
          _savedAddresses = addresses;
          _loadingAddresses = false;
          // اختر أول عنوان افتراضياً
          if (addresses.isNotEmpty) {
            _selectAddress(addresses.first);
          } else {
            _showNewAddressForm();
          }
        });
      } else {
        setState(() => _loadingAddresses = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAddresses = false);
      }
    }
  }

  void _selectAddress(Address address) {
    setState(() {
      _selectedAddressId = address.addressId;
      _showManualForm = false;
      _nameController.text = address.title;
      _phoneController.text = address.phone;
      _addressController.text = address.details;
      _cityController.text = address.city;
      _zipController.text = address.zipCode;
      _countryController.text = address.country;
    });
  }

  void _showNewAddressForm() {
    setState(() {
      _selectedAddressId = null;
      _showManualForm = true;
      _nameController.clear();
      _phoneController.clear();
      _addressController.clear();
      _cityController.clear();
      _zipController.clear();
      _countryController.clear();
    });
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _loadingPaymentMethods = true);
    try {
      final apiService = MarketSettingsApiService(globalApiClient);
      final result = await apiService.getSettings();
      if (result['success'] == true && mounted) {
        final settings = result['data'] as MarketSettings;
        setState(() {
          _marketSettings = settings;
          _availablePaymentMethods = ['wallet'];
          _selectedPaymentMethod = 'wallet';
          _walletBalance = settings.userMarketBalance;
          _walletCurrency = settings.currency;
          _loadingPaymentMethods = false;
        });
        return;
      }
    } catch (_) {
      // Intentionally ignored: fallback below
    }

    // If settings failed (e.g., 403), attempt to fetch wallet summary as a fallback
    await _loadWalletSummaryFallback();

    if (mounted) {
      // Graceful fallback to wallet-only if API fails or returns 403
      setState(() {
        _availablePaymentMethods = ['wallet'];
        _selectedPaymentMethod = 'wallet';
        _loadingPaymentMethods = false;
      });
    }
  }

  Future<void> _loadWalletSummaryFallback() async {
    try {
      final repo = WalletRepository(WalletApiService(globalApiClient));
      final summary = await repo.fetchSummary();
      if (mounted) {
        setState(() {
          _walletBalance = summary.wallet.balance;
          _walletCurrency = summary.wallet.currency.isNotEmpty
              ? summary.wallet.currency
              : summary.wallet.currencySymbol;
        });
      }
    } catch (e) {
    }
  }

  Future<void> _handleCheckout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cartState = context.read<CartBloc>().state;
    if (cartState is CartEmpty) {
      Get.snackbar(
        'error'.tr,
        'market_cart_empty'.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        icon: const Icon(Icons.info, color: Colors.white),
      );
      return;
    }

    if (cartState is! CartLoaded) {
      Get.snackbar(
        'error'.tr,
        'market_cart_not_ready'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.cancel, color: Colors.white),
      );
      return;
    }

    final cart = cartState.cart;
    if (cart.isEmpty || cart.itemsCount == 0) {
      Get.snackbar(
        'error'.tr,
        'market_cart_empty'.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        icon: const Icon(Icons.info, color: Colors.white),
      );
      return;
    }

    final cartTotal = _parseAmount(cart.total);
    final walletBalance = _walletBalance ?? _marketSettings?.userMarketBalance ?? 0;

    if (walletBalance <= 0 || cartTotal > walletBalance) {
      _showInsufficientWalletDialog(cartTotal, walletBalance);
      return;
    }

    setState(() => _isProcessing = true);

    // إذا كان هناك عنوان محفوظ محدد، استخدمه مباشرة
    if (_selectedAddressId != null) {
      context.read<CartBloc>().add(
        CheckoutCartEvent(
          shippingAddressId: int.parse(_selectedAddressId!),
          paymentMethod: _selectedPaymentMethod,
        ),
      );
    } else {
      // وإلا أنشئ عنوان جديد
      final shippingAddress = ShippingAddress(
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        city: _cityController.text,
        zipCode: _zipController.text,
        country: _countryController.text,
      );

      context.read<CartBloc>().add(
        CheckoutCartEvent(
          shippingAddress: shippingAddress,
          paymentMethod: _selectedPaymentMethod,
        ),
      );
    }
  }

  double _parseAmount(String raw) {
    final sanitized = raw.replaceAll(',', '').trim();
    return double.tryParse(sanitized) ?? 0;
  }

  void _showInsufficientWalletDialog(double total, double balance) {
    Get.dialog(
      AlertDialog(
        title: Text('wallet_balance'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'wallet_balance_current'.tr}: ${balance.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('${'wallet_order_total'.tr}: ${total.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            Text('wallet_insufficient_for_checkout'.tr),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.to(() => const WalletPage());
            },
            child: Text('recharge_wallet_title'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartCheckoutSuccess) {
          setState(() => _isProcessing = false);
          Get.snackbar(
            'success'.tr,
            state.message,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            duration: const Duration(seconds: 4),
          );
          
          // Wait for snackbar to complete, then navigate
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              // Close snackbar first
              Get.closeCurrentSnackbar();
              // Navigate back to cart page and then to products
              Get.back(); // Close checkout
              Get.back(); // Close cart
              // Navigate to orders page
              Get.to(() => const OrdersPage());
            }
          });
         } else if (state is CartPaymentRequired) {
           setState(() => _isProcessing = false);
           // Open WebView for online payment
           Get.to(() => PaymentWebViewPage(
             paymentUrl: state.paymentUrl,
             ordersCollectionId: state.ordersCollectionId,
             totalAmount: state.totalAmount,
             repository: context.read<MarketRepository>(),
           ));
        } else if (state is CartCheckoutError) {
          setState(() => _isProcessing = false);
          Get.snackbar(
            'error'.tr,
            state.message,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: const Icon(Icons.cancel, color: Colors.white),
            duration: const Duration(seconds: 4),
          );
        }
      },
      child: Scaffold(
        backgroundColor: UI.surfacePage(context),
        appBar: AppBar(
          backgroundColor: Get.isDarkMode
              ? const Color(0xFF1a1f36)
              : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'market_checkout'.tr,
            style: TextStyle(
              color: Get.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('market_shipping_info'.tr),
              const SizedBox(height: 16),
              if (_loadingAddresses)
                const Center(child: CircularProgressIndicator())
              else if (_savedAddresses.isNotEmpty && !_showManualForm)
                _buildSavedAddresses()
              else
                _buildShippingForm(),

              const SizedBox(height: 24),
              _buildSectionTitle('market_payment_method'.tr),
              const SizedBox(height: 16),
              _buildPaymentMethods(),

              const SizedBox(height: 24),
              _buildSectionTitle('market_order_summary'.tr),
              const SizedBox(height: 16),
              _buildOrderSummary(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Get.isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildShippingForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UI.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: UI.softShadow(context),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            style: TextStyle(
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'full_name'.tr,
              labelStyle: TextStyle(
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              prefixIcon: Icon(
                Icons.person,
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'required'.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _phoneController,
            style: TextStyle(
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'phone_number'.tr,
              labelStyle: TextStyle(
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              prefixIcon: Icon(
                Icons.phone,
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'required'.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _addressController,
            style: TextStyle(
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'address'.tr,
              labelStyle: TextStyle(
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              prefixIcon: Icon(
                Icons.location_on,
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'required'.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  style: TextStyle(
                    color: Get.isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'city'.tr,
                    labelStyle: TextStyle(
                      color: Get.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Get.isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Get.isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'required'.tr;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _zipController,
                  style: TextStyle(
                    color: Get.isDarkMode ? Colors.white : Colors.black,
                  ),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'zip_code'.tr,
                    labelStyle: TextStyle(
                      color: Get.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Get.isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Get.isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _countryController,
            style: TextStyle(
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'country'.tr,
              labelStyle: TextStyle(
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              prefixIcon: Icon(
                Icons.public,
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'required'.tr;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddresses() {
    if (_showManualForm) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'new_address'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Get.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildShippingForm(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _showManualForm = false);
            },
            icon: const Icon(Icons.arrow_back),
            label: Text('back_to_addresses'.tr),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'your_addresses'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Get.isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ..._savedAddresses.map((address) => _buildAddressCard(address)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _showNewAddressForm,
          icon: const Icon(Icons.add),
          label: Text('add_new_address'.tr),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: Get.isDarkMode ? Colors.blue[700] : Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(Address address) {
    final isSelected = _selectedAddressId == address.addressId;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: UI.surfaceCard(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? (Get.isDarkMode ? Colors.blue[400]! : Colors.blue)
              : (Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectAddress(address),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? (Get.isDarkMode ? Colors.blue[400] : Colors.blue)
                    : (Get.isDarkMode ? Colors.grey[600] : Colors.grey[400]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Get.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.details,
                      style: TextStyle(
                        color: Get.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${address.city}, ${address.country}',
                      style: TextStyle(
                        color: Get.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.phone,
                      style: TextStyle(
                        color: Get.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        fontSize: 14,
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
  }

  Widget _buildPaymentMethods() {
    if (_loadingPaymentMethods) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: UI.surfaceCard(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: UI.softShadow(context),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_availablePaymentMethods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: UI.surfaceCard(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: UI.softShadow(context),
        ),
        child: Center(
          child: Text(
            'no_payment_methods_available'.tr,
            style: TextStyle(
              color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    final balance = _walletBalance ?? _marketSettings?.userMarketBalance;
    final currency = _walletCurrency ?? _marketSettings?.currency ?? 'USD';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UI.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: UI.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (balance != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${'wallet_balance_available'.tr}: ${balance.toStringAsFixed(2)} $currency',
                style: TextStyle(
                  color: Get.isDarkMode ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ..._availablePaymentMethods.asMap().entries.map((entry) {
            final index = entry.key;
            final method = entry.value;
            return Column(
              children: [
                if (index > 0) const Divider(height: 24),
                _buildPaymentOption(
                  method,
                  _getPaymentMethodTitle(method),
                  _getPaymentMethodIcon(method),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  String _getPaymentMethodTitle(String method) {
    final Map<String, String> titles = {
      'cash_on_delivery': 'market_payment_cod'.tr,
      'credit_card': 'market_payment_credit_card'.tr,
      'paypal': 'paypal'.tr,
      'stripe': 'stripe'.tr,
      'skrill': 'skrill'.tr,
      'bank': 'bank_transfer'.tr,
      'bank_transfer': 'bank_transfer'.tr,
      'custom': _marketSettings?.paymentMethodCustom ?? 'custom'.tr,
      'moneypoolscash': 'moneypoolscash'.tr,
      'cashfree': 'Cashfree',
      'razorpay': 'Razorpay',
      '2checkout': '2Checkout',
      'paystack': 'Paystack',
      'wallet': 'wallet_balance'.tr,
    };
    return titles[method] ?? method.toUpperCase();
  }

  IconData _getPaymentMethodIcon(String method) {
    final Map<String, IconData> icons = {
      'cash_on_delivery': Icons.money,
      'credit_card': Icons.credit_card,
      'paypal': Icons.account_balance_wallet,
      'stripe': Icons.credit_card,
      'skrill': Icons.account_balance,
      'bank': Icons.account_balance,
      'bank_transfer': Icons.account_balance,
      'custom': Icons.payment,
      'moneypoolscash': Icons.payments,
      'cashfree': Icons.payments,
      'razorpay': Icons.payments,
      '2checkout': Icons.shopping_cart,
      'paystack': Icons.credit_card,
      'wallet': Icons.account_balance_wallet,
    };
    return icons[method] ?? Icons.payment;
  }

  Widget _buildPaymentOption(String value, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: _availablePaymentMethods.length > 1
          ? () {
              setState(() {
                _selectedPaymentMethod = value;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.green
                      : (Get.isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.circle, size: 14, color: Colors.green),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Get.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state is! CartLoaded) {
          return const SizedBox.shrink();
        }

        final cart = state.cart;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: UI.surfaceCard(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: UI.softShadow(context),
          ),
          child: Column(
            children: [
              _buildSummaryRow('market_items'.tr, '${cart.itemsCount}'),
              const Divider(height: 24),
              _buildSummaryRow(
                'market_total'.tr,
                cart.formattedTotal,
                isTotal: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal
                ? Colors.green
                : (Get.isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UI.surfaceCard(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handleCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'market_confirm_order'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
