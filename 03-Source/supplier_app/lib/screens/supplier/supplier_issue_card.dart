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
  bool _hasLoggedCardIssuance = false; // Track if we've logged this session
  bool _instructionsExpanded = false; // Track if instructions are expanded

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

      // Log card issuance only ONCE per screen session (not on each QR regeneration)
      // This prevents counting multiple "issued cards" when user changes initial stamp count
      if (!_hasLoggedCardIssuance && token.cardId != null) {
        await _businessRepo.logIssuedCard(
          token.cardId!,
          business.id,
        );
        _hasLoggedCardIssuance = true;
      }

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
                      // Initial Stamp Count Selector (Compact)
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.bolt, color: Colors.amber[700], size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Quick Start Stamps',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Stamp count selector buttons (compact)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: List.generate(8, (index) {
                                  final count = index;
                                  final isSelected = _initialStampCount == count;
                                  return ChoiceChip(
                                    label: Text(count == 0 ? 'None' : '$count', style: const TextStyle(fontSize: 13)),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    visualDensity: VisualDensity.compact,
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
                              Icon(
                                BusinessIcons.getIcon(_business!.logoIndex),
                                size: 48,
                                color: BrandColors.fromHex(_business!.brandColor),
                              ),
                              const SizedBox(height: 12),
                              
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
                              
                              const SizedBox(height: 16),
                              
                              Text(
                                'Scan to Pick Up Card',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Combined crypto + expiry info (compact)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.verified_user, size: 14, color: Colors.green[700]),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Cryptographically Signed',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green[900],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.timer_outlined, size: 14, color: Colors.orange[700]),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Valid for 5 min (expires ${_getExpiryTime()})',
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

                              const SizedBox(height: 12),

                              // Refresh Button (more compact)
                              OutlinedButton.icon(
                                onPressed: _loadBusinessAndGenerateToken,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Refresh QR'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Expandable Instructions (more prominent)
                      Card(
                        elevation: 3,
                        color: Colors.blue[50],
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.help_outline, color: Colors.white, size: 18),
                            ),
                            title: Text(
                              'How to Give Card to Customer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  _instructionsExpanded ? Icons.expand_less : Icons.expand_more,
                                  size: 16,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _instructionsExpanded ? 'Hide steps' : 'Show 5 easy steps',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            initiallyExpanded: false,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _instructionsExpanded = expanded;
                              });
                            },
                            backgroundColor: Colors.blue[50],
                            collapsedBackgroundColor: Colors.blue[50],
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInstructionStep('1', 'Show this QR code to customer'),
                                    const SizedBox(height: 8),
                                    _buildInstructionStep('2', 'Customer opens LoyaltyCards app'),
                                    const SizedBox(height: 8),
                                    _buildInstructionStep('3', 'Customer taps "Scan Card" button'),
                                    const SizedBox(height: 8),
                                    _buildInstructionStep('4', 'Customer scans this QR code'),
                                    const SizedBox(height: 8),
                                    _buildInstructionStep('5', 'Card added to customer wallet!', isLast: true),
                                  ],
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
  
  Widget _buildInstructionStep(String number, String text, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isLast ? Colors.green : Colors.blue[700],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[900],
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  String _getExpiryTime() {
    if (_token == null) return '--:--';
    
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(_token!.timestamp)
        .add(const Duration(minutes: 5));
    
    final hour = expiryTime.hour.toString().padLeft(2, '0');
    final minute = expiryTime.minute.toString().padLeft(2, '0');
    
    return '$hour:$minute';
  }
}
