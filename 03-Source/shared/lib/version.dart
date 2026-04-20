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
/// When updating version for new build, you MUST update THREE files:
/// 1. 03-Source/customer_app/pubspec.yaml (line 5: version: X.Y.Z+BUILD)
/// 2. 03-Source/supplier_app/pubspec.yaml (line 5: version: X.Y.Z+BUILD)
/// 3. 03-Source/shared/lib/version.dart (this file, appVersion constant below)
///
/// All three MUST match exactly or builds will show inconsistent version numbers.
/// Build number (+BUILD) must increment for every TestFlight upload.
const String appVersion = '0.3.0+1';
