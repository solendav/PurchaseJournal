import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:purchase_journal/config/routes/route_names.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/config/themes/app_theme.dart';
import 'package:purchase_journal/core/receipt/receipt_parser.dart';
import 'package:purchase_journal/core/widgets/journal_widgets.dart';
import 'package:purchase_journal/core/widgets/purchase_date_field.dart';
import 'package:purchase_journal/features/purchases/data/datasources/purchase_remote_datasource.dart';
import 'package:purchase_journal/features/suppliers/data/datasources/supplier_remote_datasource.dart';
import 'package:purchase_journal/features/suppliers/data/models/supplier_model.dart';
import 'package:purchase_journal/injection_container.dart';

class ScanReceiptPage extends StatefulWidget {
  const ScanReceiptPage({super.key, this.initialSupplierId});

  final String? initialSupplierId;

  @override
  State<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends State<ScanReceiptPage> {
  final _picker = ImagePicker();
  final _notes = TextEditingController();

  List<SupplierModel> _suppliers = [];
  SupplierModel? _selectedSupplier;
  ParsedReceipt? _parsed;
  String? _imagePath;
  String? _uploadedPath;
  DateTime _purchaseDate = DateTime.now();
  bool _loading = false;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _notes.dispose();
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

  Future<void> _pickAndScan(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;

    setState(() {
      _scanning = true;
      _imagePath = file.path;
    });

    try {
      final input = InputImage.fromFilePath(file.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await recognizer.processImage(input);
      await recognizer.close();

      final parsed = ReceiptParser.parse(recognized.text);
      if (!mounted) return;
      setState(() => _parsed = parsed);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _save() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a supplier')),
      );
      return;
    }
    if (_parsed == null || _parsed!.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan a receipt first')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      if (_imagePath != null && _uploadedPath == null) {
        _uploadedPath = await sl<PurchaseRemoteDataSource>().uploadReceiptFile(
          XFile(_imagePath!),
        );
      }

      await sl<PurchaseRemoteDataSource>().create({
        'supplierId': _selectedSupplier!.id,
        'purchaseDate': PurchaseDateField.toApiDate(_purchaseDate),
        'amountPaid': 0,
        'notes': _notes.text.trim(),
        'receiptImagePath': _uploadedPath ?? '',
        'items': _parsed!.lines
            .map(
              (line) => {
                'description': line.description,
                'quantity': line.quantity,
                'unitPrice': line.unitPrice,
                'lineTotal': line.lineTotal,
              },
            )
            .toList(),
      });

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan receipt')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          Row(
            children: [
              Expanded(
                child: ActionChipButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Camera',
                  filled: true,
                  onTap: _scanning ? () {} : () => _pickAndScan(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionChipButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: _scanning ? () {} : () => _pickAndScan(ImageSource.gallery),
                ),
              ),
            ],
          ),
          if (_scanning) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            const SizedBox(height: 8),
            const Center(child: Text('Reading receipt...', style: TextStyle(color: AppColors.muted))),
          ],
          const SizedBox(height: AppSpacing.section),
          const SectionTitle('Purchase info'),
          JournalCard(
            child: Column(
              children: [
                DropdownButtonFormField<SupplierModel>(
                  initialValue: _selectedSupplier,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                  items: _suppliers
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedSupplier = value),
                ),
                const SizedBox(height: 14),
                PurchaseDateField(
                  date: _purchaseDate,
                  onChanged: (d) => setState(() => _purchaseDate = d),
                ),
                if (_parsed != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Detected total: ${(_parsed!.suggestedTotal ?? _parsed!.lines.fold<double>(0, (s, l) => s + l.lineTotal)).toStringAsFixed(2)} ETB',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Payments are recorded separately on the supplier account.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
              ],
            ),
          ),
          if (_parsed != null) ...[
            const SizedBox(height: AppSpacing.section),
            SectionTitle('Detected items (${_parsed!.lines.length})'),
            ..._parsed!.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: JournalCard(
                  accent: AppColors.primary,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              'Qty ${line.quantity} × ${line.unitPrice.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        line.lineTotal.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.section),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save purchase'),
          ),
          TextButton(
            onPressed: () => context.push(RouteNames.purchaseNew),
            child: const Text('Enter manually instead'),
          ),
        ],
      ),
    );
  }
}
