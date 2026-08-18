import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import 'package:shared/models/transaction.dart' as models;
import 'dart:convert';
import '../../services/card_repository.dart';
import '../../services/stamp_repository.dart';
import '../../services/transaction_repository.dart';
import '../../services/database_helper.dart';
import '../../services/device_service.dart';
import '../../utils/error_message_mapper.dart';
import '../../services/qr_token_generator.dart';
import 'qr_scanner_screen.dart';
import 'package:uuid/uuid.dart';

class CustomerCardDetail extends StatefulWidget {
  final String cardId;

  const CustomerCardDetail({super.key, required this.cardId});

  @override
  State<CustomerCardDetail> createState() => _CustomerCardDetailState();
}

class _CustomerCardDetailState extends State<CustomerCardDetail> {
  final CardRepository _cardRepo = CardRepository(DatabaseHelper());
  final StampRepository _stampRepo = StampRepository(DatabaseHelper());
  
  models.Card? _card;
  List<Stamp> _stamps = [];
  bool _isLoading = true;
  String? _currentDeviceId; // V-005: Cache device ID for QR generation

  // Q-007: cache the generated QR string instead of calling _generateCardQR()
  // directly in build() - that embeds a live timestamp, so any incidental
  // rebuild (rotation, an unrelated setState elsewhere on screen) produced
  // a visibly different QR code even though nothing the user did changed.
  // Recomputed only when card/stamp data is actually reloaded.
  String? _cachedQRData;

  // TEST-017/TEST-020: a redemption QR for a high-stamp-count Secure Mode
  // card (or one with several overflow-relocated stamps) can exceed a QR
  // code's maximum encodable capacity. TEST-020 makes this dramatically
  // less likely (gzip+Base45+alphanumeric-mode encoding via
  // RedemptionQrCodec/AlphanumericQr - see DEFECT_TRACKER.md), but doesn't
  // make it impossible for an arbitrarily large payload, and an
  // already-issued pre-TEST-020 card could still be affected. Built once
  // when card data loads, alongside _qrTooLargeToRender for the build()
  // method to check without redoing the (non-trivial - tries QR versions
  // 1-40) work on every rebuild.
  QrCode? _cachedRedemptionQrCode;
  bool _qrTooLargeToRender = false;

  @override
  void initState() {
    super.initState();
    _loadCardData();
  }

  Future<void> _loadCardData() async {
    setState(() => _isLoading = true);
    
    // V-005: Get device ID for redemption QR (fetch once, cache in state)
    _currentDeviceId = await DeviceService.getDeviceId();
    try {
      final card = await _cardRepo.getCardById(widget.cardId);
      final stamps = await _stampRepo.getStampsByCard(widget.cardId);
      
      AppLogger.debug('Card data loaded: ${card?.businessName} (${card?.id})', 'CardDetail');
      AppLogger.debug('Stamps collected: ${card?.stampsCollected}', 'CardDetail');
      AppLogger.debug('Stamp records in DB: ${stamps.length}', 'CardDetail');
      for (var stamp in stamps) {
        AppLogger.debug('  Stamp #${stamp.stampNumber} at ${stamp.timestamp}', 'CardDetail');
      }

      if (!mounted) return;
      setState(() {
        _card = card;
        _stamps = stamps;
        _isLoading = false;
        // _generateCardQR()/_buildRedemptionQrCode() read _card/_stamps,
        // which were just assigned above in this same synchronous
        // callback, so this reflects the freshly-loaded data.
        if (card != null && card.isComplete && !card.isRedeemed) {
          _cachedQRData = null;
          _cachedRedemptionQrCode = _buildRedemptionQrCode();
          _qrTooLargeToRender = _cachedRedemptionQrCode == null;
        } else {
          _cachedRedemptionQrCode = null;
          _qrTooLargeToRender = false;
          _cachedQRData = _generateCardQR();
        }
      });
    } catch (e) {
      AppLogger.error('Error loading card data', error: e, tag: 'CardDetail');
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.error(context, ErrorMessageMapper.forOperation(e, 'load card'));
    }
  }

  // TEST-020: builds the redemption QR as an alphanumeric-mode QrCode via
  // RedemptionQrCodec (gzip + Base45) instead of the plain-JSON byte-mode
  // string _generateCardQR() used to produce for this case - see
  // DEFECT_TRACKER.md TEST-020 for the size comparison that motivated
  // this. Returns null if the payload doesn't fit even at the largest QR
  // version, or if the generator rejects inconsistent card/stamp data -
  // either way, the caller falls back to the "too large to display" panel
  // (stamp history below it still proves what's been earned).
  // TEST-022: same fix as the supplier app's issue-card QR - prefer plain
  // JSON (readable by any supplier app version) whenever it actually
  // fits, and only fall back to the compact encoding for the genuinely
  // oversized case (high stamp count and/or heavily overflow-relocated).
  // The decode side (supplier_redeem_card.dart) already tries plain JSON
  // first, so no change needed there.
  QrCode? _buildRedemptionQrCode() {
    if (_card == null) return null;
    AppLogger.qr('Card is COMPLETE - generating REDEMPTION QR (TEST-020 compact encoding)');
    AppLogger.qr('Including ${_stamps.length} stamps for redemption');
    try {
      final token = QRTokenGenerator().generateRedemptionRequest(
        card: _card!,
        stamps: _stamps,
        cardDeviceId: _card!.deviceId, // V-005: Device where card was created
        currentDeviceId: _currentDeviceId, // V-005: Device showing redemption QR (cached)
      );
      final plainJson = token.toQRString();
      if (QrCapacity.fits(plainJson)) {
        return QrCode.fromData(data: plainJson, errorCorrectLevel: QrErrorCorrectLevel.L);
      }
      final compact = RedemptionQrCodec.encode(token);
      return AlphanumericQr.build(compact);
    } catch (e) {
      AppLogger.error('Failed to build redemption QR', error: e, tag: 'QR');
      return null;
    }
  }

  String _generateCardQR() {
    if (_card == null) return '';

    // If card has been redeemed, don't generate any QR
    if (_card!.isRedeemed) {
      AppLogger.qr('Card REDEEMED - no QR generation');
      return 'REDEEMED'; // Special marker to show redeemed message instead of QR
    }

    // Redemption QR (card complete) is handled separately by
    // _buildRedemptionQrCode() - TEST-020.

    // Otherwise, generate stamp request QR
    String lastStampHash = '';
    if (_stamps.isNotEmpty) {
      lastStampHash = _stamps.last.signature;
      AppLogger.qr('Including lastStampHash from stamp #${_stamps.last.stampNumber}');
      final hashPreview = lastStampHash.length > 20 ? '${lastStampHash.substring(0, 20)}...' : lastStampHash;
      AppLogger.qr('Hash = "$hashPreview"');
    } else {
      AppLogger.qr('No stamps, lastStampHash will be empty');
    }
    
    final qrData = {
      'type': 'card_stamp_request',
      'cardId': _card!.id,
      'businessId': _card!.businessId,
      'currentStamps': _card!.stampsCollected,
      'publicKey': _card!.businessPublicKey,
      'lastStampHash': lastStampHash,  // NOW INCLUDED!
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    return jsonEncode(qrData);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Card not found')),
      );
    }

    final brandColor = BrandColors.fromHex(_card!.brandColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(_card!.businessName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Card Visual with integrated vertical status bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [brandColor, brandColor.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Vertical status bar (integrated inside card with padding)
                      if (_card!.isRedeemed || _card!.isComplete)
                        Container(
                          width: 40,
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: _card!.isRedeemed
                                    ? [Colors.grey.shade700, Colors.grey.shade600]
                                    : [Colors.green.shade600, Colors.green.shade500],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12), // Horizontal space around rotated text
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _card!.isRedeemed ? Icons.check_circle : Icons.celebration,
                                        color: Colors.white,
                                        size: _card!.isRedeemed ? 16 : 18,
                                      ),
                                      const SizedBox(width: 6),
                                      ScaleCapped(
                                        child: Text(
                                          _card!.isRedeemed ? 'REDEEMED' : 'COMPLETE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: _card!.isRedeemed ? 14 : 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      // Main card content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Business Logo/Icon
                              Icon(
                                BusinessIcons.getIcon(_card!.logoIndex),
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 12),
                              
                              // Business Name
                              Text(
                                _card!.businessName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              
                              // Stamp Grid - Compact display for complete/redeemed cards (TEST-010)
                              if (_card!.isComplete || _card!.isRedeemed)
                                _buildCompactStampDisplay()
                              else
                                _buildStampGrid(brandColor),
                              
                              // Progress Text - only show when not complete/redeemed
                              if (!_card!.isComplete && !_card!.isRedeemed) ...[
                                const SizedBox(height: 12),
                                Text(
                                  '${_card!.stampsCollected} of ${_card!.stampsRequired} stamps',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Simple Mode vs Secure Mode UI
            if (_card!.mode == OperationMode.simple) ...[
              // SIMPLE MODE: No customer QR, just scan supplier
              if (!_card!.isRedeemed) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bolt,
                        size: 64,
                        color: Colors.blue[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Express Mode',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _card!.isComplete
                            ? 'Show your supplier this completed card. Once they\'re ready, tap Redeem below.'
                            : 'Scan the supplier\'s stamp QR code to add stamps',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (_card!.isComplete)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _showRedemptionConfirmation,
                            icon: const Icon(Icons.card_giftcard),
                            label: const Text('Redeem Reward', textAlign: TextAlign.center),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const QRScannerScreen(
                                    mode: QRScanMode.receiveStamp,
                                  ),
                                ),
                              );
                              
                              if (result != null && mounted) {
                                AppFeedback.info(context, result);
                                _loadCardData();
                              }
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan to Add Stamp', textAlign: TextAlign.center),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ] else ...[
                // Redeemed state for simple mode with vertical bar
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      // Main redeemed content
                      Container(
                        margin: const EdgeInsets.only(left: 40),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: BrandColors.successContainer,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          border: Border.all(color: BrandColors.success.withOpacity(0.3), width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 64, color: BrandColors.success),
                            const SizedBox(height: 12),
                            const Text(
                              'Card Redeemed!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: BrandColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Show this to your supplier to confirm.',
                              style: TextStyle(
                                fontSize: 13,
                                color: BrandColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            if (_card!.redeemedAt != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.access_time, size: 16, color: BrandColors.success),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_card!.redeemedAt!.hour}:${_card!.redeemedAt!.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 14, color: BrandColors.textPrimary, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: BrandColors.success),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_card!.redeemedAt!.day}/${_card!.redeemedAt!.month}/${_card!.redeemedAt!.year}',
                                          style: const TextStyle(fontSize: 14, color: BrandColors.textPrimary, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const Text(
                              'This card has been redeemed and can be deleted.',
                              style: TextStyle(
                                fontSize: 13,
                                color: BrandColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      // Vertical status bar
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.grey.shade700,
                                Colors.grey.shade600,
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(2, 0),
                              ),
                            ],
                          ),
                          child: Center(
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  const ScaleCapped(
                                    child: Text(
                                      'REDEEMED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // SECURE MODE: Show customer QR code
              if (!_card!.isRedeemed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text(
                    _card!.isComplete
                        ? 'Show this QR code to redeem your reward'
                        : 'Show this QR code to collect stamps',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),

              // QR Code or Redeemed Message
              if (_card!.isRedeemed)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: BrandColors.successContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: BrandColors.success.withOpacity(0.3), width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, size: 80, color: BrandColors.success),
                      const SizedBox(height: 16),
                      const Text(
                        'Card Redeemed!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: BrandColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_card!.redeemedAt != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: BrandColors.success),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_card!.redeemedAt!.hour}:${_card!.redeemedAt!.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 14, color: BrandColors.textPrimary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: BrandColors.success),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_card!.redeemedAt!.day}/${_card!.redeemedAt!.month}/${_card!.redeemedAt!.year}',
                                    style: const TextStyle(fontSize: 14, color: BrandColors.textPrimary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const Text(
                        'This card has been redeemed and can be deleted.',
                        style: TextStyle(
                          fontSize: 14,
                          color: BrandColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else if (_qrTooLargeToRender)
                // TEST-017: the code couldn't be encoded (too much data for
                // a QR code to hold - see _qrDataFits). Show a clear
                // explanation instead of letting QrImageView fail silently;
                // the stamp history below still proves what's been earned.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.orange, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        "This card's code is too large to display",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'This can happen on an older card with a lot of stamps. Show the business your stamp history below, or ask them to redeem it manually.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: BrandColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else if (_card!.isComplete)
                // TEST-020: redemption QR uses the alphanumeric-mode
                // QrCode built ahead of time by _buildRedemptionQrCode(),
                // not the plain byte-mode data: String path below.
                Container(
                  padding: const EdgeInsets.all(8), // Reduced from 16 (TEST-010 - Compact QR Layout)
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: QrImageView.withQr(
                    qr: _cachedRedemptionQrCode!,
                    size: QRCodeSize.calculate(context) * 0.95, // 95% size (TEST-010 - Compact QR Layout)
                    backgroundColor: Colors.white,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8), // Reduced from 16 (TEST-010 - Compact QR Layout)
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: QrImageView(
                    data: _cachedQRData ?? _generateCardQR(),
                    version: QrVersions.auto,
                    size: QRCodeSize.calculate(context) * 0.95, // 95% size (TEST-010 - Compact QR Layout)
                    backgroundColor: Colors.white,
                  ),
                ),

              const SizedBox(height: 6), // Reduced from 12 (TEST-010 - Compact QR Layout)

              // Action Buttons (Secure Mode)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (!_card!.isRedeemed)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QRScannerScreen(
                                  mode: QRScanMode.receiveStamp,
                                ),
                              ),
                            );
                            
                            if (result != null && mounted) {
                              AppFeedback.info(context, result);
                              await _loadCardData(); // Reload card data
                            }
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: ScaleCapped(
                            child: Text(_card!.isComplete
                              ? 'Scan Redemption'
                              : 'Scan Stamp'),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ],

            // Stamps History
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stamp History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Card Creation Entry
                  _buildCardCreationItem(),
                  
                  // Individual Stamp Records
                  if (_stamps.isNotEmpty) ...
                    _stamps.map((stamp) => _buildStampHistoryItem(stamp)),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      // Floating Action Button - Always visible "Scan Confirmation" for redemption (TEST-010)
      floatingActionButton: (_card!.mode == OperationMode.secure && _card!.isComplete && !_card!.isRedeemed)
        ? FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRScannerScreen(
                    mode: QRScanMode.receiveStamp,
                  ),
                ),
              );
              
              if (result != null && mounted) {
                AppFeedback.info(context, result);
                await _loadCardData();
              }
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const ScaleCapped(child: Text('Scan Confirmation')),
            backgroundColor: Colors.green[600],
          )
        : null,
    );
  }

  // Compact stamp display for complete/redeemed cards (TEST-010 - Smart Collapse)
  Widget _buildCompactStampDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${_card!.stampsCollected} of ${_card!.stampsRequired} stamps',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStampGrid(Color brandColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const baseStampSize = 36.0;
        const minStampSize = 24.0;
        const stampSpacing = 8.0;
        const targetMinStampsPerRow = 8;

        final targetPerRow = _card!.stampsRequired < targetMinStampsPerRow
            ? _card!.stampsRequired
            : targetMinStampsPerRow;

        final sizeToFitTarget = targetPerRow > 0
            ? (constraints.maxWidth - ((targetPerRow - 1) * stampSpacing)) /
                targetPerRow
            : baseStampSize;

        final stampSize = sizeToFitTarget.clamp(minStampSize, baseStampSize);

        return Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: stampSpacing,
          runSpacing: stampSpacing,
          children: List.generate(_card!.stampsRequired, (index) {
            final isCollected = index < _card!.stampsCollected;

            // No per-stamp number: it was fixed-pixel-sized independent of
            // the ambient text scale, so at large accessibility text sizes
            // it visibly overflowed its circle while the circle itself
            // stayed the same size. The "N of M stamps collected" text
            // above already conveys progress and scales correctly, so
            // dropping the numbers here loses no information - just a
            // plain filled/checked circle for collected, an empty outline
            // for upcoming.
            return Container(
              width: stampSize,
              height: stampSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCollected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: isCollected
                  ? Icon(Icons.check, color: brandColor, size: stampSize * 0.56)
                  : null,
            );
          }),
        );
      },
    );
  }

  Widget _buildCardCreationItem() {
    if (_card == null) return const SizedBox.shrink();
    
    // Count initial stamps (stamps that exist with timestamp matching card creation)
    final initialStampCount = _stamps.where((stamp) {
      final timeDiff = stamp.timestamp.difference(_card!.createdAt).inSeconds.abs();
      return timeDiff < 5; // Within 5 seconds of card creation
    }).length;
    
    final displayStampCount = initialStampCount > 0 ? initialStampCount : 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: BrandColors.infoContainer,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: BrandColors.info,
          child: const Icon(Icons.add_card, color: Colors.white, size: 20),
        ),
        title: const Text(
          'Card Created',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: BrandColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(_card!.createdAt),
              style: TextStyle(fontSize: 12, color: BrandColors.textSecondary),
            ),
            if (displayStampCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Started with $displayStampCount stamp${displayStampCount > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: BrandColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.fiber_new, color: BrandColors.info),
      ),
    );
  }

  Widget _buildStampHistoryItem(Stamp stamp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: BrandColors.success,
          child: Text(
            '${stamp.stampNumber}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('Stamp #${stamp.stampNumber}'),
        subtitle: Text(
          'Received: ${_formatDate(stamp.timestamp)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showRedemptionConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.card_giftcard, color: Colors.green[600], size: 48),
        title: const Text(
          'Redeem Reward?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tapping Redeem confirms with your supplier that you\'re claiming your reward now.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Yet'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle),
            label: const Text('Yes, Redeem'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green[600],
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _processRedemption();
    }
  }

  Future<void> _processRedemption() async {
    try {
      final now = DateTime.now();
      
      // Mark card as redeemed
      await _cardRepo.markCardAsRedeemed(_card!.id);
      
      // Log redemption transaction
      final transactionRepo = TransactionRepository(DatabaseHelper());
      final redemptionTransaction = models.Transaction(
        id: const Uuid().v4(),
        cardId: _card!.id,
        type: TransactionType.redemption,
        timestamp: now,
        businessName: _card!.businessName,
        details: 'Reward redeemed: ${_card!.stampsCollected} stamps',
      );
      await transactionRepo.insertTransaction(redemptionTransaction);
      
      AppLogger.business('Simple Mode Redemption');
      AppLogger.debug('Card ID: ${_card!.id}', 'Redemption');
      AppLogger.debug('Business: ${_card!.businessName}', 'Redemption');
      AppLogger.debug('Stamps: ${_card!.stampsCollected}', 'Redemption');
      AppLogger.debug('Redeemed at: ${now.toIso8601String()}', 'Redemption');
      
      // Check for existing card with available space before creating new card
      final existingCard = await _cardRepo.findCardWithSpace(_card!.businessId);
      // Q-004 fix: track whether a new card was actually created so the
      // success dialog below can say so accurately - it previously claimed
      // "a new card has been added" unconditionally, even when an existing
      // under-filled card was reused instead.
      bool newCardCreated = false;

      if (existingCard != null) {
        AppLogger.business('Found existing card with space: ${existingCard.id}');
        AppLogger.business('  Existing card has ${existingCard.stampsCollected}/${existingCard.stampsRequired} stamps');
        AppLogger.business('  Skipping new card creation - will use existing card');
      } else {
        AppLogger.business('No existing cards with space found - creating new card');
        
        // Auto-create new card for continued loyalty
        final newCardId = '${_card!.businessId}_${DateTime.now().millisecondsSinceEpoch}';
        final newCard = models.Card(
          id: newCardId,
          businessId: _card!.businessId,
          businessName: _card!.businessName,
          businessPublicKey: _card!.businessPublicKey,
          brandColor: _card!.brandColor,
          logoIndex: _card!.logoIndex,
          mode: _card!.mode,
          stampsRequired: _card!.stampsRequired,
          stampsCollected: 0,
          createdAt: now,
          updatedAt: now,
        );
        
        await _cardRepo.insertCard(newCard);
        AppLogger.database('New card auto-created: $newCardId');
        newCardCreated = true;
      }
      
      // Reload card data
      await _loadCardData();
      
      if (mounted) {
        // Show success message
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.celebration, color: Colors.green, size: 64),
            title: const Text('Reward Redeemed!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _card!.businessName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_card!.stampsCollected} stamps redeemed',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, size: 18, color: Colors.green[700]),
                          const SizedBox(width: 6),
                          Text(
                            '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 15, color: Colors.green[900], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: Colors.green[700]),
                          const SizedBox(width: 6),
                          Text(
                            '${now.day}/${now.month}/${now.year}',
                            style: TextStyle(fontSize: 15, color: Colors.green[900], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Q-004 fix: only shown when a new card was actually
                // created - previously shown unconditionally even when an
                // existing under-filled card was reused instead.
                if (newCardCreated) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.blue[700], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'A new card has been added to your wallet automatically',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error redeeming card', error: e, tag: 'CardDetail');
      if (mounted) {
        AppFeedback.error(context, ErrorMessageMapper.forOperation(e, 'redeem card'));
      }
    }
  }
}
