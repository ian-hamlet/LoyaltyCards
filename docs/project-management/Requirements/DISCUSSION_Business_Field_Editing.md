# Requirement Discussion: Business Profile Field Editing

## Document Information
- **Created**: 2026-08-22
- **Status**: Discussion / Pre-Requirement — not yet a formal REQ or DECISION entry
- **Branch**: `feature/businessedit`
- **Purpose**: Capture the analysis and open questions from an initial scoping conversation so work can continue without re-deriving the investigation.

---

## 1. The Capability Being Considered

Allow a supplier to edit business profile fields after their business (and cards) already exist, specifically:

- **Name** (`Business.name` / `Card.businessName`)
- **Icon** (`Business.logoIndex` / `Card.logoIndex`)
- **Stamp count required** (`Business.stampsRequired` / `Card.stampsRequired`)
- Brand color is in the same category as name/icon technically, though not explicitly requested yet.

**Explicitly excluded**: `mode` (Secure vs Express). This is not a display/config value — it selects which cryptographic flow (hash-chain validation vs trust-based static QR) a card's stamps use. Changing it after cards exist under the old mode would desync those cards from the verification logic they depend on. This stays genuinely locked, confirmed consistent with existing precedent (DECISION-017 in `DEFECT_TRACKER.md`, which drew the same line when investigating `stampsRequired` editability).

Cooldown (`scanInterval`, Express Mode) already has free-edit precedent (DECISION-020) and is **not** analogous in mechanism — see §3.

---

## 2. Why This Is Safe At the Signature/Token Level

`CardIssueToken.getSignatureData()` (`source/shared/lib/models/qr_tokens.dart`) bakes `businessName`, `stampsRequired`, `brandColor`, and `mode` into the signature **at issuance time only**. The customer app then denormalizes these onto its local `Card` record (`source/shared/lib/models/card.dart`) and never re-syncs them from `Business` afterward.

Consequence: editing these fields on the `Business` record only affects **cards issued after the edit**. No existing card's signature is invalidated, no QR payload shape changes, no `'v'` version-marker bump is needed (that marker governs payload *shape*, not field *values* — see `CardIssueQrCodec.currentVersion` / `RedemptionQrCodec.currentVersion`). This was previously investigated for `stampsRequired` specifically in DECISION-017 (`DEFECT_TRACKER.md` ~L1999-2017), which confirmed old and new cards proceed independently and in parallel, each against its own frozen values.

**stampsRequired is not purely cosmetic like name/icon** — it's the actual reward terms. A customer on an old card genuinely needs a different stamp count than a new signup post-change. Frame this to suppliers as "existing customers keep their original terms," not lumped in with icon/name as pure display drift.

---

## 3. The Staleness Problem (the actual crux)

### 3.1 Cooldown is not the right mental model
`scanInterval` (DECISION-020) is looked up **live** from `Business` every time a stamp is generated — never baked into a card's signature. That's why it was safe to make freely editable with *immediate* effect on every existing card. Name/icon/stampsRequired don't work that way; they're frozen per-card at issuance.

### 3.2 Redemption does not currently cure staleness
Investigated the "does a completed card at least get fresh values when it's replaced by a new one" question directly. **It does not, in either mode, today.**

When a card completes and is redeemed, both redemption handlers create a new `Card` row but populate it by **cloning fields off the old, stale card object** — not from a fresh `Business` lookup or a freshly-decoded `CardIssueToken`:

- Secure mode: `source/customer_app/lib/screens/customer/qr_scanner_screen.dart::_handleRedemptionToken` (~L951-1058), new card built ~L1030-1041, `stampsRequired: card.stampsRequired` (old card's value).
- Express mode: `source/customer_app/lib/screens/customer/customer_card_detail.dart::_processRedemption` (~L1001-1060), same clone pattern (~L1039-1051).

Confirmed no mode-based branch exists — both paths are identical in this respect, despite going through structurally different flows (Secure = supplier-signed `RedemptionToken` scan; Express = self-service in-app, gated on `mode == simple`). `RedemptionToken` itself (`qr_tokens.dart` ~L584-651) carries no `stampsRequired`/`businessName`/`brandColor`/`logoIndex` fields at all — only `cardId`, `businessId`, `stampsRedeemed`, `signature`, `timestamp`, device fields.

**Only genuine new-card issuance** (scanning the business's current signup/`CardIssueToken` QR) reads `Business` fresh — this is what DECISION-017's verification actually tested (lower `stampsRequired` → issue a brand-new card via add-card flow → correct new value shown). It's easy to mistake this for "redemption self-heals," but it's a different code path.

### 3.3 Stamp count itself already updates live, per scan
Clarified separately: `stampsCollected` is **not** only finalized on the last/completing scan. `_handleStampToken` (`qr_scanner_screen.dart:363`) writes the new count to SQLite immediately on every scan via `CardRepository.updateStampCount` (`card_repository.dart:135-145`), and the UI reads that persisted value live. A single scan can credit more than one stamp (`StampToken.stampCount` / `additionalStamps`), but each scan still produces one atomic persisted update — this is unrelated to the staleness problem, just confirming the mental model of "per scan" vs "per stamp" vs "on completion."

---

## 4. Proposed Fix

1. Add optional fields to `StampToken` (`source/shared/lib/models/qr_tokens.dart`): `businessName`, `brandColor`, `logoIndex`, `stampsRequired` — populated by the supplier app at token-generation time as a snapshot of current `Business` values.
2. **Keep these fields outside `getSignatureData()`.** They are informational/display-only, not trust-bearing — stamp-chain integrity (hash, count, signature) is unaffected. This is what avoids repeating the Build 18 experience (`version.dart:373`) where adding fields *into* the signed payload broke verification for every already-printed QR and forced a major-version bump with mandatory reprinting.
3. Decode as nullable, following the codebase's existing convention (e.g. `StampToken.businessId: json['businessId'] as String? ?? ''  // Backward compatibility`, `qr_tokens.dart:367`). Absent field ⇒ `null`, no error, no crash.
4. Customer app: track the most recent non-null snapshot received per card (persisted alongside the card record, updated whenever a scanned `StampToken` carries one).
5. Update both redemption handlers (§3.2) so the new `Card`'s `businessName`/`brandColor`/`logoIndex`/`stampsRequired` are sourced from the latest stored snapshot **if present**, falling back to today's clone-from-old-card behavior when absent. This fallback is the backward-compatibility story: an old supplier app that never sends the new fields, or an old cached/printed QR still in circulation, changes nothing — current behavior is the default, not a regression.

### Mode-specific propagation timing (document, don't attempt to equalize)
- **Secure mode**: `StampToken` is regenerated by the supplier device on every scan (`generateStampToken`, `supplier_stamp_card.dart:297`) — freshness is effectively real-time. This is the primary win.
- **Express mode**: the stamp QR is generated once and typically printed/displayed at the counter for reuse (`_generateSimpleModeStampQR`, `supplier_stamp_card.dart:379-401` — explicitly built as a generic, reusable token, not regenerated per scan). Freshness is bounded by whenever the supplier next reopens that screen and reprints/redisplays it — could be weeks.
  - **This is accepted as the supplier's operational choice, not a defect.** Printing was originally a time-saving device for Express mode; if a supplier prefers freshness over convenience, regenerating (not necessarily printing) the code after an edit resolves it immediately. To be called out explicitly in supplier-facing documentation/UI copy (e.g. near the "regenerate stamp QR" action: *"Changed your name, icon, or stamp count? Regenerate your Express stamp code so customers see the update."*), not solved in code.

### Compatibility summary
- Old supplier app versions → snapshot fields absent → customer app falls back to today's clone behavior. No regression.
- Old customer app versions → unknown JSON keys ignored → unaffected.
- No `'v'` payload-shape version bump required — this is a value-level additive change.
- No live network/Business-record lookup introduced — stays consistent with the app's offline/QR-driven, self-contained-token architecture.

---

## 5. Open Questions for Continued Discussion

1. Should `stampsRequired` editing stay gated behind a confirmation/warning about existing-customer terms diverging (product/UX call, not a technical constraint — DECISION-017 already noted the current lock is deliberately about avoiding mid-operation confusion, not a signature limitation)?
2. Should the `RedemptionToken` also carry a supplier-signed snapshot (Secure mode only, since a supplier is actively present and scanning at redemption time), to get true redemption-instant freshness rather than relying on the last ordinary stamp scan's snapshot? This would be an enhancement beyond the minimum fix in §4.
3. What's the actual UI/flow for suppliers to edit these fields — is there a new "Edit Business Profile" screen needed in `supplier_app`, or does this extend the existing narrow `showFixStampsRequiredDialog` / settings surfaces (`supplier_settings.dart`)?
4. Confirm final field list — is `brandColor` in scope alongside name/icon/stampsRequired, given it shares the exact same staleness mechanism?

## 6. Suggested Verification (mirrors DECISION-017/018 precedent)
- Edit a test business's name/icon/stampsRequired → complete and redeem a card in **Secure mode** → confirm the new card reflects the edit.
- Repeat in **Express mode** without regenerating the stamp code → confirm the new card still shows old values until the supplier regenerates it.
- Confirm an old-format `StampToken` (no snapshot fields) still redeems correctly via the old-card-clone fallback — no crash, no behavior change from today.

---

## Related Documents
- `docs/project-management/DEFECT_TRACKER.md` — DECISION-017 (`stampsRequired` editability investigation), DECISION-018 (icon/`logoIndex` precedent), DECISION-020 (`scanInterval`/cooldown free-edit precedent), TEST-020/TEST-021/TEST-022 (QR codec compaction, version-marker history).
- `source/shared/lib/version.dart` — v2.0.0 changelog entry on additive/default-safe fields vs signature-breaking fields.
- `docs/project-management/Requirements/REQ-008_Configurable_Stamp_Requirements.md` — existing formal requirement this discussion extends.
