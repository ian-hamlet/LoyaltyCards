import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart' hide Card;
import '../../services/qr_token_generator.dart';
import '../../services/key_manager.dart';
import '../../services/business_repository.dart';
import '../../services/supplier_database_helper.dart';
import '../../services/backup_storage_service.dart';

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
  // TEST-021: pre-built alphanumeric-mode QR for _token, cached alongside
  // it so build() never re-derives it. Null means either _token hasn't
  // been generated yet, or (extremely unlikely given measured margins -
  // see DEFECT_TRACKER.md TEST-021) the payload still didn't fit.
  QrCode? _cachedIssueQrCode;
  bool _isLoading = true;
  // CRASH-001: guards each distribution method against a fast double-tap
  // firing a second concurrent native call (Printing.layoutPdf /
  // Share.shareXFiles) before the first one completes.
  bool _isPrinting = false;
  bool _isSharing = false;
  String? _errorMessage;
  int _initialStampCount = 0; // Number of stamps to pre-apply (0-stampsRequired)
  final Set<String> _loggedCardIds = {}; // Track logged card IDs to prevent duplicates
  Timer? _countdownTimer;
  Duration? _remainingTime;
  bool _configExpanded = false; // Track Quick Start configuration expansion state

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
      if (!mounted) return;
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

      if (!mounted) return;
      setState(() {
        _business = business;
        _token = token;
        _cachedIssueQrCode = _buildIssueQrCode(token);
        _isLoading = false;
      });

      // Start countdown timer for secure mode
      if (business.mode == OperationMode.secure) {
        _startCountdown();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error generating token: $e';
        _isLoading = false;
      });
    }
  }

  /// TEST-021 regression test hook - mirrors the Slider's onChanged
  /// handler. Widget-test-driving the actual Slider to an exact high
  /// value is fragile; this reaches the same code path directly.
  @visibleForTesting
  Future<void> setInitialStampCountForTesting(int count) async {
    setState(() {
      _initialStampCount = count;
    });
    await _loadBusinessAndGenerateToken();
  }

  // TEST-021: a card issued with pre-applied initial stamps embeds one
  // signature per stamp - the same shape as the redemption QR TEST-020
  // fixed - and had the same silent-failure capacity ceiling, just never
  // fixed on this side. Compact-encode via CardIssueQrCodec and use
  // alphanumeric mode instead of the default byte-mode QrImageView(data:).
  QrCode? _buildIssueQrCode(CardIssueToken token) {
    try {
      final compact = CardIssueQrCodec.encode(token);
      return AlphanumericQr.build(compact);
    } catch (e) {
      AppLogger.error('Failed to build issue card QR', error: e, tag: 'IssueCard');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                      // Initial Stamp Count Selector (Collapsible)
                      Card(
                        elevation: 1,
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: _configExpanded,
                            onExpansionChanged: (expanded) {
                              setState(() => _configExpanded = expanded);
                            },
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            title: Row(
                              children: [
                                Icon(Icons.bolt, color: Colors.amber[700], size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Quick Start Stamps',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              _initialStampCount == 0 
                                  ? 'No stamps pre-applied' 
                                  : (_initialStampCount == 1 ? '1 stamp pre-applied' : '$_initialStampCount stamps pre-applied'),
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Description
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Pre-apply stamps to new cards. Useful for welcome bonuses or promotions. Set to 0 for standard card issuance.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Slider with +/- buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        onPressed: _initialStampCount > 0
                                            ? () {
                                                Haptics.light();
                                                setState(() {
                                                  _initialStampCount--;
                                                });
                                                _loadBusinessAndGenerateToken();
                                              }
                                            : null,
                                        icon: const Icon(Icons.remove_circle),
                                        tooltip: 'Decrease initial stamp count',
                                      ),
                                      Expanded(
                                        child: Text(
                                          _initialStampCount == 0
                                              ? 'No stamps'
                                              : (_initialStampCount == 1 ? '1 stamp' : '$_initialStampCount stamps'),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _initialStampCount < _business!.stampsRequired
                                            ? () {
                                                Haptics.light();
                                                setState(() {
                                                  _initialStampCount++;
                                                });
                                                _loadBusinessAndGenerateToken();
                                              }
                                            : null,
                                        icon: const Icon(Icons.add_circle),
                                        tooltip: 'Increase initial stamp count',
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: _initialStampCount.toDouble(),
                                    min: 0,
                                    max: _business!.stampsRequired.toDouble(),
                                    divisions: _business!.stampsRequired,
                                    label: _initialStampCount == 0 
                                        ? 'None' 
                                        : (_initialStampCount == 1 ? '1 stamp' : '$_initialStampCount stamps'),
                                    onChanged: (value) {
                                      setState(() {
                                        _initialStampCount = value.toInt();
                                      });
                                      _loadBusinessAndGenerateToken();
                                    },
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
                              // TEST-021: alphanumeric-mode QR built ahead
                              // of time by _buildIssueQrCode(), not the
                              // plain byte-mode data: String path - see
                              // DEFECT_TRACKER.md TEST-021.
                              if (_cachedIssueQrCode != null)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: QrImageView.withQr(
                                    qr: _cachedIssueQrCode!,
                                    size: QRCodeSize.calculate(context),
                                    backgroundColor: Colors.white,
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.orange, size: 40),
                                      const SizedBox(height: 12),
                                      const Text(
                                        "This card's code is too large to display",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Try reducing the number of pre-applied stamps for this card.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                    ],
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
                                      ? colorScheme.primaryContainer
                                      : colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _business!.mode == OperationMode.simple
                                        ? colorScheme.primary
                                        : colorScheme.secondary,
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
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSecondaryContainer,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _business!.mode == OperationMode.simple
                                            ? 'Reusable QR (no expiry)'
                                            : (_remainingTime != null
                                                ? 'Expires in: ${_formatDuration(_remainingTime!)}'
                                                : 'Valid 5 min (expires ${_getExpiryTime()})'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _business!.mode == OperationMode.simple
                                              ? colorScheme.onPrimaryContainer
                                              : (_remainingTime != null && _remainingTime!.inMinutes < 2
                                                  ? colorScheme.error
                                                  : colorScheme.onSecondaryContainer),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (_business!.mode == OperationMode.secure) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: _loadBusinessAndGenerateToken,
                                        icon: Icon(Icons.refresh, size: 18, color: colorScheme.onSecondaryContainer),
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

                      // Save/Print buttons for simple mode
                      if (_business!.mode == OperationMode.simple) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: (_isPrinting || _cachedIssueQrCode == null) ? null : _printToken,
                                  icon: _isPrinting
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.print),
                                  label: const Text('Print'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    alignment: Alignment.center,
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: (_isSharing || _cachedIssueQrCode == null) ? null : _shareToken,
                                  icon: _isSharing
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.share),
                                  label: const Text('Share QR'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    alignment: Alignment.center,
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Instructions
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.tertiary),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline, color: colorScheme.onTertiaryContainer, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'How to Use',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onTertiaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '1. Show this QR code to customers directly from your device\n2. Or print and display it in your business\n3. Customer scans to add your loyalty card\n4. This QR code is reusable for all new customers',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  /// CRASH-001 regression test hook.
  @visibleForTesting
  Future<void> printTokenForTesting() => _printToken();

  // Print issue card QR
  Future<void> _printToken() async {
    if (_business == null || _token == null || _isPrinting || _cachedIssueQrCode == null) return;

    setState(() => _isPrinting = true);

    try {
      final result = await BackupStorageService.printIssueCard(
        qrCode: _cachedIssueQrCode!,
        businessName: _business!.name,
        initialStamps: _initialStampCount,
      );

      if (mounted) {
        if (result.isSuccess) {
          AppFeedback.success(context, 'Print dialog opened');
        } else {
          AppFeedback.error(context, result.getUserMessage());
        }
      }
    } catch (e) {
      AppLogger.error('Error printing issue card: $e', tag: 'IssueCard');
      if (mounted) {
        AppFeedback.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  /// CRASH-001 regression test hook.
  @visibleForTesting
  Future<void> shareTokenForTesting() => _shareToken();

  // Share issue card QR via native share sheet
  Future<void> _shareToken() async {
    if (_business == null || _token == null || _isSharing || _cachedIssueQrCode == null) return;

    setState(() => _isSharing = true);

    try {
      final size = MediaQuery.of(context).size;
      final sharePosition = Rect.fromLTWH(size.width / 2, size.height / 2, 10, 10);

      final result = await BackupStorageService.shareIssueCard(
        qrCode: _cachedIssueQrCode!,
        businessName: _business!.name,
        initialStamps: _initialStampCount,
        sharePositionOrigin: sharePosition,
      );

      if (mounted) {
        if (result.isSuccess) {
          AppFeedback.success(context, 'Share sheet opened');
        } else {
          AppFeedback.error(context, result.getUserMessage());
        }
      }
    } catch (e) {
      AppLogger.error('Error sharing issue card: $e', tag: 'IssueCard');
      if (mounted) {
        AppFeedback.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _startCountdown() {
    if (_token == null || _business?.mode != OperationMode.secure) return;

    // Every QR regeneration (e.g. changing the initial stamp count) calls
    // this again - without cancelling the previous timer first, each
    // regeneration leaked an orphaned Timer.periodic that ran forever
    // (found via TEST-021's widget test exercising multiple regenerations
    // in Secure Mode).
    _countdownTimer?.cancel();
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
