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

## Why this one needs two devices and two business profiles

Unlike the Customer Wallet test, there's no way to substitute a
pre-generated QR pack here — **generating QR codes live is the thing
being tested.** You'll play both roles yourself: the shop (this app, on
the device under test) and a shopper (your own second device, running the
ordinary Customer Wallet app).

You'll also set up **two separate test businesses** — one Express Mode,
one Secure Mode. The operation mode is chosen once per business and
**locked permanently** (changing it later requires a full reset that
deletes that business's data), so covering both modes means two
businesses, not one switched back and forth.

---

## Switching businesses: uninstall, reinstall, restore

LoyaltyCards Business holds **one business at a time** — there's no
multi-business switcher in this app. Normally a business could reset
itself in-app ("Delete All Data") to start over, but that option is
**only available in debug builds** — the closed-testing build you're
using is a release build, so it's not there. That means the only way to
move from "Express Test Shop" to "Secure Test Shop" (or back) is:

1. **Uninstall** LoyaltyCards Business from your device.
2. **Reinstall** it from the Play Store closed-testing link.
3. On first launch, choose **"Recover Existing Business"** (never
   "Create New Business" once a business already has a saved backup) and
   scan/import that business's saved Recovery Backup.

This is genuinely useful, not just a workaround: it means the
**Recovery Backup / Restore** feature — the app's actual disaster-recovery
safety net — gets exercised for real, repeatedly, across the whole 14
days, rather than sitting untested. By the end of the test you'll have
restored a business from backup more times than most real businesses
ever will. That's a good outcome for this closed test, not a
consolation prize for a limitation.

**Uninstalling doesn't affect your closed-test status.** Being "opted in"
to this closed test is tracked by Google against your account, separately
from whether the app happens to be installed on your device at any given
moment — uninstalling and reinstalling as instructed below doesn't reset
or interrupt your participation.

---

## Day 1: One-Time Setup

Do this once, on your first day, before the daily routine begins.

### 1. Install both apps

- Install **LoyaltyCards Business** from the Play Store closed-testing
  link: **[insert Play Console opt-in / install link here]**
- On your second device, install the ordinary **LoyaltyCards** (Customer
  Wallet) app from whichever store applies to that device (App Store or
  Play Store) — if you already have it from the earlier Customer Wallet
  test, that's fine, keep using it.

### 2. Create, back up, and card up each test business in turn

You'll create both businesses one at a time, since only one can exist on
the device at once. Use these exact values for both (the specific numbers
don't matter technically, but using the same ones keeps everyone's test
consistent and easier to support):

| Setting | Express Test Shop | Secure Test Shop |
|---|---|---|
| Business Name | `Express Test Shop` | `Secure Test Shop` |
| Operation Mode | **Express** | **Secure** |
| Stamps Required | `5` | `3` (the minimum allowed — keeps Secure Mode's live round-trips short, see below) |
| Icon / Brand Color | any | any |

For **each** business in turn (Express first, then Secure), while it's
the one currently active on the device:

1. **Create New Business** and set it up with the values above.
2. Try the one-time edit check (see step 3 below) — a natural point to do
   it while you're already in the business's Settings.
3. Scan its Add Card QR (Home → **Issue Card**) with your Customer Wallet
   device, so that business's card is in your wallet ready for the daily
   routine.
4. **Settings → Create Recovery Backup** (needs Face ID/Touch ID/
   fingerprint or your device passcode). Save the result somewhere durable
   — email it to yourself, save to Photos, or a cloud drive — named
   clearly (`express-test-backup`, `secure-test-backup`).
5. **Uninstall** LoyaltyCards Business, then **reinstall** it from the
   Play Store link, ready for the next business (or, after Secure, ready
   for the final restore below).

After both businesses have been through steps 1–5, do one more restore to
land on the business Day 1 actually needs:

6. On first launch after the last reinstall, choose **Recover Existing
   Business** and import `express-test-backup` — Day 1 is an odd day
   (Express), per the alternation below.

You should now have two backup files saved somewhere safe, one card from
each business already in your Customer Wallet, and Express Test Shop
active on the device, ready for Day 1's routine.

### 3. Try editing a business once

Confirm the editable settings work: open **Settings** and change the
business's **icon** and **brand color** once (Business Name and Stamps
Required are also editable). Only **Operation Mode** is permanently
locked — that's expected, not a bug if you can't change it.

> [!WARNING]
> **Always choose "Recover Existing Business" when restoring, never
> "Create New Business," once a business already has a saved backup.**
>
> Your Customer Wallet device's test cards are cryptographically tied to
> the specific key pair each business was created with. If you accidentally
> create a **brand-new** business with the same name instead of restoring
> the real one, it will have different keys — the old cards on your
> Customer Wallet device will stop validating against it, and you'll need
> to delete those cards and start that business's test over. Always
> double-check the restored business shows the correct name and stamp
> count before continuing.

---

## Daily Routine — alternate modes on successive days

Test **one business per day**, alternating:

- **Odd days** (1, 3, 5, 7, 9, 11, 13) → **Express Test Shop**
- **Even days** (2, 4, 6, 8, 10, 12, 14) → **Secure Test Shop**

That's 7 full cycles of each mode across the 14 days.

**Start of every day except Day 1:** the business you need today isn't
the one currently on the device (you switched at the end of yesterday's
session, or the device already ended Day 1's setup on Express) — restore
it first: **uninstall LoyaltyCards Business, reinstall it, then Recover
Existing Business** using today's saved backup (`express-test-backup` on
odd days, `secure-test-backup` on even days). Confirm the restored
business's name and stamp count match before continuing.

### On an Express day

Express Mode needs no live back-and-forth for stamping — you generate a
QR, your Customer Wallet device scans it, done.

1. In LoyaltyCards Business (**Express Test Shop** restored/selected), go to
   **Generate QR** and create a new stamp QR with the count set to **6**
   (one more than the 5 required — this fills *and* overflows the card in
   a single scan).
2. On your Customer Wallet device, scan that QR. Confirm the card shows
   as complete, and that a new (near-empty) card was created for the
   overflow.
3. Back on the completed card in Customer Wallet, tap **Redeem**. In
   LoyaltyCards Business, confirm the redemption when prompted — this is
   the "customer shows you a completed card, you confirm" handshake, no
   QR involved for redemption in Express Mode.

### On a Secure day

Secure Mode is a genuine live exchange for **every single stamp** — this
is the functionality actually being tested, so don't skip repeats. With
Stamps Required set to 3, filling and overflowing takes 4 rounds.

Repeat the following **4 times**:

1. In LoyaltyCards Business (**Secure Test Shop** restored/selected), go to
   **Stamp Card**.
2. Scan your Customer Wallet device's card QR for this business (the
   customer side shows a request code — scan that).
3. The Business app then shows a freshly signed stamp QR — scan *that*
   with your Customer Wallet device to actually receive the stamp.
4. Check the card: after the 4th round it should show as overflowed (one
   stamp past the 3 required), with a new card created for the extra.

Then redeem: on the completed (pre-overflow) card in Customer Wallet, go
to redeem — this shows a QR. In LoyaltyCards Business, go to **Redeem**
and scan it; the app validates the entire stamp chain before confirming.
Unlike Express, this validation step is real and worth watching succeed
each time.

---

## Reporting Issues

Email **ian.hamlet@dotconnected.com** with:

- Which business (Express/Secure), which step, and which day
- What you expected vs. what happened
- A screenshot if possible

We aim to respond within 48 hours.

---

## Quick Daily Checklist

| Day | Business | Restore (uninstall/reinstall/recover) | Fill + Overflow | Redeem |
|---|---|:---:|:---:|:---:|
| 1 | Express Test Shop | *(done as part of Day 1 setup)* | ☐ | ☐ |
| 2 | Secure Test Shop | ☐ | ☐ | ☐ |
| 3 | Express Test Shop | ☐ | ☐ | ☐ |
| 4 | Secure Test Shop | ☐ | ☐ | ☐ |
| 5 | Express Test Shop | ☐ | ☐ | ☐ |
| 6 | Secure Test Shop | ☐ | ☐ | ☐ |
| 7 | Express Test Shop | ☐ | ☐ | ☐ |
| 8 | Secure Test Shop | ☐ | ☐ | ☐ |
| 9 | Express Test Shop | ☐ | ☐ | ☐ |
| 10 | Secure Test Shop | ☐ | ☐ | ☐ |
| 11 | Express Test Shop | ☐ | ☐ | ☐ |
| 12 | Secure Test Shop | ☐ | ☐ | ☐ |
| 13 | Express Test Shop | ☐ | ☐ | ☐ |
| 14 | Secure Test Shop | ☐ | ☐ | ☐ |

---

_LoyaltyCards Business Android Closed Testing — thank you for helping us reach general availability._
