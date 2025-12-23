import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/ui_constants.dart';
import '../../data/models/funding.dart';
import '../../domain/funding_repository.dart';

class FundingDonatePage extends StatefulWidget {
  final Funding funding;

  const FundingDonatePage({super.key, required this.funding});

  @override
  State<FundingDonatePage> createState() => _FundingDonatePageState();
}

class _FundingDonatePageState extends State<FundingDonatePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  bool _donating = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _donate() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    setState(() => _donating = true);
    try {
      final repo = context.read<FundingRepository>();
      await repo.donateFunding(int.parse(widget.funding.postId), amount);
      if (!mounted) return;
      Get.back(result: true);
      Get.snackbar('success'.tr, 'donation_successful'.tr);
    } catch (e) {
      if (!mounted) return;
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _donating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remaining = widget.funding.remainingAmount;

    return Scaffold(
      appBar: AppBar(title: Text('donate'.tr)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(UI.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campaign card
              Container(
                decoration: BoxDecoration(
                  color: UI.surfaceCard(context),
                  borderRadius: BorderRadius.circular(UI.rLg),
                  boxShadow: UI.softShadow(context),
                ),
                padding: EdgeInsets.all(UI.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.funding.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: UI.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: widget.funding.progress,
                        minHeight: 10,
                        backgroundColor: scheme.primary.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                      ),
                    ),
                    SizedBox(height: UI.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('raised'.tr, style: TextStyle(fontSize: 12, color: UI.subtleText(context))),
                            const SizedBox(height: 2),
                            Text(
                              '\$${widget.funding.raisedAmount.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.primary),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('remaining'.tr, style: TextStyle(fontSize: 12, color: UI.subtleText(context))),
                            const SizedBox(height: 2),
                            Text(
                              '\$${remaining.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: UI.xl),

              // Amount input
              Text(
                'donation_amount'.tr,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: UI.md),
              TextFormField(
                controller: _amountCtrl,
                decoration: InputDecoration(
                  labelText: 'amount'.tr,
                  prefixIcon: const Icon(Iconsax.money_send_copy),
                  suffixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'required'.tr;
                  final amount = double.tryParse(v);
                  if (amount == null || amount <= 0) return 'amount_must_be_positive'.tr;
                  return null;
                },
              ),
              SizedBox(height: UI.lg),

              // Quick amounts
              Text(
                'quick_amounts'.tr,
                style: TextStyle(fontSize: 13, color: UI.subtleText(context)),
              ),
              SizedBox(height: UI.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [10, 25, 50, 100, 250, 500].map((amt) {
                  return ActionChip(
                    label: Text('\$$amt'),
                    onPressed: () => setState(() => _amountCtrl.text = amt.toString()),
                  );
                }).toList(),
              ),
              SizedBox(height: UI.xl * 2),

              // Donate button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _donating ? null : _donate,
                  icon: _donating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Iconsax.card_send_copy),
                  label: Text(_donating ? 'processing'.tr : 'donate_now'.tr),
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
