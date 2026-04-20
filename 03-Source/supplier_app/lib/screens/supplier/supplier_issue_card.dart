import 'dart:async';
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
  final Set<String> _loggedCardIds = {}; // Track logged card IDs to prevent duplicates
  Timer? _countdownTimer;
  Duration? _remainingTime;

  @override
  void initState() {
    super.initState();
    _loadBusinessAndGenerateToken();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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

      // Log card issuance only ONCE per unique card ID (not on each QR regeneration)
      // This prevents counting multiple "issued cards" when user changes initial stamp count
      if (token.cardId != null && !_loggedCardIds.contains(token.cardId)) {
        await _businessRepo.logIssuedCard(
          token.cardId!,
          business.id,
        );
        _loggedCardIds.add(token.cardId!);
      }

      setState(() {
        _business = business;
        _token = token;
        _isLoading = false;
      });

      // Start countdown timer for secure mode
      if (business.mode == OperationMode.secure) {
        _startCountdown();
      }
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
        foregroundColor: Colors.white,
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
                                    color: BrandColors.infoContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: BrandColors.info.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: BrandColors.info, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Card will start with $_initialStampCount stamp${_initialStampCount > 1 ? 's' : ''} already applied',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: BrandColors.textPrimary,
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
                      const SizedBox(height: 16),

                      // QR Code Display
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                BusinessIcons.getIcon(_business!.logoIndex),
                                size: 40,
                                color: BrandColors.fromHex(_business!.brandColor),
                              ),
                              const SizedBox(height: 8),
                              
                              Text(
                                _business!.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // QR Code (slightly smaller for landscape fit)
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
                                  size: QRCodeSize.calculate(context),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              Text(
                                'Scan to Pick Up Card',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              
                              const SizedBox(height: 10),
                              
                              // Expiry info with integrated refresh button
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _business!.mode == OperationMode.simple
                                      ? Colors.blue[50]
                                      : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _business!.mode == OperationMode.simple
                                        ? Colors.blue[300]!
                                        : Colors.orange[300]!,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _business!.mode == OperationMode.simple
                                          ? Icons.all_inclusive
                                          : Icons.timer_outlined,
                                      size: 16,
                                      color: _business!.mode == OperationMode.simple
                                          ? Colors.blue[700]
                                          : Colors.orange[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _business!.mode == OperationMode.simple
                                          ? 'Reusable QR (no expiry)'
                                          : (_remainingTime != null
                                              ? 'Expires in: ${_formatDuration(_remainingTime!)}'
                                              : 'Valid 5 min (expires ${_getExpiryTime()})'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _business!.mode == OperationMode.simple
                                            ? Colors.blue[900]
                                            : (_remainingTime != null && _remainingTime!.inMinutes < 2
                                                ? Colors.red[900]
                                                : Colors.orange[900]),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_business!.mode == OperationMode.secure) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: _loadBusinessAndGenerateToken,
                                        icon: Icon(Icons.refresh, size: 18, color: Colors.orange[700]),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Refresh QR Code',
                                      ),
                                    ],
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

  void _startCountdown() {
    if (_token == null || _business?.mode != OperationMode.secure) return;

    _updateRemainingTime();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    if (_token == null) return;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(_token!.timestamp)
        .add(const Duration(minutes: 5));
    final remaining = expiryTime.difference(DateTime.now());
    
    if (remaining.isNegative) {
      _countdownTimer?.cancel();
      if (mounted) {
        setState(() => _remainingTime = Duration.zero);
      }
    } else {
      if (mounted) {
        setState(() => _remainingTime = remaining);
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
