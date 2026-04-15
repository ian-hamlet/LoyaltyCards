import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared/shared.dart' hide Card;
import '../../services/business_repository.dart';
import '../../services/key_manager.dart';
import 'supplier_home.dart';
import 'package:pointycastle/ecc/api.dart';

/// Screen for importing/recovering business configuration from QR code
/// Supports both:
/// - Recovery backup (no expiry) - for disaster recovery
/// - Clone QR (24h expiry) - for setting up additional devices
class ImportBusinessScreen extends StatefulWidget {
  const ImportBusinessScreen({Key? key}) : super(key: key);

  @override
  State<ImportBusinessScreen> createState() => _ImportBusinessScreenState();
}

class _ImportBusinessScreenState extends State<ImportBusinessScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final BusinessRepository _businessRepo = BusinessRepository();
  final KeyManager _keyManager = KeyManager();
  
  bool _isProcessing = false;
  String? _errorMessage;
  int _manualRotationOffset = 0; // 0-3 for 0°, 90°, 180°, 270°

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      AppLogger.business('Processing business import QR code');

      // Step 1: Parse QR data
      AppLogger.debug('Step 1: Parsing QR data', 'Import');
      final SupplierConfigBackup backup = SupplierConfigBackup.fromQRString(qrData);
      AppLogger.debug('Parsed backup type: ${backup.type}, Business: ${backup.businessName}', 'Import');

      // Step 2: Verify signature
      AppLogger.debug('Step 2: Verifying signature', 'Import');
      final isValid = await backup.verifySignature();
      if (!isValid) {
        throw Exception('Invalid signature - backup may be tampered with');
      }
      AppLogger.debug('Signature verified', 'Import');

      // Step 3: Check expiry (for clone type)
      if (backup.type == 'clone') {
        AppLogger.debug('Step 3: Checking clone QR expiry', 'Import');
        if (backup.isExpired) {
          throw Exception('Clone QR code has expired. Please generate a new one.');
        }
        AppLogger.debug('Clone QR still valid', 'Import');
      } else {
        AppLogger.debug('Step 3: Recovery backup (no expiry)', 'Import');
      }

      // Step 4: Check if business already exists
      AppLogger.debug('Step 4: Checking for existing business', 'Import');
      final existingBusiness = await _businessRepo.getBusiness();
      if (existingBusiness != null) {
        throw Exception(
          'Business already configured on this device.\n'
          'Please reset existing business in Settings first.'
        );
      }
      AppLogger.debug('No existing business found', 'Import');

      // Step 5: Convert backup to Business
      AppLogger.debug('Step 5: Converting backup to Business model', 'Import');
      final business = backup.toBusiness();
      AppLogger.debug('Business ID: ${business.id}', 'Import');

      // Step 6: Store private key
      AppLogger.crypto('Storing private key securely');
      final privateKey = _keyManager.decodePrivateKey(backup.privateKey);
      await _keyManager.storePrivateKey(business.id, privateKey as ECPrivateKey);
      AppLogger.crypto('Private key stored');

      // Step 7: Store public key
      AppLogger.crypto('Storing public key securely');
      final publicKey = _keyManager.decodePublicKey(backup.publicKey);
      await _keyManager.storePublicKey(business.id, publicKey as ECPublicKey);
      AppLogger.crypto('Public key stored');

      // Step 8: Save business to database
      AppLogger.database('Saving business to database');
      await _businessRepo.insertBusiness(business);
      AppLogger.database('Business saved to database');

      AppLogger.business('Business import complete: ${business.name}');

      // Success!
      if (mounted) {
        Haptics.success();
        AppFeedback.success(context, 'Business restored: ${business.name}');
        
        // Navigate to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SupplierHome()),
        );
      }
    } catch (e) {
      AppLogger.error('Business import failed: $e');
      
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });

      if (mounted) {
        Haptics.error();
        AppFeedback.error(context, 'Import failed: $_errorMessage');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Import Business'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // QR Scanner with orientation handling
          if (!_isProcessing)
            ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape = constraints.maxWidth > constraints.maxHeight;
                  final padding = MediaQuery.of(context).padding;
                  
                  // Apply rotation: base + manual offset
                  final baseQuarterTurns = isLandscape ? 3 : 0;
                  final quarterTurns = (baseQuarterTurns + _manualRotationOffset) % 4;
                  
                  return RotatedBox(
                    quarterTurns: quarterTurns,
                    child: MobileScanner(
                      controller: _scannerController,
                      fit: BoxFit.contain,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            _handleQRCode(barcode.rawValue!);
                            break;
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ),

          // Manual rotation controls
          if (!_isProcessing)
            Positioned(
              top: 80,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'rotate90_import',
                    mini: true,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    onPressed: () {
                      setState(() {
                        _manualRotationOffset = (_manualRotationOffset + 1) % 4;
                      });
                    },
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rotate_90_degrees_cw, size: 20, color: Colors.blue),
                        Text('90°', style: TextStyle(fontSize: 10, color: Colors.blue)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'rotate180_import',
                    mini: true,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    onPressed: () {
                      setState(() {
                        _manualRotationOffset = (_manualRotationOffset + 2) % 4;
                      });
                    },
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flip, size: 20, color: Colors.blue),
                        Text('180°', style: TextStyle(fontSize: 10, color: Colors.blue)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Scanning frame
          if (!_isProcessing)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 24),
                    Text(
                      'Restoring business...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Validating signature and storing keys',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Instructions overlay (when not processing)
          if (!_isProcessing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black87,
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Scan Recovery QR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Scan your backup QR code to restore your business configuration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Works with both recovery backups and clone QR codes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error message (if any)
          if (_errorMessage != null && !_isProcessing)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Failed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Cancel button
          if (!_isProcessing)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  label: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
