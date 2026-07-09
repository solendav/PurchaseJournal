import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchase_journal/config/routes/route_names.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/config/themes/app_theme.dart';
import 'package:purchase_journal/core/utils/currency_display.dart';
import 'package:purchase_journal/core/widgets/journal_widgets.dart';
import 'package:purchase_journal/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:purchase_journal/features/suppliers/presentation/widgets/record_payment_dialog.dart';
import 'package:purchase_journal/injection_container.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  DashboardSummary? _summary;
  bool _loading = true;
  String? _error;

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
      final summary = await sl<DashboardRemoteDataSource>().getSummary();
      if (!mounted) return;
      setState(() => _summary = summary);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Purchase Journal'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: _loading
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
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    children: [
                      StatHeroCard(
                        label: 'Outstanding debt',
                        amount: _summary?.totalDebt ?? 0,
                        subtitle: '${_summary?.purchaseCount ?? 0} purchases recorded',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      const SizedBox(height: AppSpacing.section),
                      Row(
                        children: [
                          Expanded(
                            child: ActionChipButton(
                              icon: Icons.document_scanner_outlined,
                              label: 'Scan receipt',
                              filled: true,
                              onTap: () => context.push(RouteNames.purchaseScan),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ActionChipButton(
                              icon: Icons.shopping_cart_outlined,
                              label: 'Add purchase',
                              onTap: () => context.push(RouteNames.purchaseNew),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ActionChipButton(
                        icon: Icons.payments_outlined,
                        label: 'Record payment',
                        onTap: () => RecordPaymentDialog.show(context).then((saved) {
                          if (saved) _load();
                        }),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      const SectionTitle('Debt by supplier'),
                      if ((_summary?.bySupplier ?? []).isEmpty)
                        const JournalCard(
                          child: Text(
                            'No supplier records yet.\nAdd a supplier and record your first purchase.',
                            style: TextStyle(color: AppColors.muted, height: 1.5),
                          ),
                        )
                      else
                        ..._summary!.bySupplier.map(
                          (row) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: JournalCard(
                              onTap: () => context.push('/suppliers/${row.supplierId}'),
                              accent: row.totalDebt > 0 ? AppColors.danger : null,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                                    child: Text(
                                      row.supplierName.isNotEmpty ? row.supplierName[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          row.supplierName,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '${row.purchaseCount} purchases',
                                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  MetricAmountText(
                                    amount: row.totalDebt,
                                    alignment: Alignment.centerRight,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: row.totalDebt > 0 ? AppColors.danger : AppColors.success,
                                    ),
                                    suffixStyle: TextStyle(
                                      fontSize: 10,
                                      color: row.totalDebt > 0 ? AppColors.danger : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
