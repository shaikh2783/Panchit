import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_action_cubit.dart';
import 'package:snginepro/features/wallet/data/models/wallet_summary.dart';
import 'package:snginepro/features/wallet/domain/wallet_repository.dart';
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
  final _noteController = TextEditingController();

  // ── Razorpay ─────────────────────────────────────────────────────────────
  late final Razorpay _razorpay;
  bool _isRazorpayLoading = false;
  double? _pendingRazorpayAmount;
  String? _pendingRazorpayNote;
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _currencySymbol {
    final wallet = widget.summary.wallet;
    return wallet.currencySymbol.isNotEmpty
        ? wallet.currencySymbol
        : wallet.currency;
  }


  // ── Razorpay callbacks ────────────────────────────────────────────────────

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    final orderId = response.orderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';

    try {
      final repo = Provider.of<WalletRepository>(context, listen: false);
      final result = await repo.verifyRazorpayPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
        amount: _pendingRazorpayAmount ?? 0,
        note: _pendingRazorpayNote,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isNotEmpty
                ? result.message
                : 'Wallet recharged successfully',
          ),
        ),
      );
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRazorpayLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment verification failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isRazorpayLoading = false);
    final msg = response.message ?? 'Payment failed or cancelled';
    // Code 0 means user cancelled — show a neutral message
    final isCancel = (response.code ?? -1) == Razorpay.PAYMENT_CANCELLED;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCancel ? 'Payment cancelled' : msg),
        backgroundColor: isCancel ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isRazorpayLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'External wallet selected: ${response.walletName ?? "unknown"}',
        ),
      ),
    );
  }

  // ── Razorpay order + checkout ─────────────────────────────────────────────

  Future<void> _startRazorpayRecharge(double amount, String note) async {
    setState(() {
      _isRazorpayLoading = true;
      _pendingRazorpayAmount = amount;
      _pendingRazorpayNote = note.isEmpty ? null : note;
    });
    try {
      final repo = Provider.of<WalletRepository>(context, listen: false);
      final order = await repo.createRazorpayOrder(
        amount: amount,
        note: _pendingRazorpayNote,
      );
      final options = <String, dynamic>{
        'key': order.keyId,
        'amount': order.amount,
        'currency': order.currency,
        'order_id': order.orderId,
        'name': order.name,
        'description': order.description,
        'prefill': <String, String>{'contact': '', 'email': ''},
      };
      _razorpay.open(options);
      // _isRazorpayLoading stays true until a callback fires
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRazorpayLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create payment order: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ── Submit dispatcher ─────────────────────────────────────────────────────

  void _submitRecharge() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final note = _noteController.text.trim();
    _startRazorpayRecharge(amount, note);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          final isBlocProcessing =
              state.status == WalletActionStatus.inProgress &&
              state.lastAction == WalletActionType.recharge;
          final isProcessing = isBlocProcessing || _isRazorpayLoading;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: [
                // ── Current Balance Card ──────────────────────────────────
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

                // ── Amount ───────────────────────────────────────────────
                Text(
                  'Recharge Amount',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
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

                // ── Note (optional) ───────────────────────────────────────
                Text(
                  'Additional Information (Optional)',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: Spacing.sm),

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

                // ── Inline error ──────────────────────────────────────────
                if (state.status == WalletActionStatus.failure &&
                    state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: WalletInlineMessage(
                      message: state.errorMessage!,
                      isError: true,
                    ),
                  ),

                // ── Submit button ─────────────────────────────────────────
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
