# Accessibility Statement

**LoyaltyCards v1.0.2+8**  
**Commitment:** Making digital loyalty cards accessible to everyone  
**Last Updated:** August 31, 2026  
**Compliance Target:** WCAG 2.1 Level AA

**Note:** The known dark-mode text-legibility risk has been checked and ruled out (see "Dark Mode" section below, verified 2026-07-20). A first round of VoiceOver/semantic-labeling and live-region work landed 2026-08-31 for the Customer app - see "Screen Reader Support" and Roadmap below. Not yet applied to the Supplier app's own screens (the shared `AppFeedback` live-region fix benefits both apps, since it's one shared component, but Supplier-specific screens haven't had their own audit pass).

---

## Our Commitment

LoyaltyCards is committed to ensuring digital accessibility for all users, including those with disabilities. We strive to continually improve the user experience for everyone and apply relevant accessibility standards.

---

## Current Accessibility Status

**Status:** 🟡 **Partial Compliance** (v1.0.2+8)

LoyaltyCards is **partially conformant** with WCAG 2.1 Level AA. "Partially conformant" means that some parts of the application do not fully conform to the accessibility standard.

---

## Accessibility Features

### ✅ Currently Implemented

#### Visual Accessibility

**1. Native iOS Components**
- ✅ Uses standard Flutter Material Design widgets
- ✅ Inherits iOS system accessibility features
- ✅ Supports iOS accessibility shortcuts
- ✅ Compatible with AssistiveTouch

**2. Text Readability**
- ✅ Minimum font size: 16px (body text)
- ✅ Heading hierarchy: Proper text sizing (20-28px for headers)
- ✅ High contrast text on backgrounds (meets WCAG AA)
- ✅ Clear, readable font (Google Fonts system fonts)

**3. Color Contrast**
- ✅ Primary text: Black on white (21:1 ratio - exceeds WCAG AAA)
- ✅ Button text: White on colored buttons (minimum 4.5:1 ratio)
- ✅ Card text: High contrast on brand colors
- ✅ Error messages: Red background with white text (sufficient contrast)

**4. Visual Indicators**
- ✅ Icons accompanied by text labels
- ✅ Button states clearly visible (pressed, disabled)
- ✅ Form field outlines and focus states
- ✅ Clear navigation structure

#### Interaction Accessibility

**5. Touch Targets**
- ✅ Minimum button size: 44x44 points (iOS guideline)
- ✅ Adequate spacing between interactive elements
- ✅ Large QR code tap areas
- ✅ Floating action buttons: 56x56 points

**6. Gesture Support**
- ✅ Standard iOS gestures (tap, swipe)
- ✅ Back navigation via swipe or button
- ✅ No complex gestures required
- ✅ Alternative to gesture-only actions

**7. Keyboard/Voice Control**
- ✅ Compatible with iOS Voice Control
- ✅ Compatible with Switch Control
- ✅ All interactive elements focusable
- ✅ Logical tab order (natural reading flow)

#### Platform Integration

**8. iOS Accessibility Settings**
- ✅ Respects "Reduce Motion" setting
- ✅ Respects "Increase Contrast" setting (partial)
- ✅ Compatible with "Bold Text" setting
- ✅ Respects "Button Shapes" setting

**9. Biometric Authentication**
- ✅ Face ID with accessibility features
- ✅ Touch ID support
- ✅ Passcode fallback (always available)
- ✅ VoiceOver announces authentication prompts

---

### ⚠️ Partial Implementation (Needs Improvement)

#### Screen Reader Support

**10. VoiceOver (iOS Screen Reader)**
- ⚠️ **PARTIAL:** Basic VoiceOver support via iOS defaults, now supplemented with explicit work in the Customer app (2026-08-31)
- ✅ Loyalty card list items (Customer wallet home screen) now expose one combined, accurate description (business name, mode, progress, stamp count) instead of the visual tree's real structure - previously up to `stampsRequired` individual unlabeled circles per card, now excluded from semantics and replaced with a single label. Same fix applied to the card detail screen's stamp grid. Verified with an automated widget test (`test/screens/customer_home_semantics_test.dart`), not just manual spot-checking.
- ✅ Previously-unlabeled icon-only buttons (scanner flashlight toggle, home screen settings, search-clear) now have `tooltip`/semantic labels
- ✅ The QR code image itself now has a contextual semantic label ("QR code to receive a stamp at [Business]" / "...to redeem your reward at [Business]") instead of the generic default
- ⚠️ Custom widgets elsewhere in the app may still lack semantic labels - this was a targeted pass on the highest-value screens (wallet home, card detail, QR scanner, QR display), not an exhaustive audit
- ⚠️ Not yet applied to the Supplier app's own screens (only the shared feedback-message fix below benefits it)

**Current Experience:**
- VoiceOver reads button labels
- VoiceOver announces navigation changes
- VoiceOver describes text fields
- VoiceOver now announces QR scan outcomes (see Live Regions below) and reads loyalty cards as one clear sentence each

**Gaps:**
- Card visual details not fully described everywhere (only the two highest-traffic screens covered so far)
- Supplier app not yet covered by this pass

#### Dynamic Type

**11. Text Size Scaling**
- ⚠️ **PARTIAL:** Some text scales with iOS Dynamic Type
- ⚠️ Fixed-size text in some UI elements
- ⚠️ QR code size doesn't scale (functional limitation)

**Current Experience:**
- Body text scales with system settings
- Buttons text scales partially

**Gaps:**
- Some headings use fixed font sizes
- Card layout may break at extreme text sizes (200%+)

#### Dark Mode

**12. Dark Mode Support**
- ⚠️ **PARTIAL:** The app follows the device's system light/dark appearance (`main.dart` in both apps wires up real, distinct `theme:`/`darkTheme:` `ColorScheme.fromSeed` objects, defaulting to `ThemeMode.system`), but this was never built as an explicit, user-facing feature
- ⚠️ No in-app toggle to choose Light/Dark/System independent of the device setting
- ✅ **Verified (2026-07-20):** Checked every `BrandColors.textPrimary`/`BrandColors.textSecondary` text-color usage across both apps (21 instances total — 10 in the Supplier app, 11 in the Customer app) against their enclosing background. All of them sit on a fixed `BrandColors.*Container` background (or an explicit `Colors.white`/`Colors.grey[50]`), never on the theme's dynamic surface color — so none of them go illegible in dark mode. This is a deliberate, pre-existing pattern (one instance — the "Card Created" badge — was fixed this exact way in a past release per `CHANGELOG.md` v0.3.0+1), not an oversight.
- ⚠️ What this means in practice: branded info/success/warning callout badges keep a fixed light background + dark text regardless of the app's theme, so in dark mode they render as a light-colored badge on an otherwise-dark screen. That's a **visual style inconsistency**, not a contrast/legibility failure — text stays fully readable either way.
- ⚠️ This check covered the specific symbols most likely to cause invisible text (`BrandColors.textPrimary`/`textSecondary`); it was not an exhaustive pixel-by-pixel audit of every screen and widget, and no automated/manual VoiceOver or Dynamic Type dark-mode testing has been performed.

**Status:** The specific legibility risk this section previously flagged has been checked and ruled out. Making the branded badges themselves theme-aware (so they blend into dark mode instead of staying fixed-light) remains an optional future polish item, not a release blocker.

---

### ⚠️ Partial Implementation (continued)

#### Advanced Screen Reader Support

**13. Semantic Labels**
- ✅ Semantic grouping implemented for loyalty card list items and card detail stamp grids (Customer app) - see item 10 above
- ⚠️ Still missing on custom widgets outside the screens covered in this pass
- ✅ QR scanner: rejection reasons now announced (see Live Regions below); the "processing" state (spinner shown while a scan is being validated) does not yet have its own announcement

**14. Live Regions**
- ✅ **Success/error/info/warning messages are now announced automatically.** `AppFeedback` (`source/shared/lib/widgets/feedback.dart`) - the single component both apps use for every SnackBar-based message, including QR scan outcomes - wraps its content in `Semantics(liveRegion: true, ...)`, since Flutter's `SnackBar` doesn't reliably announce itself to VoiceOver/TalkBack on its own. This fixes every call site at once, in both apps.
- ✅ The Customer app's QR scanner screen also wraps its own in-panel rejection message (a separate UI element from the SnackBar) in the same `liveRegion: true` pattern, so a failed scan is announced even though the screen itself doesn't navigate away.
- ⚠️ Loading states (e.g. the QR scanner's "processing" spinner) still not explicitly announced - only the terminal outcomes (success/error) are covered so far.

### ❌ Not Implemented (Future Enhancements)

#### Visual Enhancements

**15. Customizable Colors**
- ❌ No color customization options
- ❌ No high-contrast mode override
- ❌ No option to disable brand colors

**16. Adjustable Interface**
- ❌ Fixed card sizes (no zoom/scaling)
- ❌ No simplified UI mode
- ❌ No option to disable animations beyond iOS setting

#### Audio/Visual Alternatives

**17. Audio Feedback**
- ❌ No audio cues for successful actions
- ❌ No haptic feedback alternatives to visual indicators
- ❌ No text-to-speech for card details

**Note:** iOS haptics supported via standard button presses

---

## Known Accessibility Barriers

### Barrier 1: QR Code Scanning (Visual Requirement)

**Issue:** QR code scanning requires camera and visual interpretation

**Impact:**
- Users with visual impairments cannot scan QR codes independently
- No alternative method for card issuance/stamp collection

**Workaround:**
- User can request assistance from business staff
- Business can scan customer's QR code (for stamps/redemption)
- Supplier can verbally confirm card details

**Future Enhancement (not currently planned/scheduled):**
- Voice-guided QR scanning
- Manual code entry option
- NFC as a non-visual alternative to QR (would require architecture changes; not on the current roadmap)

---

### Barrier 2: Card Visual Design

**Issue:** Cards use color and visual layout to convey information

**Impact:**
- Color-blind users may have difficulty distinguishing cards
- Screen reader users don't get full card description

**Workaround:**
- Business name text always present
- Stamp count provided as text (not just visual)

**Future Enhancement:**
- Add semantic labels for card descriptions
- Provide alternative text for all visual elements
- Pattern/texture options in addition to color

---

### Barrier 3: Limited Screen Reader Optimization

**Issue:** VoiceOver support relies mostly on iOS defaults, with targeted custom work on the Customer app's highest-traffic screens as of 2026-08-31 (see items 10/13/14 above) - not yet a comprehensive pass across either app

**Impact:**
- Screen reader users may experience verbose or unclear announcements on screens not yet covered
- Some interactive elements outside the covered screens remain poorly described
- Supplier app not yet covered at all (beyond the shared feedback-message fix)

**Current Mitigation:**
- All buttons have text labels
- Navigation is linear and predictable
- Standard iOS components provide baseline accessibility
- Success/error/info/warning messages now announce automatically app-wide (both apps, via the shared `AppFeedback` component)
- The Customer app's wallet home screen and card detail screen now describe each loyalty card as one clear sentence instead of many unlabeled visual elements

**Future Enhancement:**
- Extend the same semantic-labeling pass to the remaining Customer app screens and to the Supplier app
- Announce loading/processing states, not just terminal success/error outcomes
- Custom semantic labels for all remaining interactive elements
- Optimized navigation for screen readers

---

### Barrier 4: Fixed-Color Badges Don't Adapt to Dark Mode

**Issue:** The app follows system light/dark appearance for its main surfaces, but branded info/success/warning callout badges keep a fixed light background regardless of theme (see "Dark Mode Support" above), and there's no in-app override independent of the device setting

**Impact:**
- No legibility impact — text on these badges remains readable in both themes, verified 2026-07-20
- Visual inconsistency: a light-colored badge can appear on an otherwise dark-themed screen
- Users cannot force dark (or light) mode independent of their device setting

**Workaround:**
- iOS "Reduce White Point" setting (Settings → Accessibility → Display)
- iOS "Smart Invert" provides pseudo dark mode
- Toggle the device's own Light/Dark appearance setting, which the app follows for its main surfaces

**Future polish (not a release blocker):**
- Optionally give branded badge containers theme-derived variants so they blend into dark mode
- Decide whether an in-app Light/Dark/System override is worth adding for a future release

---

## Testing Methodology

### Accessibility Testing Performed

**Manual Testing (v0.2.0):**
- ✅ VoiceOver navigation tested (basic flows)
- ✅ Dynamic Type tested (system text sizes)
- ✅ Reduce Motion tested (respects setting)
- ✅ Color contrast analyzed (manual WCAG checker)
- ✅ Touch target sizes measured

**Automated Testing:**
- ⚠️ Not yet run as part of CI/CD, but the 2026-08-31 semantic-labeling work for the Customer app's wallet home screen has a dedicated automated widget test (`test/screens/customer_home_semantics_test.dart`) that asserts on the actual semantics tree (`find.bySemanticsLabel`) rather than just visible text - both that the correct combined label is present and that redundant per-element labels are not
- ⚠️ No broader automated accessibility testing (e.g. contrast/tap-target linting) implemented

**User Testing:**
- ⚠️ Not yet tested with users who have disabilities
- ⚠️ No formal accessibility audit performed

---

### Accessibility Testing Tools

**Used:**
- iOS Accessibility Inspector (Xcode)
- Manual VoiceOver testing
- Color contrast calculators (WebAIM)

**Planned:**
- Automated accessibility linting
- Third-party accessibility audit
- User testing with assistive technology users

---

## Roadmap to Full Compliance

### Before Final Pre-Submission Build

**High Priority:**
- [x] Verify the known dark-mode text-legibility risk (`BrandColors.textPrimary`/`textSecondary` on dynamic surfaces) — checked 2026-07-20, confirmed not present; see "Dark Mode Support" above
- [x] Add Semantics widgets to interactive elements — done 2026-08-31 for the Customer app's wallet home, card detail, QR scanner, and QR display screens; Supplier app and remaining Customer screens still open
- [x] Add live-region announcements for success/error/info/warning messages — done 2026-08-31, shared `AppFeedback` component, both apps
- [x] Add semantic labels for card details — done 2026-08-31 for the Customer app's loyalty card list and detail stamp grid
- [ ] Improve QR scanner accessibility further (voice guidance beyond the outcome announcement already added)
- [ ] Extend this pass to the Supplier app and the remaining Customer app screens
- [ ] Test with real VoiceOver users

**Medium Priority (may defer post-v1.0):**
- [ ] Give fixed-color badge containers theme-derived variants for visual consistency in dark mode (polish, not a legibility issue)
- [ ] Decide on in-app Light/Dark/System override vs. following system setting only
- [ ] Improve Dynamic Type support (all text scalable)
- [ ] Add haptic feedback for key actions
- [ ] Audio confirmation for successful scans
- [ ] Better contrast mode support

### Future (Post-v1.0)

**Under consideration, not committed:**
- [ ] Voice-guided card selection
- [ ] Simplified UI mode
- [ ] Customizable high-contrast themes
- [ ] Professional third-party accessibility audit
- [ ] WCAG 2.1 Level AA certification

**Note:** An earlier draft of this document referenced planned NFC support as a non-visual alternative to QR scanning. That is not on the current product roadmap (see `docs/project-management/DEFECT_TRACKER.md`) and has been removed from this statement to avoid committing to an unplanned feature. QR scanning (Barrier 1 below) remains a visual-only requirement for now.

---

## Supported Assistive Technologies

### ✅ Fully Supported

- **iOS VoiceOver** (screen reader) - Basic support
- **iOS Voice Control** (voice commands)
- **iOS Switch Control** (external switches)
- **iOS AssistiveTouch** (touch alternatives)
- **iOS Zoom** (screen magnification)
- **iOS Bold Text** (enhanced readability)
- **iOS Reduce Motion** (animation reduction)

### ⚠️ Partially Supported

- **iOS Dynamic Type** (text scaling) - Some limitations
- **iOS Increase Contrast** - Partial respect
- **iOS Smart Invert** (pseudo dark mode) - Not optimized

### ❌ Not Yet Supported

- **Third-party screen readers** (beyond VoiceOver)
- **Braille displays** (untested, may work via VoiceOver)

---

## Accessibility Best Practices Applied

### Design Principles

1. **Perceivable**
   - ✅ Text alternatives for non-text content (partial)
   - ✅ Content presented in multiple ways
   - ✅ Sufficient color contrast
   - ⚠️ No audio-only or video-only content (N/A)

2. **Operable**
   - ✅ All functionality available via keyboard/voice
   - ✅ No time limits on interactions
   - ✅ Clear navigation structure
   - ✅ Multiple ways to navigate (back button, swipe)

3. **Understandable**
   - ✅ Readable text (plain language)
   - ✅ Predictable navigation
   - ✅ Clear error messages
   - ✅ Consistent UI patterns

4. **Robust**
   - ✅ Compatible with assistive technologies
   - ✅ Uses standard iOS components
   - ✅ Semantic HTML equivalents (Flutter widgets)

---

## Contact & Feedback

### Report Accessibility Issues

If you encounter accessibility barriers while using LoyaltyCards, please contact us:

**Email:** ian.hamlet@dotconnected.com  
**Subject Line:** "Accessibility Issue - [App Name]"

**Please include:**
- Which app (Customer or Supplier)
- Device and iOS version
- Assistive technology used (if applicable)
- Description of the barrier
- What you were trying to do
- Screenshots or screen recordings (if possible)

**Response Time:** We aim to respond to accessibility issues within 48 hours and prioritize fixes in upcoming releases.

---

## Conformance Claims

### WCAG 2.1 Conformance Status

**Level A:** ⚠️ Partially Conformant  
**Level AA:** ⚠️ Partially Conformant  
**Level AAA:** ❌ Not Conformant

**Last Evaluation:** April 18, 2026 (general self-assessment); dark-mode legibility risk specifically re-checked July 20, 2026; first round of Customer app semantic-labeling/live-region work landed August 31, 2026 (see Document History)  
**Evaluation Method:** Self-assessment (manual testing + targeted code review)  
**Next Evaluation:** Before the final pre-submission build, covering the remaining open roadmap items (VoiceOver/semantics work)

---

## Legal Compliance

### Relevant Standards & Laws

**United States:**
- Americans with Disabilities Act (ADA) - Title III
- Section 508 (Rehabilitation Act)

**International:**
- Web Content Accessibility Guidelines (WCAG 2.1)
- EN 301 549 (European Standard)

**Apple App Store:**
- iOS Human Interface Guidelines (Accessibility)
- App Store Review Guidelines (2.5.18 - Accessibility)

**Commitment:**
We are actively working toward full compliance with WCAG 2.1 Level AA and relevant accessibility laws.

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | April 18, 2026 | Initial accessibility statement for v0.2.0 |
| 1.1 | July 20, 2026 | Corrected Dark Mode claims to match actual (system-following, unaudited) implementation; removed unplanned NFC commitment; filled in contact email; updated version/dates |
| 1.2 | July 20, 2026 | Verified the specific dark-mode legibility risk (BrandColors.textPrimary/textSecondary on dynamic surfaces) across both apps and confirmed it does not occur — all instances pair fixed text with fixed backgrounds. Reframed as a visual style item (fixed-color badges in dark mode), not a contrast/legibility bug. Updated roadmap accordingly. |
| 1.3 | August 31, 2026 | First round of VoiceOver/semantic-labeling and live-region work, Customer app: live-region announcements for all AppFeedback success/error/info/warning messages (shared component, both apps benefit) and the QR scanner's inline rejection message; combined semantic labels replacing per-element announcements for loyalty card list items and the card detail stamp grid (previously up to `stampsRequired` individual unlabeled circles per card); semantic labels added to previously-unlabeled icon buttons (flashlight, settings, search-clear) and the QR code image itself. Covered the wallet home, card detail, QR scanner, and QR display screens - not an exhaustive pass, and not yet applied to the Supplier app's own screens. Added automated widget-test coverage asserting on the actual semantics tree, not just visible text. Updated roadmap and per-item status accordingly. |

---

## Resources

### Internal Documentation
- [User Guide](../user/USER_GUIDE.md) - Includes accessibility tips
- [Support Procedures](../deployment/SUPPORT_PROCEDURES.md) - Accessibility support

### External Resources
- [Apple Accessibility](https://www.apple.com/accessibility/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM (Web Accessibility In Mind)](https://webaim.org/)
- [iOS Accessibility for Developers](https://developer.apple.com/accessibility/ios/)

---

**Maintained by:** Development Team  
**Last Updated:** August 31, 2026  
**Next Review:** Before the final pre-submission build for v1.0 App Store release

---

_LoyaltyCards is committed to making our applications accessible to all users. We welcome feedback and will continue to improve accessibility with each release._
