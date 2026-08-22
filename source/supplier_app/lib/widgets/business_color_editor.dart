import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide Card;
import '../models/audit_entry.dart';
import '../services/business_repository.dart';
import '../services/audit_trail_repository.dart';

/// Lets a supplier edit their brand color after setup. Same staleness
/// mechanism as Business Name - only affects cards issued from now on.
/// See Requirements/DISCUSSION_Business_Field_Editing.md §2.
/// Returns true if the business was actually updated.
Future<bool> showEditBrandColorDialog(BuildContext context, Business business) async {
  String selected = business.brandColor;

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Brand Color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Only affects cards issued from now on - customers with an existing card keep the color it was issued with, until it next updates on scan.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: BrandColors.cardColorOptions.map((color) {
                  final isSelected = color == selected;
                  final colorName = BrandColors.cardColorNames[color] ?? color;
                  return Semantics(
                    label: colorName,
                    button: true,
                    selected: isSelected,
                    child: GestureDetector(
                      onTap: () {
                        Haptics.selection();
                        setDialogState(() => selected = color);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: BrandColors.fromHex(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await BusinessRepository().updateBusiness(business.copyWith(brandColor: selected));
                await AuditTrailRepository().logEntry(
                  businessId: business.id,
                  propertyName: AuditProperty.brandColor,
                  newValue: selected,
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
      ),
    ),
  );

  return result ?? false;
}
