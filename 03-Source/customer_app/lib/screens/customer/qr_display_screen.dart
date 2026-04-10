import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import '../../services/qr_token_generator.dart';
import '../../services/stamp_repository.dart';
import '../../services/database_helper.dart';

/// Screen to display customer QR codes for supplier scanning
class QRDisplayScreen extends StatefulWidget {
  final models.Card card;
  final QRDisplayMode mode;

  const QRDisplayScreen({
    super.key,
    required this.card,
    required this.mode,
  });

  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen> {
  String? _qrData;
  bool _isLoading = true;
  String? _error;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║ QR DISPLAY SCREEN - BUILD 4 CODE RUNNING                 ║');
    print('╚═══════════════════════════════════════════════════════════╝');
    print('!!! Card ID: ${widget.card.id} !!!');
    print('!!! Card Stamps: ${widget.card.stampsCollected} !!!');
    print('!!! Mode: ${widget.mode} !!!');
    _generateQRData();
  }

  Future<void> _generateQRData() async {
    print('>>> _generateQRData() called - BUILD 4 <<<');
    print('>>> Card: ${widget.card.id}, Stamps: ${widget.card.stampsCollected} <<<');
    setState(() {
      _isLoading = true;
      _error = null;
      _qrData = null; // Clear old QR data
    });

    try {
      print('QR Display: Starting QR generation for card ${widget.card.id}');
      print('QR Display: Card has ${widget.card.stampsCollected} stamps');
      final generator = QRTokenGenerator();

      switch (widget.mode) {
        case QRDisplayMode.stampRequest:
          print('QR Display: Generating stamp request QR...');
          final token = await generator.generateStampRequest(card: widget.card);
          print('QR Display: Stamp request token generated successfully');
          print('QR Display: Token currentStamps = ${token.currentStamps}');
          print('QR Display: Token lastStampHash = "${token.lastStampHash.isEmpty ? "(empty)" : token.lastStampHash.substring(0, 20) + "..."}"');
          setState(() {
            _qrData = token.toQRString();
            _isLoading = false;
          });
          print('QR Display: QR data set, screen should update');
          break;

        case QRDisplayMode.redemption:
          print('QR Display: Generating redemption QR...');
          // Get all stamps for verification
          final stampRepo = StampRepository(DatabaseHelper());
          final stamps = await stampRepo.getStampsByCard(widget.card.id);
          print('QR Display: Found ${stamps.length} stamps for redemption');
          final token = generator.generateRedemptionRequest(
            card: widget.card,
            stamps: stamps,
          );
          print('QR Display: Redemption token generated');
          print('QR Display: Card ID = ${token.cardId}');
          print('QR Display: Stamps = ${token.stampsCollected}');
          setState(() {
            _qrData = token.toQRString();
            _isLoading = false;
          });
          print('QR Display: Redemption QR ready to scan');
          break;
      }
    } catch (e, stackTrace) {
      print('QR Display ERROR: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == QRDisplayMode.stampRequest
        ? 'Request Stamp'
        : 'Redeem Reward';

    final instruction = widget.mode == QRDisplayMode.stampRequest
        ? 'Show this QR code to ${widget.card.businessName} to receive a stamp'
        : 'Show this QR code to redeem your reward';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Color(
          int.parse('FF${widget.card.brandColor}', radix: 16),
        ),
        actions: [
          if (widget.mode == QRDisplayMode.stampRequest)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _generateQRData,
              tooltip: 'Refresh QR',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                          _error!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _generateQRData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Business name
                      Text(
                        widget.card.businessName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Stamp count
                      if (widget.mode == QRDisplayMode.stampRequest)
                        Text(
                          'Current stamps: ${widget.card.stampsCollected} / ${widget.card.stampsRequired}',
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
                          data: _qrData!,
                          version: QrVersions.auto,
                          size: 280,
                          backgroundColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Refresh reminder for stamp requests
                      if (widget.mode == QRDisplayMode.stampRequest)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'After receiving a stamp, refresh this QR (tap ⟳ above) before requesting another',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

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
                      if (widget.mode == QRDisplayMode.redemption) ...[
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
                              widget.mode == QRDisplayMode.stampRequest
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
                ),
    );
  }
}

enum QRDisplayMode {
  stampRequest,
  redemption,
}
