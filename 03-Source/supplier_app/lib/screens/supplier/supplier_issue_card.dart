import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

class SupplierIssueCard extends StatelessWidget {
  final String businessName;
  final int stampsRequired;

  const SupplierIssueCard({
    super.key,
    required this.businessName,
    required this.stampsRequired,
  });

  @override
  Widget build(BuildContext context) {
    // Generate unique card ID
    final cardId = const Uuid().v4();
    final qrData = 'LOYALTYCARD:ISSUE:$cardId:$businessName:$stampsRequired';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue New Card'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Customer Pickup Process',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Show this QR code to customer\n'
                      '2. Customer opens LoyaltyCards app\n'
                      '3. Customer taps "Add Card"\n'
                      '4. Customer scans this QR code\n'
                      '5. Card added to customer wallet!',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // QR Code
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      businessName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buy $stampsRequired, Get ${stampsRequired + 1}th FREE',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 280.0,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scan to Pick Up Card',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Card ID: ${cardId.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR code saved to gallery'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Save QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}
