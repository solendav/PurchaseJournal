import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/features/suppliers/data/models/supplier_statement_model.dart';
import 'package:purchase_journal/features/suppliers/presentation/utils/statement_table_logic.dart';

class AccountStatementTable extends StatelessWidget {
  const AccountStatementTable({
    super.key,
    required this.statement,
    required this.currency,
    required this.dateFmt,
  });

  final SupplierStatementModel statement;
  final NumberFormat currency;
  final DateFormat dateFmt;

  static const _headerStyle = TextStyle(fontWeight: FontWeight.w700, fontSize: 13);
  static const _cellStyle = TextStyle(fontSize: 13);
  static const _auditStyle = TextStyle(fontSize: 11, color: AppColors.muted, height: 1.35);
  static const _moneyStyle = TextStyle(fontSize: 13, fontFeatures: [FontFeature.tabularFigures()]);
  static final _auditDateFmt = DateFormat('dd/MM/yyyy');

  static const _columnWidths = <int, TableColumnWidth>{
    0: FixedColumnWidth(96),
    1: FixedColumnWidth(180),
    2: FixedColumnWidth(56),
    3: FixedColumnWidth(96),
    4: FixedColumnWidth(100),
    5: FixedColumnWidth(100),
    6: FixedColumnWidth(100),
    7: FixedColumnWidth(116),
    8: FixedColumnWidth(168),
  };

  static const _tableBorder = TableBorder(
    horizontalInside: BorderSide(color: AppColors.border, width: 0.5),
    verticalInside: BorderSide(color: AppColors.border, width: 0.5),
  );

  StatementTableLogic get _logic => StatementTableLogic(
        rows: statement.rows,
        dateFmt: dateFmt,
        currency: currency,
      );

  @override
  Widget build(BuildContext context) {
    final rows = statement.rows;
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No records yet', style: TextStyle(color: AppColors.muted))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            columnWidths: _columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            border: _tableBorder,
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08)),
                children: [
                  _headerCell('Date'),
                  _headerCell('Item'),
                  _headerCell('Qty', align: TextAlign.right),
                  _headerCell('Price', align: TextAlign.right),
                  _headerCell('Subtotal', align: TextAlign.right),
                  _headerCell('Day Total', align: TextAlign.right),
                  _headerCell('Paid', align: TextAlign.right),
                  _headerCell('Debt', align: TextAlign.right),
                  _headerCell('Recorded by'),
                ],
              ),
              ...rows.asMap().entries.map((e) => _dataRow(e.value, e.key)),
              TableRow(
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05)),
                children: [
                  _cell('TOTAL', style: _headerStyle),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _moneyCell(currency.format(statement.summary.totalPurchased), bold: true),
                  _cell(''),
                  _moneyCell(
                    currency.format(statement.summary.totalPaid),
                    bold: true,
                    color: AppColors.success,
                  ),
                  _moneyCell(
                    currency.format(statement.summary.totalDebt),
                    bold: true,
                    color: statement.summary.totalDebt > 0 ? AppColors.danger : AppColors.text,
                  ),
                  _cell(''),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _dataRow(StatementRowModel row, int index) {
    final dailyTotals = _logic.dailyTotalByRowIndex;
    final isPayment = row.isPayment;

    return TableRow(
      decoration: isPayment
          ? BoxDecoration(color: AppColors.accent.withValues(alpha: 0.06))
          : null,
      children: [
        _cell(_logic.dateLabel(index)),
        _cell(_logic.itemLabel(row)),
        _cell(isPayment ? '' : '${row.quantity ?? ''}', align: TextAlign.right),
        _moneyCell(_logic.unitPriceLabel(row)),
        _moneyCell(_logic.money(row.subtotal) ?? ''),
        _moneyCell(_logic.money(dailyTotals[index]) ?? ''),
        _moneyCell(
          isPayment ? (_logic.money(row.paid) ?? '') : '',
          color: isPayment ? AppColors.success : null,
        ),
        _moneyCell(
          _logic.money(row.balance) ?? '',
          bold: true,
          color: row.balance > 0 ? AppColors.danger : AppColors.text,
        ),
        _auditCell(row),
      ],
    );
  }

  Widget _headerCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(text, style: _headerStyle, textAlign: align),
    );
  }

  Widget _cell(
    String text, {
    TextAlign align = TextAlign.left,
    TextStyle? style,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: style ?? _cellStyle,
        textAlign: align,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _moneyCell(
    String text, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: _moneyStyle.copyWith(
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          color: color,
        ),
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  Widget _auditCell(StatementRowModel row) {
    final auditText = _logic.auditLabel(row, auditDateFmt: _auditDateFmt);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        auditText,
        style: _auditStyle,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
