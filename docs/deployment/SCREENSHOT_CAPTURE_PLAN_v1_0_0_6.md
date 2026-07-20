# Screenshot Capture Plan (v1.0.0+6) — SUPERSEDED

**⚠️ This document is superseded by [`SCREENSHOT_CAPTURE_PLAN_v1_0_2_8.md`](SCREENSHOT_CAPTURE_PLAN_v1_0_2_8.md).**

It was written against an outdated understanding of Apple's App Store screenshot requirements (the 6.7"/6.5"/5.5" three-tier system). As of 2026, Apple only requires screenshots for the largest display size (6.9", 1320×2868) and auto-scales them for all other device listings — see the current doc for the corrected, verified requirement and capture method. Kept here for historical reference only.

---

This is the execution plan for required App Store screenshot sets.

---

## Device Assignment

| Screen Size | Device | Type | Resolution |
|-------------|--------|------|-----------|
| 6.7" | iPhone 16 Pro Max | Physical | 1290 x 2796 |
| 6.5" | iPhone 14 Pro | Simulator | 1242 x 2688 |
| 5.5" | iPhone SE (3rd gen) | Simulator | 1242 x 2208 |
| 12.9" (optional) | iPad Pro | Physical | 2048 x 2732 |

## Required Output

Per app, provide 15 screenshots total:
- 6.7 inch: 5 screenshots (1290 x 2796)
- 6.5 inch: 5 screenshots (1242 x 2688)
- 5.5 inch: 5 screenshots (1242 x 2208)

Optional:
- 12.9 inch iPad: 5 screenshots (2048 x 2732)

Total required across both apps: 30 screenshots.

---

## Customer App Shot List (Order)

1. Wallet home with active cards
2. Card details with partial progress
3. QR scanner ready state
4. Redemption QR displayed (complete card)
5. Transaction history / activity view

---

## Supplier App Shot List (Order)

1. Business configuration/home
2. Issue card QR screen
3. Stamp issuance flow
4. Analytics dashboard
5. Backup or clone workflow screen (no sensitive key data visible)

---

## Capture Standards

- Use same visual data story across all three sizes.
- Do not include debug banners or development artifacts.
- Keep status bar clean and consistent.
- Ensure no text truncation at safe areas.
- Avoid exposing personal or sensitive data.

---

## Naming Convention

Use this file naming pattern:

- customer_67_01_home.png
- customer_67_02_card_detail.png
- customer_67_03_scanner.png
- customer_67_04_redeem_qr.png
- customer_67_05_history.png

Repeat for:
- customer_65_XX_*.png
- customer_55_XX_*.png
- supplier_67_XX_*.png
- supplier_65_XX_*.png
- supplier_55_XX_*.png

---

## QA Checklist Before Upload

- [ ] Correct dimensions for each set
- [ ] Correct sequence order (1 to 5)
- [ ] No clipping/truncation
- [ ] No inconsistent branding/text
- [ ] No confidential data visible
- [ ] Same narrative flow across all sizes

---

## Upload Checklist

- [ ] Customer 6.7 set uploaded
- [ ] Customer 6.5 set uploaded
- [ ] Customer 5.5 set uploaded
- [ ] Supplier 6.7 set uploaded
- [ ] Supplier 6.5 set uploaded
- [ ] Supplier 5.5 set uploaded
- [ ] Preview checked in App Store Connect before save
