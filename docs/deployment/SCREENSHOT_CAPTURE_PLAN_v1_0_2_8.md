# Screenshot Capture Plan (v1.0.2+8)

This is the execution plan for required App Store screenshot sets.

**Supersedes:** `SCREENSHOT_CAPTURE_PLAN_v1_0_0_6.md`. That plan assumed Apple's older three-tier requirement (6.7"/6.5"/5.5", 30 screenshots across both apps). Verified against Apple's current (2026) App Store Connect requirements — see Sources below — that assumption was outdated.

---

## Corrected Requirement

**Apple only requires screenshots for the largest current display size.** As of 2026:

- **6.9" display** (iPhone 16/15/14 Pro Max class): **1320 × 2868 px** — this is the one mandatory size
- Apple automatically scales this down to populate listings for every other supported iPhone size (6.7", 6.5", 5.5", etc.) — no separate screenshot sets are needed for those unless you specifically want custom-composed imagery per size
- iPad screenshots remain optional/separate (only needed if the app targets iPad as a distinct experience)

This means the total requirement is **5 screenshots per app (10 total)**, not 30. If a decision is later made to hand-craft additional device-specific screenshots (e.g. for marketing polish), that's an enhancement, not a submission requirement.

**Source:** [MobileAction — Apple App Store screenshot sizes & guidelines (2026)](https://www.mobileaction.co/guide/app-screenshot-sizes-and-guidelines-for-the-app-store/) — "In 2026 you only need to supply screenshots for the largest display in each family: the 6.9-inch iPhone. Apple then automatically scales those source images down to populate listings on smaller and older devices." Cross-verify directly in App Store Connect's screenshot upload UI when you get there, since Apple does revise these policies.

---

## Capture Method: Physical Device

Rather than simulators, capture directly on a **physical iPhone 16 Pro Max** (or 15/14 Pro Max — all share the 1320×2868 native resolution), which the developer already owns. This sidesteps two real gaps found while evaluating a simulator-based approach:

1. No tap/UI automation tooling is installed in the dev environment (no `idb`, `cliclick`, or `integration_test` package) — multi-step interactive flows (create business → issue card → switch apps → scan QR → stamp) would need to be driven by hand regardless.
2. Older device-class simulators (6.5"/5.5") are no longer bundled with current Xcode — moot now that only the 6.9" size is required, and a physical device gives that resolution natively with zero simulator/scaling ambiguity.

**Process:**
1. Install both apps on the physical device (via Xcode run or TestFlight build).
2. Create realistic test data by hand through normal app usage (a test business, a partially-stamped card, a complete/redeemable card) — quick given the flows are short.
3. Navigate to each of the 5 screens per app below.
4. Capture with the device's native screenshot shortcut (Side button + Volume Up).
5. AirDrop or otherwise transfer the resulting PNGs to the Mac for verification/organization.

---

## Customer App Shot List (Order)

**Corrected 2026-07-20:** screen 5 originally said "Settings / transaction history." There is no Settings-level history screen — a 92-line "activity history" section was deliberately removed from `customer_settings.dart` on 2026-07-03 (`6f1ce7a: refactor: remove customer settings activity history and duplicate app info`). The only history view that exists is the per-card **Stamp History**, shown scrolled within Card Detail. Corrected below.

1. Wallet home with active cards (mixed progress states look best — a couple of active cards, at least one near-complete)
2. Card detail with partial progress (e.g. 4/7 or 9/10 stamps)
3. QR scanner ready state
4. Redemption / redeemed-card confirmation — Express Mode's redemption is an honesty/trust-based scheme (like a paper punch card), so the "Redeem Reward? Have you received your reward from the supplier?" confirmation dialog is an accurate, intentional representation of the flow, not a QR-display screen
5. Card Detail scrolled to Stamp History (not a Settings screen — see correction above)

## Supplier App Shot List (Order)

**Corrected 2026-07-20:** the original plan called for an "Analytics / statistics dashboard" screenshot. There is no dashboard screen — the actual feature is 3 lifetime counters (Issued/Stamped/Redeemed) shown inline on the home screen header, and only when the business is in Secure Mode (`supplier_home.dart:150-162`). Rather than force a Secure Mode detour for one screenshot, swapped it for a second backup/clone shot, since that feature works in both modes.

1. Business configuration / home
2. Issue Card QR screen
3. Stamp issuance flow (denomination picker visible)
4. Recovery backup screen
5. Clone Device screen

**Note on screens 4 and 5 (2026-07-20):** both show live, real QR codes (Recovery Backup is "No Expiry," Clone Device expires in 5 minutes). Initially flagged as a key-exposure risk, but reconsidered: each business's key is randomly generated and unique to that business at setup. These screenshots use a disposable test business ("Coffee O'Clock") created solely for this purpose, with no real customers, no real rewards, and no shared server for the key to unlock access to (P2P/local-only architecture) — so a leaked key has no real victim. This would only matter if the same business identity were later reused for actual operation, in which case generate a fresh key at that point rather than reusing this one.

---

## Capture Standards

- Use the same visual data story across both apps (consistent branding, realistic but clearly fictional business names).
- No debug banners, development artifacts, or low-battery/notification clutter in the status bar.
- No text truncation.
- No confidential or real personal data visible (all test data should be obviously fictional).

---

## Naming Convention

Single size now, so the sequence number and screen name are all that's needed:

```
customer_01_home.png
customer_02_card_detail.png
customer_03_scanner.png
customer_04_redeem_qr.png
customer_05_history.png

supplier_01_home.png
supplier_02_issue_card.png
supplier_03_stamp_issuance.png
supplier_04_backup.png
supplier_05_clone_device.png
```

Destination once transferred to the Mac: `screenshots/customer_app/` and `screenshots/supplier_app/` (already created locally, and `/screenshots/` is in `.gitignore` — this is a local staging area for the App Store Connect upload, not something that gets committed).

---

## QA Checklist Before Upload

**Completed 2026-07-20** — all 10 files verified in `screenshots/customer_app/` and `screenshots/supplier_app/`:

- [x] Exactly 1320 × 2868 px — confirmed on all 10 files via `sips`
- [x] Correct sequence order (1 to 5) per app
- [x] No clipping/truncation
- [x] No inconsistent branding/text — two filenames were corrected (`customer_01`/`customer_02` were mislabeled/malformed on initial transfer, fixed to match actual content)
- [x] No confidential data visible — backup/clone QR codes reviewed and accepted as low-risk (disposable test business, see note above)
- [x] Consistent status bar — acceptable as-is (charging icon/muted bell present but not disqualifying)

**Issues found and fixed during QA:**
- `customer_01_.homePNG.PNG` → renamed to `customer_01_home.PNG` (malformed filename from transfer)
- `customer_02_issue_card.PNG` → renamed to `customer_02_card_detail.PNG` (content was card detail, not issue-card — "issue card" isn't even a customer-app concept)
- `customer_03_scanner.PNG` → background (real desk/keyboard/monitor, needed to demonstrate rotation controls since the scanner auto-captures too fast to screenshot mid-scan) blurred with a feathered mask via Pillow, keeping the header, scan-target square, rotation buttons, and instruction text sharp. Backed up before editing (a first attempt was overwritten without a backup and had to be redone from a re-transferred original — keep backups before any in-place image edit).
- `customer_05_history.PNG` → recaptured; the original had "◀ Photos" navigation chrome bled in from being screenshotted while viewing inside the Photos app rather than captured live from the app.

---

## Upload Checklist

- [ ] Customer app: 5 screenshots uploaded to the 6.9" slot in App Store Connect
- [ ] Supplier app: 5 screenshots uploaded to the 6.9" slot in App Store Connect
- [ ] Preview checked in App Store Connect before save (confirm Apple's auto-scaled smaller-device previews still look correct — text/UI shouldn't become illegible when scaled down)
