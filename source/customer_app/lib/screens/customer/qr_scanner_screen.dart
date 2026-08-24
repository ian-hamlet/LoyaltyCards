import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared/shared.dart' hide Card;
import '../../controllers/controller_results.dart';
import '../../controllers/qr_scanner_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

// QRScanMode moved to the controller so it can be used without importing any
// UI. Re-exported here so every existing `import '.../qr_scanner_screen.dart'`
// call site keeps working unchanged.
export '../../controllers/qr_scanner_controller.dart' show QRScanMode;

/// Scanner screen for adding new cards or receiving stamps
/// 
/// **SMART ROUTING** (Simple Mode):
/// When scanning a stamp QR code, the app uses "smart routing" to ensure
/// stamps always go to the correct business card, regardless of which card
/// screen you're currently viewing. For example:
/// - You have cards for "Coffee Shop" and "Restaurant" 
/// - You open the "Coffee Shop" card screen
/// - You scan a "Restaurant" stamp QR code
/// - The stamp is intelligently routed to your "Restaurant" card (not Coffee Shop)
/// - This happens automatically based on the businessId in the QR code
/// 
/// This makes the scanning experience more forgiving - you don't need to be on
/// the correct card screen to receive stamps. The system finds the right card for you.
/// 
/// **SECURE MODE:**
/// Uses exact cardId matching - each card has a unique ID that must match the QR code.
/// 
/// **AUTO NEW CARD CREATION:**
/// When a card reaches stampsRequired (is complete), a new card is automatically
/// created for the same business. If there are overflow stamps from the scan,
/// they are placed on the new card. Users are notified with a success message.
class QRScannerScreen extends StatefulWidget {
  final QRScanMode mode;

  const QRScannerScreen({
    super.key,
    required this.mode,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();

  // All scan-handling logic lives in the controller, so it can be tested
  // without a camera or a widget tree - see
  // controllers/qr_scanner_controller.dart, which follows the convention
  // established in controllers/customer_card_detail_controller.dart.
  final QrScannerController _scanController = QrScannerController();

  bool _isProcessing = false;
  String? _errorMessage;
  DateTime? _cooldownUntil;
  int _manualRotationOffset = 1; // 0, 1, 2, or 3 quarter turns (1 = 90° to fix mobile_scanner 7.2.0)

  @override
  void initState() {
    super.initState();
    _loadRotationPreference();
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
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

  Future<void> _handleQRCode(String qrData) async {
    if (_isProcessing) return;
    if (_cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!)) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final result = await _scanController.handleQrCode(
      qrData,
      widget.mode,
      // Immediate feedback that a readable code was recognized, distinct
      // from whether the scan ultimately succeeds - this is the main
      // signal a non-visual user has that the camera actually registered
      // anything at all, since there's no other non-visual affordance on
      // this screen. _showScanError below covers all rejection paths.
      onTokenRecognized: Haptics.success,
    );

    if (!mounted) return;
    _applyScanResult(result);
  }

  /// Renders one controller outcome. Three distinct screen behaviours here,
  /// which is why the controller returns a reason enum rather than just a
  /// message: a rate-limited scan leaves the camera immediately with a
  /// snackbar and no result, an already-in-wallet card leaves with its
  /// message as an ordinary result, and every genuine rejection stays put
  /// and shows the inline error panel.
  void _applyScanResult(ScanResult result) {
    if (result.isSuccess) {
      Navigator.pop(context, result.message);
      return;
    }

    switch (result.failureReason!) {
      case ScanFailureReason.rateLimited:
        // Immediately pop back to the card screen to prevent abuse - staying
        // on the camera would let the customer simply wait out the timeout
        // and scan again.
        ScaffoldMessenger.of(context).clearSnackBars(); // prevent stacking
        AppFeedback.error(context, result.message ?? 'Please wait before scanning again');
        Navigator.pop(context, null);
        return;
      case ScanFailureReason.alreadyScanned:
        Navigator.pop(context, result.message);
        return;
      case ScanFailureReason.invalidQr:
      case ScanFailureReason.wrongTokenType:
      case ScanFailureReason.validationFailed:
      case ScanFailureReason.cardNotFound:
      case ScanFailureReason.businessMismatch:
      case ScanFailureReason.signatureInvalid:
      case ScanFailureReason.alreadyRedeemed:
      case ScanFailureReason.cardNotComplete:
      case ScanFailureReason.creditingAborted:
      case ScanFailureReason.unexpectedError:
        _showScanError(result.message!);
        return;
    }
  }

  void _showScanError(String message) {
    Haptics.error();
    setState(() {
      _errorMessage = message;
      _isProcessing = false;
      _cooldownUntil = DateTime.now().add(AppConstants.errorCooldownDuration);
    });
  }


  @override
  Widget build(BuildContext context) {
    final title = widget.mode == QRScanMode.addCard
        ? 'Scan your shop\'s card QR'
        : 'Scan Stamp QR';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: Stack(
        children: [
          // Camera view
          LayoutBuilder(
            builder: (context, constraints) {
              final mediaQuery = MediaQuery.of(context);
              final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
              
              // Apply rotation: base + manual offset
              final baseQuarterTurns = isLandscape ? 3 : 0;
              final quarterTurns = (baseQuarterTurns + _manualRotationOffset) % 4;
              
              AppLogger.debug('QR Scanner Orientation');
              AppLogger.debug('Orientation: ${isLandscape ? "Landscape" : "Portrait"}');
              AppLogger.debug('Base quarterTurns: $baseQuarterTurns, Manual offset: $_manualRotationOffset');
              AppLogger.debug('Applying quarterTurns: $quarterTurns (${quarterTurns * 90} degrees)');
              
              return RotatedBox(
                quarterTurns: quarterTurns,
                child: MobileScanner(
                  controller: _controller,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error) => ScannerPermissionErrorView(error: error),
                  onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                final code = barcodes.first.rawValue;
                if (code != null) {
                  _handleQRCode(code);
                }
                  }
                },
                ),
              );
            },
          ),
          // Camera controls
          Positioned(
            top: 80,
            right: 16,
            child: Column(
              children: [
                // Camera flip (front/back switch)
                FloatingActionButton(
                  heroTag: 'flip_camera',
                  mini: true,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  onPressed: () {
                    _controller.switchCamera();
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flip_camera_ios, size: 16, color: Colors.blue),
                      ScaleCapped(child: Text('Flip', style: TextStyle(fontSize: 8, height: 1.0, color: Colors.blue))),
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
                      Icon(Icons.rotate_90_degrees_cw, size: 16, color: Colors.blue),
                      ScaleCapped(child: Text('90°', style: TextStyle(fontSize: 8, height: 1.0, color: Colors.blue))),
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
                      Icon(Icons.flip, size: 16, color: Colors.blue),
                      ScaleCapped(child: Text('180°', style: TextStyle(fontSize: 8, height: 1.0, color: Colors.blue))),
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

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  Text(
                    widget.mode == QRScanMode.addCard
                        ? 'Point camera at business QR code'
                        : 'Point camera at stamp token',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isProcessing) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Flashlight toggle
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white, size: 32),
              onPressed: () => _controller.toggleTorch(),
            ),
          ),
        ],
      ),
    );
  }
}
