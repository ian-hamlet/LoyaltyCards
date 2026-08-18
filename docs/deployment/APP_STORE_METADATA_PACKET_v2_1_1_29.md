# App Store Metadata Packet (v2.1.1+29)

**Status: Built and delivered to TestFlight 2026-08-18. Metadata confirmed and entered into App Store Connect 2026-08-18 (both apps' Promotional Text re-entered - both were found blank; Release Date confirmed set to Manual, both apps).** Build-only bump - v2.1.1+28 was already built and uploaded to TestFlight before TEST-022 was found (via real-device testing of that exact build), and Apple doesn't allow re-uploading the same build number with different content.

**Supersedes:** `APP_STORE_METADATA_PACKET_v2_1_1_28.md` (shipped to TestFlight with TEST-021 and DECISION-017, but not TEST-022) for App Store submission purposes. See `docs/project-management/DEFECT_TRACKER.md` TEST-022 for full detail. Everything else (Category, Subtitle, Description, Keywords, Promotional Text, and the Customer App's What's New) is **unchanged from the v2_1_1_28 packet** - only the Supplier App's What's New and App Review Notes gain a line about TEST-022.

**Build-only bump (2.1.1+28 -> 2.1.1+29), not a version change** - same feature set as v2.1.1+28 plus one additional bug fix (a cross-version compatibility regression TEST-021 introduced, invisible to any user running matched app versions).

---

## Shared Listing Values

- Release Version: 2.1.1
- Build: 29
- All other shared values unchanged from v2_0_3_23 - see that packet.

---

## Customer App (LoyaltyCards Customer Wallet)

### What's New in This Version
Fixed a bug where a business set up for 3 or 4 stamps couldn't issue a working card. Also improved reliability of adding and redeeming cards from a business using higher stamp counts.

### Promotional Text (170 chars max)
Free companion app for LoyaltyCards Business. Scan a shop's code to collect digital stamps - no signup, nothing stored, works offline.

**Status:** ✅ Confirmed and re-entered in ASC 2026-08-18. Kept here directly (not just "unchanged, see the old packet") because this exact field was found blank in ASC once already (2026-08-15) despite being documented as live from a prior version - having the actual text on hand in the *current* packet avoids having to dig it out of an older file again if it goes missing a second time.

All other fields unchanged from v2_0_3_23 - see that packet for Basic Info, Subtitle, Keywords, Description, and App Review Notes.

---

## Supplier App (LoyaltyCards Business)

### What's New in This Version
Fixed a bug where setting up a business with 3 or 4 required stamps produced a card that customers couldn't add - affected both Express Mode and Secure Mode. Also improved reliability of issuing and redeeming cards for Secure Mode businesses with higher stamp counts, raised the maximum stamps required from 10 to 12, and added a way to fix a business's stamp count in-app if it's ever set outside the supported range.

### Promotional Text (170 chars max)
A free pair of apps that help small shops run a simple digital stamp card - no fees, no accounts. Customers need the companion LoyaltyCards app on their own phone.

**Status:** ✅ Confirmed and re-entered in ASC 2026-08-18. This field was also found blank in ASC - the same gap as the customer app's Promotional Text (found 2026-08-15), but for this field the check was only actually done now, for this submission (it had been flagged back on 2026-08-15 as "worth checking" but not followed up on until now). Kept here directly for the same reason as the customer app's copy above - so it doesn't need digging out of `APP_STORE_METADATA_PACKET_v2_0_3_23.md` again next time.

All other fields unchanged from v2_0_3_23 - see that packet for Basic Info, Subtitle, Keywords, Description, and App Review Notes.

### App Review Notes - additional context for this build
This build fixes five related issues found during internal testing, none reported by a real user (the app has minimal real-world usage so far):
1. Businesses configured for 3 or 4 required stamps (allowed by the onboarding slider) could never actually issue a working loyalty card - a validation bound elsewhere in the app didn't match the slider's own minimum.
2. In Secure Mode, redeeming a completed card with a higher stamp count (or one where stamps had been automatically moved between cards by the app's own overflow-handling logic) could occasionally fail to display a redemption code, with no error shown. This is now fixed by switching to a more compact code format for the redemption step; the maximum supported stamp count was raised from 10 to 12 as part of confirming the fix.
3. The same underlying issue as #2 could also affect issuing a new card with many stamps already applied at once (a manual catch-up scenario) - fixed the same way. Only reachable on a business set up before this update, since the current setup range (3-12 stamps) never produces enough pre-applied stamps to trigger it.
4. A business set up before this update, with a stamp count now outside the supported range, previously had no way to fix its own configuration short of a full data reset. The app now detects this on launch and offers a guided way to update the stamp count in place, without affecting any customer's existing card.
5. The fix for #3 initially had an unintended side effect: it changed the internal format of new-card QR codes in a way that a customer running an older app version couldn't read, showing a generic error when adding a card from an updated business. This is now fixed - the app uses the original, universally-compatible format whenever possible, only switching to the newer format for the rare oversized case #3 actually targets.

None of these affect the core review flow described in the standard notes above (Express Mode business setup, issuing a card, scanning to add stamps) - all are edge cases involving specific stamp-count configurations or app-version combinations.

---

## Decisions (carried forward, unchanged)

Unchanged from v2_0_3_23 - see that packet.
