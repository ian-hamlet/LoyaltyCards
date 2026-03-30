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
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
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
                    'Scan customer\\'s completed card to redeem reward',
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
        
        Navigator.pop(context);
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
        title: const Text('🎉 Confirm Redemption'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Card ID: ${cardId.substring(0, 8).toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Completed Stamps: $stamps'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Customer earns FREE item!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _completeRedemption(context, cardId);
            },
            icon: const Icon(Icons.card_giftcard),
            label: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  void _completeRedemption(BuildContext context, String cardId) {
    // In real app, this would generate redemption token and reset card
    final redemptionToken = 'REDEEM:$cardId:${DateTime.now().millisecondsSinceEpoch}';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('✅ Redemption Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              size: 80,
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
            const Text(
              'Card has been redeemed and reset!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Customer can start collecting stamps again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == '/supplier_home');
            },
            child: const Text('Done'),
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
