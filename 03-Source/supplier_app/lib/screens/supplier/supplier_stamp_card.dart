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
                    'Position customer\'s QR code in the frame',
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
        title: const Text('Add Stamp?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.coffee, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Customer currently has $currentStamps stamps',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Add one more stamp?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
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
                  content: Text('Stamp added successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Add Stamp'),
          ),
        ],
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
            hintText: 'e.g., card-123',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _processCardQR('LOYALTYCARD:SHOW:${controller.text}:0');
              }
            },
            child: const Text('Process'),
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
