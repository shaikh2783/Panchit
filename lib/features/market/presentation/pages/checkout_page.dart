import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../application/bloc/cart/cart.dart';
import '../../data/models/shipping_address.dart';
import '../../../../core/theme/ui_constants.dart';
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
  String _selectedPaymentMethod = 'cash_on_delivery';
  bool _isProcessing = false;
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
  Future<void> _handleCheckout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isProcessing = true);
    final shippingAddress = ShippingAddress(
      name: _nameController.text,
      phone: _phoneController.text,
      location: _addressController.text, // Use address as location
      address: _addressController.text,
      city: _cityController.text,
      zip: _zipController.text,
      country: _countryController.text,
    );
    context.read<CartBloc>().add(CheckoutCartEvent(
      shippingAddress: shippingAddress,
      paymentMethod: _selectedPaymentMethod,
      notes: '',
    ));
  }
  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartCheckoutSuccess) {
          setState(() => _isProcessing = false);
          Get.snackbar(
            'success'.tr,
            'market_order_placed_success'.tr,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
          // Navigate to order details or orders list
          Get.back();
          Get.back();
        } else if (state is CartCheckoutError) {
          setState(() => _isProcessing = false);
          Get.snackbar(
            'error'.tr,
            state.message,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: const Icon(Icons.cancel, color: Colors.white),
          );
        }
      },
      child: Scaffold(
        backgroundColor: UI.surfacePage(context),
        appBar: AppBar(
          backgroundColor: Get.isDarkMode ? const Color(0xFF1a1f36) : Colors.white,
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
            style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'full_name'.tr,
              labelStyle: TextStyle(color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              prefixIcon: Icon(Icons.person, color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
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
            style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'phone_number'.tr,
              labelStyle: TextStyle(color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              prefixIcon: Icon(Icons.phone, color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
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
            style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'address'.tr,
              labelStyle: TextStyle(color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              prefixIcon: Icon(Icons.location_on, color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
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
                  style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'city'.tr,
                    labelStyle: TextStyle(color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
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
                  style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'zip_code'.tr,
                    labelStyle: TextStyle(color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _countryController,
            style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'country'.tr,
              labelStyle: TextStyle(color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              prefixIcon: Icon(Icons.public, color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
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
  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UI.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: UI.softShadow(context),
      ),
      child: Column(
        children: [
          _buildPaymentOption(
            'cash_on_delivery',
            'market_payment_cod'.tr,
            Icons.money,
          ),
          const Divider(height: 24),
          _buildPaymentOption(
            'credit_card',
            'market_payment_credit_card'.tr,
            Icons.credit_card,
          ),
          const Divider(height: 24),
          _buildPaymentOption(
            'paypal',
            'market_payment_paypal'.tr,
            Icons.account_balance_wallet,
          ),
        ],
      ),
    );
  }
  Widget _buildPaymentOption(String value, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
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
                  color: isSelected ? Colors.green : (Get.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.circle,
                        size: 14,
                        color: Colors.green,
                      ),
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
            color: isTotal ? Colors.green : (Get.isDarkMode ? Colors.white : Colors.black87),
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
