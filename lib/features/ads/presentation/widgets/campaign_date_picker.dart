import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

class CampaignDatePicker extends StatelessWidget {
  const CampaignDatePicker({
    super.key,
    required this.label,
    required this.controller,
    required this.onTap,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      theme.cardColor.withOpacity(0.5),
                      theme.cardColor.withOpacity(0.3),
                    ]
                  : [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
            ),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'ads_select_date'.tr,
              prefixIcon: Icon(
                Iconsax.calendar_1,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              suffixIcon: Icon(
                Iconsax.arrow_down_1,
                color: theme.colorScheme.primary.withOpacity(0.5),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            readOnly: true,
            onTap: onTap,
            validator: validator,
          ),
        ),
      ],
    );
  }

  static Future<DateTime?> pickDate(BuildContext context, {DateTime? initialDate}) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            dialogBackgroundColor: theme.cardColor,
            colorScheme: theme.colorScheme.copyWith(
              surface: theme.cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
