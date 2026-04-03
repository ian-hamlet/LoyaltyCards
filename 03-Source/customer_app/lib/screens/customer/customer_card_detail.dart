import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'customer_home.dart';

class CustomerCardDetail extends StatelessWidget {
  final LoyaltyCard card;

  const CustomerCardDetail({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(card.businessName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Card Visual
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [card.brandColor, card.brandColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: card.brandColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Business Name
                  Text(
                    card.businessName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Stamp Grid
                  _buildStampGrid(),
                  
                  const SizedBox(height: 16),
                  
                  // Progress Text
                  Text(
                    '${card.stampsCollected} of ${card.stampsRequired} stamps',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // QR Code Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Show this QR code to collect stamps or redeem',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),

            // QR Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: QrImageView(
                data: _getQRData(),
                version: QrVersions.auto,
                size: 250,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInstruction(
                    Icons.shopping_bag,
                    'Make a purchase at ${card.businessName}',
                  ),
                  const SizedBox(height: 12),
                  _buildInstruction(
                    Icons.qr_code_scanner,
                    'Show this QR code to get a stamp',
                  ),
                  const SizedBox(height: 12),
                  _buildInstruction(
                    Icons.card_giftcard,
                    'Complete ${card.stampsRequired} stamps to redeem your reward!',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStampGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(card.stampsRequired, (index) {
        final isStamped = index < card.stampsCollected;
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isStamped ? Colors.white : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Icon(
            isStamped ? Icons.check_circle : Icons.circle_outlined,
            color: isStamped ? card.brandColor : Colors.white,
            size: 32,
          ),
        );
      }),
    );
  }

  Widget _buildInstruction(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _getQRData() {
    // If card is complete, generate redemption QR
    if (card.stampsCollected >= card.stampsRequired) {
      return 'LOYALTYCARD:REDEEM:${card.id}:${card.stampsCollected}';
    }
    // Otherwise, generate regular card QR for stamping
    return 'LOYALTYCARD:SHOW:${card.id}:${card.stampsCollected}';
  }
}
