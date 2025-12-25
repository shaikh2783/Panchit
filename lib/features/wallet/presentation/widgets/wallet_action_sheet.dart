import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/core/theme/design_tokens.dart';
import 'package:snginepro/features/wallet/application/bloc/wallet_action_cubit.dart';
import 'package:snginepro/features/wallet/data/models/wallet_summary.dart';
import 'package:snginepro/features/wallet/presentation/widgets/wallet_shared_widgets.dart';
import 'package:get/get.dart';

class WalletActionBottomSheet extends StatefulWidget {
  const WalletActionBottomSheet({
    super.key,
    required this.summary,
    required this.action,
  });

  final WalletSummary summary;
  final WalletActionType action;

  @override
  State<WalletActionBottomSheet> createState() =>
      _WalletActionBottomSheetState();
}

class _WalletActionBottomSheetState extends State<WalletActionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _userIdController;
  late final TextEditingController _amountController;
  late final TextEditingController _referenceController;
  late final TextEditingController _noteController;
  String? _selectedSource;
  String? _selectedMethod;

  WalletActionCubit get _cubit => context.read<WalletActionCubit>();

  @override
  void initState() {
    super.initState();
    _userIdController = TextEditingController();
    _amountController = TextEditingController();
    _referenceController = TextEditingController();
    _noteController = TextEditingController();
    if (widget.action == WalletActionType.withdraw) {
      final enabledSources = widget.summary.withdrawalSources.entries
          .where((entry) => entry.value.enabled)
          .map((entry) => entry.key)
          .toList();
      if (enabledSources.isNotEmpty) {
        _selectedSource = enabledSources.first;
      }
    }
    if (widget.action == WalletActionType.recharge) {
      if (widget.summary.wallet.paymentMethods.isNotEmpty) {
        _selectedMethod = widget.summary.wallet.paymentMethods.first;
      }
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
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

  void _submit() {
    final cubit = _cubit;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    switch (widget.action) {
      case WalletActionType.transfer:
        final userId = int.tryParse(_userIdController.text.trim());
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid user ID')),
          );
          return;
        }
        cubit.transfer(userId: userId, amount: amount);
        break;
      case WalletActionType.tip:
        final userId = int.tryParse(_userIdController.text.trim());
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid user ID')),
          );
          return;
        }
        cubit.tip(userId: userId, amount: amount);
        break;
      case WalletActionType.withdraw:
        final source = _selectedSource;
        if (source == null || source.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select a withdrawal source')),
          );
          return;
        }
        cubit.withdraw(source: source, amount: amount);
        break;
      case WalletActionType.recharge:
        final reference = _referenceController.text.trim();
        final note = _noteController.text.trim();
        cubit.recharge(
          amount: amount,
          method: _selectedMethod,
          reference: reference.isEmpty ? null : reference,
          note: note.isEmpty ? null : note,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.lg,
        right: Spacing.lg,
        top: Spacing.lg,
        bottom: mediaQuery.viewInsets.bottom + Spacing.lg,
      ),
      child: BlocConsumer<WalletActionCubit, WalletActionState>(
        listener: (context, state) {
          if (state.status == WalletActionStatus.success &&
              state.result != null &&
              state.lastAction == widget.action) {
            Navigator.of(context).pop(state.result);
          }
          if (state.status == WalletActionStatus.failure &&
              state.lastAction == widget.action &&
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
              state.lastAction == widget.action;
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  _titleForAction(widget.action),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  _subtitleForAction(widget.action, widget.summary),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Spacing.lg),
                if (widget.action != WalletActionType.withdraw &&
                    widget.action != WalletActionType.recharge)
                  TextFormField(
                    controller: _userIdController,
                    enabled: !isProcessing,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'User ID',
                      hintText: 'Enter the recipient user ID',
                    ),
                    validator: (value) {
                      if (widget.action == WalletActionType.withdraw ||
                          widget.action == WalletActionType.recharge) {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return 'User ID is required';
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return 'User ID must be numeric';
                      }
                      return null;
                    },
                  ),
                if (widget.action != WalletActionType.withdraw &&
                    widget.action != WalletActionType.recharge)
                  const SizedBox(height: Spacing.md),
                TextFormField(
                  controller: _amountController,
                  enabled: !isProcessing,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount ($_currencySymbol)',
                    hintText: '0.00',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    if (widget.action == WalletActionType.withdraw &&
                        amount < widget.summary.wallet.minWithdrawal) {
                      return 'Minimum withdrawal is ${widget.summary.wallet.minWithdrawal.toStringAsFixed(2)}';
                    }
                    if (widget.summary.wallet.maxTransfer > 0 &&
                        amount > widget.summary.wallet.maxTransfer) {
                      return 'Maximum allowed is ${widget.summary.wallet.maxTransfer.toStringAsFixed(2)}';
                    }
                    return null;
                  },
                ),
                if (widget.action == WalletActionType.withdraw) ...[
                  const SizedBox(height: Spacing.md),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedSource),
                    initialValue: _selectedSource,
                    items: widget.summary.withdrawalSources.entries
                        .where((entry) => entry.value.enabled)
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(_formatWithdrawalLabel(entry.key)),
                          ),
                        )
                        .toList(),
                    onChanged: isProcessing
                        ? null
                        : (value) {
                            setState(() {
                              _selectedSource = value;
                            });
                          },
                    decoration: const InputDecoration(labelText: 'Source'),
                    validator: (value) {
                      if (widget.action != WalletActionType.withdraw) {
                        return null;
                      }
                      if (value == null || value.isEmpty) {
                        return 'Select a withdrawal source';
                      }
                      return null;
                    },
                  ),
                ],
                if (widget.action == WalletActionType.recharge) ...[
                  const SizedBox(height: Spacing.md),
                  if (widget.summary.wallet.paymentMethods.isNotEmpty)
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedMethod),
                      initialValue: _selectedMethod,
                      items: widget.summary.wallet.paymentMethods
                          .map(
                            (method) => DropdownMenuItem(
                              value: method,
                              child: Text(_formatPaymentMethod(method)),
                            ),
                          )
                          .toList(),
                      onChanged: isProcessing
                          ? null
                          : (value) {
                              setState(() {
                                _selectedMethod = value;
                              });
                            },
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                      ),
                    ),
                  const SizedBox(height: Spacing.md),
                  TextFormField(
                    controller: _referenceController,
                    enabled: !isProcessing,
                    decoration: const InputDecoration(
                      labelText: 'Reference (Optional)',
                      hintText: 'Transaction or order ID',
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  TextFormField(
                    controller: _noteController,
                    enabled: !isProcessing,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                      hintText: 'Add any additional notes',
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.lg),
                if (state.result != null &&
                    state.lastAction == widget.action &&
                    !state.result!.success)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: WalletInlineMessage(
                      message: state.result!.message,
                      isError: true,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isProcessing
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text('cancel'.tr),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: isProcessing ? null : _submit,
                        child: isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('confirmed_button'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _titleForAction(WalletActionType action) {
    switch (action) {
      case WalletActionType.transfer:
        return 'Transfer balance';
      case WalletActionType.tip:
        return 'Send a tip';
      case WalletActionType.withdraw:
        return 'Withdraw funds';
      case WalletActionType.recharge:
        return 'Recharge wallet';
    }
  }

  String _subtitleForAction(WalletActionType action, WalletSummary summary) {
    switch (action) {
      case WalletActionType.transfer:
        if (summary.wallet.maxTransfer > 0) {
          return 'You can transfer up to ${summary.wallet.maxTransfer.toStringAsFixed(2)} $_currencySymbol at a time.';
        }
        return 'Send balance to another user by entering their user ID.';
      case WalletActionType.tip:
        final min = summary.tips.minAmount.toStringAsFixed(2);
        final max = summary.tips.maxAmount > 0
            ? summary.tips.maxAmount.toStringAsFixed(2)
            : null;
        if (max != null) {
          return 'Tip between $min and $max $_currencySymbol to a user.';
        }
        return 'Tip at least $min $_currencySymbol to a user.';
      case WalletActionType.withdraw:
        return 'Minimum withdrawal is ${summary.wallet.minWithdrawal.toStringAsFixed(2)} $_currencySymbol.';
      case WalletActionType.recharge:
        return 'Add funds to your wallet balance. Enter the amount you want to recharge.';
    }
  }

  String _formatWithdrawalLabel(String source) {
    if (source.isEmpty) return source;
    final formatted = source
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        })
        .join(' ');
    return formatted;
  }

  String _formatPaymentMethod(String method) {
    if (method.isEmpty) return method;
    final formatted = method
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        })
        .join(' ');
    return formatted;
  }
}
