# App Store Metadata Packet (v2.0.3+24)

**Status: SUPERSEDED - renamed.** This build was renumbered from a build-only bump (2.0.3+24) to a version bump (2.0.4+24) before ever being built - see `APP_STORE_METADATA_PACKET_v2_0_4_24.md` for the current content, which is otherwise identical.

**Supersedes:** `APP_STORE_METADATA_PACKET_v2_0_3_23.md`. That build is currently under App Store review and contains TEST-016 (see `docs/project-management/DEFECT_TRACKER.md`) - businesses configured with 3 or 4 required stamps can never issue a valid card. This build fixes that. Everything else (Category, Subtitle, Description, Keywords, Promotional Text, App Review Notes) is **unchanged from the v2_0_3_23 packet** - see that file for the full text of those fields. Only What's New changes below.

---

## Shared Listing Values

Unchanged from v2_0_3_23 - see that packet.

---

## Customer App (LoyaltyCards Customer Wallet)

### What's New in This Version
Fixed a bug where a business set up for 3 or 4 stamps couldn't issue a working card - if you saw an error scanning a new card from a business like that, this fixes it.

All other fields unchanged from v2_0_3_23 - see that packet for Basic Info, Subtitle, Promotional Text, Keywords, Description, and App Review Notes.

---

## Supplier App (LoyaltyCards Business)

### What's New in This Version
Fixed a bug where setting up a business with 3 or 4 required stamps produced a card that customers couldn't add - affected both Express Mode and Secure Mode. If you use a low stamp count, this fixes card issuance.

All other fields unchanged from v2_0_3_23 - see that packet for Basic Info, Subtitle, Promotional Text, Keywords, Description, and App Review Notes.

---

## Decisions (carried forward, unchanged)

Unchanged from v2_0_3_23 - see that packet.
