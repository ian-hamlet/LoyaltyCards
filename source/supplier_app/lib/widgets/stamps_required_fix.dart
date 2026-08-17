import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide Card;
import '../services/business_repository.dart';

/// DECISION-017: proactive detection + self-service fix for a business
/// whose stampsRequired falls outside the app's currently-supported
/// range (e.g. one configured before TEST-017/020 tightened it). Without
/// this, the only way to recover was a full reset - wiping every
/// customer's card for the business - for what's really just a number
/// needing to move back into range. See DEFECT_TRACKER.md DECISION-017.
class OutOfRangeStampsBanner extends StatelessWidget {
  final Business business;
  final VoidCallback onFixed;

  const OutOfRangeStampsBanner({super.key, required this.business, required this.onFixed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "New cards can't be issued",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This business is set up for ${business.stampsRequired} stamps, which this app '
            "version doesn't support (supported range: ${CardIssueToken.minStampsRequired}-"
            '${CardIssueToken.maxStampsRequired}). Existing customer cards are unaffected, but '
            'no new card can be issued until this is fixed.',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () async {
                final fixed = await showFixStampsRequiredDialog(context, business);
                if (fixed) onFixed();
              },
              child: const Text('Fix Now'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a dialog letting the supplier pick a new stampsRequired value
/// within the currently-supported range, and saves it via
/// [BusinessRepository.updateBusiness]. Only ever offered when the
/// business is already out of range - not general free-editing, which
/// stays deliberately locked to avoid a business owner casually changing
/// the target stamp count mid-operation and confusing customers with
/// in-progress cards. Returns true if the business was actually updated.
Future<bool> showFixStampsRequiredDialog(BuildContext context, Business business) async {
  int selected = business.stampsRequired.clamp(
    CardIssueToken.minStampsRequired,
    CardIssueToken.maxStampsRequired,
  );

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Fix Stamps Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currently set to ${business.stampsRequired} stamps, outside the supported range '
              'of ${CardIssueToken.minStampsRequired}-${CardIssueToken.maxStampsRequired}. Choose '
              'a new value - this only affects cards issued from now on; existing customer cards '
              'keep their original stamp count.',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: selected > CardIssueToken.minStampsRequired
                      ? () => setDialogState(() => selected--)
                      : null,
                  icon: const Icon(Icons.remove_circle),
                ),
                Text('$selected stamps', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: selected < CardIssueToken.maxStampsRequired
                      ? () => setDialogState(() => selected++)
                      : null,
                  icon: const Icon(Icons.add_circle),
                ),
              ],
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
                await BusinessRepository().updateBusiness(business.copyWith(stampsRequired: selected));
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
