import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import '../../services/token_validator.dart';
import '../../services/card_repository.dart';
import '../../services/stamp_repository.dart';
import '../../services/rate_limiter.dart';
import '../../services/database_helper.dart';
import '../../services/key_manager.dart';
import '../../services/device_orientation_service.dart';

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
  int _manualRotationOffset = 1; // 0, 1, 2, or 3 quarter turns (1 = 90° to fix mobile_scanner 7.2.0)

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

    // Note: In simple mode, signature validation is skipped (trust-based)
    // In secure mode, full cryptographic validation is performed
    print('Card operation mode: ${token.mode.displayName}');

    // Use card ID from token if present (for multi-stamp consistency)
    // Otherwise generate new one (backward compatibility)
    final cardId = token.cardId ?? '${token.businessId}_${DateTime.now().millisecondsSinceEpoch}';
    final initialStampCount = token.initialStamps.length;
    
    final card = models.Card(
      id: cardId,
      businessId: token.businessId,
      businessName: token.businessName,
      businessPublicKey: token.publicKey,
      stampsRequired: token.stampsRequired,
      stampsCollected: initialStampCount,
      brandColor: token.brandColor.replaceAll('#', ''),
      logoIndex: token.logoIndex,
      mode: token.mode, // Store the operation mode from token
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save card to database
    final cardRepository = CardRepository(DatabaseHelper());
    await cardRepository.insertCard(card);
    
    print('=== Processing Card Issuance ===');
    print('Card ID: $cardId');
    print('Initial stamps to process: $initialStampCount');

    // Process initial stamps if present
    if (initialStampCount > 0) {
      final stampRepository = StampRepository(DatabaseHelper());
      String previousHash = ''; // First stamp has empty previous hash

      for (var initialStamp in token.initialStamps) {
        print('Processing initial stamp #${initialStamp.stampNumber}');
        print('  Card ID for stamp: $cardId');
        
        // Verify stamp signature (skip in simple mode)
        if (token.mode == OperationMode.secure) {
          final signatureData = '$cardId:${initialStamp.stampNumber}:${initialStamp.timestamp}:$previousHash';
          final isValid = KeyManager.verifySignature(
            signatureData,
            initialStamp.signature,
            token.publicKey,
          );

          if (!isValid) {
            setState(() {
              _errorMessage = 'Invalid stamp signature at stamp #${initialStamp.stampNumber}';
              _isProcessing = false;
            });
            // Rollback: delete the card
            await cardRepository.deleteCard(cardId);
            return;
          }
        } else {
          print('  Simple mode: Skipping signature validation');
        }

        // Create and save stamp
        final stamp = Stamp(
          id: '${cardId}_stamp_${initialStamp.stampNumber}',
          cardId: cardId,
          stampNumber: initialStamp.stampNumber,
          timestamp: DateTime.fromMillisecondsSinceEpoch(initialStamp.timestamp),
          signature: initialStamp.signature,
          previousHash: previousHash.isEmpty ? null : previousHash,
        );

        await stampRepository.insertStamp(stamp);
        print('  Initial stamp #${initialStamp.stampNumber} saved to DB');
        
        // Next stamp's previous hash is this stamp's signature
        previousHash = initialStamp.signature;
      }
      
      // Verify stamps were saved
      final savedStamps = await stampRepository.getStampsByCard(cardId);
      print('Verification: ${savedStamps.length} stamps found in DB for card $cardId');
      for (var s in savedStamps) {
        print('  Stamp #${s.stampNumber}: ${s.signature.substring(0, 20)}...');
      }
      print('=== End Card Issuance Processing ===');
    }

    if (mounted) {
      // Success! Return to home with success message
      final stampText = initialStampCount > 0 
          ? ' with $initialStampCount stamp${initialStampCount > 1 ? 's' : ''}' 
          : '';
      Navigator.pop(context, 'Card added: ${card.businessName}$stampText');
    }
  }

  Future<void> _handleStampToken(QRToken token) async {
    // Handle redemption tokens
    if (token is RedemptionToken) {
      await _handleRedemptionToken(token);
      return;
    }
    
    // Handle stamp tokens
    if (token is! StampToken) {
      setState(() {
        _errorMessage = 'Wrong QR type. Please scan a stamp or redemption token QR.';
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
      mode: card.mode,
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
    
    print('=== Validating Stamp Token ===');
    print('Card ID: ${card.id}');
    print('Card mode: ${card.mode.displayName}');
    print('Stamps in DB: ${stamps.length}');
    print('Expected next stamp: #${stamps.length + 1}');
    print('Token stamp number: ${token.stampNumber}');
    print('Expected previousHash: "${expectedPrevHash.isEmpty ? "(empty)" : expectedPrevHash.substring(0, 20) + "..."}"');
    print('Token previousHash: "${token.previousHash.isEmpty ? "(empty)" : token.previousHash.substring(0, 20) + "..."}"');
    print('=== End Validation ===');

    // Validate stamp token (skip crypto validation for simple mode)
    if (card.mode == OperationMode.secure) {
      final validation = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: card.businessPublicKey,
        expectedPreviousHash: expectedPrevHash,
        mode: card.mode,
      );

      if (!validation.isValid) {
        setState(() {
          _errorMessage = validation.error ?? 'Invalid stamp';
          _isProcessing = false;
        });
        return;
      }
    } else {
      // Simple mode: Trust-based, no cryptographic validation
      print('Simple mode: Skipping cryptographic validation');
    }

    // Add stamp to card
    print('=== Saving Main Stamp ===');
    print('Stamp #${token.stampNumber}');
    print('previousHash: "${token.previousHash.isEmpty ? "(empty -> will be null)" : token.previousHash.substring(0, 20) + "..."}"');
    print('signature: "${token.signature.substring(0, 20)}..."');
    
    final stamp = Stamp(
      id: token.id,
      cardId: token.cardId,
      stampNumber: token.stampNumber,
      timestamp: DateTime.fromMillisecondsSinceEpoch(token.timestamp),
      signature: token.signature,
      previousHash: token.previousHash.isEmpty ? null : token.previousHash,
    );

    await stampRepo.insertStamp(stamp);
    print('Main stamp saved to DB');
    
    // Process additional stamps if present
    int totalStampsAdded = 1;
    if (token.additionalStamps.isNotEmpty) {
      print('=== Processing ${token.additionalStamps.length} Additional Stamps ===');
      String currentPreviousHash = token.signature; // First additional stamp uses main stamp's signature

      for (var additionalStamp in token.additionalStamps) {
        print('Additional Stamp #${additionalStamp.stampNumber}:');
        print('  previousHash: "${currentPreviousHash.substring(0, 20)}..."');
        print('  signature: "${additionalStamp.signature.substring(0, 20)}..."');
        
        // Verify stamp signature (skip in simple mode)
        if (card.mode == OperationMode.secure) {
          final signatureData = '${token.cardId}:${additionalStamp.stampNumber}:${additionalStamp.timestamp}:$currentPreviousHash';
          final isValid = KeyManager.verifySignature(
            signatureData,
            additionalStamp.signature,
            card.businessPublicKey,
          );

          if (!isValid) {
            print('ERROR: Additional stamp signature verification FAILED');
            setState(() {
              _errorMessage = 'Invalid stamp signature at stamp #${additionalStamp.stampNumber}';
              _isProcessing = false;
            });
            // Note: We've already added some stamps. In production, you might want
            // to implement a transaction rollback here.
            return;
          }
          print('  Signature verified OK');
        } else {
          print('  Simple mode: Skipping signature validation');
        }

        // Create and save stamp
        final additionalStampRecord = Stamp(
          id: '${token.cardId}_stamp_${additionalStamp.stampNumber}',
          cardId: token.cardId,
          stampNumber: additionalStamp.stampNumber,
          timestamp: DateTime.fromMillisecondsSinceEpoch(additionalStamp.timestamp),
          signature: additionalStamp.signature,
          previousHash: currentPreviousHash.isEmpty ? null : currentPreviousHash,
        );

        await stampRepo.insertStamp(additionalStampRecord);
        totalStampsAdded++;
        print('  Additional stamp saved to DB');
        
        // Next stamp's previous hash is this stamp's signature
        currentPreviousHash = additionalStamp.signature;
      }
      print('=== All Additional Stamps Processed ===');
    }
    
    // Check for overflow
    final newTotalStamps = card.stampsCollected + totalStampsAdded;
    if (newTotalStamps > card.stampsRequired) {
      print('╔═══════════════════════════════════════════════════════════╗');
      print('║ OVERFLOW DETECTED - AUTO-CREATING NEW CARD               ║');
      print('╚═══════════════════════════════════════════════════════════╝');
      print('Current stamps: ${card.stampsCollected}');
      print('Adding: $totalStampsAdded');
      print('Total would be: $newTotalStamps');
      print('Required: ${card.stampsRequired}');
      
      final overflow = newTotalStamps - card.stampsRequired;
      final stampsForCurrentCard = card.stampsRequired - card.stampsCollected;
      
      print('Stamps to complete current card: $stampsForCurrentCard');
      print('Overflow stamps: $overflow');
      
      // Mark current card as complete
      await repository.updateStampCount(card.id, card.stampsRequired);
      print('Current card now complete with ${card.stampsRequired} stamps');
      
      // Create new card with overflow stamps
      final newCardId = '${card.businessId}_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      final newCard = models.Card(
        id: newCardId,
        businessId: card.businessId,
        businessName: card.businessName,
        businessPublicKey: card.businessPublicKey,
        brandColor: card.brandColor,
        logoIndex: card.logoIndex,
        mode: card.mode, // Preserve the operation mode
        stampsRequired: card.stampsRequired,
        stampsCollected: overflow,
        createdAt: now,
        updatedAt: now,
      );
      
      await repository.insertCard(newCard);
      print('Created new card: $newCardId with $overflow stamps');
      
      // Move overflow stamps to new card
      // Get all stamps for the original card
      final allStamps = await stampRepo.getStampsByCard(card.id);
      print('Total stamps in original card: ${allStamps.length}');
      
      // Take the last 'overflow' stamps and move them to new card
      final stampsToMove = allStamps.skip(allStamps.length - overflow).toList();
      print('Moving ${stampsToMove.length} stamps to new card...');
      
      for (var i = 0; i < stampsToMove.length; i++) {
        final oldStamp = stampsToMove[i];
        final newStampNumber = i + 1;
        
        // Delete from old card
        await stampRepo.deleteStamp(oldStamp.id);
        
        // Create on new card with renumbered stamp number
        final newStamp = Stamp(
          id: '${newCardId}_stamp_$newStampNumber',
          cardId: newCardId,
          stampNumber: newStampNumber,
          timestamp: oldStamp.timestamp,
          signature: oldStamp.signature,
          previousHash: i == 0 ? null : stampsToMove[i - 1].signature,
        );
        
        await stampRepo.insertStamp(newStamp);
        print('  Moved stamp #${oldStamp.stampNumber} -> new card stamp #$newStampNumber');
      }
      
      print('Card split complete!');
      print('  Card 1 (COMPLETE): ${card.stampsRequired} stamps');
      print('  Card 2 (NEW): $overflow stamps');
      
      if (mounted) {
        Navigator.pop(context, 
          'Card complete! 🎉 New card started with $overflow stamp${overflow > 1 ? 's' : ''}');
      }
    } else {
      // No overflow - just update stamp count
      await repository.updateStampCount(card.id, newTotalStamps);
      print('Card updated: $newTotalStamps / ${card.stampsRequired} stamps');
      
      if (mounted) {
        final stampText = totalStampsAdded > 1 
            ? '$totalStampsAdded stamps added successfully!' 
            : 'Stamp added successfully!';
        Navigator.pop(context, stampText);
      }
    }
  }

  Future<void> _handleRedemptionToken(RedemptionToken token) async {
    print('=== Processing Redemption Token ===');
    print('Card ID: ${token.cardId}');
    print('Stamps redeemed: ${token.stampsRedeemed}');
    print('Business ID: ${token.businessId}');

    // Get the card to verify it matches
    final repository = CardRepository(DatabaseHelper());
    final card = await repository.getCardById(token.cardId);

    if (card == null) {
      setState(() {
        _errorMessage = 'Card not found. Please add the card first.';
        _isProcessing = false;
      });
      return;
    }

    // Verify card is from the same business
    if (card.businessId != token.businessId) {
      setState(() {
        _errorMessage = 'Card business mismatch';
        _isProcessing = false;
      });
      return;
    }

    // Verify card is complete
    if (!card.isComplete) {
      final remaining = card.stampsRequired - card.stampsCollected;
      setState(() {
        _errorMessage = 'This card isn\'t complete yet. You need $remaining more stamp${remaining > 1 ? 's' : ''} before you can redeem.';
        _isProcessing = false;
      });
      return;
    }

    // Check if card was already redeemed
    if (card.isRedeemed) {
      setState(() {
        _errorMessage = 'This card has already been redeemed!';
        _isProcessing = false;
      });
      return;
    }

    // Verify the redemption token signature
    final signatureData = token.getSignatureData();
    final isValid = KeyManager.verifySignature(
      signatureData,
      token.signature,
      card.businessPublicKey,
    );

    if (!isValid) {
      print('ERROR: Redemption token signature verification FAILED');
      setState(() {
        _errorMessage = 'Invalid redemption token signature';
        _isProcessing = false;
      });
      return;
    }

    print('Redemption token signature verified OK');

    // Mark card as redeemed
    await repository.markCardAsRedeemed(card.id);
    print('Card marked as redeemed in database');

    print('=== Redemption Complete ===');

    if (mounted) {
      Navigator.pop(context, 
        '🎉 Redemption confirmed! Card has been redeemed. You can now delete it.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == QRScanMode.addCard
        ? 'Scan your shop\'s card QR'
        : 'Scan Stamp QR';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: Stack(
        children: [
          // Camera view
          LayoutBuilder(
            builder: (context, constraints) {
              final mediaQuery = MediaQuery.of(context);
              final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
              
              // Apply rotation based on simple landscape detection
              // Landscape: -90°, Portrait: 0° (no rotation)
              final quarterTurns = isLandscape ? 3 : 0;
              
              print('=== QR Scanner Orientation ===');
              print('Orientation: ${isLandscape ? "Landscape" : "Portrait"}');
              print('Applying quarterTurns: $quarterTurns (${quarterTurns * 90} degrees)');
              
              return RotatedBox(
                quarterTurns: quarterTurns,
                child: MobileScanner(
                  controller: _controller,
                  fit: BoxFit.contain,
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
              );
            },
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
