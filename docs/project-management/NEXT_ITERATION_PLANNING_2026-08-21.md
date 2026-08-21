# Next Iteration Planning — Inputs Index (2026-08-21)

**Purpose:** an index of the supporting documents brought in from earlier Claude sessions (drafted elsewhere, reviewed and consolidated into this repo 2026-08-21), covering a range of possible next steps across engineering, product, and marketing. **These are unphased, unprioritized inputs for a future planning/phasing discussion — not a committed roadmap.** Nothing listed here has been scheduled, sequenced, or sized yet; that's the next conversation once these have been reviewed.

Originals lived in `docs/review/` (a temporary drop folder) and have now been consolidated into their permanent homes below - `docs/review/` can be deleted once this consolidation is confirmed correct.

## 1. Cloudflare migration completion (near-term, mostly mechanical)

**[`docs/project-management/CLOUDFLARE_MIGRATION_COMPLETION_PLAN.md`](CLOUDFLARE_MIGRATION_COMPLETION_PLAN.md)**

The public site is already live on Cloudflare Pages; App Store Connect's URL fields still point at the old GitHub Pages host for both apps. A 5-step checklist to close this out, deliberately timed to ride along with the next release rather than ship as a standalone metadata change.

## 2. Feature: editable Express Mode scan cooldown (small, self-contained)

**[`docs/project-management/FEATURE_PLAN_SCAN_INTERVAL_EDITABLE.md`](FEATURE_PLAN_SCAN_INTERVAL_EDITABLE.md)**

Currently the Express Mode scan cooldown can only be set once, at business onboarding. This plan makes it editable afterward from **Supplier app** Settings (confirmed scope 2026-08-21 - the business owner editing their own cooldown, not a customer-facing control), mirroring the existing `stampsRequired` fix-up pattern. Confirmed cheap and safe — the value isn't baked into issued cards.

## 3. Positioning update: App Store metadata & copy (marketing-led, needs a decision before engineering)

**[`docs/marketing/POSITIONING_UPDATE_PLAN_2026-08-21.md`](../marketing/POSITIONING_UPDATE_PLAN_2026-08-21.md)**

Draft subtitle/promotional-text/description changes for both apps, pushing the "no server, no data, ever" architectural claim harder than the current "no signup" convenience framing. Grounded in the competitive assessment below. Draft only — needs review and a decision before it becomes a new metadata packet.

## 4. Competitive assessment (reference document, retained)

**[`docs/marketing/COMPETITIVE_ASSESSMENT_2026-08-21.md`](../marketing/COMPETITIVE_ASSESSMENT_2026-08-21.md)**

Not an action plan — a standing reference. Maps LoyaltyCards against five classes of App Store loyalty-card competitors and concludes the real differentiation is architectural (true P2P, zero backend, zero personal data) rather than the stamp-card mechanic itself. Source material for #3 above and for future marketing material.

## 5. Generalization & open protocol (larger, longer-horizon, two docs merged into one)

**[`docs/project-management/GENERALIZATION_AND_OPEN_PROTOCOL_PLAN.md`](GENERALIZATION_AND_OPEN_PROTOCOL_PLAN.md)**

The biggest-picture item here. Explores widening the app beyond "stamps" using the same underlying signed-QR-claim primitive: standalone barcode-wallet mode, generic claim types (vouchers, check-ins), a published open wire-format spec, rewarded referrals, and multi-business "zone" cards with a proper second trust tier. Explicitly mission-constrained (no recurring server cost, ever) and ranked by leverage - the standalone wallet mode is flagged as the strongest candidate to go first if any of this is picked up, since it removes the two-sided cold-start problem.

## 6. Code quality assessment (engineering health, informs how the above gets built)

**[`docs/quality/CODE_QUALITY_REVIEW_2026-08-21.md`](../quality/CODE_QUALITY_REVIEW_2026-08-21.md)**

Independent read-only review of `develop` @ `b0f6476`. Verdict: moderate, targeted refactor, not a rewrite. Five oversized screen widgets fuse UI with business/crypto logic; no CI gate currently runs `flutter analyze`/`flutter test` automatically. Recommends a CI safety net first, then a scoped extraction effort on the largest screens. Relevant context for phasing #2 and #5 above - a codebase change of that shape is exactly what benefits from the CI gate and extraction pattern this review recommends being in place first.

---

## Decided sequencing (2026-08-21)

Phasing has been discussed and decided - this supersedes the earlier unphased bucketing (kept below for the reasoning trail). Order:

### 1. This release — v2.2.0+30, in progress now

1. **Editable Express Mode scan cooldown** (#2) - Supplier app Settings. ✅ Built 2026-08-21, tested, merged to `develop` (`cad0851`) - see `FEATURE_PLAN_SCAN_INTERVAL_EDITABLE.md`.
2. **Version bumped to 2.2.0+30** (minor bump - a genuine capability increase) - ✅ done 2026-08-21, all 6 version-tracking files updated (`pubspec.yaml` x3, `pubspec.lock` x2, `version.dart`), plus `RELEASES.md`, `CHANGELOG.md`, and `APP_STORE_SUBMISSION_CHECKLIST.md`. New metadata packet created: `docs/deployment/APP_STORE_METADATA_PACKET_v2_2_0_30.md`.
3. **Positioning/metadata update** (#3) - ✅ Applied 2026-08-22 to `APP_STORE_METADATA_PACKET_v2_2_0_30.md` (both apps' Subtitle/Promotional Text/Description, plus the Supplier app's Keywords swap) - see `docs/marketing/POSITIONING_UPDATE_PLAN_2026-08-21.md`.
4. Build, submit to TestFlight, and take through App Store review as v2.2.0+30.

**CI gate (#6 step 1): explicitly deferred, not declined.** Decision: test runs stay manual/on-demand for now rather than automated on every push - revisit later if that stops being manageable.

### 2. After Apple approves this release

5. **Complete the Cloudflare migration checklist** (#1) - update the 4 ASC URL fields to the new Cloudflare host, tick off the 5 pending checklist items, then disable GitHub Pages. This was always gated on "ride along with the next release" (see `CLOUDFLARE_MIGRATION_COMPLETION_PLAN.md`) - this release is that vehicle, since the cooldown feature + metadata update will already exercise the full build/submit/approve pipeline once. This is its own milestone/checkpoint once done, not a separate app version.

### 3. Future — unscheduled, explore later

6. **Code quality refactor** (#6) - the screen-extraction work and everything else in the review.
7. **Generalization ideas** (#5) - the standalone wallet mode, generic claim types, open protocol spec, and zone certificates.

Both of these remain fully described in their own docs, unscheduled and unprioritized relative to each other, for whenever they're picked up.

Not a recommendation on sequencing within each bucket - just a first pass at what's actually ready vs. what's blocked on a decision vs. what's genuinely a later-stage bet, for when phasing gets discussed properly.
