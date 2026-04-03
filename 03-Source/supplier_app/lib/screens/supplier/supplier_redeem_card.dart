import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple[50],
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scan customer\'s completed card to redeem reward',
                    style: TextStyle(color: Colors.purple[900]),
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
    );
  }

  void _processCardQR(String qrData) {
    setState(() {
      _isProcessing = true;
    });

    // Parse QR data
    // Expected format: LOYALTYCARD:REDEEM:cardId:stamps
    if (qrData.startsWith('LOYALTYCARD:REDEEM:')) {
      final parts = qrData.split(':');
      if (parts.length >= 4) {
        final cardId = parts[2];
        final stamps = int.tryParse(parts[3]) ?? 0;
        
        _showRedemptionConfirmation(context, cardId, stamps);
      }
    } else {
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
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Card will be reset after redemption',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
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
                  content: Text('Card redeemed! Customer earned their reward 🎁'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Redeem Now'),
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
