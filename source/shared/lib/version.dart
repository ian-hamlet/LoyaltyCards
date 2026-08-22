/// Shared app version information for both Customer and Supplier apps
/// 
/// Update this version string each time you make changes to verify
/// that the new code has been deployed to the device.
/// 
/// Format: v{major}.{minor}.{patch} (Build {build})
/// Example: v1.0.0 (Build 1)
///
/// Version 0.2.0 - Pilot Testing Release
/// 
/// Ready for TestFlight deployment and initial pilot testing.
/// 
/// Key Features:
/// - Dual operation modes (Simple & Secure)
/// - P2P architecture with cryptographic security
/// - QR-based stamp issuance and redemption
/// - Multi-device supplier support (backup & clone)
/// - Privacy-first design (zero data collection)
/// - Custom branded app icons
/// - Offline-capable with local storage
/// 
/// Build 9 Changes:
/// - Fix customer QR scanner rotation buttons (TEST-004)
/// - Add camera flip button to all QR scanners
/// - Fix rotation calculation to use _manualRotationOffset variable
/// - Add flip camera (front/back switch) functionality
/// - Apply fixes to customer_app/qr_scanner_screen.dart
/// - Apply fixes to supplier_app/import_business_screen.dart
/// - Add camera controls to supplier_stamp_card.dart and supplier_redeem_card.dart
/// 
/// Build 10 Changes:
/// - Fix supplier backup/export functionality (TEST-002)
/// - Save to File and Save to Photos buttons now working
/// - File share sheet and photo library save implemented
/// - Added Future.any() timeout workaround for ImageGallerySaver iOS hang
/// 
/// Build 11 Changes:
/// - Fix duplicate empty card creation on redemption (TEST-005)
/// - Added findCardWithSpace() helper to CardRepository
/// - Check for existing non-redeemed cards before creating new card
/// - Prioritize cards with most stamps when multiple available
/// - Apply fix to both Simple and Secure Mode redemptions
/// 
/// Build 12 Changes:
/// - Add filter to hide/show redeemed cards in wallet (TEST-006)
/// - FilterChip UI control next to search bar
/// - Default: hide redeemed cards for cleaner wallet view
/// - Preference persisted using SharedPreferences
/// - Filter works alongside search functionality
/// 
/// Build 13 Changes:
/// - Standardize error handling patterns across codebase (CR-014)
/// - Added error_handling.dart utility with safeExecute helpers
/// - Documented error handling conventions for each pattern:
///   * Future<bool> for optional/graceful operations (backup, etc)
///   * Future<void> + exceptions for critical operations (database)
///   * bool for synchronous validation (QR parsing, signatures)
/// - Added comprehensive documentation to key service files
/// - No breaking changes - documentation and utilities only
/// 
/// Build 14 Changes:
/// - Code review fixes from comprehensive best practice analysis
/// - Fixed string substring operations to handle short strings safely
/// - Commented out dead code methods (canIssueStamp, recordStampIssued)
///   in rate_limiter.dart that referenced non-existent stamp_log table
/// - Added length checks before substring(0, 20) in all logging statements
/// - Prevents potential RangeError with malformed QR signatures
/// - Minor bug fixes - no functional changes to working features
/// 
/// Build 15 Changes:
/// - Fix overflow stamps creating duplicate cards (TEST-008)
/// - Apply findCardWithSpace() logic to overflow handling
/// - Check for existing non-redeemed cards before creating new overflow card
/// - Recursive overflow: fill existing cards in cascade before creating new
/// - Example: Card A (8/10) + Card B (2/10) + 5 stamps = Card A complete,
///   Card B gets 3 stamps (total 5/10), NO duplicate Card C created
/// - Comprehensive logging for overflow cascade debugging
/// - Matches redemption logic from Build 11 (TEST-005)
/// - Fix redemption success message to only show "New card added" when
///   a new card was actually created (conditional message display)
/// 
/// Build 16 Changes:
/// - DECISION-016: Conditional compilation for dangerous delete operations
/// - Wrapped "Delete All Data" sections in kDebugMode checks
/// - Dangerous operations only visible in debug/TestFlight builds
/// - Hidden in production App Store releases for user safety
/// - TEST-013: Fixed statistics info text line breaks
/// - Changed \\n to \n in supplier_home.dart statistics banner
/// - Text now displays on three separate lines correctly
/// - TEST-009: Implemented complete transaction logging system
/// - Fixed broken "Transactions" counter (was always 0)
/// - Added transaction logging for all key events (pickup, stamp, redemption)
/// - Reorganized Settings into "Your Wallet" and "Activity History" sections
/// - New wallet counter: Ready to Redeem (complete cards awaiting redemption)
/// - New activity counters: Cards Added, Stamps Earned, Rewards Redeemed
/// - All counters now show real-time meaningful data with descriptive subtitles
/// - TEST-011: Fixed redeemed card filter label confusion
/// - Changed filter label to be dynamic (shows action, not state)
/// - Label now reads "Show Redeemed" when hiding, "Hide Redeemed" when showing
/// 
/// Build 17 Changes:
/// - TEST-014: Fixed business import navigation allowing duplicate creation
/// - Changed navigation from pushReplacement to pushAndRemoveUntil
/// - Clears entire navigation stack after successful import/creation
/// - Prevents back button from returning to onboarding screen
/// - Blocks duplicate business creation after import completes
/// - Applied to both import_business_screen and supplier_onboarding
/// - TEST-015: Fixed camera infinite loop after import errors
/// - Added camera stop() calls after successful import
/// - Added camera stop() calls after import errors
/// - Pre-flight check prevents scanning when business already exists
/// - Clear error messages with "Go Back" button when blocked
/// - Camera cleanup prevents infinite scan/reject loops
/// - Bonus: Fixed memory leak in clone_device_screen.dart
/// - Added mounted checks before all setState() calls in timer callbacks
/// - Added mounted checks in async completion handlers
/// - Prevents "setState() called after dispose()" errors
/// - Proper timer cancellation and async operation cleanup
/// 
/// Build 18 Changes:
/// - TEST-012: Implemented camera rotation persistence across sessions
/// - Added SharedPreferences to save user's preferred camera rotation
/// - Rotation preference loaded automatically on camera screen init
/// - User's last rotation choice becomes their default for future sessions
/// - Single shared preference key 'camera_rotation' used by ALL cameras
/// - When user rotates ANY camera, that rotation applies to ALL cameras
/// - Last rotation done to any camera becomes the default for all cameras
/// - Consistent rotation experience across both apps and all scan contexts
/// - Applied to all 4 QR scanner screens:
///   * customer_app/qr_scanner_screen.dart
///   * supplier_app/import_business_screen.dart
///   * supplier_app/supplier_stamp_card.dart
///   * supplier_app/supplier_redeem_card.dart
/// - User only needs to set rotation once per app context
/// - Eliminates repetitive manual rotation on every scan session
/// - SharedPreferences added to supplier_app dependencies
/// - UX Improvement: Removed version number from app title bars
///   * Customer app: "My Loyalty Cards" (was "My Loyalty Cards v0.2.0+18")
///   * Supplier app: "Customer Loyalty Cards" (was "{Business Name} v0.2.0+18")
///   * Version still visible in Settings screens
///   * Cleaner, less cluttered UI
/// - UX Improvement: Supplier app title now "Customer Loyalty Cards"
///   * More descriptive of app purpose
///   * Business name already prominent on dashboard
///   * Consistent with professional business app design
/// 
/// Build 19 Changes:
/// - UX Improvements: Vertical status bars for card states
///   * Added vertical "COMPLETE" and "REDEEMED" bars to stamp counting card
///   * Integrated inside card with proper padding (32px vertical, 12px text)
///   * Rounded corners (8px) for professional appearance
///   * Consistent styling prevents future color change complexity
///   * Saves ~40-50px vertical space (removed horizontal lozenges)
/// - Added countdown timers to all time-limited QR codes in supplier app
///   * supplier_issue_card.dart: 5-minute countdown for card issuance QR
///   * supplier_stamp_card.dart: 2-minute countdown for stamp QR
///   * Consistent "Expires in: MM:SS" format across all screens
///   * Red color warning when time running low
/// - Clarified redemption instructions in customer app
///   * Updated: "Show this QR code to get your confirmation code and redeem your reward"
///   * Makes confirmation code step explicit in the process
/// - Fixed contextual instruction display for redeemed cards
///   * Instructions hidden when card already redeemed
///   * Prevents confusing "redeem your reward" on already-redeemed cards
/// - Applied vertical bar to customer QR display redemption screen
///   * Green "COMPLETE" bar on left during redemption flow
///   * Consistent visual language across all card state displays
/// 
/// Build 20 Changes:
/// - TEST-010 Redemption UI Improvements (Secure Mode)
///   * Floating Action Button: "Scan Confirmation" always visible (no scrolling)
///   * Compact QR layout: Reduced padding (16→8px) and size (95%) saves ~70px vertical space
///   * Smart collapse: Complete/Redeemed cards show compact stamp display instead of full grid
///   * Saves ~120-140px total vertical space on redemption screens
///   * Ensures "Scan Redemption Token" button visible on all iPhone sizes
///   * Better UX: Clear next step always visible, no hidden UI below fold
/// 
/// Build 21 Changes:
/// - V-002 Security Enhancement: Private Key Protection
///   * Added biometric authentication (Face ID/Touch ID/Passcode) requirement
///   * Recovery backup QR generation now requires authentication
///   * Clone device QR generation now requires authentication
///   * Prevents unauthorized access to private keys if device left unlocked
///   * Added BiometricAuthService for unified authentication handling
///   * Added local_auth package dependency
/// - Documentation: Created SECURITY_MODEL.md
///   * Clarifies Simple Mode is trust-based by design (V-001)
///   * Documents intentional security model and mitigations
///   * Explains dual-mode architecture and use cases
///   * Provides mode selection guidance for businesses
/// 
/// Build 22 Changes:
/// - Internal Quality Improvements (No user-facing changes)
///   * Added comprehensive testing infrastructure (165 automated tests)
///   * Shared package: 115 tests (models, QR tokens, utilities)
///   * Customer app: 33 tests (services, validation, rate limiting)
///   * Supplier app: 17 tests (cryptographic operations - 95%+ coverage)
///   * Created TESTING_STRATEGY.md documentation
///   * Code cleanup: Removed unused code and debug logging
///   * Updated all project documentation to v0.2.1
/// 
/// Build 23 Changes:
/// - TestFlight Feature Flags (Requested by tester feedback)
///   * Re-enabled "Danger Zone" buttons in TestFlight builds
///   * Customer: Delete All Data button now visible (was kDebugMode only)
///   * Supplier: Reset Business Configuration now visible (was kDebugMode only)
///   * Added feature flags: _enableDeleteInRelease and _enableResetInRelease
///   * Both flags set to true for TestFlight testing phase
///   * Before App Store release: Set both flags to false to hide in production
///   * Allows testers to reset/delete data during TestFlight testing
/// - Note: Build 22 tests not included in this release (shared package untested)
/// 
/// Version 0.3.0 - REQ-022: Enhanced Simple Mode
/// 
/// Build 1 Changes:
/// - REQ-022: Enhanced Simple Mode - Multi-Denomination Stamps
///   * Flexible Denominations: Any value from 1 to stampsRequired per token
///   * Token Generation UI: Denomination selector (slider + buttons)
///   * Expiry Policies: None, Daily, Weekly, or Custom date options
///   * Supplier-Specific Scan Intervals: Configurable 5-60 seconds
///   * Annotated QR Images: Business name, stamp count, expiry date labels
///   * Multi-Stamp Processing: Single scan awards multiple stamps
///   * Distribution Methods: Save to Photos, Print, Email, Save to Files
///   * Token Validation: Rejects expired tokens and invalid stamp counts
///   * Dynamic Rate Limiting: Per-supplier intervals applied from token
///   * Backward Compatible: Old single-stamp tokens continue to work
/// - Database: Supplier DB upgraded to v5 (scan_interval_seconds column)
/// - Models: StampToken with stampCount, expiryDate, scanInterval fields
/// - Test Coverage: 180 unit tests passing (131 shared + 49 customer)
/// - Files Modified: 12 files across shared/supplier/customer packages
/// - Documentation: REQ-022_IMPLEMENTATION_SUMMARY.md created
/// - Status: Code complete, ready for device testing

/// IMPORTANT: Version Number Management
/// =====================================
/// # always keep the 3 pubspec.yaml files and the version .dart file in sync with the same version number


/// Version 1.1.0 - Package Update Pass
///
/// Build 12 Changes:
/// - Dependency maintenance on feature/packageUpdate (not yet merged to develop/main):
///   * Removed 7 unused direct dependencies (path_provider, intl, pointycastle,
///     google_fonts, cupertino_icons across customer_app/supplier_app)
///   * Minor/patch bumps across shared/customer_app/supplier_app
///   * share_plus 12.0.2 -> 13.3.0 (supplier_app), no API changes required
///   * Flutter SDK 3.44.1 -> 3.44.8, Dart 3.12.1 -> 3.12.2
///   * Fixed 13 missing `mounted` guards in recovery_backup_screen.dart /
///     supplier_redeem_card.dart (real BuildContext-after-await gaps)
///   * Added direct test coverage for CryptoUtils.verifySignature (previously untested)
/// - Minor version bump (not a patch) to keep this distinguishable from the
///   1.0.3+11 build submitted for App Store review, in case of rollback
/// - Test Coverage: shared 140, customer_app 87, supplier_app 46 - all passing

/// Version 1.3.0 - Dynamic Type / Layout Overflow Fixes
///
/// Build 13 Changes:
/// - Fix RenderFlex overflow on mini-FAB camera controls (Flip/90°/180°)
///   across qr_scanner_screen.dart, supplier_redeem_card.dart,
///   supplier_stamp_card.dart, import_business_screen.dart
/// - Add ScaleCapped widget (shared/lib/widgets/scale_capped.dart) to cap
///   ambient text scale on supplementary labels (FAB labels, chip text,
///   REDEEMED/COMPLETE badges) that previously grew unboundedly at large
///   accessibility text sizes
/// - Replace fixed-pixel stamp-count numbers with a scale-safe checkmark
///   icon on collected stamps
/// - Add maxLines/ellipsis to customer card-list business name and status
///   text to stop letter-by-letter wrap when squeezed by a badge at large
///   text sizes
/// - Center button labels when they wrap to multiple lines (several
///   full-width buttons across both apps)
/// - Reword "Show Redeemed" chip and shorten several instructional strings
/// - Add haptic feedback on QR scan success/failure
/// - Test Coverage: shared 152, customer_app 124, supplier_app 66 - all passing

/// Version 1.4.0 - Secure Mode Redemption Integrity Fixes
///
/// Build 14 Changes:
/// - Fix Secure Mode redemption always failing for a card that ever
///   received an overflow-split stamp from another card completing -
///   the moved stamp's signature covered its original position, not its
///   new one, so redemption verification always rejected it
/// - Add original_card_id/original_stamp_number/original_previous_hash
///   columns (DB v7->v8 migration) recording a moved stamp's true
///   signing context, populated only by internal move logic
/// - Fix Secure Mode multi-stamp grants ("additional stamps") signed with
///   a shorter, non-canonical string that always failed redemption
///   verification even though accepted fine when first scanned
/// - Fix a card being auto-completed overwriting its own just-applied
///   completed stamp count back to its stale pre-scan value when no
///   other card genuinely had space (findCardWithSpace matched itself)
/// - Route QR validation error messages through the existing
///   ErrorMessageMapper instead of showing raw technical strings
/// - Add scan-error cooldown to the supplier redemption scanner to stop
///   repeated error popups from one scan attempt while aiming the camera
/// - Test Coverage: shared 156, customer_app 124, supplier_app 66 - all passing

/// Version 1.5.0 - Further Dynamic Type / Layout Overflow Fixes
///
/// Build 15 Changes:
/// - Fix RenderFlex/overlap overflow found across supplier screens at
///   large-but-not-max accessibility text sizes: "Quick Start Stamps" /
///   "Reusable QR (no expiry)" text (supplier_issue_card.dart), stepper
///   counters between +/- buttons (supplier_issue_card.dart,
///   supplier_onboarding.dart, supplier_stamp_card.dart), REDEEMED/COMPLETE
///   badges in narrow rotated bars (customer_card_detail.dart,
///   qr_display_screen.dart), Issued/Stamped/Redeemed stat columns
///   clipping the rightmost counter (supplier_home.dart)
/// - Upgrade mini-FAB camera control labels (Flip/90°/180°) from a smaller
///   base font to ScaleCapped, since the smaller font alone still
///   overflowed at large-but-not-max scale (all 4 files)
/// - Apply ScaleCapped to numbered-circle widgets that don't scale with
///   their fixed-size container (how_it_works.dart in both apps,
///   supplier_home.dart, clone_device_screen.dart)
/// - Fix import_business_screen.dart: "Confirm Business Restore" dialog
///   now scrolls instead of clipping its bottom paragraph; blue
///   instructional banner over the scanner is scale-capped so it can't
///   grow tall enough to cover the scan target
/// - Wrap 3 AlertDialog titles (import_business_screen.dart,
///   recovery_backup_screen.dart, supplier_redeem_card.dart) so they wrap
///   instead of overflowing the dialog's narrower width
/// - Fix clone_device_screen.dart "Expires in: ..." info box overflow
/// - Rename "Token Configuration" to "Stamp Setup" on the supplier stamp
///   issuance screen
/// - Test Coverage: shared 156, customer_app 124, supplier_app 66 - all passing

/// Version 1.6.0 - Supplier App-Wide Lock, Card-List Alignment Fixes
///
/// Build 16 Changes:
/// - Fix customer app: AppLockWrapper's app-lock preference was only
///   refreshed at cold launch or while already locked - toggling app lock
///   ON in Settings mid-session (while already authenticated) never
///   re-locked on the next background/foreground until the app was fully
///   killed and relaunched. Now re-reads the preference fresh on every
///   background.
/// - Add the same optional app-wide biometric lock to the supplier app
///   (previously it only gated individual actions like viewing backup/
///   clone QR codes, with no app-wide lock option at all) - new
///   AppLockWrapper in main.dart, new Security section in
///   supplier_settings.dart, same fresh-read-on-background fix applied
///   from the start
/// - Fix customer_card_detail.dart: "N of N stamps" badge (shown once a
///   card is complete/redeemed) overflowing at large-but-not-max
///   accessibility text sizes
/// - Fix supplier_home.dart: Issued/Stamped/Redeemed stat labels wrapping
///   mid-word ("Stamp/ed", "Redee/med") at large text sizes, throwing the
///   numbers above them out of alignment since the columns became
///   different heights: labels now scale-capped, which keeps them
///   single-line and the columns equal height
/// - Fix supplier_home.dart: dropped the redundant period after step
///   numbers in the info panel ("1." -> "1"), and scale-capped the
///   title/description text so it stays proportional to the fixed-size
///   number circle beside it at large text sizes
/// - Test Coverage: shared 156, customer_app 124, supplier_app 66 - all passing

/// Build 17 Changes:
/// - Require device authentication (Face ID/Touch ID/passcode) before an
///   import_business_screen.dart restore actually commits - previously
///   only a tap-through confirmation dialog stood between an idle,
///   unconfigured device and having a scanned backup/clone QR silently
///   installed as its business identity. Covers both the recovery-backup
///   and clone-QR flows, since they share the same import code path.
/// - Test Coverage: shared 156, customer_app 124, supplier_app 66 - all passing

/// Version 2.0.0 - QR Token Format Break
///
/// Build 18 Changes:
/// - Major version bump (not minor/patch): the QR token payload gained
///   new signed fields during the security review (stampCount,
///   expiryDate, scanInterval, device-mismatch tracking, etc.) between
///   this branch and the last main-branch release. Old "add card" and
///   "add stamp" QR codes printed from a pre-review build still parse
///   (fields are additive and default-safe) but now fail signature
///   verification, since the signed data those defaults are checked
///   against has changed - confirmed by device testing. There's no
///   version marker in the token to distinguish "old format, expected
///   to fail" from "corrupted/tampered", so this is called out as a
///   deliberate major-version line rather than folded into another
///   minor bump. Existing printed QR codes will need reprinting after
///   this ships.
/// - Test Coverage: shared 156, customer_app 124, supplier_app 66 - all passing

/// Build 19 Changes:
/// - Fix Express Mode "add card" QR rejecting a repeat customer entirely:
///   once a card was redeemed, re-scanning the same static QR to start a
///   new loyalty cycle was blocked forever ("Card has already been
///   scanned"), since the dedup check didn't distinguish an active card
///   from a redeemed one. Now only blocks re-scanning while the existing
///   card is still active.
/// - If that QR also grants initial/welcome stamps, those signatures are
///   bound to the QR's fixed cardId, not the new card's fresh id on a
///   repeat cycle - now correctly carried over using the same
///   originalCardId/originalStampNumber/originalPreviousHash mechanism
///   built for overflow-moved stamps, rather than being dropped.
/// - Closed a critical redemption-inflation gap in Secure Mode chain
///   verification (duplicate/replayed proof signatures, and an unused
///   proof-count check), and a third instance of the additional-stamp
///   signing-format bug (this time for initial stamps) - both found via a
///   multi-role security/fraud/UI/code-quality review pass.
/// - Fixed 2 more Dynamic Type overflow spots the earlier sweep missed,
///   removed an accessibility-harming ScaleCapped misapplication on
///   primary instructional text, and added real v7->v8 DB migration test
///   coverage.
/// - Delete-card confirmation now warns explicitly when the card has
///   stamps collected or is complete and ready to redeem, instead of a
///   generic message regardless of what's actually at stake.
/// - Test Coverage: shared 158, customer_app 125, supplier_app 66 - all passing

/// Build 20 Changes:
/// - CRASH-001: fixed a native EXC_BAD_ACCESS crash printing the Stamp
///   Setup QR code (supplier app), reported by Apple App Review on iPad
///   Air 11" (M3). Root cause: the Print button had no re-entrancy guard,
///   so a fast double-tap could fire two concurrent Printing.layoutPdf()
///   calls and race the native plugin's print-job setup. Added a
///   busy-state guard (_isPrinting) to the confirmed crash site and 5
///   more instances of the identical unguarded-button gap found by
///   auditing every BackupStorageService print/share/save call site.
/// - CRASH-001 follow-up: added PDF-bytes validation ahead of every
///   Printing.layoutPdf() call, closing a second single-tap-reachable
///   path to the same crash (malformed/empty PDF bytes reaching native
///   code unchecked).
/// - UI-001: fixed unreadable text on How It Works info panels in dark
///   mode (both apps) - a fixed light-mode-only background paired with
///   theme-adaptive foreground text produced light-on-light text.
/// - Express Mode redemption copy (customer app) now explicitly frames
///   the exchange as a witnessed handshake between customer and supplier,
///   rather than reading as an implicit self-service action.
/// - Test Coverage: shared/customer/supplier suites all passing (78+
///   backup service tests including new print-guard regression tests)
///
/// Build 21 Changes:
/// - Raised IPHONEOS_DEPLOYMENT_TARGET from 13.0 to 15.0 in both apps
///   (project.pbxproj, plus the commented Podfile reference) - Transporter
///   flagged 13.0 as a warning during the 2.0.1+20 upload attempt; Apple
///   requires 15.0+ for all App Store Connect uploads starting Spring 2027.
///
/// Build 22 Changes (in progress):
/// - App Store Connect metadata corrections found post-launch: Category
///   (both apps are live under Food & Drink, target is Lifestyle/Shopping
///   for the customer app and Business/Productivity for the supplier app)
///   and Subtitle (customer app's was blank in ASC; both revised to lead
///   with each app's actual differentiator instead of generic description).
/// - Resolved the customer app name question: "LoyaltyCards Customer
///   Wallet" is correct (matches live ASC), not "LoyaltyCards - Digital
///   Stamps" as every doc previously said.
/// - Added each app's App Store URL directly into the other's description,
///   so a reader doesn't have to search for the companion app.
/// - Added a printable "Get the App" QR flyer for suppliers to display at
///   checkout (marketing/supplier_app/get-the-app-flyer.html, published
///   copy linked from the Supplier Setup Guide and site homepage). Uses
///   the official Apple "Download on the App Store" badge SVGs.
/// - Finalized APP_STORE_METADATA_PACKET_v2_0_3_22.md with the Category
///   and Subtitle corrections baked in as the real submission content.
///
/// Build 23 Changes:
/// - Added the Sharing feature planned for build 22: Settings gets a new
///   "Sharing" section in both apps (Tell a Business, Tell a Friend - QR
///   code + native share-sheet link), built as a reusable AppReferralScreen
///   widget in the shared package. Supplier app also gets a "Tell a Friend"
///   shortcut icon on the Home screen's app bar. Settings reordered in both
///   apps to group Sharing with the other identity-level sections.
/// - Fixed Express Mode stamps being routed to the newest card for a
///   business instead of an older card that already had progress and
///   room - the lookup used getAllCards().firstWhere(...), which always
///   returns the most recently created match; fixed to use the existing
///   CardRepository.findCardWithSpace() helper instead.
/// - Fixed CloneDeviceScreen and RecoveryBackupScreen briefly showing a
///   false "failed" state on open - their loading flag started false but
///   initState() kicks off async auth-then-generate work immediately, so
///   the first frame rendered before that flag caught up. Started both
///   true instead, matching the pattern already correct elsewhere.
/// - Metadata packet renamed APP_STORE_METADATA_PACKET_v2_0_3_23.md,
///   carrying forward the Category/Subtitle corrections from build 22 and
///   adding What's New text for the Sharing feature.
///
/// Build 24 Changes (version bumped 2.0.3 -> 2.0.4):
/// - Fixed TEST-016: CardIssueToken.isValid() rejected stampsRequired below
///   5, but the onboarding "Stamps Required" slider allows a minimum of 3.
///   Any business configured with 3 or 4 stamps could never issue a valid
///   card - the token always failed validation on scan, in both Secure and
///   Express Mode. Lowered the floor to 3 to match the slider. Build 23
///   (v2.0.3+23) is affected and live on the App Store; this build
///   supersedes it. Found while investigating macOS build feasibility for
///   the supplier app (unrelated, separate branch - the macOS work itself
///   is not part of this or any release).
///
/// Build 26 Changes (version bumped 2.0.4 -> 2.1.0 - minor, not a build-only
/// bump: raises the supported stampsRequired ceiling, a real capability
/// change, backward compatible - see TEST-020 below):
/// - Fixed TEST-017: a Secure Mode redemption QR bundles one signature per
///   stamp; at high stamp counts (or with overflow-relocated stamps, which
///   add extra fields each) the plain-JSON payload could exceed a QR
///   code's maximum encodable capacity, causing QrImageView to fail
///   silently (a blank grey panel, no error - release-build default
///   behavior for a widget that throws during build()). Interim fix
///   lowered the max stampsRequired from 20 to 10 and added a graceful
///   fallback UI; superseded by TEST-020 below.
/// - Fixed TEST-018: the overflow-splitting logic (moving a completed
///   card's leftover stamps onto another card) has three code paths that
///   each build the relocated stamp's record - one of the three omitted
///   `originalCardId`/`originalStampNumber`/`originalPreviousHash`
///   entirely, silently dropping the provenance needed to verify that
///   stamp's signature correctly at redemption. Fixed by adding
///   `Stamp.relocateTo()`, which centralizes the whole construction
///   (not just those three fields) so no call site can omit them again.
/// - Fixed TEST-019: `CardIssueToken.isValid()` only ever returned
///   true/false, so a business whose stored `stampsRequired` fell outside
///   the supported range (e.g. one configured before TEST-017 tightened
///   it) showed a generic "An error occurred. Please try again." on every
///   scan, forever - misleading, since retrying can never help. Added
///   `CardIssueToken.validationError()`, which reports a specific,
///   actionable reason instead.
/// - Fixed TEST-020 (the real fix superseding TEST-017's interim
///   mitigation): replaced the plain-JSON/byte-mode redemption QR
///   encoding with a compact one - gzip compression, Base45 text encoding
///   (RFC 9285, chosen because its alphabet is exactly QR's more
///   space-efficient "alphanumeric mode" character set), and an explicit
///   `'v': 2` version field. Raised the stampsRequired ceiling from 10 to
///   12 - measured safe (fits) even at 100% overflow-relocated stamps,
///   the worst case, verified against the real `qr` package. New shared
///   utilities: `Base45`, `AlphanumericQr`, `RedemptionQrCodec`. Also
///   consolidated `customer_card_detail.dart` onto the existing
///   `QRTokenGenerator.generateRedemptionRequest()` instead of a
///   hand-rolled duplicate, which surfaced and fixed a real, separate
///   inconsistency: that generator was previously only reachable from
///   dead code and had drifted to omit device-mismatch detection (V-005).
///   Full detail and measured sizes: DEFECT_TRACKER.md TEST-020.
///
/// Build 28 Changes (patch version bump 2.1.0 -> 2.1.1, not build-only -
/// build 27 was committed to git but never built or uploaded to
/// TestFlight, so this supersedes it entirely and carries its content
/// forward; bumped to a real patch version rather than another build-only
/// bump because DECISION-017 below is a genuine UX improvement, not just
/// a bug fix. Build 26 was already uploaded to TestFlight without either
/// of these, and Apple doesn't allow re-uploading a build number with
/// different content):
/// - Fixed TEST-021: issuing a card with many pre-applied initial stamps
///   had the same silent QR-capacity failure as TEST-017, just never
///   fixed on the issuance side. `supplier_issue_card.dart`'s on-screen
///   QR, and `backup_storage_service.dart`'s Print/Share QR generation
///   (which actually had a *lower* capacity ceiling, using error
///   correction level M instead of the on-screen view's L), now use the
///   same compact gzip+Base45+alphanumeric-mode encoding as TEST-020's
///   redemption QR, via a new `CardIssueQrCodec`. `qr_scanner_screen.dart`
///   (customer app) gained a matching decode-fallback tier. Doesn't
///   affect any business created under the current 3-12 stampsRequired
///   range - only a legacy business with a higher stored value (e.g. the
///   20-stamp business used throughout this whole defect chain) could
///   reach a high enough initial-stamp count to hit this. Incidental fix:
///   `_startCountdown()` leaked a new Timer.periodic on every QR
///   regeneration instead of cancelling the previous one. Full detail and
///   measured sizes: DEFECT_TRACKER.md TEST-021.
/// - DECISION-017: a business whose stampsRequired falls outside the
///   supported range (e.g. a legacy business from before TEST-017/020
///   tightened it) previously had no way to recover short of a full
///   reset - which wipes every customer's card - even though changing
///   stampsRequired going forward is actually safe (each existing card
///   stores its own value at issuance, not read live from the business).
///   Supplier app now: shows a proactive warning banner on Home the
///   moment an out-of-range business is detected; blocks Issue Card from
///   generating a doomed token/QR at all (the customer app would reject
///   it anyway per TEST-019); and offers a scoped "Fix Now" flow (also
///   reachable from Settings) to reconfigure into the supported range,
///   deliberately not general free-editing. New
///   `widgets/stamps_required_fix.dart`. The 3-12 bound is now a single
///   source of truth (`CardIssueToken.minStampsRequired`/
///   `maxStampsRequired`), referenced by the onboarding slider too,
///   instead of being duplicated - the exact kind of drift that caused
///   TEST-016/017/019. Full detail: DEFECT_TRACKER.md DECISION-017.
///
/// Build 29 Changes (build-only bump - build 28 was already uploaded to
/// TestFlight without this fix, and Apple doesn't allow re-uploading a
/// build number with different content):
/// - Fixed TEST-022: TEST-021's compact issue-card QR encoding was
///   unconditional (no size check), which broke card issuance for any
///   customer app older than that fix - Base45 is never valid JSON, so a
///   pre-TEST-021 customer app scanning ANY issuance from an updated
///   supplier (not just a high-initial-stamp-count one) saw a generic
///   "not a valid QR code" error. Confirmed on a real device: supplier
///   v2.1.0+27, customer v2.0.3+23, ordinary issuance failed outright.
///   `_buildIssueQrCode()` and `_buildRedemptionQrCode()` (the latter had
///   the identical unconditional shape from TEST-020, fixed proactively)
///   now check `QrCapacity.fits()` on the plain-JSON payload first and
///   only fall back to compact encoding when it genuinely doesn't fit -
///   plain JSON now covers every initial-stamp count up to 16, comfortably
///   spanning the entire 3-12 supported range with huge margin. No decode
///   -side changes needed - both apps already try plain JSON first.
///   Full detail: DEFECT_TRACKER.md TEST-022.

/// Build 30 Changes (minor version bump 2.1.1 -> 2.2.0 - a genuine
/// capability increase, not build-only or a patch):
/// - Supplier app: the Express Mode scan cooldown (`Business.scanInterval`)
///   is now editable after setup from Settings, not just once at
///   onboarding. New `widgets/scan_interval_editor.dart`, mirroring the
///   existing `stamps_required_fix.dart` self-service pattern. Safe to
///   change anytime - unlike `stampsRequired`, `scanInterval` is never
///   baked into an issued card; it's read live off the `Business` record
///   each time a stamp token is generated, so a change applies to the very
///   next scan with no effect on any card already issued. Also added a
///   read-only display of the current cooldown to the same screen.
/// - Positioning/metadata update for both apps' App Store Connect listings,
///   informed by a competitive assessment - see
///   docs/marketing/POSITIONING_UPDATE_PLAN_2026-08-21.md and
///   docs/marketing/COMPETITIVE_ASSESSMENT_2026-08-21.md. Applied to
///   APP_STORE_METADATA_PACKET_v2_2_0_30.md 2026-08-22.
///
/// Build 31 Changes (build-only bump, same 2.2.0 line - large addition to
/// the same in-development, not-yet-shipped release rather than its own
/// version, since nothing has been uploaded under 2.2.0 yet):
/// - Supplier app: business profile fields (Name, Icon, Brand Color) are now
///   editable after setup, alongside the already-editable Stamps Required
///   and Scan Cooldown - only `mode` remains permanently locked. New editor
///   dialogs mirror the existing `stamps_required_fix.dart`/
///   `scan_interval_editor.dart` self-service pattern.
/// - `stampsRequired` changes on an in-progress (non-redeemed) card now
///   follow a directional policy: a decrease applies on the customer's next
///   scan (reusing the existing TEST-018 overflow-relocation machinery for
///   any resulting over-completion, not a new instant-complete path); an
///   increase never applies retroactively - only to the next card, created
///   once the current one completes and redeems. `StampToken` gained
///   optional, unsigned snapshot fields (`businessName`, `brandColor`,
///   `logoIndex`, `stampsRequired`) to carry this - kept outside
///   `getSignatureData()` so stamp-chain integrity is unaffected, decoded as
///   nullable for backward compatibility with older tokens/app versions.
/// - New local audit trail (Supplier app only, per-device, not synced):
///   records initial business values at setup, every subsequent profile
///   field edit, and Recovery Backup/Clone-initiated and
///   Restore/Clone-received events, each with a timestamp, the field/event
///   name, the new value, and the app version that made the change. Viewable
///   and shareable (PDF, reusing the existing `BackupStorageService`
///   print/share pattern) from a new dedicated screen off Settings.
///   Cleared by "Delete All Data" like every other business-scoped table.
///   Full detail: docs/project-management/Requirements/
///   DISCUSSION_Business_Field_Editing.md. Implementation record:
///   docs/project-management/DEFECT_TRACKER.md DECISION-021. App Store
///   metadata: docs/deployment/APP_STORE_METADATA_PACKET_v2_2_0_31.md.

/// # source/shared/lib/version.dart:
const String appVersion = '2.2.0+31';
