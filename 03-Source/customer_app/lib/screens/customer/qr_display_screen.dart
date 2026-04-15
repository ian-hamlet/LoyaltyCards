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
  bool _instructionsExpanded = false; // Track if instructions are expanded
  int _qrGeneratedTime = 0; // Track when QR was generated

  @override
  void initState() {
    super.initState();
    AppLogger.qr('QR Display Screen initialized - Card: ${widget.card.id.substring(0, 8)}, Stamps: ${widget.card.stampsCollected}, Mode: ${widget.mode}');
    _generateQRData();
  }

  Future<void> _generateQRData() async {
    AppLogger.debug('Generating QR data', 'QR');
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
            _qrGeneratedTime = DateTime.now().millisecondsSinceEpoch;
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
            _qrGeneratedTime = DateTime.now().millisecondsSinceEpoch;
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

                      const SizedBox(height: 24),

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
                          size: QRCodeSize.calculate(context),
                          backgroundColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Compact info badges
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            if (widget.mode == QRDisplayMode.stampRequest)
                              Row(
                                children: [
                                  Icon(Icons.info_outline, size: 14, color: Colors.orange[700]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Refresh QR (tap ⟳ above) after each stamp',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (widget.mode == QRDisplayMode.stampRequest)
                              const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 14, color: Colors.orange[700]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.mode == QRDisplayMode.stampRequest
                                        ? 'Valid 1 min (expires ${_getExpiryTime(1)})'
                                        : 'Valid 2 min (expires ${_getExpiryTime(2)})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _getExpiryTime(int validityMinutes) {
    if (_qrGeneratedTime == 0) return '--:--';
    
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(_qrGeneratedTime)
        .add(Duration(minutes: validityMinutes));
    
    final hour = expiryTime.hour.toString().padLeft(2, '0');
    final minute = expiryTime.minute.toString().padLeft(2, '0');
    
    return '$hour:$minute';
  }
}

enum QRDisplayMode {
  stampRequest,
  redemption,
}
