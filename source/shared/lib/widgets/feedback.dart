import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../utils/haptics.dart';

/// Standardized feedback system for consistent user notifications
///
/// ACCESSIBILITY: every SnackBar's content is wrapped in
/// `Semantics(liveRegion: true, ...)`. Flutter's SnackBar doesn't reliably
/// announce itself to VoiceOver/TalkBack on its own - liveRegion explicitly
/// tells the screen reader "this appeared, read it," which is the only
/// non-visual signal for outcomes like a QR scan result. This is the single
/// shared surface both apps use for success/error/info/warning messages, so
/// fixing it here covers every call site at once.
class AppFeedback {
  AppFeedback._();

  /// Show success message with green background
  static void success(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: AppTypography.bodyLarge),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: BrandColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius / 2),
        ),
      ),
    );
    Haptics.success();
  }

  /// Show error message with red background
  static void error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: AppTypography.bodyLarge),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: BrandColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius / 2),
        ),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
    Haptics.error();
  }

  /// Show info message with blue background
  static void info(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: AppTypography.bodyLarge),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: BrandColors.info,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius / 2),
        ),
      ),
    );
    Haptics.light();
  }

  /// Show warning message with orange background
  static void warning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: AppTypography.bodyLarge),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: BrandColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius / 2),
        ),
      ),
    );
    Haptics.medium();
  }
}
