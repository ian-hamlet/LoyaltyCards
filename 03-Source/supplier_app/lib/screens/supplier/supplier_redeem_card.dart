import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared/shared.dart' hide Card;
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
  final BusinessRepository _businessRepo = BusinessRepository();
  
  Business? _business;
  bool _isProcessing = false;
  bool _isLoading = true;
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green[700], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Simple Mode - Manual Redemption',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Honor-based system - verify customer has completed card',
                              style: TextStyle(
                                color: Colors.green[800],
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
            label: const Text('Confirm Redemption'),
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

  Future<void> _processManualRedemption() async {
    setState(() => _isProcessing = true);

    try {
      // Log the redemption with timestamp
      final now = DateTime.now();
      final cardId = 'simple_redemption_${now.millisecondsSinceEpoch}';
      
      await _businessRepo.logRedemption(
        cardId: cardId,
        stampsRedeemed: _business!.stampsRequired,
        businessId: _business!.id,
      );

      AppLogger.business('Simple Mode Redemption Logged');
      AppLogger.debug('Business: ${_business!.name}', 'Redemption');
      AppLogger.debug('Stamps: ${_business!.stampsRequired}', 'Redemption');
      AppLogger.debug('Timestamp: ${now.toIso8601String()}', 'Redemption');

      if (mounted) {
        setState(() => _isProcessing = false);
        
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
                  'Redeemed: ${_business!.stampsRequired} stamps',
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
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Error recording redemption: $e');
      }
    }
  }

  void _processCardQR(String qrData) {
    setState(() {
      _isProcessing = true;
    });

    AppLogger.qr('Processing Redemption QR');
    AppLogger.qr('QR Data: ${qrData.substring(0, qrData.length > 100 ? 100 : qrData.length)}...');

    try {
      // Try parsing as JSON token first (new format)
      final json = jsonDecode(qrData) as Map<String, dynamic>;
      
      if (json['type'] == 'redemption_request') {
        final token = RedemptionRequestToken.fromJson(json);
        AppLogger.qr('Redemption token parsed successfully');
        AppLogger.qr('Card ID: ${token.cardId}');
        AppLogger.qr('Stamps collected: ${token.stampsCollected}');
        AppLogger.qr('Signatures to verify: ${token.stampSignatures.length}');
        
        _showSecureModeRedemptionConfirmation(context, token.cardId, token.stampsCollected);
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
      AppLogger.debug('Failed to parse as JSON token: $e', 'QR');
      
      // Fall back to legacy format: LOYALTYCARD:REDEEM:cardId:stamps
      if (qrData.startsWith('LOYALTYCARD:REDEEM:')) {
        final parts = qrData.split(':');
        if (parts.length >= 4) {
          final cardId = parts[2];
          final stamps = int.tryParse(parts[3]) ?? 0;
          AppLogger.qr('Legacy redemption format detected');
          _showSecureModeRedemptionConfirmation(context, cardId, stamps);
          return;
        }
      }
      
      _showError('Unable to read this QR code. Please ask the customer to show their completed loyalty card.');
    }
  }

  void _showSecureModeRedemptionConfirmation(BuildContext context, String cardId, int stamps) async {
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
    
    if (signature == null) {
      _showError('Failed to sign redemption token');
      return;
    }

    final redemptionToken = RedemptionToken(
      cardId: cardId,
      businessId: business.id,
      stampsRedeemed: stamps,
      signature: signature,
      timestamp: now.millisecondsSinceEpoch,
    );

    AppLogger.business('Redemption Token Generated');
    AppLogger.debug('Card ID: $cardId', 'Redemption');
    AppLogger.debug('Stamps redeemed: $stamps', 'Redemption');
    AppLogger.debug('Signature: ${signature.substring(0, 20)}...', 'Redemption');
    AppLogger.debug('Token type: redemption_token', 'Redemption');

    // Log the redemption for analytics
    await businessRepo.logRedemption(
      cardId: cardId,
      stampsRedeemed: stamps,
      businessId: business.id,
    );
    AppLogger.database('Redemption logged to database');

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
    
    AppFeedback.error(context, message);
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
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.green[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Now ask customer to scan this redemption code to complete the transaction',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[900],
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
