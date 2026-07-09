import 'package:intl/intl.dart';
import 'package:purchase_journal/features/suppliers/data/models/supplier_statement_model.dart';

class StatementTableLogic {
  StatementTableLogic({
    required this.rows,
    required this.dateFmt,
    required this.currency,
  });

  final List<StatementRowModel> rows;
  final DateFormat dateFmt;
  final NumberFormat currency;

  Map<int, double> get dailyTotalByRowIndex => _buildDailyTotals();

  Map<int, double> _buildDailyTotals() {
    final purchaseSumByDay = <String, double>{};
    final lastIndexByDay = <String, int>{};

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.date.isEmpty) continue;

      final key = _dayKey(row.date);
      lastIndexByDay[key] = i;

      if (row.isPurchaseItem && row.subtotal != null) {
        purchaseSumByDay[key] = (purchaseSumByDay[key] ?? 0) + row.subtotal!;
      }
    }

    final result = <int, double>{};
    for (final entry in lastIndexByDay.entries) {
      final total = purchaseSumByDay[entry.key];
      if (total != null && total > 0) {
        result[entry.value] = total;
      }
    }
    return result;
  }

  String _dayKey(String raw) {
    try {
      final date = DateTime.parse(raw.split('T').first);
      return '${date.year}-${date.month}-${date.day}';
    } catch (_) {
      return raw;
    }
  }

  bool _isSameDay(String a, String b) => _dayKey(a) == _dayKey(b);

  String dateLabel(int index) {
    final row = rows[index];
    if (row.date.isEmpty) return '—';
    if (index > 0 && _isSameDay(rows[index - 1].date, row.date)) {
      return '>>';
    }
    try {
      return dateFmt.format(DateTime.parse(row.date.split('T').first));
    } catch (_) {
      return row.date;
    }
  }

  String itemLabel(StatementRowModel row) {
    if (row.isPayment) return row.description ?? 'Payment';
    return row.description ?? '';
  }

  String unitPriceLabel(StatementRowModel row) {
    if (row.isPayment || row.unitPrice == null) return '';
    final price = row.unitPrice!;
    if (price == price.roundToDouble()) return price.toStringAsFixed(0);
    return price.toStringAsFixed(2);
  }

  String? money(double? value) {
    if (value == null) return '';
    return currency.format(value);
  }

  String auditLabel(StatementRowModel row, {DateFormat? auditDateFmt}) {
    final created = row.createdByName?.trim() ?? '';
    final updated = row.updatedByName?.trim() ?? '';

    if (created.isEmpty && updated.isEmpty) return '—';

    final createdDate = _formatAuditDate(row.createdAt, auditDateFmt);
    if (updated.isNotEmpty && updated != created) {
      final editedDate = _formatAuditDate(row.updatedAt, auditDateFmt);
      final addedLines = _nameAndDateLines(created, createdDate);
      final editedLines = _nameAndDateLines(updated, editedDate, prefix: 'Edited');
      return '$addedLines\n$editedLines';
    }

    return _nameAndDateLines(created, createdDate);
  }

  String _nameAndDateLines(String name, String date, {String? prefix}) {
    final label = prefix != null ? '$prefix $name' : name;
    if (date.isEmpty) return label;
    if (name.isEmpty) return date;
    return '$label\n$date';
  }

  String _formatAuditDate(String? raw, DateFormat? auditDateFmt) {
    if (raw == null || raw.isEmpty || auditDateFmt == null) return '';
    try {
      return auditDateFmt.format(DateTime.parse(raw));
    } catch (_) {
      return '';
    }
  }
}
