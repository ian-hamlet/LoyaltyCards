import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared/shared.dart';
import 'dart:convert';
import '../../services/card_repository.dart';
import '../../services/database_helper.dart';
import '../../services/device_orientation_service.dart';

class CustomerAddCard extends StatefulWidget {
  const CustomerAddCard({super.key});

  @override
  State<CustomerAddCard> createState() => _CustomerAddCardState();
}

class _CustomerAddCardState extends State<CustomerAddCard> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  int _manualRotationOffset = 1; // 0, 1, 2, or 3 quarter turns (1 = 90° to fix mobile_scanner 7.2.0)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Loyalty Card'),
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
                        'Scan the QR code from the business to add their loyalty card',
                        style: TextStyle(color: Colors.blue[900]),
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
                    
                    print('=== Add Card Scanner Orientation ===');
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
                              _processQRCode(barcode.rawValue!);
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
              Haptics.light();
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Haptics.medium();
              // TODO: Implement actual card creation from QR data
              // For now, just navigate back - actual implementation in Phase 3
              Navigator.pop(context);
              Navigator.pop(context);
              
              AppFeedback.info(context, 'Card scanning will be implemented in Phase 3');
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
    
    AppFeedback.error(context, message);
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
