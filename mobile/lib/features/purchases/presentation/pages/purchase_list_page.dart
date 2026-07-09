import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:purchase_journal/config/routes/route_names.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/config/themes/app_theme.dart';
import 'package:purchase_journal/core/utils/date_display.dart';
import 'package:purchase_journal/core/widgets/journal_widgets.dart';
import 'package:purchase_journal/features/purchases/data/datasources/purchase_remote_datasource.dart';
import 'package:purchase_journal/features/purchases/data/models/payment_model.dart';
import 'package:purchase_journal/features/purchases/data/models/purchase_model.dart';
import 'package:purchase_journal/features/suppliers/data/datasources/payment_remote_datasource.dart';
import 'package:purchase_journal/features/suppliers/presentation/widgets/record_payment_dialog.dart';
import 'package:purchase_journal/injection_container.dart';

class PurchaseListPage extends StatefulWidget {
  const PurchaseListPage({super.key});

  @override
  State<PurchaseListPage> createState() => _PurchaseListPageState();
}

class _PurchaseListPageState extends State<PurchaseListPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _purchasesTabKey = GlobalKey<_PurchasesTabState>();
  final _paymentsTabKey = GlobalKey<_PaymentsTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _recordPayment() async {
    final saved = await RecordPaymentDialog.show(context);
    if (!saved || !mounted) return;
    _paymentsTabKey.currentState?.reload();
    if (_tabController.index != 1) {
      _tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPaymentsTab = _tabController.index == 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Purchases'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Purchases'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      floatingActionButton: onPaymentsTab
          ? FloatingActionButton(
              heroTag: 'payment',
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              onPressed: _recordPayment,
              child: const Icon(Icons.payments_outlined),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Record payment',
                  child: FloatingActionButton.small(
                    heroTag: 'payment',
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    onPressed: _recordPayment,
                    child: const Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Tooltip(
                  message: 'Scan receipt',
                  child: FloatingActionButton.small(
                    heroTag: 'scan',
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    onPressed: () async {
                      await context.push(RouteNames.purchaseScan);
                      if (mounted) _purchasesTabKey.currentState?.reload();
                    },
                    child: const Icon(Icons.document_scanner_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Tooltip(
                  message: 'Add purchase',
                  child: FloatingActionButton(
                    heroTag: 'add',
                    onPressed: () async {
                      await context.push(RouteNames.purchaseNew);
                      if (mounted) _purchasesTabKey.currentState?.reload();
                    },
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                ),
              ],
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PurchasesTab(key: _purchasesTabKey),
          _PaymentsTab(key: _paymentsTabKey),
        ],
      ),
    );
  }
}

class _PurchasesTab extends StatefulWidget {
  const _PurchasesTab({super.key});

  @override
  State<_PurchasesTab> createState() => _PurchasesTabState();
}

class _PurchasesTabState extends State<_PurchasesTab> with AutomaticKeepAliveClientMixin {
  List<PurchaseModel> _purchases = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _openPurchase(PurchaseModel purchase) async {
    final changed = await context.push<bool>('${RouteNames.purchaseDetail}/${purchase.id}');
    if (changed == true && mounted) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final purchases = await sl<PurchaseRemoteDataSource>().list();
      if (!mounted) return;
      setState(() => _purchases = purchases);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final metaDate = DateFormat('dd/MM/yyyy HH:mm');

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _purchases.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Text(
                        'No purchases yet.\nScan a receipt or add manually.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, height: 1.5),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  itemCount: _purchases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final purchase = _purchases[index];
                    return JournalCard(
                      onTap: () => _openPurchase(purchase),
                      accent: AppColors.accent,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  purchase.supplierName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateDisplay.formatPurchaseDate(purchase.purchaseDate)} · ${purchase.items.length} items',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                ),
                                if ((purchase.createdByName ?? '').isNotEmpty && purchase.createdAt.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Added by ${purchase.createdByName} · ${_formatDate(metaDate, purchase.createdAt)}',
                                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currency.format(purchase.itemsTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Text(
                                'purchased',
                                style: TextStyle(color: AppColors.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  static String _formatDate(DateFormat fmt, String raw) {
    try {
      return fmt.format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _PaymentsTab extends StatefulWidget {
  const _PaymentsTab({super.key});

  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> with AutomaticKeepAliveClientMixin {
  List<PaymentModel> _payments = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final payments = await sl<PaymentRemoteDataSource>().list();
      if (!mounted) return;
      setState(() => _payments = payments);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPayment(PaymentModel payment) async {
    final changed = await context.push<bool>('${RouteNames.paymentDetail}/${payment.id}');
    if (changed == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final metaDate = DateFormat('dd/MM/yyyy HH:mm');

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _payments.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Text(
                        'No payments yet.\nRecord a payment to a supplier.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, height: 1.5),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  itemCount: _payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    return JournalCard(
                      onTap: () => _openPayment(payment),
                      accent: AppColors.success,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  payment.supplierName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateDisplay.formatPurchaseDate(payment.paymentDate),
                                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                ),
                                if (payment.notes.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    payment.notes,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                  ),
                                ],
                                if ((payment.createdByName ?? '').isNotEmpty && payment.createdAt.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Recorded by ${payment.createdByName} · ${_formatDate(metaDate, payment.createdAt)}',
                                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currency.format(payment.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                              const Text(
                                'paid',
                                style: TextStyle(color: AppColors.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  static String _formatDate(DateFormat fmt, String raw) {
    try {
      return fmt.format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}
