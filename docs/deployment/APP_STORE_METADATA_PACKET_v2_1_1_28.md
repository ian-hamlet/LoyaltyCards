# App Store Metadata Packet (v2.1.1+28)

**Status: Built and uploaded to TestFlight (confirmed by the user actively testing against it 2026-08-17) - superseded by `APP_STORE_METADATA_PACKET_v2_1_1_29.md` for App Store submission.** This build carried TEST-021 and DECISION-017; TEST-022 didn't exist yet at upload time - it was found via real-device testing of this exact build, and fixed afterward. The body below reflects what this build actually was.

**Supersedes:** `APP_STORE_METADATA_PACKET_v2_1_0_27.md` (shipped to TestFlight with TEST-021 only) and `APP_STORE_METADATA_PACKET_v2_1_0_26.md` for App Store submission purposes - that build shipped to TestFlight and fixed TEST-016 through TEST-020, but not TEST-021 or DECISION-017 (self-service recovery for a business outside the supported stamps-required range). See `docs/project-management/DEFECT_TRACKER.md` for full detail. Everything else (Category, Subtitle, Description, Keywords, Promotional Text, and the Customer App's What's New) is **unchanged from the v2_1_0_26 packet** - only the Supplier App's What's New and App Review Notes gain lines about TEST-021 and DECISION-017.

**Patch version bump (2.1.0 -> 2.1.1)** - bumped past build-only because DECISION-017 is a genuine UX improvement, not just a bug fix; same feature set as v2.1.0+26 plus one additional bug fix and one UX improvement, both supplier-side only.

---

## Shared Listing Values

- Release Version: 2.1.1
- Build: 28
- All other shared values unchanged from v2_0_3_23 - see that packet.

---

## Customer App (LoyaltyCards Customer Wallet)

### What's New in This Version
Fixed a bug where a business set up for 3 or 4 stamps couldn't issue a working card. Also improved reliability of redeeming a completed card from a business using higher stamp counts - some completed cards could fail to show a redemption code; this is now fixed.

All other fields unchanged from v2_0_3_23 - see that packet for Basic Info, Subtitle, Promotional Text, Keywords, Description, and App Review Notes.

---

## Supplier App (LoyaltyCards Business)

### What's New in This Version
Fixed a bug where setting up a business with 3 or 4 required stamps produced a card that customers couldn't add - affected both Express Mode and Secure Mode. Also improved reliability of issuing and redeeming cards for Secure Mode businesses with higher stamp counts, raised the maximum stamps required from 10 to 12, and added a way to fix a business's stamp count in-app if it's ever set outside the supported range.

All other fields unchanged from v2_0_3_23 - see that packet for Basic Info, Subtitle, Promotional Text, Keywords, Description, and App Review Notes.

### App Review Notes - additional context for this build
This build fixes four related issues found during internal testing, none reported by a real user (the app has minimal real-world usage so far):
1. Businesses configured for 3 or 4 required stamps (allowed by the onboarding slider) could never actually issue a working loyalty card - a validation bound elsewhere in the app didn't match the slider's own minimum.
2. In Secure Mode, redeeming a completed card with a higher stamp count (or one where stamps had been automatically moved between cards by the app's own overflow-handling logic) could occasionally fail to display a redemption code, with no error shown. This is now fixed by switching to a more compact code format for the redemption step; the maximum supported stamp count was raised from 10 to 12 as part of confirming the fix.
3. The same underlying issue as #2 could also affect issuing a new card with many stamps already applied at once (a manual catch-up scenario) - fixed the same way. Only reachable on a business set up before this update, since the current setup range (3-12 stamps) never produces enough pre-applied stamps to trigger it.
4. A business set up before this update, with a stamp count now outside the supported range, previously had no way to fix its own configuration short of a full data reset. The app now detects this on launch and offers a guided way to update the stamp count in place, without affecting any customer's existing card.

None of these affect the core review flow described in the standard notes above (Express Mode business setup, issuing a card, scanning to add stamps) - all are edge cases involving specific stamp-count configurations.

---

## Decisions (carried forward, unchanged)

Unchanged from v2_0_3_23 - see that packet.
