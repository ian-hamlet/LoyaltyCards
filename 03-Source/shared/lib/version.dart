/// Shared app version information for both Customer and Supplier apps
/// 
/// Update this version string each time you make changes to verify
/// that the new code has been deployed to the device.
/// 
/// Format: v{major}.{minor}.{patch} (Build {build})
/// Example: v1.0.0 (Build 1)
///
/// Build 60 Changes:
/// - Removed step-by-step instructions from supplier simple mode stamp screen
/// - Cleaner UI - instructions should be in help documentation, not main screen
/// 
/// Build 59 Changes:
/// - Fixed iOS build: Installed CocoaPods (required for iOS plugins)
/// - Ran pod install to setup Flutter module dependencies
/// - Build now succeeds on iOS (was "no such module flutter" error)
/// 
/// Build 58 Changes:
/// - Fixed import ambiguity: Added 'hide Card' to shared import in supplier_stamp_card.dart
/// - Build now succeeds (was conflicting with Flutter's Card widget)
/// 
/// Build 57 Changes:
/// - **CRITICAL UX FIX**: Simple mode supplier stamp screen now consistent
/// - Displays QR directly in screen body (like Issue Card screen)
/// - Back button now works properly (no modal dialog blocking it)
/// - Added Regenerate button in AppBar (consistent with Issue Card)
/// - Same color scheme across all supplier screens
/// - Removed confusing modal dialog with "Back" button
/// 
/// Build 56 Changes:
/// - Removed 60-minute rate limit in simple mode (now 1 second like secure mode)
/// - Allows multiple stamps to be added quickly (e.g., 2 coffees)
/// - Customer can scan simple mode QR repeatedly with 1-second delays
/// - 1-second delay prevents accidental duplicate scans only
/// 
/// Build 55 Changes:
/// - **CRITICAL FIX**: Added businessId to StampToken model for simple mode
/// - Simple mode stamps now work: Customer app looks up card by businessId, not cardId
/// - Fixed "Card not found please add the card first" error in simple mode
/// - StampToken now includes businessId field for proper card lookup
/// 
/// Build 54 Changes:
/// - **CRITICAL FIX**: Customer simple mode now works correctly
/// - Simple mode cards: Show camera scanner button (no customer QR shown)
/// - Secure mode cards: Show customer QR + scan stamp token button (unchanged)
/// - Simple mode: Customer directly scans supplier's static stamp QR
/// - Secure mode: Customer shows QR to supplier, then scans stamp token
/// - Fixed supplier app back button visibility on iPad (added foregroundColor: Colors.white)
/// - Updated all supplier AppBars for better visibility across all screens
/// 
/// Build 53 Changes:
/// - Simple mode supplier: Auto-generate stamp QR on screen load
/// - No intermediate button screen in simple mode
/// - QR dialog appears immediately when supplier opens stamp card
/// - Added "Regenerate" button to create new QR without closing screen
/// - Changed "Cancel" to "Back" for clearer navigation
/// 
/// Build 52 Changes:
/// - Fixed simple mode supplier stamp card behavior
/// - Simple mode: Shows button to generate stamp QR (no camera)
/// - Secure mode: Shows camera scanner to scan customer card
/// - Added _generateSimpleModeStampQR() for direct stamp QR generation
/// - Simple mode suppliers never scan customer cards
/// - Customers always scan supplier QR in simple mode
/// 
/// Build 51 Changes:
/// - Fixed search box dark mode readability (theme-aware surface color)
/// - Added operation mode indicator icon to customer cards
/// - Simple mode: Infinity icon (∞) in blue
/// - Secure mode: Security icon (🔒) in orange
/// - Mode indicator appears next to business name for visibility
/// 
/// Build 50 Changes:
/// - Proper Simple Mode implementation: Static/reusable QR codes in simple mode
/// - Simple mode tokens don't expire (no time validation)
/// - Rate limiting: 1 hour cooldown per business for simple mode (prevents abuse)
/// - Secure mode: 1 second cooldown (prevents duplicate scans)
/// - UI shows "Reusable QR (no expiry)" for simple mode
/// - UI shows "Valid X min (expires...)" for secure mode
/// - Refresh button only shown for secure mode (simple mode QRs are permanent)
/// - Customer can scan same simple mode QR multiple times (rate limited per customer)

const String appVersion = 'v0.1.0 (Build 60)';
