import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SupplierStampCard extends StatefulWidget {
  const SupplierStampCard({super.key});

  @override
  State<SupplierStampCard> createState() => _SupplierStampCardState();
}

class _SupplierStampCardState extends State<SupplierStampCard> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stamp Card'),
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
            color: Colors.orange[50],
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Position customer\\'s QR code in the frame',
                    style: TextStyle(color: Colors.orange[900]),
                  ),
                ),
              ],
            ),
          ),

          // Scanner
          Expanded(
            flex: 4,
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

          // Manual Entry Option
          Expanded(
            flex: 1,
            child: Center(
              child: TextButton.icon(
                onPressed: () => _showManualEntry(context),
                icon: const Icon(Icons.keyboard),
                label: const Text('Enter Card ID Manually'),
              ),
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
    // Expected format: LOYALTYCARD:SHOW:cardId:currentStamps
    if (qrData.startsWith('LOYALTYCARD:SHOW:')) {
      final parts = qrData.split(':');
      if (parts.length >= 4) {
        final cardId = parts[2];
        final currentStamps = int.tryParse(parts[3]) ?? 0;
        
        Navigator.pop(context);
        _showStampConfirmation(context, cardId, currentStamps);
      }
    } else {
      _showError('Invalid QR code. Please scan a customer card.');
    }
  }

  void _showStampConfirmation(BuildContext context, String cardId, int currentStamps) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Stamp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Card ID: ${cardId.substring(0, 8).toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Current Stamps: $currentStamps'),
            const SizedBox(height: 8),
            Text(
              'New Stamps: ${currentStamps + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _generateStampToken(context, cardId, currentStamps + 1);
            },
            child: const Text('Add Stamp'),
          ),
        ],
      ),
    );
  }

  void _generateStampToken(BuildContext context, String cardId, int newStampCount) {
    // In real app, this would generate cryptographic signature
    final stampToken = 'STAMP:$cardId:$newStampCount:${DateTime.now().millisecondsSinceEpoch}';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _StampTokenScreen(
          cardId: cardId,
          newStampCount: newStampCount,
          stampToken: stampToken,
        ),
      ),
    );
  }

  void _showManualEntry(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Card ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Card ID',
            hintText: 'ABC123XY',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _processCardQR('LOYALTYCARD:SHOW:${controller.text}:3');
            },
            child: const Text('Submit'),
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

class _StampTokenScreen extends StatelessWidget {
  final String cardId;
  final int newStampCount;
  final String stampToken;

  const _StampTokenScreen({
    required this.cardId,
    required this.newStampCount,
    required this.stampToken,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stamp Added'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Stamp Added Successfully!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Card now has $newStampCount stamps',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Customer: Scan this QR code',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    // In real app, display QR code with stampToken
                    Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text('[QR Code Here]'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == '/supplier_home');
              },
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
