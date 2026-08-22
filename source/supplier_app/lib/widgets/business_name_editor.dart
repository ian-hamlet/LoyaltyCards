import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide Card;
import '../models/audit_entry.dart';
import '../services/business_repository.dart';
import '../services/audit_trail_repository.dart';

/// Lets a supplier edit their business name after setup. Purely a display
/// value - it's baked into a card's signature at issuance (frozen per-card,
/// like stampsRequired), never re-read live by an existing card. See
/// Requirements/DISCUSSION_Business_Field_Editing.md §2.
/// Returns true if the business was actually updated.
Future<bool> showEditBusinessNameDialog(BuildContext context, Business business) async {
  final controller = TextEditingController(text: business.name);

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final trimmed = controller.text.trim();
        final isValid = trimmed.isNotEmpty;

        return AlertDialog(
          title: const Text('Business Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Only affects cards issued from now on - customers with an existing card keep the name it was issued with, until it next updates on scan.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: !isValid
                  ? null
                  : () async {
                      try {
                        await BusinessRepository().updateBusiness(business.copyWith(name: trimmed));
                        await AuditTrailRepository().logEntry(
                          businessId: business.id,
                          propertyName: AuditProperty.businessName,
                          newValue: trimmed,
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                      } catch (e) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('Failed to save: $e')),
                          );
                        }
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );

  return result ?? false;
}
