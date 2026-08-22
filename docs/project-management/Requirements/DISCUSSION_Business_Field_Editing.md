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
- **Brand Color** (`Business.brandColor` / `Card.brandColor`)
- **Stamp count required** (`Business.stampsRequired` / `Card.stampsRequired`)

**Confirmed 2026-08-22: editors are needed for all four of the above.** `stampsRequired` and `scanInterval` (Express Mode cooldown, a related but separately-precedented field - see below) already have edit UI (`stamps_required_fix.dart`, `scan_interval_editor.dart`). Name, Icon, and Brand Color currently have **no edit UI at all** (`supplier_settings.dart` shows them as read-only `ListTile`s) - new dialogs are needed for these three, following the same self-service pattern as the two that already exist.

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

### 4.1 Decided: directional policy for `stampsRequired` changes on an in-progress card

**Principle:** never worsen the deal for a customer already collecting under it; freely improve it. A customer who started collecting under one target didn't agree to a harder one part-way through — but there's no reason to withhold a benefit from them either. This resolves Open Question #1 below.

- **Decrease → applied on the customer's next scan, to the in-progress card itself.** When a scan writes a new stamp count (`_handleStampToken` in Secure mode; the Express equivalent), also compare the snapshot's `stampsRequired` against the card's current value. If lower, update the card's `stampsRequired` in the same write.
- **Increase → never applied to a card already in progress.** It only takes effect on the *next* card, created once the current one completes and redeems — which is exactly what points 1-5 above already fix. No separate mechanism needed for this half; implementing §4 as written *is* the increase-handling rule.
- **No proactive notification.** The customer only discovers a decrease's effect the next time they scan - consistent with the app's fundamentally QR-scan-driven architecture (nothing pushes state to the customer's device between scans, by design). This is a deliberate non-goal, not a gap to close.

**Edge case: a decrease brings `stampsCollected` at or past the new, lower `stampsRequired`.** This does **not** trigger an out-of-band "instant complete" - it's deliberately left to resolve on the customer's *next* scan, the same way any other completion does. Concretely: the scan that carries the lower snapshot applies the new `stampsRequired` to the card in the same write that credits the new stamp(s) - at which point the card may now be at or past its (revised, lower) target, and the **existing overflow-relocation machinery** (`Stamp.relocateTo()`, `CardRepository.findCardWithSpace()`, built for TEST-018) takes over exactly as it already does for an ordinary over-collection: the card completes at its `stampsRequired` count, and any surplus stamps carry forward onto a new (or existing-with-space) card. No new "complete without a new stamp" state is introduced - this reuses already-tested machinery rather than adding a second completion path. The customer won't know the count was reduced to (or below) their total until that next scan actually happens and the overflow lands.

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

1. ~~Should `stampsRequired` editing stay gated behind a confirmation/warning about existing-customer terms diverging~~ **Resolved, see §4.1.** Decrease applies immediately to in-progress cards (customer-favorable, no warning needed); increase only ever applies to a new card created after the current one redeems (never retroactive). Confirmation copy should still differ by direction so the supplier understands the effect: raising the count warns *"existing customers keep their current, lower target - only new cards use the new one"*; lowering it can just say *"existing customers' cards will update automatically on their next visit."*
2. Should the `RedemptionToken` also carry a supplier-signed snapshot (Secure mode only, since a supplier is actively present and scanning at redemption time), to get true redemption-instant freshness rather than relying on the last ordinary stamp scan's snapshot? This would be an enhancement beyond the minimum fix in §4.
3. ~~What's the actual UI/flow for suppliers to edit these fields~~ **Resolved 2026-08-22: extends existing settings surfaces, no new screen.** Implemented as inline editor dialogs (`business_name_editor.dart`, `business_icon_editor.dart`, `business_color_editor.dart`, mirroring the existing `stamps_required_fix.dart`/`scan_interval_editor.dart` pattern) launched from `supplier_settings.dart`'s existing `ListView` rows — not a new dedicated "Edit Business Profile" screen.
4. ~~Confirm final field list — is `brandColor` in scope~~ **Resolved 2026-08-22: yes.** Editors needed for Name, Icon, Brand Color, and Stamps Required - everything except `mode` (permanently locked, see above). See §1.

## 6. Suggested Verification (mirrors DECISION-017/018 precedent)
- Edit a test business's name/icon/stampsRequired (**increase**) → complete and redeem a card in **Secure mode** → confirm the new card reflects the edit, and confirm the still-in-progress old card was unaffected while it was open.
- Repeat in **Express mode** without regenerating the stamp code → confirm the new card still shows old values until the supplier regenerates it.
- Confirm an old-format `StampToken` (no snapshot fields) still redeems correctly via the old-card-clone fallback — no crash, no behavior change from today.
- **Decrease, in-progress card, no overflow:** business at `stampsRequired = 10`, customer card at 4/10 → supplier decreases to 6 → customer's next scan (adding a stamp, now 5/6) shows the card retargeted to 6, not still 10.
- **Decrease, in-progress card, triggers overflow (the §4.1 edge case):** customer card at 7/10 → supplier decreases to 5 → confirm nothing changes until the customer's *next* scan → that scan credits its stamp(s), the card completes at 5, and the existing overflow-relocation logic carries the surplus onto a new/existing card - not an instant completion the moment the business value changed.
- **Audit trail (§7):** fresh business setup logs one row per tracked field; editing `stampsRequired` and `scanInterval` each log exactly one new row with the new value, app version, and timestamp; Create Recovery Backup and Clone to Another Device each log an initiated-event row; restoring a backup and receiving a clone each log a distinct completion-event row plus the full set of inherited-value rows; the generated PDF opens and its table matches the on-device rows exactly.

---

## 7. New Requirement: Local Audit Trail for Business Configuration Changes

Requested 2026-08-22, alongside this field-editing work — since we're now letting suppliers change values that used to be permanent, a local record of what changed, when, and under what app version is worth having for support purposes. Grounded against the actual current schema/screens (`source/supplier_app/lib/services/supplier_database_helper.dart`, current `supplierDatabaseVersion = 5`), not yet implemented.

### 7.1 What gets logged

1. **Initial values, at business setup** — one row per profile field, logged the moment a business is created.
2. **Any subsequent edit** to a profile field — one row per field changed.
3. **Backup/Clone initiated** — one row when a Recovery Backup or a Clone-to-another-device QR is generated (the source device's side).
4. **Restore/Clone received** — one row marking the event, **plus** one row per field for the inherited values (same shape as #1 - a restore/clone-receive is, from the audit trail's perspective, just a new starting point, exactly like initial setup).

**Fields tracked**: Business Name, Icon, Stamps Required, Brand Color, Operation Mode (logged once at setup only, since it's permanently locked - see §1 - never appears as a later "edit" row), Scan Cooldown.

**Sequencing note**: `stampsRequired` and `scanInterval` already have edit UI today (`stamps_required_fix.dart`, `scan_interval_editor.dart`) - instrument those first, wired up immediately. Name, Icon, and Brand Color need new editor dialogs built as part of this same effort (confirmed in scope, §1) before their edits can be logged - the audit trail can't get ahead of the editors it's auditing, but all three are now confirmed work, not speculative.

### 7.2 Data model

New table, added via a schema version bump (`supplierDatabaseVersion` 5 → 6), following the exact `_onUpgrade` precedent already used for adding `redemptions` in the v1→v2 migration (`supplier_database_helper.dart:213-229`):

```sql
CREATE TABLE audit_trail (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  business_id TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  property_name TEXT NOT NULL,
  new_value TEXT,
  app_version TEXT NOT NULL,
  FOREIGN KEY (business_id) REFERENCES business (id) ON DELETE CASCADE
)
```

`business_id` is carried even though the app is genuinely single-business today (`BusinessRepository.getBusiness()` has no WHERE clause) - every other child table (`issued_cards`, `stamp_history`, `redemptions`) already does this, for cascading delete and as a stable identifier surviving resets. Match the existing pattern rather than deviate from it.

Deliberately **no old-value column** - matches what was actually asked for (date/time, property name, new value, app version). A field-edit row shows what it became, not what it changed from; the *previous* value is simply whatever the prior row for that same `property_name` said.

**Two real gotchas the current code surfaces, not optional cleanup**:
- `_validateDatabaseSchema()` (`supplier_database_helper.dart:393-436`) hardcodes the required-tables set (line 401) and required `business` columns (411-414). `audit_trail` must be added to that set or every post-migration validation fails.
- `clearAllData()` (446-455) hardcodes a delete per table. Needs a new `db.delete('audit_trail')` line - and since `ON DELETE CASCADE` already wipes it whenever `business` is deleted (i.e. whenever "Delete All Data" fires), this is really just being explicit/consistent with the existing per-table delete style, not a new behavior. Worth confirming this is the wanted behavior: a full reset takes the audit trail with it, since a reset business is a new identity - see Open Questions below.

### 7.3 Call sites to instrument

| Event | File : line | Notes |
|---|---|---|
| Initial values (fresh setup) | `supplier_onboarding.dart:94` (`insertBusiness`) | One row per tracked field |
| Initial values (restored) | `import_business_screen.dart:227` (`insertBusiness`), branch on `backup.type` | `'recovery'` vs `'clone'` (`supplier_config_backup.dart:22`) - log which, plus per-field inherited-value rows |
| Stamps Required edited | `stamps_required_fix.dart:125` | Already editable today |
| Scan Cooldown edited | `scan_interval_editor.dart:85-87` | Already editable today |
| Name / Icon / Brand Color edited | *(new editor dialogs needed - confirmed in scope, §1)* | Mirror `stamps_required_fix.dart`/`scan_interval_editor.dart`'s pattern; log call goes in each new dialog's save handler |
| Backup initiated | `recovery_backup_screen.dart:155-156` (`_generateBackup()`, inside `SupplierConfigBackup.createRecoveryBackup(...)` call) | |
| Clone initiated | `clone_device_screen.dart:112` (`_generateCloneQR()`, inside `SupplierConfigBackup.createCloneQR(...)` call) | |

### 7.4 Viewing, printing, and sharing the trail

Reuse the existing `BackupStorageService` (`source/supplier_app/lib/services/backup_storage_service.dart`) pattern wholesale rather than building new plumbing - it already does PDF generation (`pdf`/`pw.Document`), native print (`Printing.layoutPdf`), and share (`Share.shareXFiles`) for the backup/recovery flows:
- A new `generateAuditTrailPdf()`-style method, structured as a `pw.Table` (existing PDFs there use `pw.Column`/`pw.Container`, not `pw.Table` yet - this would be the first use of it, same package already a dependency).
- Reuse `_generateValidatedPdfBytes()`/`_isValidPdfBytes()` (lines 438-444, 423-426) for the same PDF-integrity safety net already applied to every other generated PDF.
- Reuse the `_generateFileName()` convention (line 447-453): `LoyaltyCards-AuditTrail-{BusinessName}-{yyyy-MM-dd}.pdf`.
- Mirror the existing double-tap guard pattern (busy-flag disabling the button mid-generation - see CRASH-001, `recovery_backup_screen.dart:59-61`) for whatever new Print/Share buttons this adds.

**Placement**: a new "Audit Trail" section in `supplier_settings.dart`'s `ListView`, following the existing header + `Divider` convention used by every other section there, placed as the literal last child - after the "Tips" container (currently the last item, ending at line 568) - matching "bottom of the business settings page" as written. **Confirmed 2026-08-22: the dedicated-screen approach (§7.4 above) is fine** - the actual requirement is that the trail must be easily both **readable in-app and shareable**, not any particular screen structure. A `ListTile` in Settings navigating to a dedicated screen (same pattern as "Create Recovery Backup"/"Clone to Another Device") satisfies both naturally: the screen itself is the readable table view, with Print/Share buttons on it for the shareable half.

### 7.5 Open Questions (audit trail specific) — all resolved 2026-08-22

1. ~~Does "Delete All Data" wiping the audit trail match intent~~ **Resolved: yes.** Confirmed explicitly - and worth noting, "Delete All Data" is itself gated to development builds only today (`_showResetButton => kDebugMode || _enableResetInRelease`, with `_enableResetInRelease = false` - `supplier_settings.dart:32-33`), so in production this is currently a non-issue; the `ON DELETE CASCADE` behavior in §7.2 already does this correctly with no extra code.
2. ~~Confirm the tracked-fields list~~ **Resolved, see §1/§7.1: Name, Icon, Brand Color, Stamps Required, Scan Cooldown** (Operation Mode logged once at setup only, never as an edit - it's permanently locked).
3. ~~Dedicated screen vs. inline table~~ **Resolved: dedicated screen, see §7.4 above.** The hard requirement is readable + shareable, not the specific layout.
4. ~~Any cap on trail length~~ **Resolved: no cap.** Genuinely unbounded for now - revisit later if it ever actually becomes a problem in practice.

---

## Related Documents
- `docs/project-management/DEFECT_TRACKER.md` — DECISION-017 (`stampsRequired` editability investigation), DECISION-018 (icon/`logoIndex` precedent), DECISION-020 (`scanInterval`/cooldown free-edit precedent), TEST-020/TEST-021/TEST-022 (QR codec compaction, version-marker history).
- `source/shared/lib/version.dart` — v2.0.0 changelog entry on additive/default-safe fields vs signature-breaking fields.
- `docs/project-management/Requirements/REQ-008_Configurable_Stamp_Requirements.md` — existing formal requirement this discussion extends.
