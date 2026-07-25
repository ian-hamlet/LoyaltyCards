import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Replaces mobile_scanner's default error view (a plain black screen with
/// terse text and no way forward) for a denied camera permission.
///
/// Scanning is the only way to add a card, collect a stamp, or redeem a
/// reward in this app - a customer or supplier who taps "Don't Allow" on
/// the OS camera prompt otherwise has no path back except guessing their
/// way to Settings unassisted. This gives them a button that does it.
///
/// For any other scanner error, falls back to mobile_scanner's own default
/// message rather than assuming a settings fix applies.
class ScannerPermissionErrorView extends StatelessWidget {
  const ScannerPermissionErrorView({required this.error, super.key});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    if (error.errorCode != MobileScannerErrorCode.permissionDenied) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            error.errorCode.message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Camera access is needed to scan QR codes.',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enable it in Settings to continue.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => AppSettings.openAppSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
