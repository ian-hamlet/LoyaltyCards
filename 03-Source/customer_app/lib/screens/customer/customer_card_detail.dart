import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import 'dart:convert';
import '../../services/card_repository.dart';
import '../../services/stamp_repository.dart';
import '../../services/database_helper.dart';
import 'qr_display_screen.dart';
import 'qr_scanner_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCardData();
  }

  Future<void> _loadCardData() async {
    setState(() => _isLoading = true);
    try {
      final card = await _cardRepo.getCardById(widget.cardId);
      final stamps = await _stampRepo.getStampsByCard(widget.cardId);
      
      setState(() {
        _card = card;
        _stamps = stamps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppFeedback.error(context, 'Error loading card: $e');
      }
    }
  }

  String _generateCardQR() {
    if (_card == null) return '';
    
    // If card has been redeemed, don't generate any QR
    if (_card!.isRedeemed) {
      print('Card Detail QR: Card REDEEMED - no QR generation');
      return 'REDEEMED'; // Special marker to show redeemed message instead of QR
    }
    
    // If card is complete, generate redemption QR instead
    if (_card!.isComplete) {
      print('Card Detail QR: Card is COMPLETE - generating REDEMPTION QR');
      print('Card Detail QR: ${_stamps.length} stamps for redemption');
      
      final signatures = _stamps.map((s) => s.signature).toList();
      
      final qrData = {
        'type': 'redemption_request',
        'cardId': _card!.id,
        'businessId': _card!.businessId,
        'stampsCollected': _card!.stampsCollected,
        'stampSignatures': signatures,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      return jsonEncode(qrData);
    }
    
    // Otherwise, generate stamp request QR
    String lastStampHash = '';
    if (_stamps.isNotEmpty) {
      lastStampHash = _stamps.last.signature;
      print('Card Detail QR: Including lastStampHash from stamp #${_stamps.last.stampNumber}');
      print('Card Detail QR: Hash = "${lastStampHash.substring(0, 20)}..."');
    } else {
      print('Card Detail QR: No stamps, lastStampHash will be empty');
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
            // Card Visual
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [brandColor, brandColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
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
                  
                  // Stamp Grid
                  _buildStampGrid(brandColor),
                  
                  const SizedBox(height: 12),
                  
                  // Progress Text
                  Text(
                    '${_card!.stampsCollected} of ${_card!.stampsRequired} stamps',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Completion/Redemption Badge
                  if (_card!.isRedeemed) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'REDEEMED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_card!.isComplete) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.celebration, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'CARD COMPLETE!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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
                        Icons.all_inclusive,
                        size: 64,
                        color: Colors.blue[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _card!.isComplete 
                            ? 'Ready to redeem your reward'
                            : 'Simple Mode - Scan to collect stamps',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _card!.isComplete
                            ? 'Show this card to the supplier to verify, then redeem below'
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
                            label: const Text('Redeem Reward'),
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
                            label: const Text('Scan to Add Stamp'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ] else ...[
                // Redeemed state for simple mode
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[200]!, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 80, color: Colors.green[600]),
                      const SizedBox(height: 16),
                      Text(
                        'Card Redeemed!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
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
                                  Icon(Icons.access_time, size: 16, color: Colors.green[700]),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_card!.redeemedAt!.hour}:${_card!.redeemedAt!.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(fontSize: 14, color: Colors.green[900], fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.green[700]),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_card!.redeemedAt!.day}/${_card!.redeemedAt!.month}/${_card!.redeemedAt!.year}',
                                    style: TextStyle(fontSize: 14, color: Colors.green[900], fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        'This card has been redeemed and can be deleted.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // SECURE MODE: Show customer QR code
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
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 80, color: Colors.green[600]),
                      const SizedBox(height: 16),
                      Text(
                        'Card Redeemed!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This card has been redeemed and can be deleted.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: QrImageView(
                    data: _generateCardQR(),
                    version: QrVersions.auto,
                    size: QRCodeSize.calculate(context),
                    backgroundColor: Colors.white,
                  ),
                ),

              const SizedBox(height: 12),

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
                              _loadCardData(); // Reload card data
                            }
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(_card!.isComplete 
                            ? 'Scan Redemption Token' 
                            : 'Scan Stamp Token'),
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
            if (_stamps.isNotEmpty) ...[
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
                    ..._stamps.map((stamp) => _buildStampHistoryItem(stamp)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStampGrid(Color brandColor) {
    final rows = (_card!.stampsRequired / 5).ceil();
    final stampsPerRow = (_card!.stampsRequired / rows).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        final startIndex = rowIndex * stampsPerRow;
        final endIndex = (startIndex + stampsPerRow < _card!.stampsRequired) 
            ? startIndex + stampsPerRow 
            : _card!.stampsRequired;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(endIndex - startIndex, (colIndex) {
              final stampIndex = startIndex + colIndex;
              final isCollected = stampIndex < _card!.stampsCollected;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCollected ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: isCollected
                      ? Icon(Icons.check, color: brandColor, size: 20)
                      : Center(
                          child: Text(
                            '${stampIndex + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              );
            }),
          ),
        );
      }),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Have you received your reward from the supplier?',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This will mark your card as redeemed with the current date and time',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      
      print('=== Simple Mode Redemption ===');
      print('Card ID: ${_card!.id}');
      print('Business: ${_card!.businessName}');
      print('Stamps: ${_card!.stampsCollected}');
      print('Redeemed at: ${now.toIso8601String()}');
      
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
                const SizedBox(height: 12),
                Text(
                  'You can now delete this card',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                ),
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
      if (mounted) {
        AppFeedback.error(context, 'Error redeeming card: $e');
      }
    }
  }
}
