# Functional & Code Quality Review — 2026-07-26

**LoyaltyCards v1.1.0+12 (branch `feature/SecurityReview`)**
**Assessment Date:** July 26, 2026
**Assessor:** AI-assisted review (4 parallel focused analyses — Flutter lifecycle/state/navigation, business logic correctness, data layer correctness, iOS platform/performance), most severe findings independently verified by direct code reading before being recorded here.
**Trigger:** Requested as a second, distinct round of critical appraisal immediately after the [2026-07-25 security review](VULNERABILITIES.md#2026-07-25-security-review--signature-coverage--redemption-verification) and its fix pass.

**⚠️ Important: none of the findings in this document were identified in the 2026-07-25 security review**, despite that review covering the same codebase in depth just one day earlier. This is not a failure of that review — it was deliberately scoped to cryptography, key management, storage security, and auth/rate-limiting exploits (V-010 through V-016). This pass used a different lens entirely: functional correctness, Flutter engineering quality, and iOS platform integration, for a legitimate (non-adversarial) user in normal use. The two passes are complementary, not overlapping — a codebase can be free of exploitable vulnerabilities and still have real correctness bugs, and vice versa. Recording this explicitly so future reviews know a single pass, however thorough, does not substitute for reviewing from multiple angles.

**Status: all findings below are OPEN. Nothing in this document has been fixed yet** — this is a findings-only record, fixes to follow in a separate pass.

---

## Verified findings (read the actual code, not just agent output)

### Q-001: Biometric app-lock never re-locks after backgrounding

**Severity:** HIGH
**Affected Component:** Customer App - `main.dart`, `_AppLockWrapperState`
**Verification:** Confirmed via repo-wide grep — `WidgetsBindingObserver` appears **zero times** in either app.

`_checkAuthRequirement()` is called exactly once, from `initState()`. Nothing in `_AppLockWrapperState` observes `AppLifecycleState` changes, so once `_isAuthenticated` flips to `true` it stays `true` for the remaining life of the widget tree/process.

**Scenario:** Customer enables "require app lock," authenticates via Face ID once, backgrounds the app (switches to Messages, takes a call, etc.), then hands the still-unlocked phone to someone else or leaves it unattended. Reopening LoyaltyCards shows all cards immediately — no re-prompt. The feature functions as a one-time cold-launch gate, not a re-lock, which undermines its stated purpose ("protect access after the app isn't in front of you").

**Suggested fix:** Add `WidgetsBindingObserver` to `_AppLockWrapperState`, override `didChangeAppLifecycleState`, and re-run `_checkAuthRequirement()` (setting `_isAuthenticated = false` first) when the app transitions to `paused`/`inactive` and returns to `resumed`.

---

### Q-002: A single database-open timeout permanently deletes all local data

**Severity:** HIGH
**Affected Component:** Both apps - `database_helper.dart` / `supplier_database_helper.dart`, `_attemptDatabaseRecovery`
**Verification:** Confirmed by direct code read of both files.

```dart
// database_helper.dart:30-42 (supplier_database_helper.dart is the same shape)
Future<Database> get database async {
  if (_database != null) return _database!;
  try {
    _database = await _initDatabase().timeout(
      const Duration(seconds: 10),
      onTimeout: () { throw TimeoutException(...); },
    );
    return _database!;
  } on TimeoutException {
    await _attemptDatabaseRecovery();  // <-- deletes the file, no corruption check
    rethrow;
  }
  ...
}
```

`_attemptDatabaseRecovery()` deletes the on-disk `.db` file outright on **any** timeout — there is no `PRAGMA integrity_check`, no distinction between "genuinely corrupt" and "temporarily locked/slow." A missed 10-second deadline is the only trigger.

**Scenario:** Cold start on a throttled, low-storage, or otherwise slow device; or a backup/AV process (Time Machine equivalent, MDM scan, etc.) holding an OS-level file lock at exactly the wrong moment. A perfectly intact database gets deleted. Since this is a P2P app with no server, that data (every card, stamp, transaction) is unrecoverable — the app's own Recovery Backup feature (supplier side) is the only mitigation, and it's opt-in and business-only; customers have nothing equivalent.

**Suggested fix:** Before deleting, attempt a lighter-weight recovery first (retry the open with a longer timeout once, or run `PRAGMA integrity_check` if a connection can be opened read-only) and only delete if that check genuinely fails. At minimum, don't delete on the very first timeout — track consecutive failures and require corroborating evidence of corruption.

---

### Q-003: Stamp crediting is not transactional — can desync `stampsCollected` from actual stamp rows

**Severity:** HIGH
**Affected Component:** Customer App - `qr_scanner_screen.dart`, `_handleStampToken`
**Verification:** Confirmed — zero uses of `db.transaction()` anywhere in `qr_scanner_screen.dart` or the customer app's service layer.

`insertStamp`, `insertTransaction`, the REQ-022 multi-denomination loop, and the Secure-Mode "additional stamps" loop are all separate, un-transacted DB writes. `card.stampsCollected` is only updated at the very end of the function.

**Scenario:** Any step throws partway through — a legitimate signature check failing mid-loop (not an attack, just a stale/corrupted token), or a transient DB error on `insertTransaction`. One or more `Stamp` rows are already persisted, but `stampsCollected` is never incremented. The card's progress bar (`stampsCollected`) and the Stamp History screen (raw `stamps` table) now disagree, and because the hash chain's `previousHash` has already advanced, the customer can't cleanly rescan to "fix" it.

**Suggested fix:** Wrap the full crediting sequence (all stamp inserts, transaction log inserts, and the final `stampsCollected` update) in a single `db.transaction((txn) async { ... })` so it's all-or-nothing.

---

### Q-004: Wrong "new card created" message on Express Mode redemption

**Severity:** HIGH (correctness/UX, not data-loss)
**Affected Component:** Customer App - `customer_card_detail.dart`, `_processRedemption`
**Verification:** Confirmed by direct code read, lines 919-926 vs. 1009-1032.

```dart
final existingCard = await _cardRepo.findCardWithSpace(_card!.businessId);
if (existingCard != null) {
  // Skipping new card creation - will use existing card
} else {
  // Auto-create new card for continued loyalty
  await _cardRepo.insertCard(newCard);
}
// ... later, unconditionally in the success dialog:
Text('A new card has been added to your wallet automatically')
```

The dialog text is not gated on which branch ran — it always claims a new card was created, even when the code correctly reused an existing under-filled card instead.

**Scenario:** A customer with two cards for the same business (e.g. from an earlier overflow split — see Q-003's `.skip()` interaction below) redeems card A in Express Mode. The app correctly reuses card B rather than creating a third card, but still tells the customer a new card was added. They look for a card that was never created.

**Note:** the equivalent QR-scanner-driven redemption path (`qr_scanner_screen.dart`) already tracks a `newCardCreated` boolean and branches the message correctly — this is a case of one of two near-duplicate code paths getting the fix and the other not.

**Suggested fix:** Track whether the `existingCard != null` or `else` branch ran (a local `bool newCardCreated`) and conditionally show/hide the "new card added" message block, mirroring `qr_scanner_screen.dart`'s existing pattern.

---

## Additional findings (agent-reported, source-grounded, not independently re-verified line-by-line)

These came from careful, source-referenced agent analysis but weren't each individually re-read by me before this document was written — flagged as such so they're triaged with appropriate scrutiny before being acted on, not assumed fully confirmed.

### Q-005: Missing `mounted` checks in screens the 2026-07-25 security pass didn't touch (MEDIUM-HIGH)
Same crash pattern already fixed in `recovery_backup_screen.dart`/`supplier_redeem_card.dart` (that pass's redemption-confirmation flow specifically) exists in other files that pass didn't reach:
- `customer_app/lib/screens/customer/qr_display_screen.dart` — `_generateQRData()`, no `mounted` checks anywhere
- `customer_app/lib/screens/customer/customer_card_detail.dart` — `_loadCardData()` success/catch paths
- `supplier_app/lib/screens/supplier/supplier_issue_card.dart` — `_loadBusinessAndGenerateToken()`, all four `setState` calls
- `supplier_app/lib/screens/supplier/supplier_stamp_card.dart` — `_loadBusiness`, `_handleQRCode`, `_generateSimpleModeStampQR`
- `supplier_app/lib/screens/supplier/supplier_redeem_card.dart` — `_loadBusiness()` specifically (the rest of this file was hardened; this simpler init function was missed)

### Q-006: Overflow stamp-move can throw `RangeError` on desynced data (MEDIUM)
`qr_scanner_screen.dart` (`allStamps.skip(allStamps.length - overflow)`) assumes stamp-row count always matches `stampsCollected`. If Q-003 has already caused drift, the skip count can go negative and `Iterable.skip()` throws, leaving a just-completed card stuck mid-split.

### Q-007: QR code regenerated (with a live timestamp) on every incidental rebuild (MEDIUM)
`customer_card_detail.dart`'s `_generateCardQR()` is called directly in `build()` and embeds `DateTime.now()`, so any unrelated rebuild (rotation, unrelated `setState`) produces a visibly different QR code. `qr_display_screen.dart` does this correctly (generate once, cache in state, manual refresh only) — worth mirroring.

### Q-008: Migration backup files never cleaned up on failure (MEDIUM)
Both database helpers: `_cleanupOldBackups` is only called in the migration *success* path. A device stuck retrying a failing migration across app launches accumulates `backup_v*_<timestamp>.db` files indefinitely.

### Q-009: `Transaction.fromJson` throws on any unrecognized enum value (MEDIUM)
`shared/lib/models/transaction.dart` — `TransactionType.values.firstWhere(...)` has no `orElse`, unlike `OperationModeExtension.fromString` which safely defaults. One bad/legacy `type` value crashes the *entire* transaction list load (`.map().toList()` is eager), not just that row.

### Q-010: Customer app's migration backup/restore silently targets the wrong filename in test mode (MEDIUM)
`database_helper.dart`'s `_createDatabaseBackup`/`_restoreDatabaseBackup` hardcode `AppConstants.databaseName` instead of respecting `_testDatabaseName` (which `_initDatabase`/`_attemptDatabaseRecovery` in the same file *do* respect). The failure is silently swallowed by an outer try/catch ("continue migration even if backup fails"), meaning this safety net has likely never been exercised or verified by any test. The supplier app doesn't have this inconsistency — it's customer-app-only.

### Q-011: Orientation-correction code is dead, and the live workaround is fragile on iPad (LOW-MEDIUM)
`DeviceOrientationService` (native `MethodChannel`, would correctly detect upside-down orientation) exists in both apps but is **never called** anywhere. The actual camera-rotation logic is an aspect-ratio heuristic (`width > height`) plus manual user-facing "Rotate 90°/180°" buttons persisted to `SharedPreferences`. This heuristic cannot distinguish portrait from portrait-upside-down — both apps' iPad `Info.plist` orientation lists include `PortraitUpsideDown`, so this is reachable on iPad (which the apps now target per this session's App Store screenshot work), not just a theoretical edge case.

### Q-012: Backup file copy may not close the live connection actually being upgraded (LOW, lower confidence)
Migration backup/restore only close the cached `_database` field if non-null — during first-cold-boot upgrade that field is still `null` (set only after `_initDatabase()` returns), so the connection mid-`onUpgrade` may not be closed before the backup file copy runs underneath it. Flagged as lower-confidence pending a closer read of sqflite's exact connection lifecycle here.

---

## What's already solid (verified, not just claimed)

- `MobileScannerController` lifecycle across app background/foreground is **already handled correctly** — the `mobile_scanner` 7.2.0 library's own `MobileScanner` widget installs a `WidgetsBindingObserver` internally and pauses/resumes the camera automatically (`useAppLifecycleState: true` is the default, unoverridden at all four call sites). Verified by reading the library source, not just app code — no fix needed here despite the absence of an app-level `WidgetsBindingObserver`.
- Migration step-ordering is correct: a multi-version jump (e.g. v3→v7) applies every intermediate `if (oldVersion < N)` step in order.
- `PRAGMA foreign_keys = ON` is set in `onConfigure`, which sqflite guarantees runs before `onCreate`/`onUpgrade` — cascading deletes are active before any schema writes, and every child table correctly declares `ON DELETE CASCADE`.
- No N+1 query patterns; no `FutureBuilder`/`StreamBuilder`-in-`build()` bugs (neither widget is used anywhere in either app); no deprecated Flutter APIs found beyond the already-known `withOpacity` (checked `WillPopScope`, old Material buttons, `MaterialState`, `ColorScheme.background`, `textScaleFactor` — zero hits).
- `TextEditingController`/`Timer`/`AnimationController` disposal is disciplined and symmetric everywhere checked; `Dismissible`/`ListView.builder` items use proper unique keys.
- `isComplete` uses `>=` not `==` (tolerant of overflow); `RedemptionRequestToken.hasDeviceMismatch()` correctly treats null device IDs (legacy pre-V-005 cards) as "no mismatch" rather than crashing.
- `import_business_screen.dart` is the best-disciplined example in the codebase of `mounted` checking through a multi-step async+dialog flow.

---

## Recommended triage order

1. **Q-002** (data-loss on timeout) and **Q-001** (biometric re-lock gap) first — both are user-facing failures of features whose entire purpose is the thing that's broken (data safety, access control).
2. **Q-003** (non-atomic stamp write) and **Q-004** (wrong redemption message) next — real correctness bugs a normal user can hit without any adversarial input.
3. **Q-005** (missing `mounted` checks) — mechanical, same fix pattern already applied elsewhere this session, low risk to apply broadly.
4. Q-006 through Q-012 — real but lower-severity/lower-likelihood; batch into a later pass.

**Document Version:** 1.0 (2026-07-26, initial findings record — no fixes applied yet)
