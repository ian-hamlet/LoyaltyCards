import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CustomerAddCard extends StatefulWidget {
  const CustomerAddCard({super.key});

  @override
  State<CustomerAddCard> createState() => _CustomerAddCardState();
}

class _CustomerAddCardState extends State<CustomerAddCard> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Loyalty Card'),
      ),
      body: Column(
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
                    'Scan the QR code from the business to add their loyalty card',
                    style: TextStyle(color: Colors.blue[900]),
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
                    _processQRCode(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
          ),

          // Mock Data Button (for testing without camera)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                // Simulate scanning a card
                _processQRCode('LOYALTYCARD:ISSUE:test-card-123:Bakery Corner:5');
              },
              icon: const Icon(Icons.science),
              label: const Text('Use Mock Data (Testing)'),
            ),
          ),
        ],
      ),
    );
  }

  void _processQRCode(String qrData) {
    setState(() {
      _isProcessing = true;
    });

    // Parse QR data
    // Expected format: LOYALTYCARD:ISSUE:cardId:businessName:stampsRequired
    if (qrData.startsWith('LOYALTYCARD:ISSUE:')) {
      final parts = qrData.split(':');
      if (parts.length >= 5) {
        final cardId = parts[2];
        final businessName = parts[3];
        final stampsRequired = int.tryParse(parts[4]) ?? 7;
        
        _showCardConfirmation(
          context,
          cardId,
          businessName,
          stampsRequired,
        );
      }
    } else {
      _showError('Invalid QR code. Please scan a supplier card issuance code.');
    }
  }

  void _showCardConfirmation(
    BuildContext context,
    String cardId,
    String businessName,
    int stampsRequired,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Loyalty Card?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.store, color: Colors.white),
              ),
              title: Text(
                businessName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Buy $stampsRequired, Get ${stampsRequired + 1}th FREE'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Start collecting stamps now!'),
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
              // TODO: Implement actual card creation from QR data
              // For now, just navigate back - actual implementation in Phase 3
              Navigator.pop(context);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Card scanning will be implemented in Phase 3'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Add Card'),
          ),
        ],
      ),
    );
  }

  Color _generateColor(String businessName) {
    // Simple deterministic color generation based on business name
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.brown,
      Colors.indigo,
    ];
    
    final hash = businessName.hashCode;
    return colors[hash.abs() % colors.length];
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
