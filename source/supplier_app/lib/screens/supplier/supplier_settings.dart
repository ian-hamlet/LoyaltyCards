import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide Card;
import '../../services/business_repository.dart';
import '../../services/key_manager.dart';
import 'supplier_onboarding.dart';
import 'recovery_backup_screen.dart';
import 'clone_device_screen.dart';

/// Feature flag: Show dangerous reset button during testing phase
/// Set to false before production App Store release
const bool _enableResetInRelease = true;

class SupplierSettings extends StatefulWidget {
  final Business business;

  const SupplierSettings({super.key, required this.business});

  @override
  State<SupplierSettings> createState() => _SupplierSettingsState();
}

class _SupplierSettingsState extends State<SupplierSettings> {
  final BusinessRepository _businessRepo = BusinessRepository();
  final KeyManager _keyManager = KeyManager();

  /// Check if dangerous reset button should be shown
  /// True in debug mode OR if explicitly enabled for TestFlight testing
  bool get _showResetButton => kDebugMode || _enableResetInRelease;

  Future<void> _confirmAndResetBusiness() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Business Configuration'),
        content: const Text(
          'This will delete your business configuration including:\n\n'
          '• Business name\n'
          '• Cryptographic keys\n'
          '• All issued cards and stamps history\n\n'
          'This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Haptics.light();
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Haptics.error();
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        AppLogger.info('${'=' * 60}');
        AppLogger.info('SUPPLIER APP: RESETTING BUSINESS - ${DateTime.now().toIso8601String()}');
        AppLogger.info('Business: ${widget.business.name} (ID: ${widget.business.id})');
        
        // Delete business and keys
        AppLogger.database('Deleting business configuration...');
        await _businessRepo.deleteBusiness(widget.business.id);
        AppLogger.crypto('Deleting cryptographic keys...');
        await _keyManager.deleteKeys(widget.business.id);
        
        AppLogger.info('BUSINESS RESET COMPLETE');
        AppLogger.info('${'=' * 60}');

        if (mounted) {
          // Pop loading dialog
          Navigator.pop(context);

          // Navigate to onboarding
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SupplierOnboarding()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          // Pop loading dialog
          Navigator.pop(context);

          AppFeedback.error(context, 'Error resetting business: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Business Info Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Business Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Business Name'),
            subtitle: Text(widget.business.name),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Brand Color'),
            subtitle: Text(widget.business.brandColor),
            trailing: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BrandColors.fromHex(widget.business.brandColor),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.confirmation_number),
            title: const Text('Stamps Required'),
            subtitle: Text('${widget.business.stampsRequired} stamps'),
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Business ID'),
            subtitle: Text(
              widget.business.id,
              style: const TextStyle(fontSize: 11),
            ),
          ),

          const Divider(height: 32),

          // App Version Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'App Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(appVersion),
          ),
          const Divider(height: 32),

          // Backup & Recovery Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Backup & Recovery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.backup, color: Colors.blue),
            title: const Text('Create Recovery Backup'),
            subtitle: const Text(
              'Save your business configuration to prevent data loss',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Haptics.medium();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecoveryBackupScreen(
                    business: widget.business,
                    isFirstTime: false,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.device_hub, color: Colors.green),
            title: const Text('Clone to Another Device'),
            subtitle: const Text(
              'Set up this business on additional devices',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Haptics.medium();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CloneDeviceScreen(
                    business: widget.business,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 32),

          // Danger Zone - TestFlight/Debug only (controlled by feature flag)
          if (_showResetButton) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text(
                'Reset Business Configuration',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text(
                'Delete business and start over with new name',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Haptics.medium();
                _confirmAndResetBusiness();
              },
            ),
            const SizedBox(height: 32),
          ],

          const Divider(height: 32),

          // Tips Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Tips',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• To refresh the QR code on Issue Card screen, tap the refresh icon in the top right\n'
                  '• Each QR code is valid for 5 minutes\n'
                  '• Resetting deletes all customer card history',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
