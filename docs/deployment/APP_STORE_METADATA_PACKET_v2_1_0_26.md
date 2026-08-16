# App Store Metadata Packet (v2.1.0+26)

**Status: IN PROGRESS - not yet built or uploaded, pending real-device verification.**

**Supersedes:** `APP_STORE_METADATA_PACKET_v2_0_4_24.md` (never built, folded into this release along with the interim test-only build v2.0.4+25) and, more importantly, `APP_STORE_METADATA_PACKET_v2_0_3_23.md` - that build is **live on the App Store** and contains TEST-016 (businesses with 3 or 4 required stamps can never issue a valid card). This build fixes that, plus a redemption QR-capacity failure (TEST-017 through TEST-020) found while testing the TEST-016 fix - see `docs/project-management/DEFECT_TRACKER.md` for full detail on all four. Everything else (Category, Subtitle, Description, Keywords, Promotional Text, App Review Notes) is **unchanged from the v2_0_3_23 packet** - see that file for the full text of those fields. Only What's New changes below.

**Minor version bump (2.0.4 -> 2.1.0), not build-only** - raising the supported Secure Mode stamps-required ceiling from 10 to 12 is a real, deliberate capability increase, not just a bug fix, per explicit decision.

---

## Shared Listing Values

- Release Version: 2.1.0
- Build: 26
- All other shared values unchanged from v2_0_3_23 - see that packet.

---

## Customer App (LoyaltyCards Customer Wallet)

### What's New in This Version
Fixed a bug where a business set up for 3 or 4 stamps couldn't issue a working card. Also improved reliability of redeeming a completed card from a business using higher stamp counts - some completed cards could fail to show a redemption code; this is now fixed.

All other fields unchanged from v2_0_3_23 - see that packet for Basic Info, Subtitle, Promotional Text, Keywords, Description, and App Review Notes.

---

## Supplier App (LoyaltyCards Business)

### What's New in This Version
Fixed a bug where setting up a business with 3 or 4 required stamps produced a card that customers couldn't add - affected both Express Mode and Secure Mode. Also improved redemption reliability for Secure Mode businesses with higher stamp counts, and raised the maximum stamps required from 10 to 12.

All other fields unchanged from v2_0_3_23 - see that packet for Basic Info, Subtitle, Promotional Text, Keywords, Description, and App Review Notes.

### App Review Notes - additional context for this build
This build fixes two related issues found during internal testing, neither reported by a real user (the app has minimal real-world usage so far):
1. Businesses configured for 3 or 4 required stamps (allowed by the onboarding slider) could never actually issue a working loyalty card - a validation bound elsewhere in the app didn't match the slider's own minimum.
2. In Secure Mode, redeeming a completed card with a higher stamp count (or one where stamps had been automatically moved between cards by the app's own overflow-handling logic) could occasionally fail to display a redemption code, with no error shown. This is now fixed by switching to a more compact code format for the redemption step; the maximum supported stamp count was raised from 10 to 12 as part of confirming the fix.

Neither issue affects the core review flow described in the standard notes above (Express Mode business setup, issuing a card, scanning to add stamps) - both are edge cases involving specific stamp-count configurations.

---

## Decisions (carried forward, unchanged)

Unchanged from v2_0_3_23 - see that packet.
