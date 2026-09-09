# LoyaltyCards Business — Android Closed Testing Instructions

**For:** Google Play Closed Testing participants
**App:** LoyaltyCards Business (the "Supplier" app)
**Testing window:** 14 continuous days — **[start date] to [end date]**
**Daily time needed:** roughly 5–10 minutes
**You will need:** the Android device running LoyaltyCards Business (the
app under test), **plus a second device of your own** with the regular
LoyaltyCards (Customer Wallet) app installed — either platform, iOS or
Android, doesn't matter.

---

## Why this test exists, and why it's separate from the Customer Wallet test

This is a second, **independent** 14-day/12-tester closed test — it
doesn't piggyback on the Customer Wallet one you may already have
completed. Each app has its own Play Store listing, and Google's
requirement (12 testers opted in continuously for 14 days, for a personal
developer account) applies per app.

The Customer Wallet was tested first deliberately: it's the simpler app to
test (one device, a pre-made QR pack) and has the wider appeal, since
every shopper is a potential Customer Wallet user, while LoyaltyCards
Business is only relevant to the smaller number of businesses running a
loyalty scheme. This test is about the Business side specifically.

As before, LoyaltyCards Business is deliberately simple, so this is mostly
about **accruing the required testing time with real daily use** — you'll
be repeating the same routine most days. That's expected. If anything
looks genuinely wrong, though, see "Reporting Issues" below.

---

## Why this one needs two devices and two test businesses

Unlike the Customer Wallet test, there's no way to substitute a
pre-generated QR pack here — **generating QR codes live is the thing
being tested.** You'll play both roles yourself: the shop (this app, on
the device under test) and a shopper (your own second device, running the
ordinary Customer Wallet app).

You'll also set up **two separate test businesses** — one Express Mode,
one Secure Mode. The operation mode is chosen once per business and
**locked permanently** (there's no in-app way to convert one mode to the
other), so covering both modes means two businesses, not one switched
back and forth.

**The two businesses are tested in two back-to-back phases, not
alternated day by day** — see "Two Phases, Not Alternating Days" below
for why.

---

## Two Phases, Not Alternating Days

- **Phase 1 — Express (Days 1–7):** Express Test Shop, set up once on Day
  1 and left running for the whole week.
- **Phase 2 — Secure (Days 8–14):** Secure Test Shop, set up once at the
  start of Day 8 and left running for the rest of the test.

LoyaltyCards Business holds **one business at a time** — there's no
multi-business switcher in this app. Normally a business could reset
itself in-app ("Delete All Data") to start over, but that option is
**only available in debug builds**; the closed-testing build you're using
is a release build, so it isn't there. That means moving from Express to
Secure requires **uninstalling and reinstalling** the app.

Doing this as two phases — instead of alternating Express/Secure on
successive days — means that uninstall/reinstall happens **exactly once**
across the whole 14-day test, at the Phase 1 → Phase 2 boundary, instead
of thirteen times. Fewer uninstalls is a better test in its own right
(closer to how a real business actually uses the app — install once, keep
using it), and avoids a pattern of repeated uninstall/reinstall cycles
that could otherwise look unusual in Google's review of the test.

**Uninstalling doesn't affect your closed-test status.** Being "opted in"
to this closed test is tracked by Google against your account, separately
from whether the app happens to be installed on your device at any given
moment — the one uninstall/reinstall this test needs doesn't reset or
interrupt your participation.

---

## Backup and Clone — tested once, early, on the lower-stakes business

LoyaltyCards Business has two related recovery features, both worth
exercising for real during this test:

- **Create Recovery Backup** (Settings) — a backup with no expiry,
  intended as a business's long-term disaster-recovery safety net.
- **Clone to Another Device** (Settings) — a backup that expires after
  **5 minutes**, intended for setting up a second device while the
  original keeps working.

Both produce a QR code that the app's **Import Business** screen (choose
**"Recover Existing Business"** on first launch) reads back in exactly
the same way — the only difference is that a Clone QR is checked against
its 5-minute expiry and a Recovery Backup isn't. Restoring from either one
also restores the same underlying business (name, keys, stamps required,
brand color) — see the note below on what doesn't come back.

Rather than adding extra uninstall cycles to exercise both separately,
**Day 1's one-time setup tests Clone directly** (since it needs an
uninstall/reinstall to prove the restore actually works, not just that
the QR was generated) **on Express Test Shop** — the simpler, lower-stakes
business. Because both restore paths go through the same import code,
successfully restoring via Clone is good evidence the Recovery Backup
would work the same way if it were ever needed for real. The Recovery
Backup is still created and saved on Day 1, exactly as a real business
would keep one, but doesn't need a second restore cycle to prove itself
during this test.

> [!NOTE]
> Restoring a business (either way) resets its **icon** to the default
> and its **stamp scan cooldown** to the app's default — the backup format
> doesn't carry those two fields. Everything else restores correctly.
> This is a known, already-tracked gap, not something to report as a new
> issue.

---

## Phase 1, Day 1: One-Time Setup

Do this once, at the very start of the test.

### 1. Install both apps

- Install **LoyaltyCards Business** from the Play Store closed-testing
  link: **[insert Play Console opt-in / install link here]**
- On your second device, install the ordinary **LoyaltyCards** (Customer
  Wallet) app from whichever store applies to that device (App Store or
  Play Store) — if you already have it from the earlier Customer Wallet
  test, that's fine, keep using it.

### 2. Create Express Test Shop

On first launch, choose **Create New Business** and set it up with:

| Setting | Value |
|---|---|
| Business Name | `Express Test Shop` |
| Operation Mode | **Express** |
| Stamps Required | `5` |
| Icon / Brand Color | any |

### 3. Try editing the business once

Open **Settings** and change the business's **icon** and **brand color**
once (Business Name and Stamps Required are also editable). Only
**Operation Mode** is permanently locked — that's expected, not a bug if
you can't change it.

### 4. Add the card to your Customer Wallet device

Home → **Issue Card**, scan the QR with your Customer Wallet device, so
Express Test Shop's card is in your wallet ready for the daily routine.

### 5. Test Clone to Another Device, and prove the restore works

1. **Settings → Clone to Another Device.** This shows a QR code valid for
   5 minutes — leave this screen open (or keep the app in the foreground)
   until step 3 below.
2. **Uninstall** LoyaltyCards Business, then **reinstall** it from the
   Play Store link.
3. On first launch, choose **Recover Existing Business** and scan the
   Clone QR from step 1 (you have 5 minutes from when it was generated —
   if it's expired, uninstall/reinstall once more and generate a fresh
   one). Confirm the restore screen shows **Express Test Shop** with the
   correct name and stamp count before confirming **Restore This
   Business**.

You should now be back on Express Test Shop, restored via Clone, with the
same card still valid on your Customer Wallet device (same keys — that's
the point of the test).

### 6. Create the Recovery Backup

**Settings → Create Recovery Backup** (needs Face ID/Touch ID/fingerprint
or your device passcode). Save the result somewhere durable — email it to
yourself, save to Photos, or a cloud drive — named clearly
(`express-test-backup`). You won't need to restore from this during the
test (step 5 already proved the restore mechanism works), but keep it
saved as you would for a real business.

> [!WARNING]
> **Always choose "Recover Existing Business" when restoring, never
> "Create New Business," if a business already has a saved backup.**
> Your Customer Wallet device's test card is cryptographically tied to
> the specific key pair Express Test Shop was created with. Accidentally
> creating a **brand-new** business with the same name instead of
> restoring the real one gives it different keys — the card on your
> Customer Wallet device will stop validating against it, and you'd need
> to delete that card and start over.

That's the end of one-time setup. From here through the end of Day 7, no
further uninstalls are needed — just the daily routine below.

---

## Phase 1 (Days 1–7): Express Test Shop daily routine

Express Mode needs no live back-and-forth for stamping — you generate a
QR, your Customer Wallet device scans it, done.

1. In LoyaltyCards Business, go to **Generate QR** and create a new stamp
   QR with the count set to **6** (one more than the 5 required — this
   fills *and* overflows the card in a single scan).
2. On your Customer Wallet device, scan that QR. Confirm the card shows
   as complete, and that a new (near-empty) card was created for the
   overflow.
3. On the completed card in Customer Wallet, tap **Redeem Reward**, then
   confirm **Yes, Redeem**. This is Express Mode's redemption — a
   self-serve confirmation entirely on the Customer Wallet side, with
   **no QR code and nothing to do in LoyaltyCards Business**. That's the
   key difference from Secure Mode's redemption in Phase 2, which does
   need a live scan exchange — see below.

Do this once per day, Days 1 through 7.

---

## Phase 2, Day 8: Switch to Secure Test Shop

This is the test's **one and only other uninstall**.

1. **Uninstall** LoyaltyCards Business, then **reinstall** it from the
   Play Store link.
2. On first launch, choose **Create New Business** (not "Recover Existing
   Business" — Secure Test Shop doesn't exist yet) and set it up with:

| Setting | Value |
|---|---|
| Business Name | `Secure Test Shop` |
| Operation Mode | **Secure** |
| Stamps Required | `3` (the minimum allowed — keeps each day's live round-trips short) |
| Icon / Brand Color | any |

3. Home → **Issue Card**, scan the QR with your Customer Wallet device,
   so Secure Test Shop's card is in your wallet too (your Express Test
   Shop card stays in your wallet unchanged, even though the business
   itself is no longer installed).

You won't need Express Test Shop again for the rest of the test, so
there's no restore to do here — just set up Secure fresh and move into
its daily routine.

---

## Phase 2 (Days 8–14): Secure Test Shop daily routine

Secure Mode is a genuine live exchange, both for stamping **and** for
redemption — this two-way, double-scan handshake is the main functional
difference from Express Mode, and is exactly what this phase is testing.
Don't skip repeats even though it's the same routine each day.

### Stamping (repeat 4 times, since Stamps Required is 3)

1. In LoyaltyCards Business, go to **Stamp Card**.
2. Scan your Customer Wallet device's card QR (the customer side shows a
   request code — scan that).
3. LoyaltyCards Business then shows a freshly signed stamp QR on screen —
   scan *that* with your Customer Wallet device to actually receive the
   stamp. This is the double-scan: the customer's request, then the
   supplier's signed response.
4. Check the card: after the 4th round it should show as overflowed (one
   stamp past the 3 required), with a new card created for the extra.

### Redeeming — the double-scan verification

On the completed (pre-overflow) card, once it's full, Customer Wallet
automatically shows a **redemption request QR** in place of the usual
card QR — nothing to tap, it appears as soon as the card is complete.

1. In LoyaltyCards Business, go to **Redeem Card** and scan that QR. The
   app validates the entire stamp chain before accepting it — this
   validation is real and worth watching succeed each time, unlike
   Express Mode where there's nothing to check.
2. Once validated, LoyaltyCards Business shows its **own** signed QR on
   screen — a confirmation of the redemption for the customer to keep as
   proof.
3. Back on your Customer Wallet device, tap **Scan Redemption** on the
   completed card and scan that QR. This closes the loop: the card shows
   as redeemed, and a new card is created for next time.

That's the double scan: customer → supplier (redemption request), then
supplier → customer (signed confirmation). Both scans are required for
the redemption to complete on the Customer Wallet side.

Do this once per day, Days 8 through 14.

---

## Reporting Issues

Email **ian.hamlet@dotconnected.com** with:

- Which business (Express/Secure), which step, and which day
- What you expected vs. what happened
- A screenshot if possible

We aim to respond within 48 hours.

---

## Quick Daily Checklist

### Phase 1 — Express Test Shop (Days 1–7)

| Day | Setup (Day 1 only) | Fill + Overflow | Redeem |
|---|:---:|:---:|:---:|
| 1 | ☐ Create business, edit icon/color, add card, Clone + restore test, Recovery Backup | ☐ | ☐ |
| 2 | — | ☐ | ☐ |
| 3 | — | ☐ | ☐ |
| 4 | — | ☐ | ☐ |
| 5 | — | ☐ | ☐ |
| 6 | — | ☐ | ☐ |
| 7 | — | ☐ | ☐ |

### Phase 2 — Secure Test Shop (Days 8–14)

| Day | Setup (Day 8 only) | Stamp ×4 (double-scan each) | Redeem (double-scan) |
|---|:---:|:---:|:---:|
| 8 | ☐ Uninstall/reinstall, Create New Business, add card | ☐ | ☐ |
| 9 | — | ☐ | ☐ |
| 10 | — | ☐ | ☐ |
| 11 | — | ☐ | ☐ |
| 12 | — | ☐ | ☐ |
| 13 | — | ☐ | ☐ |
| 14 | — | ☐ | ☐ |

---

_LoyaltyCards Business Android Closed Testing — thank you for helping us reach general availability._
