# Changelog

All notable changes to the LoyaltyCards project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

**Status:** 🔵 In development on `feature/express-mode-cooldown-display` - not yet targeted at a specific version/build number (planned to ship alongside a positioning/metadata update as the next release - see `docs/project-management/NEXT_ITERATION_PLANNING_2026-08-21.md`).

### Added
- **Express Mode: the configured scan cooldown is now shown in Settings' Business Information section.** Previously the per-business cooldown (`Business.scanInterval`, set via the slider on onboarding/Fix Now) had no way to be checked after setup short of re-opening that slider - now it's visible at a glance alongside Business Name, Stamps Required, and Operation Mode. Secure Mode businesses don't use a cooldown, so the row only appears for Express Mode. `source/supplier_app/lib/screens/supplier/supplier_settings.dart`.
- **Express Mode: the scan cooldown is now editable after setup, not just at onboarding.** Tapping the row above opens the same stepper/slider control used during onboarding (`source/supplier_app/lib/widgets/scan_interval_editor.dart`), bounded to the same 5-60s range. Safe to change anytime - unlike `stampsRequired`, `scanInterval` isn't baked into issued cards; it's read live off the `Business` record each time a stamp is generated, so a change applies to the very next scan with no effect on cards already issued. See `docs/project-management/FEATURE_PLAN_SCAN_INTERVAL_EDITABLE.md`.

## [2.1.1+29] - 2026-08-17

**Status:** 🟢 LIVE — approved by Apple and released to the App Store 2026-08-19 (both apps, via App Store Connect). Build-only bump. Supersedes v2.1.1+28, which shipped DECISION-017 and TEST-021 to TestFlight but not this fix, found via real-device testing of that exact build. Apple doesn't allow re-uploading the same build number with different content. Built and delivered to TestFlight 2026-08-18, real-device validated, submitted for App Store review 2026-08-18. See `docs/deployment/RELEASES.md` for the full release record.

### Fixed
- **TEST-022: TEST-021's compact issue-card QR encoding was unconditional, breaking issuance for any customer app older than that fix.** A supplier on v2.1.0+27 or later compact-encodes every Issue Card QR regardless of size - Base45 is never valid JSON, so a customer app that predates TEST-021 fails to parse it at all (a generic "not a valid QR Code" error), for *every* issuance, not just the rare high-initial-stamp-count case TEST-021 targeted. Confirmed on a real device (supplier 27, customer 23). Fixed by preferring plain JSON whenever it fits (covers every initial-stamp count up to 16, comfortably spanning the whole 3-12 supported range), falling back to compact encoding only for the genuine legacy edge case. Applied the same fix proactively to the redemption QR (TEST-020), which had the identical unconditional-encoding shape. Full detail: `docs/project-management/DEFECT_TRACKER.md` TEST-022.

## [2.1.1+28] - 2026-08-17

**Status:** 🟢 Shipped to TestFlight, superseded by v2.1.1+29 for App Store submission (missing the TEST-022 fix above). Patch version bump (2.1.0 -> 2.1.1, not build-only). Real-device verified end-to-end, including the full DECISION-017 flow across both matched and mismatched supplier/customer version pairs - see `docs/testing/DECISION-017_LEGACY_BUSINESS_TEST_PLAN.md`. Supersedes v2.1.0+27, which shipped TEST-021 to TestFlight the night of 2026-08-16/17 but not DECISION-017. v2.1.0+26 was already built and uploaded to TestFlight before either fix below was found/added.

### Added
- **DECISION-017: a business whose stamps-required count falls outside the supported range can now fix it themselves, in-app.** Previously, a business in this state (e.g. one still configured for 20 stamps, from before this range tightened) had no way to recover short of a full reset, wiping every customer's card - a disproportionate response to a number being out of range, when changing it going forward is actually safe (each existing card keeps its own stamp count, unaffected by the business's current setting). The Supplier app now shows a proactive warning on Home and blocks Issue Card from generating a doomed QR at all, with a "Fix Now" flow (also available in Settings) to reconfigure into the supported range. Full detail: `docs/project-management/DEFECT_TRACKER.md` DECISION-017.

### Fixed
- **TEST-021: issuing a card with many pre-applied initial stamps could hit the same silent QR-capacity failure as TEST-017, never fixed on the issuance side.** Found by real-device testing of the v2.1.0+26 TestFlight build, using the same legacy 20-stamp business used throughout this whole defect chain. Applied the same compact encoding (`CardIssueQrCodec`, mirroring `RedemptionQrCodec`) to the supplier app's issue-card QR - on-screen, Print, and Share, the latter two having an even lower capacity ceiling than the on-screen view. Doesn't affect any business created under the current 3-12 range - and DECISION-017 above closes off the only path that could reach it anyway. Full detail: `docs/project-management/DEFECT_TRACKER.md` TEST-021.

## [2.1.0+27] - 2026-08-17

**Status:** 🟢 Shipped to TestFlight the night of 2026-08-16/17, superseded by v2.1.1+28 for App Store submission (missing DECISION-017 - see above). Carried TEST-021 only - see 2.1.1+28 above for full detail.

## [2.1.0+26] - 2026-08-16

**Status:** 🟢 Shipped to TestFlight, superseded by v2.1.0+27 for App Store submission (missing TEST-021 - see above). Minor version bump (2.0.4 -> 2.1.0, not a build-only bump - see Added). Real-device verified, including via this actual TestFlight build (12-stamp Secure Mode card with 100% overflow-relocated stamps redeems successfully; a 3/4-stamp business issues a working card end-to-end; the TEST-019 message confirmed against the 20-stamp legacy business; Express Mode and Recovery Backup restore also spot-checked). Supersedes 2.0.4+24 and the interim test-only build 2.0.4+25 (never a real release candidate). Also supersedes 2.0.3+23, which is **live on the App Store** but contains TEST-016 (carried forward and fixed here) and does not have any of the fixes below.

### Added
- **Raised the maximum Secure Mode `stampsRequired` from 10 to 12** (TEST-020) - a real, deliberate capability increase, not a side effect, which is why this is a minor version bump rather than a patch. Backward compatible: nothing that worked at 10 stamps changes.

### Fixed
- **TEST-016: Businesses set up with 3 or 4 required stamps could never issue a valid card.** The onboarding "Stamps Required" slider allows a minimum of 3, but `CardIssueToken.isValid()` rejected anything below 5 - any card issued by such a business always failed validation on scan, in both Secure and Express Mode, since both share the same token and validation path. Discovered while testing the supplier app on macOS (unrelated investigation - see `docs/project-management/DEFECT_TRACKER.md` TEST-016). Fixed by lowering the floor to 3 to match the slider. (Carried forward from 2.0.4+24, which never shipped.)
- **TEST-017: Secure Mode redemption QR silently failed on higher-stamp-count or heavily overflow-relocated cards.** A redemption QR bundles one cryptographic signature per stamp; at high stamp counts the plain-JSON payload could exceed a QR code's maximum encodable capacity. `QrImageView` has no way to signal this ahead of time, so the failure only surfaced when the widget was actually painted - by which point Flutter's release-build default is to render nothing but a blank grey box, no error text. Interim fix (lowered the cap to 10, added a fallback UI) superseded by TEST-020's real fix below.
- **TEST-018: Overflow-relocated stamps could lose the provenance needed to verify them at redemption.** When a completed card's leftover stamps spill onto another card, the app records each moved stamp's *original* card/position/hash, since its signature was signed against that original context and can't be recomputed for its new position. One of three code paths that do this move omitted those fields entirely, silently dropping them - a legitimately-earned stamp could then fail signature verification. Fixed by adding `Stamp.relocateTo()`, which centralizes the entire relocated-stamp construction so no path can omit the fields again.
- **TEST-019: Generic "An error occurred" shown when a business's card configuration is incompatible with the app version.** A business created before TEST-017 tightened the stampsRequired bound (e.g. still configured for 20) failed `CardIssueToken.isValid()` on every card it issues, forever - but the customer only ever saw a generic, misleading "please try again" message. Added `CardIssueToken.validationError()` to report a specific, actionable reason instead.
- **TEST-020: the real fix for TEST-017**, not just a narrower stopgap. Replaced the plain-JSON/byte-mode redemption QR encoding with gzip compression + Base45 text encoding (RFC 9285) + QR's more space-efficient "alphanumeric" encoding mode, plus an explicit format-version field. A 12-stamp card is now safe even if every one of its stamps was overflow-relocated - the worst case, verified against the real QR encoding library, not estimated. Also consolidated the customer app's redemption-QR generation onto its existing `QRTokenGenerator` instead of a hand-rolled duplicate, which surfaced and fixed a real, separate bug: that generator had silently drifted to omit device-mismatch detection (V-005). Full detail and measured payload sizes: `docs/project-management/DEFECT_TRACKER.md` TEST-020.

## [2.0.4+24] - 2026-08-15

**Status:** 🟡 SUPERSEDED by 2.1.0+26 - never built, uploaded, or submitted; folded into that release along with 2.0.4+25 (an interim build-number-only bump for on-device testing, never a real release candidate either).

### Fixed
- **TEST-016: Businesses set up with 3 or 4 required stamps could never issue a valid card.** The onboarding "Stamps Required" slider allows a minimum of 3, but `CardIssueToken.isValid()` rejected anything below 5 - any card issued by such a business always failed validation on scan, in both Secure and Express Mode, since both share the same token and validation path. Discovered while testing the supplier app on macOS (unrelated investigation - see `docs/project-management/DEFECT_TRACKER.md` TEST-016). Fixed by lowering the floor to 3 to match the slider.

## [2.0.3+23] - 2026-08-15

**Status:** 🟢 **LIVE ON THE APP STORE** (both apps) - built, uploaded, TestFlight-tested (Sharing feature and both bug fixes confirmed working), submitted for App Store review 2026-08-15, and approved and released 2026-08-16. **⚠️ Contains TEST-016** (see 2.1.0+26 above) - supersede with that build as soon as possible. Supersedes 2.0.3+22, which never produced an uploaded build; everything below is the complete state of the 2.0.3 line so far.

### Added
- **Sharing feature (both apps):** new Settings section, "Sharing," with "Tell a Business" (QR code + native share-sheet link to LoyaltyCards Business - for a customer referring a shop, or a shop owner referring another shop) and "Tell a Friend" (same, but to LoyaltyCards - for customer-to-customer referral, or a shop pointing a new customer at the wallet app). Built as a reusable `AppReferralScreen` widget in the shared package rather than three near-identical screens, since the same pattern is needed in both apps. The supplier app also gets a small "Tell a Friend" shortcut icon on the Home screen's app bar, since a shop needs this one tap away during a live checkout interaction, not buried in Settings. Settings reordered in both apps to put Sharing alongside the other identity/account-level sections.
- Each app's description now links directly to the companion app's App Store listing, so a reader doesn't have to search for it.
- Printable "Get the App" QR flyer for suppliers to display at checkout (`marketing/supplier_app/get-the-app-flyer.html`, published copy linked from the Supplier Setup Guide and site homepage) - uses the official Apple "Download on the App Store" badge SVGs, switching between black/white variants by color scheme and forcing black for print.

### Fixed
- **Express Mode stamps were routed to the wrong card.** Reported: add a card, collect a few stamps, scan "Add Card" again for the same business (correctly creates a second, empty overflow card), then scan "Add Stamp" - the stamp landed on the empty card instead of the older card that already had progress and room, and repeating the cycle left several partially-filled cards instead of ever finishing one. Root cause: the stamp lookup used `getAllCards().firstWhere(...)`, which always returns the most recently created matching card (`getAllCards()` orders newest-first) with no concept of "has space" or "not redeemed." Fixed by routing through the existing `CardRepository.findCardWithSpace()` helper instead, which was already used correctly elsewhere for overflow handling.
- **Clone/Recovery Backup screens briefly showed a false error on open.** Reported: opening "Clone to Another Device" showed "Failed to generate clone QR" for a moment before the real screen appeared. Both screens kick off an async authenticate-then-generate flow directly from `initState()`, but their loading flag started `false` and wasn't set `true` until generation actually began - after the biometric prompt resolved - leaving a gap where the first frame rendered with no data and the flag still saying "not loading." Fixed by starting both flags `true`, matching the pattern already correct in three other screens; audited the rest of `supplier_app` for the same shape, no other instances found.
- App Store Connect metadata corrections queued since 2.0.2+21 shipped, now finalized as real submission content in `APP_STORE_METADATA_PACKET_v2_0_3_23.md`: Category (both apps were live under Food & Drink - a poor fit, especially for the B2B supplier app - now Lifestyle/Shopping for the customer app and Business/Productivity for the supplier app) and Subtitle (customer app's was blank in ASC; both now lead with each app's actual differentiator instead of a generic description).
- Resolved the customer app name question flagged 2026-08-10: "LoyaltyCards Customer Wallet" is correct (matches live ASC), not "LoyaltyCards - Digital Stamps" as every doc previously said - corrected throughout the repo.

## [2.0.2+21] - 2026-08-10

**Status:** 🟢 **LIVE ON THE APP STORE** - passed App Review and is now available to the public (both apps). First public release. Build-only bump - Transporter flagged the 2.0.1+20 upload attempt for a deployment-target issue; no app behavior changed beyond that plus the CRASH-001/UI-001 fixes carried over from 2.0.1+20.

### Fixed
- Raised `IPHONEOS_DEPLOYMENT_TARGET` from 13.0 to 15.0 in both apps (`project.pbxproj`, plus the commented `Podfile` reference) - Apple requires 15.0+ for all App Store Connect uploads starting Spring 2027, and Transporter had already begun flagging 13.0 as a warning on this upload.
- Fixed a real inaccuracy across all 4 public docs (`ABOUT_LOYALTYCARDS.md`, `about.html`, `user-guide.html`, `supplier-setup-guide.html`): Express Mode redemption was described as scanning a "Redeem QR code," but it's actually a witnessed tap-to-redeem with no QR involved at all - predates this version, caught while checking these docs for 2.0.1+20 accuracy.

### Documentation
- Recorded the decision to resubmit to App Review without reproducing CRASH-001 locally or on the exact M3 iPad from the crash report, since both identified trigger paths are already fixed and independently regression-tested - see "Decision: Resubmitting Without Hardware Reproduction" in `CRASH-001-stamp-print-race-condition.md`.

## [2.0.1+20] - 2026-08-06

**Status:** Built, superseded by 2.0.2+21 before upload - see Fixed above. Responds to an Apple App Review rejection of the 2.0.0+19 submission - see CRASH-001 below. Patch version bump - bug fixes and copy changes only, no format/behavior break.

### Fixed
- **CRASH-001: native `EXC_BAD_ACCESS` crash printing the Stamp Setup QR code (supplier app).** Apple's App Review rejection reported a crash on iPad Air 11-inch (M3), iPadOS 26.6, tapping "Print." Traced to `EXC_BAD_ACCESS` inside `CGPDFDocumentGetNumberOfPages`, on a background thread UIKit spins up itself to compute the page count for the native Print Preview screen. Root cause: the Stamp Setup screen's Print button had no guard against a fast double-tap, which could fire two concurrent `Printing.layoutPdf()` calls and race the native plugin's print-job setup. Fixed by adding a busy-state guard (`_isPrinting`) that disables the button while a print job is in flight. Audited every other call site of `BackupStorageService`'s print/share/save methods and found the identical unguarded-button gap on 5 more buttons across `recovery_backup_screen.dart` (Print Backup, Share via Email, Save to Files) and `supplier_issue_card.dart` (Print, Share) - all fixed the same way. Regression tests added for all 6 locations (`supplier_stamp_card_test.dart`, `supplier_issue_card_test.dart`, `recovery_backup_screen_test.dart`), each verified red (native call fires twice with the guard removed) before green. Full writeup: `docs/project-management/CRASH-001-stamp-print-race-condition.md`.
- **CRASH-001 follow-up:** every `Printing.layoutPdf()` call handed `pdf.save()`'s output straight to the native plugin with no validation - a second, single-tap-reachable path to the same crash if PDF generation ever produced empty or malformed bytes. Added `BackupStorageService._isValidPdfBytes()` (non-empty, correct `%PDF-` header) ahead of all 3 print paths (`printBackup`, `printSimpleToken`, `printIssueCard`); invalid output now surfaces as an ordinary caught "Failed to print" error instead of reaching native code.
- **UI-001: unreadable text on How It Works info panels in dark mode (both apps).** The supplier app's 3 panels (after Step 5) and the customer app's 4 panels (after Step 4) paired a fixed `BrandColors.xContainer` background (light-mode-only) with theme-adaptive foreground text - in dark mode the background never changed while the text flipped to a light tone meant for dark surfaces, producing unreadable light-on-light text. Fixed by switching both background and foreground to matching `colorScheme` container/on-container pairs. Full writeup: `docs/project-management/UI-001-how-it-works-dark-mode-contrast.md`.
- Raised `IPHONEOS_DEPLOYMENT_TARGET` from 13.0 to 15.0 in both apps (`project.pbxproj`, plus the commented `Podfile` reference) - Transporter flagged 13.0 during this build's upload, since Apple requires 15.0+ for all App Store Connect uploads starting Spring 2027.

### Changed
- Express Mode redemption copy (customer app) now explicitly frames the exchange as a witnessed handshake rather than an implicit self-service action: the pre-redeem instruction tells the customer to show their supplier the completed card before tapping Redeem, the confirm dialog reframes the tap itself as the moment of exchange (previously asked "have you received your reward?" - backwards, since nothing had happened yet), and the redeemed-card screen now explicitly says to show it to the supplier to confirm. No logic changed - copy only, in `customer_card_detail.dart`.

### Documentation
- Added `docs/project-management/CRASH-001-stamp-print-race-condition.md` and `docs/project-management/UI-001-how-it-works-dark-mode-contrast.md`, both cross-referenced from `DEFECT_TRACKER.md`.

## [2.0.0+19] - 2026-07-28

**Status:** Built, uploaded, and **submitted for App Store review 2026-07-28** (both apps). Release branch `releases/v2.0.0-build19`. First submission beyond TestFlight for this project.

### Fixed
- Express Mode "add card" QR rejecting a repeat customer entirely: once a card was redeemed, re-scanning the same static QR to start a new loyalty cycle was blocked forever ("Card has already been scanned"), since the dedup check didn't distinguish an active card from a redeemed one. Now only blocks re-scanning while the existing card is still active.
- If that QR also grants initial/welcome stamps, those signatures are bound to the QR's fixed cardId, not the new card's fresh id on a repeat cycle - now correctly carried over using the same `originalCardId`/`originalStampNumber`/`originalPreviousHash` mechanism built for overflow-moved stamps, rather than being dropped.
- Closed a critical redemption-inflation gap in Secure Mode chain verification (duplicate/replayed proof signatures, and an unused proof-count check), and a third instance of the additional-stamp signing-format bug (this time for initial stamps) - both found via a multi-role security/fraud/UI/code-quality review pass.
- 2 more Dynamic Type overflow spots the earlier sweep missed, and an accessibility-harming `ScaleCapped` misapplication on primary instructional text.
- Delete-card confirmation now warns explicitly when the card has stamps collected or is complete and ready to redeem, instead of a generic message regardless of what's actually at stake.

### Added
- Real v7→v8 DB migration test coverage (previously only fresh-create was tested).

### Documentation
- Recorded the accepted-risk decision on the rate-limiter's device-clock manipulation angle in `docs/quality/VULNERABILITIES.md` (V-015 addendum) - not significant given Express Mode's framing as a paper-card equivalent, no further mitigation planned.
- De-staled `docs/user/ABOUT_LOYALTYCARDS.md` (Express Mode rename, corrected rate-limit claim, dropped pilot/invitation-only framing) and published a new public page, `site/user/about.html`, explaining the two-app pairing and Express vs Secure Mode with case studies.
- Replaced the stale v1.0.2+8 App Store metadata packet with `APP_STORE_METADATA_PACKET_v2_0_0_19.md` - same Express Mode rename, plus a "Two Apps, One System" section and case study in each app's description (later shortened for readability before submission), and the App Privacy questionnaire update needed for the customer app's Secure Mode device-ID signal.

## [2.0.0+18] - 2026-07-27

**Status:** Built on `develop` (merged from `feature/uireview`), not yet built/uploaded as an IPA. Major version bump.

### Changed
- **Breaking: QR token format.** The QR token payload gained new signed fields during the security review (`stampCount`, `expiryDate`, `scanInterval`, device-mismatch tracking, etc.) since the last main-branch release. Old "add card" and "add stamp" QR codes printed from a pre-review build still parse (the new fields are additive and default-safe) but now fail signature verification, since the signed data those defaults are checked against has changed - confirmed by device testing. There's no version marker in the token to distinguish "old format, expected to fail" from "corrupted/tampered", so this is called out as a deliberate major-version line rather than folded into another minor bump. **Existing printed QR codes will need reprinting after this ships.**

## [1.6.0+17] - 2026-07-27

**Status:** Built on `feature/uireview` (not yet merged to `develop`/`main`), not yet built/uploaded as an IPA. Build-only bump (same 1.6.0 feature set as +16).

### Added
- Require device authentication (Face ID/Touch ID/passcode) before an `import_business_screen.dart` restore actually commits - previously only a tap-through confirmation dialog stood between an idle, unconfigured device and having a scanned backup/clone QR silently installed as its business identity. Covers both the recovery-backup and clone-QR flows, since they share the same import code path.

## [1.6.0+16] - 2026-07-27

**Status:** Built on `feature/uireview` (not yet merged to `develop`/`main`), not yet built/uploaded as an IPA. Minor version bump (not patch) to keep this distinguishable from v1.5.0+15 in case of rollback.

### Fixed
- Customer app: `AppLockWrapper`'s app-lock preference was only refreshed at cold launch or while already locked - toggling app lock ON in Settings mid-session (while already authenticated) never re-locked on the next background/foreground until the app was fully killed and relaunched. Now re-reads the preference fresh on every background.
- `customer_card_detail.dart`: "N of N stamps" badge (shown once a card is complete/redeemed) overflowing at large-but-not-max accessibility text sizes
- `supplier_home.dart`: Issued/Stamped/Redeemed stat labels wrapping mid-word ("Stamp/ed", "Redee/med") at large text sizes, throwing the numbers above them out of alignment since the columns became different heights - labels now scale-capped, keeping them single-line and the columns equal height
- `supplier_home.dart`: dropped the redundant period after step numbers in the info panel ("1." → "1"), and scale-capped the title/description text so it stays proportional to the fixed-size number circle beside it at large text sizes

### Added
- Optional app-wide biometric lock for the supplier app, matching the customer app - previously it only gated individual actions (viewing backup/clone QR codes) with no app-wide lock option at all. New `AppLockWrapper` in `main.dart`, new Security section in `supplier_settings.dart`, with the fresh-read-on-background fix applied from the start

### Fixed
- More Dynamic Type / layout overflow found across supplier screens at large-but-not-max accessibility text sizes: "Quick Start Stamps" / "Reusable QR (no expiry)" text and stepper counters (`supplier_issue_card.dart`, `supplier_onboarding.dart`, `supplier_stamp_card.dart`), REDEEMED/COMPLETE badges in narrow rotated bars (`customer_card_detail.dart`, `qr_display_screen.dart`), and Issued/Stamped/Redeemed stat columns clipping the rightmost counter (`supplier_home.dart`)
- Mini-FAB camera control labels (Flip/90°/180°) upgraded from a smaller base font to `ScaleCapped`, since the smaller font alone still overflowed at large-but-not-max scale, across all 4 files that have these controls
- Numbered-circle widgets that don't scale with their fixed-size container now use `ScaleCapped` (`how_it_works.dart` in both apps, `supplier_home.dart`, `clone_device_screen.dart`)
- `import_business_screen.dart`: the "Confirm Business Restore" dialog now scrolls instead of clipping its bottom paragraph; the blue instructional banner over the scanner is scale-capped so it can't grow tall enough to cover the scan target
- 3 `AlertDialog` titles now wrap instead of overflowing the dialog's narrower width (`import_business_screen.dart`, `recovery_backup_screen.dart`, `supplier_redeem_card.dart`)
- `clone_device_screen.dart` "Expires in: ..." info box overflow

### Changed
- Renamed "Token Configuration" to "Stamp Setup" on the supplier stamp issuance screen

## [1.4.0+14] - 2026-07-27

**Status:** Built on `feature/uireview` (not yet merged to `develop`/`main`), not yet built/uploaded as an IPA. Minor version bump (not patch) to keep this distinguishable from v1.3.0+13 in case of rollback.

### Fixed
- Secure Mode redemption always failing for a card that ever received an overflow-split stamp from another card completing - the moved stamp's signature covered its original position, not its new one, so redemption verification always rejected it. Added `original_card_id`/`original_stamp_number`/`original_previous_hash` columns (DB v7→v8 migration) recording a moved stamp's true signing context, populated only by internal move logic - never from anything a scanned QR token or user action controls
- Secure Mode multi-stamp grants ("additional stamps") signed with a shorter, non-canonical string that always failed redemption verification even though accepted fine when first scanned - now uses the same canonical `SignatureFormat` as every other signing/verification call site
- A card being auto-completed overwriting its own just-applied completed stamp count back to its stale pre-scan value when no other card genuinely had space (`findCardWithSpace` matched itself, since the card still shows space at query time before its completion update lands)
- QR validation error messages now route through the existing `ErrorMessageMapper` instead of showing raw technical strings like "Invalid signature: signature_mismatch" directly to the user
- Repeated error popups from a single scan attempt on the supplier redemption scanner while the camera was still being aimed - added the same scan-error cooldown the customer scanner already had

## [1.3.0+13] - 2026-07-26

**Status:** Built on `feature/uireview` (forked from `feature/SecurityReview`, not yet merged to `develop`/`main`), not yet built/uploaded as an IPA. Minor version bump (not patch) to keep this distinguishable from v1.1.0+12 in case of rollback.

### Fixed
- `RenderFlex` overflow on mini-FAB camera controls (Flip/90°/180°) across `qr_scanner_screen.dart`, `supplier_redeem_card.dart`, `supplier_stamp_card.dart`, `import_business_screen.dart`
- Business name/status text in the customer card list wrapping letter-by-letter at large accessibility text sizes when squeezed by a fixed-size badge - added `maxLines`/ellipsis
- Several full-width button labels (e.g. "Recover from Backup", "Clone from Another Device", "Scan to Add Stamp") left-justifying their second line when wrapped instead of centering with the rest of the button
- Stamp-count numbers on the card detail progress grid were fixed-pixel-sized and could overflow their circles at large text scale - replaced collected-stamp numbers with a scale-safe checkmark icon

### Added
- `ScaleCapped` widget (`shared/lib/widgets/scale_capped.dart`) to cap ambient text scale on supplementary labels (FAB labels, chip text, REDEEMED/COMPLETE badges) that previously grew unboundedly at large accessibility text sizes, rather than wrapping or truncating
- Haptic feedback on QR scan success/failure across customer and supplier scan flows

### Changed
- Reworded the customer card-list filter chip from a dynamic "Hiding/Showing Redeemed Cards" label to a fixed "Show Redeemed" label using `FilterChip`'s built-in selected state
- Shortened several verbose instructional strings (e.g. "Show this QR code to redeem your card and get your reward" -> "Show this QR code to redeem your reward"; dropped "Token" from scan button labels)

## [1.1.0+12] - 2026-07-24

**Status:** Built on `feature/packageUpdate` (not yet merged to `develop`/`main`), not yet built/uploaded as an IPA. Minor version bump (not patch) deliberately used to keep this build distinguishable from v1.0.3+11, which is currently submitted for App Store review - if review requires a revert, v1.0.3+11 remains a clean, separately-versioned target.

### Changed
- Dependency maintenance pass across `shared`, `customer_app`, `supplier_app` - see `docs/project-management/PACKAGE_UPDATE_PLAN.md` for full detail
- Removed 7 unused direct dependencies that had no matching import anywhere in the codebase: `path_provider`, `intl`, `pointycastle`, `google_fonts`, `cupertino_icons` (customer_app); `google_fonts`, `cupertino_icons` (supplier_app)
- Minor/patch version bumps across all three packages (sqflite, uuid, mobile_scanner, local_auth, flutter_secure_storage, pdf, printing, etc.)
- `share_plus` 12.0.2 -> 13.3.0 (supplier_app) - reviewed the full changelog across the range; only breaking change was a minimum SDK/platform floor already met by this project, no API changes required
- Flutter SDK 3.44.1 -> 3.44.8, Dart 3.12.1 -> 3.12.2 (local toolchain, not a repo file change)

### Fixed
- `stamp_signer_test.dart` had a broken `setUp()` written as a bare function declaration instead of a registered callback - it never actually ran, so test state was never reset between tests
- Two dead null-aware fallbacks (`business.privateKey ?? ''`) removed after confirming the field is non-nullable
- Two unreachable `switch` `default` clauses removed (enum switches were already exhaustive)
- 13 genuine `BuildContext`-used-after-`await`-with-no-`mounted`-check gaps fixed in `recovery_backup_screen.dart` (backup/recovery QR generation, print, email, save-to-files) and `supplier_redeem_card.dart` (device-mismatch confirmation) - these could have thrown "setState() called after dispose()" style errors if a user navigated away mid-operation

### Added
- Direct unit test coverage for `CryptoUtils.verifySignature` (`shared/test/utils/crypto_utils_test.dart`, 9 tests) - the ECDSA P-256/SHA-256 signature verification declared to Apple in the App Review export compliance packet previously had no dedicated test coverage

---

## [1.0.3+11] - 2026-07-21

**Note:** this changelog was not kept up to date between v0.3.0+1 and v1.0.3+11 - every release in between (v1.0.0, v1.0.1+7, v1.0.2+8/9, v1.0.3+10) shipped without an entry here. Not backfilled retroactively; picking up from this release forward. See `docs/deployment/RELEASES.md` and git history for what actually happened in that gap.

**Status:** Built from `develop`, not yet built/uploaded as an IPA. v1.0.3+10 (previous build) was uploaded to TestFlight and confirmed running on physical hardware.

### Changed
- Supplier onboarding: Express vs Secure Mode selection now shows each mode's `recommendedFor` guidance directly (e.g. "Recommended for coffee shops, restaurants, and low-value rewards with fast checkout") instead of a shorter, vaguer description - no longer requires tapping the info icon to get useful guidance
- Added a persistent, always-visible warning below the mode selector: switching modes later requires a full business reset, which invalidates every card current customers hold. Previously this was only mentioned in the docs, not surfaced in the app itself at the decision point. The warning now also points to the info icon and the User Guide for more detail.
- Expanded the tap-to-reveal info tooltip from a two-line summary to a fuller side-by-side comparison covering speed, equipment needed, fraud-protection mechanism, and recommended use case for each mode
- File: `supplier_app/lib/screens/supplier/supplier_onboarding.dart`

### Fixed
- Both apps' `Info.plist` now declare `ITSAppUsesNonExemptEncryption = false`, so App Store Connect/Transporter self-declare export compliance correctly instead of prompting for a manual answer (which was answered incorrectly as "No encryption" on the first v1.0.2+8 upload)
- All 74 app icon files (both apps) had their alpha channel flattened - Apple rejects a transparent large App Store icon
- `_enableDeleteInRelease`/`_enableResetInRelease` feature flags (customer and supplier Settings screens) now correctly default to `false`, so the "Delete All Data"/"Reset Business Configuration" buttons are hidden in release builds as originally intended

### Documentation
- Published Privacy Policy, Terms of Service, Accessibility Statement, Support page, User Guide, and Supplier Setup Guide to a public GitHub Pages site (`site/`) - previously the only public presence was an accidental full-repo exposure via Jekyll's default rendering, which has been closed
- Corrected several stale claims found while reviewing docs for publication: removed a "Save to Photos" backup reference (that flow was removed in v0.3.1), corrected a "1-hour" customer rate limit claim to the actual configurable 5-60 second cooldown (30s default), corrected QR/token expiry claims, renamed "Simple Mode" references to "Express Mode" to match the app's actual display name, and softened oversold "audit trail"/"analytics dashboard" claims to match what's actually shown to users
- Terms of Service strengthened: explicit disclaimers for user input errors and falsified app data, and an explicit statement that suppliers - not LoyaltyCards - are responsible for verifying presented card/stamp data before issuing rewards (same standard as a paper loyalty card)

---

## [0.3.0+1] - 2026-04-21

**Status:** ✅ Production - Deployed to TestFlight  
**Release Branch:** releases/v0.3.0-build01

### 🔒 CRITICAL Security Fixes

#### Fixed
- **SEC-001: Hardcoded HMAC Key Vulnerability** - CRITICAL
  - Replaced hardcoded HMAC key with HKDF key derivation from business private key
  - Each business now has unique HMAC key derived cryptographically
  - Prevents forgery of backup QR codes
  - File: `shared/lib/models/supplier_config_backup.dart`

- **SEC-002: Timing Attack Vulnerability** - HIGH
  - Implemented constant-time comparison for signature verification
  - XOR-based byte comparison prevents timing-based signature guessing
  - Protects against side-channel attacks
  - File: `shared/lib/models/supplier_config_backup.dart`

- **ERROR-001: Missing Error Handling** - CRITICAL
  - Added comprehensive error handling to TransactionRepository (all 11 methods)
  - Prevents app crashes on database errors
  - User-friendly error messages via TransactionException.getUserMessage()
  - File: `customer_app/lib/services/transaction_repository.dart`

### 📦 Package Updates

#### Updated
- `device_info_plus`: 11.5.0 → 13.1.0 (fixes Xcode 64-to-32 bit warnings)
- `local_auth`: 2.3.0 → 3.0.1 (breaking API changes handled)
- `share_plus`: 10.1.4 → 12.0.2 (enhanced sharing capabilities)
- `win32`: 5.15.0 → 6.0.1 (Windows compatibility)

#### Breaking Changes Handled
- `local_auth` 3.0.1: Removed `AuthenticationOptions` parameter, simplified authenticate() calls
- Updated both customer and supplier apps for API compatibility

### 🐛 Bug Fixes

#### Fixed
- **Multi-Stamp Token Generation Bug** - CRITICAL (Simple Mode)
  - QR codes now regenerate in real-time when slider or expiry changes
  - Prevents customers scanning outdated tokens
  - File: `supplier_app/lib/screens/supplier/supplier_stamp_card.dart`

- **Text Contrast Issue** - HIGH (Accessibility)
  - "Card Created" title in stamp history now readable on light blue background
  - Added `color: BrandColors.textPrimary` to title text
  - File: `customer_app/lib/screens/customer/customer_card_detail.dart`

### ✨ Features & Improvements

#### Added
- **QR Token Generator Error Handling** - HIGH
  - QRGenerationException with comprehensive error handling
  - All QR generation paths now properly handle failures
  - File: `customer_app/lib/services/qr_token_generator.dart`

- **Biometric Auth Structured Results** - HIGH
  - BiometricAuthResult with 6 specific status types
  - Eliminates silent failures in authentication flows
  - Files: `customer_app/lib/services/biometric_auth_service.dart`, `supplier_app/lib/services/biometric_auth_service.dart`

- **User-Friendly Error Messages** - HIGH
  - ErrorMessageMapper utility for translating technical errors
  - Consistent error presentation across both apps
  - File: `shared/lib/utils/error_handler.dart`

- **SharedPreferences Error Handling** - HIGH
  - Try-catch wrapping with UI state revert on failure
  - Prevents silent data loss
  - File: `customer_app/lib/screens/customer/customer_settings.dart`

#### Changed
- **UX Streamlining** - Removed "Save to Photos" option from backup workflows
  - Simplified to 3 options: Print, Share via Email, Save to Files
  - Reduces user confusion and maintenance burden
  - File: `supplier_app/lib/screens/supplier/recovery_backup_screen.dart`

- **Smart Routing Documentation** - Added comprehensive inline documentation
  - Explains auto-routing to correct business card
  - Documents auto-new-card creation on completion (not just overflow)
  - File: `customer_app/lib/screens/customer/qr_scanner_screen.dart`

### ✅ Testing

#### Added
- **TEST-001: BackupStorageService Tests** - 16 comprehensive tests
  - HKDF key derivation validation
  - Constant-time comparison verification
  - QR generation edge cases
  - File: `shared/test/services/backup_storage_service_test.dart`

- **TEST-002: Database Timeout Tests** - 17 comprehensive tests
  - 10-second timeout verification
  - Recovery mechanism validation
  - Both customer and supplier app coverage
  - Files: `customer_app/test/services/database_timeout_test.dart`, `supplier_app/test/services/database_timeout_test.dart`

#### Updated
- **Test Suite Expansion**: 165 → 264 tests (99 new tests added)
  - Customer App: 70 → 87 tests
  - Supplier App: 30 → 46 tests
  - Shared Package: 115 → 131 tests
- **Test Success Rate**: 100% (264/264 passing)

### 📚 Documentation

#### Added
- `EXPERT_CODE_REVIEW_PRODUCTION_READINESS.md` - Comprehensive production readiness assessment
- `EXPERT_ARCHITECTURAL_REVIEW.md` - Architecture review report
- `DOCUMENTATION_INDEX.md` - Master index of all project documentation
- `DOCUMENTATION_CLEANUP_SUMMARY.md` - Documentation consolidation record
- `LESSONS_LEARNED.md` - AI-driven development insights

#### Updated
- Major documentation reorganization into 8 logical categories
- 56 files moved from flat structure to organized folders
- All paths updated and cross-references maintained

#### Removed
- 12 outdated/duplicate documents consolidated

### 🗄️ Database

#### No Changes
- Customer App Database: v7 (stable)
- Supplier App Database: v5 (stable)

### 🔧 Technical Debt Addressed

- Removed obsolete `loyalty_cards_prototype` folder
- Suppressed Xcode warning for device_info_plus (64-to-32 bit conversion)
- Code review findings fully addressed (all CRITICAL and HIGH priority issues)

---

## [0.2.1+23] - 2026-04-18

**Status:** ✅ TestFlight Testing (Internal)  
**Note:** Version number remained 0.2.1+23 during bug fixes before incrementing to 0.3.0+1

### 🐛 Bug Fixes

#### Fixed
- Various minor bug fixes during pre-release testing
- UI/UX refinements based on internal feedback
- Stability improvements

---

## [0.2.0+21] - 2026-04-18

**Status:** 🚧 In Development (feature/security-vulnerability-fixes → develop)

### 🔒 Security Enhancements

#### Added
- **V-002: Private Key Protection** - Biometric authentication now required for sensitive operations
  - Recovery backup QR display requires Face ID/Touch ID/Passcode authentication
  - Device clone QR display requires Face ID/Touch ID/Passcode authentication
  - New `BiometricAuthService` for unified authentication across supplier app
  - Added `local_auth` ^2.3.0 dependency for biometric authentication
  - Info.plist entries for Face ID usage descriptions in both apps

- **V-005: Multi-Device Duplication Detection** - Prevent card duplication across devices
  - Device ID tracking via `device_info_plus` ^11.5.0
  - Device ID captured during card issuance and stamping
  - Mismatch detection warns users when scanning cards from different devices
  - User-friendly warning dialog explains device binding
  - Database migration v5 → v6 adds `device_id` columns to cards and stamps tables

#### Changed
- Customer App now has optional Face ID lock feature for added privacy
- Supplier App requires authentication to access private cryptographic keys

#### Database Changes
- **Customer App Database:** v5 → v6
  - Added `device_id TEXT` column to `cards` table
  - Added `device_id TEXT` column to `stamps` table
- **Supplier App Database:** v4 (no changes this build)

#### Documentation
- Created VULNERABILITIES.md - Comprehensive security assessment
- Created TERMS_OF_SERVICE.md - Legal requirements for App Store
- Updated USER_GUIDE.md with biometric authentication instructions
- Updated BUILD_21_TESTING_GUIDE.md with security test scenarios

---

## [0.2.0+20] - 2026-04-17

### 🔒 Security
- Implemented V-002: Biometric authentication for private key access
- Added Face ID/Touch ID protection for recovery backup and device cloning

### 🐛 Bug Fixes
- **TEST-010: Redemption UI Below Fold** - Critical UX fix
  - Implemented Floating Action Button for "Scan Confirmation" - always visible
  - Compact QR layout saves ~35px vertical space
  - Smart collapse of stamp display saves ~100-120px
  - Removed duplicate stamp count text saves ~28-32px
  - Total vertical space recovered: ~163-187px
  - Resolves scrolling issues on smaller iPhone screens

---

## [0.2.0+18] - 2026-04-16

### 🐛 Bug Fixes
- **TEST-012: Camera Rotation** - Fixed camera orientation issues
  - Corrected rotation calculations in QR scanner
  - Improved camera flip functionality
  - Better handling of device orientation changes

---

## [0.2.0+17] - 2026-04-16

### 🐛 Bug Fixes
- Fixed 2 CRITICAL defects + 1 bonus enhancement
- Improved QR scanning reliability
- Enhanced stamp validation logic

---

## [0.2.0+16] - 2026-04-16

### 🐛 Bug Fixes
- Fixed 4 navigation and UI defects
- Improved user flow consistency

---

## [0.2.0+15] - 2026-04-16

**Status:** ✅ TestFlight Internal Testing

### 🚀 Features
- First TestFlight deployment for internal pilot testing
- Regression testing validation complete
- Core features stable for initial user feedback

---

## [0.2.0+4] - 2026-04-14

**Status:** ✅ TestFlight Pilot Deployment

### 🎨 Features
- Custom app icons for personalized branding
- Dual operation modes (Simple & Secure)
- Multi-device supplier support (backup & clone)
- QR-based stamp issuance and redemption
- Privacy-first P2P architecture

### 🏗️ Infrastructure
- SQLite local database
- Cryptographic signature validation (ECDSA P-256)
- Offline-capable operation
- iOS Keychain secure storage

---

## [0.1.0+46] - 2026-04-13 and Earlier

### 🛠️ Development Phase
- Initial prototype development
- Core architecture implementation
- Database schema design
- Security model implementation
- Customer and Supplier app foundations

---

## Categories Reference

- **Added** - New features
- **Changed** - Changes to existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security-related changes

---

## Version History Quick Reference

| Version | Date | Status | Key Focus |
|---------|------|--------|-----------|
| 0.3.0+1 | 2026-04-21 | ✅ Production | Security fixes, package updates, 264 tests |
| 0.2.1+23 | 2026-04-18 | ✅ TestFlight | Bug fixes and refinements |
| 0.2.0+21 | 2026-04-18 | 🚧 Development | Security enhancements (V-002, V-005) |
| 0.2.0+20 | 2026-04-17 | ✅ Complete | Private key protection, UI fixes |
| 0.2.0+18 | 2026-04-16 | ✅ Complete | Camera rotation fixes |
| 0.2.0+17 | 2026-04-16 | ✅ Complete | Critical defect fixes |
| 0.2.0+16 | 2026-04-16 | ✅ Complete | Navigation fixes |
| 0.2.0+15 | 2026-04-16 | ✅ TestFlight | Internal pilot testing |
| 0.2.0+4 | 2026-04-14 | ✅ TestFlight | Initial pilot deployment |
| 0.1.0+46 | 2026-04-13 | ✅ Complete | Development phase |

---

**Maintained by:** Development Team  
**Last Updated:** April 22, 2026
