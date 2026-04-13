import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart' hide Card;
import '../../services/qr_token_generator.dart';
import '../../services/key_manager.dart';
import '../../services/business_repository.dart';
import '../../services/supplier_database_helper.dart';
import '../../services/device_orientation_service.dart';

class SupplierStampCard extends StatefulWidget {
  const SupplierStampCard({super.key});

  @override
  State<SupplierStampCard> createState() => _SupplierStampCardState();
}

class _SupplierStampCardState extends State<SupplierStampCard> {
  final MobileScannerController _cameraController = MobileScannerController(
    facing: CameraFacing.back,
    autoStart: true,
  );
  final BusinessRepository _businessRepo = BusinessRepository();
  final QRTokenGenerator _tokenGenerator = QRTokenGenerator(KeyManager());
  
  Business? _business;
  StampToken? _stampToken; // For simple mode QR display
  bool _isProcessing = false;
  String? _errorMessage;
  int _manualRotationOffset = 1; // 0, 1, 2, or 3 quarter turns (1 = 90° to fix mobile_scanner 7.2.0)

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    try {
      final business = await _businessRepo.getBusiness();
      setState(() {
        _business = business;
      });
      
      // Auto-generate QR for simple mode
      if (business?.mode == OperationMode.simple) {
        // Small delay to ensure widget is built
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          await _generateSimpleModeStampQR();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading business: $e';
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String qrData) async {
    if (_isProcessing) return;
    if (_business == null) {
      _showError('Business not found. Please complete onboarding.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Parse QR token
      final token = QRToken.fromQRString(qrData);

      if (token is! CardStampRequestToken) {
        setState(() {
          _errorMessage = 'Invalid QR code. Please scan a stamp request QR.';
          _isProcessing = false;
        });
        return;
      }

      // Validate token
      if (!token.isValid()) {
        setState(() {
          _errorMessage = 'Invalid token format';
          _isProcessing = false;
        });
        return;
      }

      // Check business ID matches
      if (token.businessId != _business!.id) {
        setState(() {
          _errorMessage = 'This card belongs to a different business';
          _isProcessing = false;
        });
        return;
      }

      // Log card activity (tracks unique cards using the system)
      await _businessRepo.logCardActivity(token.cardId, _business!.id);

      // Check timestamp (must be < 1 minute old)
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - token.timestamp;
      if (age > 60 * 1000) {
        setState(() {
          _errorMessage = 'QR code expired. Customer needs to generate a new one.';
          _isProcessing = false;
        });
        return;
      }

      // Generate stamp token
      final previousHash = token.lastStampHash; // Use customer's last stamp hash

      print('=== Supplier Processing Stamp Request ===');
      print('Customer card ID: ${token.cardId}');
      print('Customer current stamps: ${token.currentStamps}');
      print('Customer last stamp hash: "${token.lastStampHash.isEmpty ? "(empty)" : token.lastStampHash.substring(0, 20) + "..."}"');
      print('Will generate stamp #${token.currentStamps + 1}');
      print('=== End Supplier Processing ===');

      if (mounted) {
        // Show stamp count selector, then generate and show stamp token QR
        _showStampCountSelector(token, previousHash);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing QR: $e';
        _isProcessing = false;
      });
    }
  }

  void _showStampCountSelector(CardStampRequestToken token, String previousHash) {
    int selectedCount = 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: Icon(Icons.local_cafe, color: Colors.brown[400], size: 48),
          title: Text(
            'How many stamps?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Card currently has ${token.currentStamps} stamp${token.currentStamps != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: AppTypography.bodyLarge,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(7, (index) {
                  final count = index + 1;
                  final isSelected = selectedCount == count;
                  return ChoiceChip(
                    label: Text('$count'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        Haptics.selection();
                        setDialogState(() {
                          selectedCount = count;
                        });
                      }
                    },
                    selectedColor: Colors.blue[600],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Haptics.light();
                setState(() {
                  _isProcessing = false;
                });
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Haptics.medium();
                Navigator.pop(context);
                await _generateAndShowStamp(
                  token,
                  previousHash,
                  selectedCount,
                );
              },
              icon: const Icon(Icons.check),
              label: Text('Add $selectedCount'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndShowStamp(
    CardStampRequestToken token,
    String previousHash,
    int stampCount,
  ) async {
    try {
      final additionalStampCount = stampCount - 1; // First stamp is main, rest are additional
      
      final stampToken = await _tokenGenerator.generateStampToken(
        businessId: _business!.id,
        cardId: token.cardId,
        stampNumber: token.currentStamps + 1,
        previousHash: previousHash,
        additionalStampCount: additionalStampCount,
      );

      // NOTE: Stamps are logged when CUSTOMER successfully scans and validates,
      // not when supplier generates the token. This prevents counting stamps
      // that were generated but never received due to errors.

      if (mounted) {
        _showStampTokenQR(stampToken, token.currentStamps, stampCount);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating stamp: $e';
        _isProcessing = false;
      });
    }
  }

  void _showStampTokenQR(StampToken token, int currentStamps, int stampCount) {
    final newStampCount = currentStamps + stampCount;
    final stampText = stampCount > 1 ? '$stampCount Stamps' : 'Stamp ${token.stampNumber}';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                '$stampText Added!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Progress: $currentStamps → $newStampCount',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Stamp Token QR
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: QrImageView(
                  data: token.toQRString(),
                  version: QrVersions.auto,
                  size: QRCodeSize.calculate(context),
                  backgroundColor: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _business!.mode == OperationMode.simple
                      ? Colors.blue.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _business!.mode == OperationMode.simple
                          ? Icons.all_inclusive
                          : Icons.timer_outlined,
                      size: 16,
                      color: _business!.mode == OperationMode.simple
                          ? Colors.blue.shade700
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _business!.mode == OperationMode.simple
                          ? 'Reusable QR (no expiry)'
                          : 'Valid for 2 min (expires ${_getExpiryTime(token)})',
                      style: TextStyle(
                        fontSize: 12,
                        color: _business!.mode == OperationMode.simple
                            ? Colors.blue.shade900
                            : Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to home
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getExpiryTime(StampToken token) {
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(token.timestamp)
        .add(const Duration(minutes: 2));
    
    final hour = expiryTime.hour.toString().padLeft(2, '0');
    final minute = expiryTime.minute.toString().padLeft(2, '0');
    
    return '$hour:$minute';
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isProcessing = false;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _generateSimpleModeStampQR() async {
    if (_business == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // For simple mode, generate a generic stamp token
      // It's reusable and doesn't require customer card info
      final stampToken = await _tokenGenerator.generateStampToken(
        businessId: _business!.id,
        cardId: 'simple-mode-stamp', // Generic ID for simple mode
        stampNumber: 1, // Generic stamp number
        previousHash: '', // No hash chain in simple mode
        additionalStampCount: 0,
      );

      if (mounted) {
        setState(() {
          _stampToken = stampToken;
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating stamp: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_business == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Stamp Card'),
          backgroundColor: const Color(0xFF2C3E50),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Simple mode: Show stamp QR directly
    if (_business!.mode == OperationMode.simple) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Stamp Card'),
          backgroundColor: const Color(0xFF2C3E50),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _generateSimpleModeStampQR,
              tooltip: 'Regenerate QR',
            ),
          ],
        ),
        body: _stampToken == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Card
                    Card(
                      elevation: 1,
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Simple Mode - Reusable QR',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Customer scans this QR to add a stamp',
                                    style: TextStyle(
                                      color: Colors.blue[800],
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
                    
                    const SizedBox(height: 16),
                    
                    // QR Code Display
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              BusinessIcons.getIcon(_business!.logoIndex),
                              size: 40,
                              color: BrandColors.fromHex(_business!.brandColor),
                            ),
                            const SizedBox(height: 8),
                            
                            Text(
                              _business!.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.all_inclusive, size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 6),
                                Text(
                                  'Reusable Stamp QR',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // QR Code
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: QrImageView(
                                data: _stampToken!.toQRString(),
                                version: QrVersions.auto,
                                size: QRCodeSize.calculate(context),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      );
    }

    // Secure mode: Show camera scanner
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stamp Card'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ask customer to show their card QR code',
                        style: TextStyle(
                          color: Colors.blue[900],
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
                    
                    print('=== Stamp Card Scanner Orientation ===');
                    print('Orientation: ${isLandscape ? "Landscape" : "Portrait"}');
                    print('Status bar: $statusBarPosition');
                    print('Padding - Top: ${padding.top}, Bottom: ${padding.bottom}, Left: ${padding.left}, Right: ${padding.right}');
                    print('Base quarterTurns: $baseQuarterTurns, Manual offset: $_manualRotationOffset');
                    print('Final quarterTurns: $quarterTurns (${quarterTurns * 90} degrees)');
                    
                    return RotatedBox(
                      quarterTurns: quarterTurns,
                      child: MobileScanner(
                        controller: _cameraController,
                        fit: BoxFit.contain,
                        onDetect: (capture) {
                          if (_isProcessing) return;
                    
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
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
              ),
            ],
          ),

          // Manual rotation controls
          Positioned(
            top: 80,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'rotate90',
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
                  heroTag: 'rotate180',
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

          // Error message
          if (_errorMessage != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
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
              onPressed: () => _cameraController.toggleTorch(),
            ),
          ),
        ],
      ),
    );
  }
}
