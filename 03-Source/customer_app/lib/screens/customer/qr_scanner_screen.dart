import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import '../../services/token_validator.dart';
import '../../services/card_repository.dart';
import '../../services/stamp_repository.dart';
import '../../services/rate_limiter.dart';
import '../../services/database_helper.dart';

/// Scanner screen for adding new cards or receiving stamps
class QRScannerScreen extends StatefulWidget {
  final QRScanMode mode;

  const QRScannerScreen({
    super.key,
    required this.mode,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final token = QRToken.fromQRString(qrData);

      if (token == null) {
        setState(() {
          _errorMessage = 'Invalid QR code format';
          _isProcessing = false;
        });
        return;
      }

      switch (widget.mode) {
        case QRScanMode.addCard:
          await _handleCardIssue(token);
          break;
        case QRScanMode.receiveStamp:
          await _handleStampToken(token);
          break;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing QR: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleCardIssue(QRToken token) async {
    if (token is! CardIssueToken) {
      setState(() {
        _errorMessage = 'Wrong QR type. Please scan a card issuance QR.';
        _isProcessing = false;
      });
      return;
    }

    // Validate token
    final validation = await TokenValidator.validateCardIssueToken(token);
    if (!validation.isValid) {
      setState(() {
        _errorMessage = validation.error ?? 'Invalid token';
        _isProcessing = false;
      });
      return;
    }

    // Create card from token
    final card = models.Card(
      id: '${token.businessId}_${DateTime.now().millisecondsSinceEpoch}',
      businessId: token.businessId,
      businessName: token.businessName,
      businessPublicKey: token.publicKey,
      stampsRequired: token.stampsRequired,
      stampsCollected: 0,
      brandColor: token.brandColor.replaceAll('#', ''),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save card to database
    final repository = CardRepository(DatabaseHelper());
    await repository.insertCard(card);

    if (mounted) {
      // Success! Return to home with success message
      Navigator.pop(context, 'Card added: ${card.businessName}');
    }
  }

  Future<void> _handleStampToken(QRToken token) async {
    if (token is! StampToken) {
      setState(() {
        _errorMessage = 'Wrong QR type. Please scan a stamp token QR.';
        _isProcessing = false;
      });
      return;
    }

    // Get the card this stamp is for
    final repository = CardRepository(DatabaseHelper());
    final card = await repository.getCardById(token.cardId);

    if (card == null) {
      setState(() {
        _errorMessage = 'Card not found. Please add the card first.';
        _isProcessing = false;
      });
      return;
    }

    // Check rate limiting
    final rateLimiter = RateLimiter(DatabaseHelper());
    final rateLimit = await rateLimiter.canReceiveStamp(
      cardId: card.id,
      businessId: card.businessId,
    );

    if (!rateLimit.canProceed) {
      setState(() {
        _errorMessage = rateLimit.message ?? 'Rate limit exceeded';
        _isProcessing = false;
      });
      return;
    }

    // Get expected previous hash
    final stampRepo = StampRepository(DatabaseHelper());
    final stamps = await stampRepo.getStampsByCard(card.id);
    final expectedPrevHash = stamps.isNotEmpty ? stamps.last.signature : '';

    // Validate stamp token
    final validation = await TokenValidator.validateStampToken(
      token: token,
      businessPublicKey: card.businessPublicKey,
      expectedPreviousHash: expectedPrevHash,
    );

    if (!validation.isValid) {
      setState(() {
        _errorMessage = validation.error ?? 'Invalid stamp';
        _isProcessing = false;
      });
      return;
    }

    // Add stamp to card
    final stamp = Stamp(
      id: token.id,
      cardId: token.cardId,
      stampNumber: token.stampNumber,
      timestamp: DateTime.fromMillisecondsSinceEpoch(token.timestamp),
      signature: token.signature,
      previousHash: token.previousHash,
    );

    await stampRepo.insertStamp(stamp);
    await repository.updateStampCount(card.id, card.stampsCollected + 1);

    if (mounted) {
      // Success! Return with success message
      Navigator.pop(context, 'Stamp added successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == QRScanMode.addCard
        ? 'Scan Card QR'
        : 'Scan Stamp QR';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                final code = barcodes.first.rawValue;
                if (code != null) {
                  _handleQRCode(code);
                }
              }
            },
          ),

          // Scanning frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  Text(
                    widget.mode == QRScanMode.addCard
                        ? 'Point camera at business QR code'
                        : 'Point camera at stamp token',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isProcessing) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Flashlight toggle
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white, size: 32),
              onPressed: () => _controller.toggleTorch(),
            ),
          ),
        ],
      ),
    );
  }
}

enum QRScanMode {
  addCard,
  receiveStamp,
}
