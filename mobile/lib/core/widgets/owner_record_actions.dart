import 'package:flutter/material.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';

/// Owner-only edit/delete actions shown at the bottom of record detail screens.
class OwnerRecordActions extends StatelessWidget {
  const OwnerRecordActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.deleting = false,
    this.editing = false,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool deleting;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    if (editing) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Owner actions',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: deleting ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: deleting ? null : onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  icon: deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline, size: 18),
                  label: Text(deleting ? 'Deleting...' : 'Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
