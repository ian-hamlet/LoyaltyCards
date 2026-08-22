import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide Card;
import '../models/audit_entry.dart';
import '../services/business_repository.dart';
import '../services/audit_trail_repository.dart';

/// Lets a supplier edit their business icon after setup. Same staleness
/// mechanism as Business Name/Brand Color - only affects cards issued from
/// now on. Shows the full icon palette (unlike onboarding's curated
/// subset) since this is a deliberate later change, not a first-setup
/// default choice. See Requirements/DISCUSSION_Business_Field_Editing.md §2.
/// Returns true if the business was actually updated.
Future<bool> showEditBusinessIconDialog(BuildContext context, Business business) async {
  int selected = business.logoIndex;

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Business Icon'),
        content: SizedBox(
          width: double.maxFinite,
          height: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Only affects cards issued from now on - customers with an existing card keep the icon it was issued with, until it next updates on scan.',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: BusinessIcons.icons.length,
                  itemBuilder: (context, index) {
                    final isSelected = selected == index;
                    final color = BrandColors.fromHex(business.brandColor);
                    return Semantics(
                      label: BusinessIcons.getIconName(index),
                      button: true,
                      selected: isSelected,
                      child: GestureDetector(
                        onTap: () {
                          Haptics.selection();
                          setDialogState(() => selected = index);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected ? color : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? color : Colors.grey[400]!,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: Icon(
                                BusinessIcons.getIcon(index),
                                size: 26,
                                color: isSelected ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
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
                await BusinessRepository().updateBusiness(business.copyWith(logoIndex: selected));
                await AuditTrailRepository().logEntry(
                  businessId: business.id,
                  propertyName: AuditProperty.icon,
                  newValue: BusinessIcons.getIconName(selected),
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
