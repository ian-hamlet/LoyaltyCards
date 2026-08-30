import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/app_logger.dart';
import '../utils/qr_code_size.dart';
import 'feedback.dart';

/// Generic "point someone at an App Store listing" screen: a QR code plus a
/// guarded Share button. Used for every companion-app/friend referral flow
/// across both apps (customer->supplier, customer->friend, supplier-
/// >customer) so the copy is the only thing that differs per call site.
///
/// Display-only QR (no printing - neither app needs a print path for this,
/// and adding one would pull in the native crash surface documented in
/// CRASH-001 for no real benefit here). The Share button still gets the
/// CRASH-001 re-entrancy guard even though it doesn't call
/// Printing.layoutPdf(): the lesson from that incident wasn't "guard print
/// specifically," it was "guard every button that triggers an async native
/// call" - a fast double-tap on Share could just as easily open two share
/// sheets.
class AppReferralScreen extends StatefulWidget {
  final String appBarTitle;
  final Color appBarColor;
  final IconData icon;
  final String headline;
  final String bodyText;
  final String qrData;
  final String shareText;
  final String errorTag;

  const AppReferralScreen({
    super.key,
    required this.appBarTitle,
    required this.appBarColor,
    required this.icon,
    required this.headline,
    required this.bodyText,
    required this.qrData,
    required this.shareText,
    required this.errorTag,
  });

  @override
  State<AppReferralScreen> createState() => _AppReferralScreenState();
}

class _AppReferralScreenState extends State<AppReferralScreen> {
  bool _isSharing = false;

  /// CRASH-001 regression test hook.
  @visibleForTesting
  Future<void> shareForTesting() => _share();

  Future<void> _share() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      final size = MediaQuery.of(context).size;
      final sharePositionOrigin = Rect.fromLTWH(size.width / 2, size.height / 2, 10, 10);

      await SharePlus.instance.share(
        ShareParams(text: widget.shareText, sharePositionOrigin: sharePositionOrigin),
      );
    } catch (e) {
      AppLogger.error('Error sharing referral link: $e', tag: widget.errorTag);
      if (mounted) {
        AppFeedback.error(context, 'Could not open the share sheet. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle),
        backgroundColor: widget.appBarColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Icon(widget.icon, size: 56, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              widget.headline,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              widget.bodyText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: widget.qrData,
                version: QrVersions.auto,
                size: QRCodeSize.calculate(context),
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Point their phone's camera at the code above",
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isSharing ? null : _share,
              icon: _isSharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.ios_share),
              label: const Text('Share the Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.appBarColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
