# Accessibility Statement

**LoyaltyCards v1.0.2+8**  
**Commitment:** Making digital loyalty cards accessible to everyone  
**Last Updated:** July 20, 2026  
**Compliance Target:** WCAG 2.1 Level AA

**Note:** The known dark-mode text-legibility risk has been checked and ruled out (see "Dark Mode" section below, verified 2026-07-20). Broader VoiceOver/semantic-labeling work remains open — see Roadmap.

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
- ⚠️ **PARTIAL:** Basic VoiceOver support via iOS defaults
- ⚠️ Custom widgets may lack semantic labels
- ⚠️ Image-only buttons missing accessibility labels
- ⚠️ Card stamp counts may not be clearly announced
- ⚠️ QR code scanning instructions need improvement

**Current Experience:**
- VoiceOver reads button labels
- VoiceOver announces navigation changes
- VoiceOver describes text fields

**Gaps:**
- QR scanner status not clearly announced
- Card visual details not fully described
- Stamp counts may be read as separate numbers
- Business logos described as "image" (not business name)

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

### ❌ Not Implemented (Future Enhancements)

#### Advanced Screen Reader Support

**13. Semantic Labels**
- ❌ Missing semantic labels on custom widgets
- ❌ No semantic grouping of related elements
- ❌ QR code scanner needs better state announcements

**14. Live Regions**
- ❌ Success/error messages not announced automatically
- ❌ Loading states not clearly communicated to screen readers

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

**Issue:** VoiceOver support relies on iOS defaults, not custom optimized

**Impact:**
- Screen reader users may experience verbose or unclear announcements
- Navigation flow may not be optimal
- Some interactive elements poorly described

**Current Mitigation:**
- All buttons have text labels
- Navigation is linear and predictable
- Standard iOS components provide baseline accessibility

**Future Enhancement (v0.3.0):**
- Add Semantics widgets throughout app
- Custom semantic labels for all interactive elements
- Optimized navigation for screen readers
- Clear announcements for success/error states

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
- ⚠️ No automated accessibility testing implemented
- ⚠️ No CI/CD accessibility checks

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
- [ ] Add Semantics widgets to all interactive elements
- [ ] Optimize VoiceOver announcements
- [ ] Add semantic labels for card details
- [ ] Improve QR scanner accessibility (voice guidance)
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

**Note:** An earlier draft of this document referenced planned NFC support as a non-visual alternative to QR scanning. That is not on the current product roadmap (see `docs/project-management/NEXT_ACTIONS.md`) and has been removed from this statement to avoid committing to an unplanned feature. QR scanning (Barrier 1 below) remains a visual-only requirement for now.

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

**Last Evaluation:** April 18, 2026 (general self-assessment); dark-mode legibility risk specifically re-checked July 20, 2026  
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
**Last Updated:** July 20, 2026  
**Next Review:** Before the final pre-submission build for v1.0 App Store release

---

_LoyaltyCards is committed to making our applications accessible to all users. We welcome feedback and will continue to improve accessibility with each release._
