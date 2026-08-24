import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:qr_flutter/qr_flutter.dart';
import '../../controllers/controller_results.dart';
import '../../controllers/supplier_redeem_card_controller.dart';
import '../../services/device_orientation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupplierRedeemCard extends StatefulWidget {
  const SupplierRedeemCard({super.key});

  @override
  State<SupplierRedeemCard> createState() => _SupplierRedeemCardState();
}

class _SupplierRedeemCardState extends State<SupplierRedeemCard> {
  MobileScannerController cameraController = MobileScannerController(
    facing: CameraFacing.back,
    autoStart: true,
  );

  // All business/crypto logic for this screen lives in the controller, so
  // it can be tested without pumping a widget tree - see
  // controllers/supplier_redeem_card_controller.dart for the convention.
  // Dialog/navigation orchestration (device-mismatch warning, manual
  // redemption confirmation, the final Navigator.push to show the
  // redemption QR) stays here deliberately - see the ForTesting hooks below
  // for why this screen keeps widget-level test coverage alongside the
  // controller's own.
  final SupplierRedeemCardController _controller = SupplierRedeemCardController();

  Business? get _business => _controller.business;
  bool _isProcessing = false;
  bool _isLoading = true;
  int _manualRotationOffset = 1; // 0, 1, 2, or 3 quarter turns (1 = 90° to fix mobile_scanner 7.2.0)

  // Without this, onDetect fires on every camera frame that decodes the
  // still-in-view QR code - resetting _isProcessing immediately on error
  // let the same code get reprocessed and rejected several times in a row
  // while the camera was still being aimed, showing the same error repeatedly.
  DateTime? _cooldownUntil;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
    _loadRotationPreference();
  }

  Future<void> _loadBusiness() async {
    // Matches the pre-extraction behavior exactly: isLoading clears either
    // way, and a load failure just leaves _business null (build() then
    // shows the loading spinner indefinitely) - not ideal, but not this
    // extraction's concern to change.
    await _controller.loadBusiness();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  /// Load saved camera rotation preference from SharedPreferences
  Future<void> _loadRotationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRotation = prefs.getInt('camera_rotation') ?? 1;
      if (mounted) {
        setState(() {
          _manualRotationOffset = savedRotation;
        });
        AppLogger.debug('Loaded camera rotation preference: $savedRotation (${savedRotation * 90}°)', 'Camera');
      }
    } catch (e) {
      AppLogger.warning('Failed to load camera rotation preference: $e', 'Camera');
    }
  }

  /// Save camera rotation preference to SharedPreferences
  Future<void> _saveRotationPreference(int rotation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('camera_rotation', rotation);
      AppLogger.debug('Saved camera rotation preference: $rotation (${rotation * 90}°)', 'Camera');
    } catch (e) {
      AppLogger.warning('Failed to save camera rotation preference: $e', 'Camera');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _business == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Redeem Card'),
          backgroundColor: BrandColors.success,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Simple mode: Manual redemption confirmation
    if (_business!.mode == OperationMode.simple) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Redeem Card'),
          backgroundColor: BrandColors.success,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                elevation: 1,
                color: BrandColors.successContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: BrandColors.success, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Express Mode - Manual Redemption',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: BrandColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Honor-based system - verify customer has completed card',
                              style: TextStyle(
                                color: BrandColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Instructions
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        size: 80,
                        color: Colors.green[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Redeem Customer Reward',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Secure mode: Camera scanner (existing implementation)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem Card'),
        backgroundColor: BrandColors.success,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                color: BrandColors.successContainer,
                child: const Row(
                  children: [
                    Icon(Icons.card_giftcard, color: BrandColors.success),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Scan customer\'s completed card to redeem reward',
                        style: TextStyle(
                          color: BrandColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scanner
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final mediaQuery = MediaQuery.of(context);
                    final padding = mediaQuery.viewPadding;
                    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
                    
                    // Detect status bar position
                    String statusBarPosition;
                    if (padding.top > padding.left && padding.top > padding.right) {
                      statusBarPosition = 'top (portrait)';
                    } else if (padding.left > padding.right) {
                      statusBarPosition = 'left (landscapeRight)';
                    } else if (padding.right > padding.left) {
                      statusBarPosition = 'right (landscapeLeft)';
                    } else {
                      statusBarPosition = 'unknown';
                    }
                    
                    // Apply rotation: base + manual offset
                    final baseQuarterTurns = isLandscape ? 3 : 0;
                    final quarterTurns = (baseQuarterTurns + _manualRotationOffset) % 4;
                    
                    AppLogger.debug(
                      'Scanner: ${isLandscape ? "Landscape" : "Portrait"}, '
                      'statusBar: $statusBarPosition, '
                      'rotation: ${quarterTurns * 90}°',
                      'Scanner'
                    );
                    
                    return RotatedBox(
                      quarterTurns: quarterTurns,
                      child: MobileScanner(
                        controller: cameraController,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error) => ScannerPermissionErrorView(error: error),
                        onDetect: (capture) {
                          if (_isProcessing) return;
                          if (_cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!)) return;
                    
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _processCardQR(barcode.rawValue!);
                        break;
                        }
                      }
                    },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Camera controls
          Positioned(
            top: 80,
            right: 16,
            child: Column(
              children: [
                // Camera flip (front/back switch)
                FloatingActionButton(
                  heroTag: 'flip_camera_redeem',
                  mini: true,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  onPressed: () {
                    cameraController.switchCamera();
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flip_camera_ios, size: 16, color: Colors.green),
                      ScaleCapped(child: Text('Flip', style: TextStyle(fontSize: 8, height: 1.0, color: Colors.green))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Rotate 90°
                FloatingActionButton(
                  heroTag: 'rotate90',
                  mini: true,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  onPressed: () {
                    final newRotation = (_manualRotationOffset + 1) % 4;
                    setState(() {
                      _manualRotationOffset = newRotation;
                    });
                    _saveRotationPreference(newRotation);
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rotate_90_degrees_cw, size: 16, color: Colors.green),
                      ScaleCapped(child: Text('90°', style: TextStyle(fontSize: 8, height: 1.0, color: Colors.green))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Rotate 180°
                FloatingActionButton(
                  heroTag: 'rotate180',
                  mini: true,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  onPressed: () {
                    final newRotation = (_manualRotationOffset + 2) % 4;
                    setState(() {
                      _manualRotationOffset = newRotation;
                    });
                    _saveRotationPreference(newRotation);
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flip, size: 16, color: Colors.green),
                      ScaleCapped(child: Text('180°', style: TextStyle(fontSize: 8, height: 1.0, color: Colors.green))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scanning frame
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

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),

          // Flashlight toggle
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white, size: 32),
              onPressed: () => cameraController.toggleTorch(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: Colors.green[700], size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Future<void> _showRedemptionConfirmation() async {
    if (_business == null) return;

    // For simple mode, show manual confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.card_giftcard, color: Colors.green[600], size: 48),
        title: const Text(
          'Confirm Redemption',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Have you:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 12),
            _buildCheckItem('✓ Verified customer\'s completed card'),
            const SizedBox(height: 8),
            _buildCheckItem('✓ Provided the reward to the customer'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This will record the redemption with current timestamp',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirm Redemption', textAlign: TextAlign.center),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green[600],
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _processManualRedemption();
    }
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green[600], size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  /// Test-only entry point for [_processManualRedemption] - see
  /// [processCardQRForTesting] for why a direct call is needed instead of
  /// driving this through the UI. Note: as of this writing, no visible
  /// button in the Simple Mode build actually calls
  /// [_showRedemptionConfirmation]/[_processManualRedemption] - flagged
  /// separately, this wrapper still exercises the underlying logic.
  @visibleForTesting
  Future<void> processManualRedemptionForTesting() => _processManualRedemption();

  Future<void> _processManualRedemption() async {
    setState(() => _isProcessing = true);

    final result = await _controller.recordManualRedemption();
    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() => _isProcessing = false);
      _showError(result.errorMessage!);
      return;
    }

    setState(() => _isProcessing = false);

    final now = result.redeemedAt!;

    // Show success message
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.celebration, color: Colors.green, size: 64),
        title: const Text('Redemption Recorded!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Redeemed: ${result.stampsRedeemed} stamps',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${now.day}/${now.month}/${now.year}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to home
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  /// Test-only entry point for [_processCardQR] - lets widget tests
  /// simulate "a QR was scanned" without a real camera (mobile_scanner
  /// can't produce detection events in the test environment). Since this
  /// State class is private, call it dynamically:
  /// `(tester.state(find.byType(SupplierRedeemCard)) as dynamic).processCardQRForTesting(qrData)`.
  @visibleForTesting
  Future<void> processCardQRForTesting(String qrData) => _processCardQR(qrData);

  Future<void> _processCardQR(String qrData) async {
    setState(() {
      _isProcessing = true;
    });

    final result = await _controller.parseRedemptionQr(qrData, onTokenRecognized: Haptics.success);
    if (!mounted) return;

    if (!result.isSuccess) {
      _showError(result.errorMessage!);
      return;
    }

    final token = result.token;
    if (token != null) {
      await _processRedemptionRequestToken(token);
    } else {
      // Legacy format (LOYALTYCARD:REDEEM:...) - never carried a full
      // token, so no validateRedemptionToken() step, straight to
      // confirmation - matches the pre-extraction call shape exactly.
      await _showSecureModeRedemptionConfirmation(context, result.cardId!, result.stampsCollected!);
    }
  }

  /// Shared by both the plain-JSON and TEST-020 compact-decode success
  /// paths in _processCardQR - validates a parsed [RedemptionRequestToken]
  /// and proceeds to redemption confirmation or a rejection message.
  Future<void> _processRedemptionRequestToken(RedemptionRequestToken token) async {
    final validation = _controller.validateRedemptionToken(token);

    if (!validation.isSuccess) {
      if (validation.failureReason == SupplierScanFailureReason.deviceMismatch) {
        await _showDeviceMismatchWarning(context, token);
      } else {
        _showError(validation.errorMessage!);
      }
      return;
    }

    await _showSecureModeRedemptionConfirmation(context, token.cardId, token.stampsCollected, token: token);
  }

  Future<void> _showSecureModeRedemptionConfirmation(
    BuildContext context,
    String cardId,
    int stamps, {
    RedemptionRequestToken? token,
  }) async {
    final result = await _controller.confirmRedemption(cardId, stamps, token: token);
    if (!mounted) return;

    if (!result.isSuccess) {
      _showError(result.errorMessage!);
      return;
    }

    // Show QR code for customer to scan
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _RedemptionTokenScreen(
          token: result.redemptionToken!,
          stampsRedeemed: result.stampsRedeemed!,
        ),
      ),
    );

    // Return to previous screen after showing token
    if (mounted) {
      Navigator.pop(context, true);
    }

    // Reset processing flag only after all navigation completes
    setState(() {
      _isProcessing = false;
    });
  }

  void _showError(String message) {
    Haptics.error();
    setState(() {
      _isProcessing = false;
      _cooldownUntil = DateTime.now().add(AppConstants.errorCooldownDuration);
    });

    AppFeedback.error(context, message);
  }
  
  /// V-005: Show warning when card is being redeemed on a different device
  Future<void> _showDeviceMismatchWarning(BuildContext context, RedemptionRequestToken token) async {
    setState(() {
      _isProcessing = false;
    });
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('Device Mismatch')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This card is being redeemed on a different device than where it was created.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Possible reasons:'),
              const SizedBox(height: 8),
              const Text('• Customer got a new phone'),
              const Text('• Customer restored from backup'),
              const Text('• Card was cloned/duplicated (fraud)'),
              const SizedBox(height: 16),
              const Text(
                'Verify the customer\'s identity and check stamp history before proceeding.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Proceed Anyway'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (result == true) {
      // User chose to proceed despite mismatch
      AppLogger.warning('Supplier chose to proceed with device mismatch', 'Security');
      await _showSecureModeRedemptionConfirmation(context, token.cardId, token.stampsCollected, token: token);
    } else {
      // User cancelled
      AppLogger.warning('Supplier cancelled redemption due to device mismatch', 'Security');
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

// Screen to display redemption token QR code
class _RedemptionTokenScreen extends StatelessWidget {
  final RedemptionToken token;
  final int stampsRedeemed;

  const _RedemptionTokenScreen({
    required this.token,
    required this.stampsRedeemed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redemption Token'),
        backgroundColor: BrandColors.success,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              const Icon(
                Icons.celebration,
                size: 80,
                color: Colors.purple,
              ),
              const SizedBox(height: 24),

              // Instructions
              const Text(
                'Reward Redeemed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$stampsRedeemed stamps completed',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              
              // Customer instruction
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BrandColors.successContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BrandColors.success.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: BrandColors.success, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Now ask customer to scan this redemption code to complete the transaction',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: BrandColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: token.toQRString(),
                  version: QrVersions.auto,
                  size: QRCodeSize.calculate(context),
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Done button
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: BrandColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
