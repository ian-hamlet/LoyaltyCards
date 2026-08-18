# App Store Metadata Packet (v2.1.0+27)

**Status: Built and uploaded to TestFlight the night of 2026-08-16/17 (confirmed by the user 2026-08-17) - superseded by `APP_STORE_METADATA_PACKET_v2_1_1_28.md` for App Store submission.** This build carried TEST-021 only; DECISION-017 didn't exist yet at upload time - it was designed and added afterward, and the two now ship together as v2.1.1+28 (a patch bump, since DECISION-017 is a genuine UX improvement rather than another build-only fix). The body below reflects what this build (TEST-021 only) actually was.

**Supersedes:** `APP_STORE_METADATA_PACKET_v2_1_0_26.md` for App Store submission purposes - that build shipped to TestFlight and fixed TEST-016 through TEST-020, but not TEST-021 (the issue-card counterpart to TEST-017/020's redemption QR capacity fix), found afterward via TestFlight testing. See `docs/project-management/DEFECT_TRACKER.md` for full detail.

**Build-only bump (2.1.0+26 -> 2.1.0+27), not a version change** - same feature set as v2.1.0+26 plus TEST-021's bug fix.

---

## Shared Listing Values

- Release Version: 2.1.0
- Build: 27
- All other shared values unchanged from v2_0_3_23 - see that packet.

---

## Customer App (LoyaltyCards Customer Wallet)

### What's New in This Version
Fixed a bug where a business set up for 3 or 4 stamps couldn't issue a working card. Also improved reliability of redeeming a completed card from a business using higher stamp counts - some completed cards could fail to show a redemption code; this is now fixed.

All other fields unchanged from v2_0_3_23 - see that packet for Basic Info, Subtitle, Promotional Text, Keywords, Description, and App Review Notes.

---

## Supplier App (LoyaltyCards Business)

### What's New in This Version
Fixed a bug where setting up a business with 3 or 4 required stamps produced a card that customers couldn't add - affected both Express Mode and Secure Mode. Also improved reliability of issuing and redeeming cards for Secure Mode businesses with higher stamp counts, and raised the maximum stamps required from 10 to 12.

All other fields unchanged from v2_0_3_23 - see that packet for Basic Info, Subtitle, Promotional Text, Keywords, Description, and App Review Notes.

### App Review Notes - additional context for this build
This build fixes three related issues found during internal testing, none reported by a real user (the app has minimal real-world usage so far):
1. Businesses configured for 3 or 4 required stamps (allowed by the onboarding slider) could never actually issue a working loyalty card - a validation bound elsewhere in the app didn't match the slider's own minimum.
2. In Secure Mode, redeeming a completed card with a higher stamp count (or one where stamps had been automatically moved between cards by the app's own overflow-handling logic) could occasionally fail to display a redemption code, with no error shown. This is now fixed by switching to a more compact code format for the redemption step; the maximum supported stamp count was raised from 10 to 12 as part of confirming the fix.
3. The same underlying issue as #2 could also affect issuing a new card with many stamps already applied at once (a manual catch-up scenario) - fixed the same way. Only reachable on a business set up before this update, since the current setup range (3-12 stamps) never produces enough pre-applied stamps to trigger it.

None of these affect the core review flow described in the standard notes above (Express Mode business setup, issuing a card, scanning to add stamps) - all are edge cases involving specific stamp-count configurations.

---

## Decisions (carried forward, unchanged)

Unchanged from v2_0_3_23 - see that packet.
