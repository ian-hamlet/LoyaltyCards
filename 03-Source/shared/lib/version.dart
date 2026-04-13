/// Shared app version information for both Customer and Supplier apps
/// 
/// Update this version string each time you make changes to verify
/// that the new code has been deployed to the device.
/// 
/// Format: v{major}.{minor}.{patch} (Build {build})
/// Example: v1.0.0 (Build 1)
///
/// Build 75 Changes:
/// - **SIMPLE MODE STAMP UI UPDATE**: Added green check icon and customer instruction
/// - Changed business icon to green check circle (matches secure mode)
/// - Added blue instruction box: "Now ask customer to scan this code and get their stamp"
/// - Consistent visual design between simple and secure modes
/// - Single stamp wording (simple mode is always one stamp at a time)
/// 
/// Build 74 Changes:
/// - **STAMP TEXT CORRECTION**: Changed "N Stamps Added!" to "Adding N Stamps!"
/// - Reflects in-progress state - customer hasn't scanned yet
/// - AppBar title: "Stamp Added" → "Adding Stamps"
/// - Main text: "$stampCount Stamps Added!" → "Adding $stampCount Stamps!"
/// 
/// Build 73 Changes:
/// - **REVERTED BUTTON STYLING**: Removed black border from Create Business Profile button
/// - Reverted bottomNavigationBar changes from Build 70 (removed Container wrapper with shadow)
/// - Button now looks clean again without decorative border
/// 
/// Build 72 Changes:
/// - **STAMP QR INSTRUCTION**: Added customer instruction on secure mode stamp screen
/// - "Now ask customer to scan this code and get their X stamp(s)"
/// - Blue highlighted banner with QR scanner icon for visibility
/// - **FIXED NAVIGATION**: Done and back buttons now return directly to home screen
/// - Both buttons pop twice (close QR screen + close camera scanner)
/// - No more stuck on camera screen with spinning circle
/// 
/// Build 71 Changes:
/// - **HIDE STATISTICS IN SIMPLE MODE**: Counters (Issued/Stamped/Redeemed) hidden for simple suppliers
/// - In simple mode, transactions aren't tracked server-side, so counters are inaccurate
/// - Statistics section only shown in secure mode where logging occurs
/// - **UNIFIED STAMP QR DISPLAY**: Secure mode now uses non-modal screen (consistent with simple mode)
/// - Changed from modal dialog popup to full screen navigation
/// - Supplier can keep QR visible without accidental dismissal
/// - Better UX: consistent behavior across both operation modes
/// - Simpler state management (no dialog lifecycle)
/// 
/// Build 70 Changes:
/// - **REDEMPTION INSTRUCTION**: Added clear instruction on redemption token screen
/// - "Now ask customer to scan this redemption code to complete the transaction"
/// - Green highlighted banner with QR scanner icon for better visibility
/// - **FIXED KEYBOARD OVERLAP**: Supplier setup button no longer hidden by iPad keyboard
/// - Bottom navigation bar now stays above keyboard suggestions/spell hints
/// - Added shadow and proper spacing for better visual clarity
/// 
/// NOTE: Stamp QR Display Design
/// - Secure mode currently uses modal dialog to show stamp QR
/// - Simple mode shows QR directly on screen (non-modal)
/// - RECOMMENDATION: Non-modal is better practice for QR codes because:
///   * Supplier can keep QR visible while customer scans
///   * No risk of accidental dismissal
///   * Simpler UX with fewer state transitions
/// - Consider unifying both modes to use non-modal display in future update
/// 
/// Build 69 Changes:
/// - **CARD CREATION IN STAMP HISTORY**: Shows when card was created and initial stamps (if any)
/// - Stamp history now always displays with "Card Created" entry at top
/// - Shows card creation date/time and number of initial stamps added
/// - Blue card icon distinguishes creation from regular stamps
/// - **FIXED TEXT COLOR**: "New card automatically added" text now uses blue[900] for better contrast
/// - Changed from default color to Colors.blue[900] on blue[50] background (improved readability)
/// 
/// Build 68 Changes:
/// - **FIXED SIMPLE MODE STAMP HISTORY**: Stamps now save correctly with unique IDs
/// - In simple mode, each scan generates a unique stamp record (not replaced)
/// - Stamp ID uses card + stamp number: `{cardId}_stamp_{number}` 
/// - Stamp number increments properly: 1, 2, 3, etc.
/// - Timestamp uses scan time (not token time since QR is reusable)
/// - Previous hash chains correctly from last stamp signature
/// - Stamp history now shows all stamps, not just the first one
/// 
/// Build 67 Changes:
/// - **AUTO-CREATE CARD ON REDEMPTION**: New card automatically added after redemption
/// - Both simple and secure modes now create a fresh card after reward is redeemed
/// - Matches overflow behavior where new cards are created automatically
/// - Success message updated to mention new card creation
/// - **IMPROVED STAMP HISTORY LOADING**: Added await to ensure stamps reload before showing feedback
/// - Added debug logging to card data loading for troubleshooting
/// 
/// Build 66 Changes:
/// - **SECURE MODE REDEMPTION TIMESTAMP**: Added date/time display to secure mode redeemed cards
/// - Secure mode now shows redemption timestamp like simple mode (consistent UX)
/// - Changed background from grey to green for redeemed cards in secure mode
/// - **SIMPLIFIED CONFIRMATION**: Removed confusing orange info box from simple mode redemption confirmation
/// - Removed "This will mark your card as redeemed..." text box (redundant, hard to read)
/// - Confirmation dialog now cleaner with just the main question
/// 
/// Build 65 Changes:
/// - **DATABASE MIGRATION**: Fixed "no redeemed_at column" exception
/// - Added database migration from v4 to v5 to add redeemed_at column
/// - Existing app installations will automatically upgrade their database
/// - Database version incremented to 5
/// 
/// Build 64 Changes:
/// - **SIMPLIFIED SUPPLIER UI**: Removed instructional text from simple mode screens
/// - Stamp screen: Removed "Customer scans this QR to add a stamp" info card
/// - Redeem screen: Removed step-by-step instructions and info box
/// - Supplier screens now show QR codes and icons only - cleaner interface
/// 
/// Build 63 Changes:
/// - **REDEMPTION TIMESTAMP**: Store and display when cards were redeemed
/// - Added redeemed_at column to database (records timestamp at redemption)
/// - Redemption success dialog shows time and date in customer app
/// - Redeemed cards in wallet display redemption timestamp
/// - Improved text readability: green color scheme instead of grey
/// 
/// Build 62 Changes:
/// - **CUSTOMER SELF-REDEMPTION**: Simple mode customers now redeem their own cards
/// - Customer presses "Redeem Reward" button after receiving reward from supplier
/// - Card marked as redeemed with timestamp on customer's device
/// - Supplier just verifies card visually - no button press needed
/// - Success dialog shows redemption time and date to customer
/// - Supplier instructions updated: customer triggers redemption
/// 
/// Build 61 Changes:
/// - **SIMPLE MODE REDEMPTION**: Manual confirmation for simple mode suppliers
/// - No QR scanning needed - honor-based system
/// - Supplier confirms they verified completed card and gave reward
/// - Records redemption with timestamp for supplier confidence
/// - Shows redemption time and date in confirmation dialog
/// - Secure mode redemption unchanged (still uses camera scanner)
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

const String appVersion = 'v0.1.0 (Build 75)';
