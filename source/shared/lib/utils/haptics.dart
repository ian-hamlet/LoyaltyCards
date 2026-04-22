import 'package:flutter/services.dart';

/// Haptic feedback utilities for tactile user feedback
class Haptics {
  Haptics._();

  /// Light impact feedback (subtle tap)
  static void light() => HapticFeedback.lightImpact();
  
  /// Medium impact feedback (standard tap)
  static void medium() => HapticFeedback.mediumImpact();
  
  /// Heavy impact feedback (important action)
  static void heavy() => HapticFeedback.heavyImpact();
  
  /// Selection click (toggle, picker change)
  static void selection() => HapticFeedback.selectionClick();
  
  /// Success pattern (completion, achievement)
  static void success() => HapticFeedback.mediumImpact();
  
  /// Error pattern (failure, warning)
  static void error() => HapticFeedback.vibrate();
}
