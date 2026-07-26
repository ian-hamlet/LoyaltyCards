import 'package:flutter/material.dart';

/// Caps ambient text scaling for [child] at [maxScale], while still
/// respecting any *smaller* scale the user has configured.
///
/// Use for supplementary or decorative labels (chip text, button labels,
/// small in-circle numbers) that have a working fallback elsewhere and
/// don't need to support the full Dynamic Type accessibility range -
/// unlike primary content, which should always scale freely. Several
/// widgets in this app (FloatingActionButton.extended, Chip/FilterChip,
/// button labels) size themselves to fit their label's *unwrapped* width
/// with nothing constraining that width to the screen - at large
/// accessibility text sizes they grow past the screen edge and can
/// overlap other content, rather than wrapping or truncating.
class ScaleCapped extends StatelessWidget {
  const ScaleCapped({super.key, required this.child, this.maxScale = 1.3});

  final Widget child;

  /// The largest text scale factor this content will render at, regardless
  /// of the device's actual accessibility text size setting. 1.3 comfortably
  /// covers everything up to iOS's "Larger Text" range without reaching the
  /// "accessibility sizes" range where these widgets start breaking.
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    final ambientScaler = MediaQuery.textScalerOf(context);
    final cappedScaler = TextScaler.linear(
      ambientScaler.scale(1.0).clamp(0.0, maxScale),
    );
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: cappedScaler),
      child: child,
    );
  }
}
