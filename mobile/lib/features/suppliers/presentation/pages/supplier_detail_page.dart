import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:purchase_journal/config/routes/route_names.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/config/themes/app_theme.dart';
import 'package:purchase_journal/core/utils/currency_display.dart';
import 'package:purchase_journal/core/widgets/debt_summary_row.dart';
import 'package:purchase_journal/core/widgets/journal_widgets.dart';
import 'package:purchase_journal/features/suppliers/data/datasources/supplier_remote_datasource.dart';
import 'package:purchase_journal/features/suppliers/data/models/supplier_statement_model.dart';
import 'package:purchase_journal/features/suppliers/presentation/widgets/account_statement_table.dart';
import 'package:purchase_journal/features/suppliers/presentation/widgets/record_payment_dialog.dart';
import 'package:purchase_journal/features/suppliers/presentation/widgets/statement_export_actions.dart';
import 'package:purchase_journal/injection_container.dart';

class SupplierDetailPage extends StatefulWidget {
  const SupplierDetailPage({super.key, required this.supplierId});

  final String supplierId;

  @override
  State<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends State<SupplierDetailPage> {
  SupplierStatementModel? _statement;
  bool _loading = true;
  String? _error;

  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final statement = await sl<SupplierRemoteDataSource>().getStatement(widget.supplierId);
      if (!mounted) return;
      setState(() => _statement = statement);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recordPayment() async {
    final saved = await RecordPaymentDialog.show(context, supplierId: widget.supplierId);
    if (saved && mounted) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded')),
      );
    }
  }

  Future<void> _addPurchase() async {
    await context.push('${RouteNames.purchaseNew}?supplierId=${widget.supplierId}');
    _load();
  }

  // Scan receipt — disabled until release build supports ML Kit R8.
  // Future<void> _addPurchase({required bool scan}) async {
  //   final route = scan
  //       ? '${RouteNames.purchaseScan}?supplierId=${widget.supplierId}'
  //       : '${RouteNames.purchaseNew}?supplierId=${widget.supplierId}';
  //   await context.push(route);
  //   _load();
  // }
  //
  // void _showAddPurchaseOptions() {
  //   showModalBottomSheet<void>(
  //     context: context,
  //     backgroundColor: AppColors.surface,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
  //     ),
  //     builder: (context) => SafeArea(
  //       child: Padding(
  //         padding: const EdgeInsets.all(AppSpacing.page),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: [
  //             Text(
  //               'Add purchase',
  //               style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  //             ),
  //             const SizedBox(height: 12),
  //             ListTile(
  //               leading: const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
  //               title: const Text('Scan receipt'),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 _addPurchase(scan: true);
  //               },
  //             ),
  //             ListTile(
  //               leading: const Icon(Icons.edit_note_outlined, color: AppColors.primary),
  //               title: const Text('Enter manually'),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 _addPurchase(scan: false);
  //               },
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final currency = journalCurrency;
    final statement = _statement;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(statement?.supplierName ?? 'Supplier'),
        actions: [
          if (statement != null)
            StatementExportButton(
              statement: statement,
              dateFmt: _dateFmt,
              currency: currency,
              iconColor: Colors.white,
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Tooltip(
            message: 'Record payment',
            child: FloatingActionButton.small(
              heroTag: 'payment',
              onPressed: _recordPayment,
              backgroundColor: AppColors.success,
              child: const Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Tooltip(
            message: 'Add purchase',
            child: FloatingActionButton(
              heroTag: 'purchase',
              onPressed: _addPurchase,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.page),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                    ),
                  ],
                )
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    children: [
                      StatHeroCard(
                        label: 'Outstanding debt',
                        amount: statement?.summary.totalDebt ?? 0,
                        subtitle: '${statement?.summary.purchaseCount ?? 0} purchases',
                        icon: Icons.storefront_outlined,
                      ),
                      const SizedBox(height: 12),
                      DebtSummaryRow(
                        purchased: statement?.summary.totalPurchased ?? 0,
                        paid: statement?.summary.totalPaid ?? 0,
                      ),
                      const SizedBox(height: AppSpacing.section),
                      Row(
                        children: [
                          Expanded(
                            child: ActionChipButton(
                              icon: Icons.shopping_cart_outlined,
                              label: 'Add purchase',
                              filled: true,
                              onTap: _addPurchase,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ActionChipButton(
                              icon: Icons.payments_outlined,
                              label: 'Record payment',
                              onTap: _recordPayment,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.section),
                      SectionTitle(
                        'Account statement',
                        trailing: statement == null
                            ? null
                            : StatementExportButton(
                                statement: statement,
                                dateFmt: _dateFmt,
                                currency: currency,
                                compact: true,
                              ),
                      ),
                      if (statement == null)
                        const SizedBox.shrink()
                      else
                        AccountStatementTable(
                          statement: statement,
                          currency: currency,
                          dateFmt: _dateFmt,
                        ),
                    ],
                  ),
                ),
    );
  }
}
