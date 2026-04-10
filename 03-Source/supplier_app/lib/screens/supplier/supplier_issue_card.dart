import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart' hide Card;
import '../../services/qr_token_generator.dart';
import '../../services/key_manager.dart';
import '../../services/business_repository.dart';
import '../../services/supplier_database_helper.dart';

class SupplierIssueCard extends StatefulWidget {
  const SupplierIssueCard({super.key});

  @override
  State<SupplierIssueCard> createState() => _SupplierIssueCardState();
}

class _SupplierIssueCardState extends State<SupplierIssueCard> {
  final BusinessRepository _businessRepo = BusinessRepository();
  final QRTokenGenerator _tokenGenerator = QRTokenGenerator(KeyManager());
  
  Business? _business;
  CardIssueToken? _token;
  bool _isLoading = true;
  String? _errorMessage;
  int _initialStampCount = 0; // Number of stamps to pre-apply (0-7)

  @override
  void initState() {
    super.initState();
    _loadBusinessAndGenerateToken();
  }

  Future<void> _loadBusinessAndGenerateToken() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final business = await _businessRepo.getBusiness();
      if (business == null) {
        setState(() {
          _errorMessage = 'Business not found. Please complete onboarding.';
          _isLoading = false;
        });
        return;
      }

      final token = await _tokenGenerator.generateCardIssueToken(
        business: business,
        initialStampCount: _initialStampCount,
      );

      // Log card issuance (QR generated)
      // Note: In P2P model, we don't know if customer actually picks up the card,
      // but we track QR generation as a proxy metric
      await _businessRepo.logIssuedCard(
        token.businessId + '_' + DateTime.now().millisecondsSinceEpoch.toString(),
        business.id,
      );

      setState(() {
        _business = business;
        _token = token;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating token: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue New Card'),
        backgroundColor: const Color(0xFF2C3E50),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBusinessAndGenerateToken,
            tooltip: 'Regenerate QR',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
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
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Instructions Card
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700], size: 32),
                              const SizedBox(height: 12),
                              Text(
                                'Customer Pickup Process',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '1. Show this QR code to customer\n'
                                '2. Customer opens LoyaltyCards app\n'
                                '3. Customer taps "Scan Card" button\n'
                                '4. Customer scans this QR code\n'
                                '5. Card added to customer wallet!',
                                style: TextStyle(
                                  height: 1.6,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                                            const SizedBox(height: 24),

                      // Initial Stamp Count Selector
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.bolt, color: Colors.amber[700], size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Quick Start Stamps',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Issue card with stamps already applied (for large purchases)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Stamp count selector buttons
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(8, (index) {
                                  final count = index;
                                  final isSelected = _initialStampCount == count;
                                  return ChoiceChip(
                                    label: Text(count == 0 ? 'None' : '$count'),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected && _initialStampCount != count) {
                                        setState(() {
                                          _initialStampCount = count;
                                        });
                                        _loadBusinessAndGenerateToken();
                                      }
                                    },
                                    selectedColor: Colors.blue[600],
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  );
                                }),
                              ),
                              
                              if (_initialStampCount > 0) ...[
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
                                      Icon(Icons.check_circle, color: Colors.blue[700], size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Card will start with $_initialStampCount stamp${_initialStampCount > 1 ? 's' : ''} already applied',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.blue[900],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // QR Code Display
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                _business!.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Text(
                                'Collect ${_business!.stampsRequired} stamps for a reward',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // QR Code
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: QrImageView(
                                  data: _token!.toQRString(),
                                  version: QrVersions.auto,
                                  size: 280.0,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              Text(
                                'Scan to Pick Up Card',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_user,
                                      size: 16,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Cryptographically Signed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Expiry notice
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 18,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'QR code valid for 5 minutes',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Refresh Button (prominent)
                              ElevatedButton.icon(
                                onPressed: _loadBusinessAndGenerateToken,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Generate New QR Code'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3498DB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
