import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:purchase_journal/config/routes/route_names.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/config/themes/app_theme.dart';
import 'package:purchase_journal/core/auth/auth_session.dart';
import 'package:purchase_journal/core/error/error_message_mapper.dart';
import 'package:purchase_journal/core/utils/date_display.dart';
import 'package:purchase_journal/core/widgets/journal_widgets.dart';
import 'package:purchase_journal/core/widgets/owner_record_actions.dart';
import 'package:purchase_journal/features/purchases/data/datasources/purchase_remote_datasource.dart';
import 'package:purchase_journal/features/purchases/data/models/purchase_model.dart';
import 'package:purchase_journal/injection_container.dart';

class PurchaseDetailPage extends StatefulWidget {
  const PurchaseDetailPage({super.key, required this.purchaseId});

  final String purchaseId;

  @override
  State<PurchaseDetailPage> createState() => _PurchaseDetailPageState();
}

class _PurchaseDetailPageState extends State<PurchaseDetailPage> {
  PurchaseModel? _purchase;
  bool _loading = true;
  bool _deleting = false;
  String? _error;

  AuthSession get _auth => sl<AuthSession>();

  final _currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
  final _metaDate = DateFormat('dd/MM/yyyy HH:mm');

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
      final purchase = await sl<PurchaseRemoteDataSource>().getById(widget.purchaseId);
      if (!mounted) return;
      setState(() => _purchase = purchase);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ErrorMessageMapper.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEdit() async {
    final changed = await context.push<bool>(
      '${RouteNames.purchaseDetail}/${widget.purchaseId}/edit',
    );
    if (changed == true && mounted) _load();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete purchase?'),
        content: const Text('This purchase and its line items will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await sl<PurchaseRemoteDataSource>().delete(widget.purchaseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase deleted')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessageMapper.message(e))),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _formatMeta(String raw) {
    try {
      return _metaDate.format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final isOwner = _auth.user?.isOwner ?? false;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Purchase')),
          body: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
                            const SizedBox(height: 16),
                            FilledButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      ),
                    )
                  : _buildBody(isOwner),
        );
      },
    );
  }

  Widget _buildBody(bool isOwner) {
    final purchase = _purchase!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        JournalCard(
          accent: AppColors.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                purchase.supplierName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _currency.format(purchase.itemsTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateDisplay.formatPurchaseDate(purchase.purchaseDate),
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Line items'),
        ...purchase.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: JournalCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          '${item.quantity} × ${_currency.format(item.unitPrice)}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _currency.format(item.lineTotal),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (purchase.notes.isNotEmpty) ...[
          const SizedBox(height: 10),
          const SectionTitle('Notes'),
          JournalCard(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(purchase.notes),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const SectionTitle('Activity'),
        JournalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((purchase.createdByName ?? '').isNotEmpty)
                _auditRow('Added by', '${purchase.createdByName} · ${_formatMeta(purchase.createdAt)}'),
              if ((purchase.updatedByName ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _auditRow('Last edited by', '${purchase.updatedByName} · ${_formatMeta(purchase.updatedAt)}'),
                ),
            ],
          ),
        ),
        if (isOwner)
          OwnerRecordActions(
            deleting: _deleting,
            onEdit: _openEdit,
            onDelete: _delete,
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.push('/suppliers/${purchase.supplierId}'),
          icon: const Icon(Icons.store_outlined, size: 18),
          label: const Text('View supplier account'),
        ),
      ],
    );
  }

  Widget _auditRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
