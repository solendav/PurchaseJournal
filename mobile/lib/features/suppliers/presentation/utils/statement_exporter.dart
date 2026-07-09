import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:purchase_journal/core/utils/file_download.dart';
import 'package:purchase_journal/features/suppliers/data/models/supplier_statement_model.dart';
import 'package:purchase_journal/features/suppliers/presentation/utils/statement_table_logic.dart';

class StatementExporter {
  StatementExporter({
    required this.statement,
    required this.dateFmt,
    required this.currency,
  });

  final SupplierStatementModel statement;
  final DateFormat dateFmt;
  final NumberFormat currency;

  StatementTableLogic get _logic => StatementTableLogic(
        rows: statement.rows,
        dateFmt: dateFmt,
        currency: currency,
      );

  String get _title => 'Supplier Statement — ${statement.supplierName}';

  String get _fileBase {
    final slug = statement.supplierName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    return 'purchase_journal_statement_${slug.isEmpty ? 'supplier' : slug}_$stamp';
  }

  Future<void> exportExcel() async {
    if (statement.rows.isEmpty) throw StateError('No statement rows to export');

    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet();
    if (defaultName != null) excel.rename(defaultName, 'Statement');
    final sheet = excel['Statement'];

    sheet.appendRow([TextCellValue(_title)]);
    sheet.appendRow([
      TextCellValue('Total Purchased'),
      TextCellValue(currency.format(statement.summary.totalPurchased)),
    ]);
    sheet.appendRow([
      TextCellValue('Total Paid'),
      TextCellValue(currency.format(statement.summary.totalPaid)),
    ]);
    sheet.appendRow([
      TextCellValue('Debt'),
      TextCellValue(currency.format(statement.summary.totalDebt)),
    ]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Item'),
      TextCellValue('Qty'),
      TextCellValue('Price'),
      TextCellValue('Subtotal'),
      TextCellValue('Day Total'),
      TextCellValue('Paid'),
      TextCellValue('Debt'),
      TextCellValue('Recorded by'),
    ]);

    final dailyTotals = _logic.dailyTotalByRowIndex;
    final auditDateFmt = DateFormat('dd/MM/yyyy');
    for (var i = 0; i < statement.rows.length; i++) {
      final row = statement.rows[i];
      sheet.appendRow([
        TextCellValue(_logic.dateLabel(i)),
        TextCellValue(_logic.itemLabel(row)),
        TextCellValue(row.isPayment ? '' : '${row.quantity ?? ''}'),
        TextCellValue(_logic.unitPriceLabel(row)),
        TextCellValue(_logic.money(row.subtotal) ?? ''),
        TextCellValue(_logic.money(dailyTotals[i]) ?? ''),
        TextCellValue(row.isPayment ? (_logic.money(row.paid) ?? '') : ''),
        TextCellValue(_logic.money(row.balance) ?? ''),
        TextCellValue(_logic.auditLabel(row, auditDateFmt: auditDateFmt).replaceAll('\n', ' · ')),
      ]);
    }

    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(currency.format(statement.summary.totalPurchased)),
      TextCellValue(''),
      TextCellValue(currency.format(statement.summary.totalPaid)),
      TextCellValue(currency.format(statement.summary.totalDebt)),
      TextCellValue(''),
    ]);

    final bytes = excel.encode();
    if (bytes == null) throw StateError('Failed to generate Excel file');

    await downloadFile(
      bytes: Uint8List.fromList(bytes),
      filename: '$_fileBase.xlsx',
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      subject: _title,
    );
  }

  Future<void> exportPdf() async {
    if (statement.rows.isEmpty) throw StateError('No statement rows to export');

    final dailyTotals = _logic.dailyTotalByRowIndex;
    final auditDateFmt = DateFormat('dd/MM/yyyy');
    final tableData = <List<String>>[];

    for (var i = 0; i < statement.rows.length; i++) {
      final row = statement.rows[i];
      tableData.add([
        _logic.dateLabel(i),
        _logic.itemLabel(row),
        row.isPayment ? '' : '${row.quantity ?? ''}',
        _logic.unitPriceLabel(row),
        _logic.money(row.subtotal) ?? '',
        _logic.money(dailyTotals[i]) ?? '',
        row.isPayment ? (_logic.money(row.paid) ?? '') : '',
        _logic.money(row.balance) ?? '',
        _logic.auditLabel(row, auditDateFmt: auditDateFmt).replaceAll('\n', ' · '),
      ]);
    }

    tableData.add([
      'TOTAL',
      '',
      '',
      '',
      currency.format(statement.summary.totalPurchased),
      '',
      currency.format(statement.summary.totalPaid),
      currency.format(statement.summary.totalDebt),
      '',
    ]);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(_title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(
            'Purchased: ${currency.format(statement.summary.totalPurchased)}  '
            'Paid: ${currency.format(statement.summary.totalPaid)}  '
            'Debt: ${currency.format(statement.summary.totalDebt)}',
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Item', 'Qty', 'Price', 'Subtotal', 'Day Total', 'Paid', 'Debt', 'Recorded by'],
            data: tableData,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    await downloadFile(
      bytes: await doc.save(),
      filename: '$_fileBase.pdf',
      mimeType: 'application/pdf',
      subject: _title,
    );
  }
}
