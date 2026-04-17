import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared/models/business.dart';
import 'package:shared/models/supplier_config_backup.dart';
import 'package:shared/widgets/feedback.dart';
import 'package:shared/shared.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/backup_storage_service.dart';
import '../../services/key_manager.dart';
import '../../services/biometric_auth_service.dart';
import 'package:intl/intl.dart';

/// Screen for creating and exporting supplier configuration backups
/// Offers four storage methods: Print, Photos, Email, Files
/// 
/// **PERMISSIONS REQUIRED:**
/// 
/// 1. **Save to Photos:**
///    - iOS Permission: NSPhotoLibraryAddUsageDescription (defined in Info.plist)
///    - Level: "Add Photos Only" (write access, no read access needed)
///    - Prompt: Appears first time user taps "Save to Photos"
///    - User can allow or deny; denied means feature won't work
/// 
/// 2. **Email to Myself:**
///    - No system permissions required
///    - Uses system share sheet which has built-in email access
///    - Works immediately without prompts
/// 
/// 3. **Save to Files:**
///    - No system permissions required on iOS (app's own documents directory)
///    - Opens share sheet to let user choose save location
///    - User can select Files app, iCloud Drive, etc.
/// 
/// 4. **Print Backup:**
///    - No permissions required
///    - Opens system print dialog
///    - User can print or save as PDF
/// Offers four storage methods: Print, Photos, Email, Files
class RecoveryBackupScreen extends StatefulWidget {
  final Business business;
  final bool isFirstTime; // True if called during initial setup

  const RecoveryBackupScreen({
    Key? key,
    required this.business,
    this.isFirstTime = false,
  }) : super(key: key);

  @override
  State<RecoveryBackupScreen> createState() => _RecoveryBackupScreenState();
}

class _RecoveryBackupScreenState extends State<RecoveryBackupScreen> {
  SupplierConfigBackup? _backup;
  Uint8List? _qrImageBytes;
  bool _isGenerating = false;
  bool _authenticationRequired = true;
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
    
    final authMethodName = await _biometricAuth.getAuthMethodName();
    
    final bool isAuthenticated = await _biometricAuth.authenticate(
      reason: 'Authenticate to view recovery backup QR code containing your private key',
    );

    if (!isAuthenticated) {
      AppLogger.warning('Authentication failed or cancelled - backup not generated', 'Backup');
      if (mounted) {
        setState(() {
          _authenticationRequired = true;
          _isGenerating = false;
        });
        
        // Show message and navigate back
        AppFeedback.warning(context, 'Authentication required to view backup QR code');
        Navigator.of(context).pop();
      }
      return;
    }

    AppLogger.debug('✅ Authentication successful - generating backup', 'Backup');
    setState(() {
      _authenticationRequired = false;
    });
    
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
      
      AppLogger.debug('Generating QR image bytes...', 'Backup');
      final qrBytes = await BackupStorageService.generateQRImageBytes(backup);
      AppLogger.debug('QR image generated: ${qrBytes.length} bytes', 'Backup');

      setState(() {
        _backup = backup;
        _qrImageBytes = qrBytes;
        _isGenerating = false;
      });
      
      AppLogger.debug('✅ Backup generation complete', 'Backup');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate backup: $e', tag: 'Backup');
      AppLogger.error('Stack trace: $stackTrace', tag: 'Backup');
      setState(() => _isGenerating = false);
      AppFeedback.error(context, 'Failed to generate backup: $e');
    }
  }

  Future<void> _printBackup() async {
    AppLogger.debug('🖨️ Print Backup button tapped', 'Backup');
    
    if (_backup == null || _qrImageBytes == null) {
      AppLogger.error('Print failed: backup or image bytes are null', tag: 'Backup');
      AppFeedback.error(context, 'Backup data not ready');
      return;
    }

    AppLogger.debug('Calling BackupStorageService.printBackup...', 'Backup');
    
    try {
      final success = await BackupStorageService.printBackup(
        _backup!,
        _qrImageBytes!,
      );

      AppLogger.debug('printBackup returned: $success', 'Backup');

      if (success) {
        setState(() => _completedMethods.add('print'));
        AppLogger.debug('Print method completed successfully', 'Backup');
        AppFeedback.success(context, 'Print dialog opened');
      } else {
        AppLogger.warning('printBackup returned false - no dialog shown', 'Backup');
        AppFeedback.error(context, 'Failed to open print dialog');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Exception in _printBackup: $e', tag: 'Backup');
      AppLogger.error('Stack trace: $stackTrace', tag: 'Backup');
      AppFeedback.error(context, 'Print error: $e');
    }
  }

  Future<void> _saveToPhotos() async {
    AppLogger.debug('📷 Save to Photos button tapped', 'Backup');
    
    if (_backup == null || _qrImageBytes == null) {
      AppLogger.error('Save to Photos failed: backup or image bytes are null', tag: 'Backup');
      AppLogger.debug('  backup null: ${_backup == null}, imageBytes null: ${_qrImageBytes == null}', 'Backup');
      AppFeedback.error(context, 'Backup data not ready');
      return;
    }

    AppLogger.debug('Image bytes size: ${_qrImageBytes!.length} bytes', 'Backup');
    AppLogger.debug('Calling BackupStorageService.saveToPhotos...', 'Backup');
    
    try {
      final success = await BackupStorageService.saveToPhotos(
        _backup!,
        _qrImageBytes!,
      );

      AppLogger.debug('saveToPhotos returned: $success', 'Backup');

      if (success) {
        setState(() => _completedMethods.add('photos'));
        AppLogger.debug('Photos method completed successfully', 'Backup');
        AppFeedback.success(context, 'Saved to Photos');
      } else {
        AppLogger.warning('saveToPhotos returned false - check permissions or storage', 'Backup');
        AppFeedback.error(context, 'Failed to save to Photos - check permissions');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Exception in _saveToPhotos: $e', tag: 'Backup');
      AppLogger.error('Stack trace: $stackTrace', tag: 'Backup');
      AppFeedback.error(context, 'Save error: $e');
    }
  }

  Future<void> _shareViaEmail() async {
    AppLogger.debug('📧 Email to Myself button tapped', 'Backup');
    
    if (_backup == null || _qrImageBytes == null) {
      AppLogger.error('Share via email failed: backup or image bytes are null', tag: 'Backup');
      AppFeedback.error(context, 'Backup data not ready');
      return;
    }

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

      final success = await BackupStorageService.shareViaEmail(
        _backup!,
        _qrImageBytes!,
        sharePositionOrigin: sharePosition,
      );

      AppLogger.debug('shareViaEmail returned: $success', 'Backup');

      if (success) {
        setState(() => _completedMethods.add('email'));
        AppLogger.debug('Email method completed successfully', 'Backup');
        AppFeedback.success(context, 'Share sheet opened');
      } else {
        AppLogger.warning('shareViaEmail returned false', 'Backup');
        AppFeedback.error(context, 'Failed to share');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Exception in _shareViaEmail: $e', tag: 'Backup');
      AppLogger.error('Stack trace: $stackTrace', tag: 'Backup');
      AppFeedback.error(context, 'Share error: $e');
    }
  }

  Future<void> _saveToFiles() async {
    AppLogger.debug('📁 Save to Files button tapped', 'Backup');
    
    if (_backup == null || _qrImageBytes == null) {
      AppLogger.error('Save to Files failed: backup or image bytes are null', tag: 'Backup');
      AppFeedback.error(context, 'Backup data not ready');
      return;
    }

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

      final success = await BackupStorageService.saveToFiles(
        _backup!,
        _qrImageBytes!,
        sharePositionOrigin: sharePosition,
      );

      AppLogger.debug('saveToFiles returned: $success', 'Backup');

      if (success) {
        setState(() => _completedMethods.add('files'));
        AppLogger.debug('Files method completed successfully', 'Backup');
        AppFeedback.success(context, 'Saved to Files');
      } else {
        AppLogger.warning('saveToFiles returned false', 'Backup');
        AppFeedback.error(context, 'Failed to save to Files');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Exception in _saveToFiles: $e', tag: 'Backup');
      AppLogger.error('Stack trace: $stackTrace', tag: 'Backup');
      AppFeedback.error(context, 'Save error: $e');
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
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('No Backup Created'),
          ],
        ),
        content: Text(
          'Without a backup, if you lose this device, all your customer loyalty cards will become invalid.\n\n'
          'You would need to re-issue new cards to every customer.\n\n'
          'Are you sure you want to skip creating a backup?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, false); // Close screen
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Skip Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recovery Backup'),
        leading: widget.isFirstTime
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: _isGenerating
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warning banner
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, color: Colors.red, size: 32),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'KEEP THIS SECURE',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Anyone with this QR can impersonate your business',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // QR Code display
                  if (_backup != null)
                    Container(
                      padding: EdgeInsets.all(20),
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
                          SizedBox(height: 8),
                          Text(
                            'Recovery Backup - No Expiry',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 16),
                          QrImageView(
                            data: _backup!.toQRString(),
                            version: QrVersions.auto,
                            size: 250,
                          ),
                          SizedBox(height: 8),
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

                  SizedBox(height: 24),

                  // Instructions
                  Text(
                    'Save This Backup:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We recommend using all methods for maximum safety',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  SizedBox(height: 16),

                  // Print option (highlighted)
                  _buildStorageOption(
                    icon: Icons.print,
                    title: 'Print Backup',
                    subtitle: 'Recommended: Store in safe place',
                    completed: _completedMethods.contains('print'),
                    onTap: _printBackup,
                    isPrimary: true,
                  ),

                  SizedBox(height: 12),

                  // Photos option
                  _buildStorageOption(
                    icon: Icons.photo_library,
                    title: 'Save to Photos',
                    subtitle: 'Backs up to iCloud automatically',
                    completed: _completedMethods.contains('photos'),
                    onTap: _saveToPhotos,
                  ),

                  SizedBox(height: 12),

                  // Email option
                  _buildStorageOption(
                    icon: Icons.email,
                    title: 'Email to Myself',
                    subtitle: 'Easy to find and access',
                    completed: _completedMethods.contains('email'),
                    onTap: _shareViaEmail,
                  ),

                  SizedBox(height: 12),

                  // Files option
                  _buildStorageOption(
                    icon: Icons.folder,
                    title: 'Save to Files',
                    subtitle: 'Store in password manager or cloud',
                    completed: _completedMethods.contains('files'),
                    onTap: _saveToFiles,
                  ),

                  SizedBox(height: 24),

                  // Completion indicator
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _completedMethods.length >= 2
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _completedMethods.length >= 2
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: _completedMethods.length >= 2
                              ? Colors.green
                              : Colors.grey,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_completedMethods.length}/4 methods completed',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (_completedMethods.length < 2)
                                Text(
                                  'We recommend at least 2 methods',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Done button
                  ElevatedButton(
                    onPressed: _onDone,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _completedMethods.isEmpty ? 'Skip (Not Recommended)' : 'Done',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  SizedBox(height: 16),
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
        trailing: completed
            ? Icon(Icons.check_circle, color: Colors.green)
            : Icon(Icons.chevron_right, color: Colors.grey[600]),
        onTap: onTap,
      ),
    );
  }
}
