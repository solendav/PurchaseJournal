import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/config/themes/app_theme.dart';
import 'package:purchase_journal/core/auth/auth_session.dart';
import 'package:purchase_journal/core/error/error_message_mapper.dart';
import 'package:purchase_journal/core/utils/date_display.dart';
import 'package:purchase_journal/core/widgets/owner_record_actions.dart';
import 'package:purchase_journal/core/widgets/journal_widgets.dart';
import 'package:purchase_journal/core/widgets/purchase_date_field.dart';
import 'package:purchase_journal/features/purchases/data/models/payment_model.dart';
import 'package:purchase_journal/features/suppliers/data/datasources/payment_remote_datasource.dart';
import 'package:purchase_journal/injection_container.dart';

class PaymentDetailPage extends StatefulWidget {
  const PaymentDetailPage({super.key, required this.paymentId});

  final String paymentId;

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  PaymentModel? _payment;
  bool _loading = true;
  String? _error;

  bool _editing = false;
  bool _saving = false;
  bool _deleting = false;

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();

  AuthSession get _auth => sl<AuthSession>();

  final _metaDate = DateFormat('dd/MM/yyyy HH:mm');
  final _currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payment = await sl<PaymentRemoteDataSource>().getById(widget.paymentId);
      if (!mounted) return;
      setState(() {
        _payment = payment;
        _syncControllers(payment);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ErrorMessageMapper.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _syncControllers(PaymentModel payment) {
    _amountController.text = payment.amount.toStringAsFixed(2);
    _notesController.text = payment.notes;
    _paymentDate = _parseDate(payment.paymentDate) ?? DateTime.now();
  }

  DateTime? _parseDate(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  String _formatMeta(String raw) {
    try {
      return _metaDate.format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await sl<PaymentRemoteDataSource>().update(
        widget.paymentId,
        amount: amount,
        paymentDate: PurchaseDateField.toApiDate(_paymentDate),
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _payment = updated;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessageMapper.message(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete payment?'),
        content: const Text('This payment will be removed from the supplier account.'),
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
      await sl<PaymentRemoteDataSource>().delete(widget.paymentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment deleted')),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final isOwner = _auth.user?.isOwner ?? false;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Payment'),
          ),
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
    final payment = _payment!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        JournalCard(
          accent: AppColors.success,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.supplierName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _currency.format(payment.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateDisplay.formatPurchaseDate(payment.paymentDate),
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Details'),
        JournalCard(
          child: _editing ? _buildEditForm() : _buildReadOnlyDetails(payment),
        ),
        if (!_editing) ...[
          const SizedBox(height: 20),
          const SectionTitle('Activity'),
          JournalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((payment.createdByName ?? '').isNotEmpty)
                  _auditRow('Recorded by', '${payment.createdByName} · ${_formatMeta(payment.createdAt)}'),
                if ((payment.updatedByName ?? '').isNotEmpty && (payment.updatedAt ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _auditRow('Last edited by', '${payment.updatedByName} · ${_formatMeta(payment.updatedAt!)}'),
                  ),
              ],
            ),
          ),
        ],
        if (_editing) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          setState(() {
                            _editing = false;
                            _syncControllers(payment);
                          });
                        },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ],
        if (isOwner && !_editing)
          OwnerRecordActions(
            deleting: _deleting,
            editing: _editing,
            onEdit: () => setState(() => _editing = true),
            onDelete: _delete,
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

  Widget _buildReadOnlyDetails(PaymentModel payment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow('Amount', _currency.format(payment.amount)),
        const SizedBox(height: 12),
        _detailRow('Payment date', DateDisplay.formatPurchaseDate(payment.paymentDate)),
        const SizedBox(height: 12),
        _detailRow('Notes', payment.notes.isEmpty ? '—' : payment.notes),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15)),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount paid (ETB)'),
        ),
        const SizedBox(height: 12),
        PurchaseDateField(
          label: 'Payment date',
          date: _paymentDate,
          onChanged: (d) => setState(() => _paymentDate = d),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
          maxLines: 3,
        ),
      ],
    );
  }
}
