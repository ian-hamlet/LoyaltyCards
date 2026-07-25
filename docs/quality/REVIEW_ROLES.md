# Application Review Roles

Reusable review lenses for LoyaltyCards (customer_app / supplier_app / shared),
beyond the two general-purpose passes already done: the security review
([VULNERABILITIES.md](VULNERABILITIES.md), V-010–V-016) and the functional review
([FUNCTIONAL_REVIEW_2026-07-26.md](FUNCTIONAL_REVIEW_2026-07-26.md), Q-001–Q-012).
Each role below targets a gap those two didn't cover.

Localization was considered and deliberately excluded — not a current product target.

## Review status: all 8 roles run 2026-07-25

All eight roles below have now been executed once (8 parallel general-purpose
agents, read-only). Full findings are under each role's heading; see
[REVIEW_MATRIX.md](REVIEW_MATRIX.md) for the at-a-glance table.

**Two notable cross-role convergences** — different lenses, same root cause,
which raises confidence these are real:

1. **Recovery Backup / Clone Device restore defeats V-013's duplicate-redemption
   check.** Found independently by both the Fraud/Abuse Red-Team review (as
   High) and the Offline/Multi-Device Consistency review (as Critical — see
   below for why the severities differ). `SupplierConfigBackup` carries
   business identity and keys but never the `redemptions`/`stamp_history`
   tables, so a cloned or recovered supplier device starts with an empty
   redemption ledger while every previously-issued, previously-redeemed card
   remains fully cryptographically valid. This is the single highest-priority
   fix to come out of this round.
2. **A hashed device identifier is generated, stored, and P2P-transmitted via
   QR, undisclosed in the Privacy Policy.** Found independently by both the
   App Store Compliance review (as Critical, framed as an App Review
   rejection risk) and the Legal/Privacy review (as Medium, framed as
   documentation drift). The V-005 anti-fraud fix embeds a hashed device ID
   in `RedemptionRequestToken`/`RedemptionToken`, but the Privacy Policy
   explicitly lists "Device identifiers" under "Data We DO NOT Collect."

## The prompt

To run one role:

> Run a **[ROLE NAME]** review of the LoyaltyCards codebase (customer_app,
> supplier_app, shared), using that role's checklist in
> docs/quality/REVIEW_ROLES.md. First skim docs/quality/VULNERABILITIES.md and
> docs/quality/FUNCTIONAL_REVIEW_2026-07-26.md so you don't re-surface issues
> already tracked there. Report findings with severity (Critical/High/Medium/Low)
> and file:line references, and for each recommend either a fix or
> accept-as-risk with reasoning. When done, update that role's row in
> docs/quality/REVIEW_MATRIX.md: date, one-line summary, and finding counts by
> severity.

To run all of them: repeat the above once per role below, or hand the whole list
to parallel subagents (one per role) if running them independently makes sense
for the effort involved.

## Roles

### 1. Fraud / Abuse Red-Team
**Lens:** an adversarial customer, supplier, or colluding pair trying to extract
rewards dishonestly — distinct from the security review's "can the crypto be
broken" framing.
**Check:** Express Mode self-stamp/self-redeem abuse paths; multi-device stamp
duplication via backup/restore; supplier-customer collusion (fake stamps for
kickback); device clock manipulation; backup/restore replay to reset an
already-redeemed card's state; whether the mitigations documented in
[SECURITY_MODEL.md](../technical/SECURITY_MODEL.md) (timestamp visibility, rate
limiting, face-to-face accountability) actually hold under deliberate,
motivated abuse rather than casual opportunism.
**Deliverable:** abuse-case list, likelihood × impact, existing-mitigation
sufficiency verdict per case.

**Findings (2026-07-25) — High: 1, Medium: 1, Low: 1:**

- **[High] Recovery Backup / Clone Device restore silently resets the
  supplier's anti-double-redemption ledger, defeating V-013.**
  `SupplierConfigBackup` (`shared/lib/models/supplier_config_backup.dart`)
  carries business identity + keys only, never the `redemptions` table.
  `BusinessRepository.hasBeenRedeemed()` queries only the local device's own
  table. Since businessId and the keypair survive a restore unchanged, every
  previously-redeemed card stays fully valid and can be redeemed again on a
  cloned/recovered device with zero forgery. Clone Device's stated use case
  (two concurrent registers) makes this reachable without any device-loss
  event at all. **Also flagged independently by Offline/Multi-Device
  Consistency, below — see the convergence note at the top of this doc.**
  Recommend: either embed a redemption watermark/digest in the backup
  payload, or at minimum surface an explicit warning on both Clone and
  Recovery flows that past redemptions aren't carried over. Not currently
  documented anywhere as a residual risk.
- **[Medium] "Supplier visual verification" mitigation has no supporting UI.**
  SECURITY_MODEL.md credits the supplier with reviewing stamp timestamps
  before redeeming, but `supplier_redeem_card.dart` never renders per-stamp
  timestamps or a redemption date in the supplier's own UI — the data only
  ever exists on the customer's device, unprompted. Simple Mode redemption
  isn't even tied to a real `cardId` (`_processManualRedemption` fabricates a
  synthetic ID), so there's nothing for the supplier app to look up even if
  it wanted to. Recommend: either add a lightweight display of incoming
  stamp timestamps at confirmation, or soften the doc's language to
  "supplier is expected to ask to see the customer's phone" (procedural, not
  tooling-backed).
- **[Low, accept-as-risk] Express Mode's `stampCount` field lets one
  fabricated QR complete an entire card in a single scan**, not just
  accelerate per-stamp forgery (`qr_scanner_screen.dart:420-437`). This
  sharpens the already-accepted V-001/L-002 risk rather than introducing a
  new category — recommend only a doc update noting `stampCount` allows
  instant single-scan completion, a more overlookable pattern than gradual
  forgery.
- Checked with no new findings beyond existing docs: two-device Express Mode
  double-collection (V-015, confirmed still by-design), device clock
  manipulation (all load-bearing `DateTime.now()` calls traced — already
  documented), QR/stamp/redemption screenshot replay (V-003/V-012 hold,
  given the supplier's own ledger is intact), supplier-customer collusion
  (no technical deterrent in either mode — inherent to a keyless, supplier-
  is-the-authority architecture; recommend adding explicit accept-as-risk
  documentation to SECURITY_MODEL.md since it isn't called out today).

### 2. Accessibility
**Lens:** a user relying on VoiceOver/TalkBack, Dynamic Type, or with low
vision/motor impairment.
**Check:** semantic labels on icon-only buttons; tap target sizes (44×44pt
minimum); color contrast beyond the dark-mode fixes already applied to
`how_it_works.dart` and the ~10 known contrast bugs; Dynamic Type scaling
without layout breakage; screen-reader focus order; accessibility of the
QR-scanner screen specifically (an inherently visual interaction with no
obvious non-visual fallback).
**Deliverable:** pass/fail per screen, prioritized list.

**Findings (2026-07-25) — Critical: 1, High: 2, Medium: 2, Low: 1:**

- **[Critical] QR-scanner screens have no non-visual affordance at all — a
  blind user cannot stamp or redeem.** Zero `Semantics(`/`semanticLabel`
  usage anywhere in either app; zero haptic/audio feedback tied to the actual
  scan-detect success/failure path in any of the three scanner screens
  (`qr_scanner_screen.dart`, `supplier_stamp_card.dart`,
  `supplier_redeem_card.dart`); no manual-entry fallback exists anywhere.
  Since scanning is the *only* way to stamp or redeem, this fully locks out
  a screen-reader user from the app's core function. Recommend: haptic
  feedback + `SemanticsService.announce()` on scan success/failure at
  minimum, and ideally a manual-code-entry fallback (the QR payload is just
  a string token, already parseable via `QRToken.fromQRString`).
- **[High] Icon-only `+`/`-` stepper controls have no accessible label** —
  `supplier_onboarding.dart:215,231,368,384`, `supplier_issue_card.dart:207,228`.
  VoiceOver announces adjacent increment/decrement buttons identically as
  "button, button." Cheap fix: add `tooltip` text, matching the pattern
  already used correctly elsewhere in the same file.
- **[High] Brand-color picker swatches are unlabeled bare `GestureDetector`s**
  (`supplier_onboarding.dart:423-452`) — no text, tooltip, or `Semantics`
  anywhere near them; a VoiceOver user configuring their business's brand
  color gets silent, unlabeled swipe targets. Recommend wrapping each in
  `Semantics(label: ..., button: true, selected: ...)`.
- **[Medium] Widespread hardcoded `Colors.grey[600]`/`.shade*` text color,
  not theme-aware — distinct from the `BrandColors.textPrimary/textSecondary`
  pattern already fixed this session.** Confirmed across ~15 files in both
  apps; computes to roughly 4.4:1 contrast against a typical dark surface,
  just under WCAG AA's 4.5:1 threshold. Recommend replacing with
  `Theme.of(context).colorScheme.onSurfaceVariant`, same fix pattern already
  applied elsewhere, worth its own pass given the volume.
- **[Medium] Stamp-grid numbers can overflow their fixed-diameter circles at
  large Dynamic Type sizes** (`customer_card_detail.dart:736-792`) — font
  size isn't decoupled from system text scaling, so at iOS's largest
  accessibility sizes stamp numbers visibly overlap in the grid. The
  accompanying "N of M stamps" text scales correctly and could serve as the
  accessible source of truth if the grid numbers are exempted from scaling.
- **[Low] Flashlight/rotate controls lack tooltips; mini FABs are under the
  44pt tap-target minimum** across scanner screens — secondary to the
  Critical finding above, cheap fix (add `tooltip`, same pattern as
  elsewhere).
- Checked with no findings: screen-reader focus order (Stack/Positioned usage
  confined to already-flagged visual-only scanner/QR screens); Dynamic Type
  truncation via `maxLines`/`ellipsis` (zero occurrences outside the
  already-fixed `how_it_works.dart`).

### 3. App Store / Platform Compliance
**Lens:** an Apple App Review team member.
**Check:** Info.plist usage-description strings match actual usage; Privacy
Manifest / data-collection disclosures match reality (no server, no accounts —
confirm the manifest actually says that); HIG conformance on navigation and
standard controls; permission requests (camera, biometrics, notifications if
any) are minimal, justified, and correctly timed; no guideline trip-wires
around the P2P/no-backend architecture being misread as something it isn't.
**Deliverable:** submission-readiness checklist, pass/fail/needs-fix per item.

**Findings (2026-07-25) — Critical: 1, High: 0, Medium: 2, Low: 1:**

- **[Critical] Privacy Policy falsely claims "no device identifiers
  collected" / "no data leaves your device," contradicted by shipped code.**
  The V-005 fix embeds a hashed device identifier
  (`DeviceService.getDeviceId()`) in the redemption QR payload
  (`cardDeviceId`/`currentDeviceId` on `RedemptionRequestToken`/
  `RedemptionToken`), which is read by the supplier's device — that's data
  leaving the customer's device. `docs/legal/PRIVACY_POLICY.md` explicitly
  lists "❌ Device identifiers" under data *not* collected and separately
  claims "No data leaves your device." The draft App Review Packet also
  answers Apple's "does this app collect user data" question "No." This is
  a canonical Guideline 5.1.1 rejection pattern if a reviewer or researcher
  finds the mismatch. **Also flagged independently by Legal/Privacy, below
  — see the convergence note at the top of this doc.** Recommend: disclose
  the hashed device ID and its P2P-only fraud-prevention purpose in the
  Privacy Policy, and correct the App Privacy questionnaire answers before
  submission — the feature itself is legitimate and shouldn't be removed.
- **[Medium] App Review / metadata packets are stale** —
  `APP_REVIEW_PACKET_v1_0_2_8.md` and the metadata packet don't reflect two
  version bumps since (`1.0.3+10`, `1.1.0+12`), including the device-ID
  behavior above. Recommend regenerating/re-dating before submission of the
  current build.
- **[Medium] Reviewer instructions don't state the P2P flow needs two
  physical devices with cameras** — `mobile_scanner` doesn't work in
  Simulator, and a single device can't scan its own screen. Add an explicit
  line to the Reviewer Test Instructions; cheap fix, reduces review friction.
- **[Low, accept-as-risk] No app-level `PrivacyInfo.xcprivacy` manifest** in
  either `ios/Runner/` — but no native code in either app's own Runner
  target currently uses a required-reason API, and third-party plugin
  manifests already aggregate correctly in archived builds. No action needed
  today; worth a sanity check at the next `xcodebuild archive`.
- Checked with no findings: Info.plist usage-description strings (present,
  accurate, contextual — no upfront permission grabs); no analytics/crash-
  reporting/network SDKs anywhere in `source/*/lib`; no IAP/payment
  trip-wires; HIG-conformant navigation.

### 4. Offline / Multi-Device Consistency
**Lens:** there is no server to reconcile state — what happens when the same
business or card exists across multiple devices, or a device restores a stale
backup.
**Check:** `DeviceService`/`device_id` tracking usage (V-005); interaction
between backup/restore and `is_redeemed`/stamp counts; behavior if a supplier
restores an old backup after issuing newer stamps; race conditions from
scanning the same reusable Express Mode QR on two customer devices; SQLite
schema-migration safety across versions (`_onUpgradeWithSafety` rollback path).
**Deliverable:** walk-through of each risky scenario — current behavior vs.
desired behavior.

**Findings (2026-07-25) — Critical: 1, High: 1, Medium: 0, Low: 0:**

- **[Critical] Cloned/recovered supplier devices each keep an independent
  redemption ledger, defeating V-013 for the app's own supported multi-
  register/recovery workflows.** Same root cause as the Fraud/Abuse finding
  above, traced end-to-end here: `import_business_screen.dart`'s only DB
  write on import is `insertBusiness()` — `redemptions`, `stamp_history`,
  and `issued_cards` are never part of the backup payload or the import
  path. Separately, `Card.isRedeemed` is only set on the *second* leg of the
  redemption handshake (scanning the signed `RedemptionToken` back), which
  the customer is free to skip — so a completed, genuinely-signed card can
  be redeemed once per cloned/recovered device with zero forgery required.
  Rated Critical here (vs. High in the Fraud/Abuse review) because Clone
  Device's own stated purpose — two concurrent registers sharing a business
  — makes this reachable in completely ordinary, non-adversarial use, not
  just after a device-loss event. Recommend downgrading V-013's "FIXED"
  status to "fixed per-device" until addressed, and see the shared
  recommendation under Fraud/Abuse above.
- **[High] Card-split/overflow stamp-move logic still performs many
  un-transacted delete+insert writes**, unlike the credit path Q-003 already
  fixed (`qr_scanner_screen.dart:635-830`). When a scan pushes a card past
  `stampsRequired`, the destination card's `stampsCollected` is bumped
  *before* the per-stamp move loop runs, and each stamp move is a separate
  un-transacted delete-then-insert. A force-quit or transient DB error
  mid-loop permanently loses stamp rows while the count field claims they
  exist — a genuine data-loss bug reproducible by a normal OS-initiated app
  kill, not an adversarial scenario. Recommend extending the same
  `runInTransaction`/`executor` pattern Q-003 introduced to cover this
  entire block.
- Checked with no new findings: `device_id` remains purely advisory,
  customer-side only, never blocking (matches documented design — and is
  the direct reason nothing tracks "which device redeemed this," i.e. the
  root cause of the Critical finding above); two-device Express Mode
  double-collection (V-015, unchanged, by-design); SQLite migration/rollback
  safety (matches Q-002/Q-008/Q-012 as already documented, including
  Q-012's still-open item about the live connection not always closing
  before a backup-file copy — no new angle found beyond what's already
  tracked).

### 5. Onboarding / First-Run UX
**Lens:** a brand-new user with zero context — a supplier setting up their
first business, or a customer scanning their first card.
**Check:** clarity of the Express vs. Secure mode choice at setup; error
messages for common early mistakes; empty states; first-card-issuance flow
friction; permission-request timing and framing (camera, biometrics).
**Deliverable:** friction-point list, framed as "would this cause an abandoned
setup or a 1-star review."

**Findings (2026-07-25) — Critical: 0, High: 1, Medium: 1, Low: 1:**

- **[High] Camera permission denial is a dead end with no recovery path.**
  None of the three `MobileScanner` widgets (customer + 2 supplier screens)
  pass an `errorBuilder`; on denial the package's default fallback is a
  plain black screen reading "Camera permission denied." with no "Open
  Settings" button and no retry affordance. Since the customer app's *only*
  route to adding a first card is this scanner screen, a reflexive "Don't
  Allow" tap on first launch — plausible for a brand-new install — strands
  the user with no visible way forward. Rated the single highest-risk UX gap
  found: it sits directly on the only path to the app's core first action.
  Recommend adding an `errorBuilder` that detects `permissionDenied`
  specifically and offers a button to open Settings.
- **[Medium] Express vs. Secure mode tradeoff is explained in plain language
  only behind a tap-triggered tooltip, not shown by default.** The visible
  radio-button subtitles only say who each mode is "recommended for," never
  that Secure Mode needs the supplier's device present at every single
  stamp — that explanation exists only behind a small ⓘ icon. An owner who
  doesn't discover it can pick a mode without understanding the operational
  commitment, and switching later invalidates every already-issued card
  (the amber warning covers that cost, but only after the fact). Recommend
  promoting the tooltip's key operational line into always-visible subtitle
  text.
- **[Low, accept-as-risk] Camera permission requested immediately on screen
  open with no in-app priming screen** — minor given the Info.plist usage
  strings are already clear; recommend prioritizing the denial dead-end fix
  above over adding a priming step.
- Checked with no findings: error messages for common mistakes (wrong QR
  type, card not found, expired/already-redeemed, incomplete card) are all
  specific and actionable; empty states (clear on both sides; supplier can't
  even reach a card-less home screen, it redirects straight to onboarding);
  first-issuance friction (~4-5 taps per side across two devices, reasonable
  for an inherently two-device interaction); biometric prompt timing
  (opt-in only, off by default — no first-launch surprise).

### 6. Test Coverage / QA
**Lens:** what's untested, not what's currently broken — complements the
functional review, which found live bugs directly.
**Check:** coverage gaps in critical paths (redemption, backup/restore,
mode-switching); whether widget/integration tests exist for actual user flows
versus only unit tests on services/repositories; flaky-test risk (see the
cross-file DB-singleton race found and fixed in `supplier_app` this session);
whether the Q-001–Q-010 fixes have durable regression tests beyond the ones
added during that pass.
**Deliverable:** coverage-gap list mapped to risk — a gap in redemption logic
outweighs one in a settings toggle.

**Findings (2026-07-25) — Critical: 2, High: 3, Medium: 2, Low: 1. Suite
health: 332/332 tests green (shared 152, customer_app 122, supplier_app 58),
verified by running each package fresh.**

- **[Critical] `database_timeout_test.dart` doesn't exercise the Q-002 fix.**
  8 of its tests are empty `// TODO: Implement...` stubs — a regression to
  the `_looksLikeValidSqliteFile` header check would silently reintroduce
  unconditional data-wipe-on-timeout, arguably the highest-stakes fix in the
  codebase, with nothing to catch it.
- **[Critical] `SupplierConfigBackup` has zero test coverage** — the
  HMAC-SHA256/HKDF signing and `fromJson`/`fromQRString` parsing for both
  Clone Device and Recovery Backup QR payloads is entirely untested, despite
  being both security- and recovery-critical (and, per the Fraud/Abuse and
  Offline/Multi-Device findings above, the exact mechanism with the
  Critical redemption-ledger gap).
- **[High] `import_business_screen.dart`'s restore path has zero coverage**
  at any level — the "reader" half of backup/restore.
- **[High] `supplier_redeem_card.dart` (both modes, device-mismatch
  handling) is referenced by no test file in the repo.**
- **[High] Widget/integration coverage is essentially absent monorepo-wide**
  — 1 widget-test file out of ~22 screens across both apps; the existing
  `database_helper_operations_test.dart` "simulates" `qr_scanner_screen.dart`
  rather than exercising it.
- **[Medium] Q-001 (biometric re-lock), Q-004 (newCardCreated dialog
  gating), and Q-006 (`_safeSkipCount`) have no regression tests** despite
  being real fixes from this session.
- **[Medium] `biometric_auth_service.dart`'s fail-open catch blocks are
  untested in both apps** — same shape of risk as V-014.
- **[Low] Q-008's cleanup-after-rollback path is unverified by any
  migration test.**
- Checked with no findings beyond the above: `CryptoUtils
  .verifyRedemptionStampChain` is well exercised (genuine chains, tampered
  signatures, appended/reordered stamps, wrong cardId, wrong public key,
  empty lists all covered); the `resetForTesting(testDatabaseName:)`
  pattern from this session's cross-file DB-race fix is applied
  consistently everywhere it needs to be; no `skip:` markers found anywhere.

### 7. Performance / Battery
**Lens:** sustained or repeated use, not a single scan — lower priority given
this app's actual usage pattern (short bursts), but cheap to check.
**Check:** camera/QR-scanner lifecycle — is the camera released when leaving
the screen (ties to the Q-005 `mounted`-check fixes); rebuild/animation cost on
card list/detail screens; SQLite query patterns (N+1 risk across
cards/stamps/transactions); cold-start time.
**Deliverable:** hotspot list — flag only what's likely to actually matter at
this app's scale.

**Findings (2026-07-25) — Critical: 0, High: 0, Medium: 0, Low: 1. Cleanest
result of all 8 roles — the codebase checked out well across every checklist
area.**

- **[Low, accept-as-risk] "Delete all data" issues one DB call per card**
  instead of a single bulk delete (`customer_settings.dart:224-234`). A
  rare, explicitly user-triggered action at a card-count scale where the
  N+1 cost is negligible — accept as-is, fix opportunistically only if
  touching this file for other reasons.
- Checked with no findings, independently re-verified (not just trusted from
  the prior review's summary): camera controller lifecycle — all four
  scanner screens across both apps correctly dispose; three
  `Timer.periodic` countdowns all cancel in `dispose()`; two
  `AnimationController`s dispose correctly; card-list loading is a single
  indexed query with no per-card N+1; QR generation is cached everywhere
  (Q-007's pattern followed consistently on the supplier side too); both
  `main.dart` files do nothing synchronous/slow before `runApp()`; no
  `StreamSubscription` usage anywhere in either app.

### 8. Legal / Privacy
**Lens:** does actual data handling still match what the Privacy Policy/ToS
promise — largely already covered by earlier session work; this role's job is
to catch drift, not redo that work.
**Check:** any data-collection path not disclosed; confirm no analytics/crash
reporting has been added without a matching policy update (`AppLogger` has
none as of this writing — verify that's still true); backup-destination claims
(local-only, not cloud) match code reality.
**Deliverable:** delta list against the existing Privacy Policy — should be
short or empty if nothing has drifted.

**Findings (2026-07-25) — Critical: 0, High: 0, Medium: 1, Low: 1:**

- **[Medium] Hashed device identifier is collected and P2P-transmitted,
  contradicting the Privacy Policy's explicit "no device identifiers"
  claim.** Same underlying issue as the App Store Compliance finding above
  (see the convergence note at the top of this doc for why the severities
  differ — this role frames it as documentation drift, App Store Compliance
  frames it as submission risk). `docs/legal/PRIVACY_POLICY.md` also makes a
  narrower claim that QR codes contain only "business ID, card ID, stamp
  count" — which omits the device ID field entirely. Recommend updating the
  docs (not the code — the feature is legitimate, hashed, and P2P-only,
  never reaches a server or the developer): add a carve-out sentence
  explaining the one-way-hashed per-device identifier and its fraud-
  prevention purpose, and revisit the App Review Packet's "Data Not
  Collected" answer before submission.
- **[Low] Accessibility Statement's hardcoded version number is stale**
  ("v1.0.2+8" vs. current `1.1.0+12`) — documentation-currency gap only, not
  contradicted by any code behavior. Bump as part of the next pre-submission
  doc pass; accept-as-risk is also reasonable if this file is intentionally
  refreshed only right before final submission.
- Checked with no drift found: no network calls anywhere in `source/*/lib`;
  no analytics/crash-reporting SDK in any pubspec; `backup_storage_service
  .dart` does only local file writes + the OS-native share/print sheet, no
  cloud API (the "optional encrypted cloud backup" mentioned in older
  architecture docs was never actually built, so there's nothing to
  disclose); `AppLogger` confirmed to have no remote sink, consistent with
  the recent stack-trace-drop decision; every pubspec dependency serves a
  functional purpose, no telemetry package present; backup-destination
  claims match code exactly; Secure Mode key storage via
  `flutter_secure_storage`/Keychain matches the documented claim.

## See also
- [REVIEW_MATRIX.md](REVIEW_MATRIX.md) — tracking table updated after each run
- [VULNERABILITIES.md](VULNERABILITIES.md) — security review findings (V-series)
- [FUNCTIONAL_REVIEW_2026-07-26.md](FUNCTIONAL_REVIEW_2026-07-26.md) — functional
  review findings (Q-series)
