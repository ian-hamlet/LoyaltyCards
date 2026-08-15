# Device Test Plan - v2.0.1+20

**Still applies to v2.0.2+21:** v2.0.1+20 was never uploaded (Transporter flagged its deployment target before that happened) - v2.0.2+21 carries the identical app-facing changes plus an invisible `IPHONEOS_DEPLOYMENT_TARGET` fix, so every test step below is unchanged. Not renamed to avoid duplicating the file for a build-config-only difference.

**Purpose:** Verify the CRASH-001 print-crash fix and do a light regression pass over the other changes in this release, before rebuilding and resubmitting to Apple.

**Apps under test:** Supplier App (LoyaltyCards Business) and Customer App (LoyaltyCards Customer Wallet)

**Related:**
- [`CRASH-001-stamp-print-race-condition.md`](../project-management/CRASH-001-stamp-print-race-condition.md) - full crash analysis and fix details
- [`UI-001-how-it-works-dark-mode-contrast.md`](../project-management/UI-001-how-it-works-dark-mode-contrast.md) - dark mode fix details
- [`CHANGELOG.md`](../../CHANGELOG.md) - `[2.0.1+20]` entry

---

## Priority Devices

The original crash and the App Review rejection were reported on two different but related devices - both are worth prioritizing if you can get hold of them, since we don't know for certain the crash is device-specific rather than just more likely to surface there:

| Priority | Device | OS | Why |
|---|---|---|---|
| 1 | iPad Air 11-inch (M2) - model `iPad15,3` | iPadOS 26.6 | Original crash report device (App Store Connect crash analytics) |
| 1 | iPad Air 11-inch (M3) | iPadOS 26.6 | App Review's own test device (rejection notes) |
| 2 | Any other iPad, same OS line (26.x) | iPadOS 26.x | Rules out "M2/M3-specific" as a factor |
| 3 | Any iPhone | Current iOS | Lower priority - the crash report devices were both iPads, and the print flow is identical on iPhone, but worth a pass if a device is easy to grab |

If none of the priority-1 devices are available, testing on whatever iPad is on hand is still useful - the fix (a re-entrancy guard + data validation) isn't expected to be device-specific, so a clean pass on any device is meaningful signal, just not conclusive on its own.

---

## Part 1: CRASH-001 Verification (Primary Focus)

**What we're checking:** that the fix actually installed correctly and the app can no longer be made to fire two concurrent print/share jobs, on a real device. This can't be verified by automated tests alone (they run against a mocked native layer) - this is the real-device confirmation that was missing before.

**Important framing:** this is a timing race. Not reproducing a crash doesn't prove the bug is gone (it was never reliably reproducible even before the fix - see the CRASH-001 doc). What we're really checking here is that the *guard visibly works* (button disables, can't be double-tapped) - that's the deterministic, checkable part. Treat "no crash after heavy tapping" as supporting evidence, not proof.

### Test 1a: Stamp Setup Print button (the confirmed original crash site)

**Screen:** Supplier app → Express/Simple Mode business → "Generate Stamp QR Code" (Stamp Setup)

1. Generate a stamp QR code (tap "Generate QR Code", wait for it to appear).
2. Rapidly double/triple-tap the **Print** button.
3. **Expected:** the button visibly disables (dims / shows a small spinner in place of the print icon) the instant it's tapped, and stays disabled until the print sheet finishes opening. Repeated taps during that window should do nothing.
4. **Fail condition:** app crashes, freezes, or the button stays tappable while a print job is clearly still starting up.
5. Repeat 5-10 times - try tapping at different moments relative to the sheet's opening animation (before it starts, mid-animation, right as it appears).

### Test 1b: Stamp Setup Share QR button

Same screen, same steps, but the **Share QR** button instead. Same expected behavior (disables, spinner, re-enables once the share sheet opens or the action completes).

### Test 1c: Recovery Backup screen - all three buttons

**Screen:** Supplier app → Settings (or onboarding) → Recovery Backup

Repeat the rapid-tap test independently on each of:
- **Print Backup**
- **Share via Email**
- **Save to Files**

Each should independently disable itself while its own job is in flight (tapping Print shouldn't disable Share, and vice versa).

### Test 1d: Issue Card screen - both buttons

**Screen:** Supplier app → Express/Simple Mode business → Issue Card

Repeat the rapid-tap test on:
- **Print**
- **Share**

### Test 1e: Malformed-PDF path (defense-in-depth, not expected to be triggerable manually)

This one can't really be forced from the UI - it's the fix for a scenario (corrupted/empty PDF generation output) that isn't reachable through normal use. Nothing to actively test here; just note if *any* print action ever produces an unexpected "Failed to print" error with no obvious cause - that would be this path firing, and worth capturing the exact steps that led to it.

### If a crash *does* happen during any of the above

1. Note the exact device, OS version, and which button/screen.
2. Immediately pull the crash log: Settings → Privacy & Security → Analytics & Improvements → Analytics Data → find the entry starting `Runner-<date>`.
3. Save/export that file before doing anything else - don't just note "it crashed."
4. Compare against the original crash signature (`CGPDFDocumentGetNumberOfPages` / `EXC_BAD_ACCESS`) - if it's a different exception type or stack, that's a *new* finding, not a recurrence of CRASH-001.

---

## Part 2: Light Regression Pass (Other 2.0.1+20 Changes)

Quick checks, not exhaustive - these are lower-risk changes (copy and color only, no logic changes) but worth a glance since they touch user-facing screens.

### Test 2a: Dark mode contrast (UI-001)

**Screens:** "How It Works" in both apps.

1. Switch the device to Dark Mode (Settings → Display & Brightness, or Control Center).
2. Open How It Works in the supplier app - check the 3 info panels after Step 5 (Secure & Private / Dynamic QR Codes / Works Offline) have clearly readable text against their backgrounds.
3. Open How It Works in the customer app - check the 4 info panels after Step 4 (Your Privacy Protected / Secure & Verified / Dynamic QR Codes / Works Anywhere).
4. Switch back to Light Mode and confirm both screens still look correct there too (make sure the fix didn't regress the light-mode appearance).

### Test 2b: Express Mode redemption copy

**Screens:** Customer app → a complete (not yet redeemed) Express/Simple Mode card.

1. Open the complete card - confirm the instruction text reads "Show your supplier this completed card. Once they're ready, tap Redeem below."
2. Tap **Redeem Reward** - confirm the dialog reads "Tapping Redeem confirms with your supplier that you're claiming your reward now." with Not Yet / Yes, Redeem buttons.
3. Tap **Yes, Redeem** - confirm the resulting "Card Redeemed!" screen includes "Show this to your supplier to confirm."
4. No functional check needed beyond reading the text - nothing about the redemption logic changed.

---

## Reporting Back

For each test, a simple pass/fail plus device/OS is enough:

```
Test 1a (Stamp Setup Print) - iPad Air M2, iPadOS 26.6 - PASS (button disabled correctly, no crash after 10 rapid taps)
Test 1b (Stamp Setup Share) - iPad Air M2, iPadOS 26.6 - PASS
...
```

If everything in Part 1 passes cleanly across at least one priority-1 device, that's enough confidence to proceed with the resubmission - see the Follow-Up Recommendations in the CRASH-001 doc for what's still worth doing after that (filing upstream against the `printing` package, monitoring App Store Connect crash analytics after release).
