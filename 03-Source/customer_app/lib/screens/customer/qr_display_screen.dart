import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import '../../services/qr_token_generator.dart';
import '../../services/stamp_repository.dart';
import '../../services/database_helper.dart';

/// Screen to display customer QR codes for supplier scanning
class QRDisplayScreen extends StatelessWidget {
  final models.Card card;
  final QRDisplayMode mode;

  const QRDisplayScreen({
    super.key,
    required this.card,
    required this.mode,
  });

  Future<String> _generateQRData() async {
    final generator = QRTokenGenerator();

    switch (mode) {
      case QRDisplayMode.stampRequest:
        final token = generator.generateStampRequest(card: card);
        return token.toQRString();

      case QRDisplayMode.redemption:
        // Get all stamps for verification
        final stampRepo = StampRepository(DatabaseHelper());
        final stamps = await stampRepo.getStampsByCard(card.id);
        final token = generator.generateRedemptionRequest(
          card: card,
          stamps: stamps,
        );
        return token.toQRString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = mode == QRDisplayMode.stampRequest
        ? 'Request Stamp'
        : 'Redeem Reward';

    final instruction = mode == QRDisplayMode.stampRequest
        ? 'Show this QR code to ${card.businessName} to receive a stamp'
        : 'Show this QR code to redeem your reward';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Color(
          int.parse('FF${card.brandColor}', radix: 16),
        ),
      ),
      body: FutureBuilder<String>(
        future: _generateQRData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error generating QR code',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final qrData = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Business name
                Text(
                  card.businessName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Stamp count
                if (mode == QRDisplayMode.stampRequest)
                  Text(
                    'Current stamps: ${card.stampsCollected} / ${card.stampsRequired}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  )
                else
                  Text(
                    'Card Complete! 🎉',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
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
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 280,
                    backgroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          instruction,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Additional info for redemption
                if (mode == QRDisplayMode.redemption) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'After redemption, your card will be reset and ready to collect new stamps.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // QR expires warning
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mode == QRDisplayMode.stampRequest
                            ? 'Valid for 1 minute'
                            : 'Valid for 2 minutes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum QRDisplayMode {
  stampRequest,
  redemption,
}
