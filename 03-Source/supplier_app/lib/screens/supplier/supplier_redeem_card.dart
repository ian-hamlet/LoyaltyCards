import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared/shared.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../services/business_repository.dart';
import '../../services/key_manager.dart';
import '../../services/device_orientation_service.dart';

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
  bool _isProcessing = false;
  int _manualRotationOffset = 0; // 0, 1, 2, or 3 quarter turns

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem Card'),
        backgroundColor: BrandColors.success,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.green[50],
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Scan customer\'s completed card to redeem reward',
                        style: TextStyle(
                          color: Colors.green[900],
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
                    
                    print('=== Redeem Card Scanner Orientation ===');
                    print('Orientation: ${isLandscape ? "Landscape" : "Portrait"}');
                    print('Status bar: $statusBarPosition');
                    print('Padding - Top: ${padding.top}, Bottom: ${padding.bottom}, Left: ${padding.left}, Right: ${padding.right}');
                    print('Base quarterTurns: $baseQuarterTurns, Manual offset: $_manualRotationOffset');
                    print('Final quarterTurns: $quarterTurns (${quarterTurns * 90} degrees)');
                    
                    return RotatedBox(
                      quarterTurns: quarterTurns,
                      child: MobileScanner(
                        controller: cameraController,
                        fit: BoxFit.contain,
                        onDetect: (capture) {
                          if (_isProcessing) return;
                    
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
                      Icon(Icons.rotate_90_degrees_cw, size: 20, color: Colors.green),
                      Text('90°', style: TextStyle(fontSize: 10, color: Colors.green)),
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
                      Icon(Icons.flip, size: 20, color: Colors.green),
                      Text('180°', style: TextStyle(fontSize: 10, color: Colors.green)),
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

  void _processCardQR(String qrData) {
    setState(() {
      _isProcessing = true;
    });

    print('=== Processing Redemption QR ===');
    print('QR Data: ${qrData.substring(0, qrData.length > 100 ? 100 : qrData.length)}...');

    try {
      // Try parsing as JSON token first (new format)
      final json = jsonDecode(qrData) as Map<String, dynamic>;
      
      if (json['type'] == 'redemption_request') {
        final token = RedemptionRequestToken.fromJson(json);
        print('Redemption token parsed successfully');
        print('Card ID: ${token.cardId}');
        print('Stamps collected: ${token.stampsCollected}');
        print('Signatures to verify: ${token.stampSignatures.length}');
        
        _showRedemptionConfirmation(context, token.cardId, token.stampsCollected);
        return;
      } else if (json['type'] == 'card_stamp_request') {
        // Customer is showing a stamp request QR, not a redemption QR
        // This means their card isn't complete yet
        final stampToken = CardStampRequestToken.fromJson(json);
        final stampsCollected = stampToken.currentStamps;
        _showError('This card isn\'t ready to redeem yet.\n\nCustomer has $stampsCollected stamps but needs all stamps to be complete before redeeming.');
        return;
      } else {
        _showError('Please scan a completed loyalty card for redemption.');
        return;
      }
    } catch (e) {
      print('Failed to parse as JSON token: $e');
      
      // Fall back to legacy format: LOYALTYCARD:REDEEM:cardId:stamps
      if (qrData.startsWith('LOYALTYCARD:REDEEM:')) {
        final parts = qrData.split(':');
        if (parts.length >= 4) {
          final cardId = parts[2];
          final stamps = int.tryParse(parts[3]) ?? 0;
          print('Legacy redemption format detected');
          _showRedemptionConfirmation(context, cardId, stamps);
          return;
        }
      }
      
      _showError('Unable to read this QR code. Please ask the customer to show their completed loyalty card.');
    }
  }

  void _showRedemptionConfirmation(BuildContext context, String cardId, int stamps) async {
    // Get business info to sign the redemption token
    final businessRepo = BusinessRepository();
    final business = await businessRepo.getBusiness();
    
    if (business == null) {
      _showError('Business not configured');
      return;
    }

    // Generate redemption token
    final now = DateTime.now();
    final keyManager = KeyManager();
    final privateKey = await keyManager.getPrivateKey(business.id);
    
    if (privateKey == null) {
      _showError('Private key not found');
      return;
    }

    // Create signature: cardId:stampsRedeemed:timestamp
    final signatureData = '$cardId:$stamps:${now.millisecondsSinceEpoch}';
    final signature = await keyManager.signData(signatureData, privateKey);

    final redemptionToken = RedemptionToken(
      cardId: cardId,
      businessId: business.id,
      stampsRedeemed: stamps,
      signature: signature,
      timestamp: now.millisecondsSinceEpoch,
    );

    print('=== Redemption Token Generated ===');
    print('Card ID: $cardId');
    print('Stamps redeemed: $stamps');
    print('Signature: ${signature.substring(0, 20)}...');
    print('Token type: redemption_token');

    // Log the redemption for analytics
    await businessRepo.logRedemption(
      cardId: cardId,
      stampsRedeemed: stamps,
      businessId: business.id,
    );
    print('Redemption logged to database');

    // Show QR code for customer to scan
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _RedemptionTokenScreen(
            token: redemptionToken,
            stampsRedeemed: stamps,
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
  }

  void _showError(String message) {
    setState(() {
      _isProcessing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                  size: 280,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Instructions for customer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.green[700], size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'Customer: Scan this QR code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This confirms the redemption and prevents the card from being used again.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
