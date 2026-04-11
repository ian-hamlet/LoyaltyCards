import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared/shared.dart';
import 'dart:convert';

class SupplierRedeemCard extends StatefulWidget {
  const SupplierRedeemCard({super.key});

  @override
  State<SupplierRedeemCard> createState() => _SupplierRedeemCardState();
}

class _SupplierRedeemCardState extends State<SupplierRedeemCard> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

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
                child: MobileScanner(
                  controller: cameraController,
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
              ),
            ],
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
      } else {
        _showError('Invalid redemption QR - wrong token type: ${json['type']}');
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
      
      _showError('Invalid QR code for redemption');
    }
  }

  void _showRedemptionConfirmation(BuildContext context, String cardId, int stamps) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Redeem Reward'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 80, color: Colors.purple),
            const SizedBox(height: 16),
            Text(
              'Customer has completed their card!',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$stamps stamps collected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'Valid completed card!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Give reward and ask customer to delete the card from their app.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true); // Return success
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Reward given! Customer can now delete their completed card.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 4),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Reward Given'),
          ),
        ],
      ),
    );
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
