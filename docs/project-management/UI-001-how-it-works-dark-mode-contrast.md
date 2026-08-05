# UI-001: Unreadable Text on How It Works Info Panels in Dark Mode

**Source:** User-reported (visual inspection of the app)
**Status:** ✅ FIXED
**Priority:** MEDIUM (readability/accessibility, not a crash)
**Affected Apps:** Supplier App and Customer App
**Screen/Feature:** "How It Works" screen in both apps
**Files:**
- `source/supplier_app/lib/screens/supplier/how_it_works.dart`
- `source/customer_app/lib/screens/customer/how_it_works.dart`

---

## Definition of the Problem

On the "How It Works" screen, the info panels below the numbered steps (3 panels in the supplier app, after Step 5; 4 panels in the customer app, after Step 4) rendered with text that was unreadable in dark mode - the foreground text color blended into the background instead of contrasting against it.

## Root Cause

Each panel is a `Container` with a tinted background plus a title/description on top. The background used a **fixed** color from `BrandColors` (e.g. `BrandColors.primaryContainer = Color(0xFFEDE7F6)`, a light purple hex constant defined in `source/shared/lib/constants/constants.dart`) that never changes regardless of theme. The foreground text, however, used a **theme-adaptive** color (`Theme.of(context).colorScheme.onPrimaryContainer`, or in the customer app's case, the default inherited theme text color / `colorScheme.onSurfaceVariant`).

Both apps generate their light and dark themes from the same seed color via `ColorScheme.fromSeed(seedColor: BrandColors.primary, brightness: ...)` (see `main.dart` in each app). In dark mode, `colorScheme.onPrimaryContainer` (and the other `on*Container` colors) resolve to a **light** tone, designed to sit on top of a **dark**-mode-appropriate container color. Since the background here never left its fixed light-mode value, dark mode ended up painting light text on a light background - the actual "unreadable" defect reported.

### Why this wasn't caught by prior reviews

The codebase already has an established, correct pattern for this exact problem - pairing `Theme.of(context).colorScheme.xContainer` (theme-adaptive background) with `colorScheme.onXContainer` (theme-adaptive foreground), both drawn live from the same `ColorScheme`, guaranteeing contrast in both themes. This pattern is used correctly in several other screens (e.g. `supplier_issue_card.dart`'s info panels). The "How It Works" screens, however, had been written (or last touched) with the **older** static `BrandColors.xContainer` background, and picked up the newer theme-adaptive text color for the foreground at some point without the background being updated to match - the two halves of the correct pattern got split across separate edits, and nothing caught the mismatch since both classes of code (a `BoxDecoration`'s `color:` and a `Text`'s `style.color:`) type-check identically as plain `Color` values - there's nothing statically detectable about one being fixed and the other being theme-driven.

## Audit

Every other use of `BrandColors.primaryContainer` / `successContainer` / `errorContainer` / `warningContainer` / `infoContainer` across both apps was checked (10 additional call sites, in `supplier_redeem_card.dart`, `supplier_home.dart`, `supplier_stamp_card.dart`, `supplier_issue_card.dart`, and `customer_app`'s `customer_card_detail.dart`). All 10 correctly pair the fixed container color with a matching **fixed** text color (`BrandColors.textPrimary`, a static dark gray) - not theme-adaptive, so they stay legible in both themes regardless (a valid, if not dark-mode-native, pattern). Only the two "How It Works" screens had the fixed-background/adaptive-foreground mismatch.

## Fix Applied

Switched every affected panel's background **and** foreground to the matching `colorScheme` container/on-container pair, so both move together as the theme changes:

| App | Panel | Background | Foreground/Icon |
|---|---|---|---|
| Supplier | Secure & Private | `colorScheme.primaryContainer` | `colorScheme.primary` (icon) / `onPrimaryContainer` (text, already correct) |
| Supplier | Dynamic QR Codes | `colorScheme.secondaryContainer` | `colorScheme.secondary` (icon) / `onSecondaryContainer` (text, already correct) |
| Supplier | Works Offline | `colorScheme.tertiaryContainer` | `colorScheme.tertiary` (icon) / `onTertiaryContainer` (text, already correct) |
| Customer | Your Privacy Protected | `colorScheme.primaryContainer` | `colorScheme.primary` (icon) / `onPrimaryContainer` (text) |
| Customer | Secure & Verified | `colorScheme.tertiaryContainer` | `colorScheme.tertiary` (icon) / `onTertiaryContainer` (text) |
| Customer | Dynamic QR Codes | `colorScheme.secondaryContainer` | `colorScheme.secondary` (icon) / `onSecondaryContainer` (text) |
| Customer | Works Anywhere | `colorScheme.surfaceContainerHighest` | `colorScheme.onSurfaceVariant` (icon + text) |

Material 3's `ColorScheme` only exposes three colored container slots (`primary`/`secondary`/`tertiary`), so the customer app's 4th panel ("Works Anywhere") uses the neutral `surfaceContainerHighest`/`onSurfaceVariant` pairing instead of introducing a fourth accent hue.

This trades the original literal semantic hue (orange = warning/time-sensitive, green = success/offline-friendly) for a guaranteed-correct, theme-generated hue - a deliberate choice, since no dark-mode-aware variant of `BrandColors`' semantic colors exists in this codebase to preserve both the hue and the contrast guarantee without introducing a new pattern. Each panel is still visually distinct from the others.

## Testing

- `flutter analyze` clean on both changed files (no new warnings introduced).
- Full test suite green on both apps (74 tests, supplier app; 125 tests, customer app) - no functional behavior changed, this is a color-only fix, so no new automated test was added.
- **Not yet visually verified on-device/simulator in both light and dark mode** - this was made from code inspection and knowledge of how `ColorScheme.fromSeed` behaves, not a rendered screenshot. Recommended as the first thing to check when testing resumes.

## Follow-Up Recommendations

1. Visually confirm both screens in light and dark mode on-device before resubmitting to Apple.
2. Consider whether other screens across the app have the same fixed-background/adaptive-foreground mismatch outside of the `BrandColors.xContainer` usages already audited here (e.g. any hardcoded `Color(0x...)` literals paired with `Theme.of(context).colorScheme.*` foregrounds) - this audit was scoped specifically to `BrandColors.xContainer` call sites, not every hardcoded color in the app.
3. If preserving the literal warning/success semantic hues in dark mode is wanted later, that would require adding explicit dark-mode variants to `BrandColors` (none exist today) rather than relying on Material 3's generated `colorScheme`.
