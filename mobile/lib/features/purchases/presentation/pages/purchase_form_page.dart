import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/config/themes/app_theme.dart';
import 'package:purchase_journal/core/error/error_message_mapper.dart';
import 'package:purchase_journal/core/widgets/journal_widgets.dart';
import 'package:purchase_journal/core/widgets/purchase_date_field.dart';
import 'package:purchase_journal/features/purchases/data/datasources/purchase_remote_datasource.dart';
import 'package:purchase_journal/features/suppliers/data/datasources/supplier_remote_datasource.dart';
import 'package:purchase_journal/features/suppliers/data/models/supplier_model.dart';
import 'package:purchase_journal/injection_container.dart';

class _LineItemRow {
  _LineItemRow()
      : description = TextEditingController(),
        quantity = TextEditingController(text: '1'),
        unitPrice = TextEditingController(text: '0');

  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unitPrice;

  void dispose() {
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
  }

  Map<String, dynamic> toJson() {
    final qty = double.tryParse(quantity.text) ?? 1;
    final price = double.tryParse(unitPrice.text) ?? 0;
    return {
      'description': description.text.trim(),
      'quantity': qty,
      'unitPrice': price,
      'lineTotal': qty * price,
    };
  }
}

class PurchaseFormPage extends StatefulWidget {
  const PurchaseFormPage({super.key, this.initialSupplierId, this.purchaseId});

  final String? initialSupplierId;
  final String? purchaseId;

  bool get isEditing => purchaseId != null && purchaseId!.isNotEmpty;

  @override
  State<PurchaseFormPage> createState() => _PurchaseFormPageState();
}

class _PurchaseFormPageState extends State<PurchaseFormPage> {
  final _picker = ImagePicker();
  final _notes = TextEditingController();
  final _items = <_LineItemRow>[_LineItemRow()];

  List<SupplierModel> _suppliers = [];
  SupplierModel? _selectedSupplier;
  DateTime _purchaseDate = DateTime.now();
  XFile? _receiptImage;
  Uint8List? _receiptPreviewBytes;
  String _existingReceiptPath = '';
  bool _loading = false;
  bool _bootstrapping = false;

  bool get _isEditing => widget.isEditing;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _bootstrapping = true);
    try {
      await _loadSuppliers();
      if (_isEditing) {
        await _loadPurchase();
      }
    } finally {
      if (mounted) setState(() => _bootstrapping = false);
    }
  }

  Future<void> _loadPurchase() async {
    final purchase = await sl<PurchaseRemoteDataSource>().getById(widget.purchaseId!);
    if (!mounted) return;

    for (final row in _items) {
      row.dispose();
    }

    setState(() {
      _selectedSupplier = _suppliers.cast<SupplierModel?>().firstWhere(
            (s) => s?.id == purchase.supplierId,
            orElse: () => _suppliers.isNotEmpty ? _suppliers.first : null,
          );
      _purchaseDate = DateTime.tryParse(purchase.purchaseDate) ?? DateTime.now();
      _notes.text = purchase.notes;
      _existingReceiptPath = purchase.receiptImagePath;
      _items
        ..clear()
        ..addAll(
          purchase.items.map((item) {
            final row = _LineItemRow();
            row.description.text = item.description;
            row.quantity.text = item.quantity.toString();
            row.unitPrice.text = item.unitPrice.toString();
            return row;
          }),
        );
      if (_items.isEmpty) {
        _items.add(_LineItemRow());
      }
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    final suppliers = await sl<SupplierRemoteDataSource>().list();
    if (!mounted) return;
    setState(() {
      _suppliers = suppliers;
      if (widget.initialSupplierId != null) {
        _selectedSupplier = suppliers.cast<SupplierModel?>().firstWhere(
              (s) => s?.id == widget.initialSupplierId,
              orElse: () => suppliers.isNotEmpty ? suppliers.first : null,
            );
      }
    });
  }

  double get _itemsTotal {
    return _items.fold<double>(0, (sum, row) {
      final data = row.toJson();
      return sum + (data['lineTotal'] as double);
    });
  }

  Future<void> _pickReceipt(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _receiptImage = picked;
      _receiptPreviewBytes = bytes;
    });
  }

  void _removeReceipt() {
    setState(() {
      _receiptImage = null;
      _receiptPreviewBytes = null;
    });
  }

  Future<void> _save() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a supplier')),
      );
      return;
    }

    final items = _items.map((e) => e.toJson()).where((e) => (e['description'] as String).isNotEmpty).toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      var receiptPath = _existingReceiptPath;
      if (_receiptImage != null) {
        receiptPath = await sl<PurchaseRemoteDataSource>().uploadReceiptFile(_receiptImage!);
      }

      final body = {
        'supplierId': _selectedSupplier!.id,
        'purchaseDate': PurchaseDateField.toApiDate(_purchaseDate),
        'amountPaid': 0,
        'notes': _notes.text.trim(),
        'receiptImagePath': receiptPath,
        'items': items,
      };

      if (_isEditing) {
        await sl<PurchaseRemoteDataSource>().update(widget.purchaseId!, body);
      } else {
        await sl<PurchaseRemoteDataSource>().create(body);
      }
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessageMapper.message(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapping) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit purchase' : 'New purchase')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit purchase' : 'New purchase')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          const SectionTitle('Details'),
          JournalCard(
            child: Column(
              children: [
                DropdownButtonFormField<SupplierModel>(
                  initialValue: _selectedSupplier,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                  items: _suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (value) => setState(() => _selectedSupplier = value),
                ),
                const SizedBox(height: 14),
                PurchaseDateField(
                  date: _purchaseDate,
                  onChanged: (d) => setState(() => _purchaseDate = d),
                ),
                const SizedBox(height: 14),
                Text(
                  'Purchase total: ${NumberFormat('#,##0.00').format(_itemsTotal)} ETB',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Record payments separately from the supplier account.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          const SectionTitle('Receipt image (optional)'),
          JournalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_receiptPreviewBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _receiptPreviewBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _removeReceipt,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Remove image'),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ActionChipButton(
                        icon: Icons.photo_camera_outlined,
                        label: 'Camera',
                        filled: _receiptPreviewBytes == null,
                        onTap: () => _pickReceipt(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionChipButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: () => _pickReceipt(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          SectionTitle(
            'Line items',
            trailing: TextButton.icon(
              onPressed: () => setState(() => _items.add(_LineItemRow())),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Add'),
            ),
          ),
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: JournalCard(
                accent: AppColors.accent,
                child: Column(
                  children: [
                    TextField(
                      controller: row.description,
                      decoration: const InputDecoration(labelText: 'Item name'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: row.quantity,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Qty'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: row.unitPrice,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Price'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (_items.length > 1)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                row.dispose();
                                _items.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.close, color: AppColors.muted),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.section),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_isEditing ? 'Save changes' : 'Save purchase'),
          ),
        ],
      ),
    );
  }
}
