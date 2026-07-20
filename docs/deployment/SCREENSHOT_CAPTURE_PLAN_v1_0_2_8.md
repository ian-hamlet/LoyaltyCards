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

1. Wallet home with active cards (mixed progress states look best — a couple of active cards, at least one near-complete)
2. Card detail with partial progress (e.g. 4/7 or 9/10 stamps)
3. QR scanner ready state
4. Redemption QR displayed (complete card, "Ready to Redeem")
5. Settings / transaction history

## Supplier App Shot List (Order)

1. Business configuration / home
2. Issue Card QR screen
3. Stamp issuance flow (denomination picker visible)
4. Analytics / statistics dashboard
5. Backup or Clone Device screen (confirm no real private key material is visible on screen — biometric prompt state is fine, the actual key/QR payload should not be captured)

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
supplier_04_analytics.png
supplier_05_backup.png
```

Suggested destination once transferred to the Mac: `screenshots/customer_app/` and `screenshots/supplier_app/` (new directories, not yet in the repo — screenshots themselves shouldn't be committed to git; treat this as a local staging area for the App Store Connect upload, add a `.gitignore` entry if the folder is created).

---

## QA Checklist Before Upload

- [ ] Exactly 1320 × 2868 px (verify with `sips -g pixelWidth -g pixelHeight <file>` after transfer)
- [ ] Correct sequence order (1 to 5) per app
- [ ] No clipping/truncation
- [ ] No inconsistent branding/text
- [ ] No confidential data visible (especially screen 5 of the Supplier app — backup/clone)
- [ ] Consistent status bar (no odd time/battery/signal artifacts)

---

## Upload Checklist

- [ ] Customer app: 5 screenshots uploaded to the 6.9" slot in App Store Connect
- [ ] Supplier app: 5 screenshots uploaded to the 6.9" slot in App Store Connect
- [ ] Preview checked in App Store Connect before save (confirm Apple's auto-scaled smaller-device previews still look correct — text/UI shouldn't become illegible when scaled down)
