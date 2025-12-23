import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_action_cubit.dart';
import 'package:snginepro/features/wallet/data/models/wallet_summary.dart';
import 'package:snginepro/features/wallet/domain/wallet_repository.dart';
import 'package:snginepro/features/wallet/presentation/widgets/paypal_payment_handler.dart';
import 'package:snginepro/features/wallet/presentation/widgets/wallet_shared_widgets.dart';

class WalletRechargePage extends StatelessWidget {
  const WalletRechargePage({super.key, required this.summary});

  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<WalletRepository>(context, listen: false);
    return BlocProvider<WalletActionCubit>(
      create: (_) => WalletActionCubit(repository),
      child: _WalletRechargeView(summary: summary),
    );
  }
}

class _WalletRechargeView extends StatefulWidget {
  const _WalletRechargeView({required this.summary});

  final WalletSummary summary;

  @override
  State<_WalletRechargeView> createState() => _WalletRechargeViewState();
}

class _WalletRechargeViewState extends State<_WalletRechargeView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedMethod;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _currencySymbol {
    final wallet = widget.summary.wallet;
    return wallet.currencySymbol.isNotEmpty
        ? wallet.currencySymbol
        : wallet.currency;
  }

  void _submitRecharge() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final note = _noteController.text.trim();

    // Check if PayPal is selected
    if (_selectedMethod?.toLowerCase() == 'paypal') {
      _processPayPalPayment(amount, note);
    } else {
      // Direct recharge for other methods
      final reference = _referenceController.text.trim();
      context.read<WalletActionCubit>().recharge(
        amount: amount,
        method: _selectedMethod,
        reference: reference.isEmpty ? null : reference,
        note: note.isEmpty ? null : note,
      );
    }
  }

  void _processPayPalPayment(double amount, String note) {
    final currency = widget.summary.wallet.currency.isNotEmpty
        ? widget.summary.wallet.currency
        : 'USD';

    PayPalPaymentHandler.processPayment(
      context: context,
      amount: amount,
      currency: currency,
      description: 'Wallet Recharge - ${amount.toStringAsFixed(2)} $currency',
      onSuccess: (params) {
        // Extract transaction ID from PayPal response
        final transactionId = PayPalPaymentHandler.extractTransactionId(params);
        final payerId = PayPalPaymentHandler.extractPayerId(params);

        // Call recharge API with PayPal transaction details
        context.read<WalletActionCubit>().recharge(
          amount: amount,
          method: 'paypal',
          reference: transactionId.isNotEmpty ? transactionId : payerId,
          note: note.isEmpty ? 'PayPal Payment' : '$note - PayPal Payment',
        );

        Navigator.of(context).pop();
      },
      onError: (error) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PayPal payment failed: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      onCancel: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableMethods = widget.summary.wallet.paymentMethods;

    return Scaffold(
      appBar: AppBar(
        title: Text('recharge_wallet_title'.tr),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<WalletActionCubit, WalletActionState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.lastAction == WalletActionType.recharge,
        listener: (context, state) {
          if (state.status == WalletActionStatus.success &&
              state.result != null) {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.result!.message.isNotEmpty
                      ? state.result!.message
                      : 'Wallet recharged successfully',
                ),
              ),
            );
            Navigator.of(context).pop(state.result);
          }

          if (state.status == WalletActionStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isProcessing =
              state.status == WalletActionStatus.inProgress &&
              state.lastAction == WalletActionType.recharge;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: [
                // Current Balance Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.large),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Balance',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          '$_currencySymbol${widget.summary.wallet.balance.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xl),

                // Amount Input
                Text(
                  'Recharge Amount',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                TextFormField(
                  controller: _amountController,
                  enabled: !isProcessing,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount ($_currencySymbol)',
                    hintText: '0.00',
                    prefixIcon: const Icon(Iconsax.wallet_money),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Spacing.xl),

                // Payment Methods Section
                Text(
                  'Select Payment Method',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                if (availableMethods.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.info_circle,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Text(
                              'No payment methods available',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...availableMethods.map(
                    (method) => Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.sm),
                      child: _PaymentMethodCard(
                        method: method,
                        isSelected: _selectedMethod == method,
                        onTap: isProcessing
                            ? null
                            : () {
                                setState(() {
                                  _selectedMethod = method;
                                });
                              },
                      ),
                    ),
                  ),
                const SizedBox(height: Spacing.lg),

                // Optional Fields
                Text(
                  'Additional Information (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                TextFormField(
                  controller: _referenceController,
                  enabled: !isProcessing,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Reference',
                    hintText: 'Order ID or transaction number',
                    prefixIcon: Icon(Iconsax.document_text),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                TextFormField(
                  controller: _noteController,
                  enabled: !isProcessing,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'Add any additional notes',
                    prefixIcon: Icon(Iconsax.message_text),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: Spacing.xl),

                // Error Message
                if (state.status == WalletActionStatus.failure &&
                    state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: WalletInlineMessage(
                      message: state.errorMessage!,
                      isError: true,
                    ),
                  ),

                // Submit Button
                FilledButton(
                  onPressed: isProcessing ? null : _submitRecharge,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.large),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.wallet_add, size: 20),
                            const SizedBox(width: Spacing.sm),
                            Text(
                              'Recharge Now',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: Spacing.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final String method;
  final bool isSelected;
  final VoidCallback? onTap;

  IconData _getIconForMethod(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('paypal')) return Iconsax.wallet;
    if (lower.contains('stripe')) return Iconsax.card;
    if (lower.contains('bank')) return Iconsax.bank;
    if (lower.contains('credit') || lower.contains('card')) {
      return Iconsax.card;
    }
    return Iconsax.wallet_money;
  }

  String _formatMethodName(String method) {
    if (method.isEmpty) return method;
    return method
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _getIconForMethod(method);
    final displayName = _formatMethodName(method);

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.large),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.dividerColor.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.large),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      (isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceVariant)
                          .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(Radii.medium),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.textTheme.titleMedium?.color,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Iconsax.tick_circle,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
