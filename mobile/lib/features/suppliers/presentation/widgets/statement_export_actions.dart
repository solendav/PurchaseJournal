import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/features/suppliers/data/models/supplier_statement_model.dart';
import 'package:purchase_journal/features/suppliers/presentation/utils/statement_exporter.dart';

enum StatementExportFormat { excel, pdf }

Future<void> exportSupplierStatement(
  BuildContext context, {
  required SupplierStatementModel statement,
  required StatementExportFormat format,
  required DateFormat dateFmt,
  required NumberFormat currency,
}) async {
  try {
    final exporter = StatementExporter(
      statement: statement,
      dateFmt: dateFmt,
      currency: currency,
    );
    if (format == StatementExportFormat.excel) {
      await exporter.exportExcel();
    } else {
      await exporter.exportPdf();
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb ? '${format.name.toUpperCase()} download started' : '${format.name.toUpperCase()} ready to share',
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
}

class StatementExportButton extends StatelessWidget {
  const StatementExportButton({
    super.key,
    required this.statement,
    required this.dateFmt,
    required this.currency,
    this.iconColor,
    this.compact = false,
  });

  final SupplierStatementModel statement;
  final DateFormat dateFmt;
  final NumberFormat currency;
  final Color? iconColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (statement.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return PopupMenuButton<StatementExportFormat>(
        tooltip: 'Export statement',
        offset: const Offset(0, 40),
        onSelected: (format) => exportSupplierStatement(
          context,
          statement: statement,
          format: format,
          dateFmt: dateFmt,
          currency: currency,
        ),
        itemBuilder: (context) => _exportMenuItems,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Export',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopupMenuButton<StatementExportFormat>(
      tooltip: 'Export statement',
      icon: Icon(Icons.download_outlined, color: iconColor ?? AppColors.primary),
      onSelected: (format) => exportSupplierStatement(
        context,
        statement: statement,
        format: format,
        dateFmt: dateFmt,
        currency: currency,
      ),
      itemBuilder: (context) => _exportMenuItems,
    );
  }

  static const _exportMenuItems = [
    PopupMenuItem(
      value: StatementExportFormat.excel,
      child: Row(
        children: [
          Icon(Icons.table_chart_outlined),
          SizedBox(width: 12),
          Text('Export Excel'),
        ],
      ),
    ),
    PopupMenuItem(
      value: StatementExportFormat.pdf,
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_outlined),
          SizedBox(width: 12),
          Text('Export PDF'),
        ],
      ),
    ),
  ];
}
