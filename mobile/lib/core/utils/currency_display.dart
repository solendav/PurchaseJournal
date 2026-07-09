import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Whole-number ETB formatter used on metric cards (matches EasyMerkato).
final NumberFormat journalCurrency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

/// Numeric part only — suffix "ETB" is shown separately on cards.
String formatMetricAmount(num amount, [NumberFormat? currency]) {
  final fmt = currency ?? journalCurrency;
  return fmt.format(amount.toDouble()).replaceAll('ETB ', '').trim();
}

class MetricAmountText extends StatelessWidget {
  const MetricAmountText({
    super.key,
    required this.amount,
    this.currency,
    this.style,
    this.suffixStyle,
    this.alignment = Alignment.centerLeft,
    this.showSuffix = true,
  });

  final num amount;
  final NumberFormat? currency;
  final TextStyle? style;
  final TextStyle? suffixStyle;
  final Alignment alignment;
  final bool showSuffix;

  @override
  Widget build(BuildContext context) {
    final valueStyle = style ??
        Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            );
    final etbStyle = suffixStyle ??
        Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).hintColor,
            );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            formatMetricAmount(amount, currency),
            maxLines: 1,
            style: valueStyle,
          ),
          if (showSuffix) ...[
            const SizedBox(width: 4),
            Text('ETB', style: etbStyle),
          ],
        ],
      ),
    );
  }
}
