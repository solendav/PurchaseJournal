import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchase_journal/config/routes/route_names.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/config/themes/app_theme.dart';
import 'package:purchase_journal/core/widgets/journal_widgets.dart';

/// Receipt scanning is temporarily disabled (ML Kit removed from release build).
/// Re-enable with `google_mlkit_text_recognition` in pubspec and restore the full page.
class ScanReceiptPage extends StatelessWidget {
  const ScanReceiptPage({super.key, this.initialSupplierId});

  final String? initialSupplierId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan receipt')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const JournalCard(
              child: Text(
                'Receipt scanning is not available in this release. '
                'Use Add purchase to enter details manually.',
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            FilledButton(
              onPressed: () {
                final query = initialSupplierId != null ? '?supplierId=$initialSupplierId' : '';
                context.push('${RouteNames.purchaseNew}$query');
              },
              child: const Text('Enter purchase manually'),
            ),
          ],
        ),
      ),
    );
  }
}
