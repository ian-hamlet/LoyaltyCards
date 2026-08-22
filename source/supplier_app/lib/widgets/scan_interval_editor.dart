import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide Card;
import '../models/audit_entry.dart';
import '../services/business_repository.dart';
import '../services/audit_trail_repository.dart';

/// Lets a supplier edit their Express Mode scan cooldown after setup,
/// instead of only being able to set it once during onboarding. Unlike
/// stampsRequired (see stamps_required_fix.dart), scanInterval is never
/// baked into an issued card - it's read live off the Business record
/// each time a stamp token is generated (see supplier_stamp_card.dart),
/// so a change here is safe to apply immediately with no effect on
/// existing cards. Mirrors the stepper + slider UI from
/// supplier_onboarding.dart so the editing experience matches setup.
/// Only meaningful for Express Mode - Secure Mode never uses scanInterval.
/// Returns true if the business was actually updated.
Future<bool> showEditScanIntervalDialog(BuildContext context, Business business) async {
  final minSeconds = AppConstants.simpleModeMinScanIntervalMs ~/ 1000;
  final maxSeconds = AppConstants.simpleModeMaxScanIntervalMs ~/ 1000;
  int selected = (business.scanInterval ~/ 1000).clamp(minSeconds, maxSeconds);

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Scan Cooldown'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minimum wait time between accepted stamp scans for a customer card '
              '(range: $minSeconds-$maxSeconds seconds). Applies to the next stamp '
              'scanned - no need to reissue existing cards.',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: selected > minSeconds
                      ? () {
                          Haptics.light();
                          setDialogState(() => selected -= 5);
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle),
                  tooltip: 'Decrease scan cooldown',
                ),
                Expanded(
                  child: Text(
                    '$selected seconds',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: selected < maxSeconds
                      ? () {
                          Haptics.light();
                          setDialogState(() => selected += 5);
                        }
                      : null,
                  icon: const Icon(Icons.add_circle),
                  tooltip: 'Increase scan cooldown',
                ),
              ],
            ),
            Slider(
              value: selected.toDouble(),
              min: minSeconds.toDouble(),
              max: maxSeconds.toDouble(),
              divisions: (maxSeconds - minSeconds) ~/ 5,
              label: '${selected}s',
              onChanged: (value) => setDialogState(() => selected = value.toInt()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await BusinessRepository().updateBusiness(
                  business.copyWith(scanInterval: selected * 1000),
                );
                await AuditTrailRepository().logEntry(
                  businessId: business.id,
                  propertyName: AuditProperty.scanCooldown,
                  newValue: '${selected}s',
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
