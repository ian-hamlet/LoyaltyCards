import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import 'dart:convert';
import '../../services/card_repository.dart';
import '../../services/stamp_repository.dart';

class CustomerCardDetail extends StatefulWidget {
  final String cardId;

  const CustomerCardDetail({super.key, required this.cardId});

  @override
  State<CustomerCardDetail> createState() => _CustomerCardDetailState();
}

class _CustomerCardDetailState extends State<CustomerCardDetail> {
  final CardRepository _cardRepo = CardRepository();
  final StampRepository _stampRepo = StampRepository();
  
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading card: $e')),
        );
      }
    }
  }

  String _generateCardQR() {
    if (_card == null) return '';
    
    final qrData = {
      'type': 'card_stamp_request',
      'cardId': _card!.id,
      'businessId': _card!.businessId,
      'currentStamps': _card!.stampsCollected,
      'publicKey': _card!.businessPublicKey,
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
              padding: const EdgeInsets.all(24),
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
                  // Business Name
                  Text(
                    _card!.businessName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Stamp Grid
                  _buildStampGrid(brandColor),
                  
                  const SizedBox(height: 16),
                  
                  // Progress Text
                  Text(
                    '${_card!.stampsCollected} of ${_card!.stampsRequired} stamps',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Completion Badge
                  if (_card!.isComplete) ...[
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

            // QR Code Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _card!.isComplete 
                    ? 'Show this QR code to redeem your reward'
                    : 'Show this QR code to collect stamps',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),

            // QR Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(
                data: _generateCardQR(),
                version: QrVersions.auto,
                size: 250,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (_card!.isComplete)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Future: Navigate to redemption flow
                        },
                        icon: const Icon(Icons.redeem),
                        label: const Text('Redeem Reward'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Future: Show stamp request
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Get Stamp'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                ],
              ),
            ),

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
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCollected ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: isCollected
                      ? Icon(Icons.check, color: brandColor, size: 24)
                      : Center(
                          child: Text(
                            '${stampIndex + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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
}
