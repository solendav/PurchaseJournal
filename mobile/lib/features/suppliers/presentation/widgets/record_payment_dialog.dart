import 'package:flutter/material.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/config/themes/app_theme.dart';
import 'package:purchase_journal/core/widgets/purchase_date_field.dart';
import 'package:purchase_journal/features/suppliers/data/datasources/payment_remote_datasource.dart';
import 'package:purchase_journal/features/suppliers/data/datasources/supplier_remote_datasource.dart';
import 'package:purchase_journal/features/suppliers/data/models/supplier_model.dart';
import 'package:purchase_journal/injection_container.dart';

class RecordPaymentDialog extends StatefulWidget {
  const RecordPaymentDialog({super.key, this.supplierId});

  final String? supplierId;

  static Future<bool> show(BuildContext context, {String? supplierId}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => RecordPaymentDialog(supplierId: supplierId),
    );
    return result == true;
  }

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  List<SupplierModel> _suppliers = [];
  SupplierModel? _selectedSupplier;
  DateTime _paymentDate = DateTime.now();
  bool _loading = false;
  bool _loadingSuppliers = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await sl<SupplierRemoteDataSource>().list();
      if (!mounted) return;
      setState(() {
        _suppliers = suppliers;
        if (widget.supplierId != null) {
          _selectedSupplier = suppliers.cast<SupplierModel?>().firstWhere(
                (s) => s?.id == widget.supplierId,
                orElse: () => suppliers.isNotEmpty ? suppliers.first : null,
              );
        }
      });
    } finally {
      if (mounted) setState(() => _loadingSuppliers = false);
    }
  }

  Future<void> _save() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a supplier')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await sl<PaymentRemoteDataSource>().create(
        supplierId: _selectedSupplier!.id,
        amount: amount,
        paymentDate: PurchaseDateField.toApiDate(_paymentDate),
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      title: const Text('Record payment'),
      content: _loadingSuppliers
          ? const SizedBox(
              width: 220,
              height: 80,
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.supplierId == null) ...[
                    DropdownButtonFormField<SupplierModel>(
                      initialValue: _selectedSupplier,
                      decoration: const InputDecoration(labelText: 'Supplier'),
                      items: _suppliers
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedSupplier = value),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount paid (ETB)'),
                    autofocus: widget.supplierId != null,
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
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save payment'),
        ),
      ],
    );
  }
}
