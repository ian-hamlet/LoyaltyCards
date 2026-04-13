import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared/models/business.dart';
import 'package:shared/models/supplier_config_backup.dart';
import 'package:shared/widgets/feedback.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/key_manager.dart';

/// Screen for generating clone QR code to set up business on additional devices
/// Clone QR expires in 24 hours and allows another device to get full business config
class CloneDeviceScreen extends StatefulWidget {
  final Business business;

  const CloneDeviceScreen({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  State<CloneDeviceScreen> createState() => _CloneDeviceScreenState();
}

class _CloneDeviceScreenState extends State<CloneDeviceScreen> {
  SupplierConfigBackup? _cloneQR;
  bool _isGenerating = false;
  Timer? _countdownTimer;
  Duration? _remainingTime;
  final KeyManager _keyManager = KeyManager();

  @override
  void initState() {
    super.initState();
    _generateCloneQR();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateCloneQR() async {
    setState(() => _isGenerating = true);

    try {
      // Fetch private key from secure storage for clone QR inclusion
      final privateKeyString = await _keyManager.getPrivateKeyString(widget.business.id);
      if (privateKeyString == null) {
        throw Exception('Private key not found in secure storage');
      }

      // Create business object with privateKey populated for clone QR
      final businessWithKeys = widget.business.copyWith(
        privateKey: privateKeyString,
      );

      final cloneQR = await SupplierConfigBackup.createCloneQR(businessWithKeys);

      setState(() {
        _cloneQR = cloneQR;
        _isGenerating = false;
      });

      // Start countdown timer
      _startCountdown();
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        AppFeedback.error(context, 'Failed to generate clone QR: $e');
      }
    }
  }

  void _startCountdown() {
    if (_cloneQR?.expiresAt == null) return;

    _updateRemainingTime();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    if (_cloneQR?.expiresAt == null) return;

    final remaining = _cloneQR!.expiresAt!.difference(DateTime.now());
    
    if (remaining.isNegative) {
      setState(() => _remainingTime = Duration.zero);
      _countdownTimer?.cancel();
    } else {
      setState(() => _remainingTime = remaining);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clone to Another Device'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text(
                    'Generating clone QR...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : _cloneQR == null
              ? const Center(
                  child: Text('Failed to generate clone QR'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Instructions header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.device_hub, color: Colors.green.shade700, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Set Up Additional Device',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Scan this QR code on your second device to set up the same business configuration.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: _cloneQR!.toQRString(),
                              version: QrVersions.auto,
                              size: 280,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.business.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Expiry countdown
                      if (_remainingTime != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _remainingTime!.inMinutes < 2
                                ? Colors.red.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _remainingTime!.inMinutes < 2
                                  ? Colors.red.shade200
                                  : Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: _remainingTime!.inMinutes < 2
                                    ? Colors.red.shade700
                                    : Colors.orange.shade700,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Expires in: ${_formatDuration(_remainingTime!)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _remainingTime!.inMinutes < 2
                                          ? Colors.red.shade900
                                          : Colors.orange.shade900,
                                    ),
                                  ),
                                  Text(
                                    _remainingTime!.inMinutes < 2
                                        ? 'Expiring soon!'
                                        : 'Valid for 5 minutes',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _remainingTime!.inMinutes < 2
                                          ? Colors.red.shade700
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'How to Clone',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildStep('1', 'Open supplier app on your second device'),
                            const SizedBox(height: 8),
                            _buildStep('2', 'Tap "Clone from Another Device"'),
                            const SizedBox(height: 8),
                            _buildStep('3', 'Scan this QR code'),
                            const SizedBox(height: 8),
                            _buildStep('4', 'Both devices now share the same business'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Warning
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.amber.shade900),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Security Notice',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This QR contains your private cryptographic keys. Only scan on devices you control.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Regenerate button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _generateCloneQR,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Generate New QR (resets timer)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
