import 'package:flutter/material.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/config/themes/app_theme.dart';
import 'package:purchase_journal/core/utils/currency_display.dart';

class DebtSummaryRow extends StatelessWidget {
  const DebtSummaryRow({
    super.key,
    required this.purchased,
    required this.paid,
  });

  final num purchased;
  final num paid;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniStat(label: 'Purchased', amount: purchased)),
        const SizedBox(width: 10),
        Expanded(child: _MiniStat(label: 'Paid', amount: paid, valueColor: AppColors.success)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.amount,
    this.valueColor,
  });

  final String label;
  final num amount;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 4),
          MetricAmountText(
            amount: amount,
            alignment: Alignment.centerLeft,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: valueColor ?? AppColors.text,
            ),
            suffixStyle: TextStyle(
              fontSize: 10,
              color: valueColor ?? AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
