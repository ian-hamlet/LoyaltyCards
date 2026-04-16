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

const String appVersion = '0.2.0+17';
