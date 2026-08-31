import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/backup_storage_service.dart';
import '../../services/key_manager.dart';
import '../../services/biometric_auth_service.dart';
import '../../services/audit_trail_repository.dart';
import '../../models/biometric_auth_result.dart';
import '../../models/audit_entry.dart';
import 'package:intl/intl.dart';

/// Screen for creating and exporting supplier configuration backups
/// Offers three storage methods: Print, Share via Email, Save to Files
/// 
/// **PERMISSIONS REQUIRED:**
/// 
/// 1. **Share via Email:**
///    - No system permissions required
///    - Uses system share sheet which has built-in email access
///    - Works immediately without prompts
/// 
/// 2. **Save to Files:**
///    - No system permissions required on iOS (app's own documents directory)
///    - Opens share sheet to let user choose save location
///    - User can select Files app, iCloud Drive, etc.
/// 
/// 3. **Print Backup:**
///    - No permissions required
///    - Opens system print dialog
///    - User can print or save as PDF
class RecoveryBackupScreen extends StatefulWidget {
  final Business business;
  final bool isFirstTime; // True if called during initial setup

  const RecoveryBackupScreen({
    super.key,
    required this.business,
    this.isFirstTime = false,
  });

  @override
  State<RecoveryBackupScreen> createState() => _RecoveryBackupScreenState();
}

class _RecoveryBackupScreenState extends State<RecoveryBackupScreen> {
  SupplierConfigBackup? _backup;
  Uint8List? _qrImageBytes;
  // Starts true, not false: same reasoning as CloneDeviceScreen -
  // initState() kicks off authentication immediately, but _isGenerating
  // isn't set until the generate step runs *after* auth succeeds. Starting
  // false let the first frame render the backup screen's body before
  // _backup existed, instead of showing the loading state that's already
  // genuinely in flight.
  bool _isGenerating = true;
  // CRASH-001: guards each distribution method against a fast double-tap
  // firing a second concurrent native call (Printing.layoutPdf /
  // Share.shareXFiles) before the first one completes.
  bool _isPrinting = false;
  bool _isSharingEmail = false;
  bool _isSavingToFiles = false;

  /// CRASH-001 regression test hooks: expose each busy-state flag directly
  /// rather than only via widget-render timing. Print/Share via Email take
  /// genuine async time before resolving (real MethodChannel round-trip),
  /// so their disable state is observable a frame later; Save to Files'
  /// underlying BackupStorageService.saveToFiles() throws synchronously on
  /// any platform that isn't iOS or Android (which is all a `flutter test`
  /// host ever is), resolving too fast for that same timing window - these
  /// getters let the guard be verified directly regardless of how fast the
  /// native call underneath happens to resolve.
  @visibleForTesting
  bool get isPrintingForTesting => _isPrinting;
  @visibleForTesting
  bool get isSharingEmailForTesting => _isSharingEmail;
  @visibleForTesting
  bool get isSavingToFilesForTesting => _isSavingToFiles;

  final Set<String> _completedMethods = {};
  final KeyManager _keyManager = KeyManager();
  final BiometricAuthService _biometricAuth = BiometricAuthService();

  @override
  void initState() {
    super.initState();
    _authenticateAndGenerate();
  }

  /// Require biometric/passcode authentication before showing backup QR
  /// This protects the private key from unauthorized access
  Future<void> _authenticateAndGenerate() async {
    AppLogger.debug('🔐 Requesting authentication for backup QR generation...', 'Backup');

    final result = await _biometricAuth.authenticate(
      reason: 'Authenticate to view recovery backup QR code containing your private key',
    );

    if (!result.isSuccess) {
      AppLogger.warning('Authentication failed: ${result.status}', 'Backup');
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        
        // Show specific failure message
        final message = result.getUserMessage();
        final guidance = result.getActionableGuidance();
        
        if (guidance != null) {
          AppFeedback.error(context, '$message\n$guidance');
        } else if (result.status != BiometricAuthStatus.userCancelled) {
          // Don't show error for user cancellation (they know they cancelled)
          AppFeedback.warning(context, message);
        }
        
        Navigator.of(context).pop();
      }
      return;
    }

    AppLogger.debug('✅ Authentication successful - generating backup', 'Backup');

    await _generateBackup();
  }

  Future<void> _generateBackup() async {
    AppLogger.debug('🔄 Generating recovery backup for business: ${widget.business.name}', 'Backup');
    setState(() => _isGenerating = true);

    try {
      // Fetch private key from secure storage for backup inclusion
      AppLogger.debug('Fetching private key from secure storage...', 'Backup');
      final privateKeyString = await _keyManager.getPrivateKeyString(widget.business.id);
      if (privateKeyString == null) {
        AppLogger.error('Private key not found in secure storage for business: ${widget.business.id}', tag: 'Backup');
        throw Exception('Private key not found in secure storage');
      }
      AppLogger.debug('Private key retrieved (${privateKeyString.length} chars)', 'Backup');

      // Create business object with privateKey populated for backup
      final businessWithKeys = widget.business.copyWith(
        privateKey: privateKeyString,
      );

      AppLogger.debug('Creating recovery backup object...', 'Backup');
      final backup =
          await SupplierConfigBackup.createRecoveryBackup(businessWithKeys);
      AppLogger.debug('Backup created, QR string length: ${backup.toQRString().length}', 'Backup');

      // Requirements/DISCUSSION_Business_Field_Editing.md §7: log the
      // initiated event - the audit trail records that a backup was made,
      // not the backup's contents (which include the private key).
      await AuditTrailRepository().logEntry(
        businessId: widget.business.id,
        propertyName: AuditProperty.recoveryBackupCreated,
      );
      
      AppLogger.debug('Generating QR image bytes...', 'Backup');
      final qrBytes = await BackupStorageService.generateQRImageBytes(backup);
      AppLogger.debug('QR image generated: ${qrBytes.length} bytes', 'Backup');

      if (!mounted) return;
      setState(() {
        _backup = backup;
        _qrImageBytes = qrBytes;
        _isGenerating = false;
      });

      AppLogger.debug('✅ Backup generation complete', 'Backup');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate backup: $e', tag: 'Backup');
      AppLogger.error('Stack trace: $stackTrace', tag: 'Backup');
      if (!mounted) return;
      setState(() => _isGenerating = false);
      AppFeedback.error(context, 'Failed to generate backup: $e');
    }
  }

  /// CRASH-001 regression test hook.
  @visibleForTesting
  Future<void> printBackupForTesting() => _printBackup();

  Future<void> _printBackup() async {
    AppLogger.debug('🖨️ Print Backup button tapped', 'Backup');

    if (_backup == null || _qrImageBytes == null || _isPrinting) {
      if (_backup == null || _qrImageBytes == null) {
        AppLogger.error('Print failed: backup or image bytes are null', tag: 'Backup');
        AppFeedback.error(context, 'Backup data not ready');
      }
      return;
    }

    setState(() => _isPrinting = true);
    AppLogger.debug('Calling BackupStorageService.printBackup...', 'Backup');

    try {
      final result = await BackupStorageService.printBackup(
        _backup!,
        _qrImageBytes!,
      );

      AppLogger.debug('printBackup returned: ${result.isSuccess}', 'Backup');
      if (!mounted) return;

      if (result.isSuccess) {
        setState(() => _completedMethods.add('print'));
        AppLogger.debug('Print method completed successfully', 'Backup');
        AppFeedback.success(context, 'Print dialog opened');
      } else {
        AppLogger.warning('printBackup failed: ${result.message}', 'Backup');
        AppFeedback.error(context, result.getUserMessage());
      }
    } catch (e, stackTrace) {
      AppLogger.error('Exception in _printBackup: $e', tag: 'Backup');
      AppLogger.error('Stack trace: $stackTrace', tag: 'Backup');
      if (!mounted) return;
      AppFeedback.error(context, 'Print error: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  /// CRASH-001 regression test hook.
  @visibleForTesting
  Future<void> shareViaEmailForTesting() => _shareViaEmail();

  Future<void> _shareViaEmail() async {
    AppLogger.debug('📧 Share via Email button tapped', 'Backup');

    if (_backup == null || _qrImageBytes == null || _isSharingEmail) {
      if (_backup == null || _qrImageBytes == null) {
        AppLogger.error('Share via email failed: backup or image bytes are null', tag: 'Backup');
        AppFeedback.error(context, 'Backup data not ready');
      }
      return;
    }

    setState(() => _isSharingEmail = true);

    try {
      // Get screen size for iPad share position
      final size = MediaQuery.of(context).size;
      final sharePosition = Rect.fromLTWH(
        size.width / 2,
        size.height / 2,
        10,
        10,
      );

      AppLogger.debug('Screen size: ${size.width}x${size.height}', 'Backup');
      AppLogger.debug('Share position: $sharePosition', 'Backup');
      AppLogger.debug('Calling BackupStorageService.shareViaEmail...', 'Backup');

      final result = await BackupStorageService.shareViaEmail(
        _backup!,
        _qrImageBytes!,
        sharePositionOrigin: sharePosition,
      );

      AppLogger.debug('shareViaEmail returned: ${result.isSuccess}', 'Backup');
      if (!mounted) return;

      if (result.isSuccess) {
        setState(() => _completedMethods.add('email'));
        AppLogger.debug('Email method completed successfully', 'Backup');
        AppFeedback.success(context, 'Share sheet opened');
      } else {
        AppLogger.warning('shareViaEmail failed: ${result.message}', 'Backup');
        AppFeedback.error(context, result.getUserMessage());
      }
    } catch (e, stackTrace) {
      AppLogger.error('Exception in _shareViaEmail: $e', tag: 'Backup');
      AppLogger.error('Stack trace: $stackTrace', tag: 'Backup');
      if (!mounted) return;
      AppFeedback.error(context, 'Share error: $e');
    } finally {
      if (mounted) setState(() => _isSharingEmail = false);
    }
  }

  /// CRASH-001 regression test hook.
  @visibleForTesting
  Future<void> saveToFilesForTesting() => _saveToFiles();

  Future<void> _saveToFiles() async {
    AppLogger.debug('📁 Save to Files button tapped', 'Backup');

    if (_backup == null || _qrImageBytes == null || _isSavingToFiles) {
      if (_backup == null || _qrImageBytes == null) {
        AppLogger.error('Save to Files failed: backup or image bytes are null', tag: 'Backup');
        AppFeedback.error(context, 'Backup data not ready');
      }
      return;
    }

    setState(() => _isSavingToFiles = true);

    try {
      // Get screen size for iPad share position
      final size = MediaQuery.of(context).size;
      final sharePosition = Rect.fromLTWH(
        size.width / 2,
        size.height / 2,
        10,
        10,
      );

      AppLogger.debug('Share position for Files: $sharePosition', 'Backup');
      AppLogger.debug('Calling BackupStorageService.saveToFiles...', 'Backup');

      final result = await BackupStorageService.saveToFiles(
        _backup!,
        _qrImageBytes!,
        sharePositionOrigin: sharePosition,
      );

      AppLogger.debug('saveToFiles returned: ${result.isSuccess}', 'Backup');
      if (!mounted) return;

      if (result.isSuccess) {
        setState(() => _completedMethods.add('files'));
        AppLogger.debug('Files method completed successfully', 'Backup');
        AppFeedback.success(context, 'Saved to Files');
      } else {
        AppLogger.warning('saveToFiles failed: ${result.message}', 'Backup');
        AppFeedback.error(context, result.getUserMessage());
      }
    } catch (e, stackTrace) {
      AppLogger.error('Exception in _saveToFiles: $e', tag: 'Backup');
      AppLogger.error('Stack trace: $stackTrace', tag: 'Backup');
      if (!mounted) return;
      AppFeedback.error(context, 'Save error: $e');
    } finally {
      if (mounted) setState(() => _isSavingToFiles = false);
    }
  }

  void _onDone() {
    if (_completedMethods.isEmpty && widget.isFirstTime) {
      _showSkipWarning();
    } else {
      Navigator.pop(context, _completedMethods.isNotEmpty);
    }
  }

  void _showSkipWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('No Backup Created')),
          ],
        ),
        content: const Text(
          'Without a backup, if you lose this device, all your customer loyalty cards will become invalid.\n\n'
          'You would need to re-issue new cards to every customer.\n\n'
          'Are you sure you want to skip creating a backup?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, false); // Close screen
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Skip Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Backup'),
        leading: widget.isFirstTime
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: _isGenerating
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warning banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      border: Border.all(color: colorScheme.error, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, color: colorScheme.onErrorContainer, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'KEEP THIS SECURE',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onErrorContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Anyone with this QR can impersonate your business',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // QR Code display
                  if (_backup != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.business.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Recovery Backup - No Expiry',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: _backup!.toQRString(),
                            version: QrVersions.auto,
                            size: 250,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Created: ${DateFormat('MMM d, yyyy').format(_backup!.timestamp)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Redemption tracking notice - restoring onto a
                  // replacement device does not carry over which rewards
                  // were already redeemed on the original device, since
                  // there's no shared server/database (see docs/technical/
                  // SECURITY_MODEL.md's "Redemption Tracking Across Cloned
                  // Devices" section for the full rationale).
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long_outlined, color: Colors.amber.shade900),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Redemption Records Are Not Included',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'A device restored from this backup won\'t know which rewards were already redeemed before the backup was made - verify manually if a card looks like it should already be redeemed.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Instructions
                  Text(
                    'Save This Backup:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We recommend using all methods for maximum safety',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 16),

                  // Print option (highlighted)
                  _buildStorageOption(
                    icon: Icons.print,
                    title: 'Print Backup',
                    subtitle: 'Recommended: Store in safe place',
                    completed: _completedMethods.contains('print'),
                    onTap: _printBackup,
                    isPrimary: true,
                    isBusy: _isPrinting,
                  ),

                  const SizedBox(height: 12),

                  // Email option
                  _buildStorageOption(
                    icon: Icons.email,
                    title: 'Share via Email',
                    subtitle: 'Easy to find and access',
                    completed: _completedMethods.contains('email'),
                    onTap: _shareViaEmail,
                    isBusy: _isSharingEmail,
                  ),

                  const SizedBox(height: 12),

                  // Files option
                  _buildStorageOption(
                    icon: Icons.folder,
                    title: 'Save to Files',
                    subtitle: 'Store in password manager or cloud',
                    completed: _completedMethods.contains('files'),
                    onTap: _saveToFiles,
                    isBusy: _isSavingToFiles,
                  ),

                  const SizedBox(height: 24),

                  // Completion indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _completedMethods.length >= 2
                          ? colorScheme.tertiaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _completedMethods.length >= 2
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: _completedMethods.length >= 2
                              ? colorScheme.onTertiaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_completedMethods.length}/3 methods completed',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _completedMethods.length >= 2
                                      ? colorScheme.onTertiaryContainer
                                      : colorScheme.onSurface,
                                ),
                              ),
                              if (_completedMethods.length < 2)
                                Text(
                                  'We recommend at least 2 methods',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Done button
                  ElevatedButton(
                    onPressed: _onDone,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _completedMethods.isEmpty ? 'Skip (Not Recommended)' : 'Done',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildStorageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool completed,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isBusy = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? Colors.blue.shade50 : Colors.white,
        border: Border.all(
          color: isPrimary ? Colors.blue : Colors.grey.shade300,
          width: isPrimary ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: completed
              ? Colors.green
              : (isPrimary ? Colors.blue : Colors.grey.shade700),
          size: 32,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87, // Consistent readable dark text
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[700], // Darker, more readable gray
            fontSize: 13,
          ),
        ),
        trailing: isBusy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : (completed
                ? const Icon(Icons.check_circle, color: Colors.green)
                : Icon(Icons.chevron_right, color: Colors.grey[600])),
        // CRASH-001: null onTap while busy - prevents a fast double-tap from
        // firing a second concurrent native call before the first resolves.
        onTap: isBusy ? null : onTap,
      ),
    );
  }
}
