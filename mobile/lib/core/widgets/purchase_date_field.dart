import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/config/themes/app_theme.dart';

/// Day / month / year picker. Defaults to today.
class PurchaseDateField extends StatelessWidget {
  const PurchaseDateField({
    super.key,
    required this.date,
    required this.onChanged,
    this.label = 'Purchase date',
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final String label;

  static final _displayFormat = DateFormat('dd/MM/yyyy');
  static final _apiFormat = DateFormat('yyyy-MM-dd');

  static String toApiDate(DateTime date) => _apiFormat.format(date);

  static String display(DateTime date) => _displayFormat.format(date);

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Select purchase date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
        ),
        child: Text(
          display(date),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}
