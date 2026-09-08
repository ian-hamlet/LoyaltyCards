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

## Day 1: One-Time Setup

Do this once, on your first day, before the daily routine begins.

### 1. Install both apps

- Install **LoyaltyCards Business** from the Play Store closed-testing
  link: **[insert Play Console opt-in / install link here]**
- On your second device, install the ordinary **LoyaltyCards** (Customer
  Wallet) app from whichever store applies to that device (App Store or
  Play Store) — if you already have it from the earlier Customer Wallet
  test, that's fine, keep using it.

### 2. Create your two test businesses

In LoyaltyCards Business, set up two businesses with these exact values
(the specific numbers don't matter technically, but using the same ones
keeps everyone's test consistent and easier to support):

| Setting | Express Test Shop | Secure Test Shop |
|---|---|---|
| Business Name | `Express Test Shop` | `Secure Test Shop` |
| Operation Mode | **Express** | **Secure** |
| Stamps Required | `5` | `3` (the minimum allowed — keeps Secure Mode's live round-trips short, see below) |
| Icon / Brand Color | any | any |

*(If the app only lets you manage one business profile at a time, use
"Import/Switch Business" or the equivalent multi-business option in
Settings to hold both side by side — you'll be switching between them on
alternating days.)*

### 3. Try editing a business once

Before settling into the daily routine, confirm the editable settings
work: open **Settings** for either business and change its **icon** and
**brand color** once (Business Name and Stamps Required are also
editable). Only **Operation Mode** is permanently locked — that's
expected, not a bug if you can't change it.

### 4. Create a Recovery Backup for *each* business — important

For each of your two businesses: **Settings → Create Recovery Backup**
(this needs Face ID/Touch ID/fingerprint or your device passcode). Save
the resulting backup (QR image or PDF) somewhere durable — email it to
yourself, save to Photos, or a cloud drive. Name the files clearly, e.g.
`express-test-backup` and `secure-test-backup`.

> [!WARNING]
> **Do not uninstall LoyaltyCards Business, and do not use "Delete All
> Data" / factory-reset a business, at any point during the 14 days
> unless you immediately restore from your saved backup afterward.**
>
> Your Customer Wallet device's test cards are cryptographically tied to
> the specific key pair each business was created with. If you lose the
> app's data and create **brand-new** businesses instead of restoring,
> the old cards on your Customer Wallet device will stop validating
> against the new keys, and you'll need to delete those cards and start
> the whole test over.
>
> **If you ever do need to reinstall the app or switch devices:** open
> LoyaltyCards Business, choose **"Recover Existing Business"** during
> setup (not "Create New Business"), and scan or import the matching
> saved backup. Confirm the restored business shows the same name and
> stamp count as before, then carry on with the daily routine as normal.

### 5. Add both cards to your Customer Wallet device

On your second device's Customer Wallet app: scan **Express Test Shop**'s
Add Card QR (Home → **Issue Card** in the Business app), and do the same
for **Secure Test Shop**. You should now have one card from each business
in your wallet, ready for the daily routine below.

---

## Daily Routine — alternate modes on successive days

Test **one business per day**, alternating:

- **Odd days** (1, 3, 5, 7, 9, 11, 13) → **Express Test Shop**
- **Even days** (2, 4, 6, 8, 10, 12, 14) → **Secure Test Shop**

That's 7 full cycles of each mode across the 14 days.

### On an Express day

Express Mode needs no live back-and-forth for stamping — you generate a
QR, your Customer Wallet device scans it, done.

1. In LoyaltyCards Business (**Express Test Shop** selected), go to
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

1. In LoyaltyCards Business (**Secure Test Shop** selected), go to
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

| Day | Business | Setup done | Fill + Overflow | Redeem |
|---|---|:---:|:---:|:---:|
| 1 | Express Test Shop | ☐ | ☐ | ☐ |
| 2 | Secure Test Shop | | ☐ | ☐ |
| 3 | Express Test Shop | | ☐ | ☐ |
| 4 | Secure Test Shop | | ☐ | ☐ |
| 5 | Express Test Shop | | ☐ | ☐ |
| 6 | Secure Test Shop | | ☐ | ☐ |
| 7 | Express Test Shop | | ☐ | ☐ |
| 8 | Secure Test Shop | | ☐ | ☐ |
| 9 | Express Test Shop | | ☐ | ☐ |
| 10 | Secure Test Shop | | ☐ | ☐ |
| 11 | Express Test Shop | | ☐ | ☐ |
| 12 | Secure Test Shop | | ☐ | ☐ |
| 13 | Express Test Shop | | ☐ | ☐ |
| 14 | Secure Test Shop | | ☐ | ☐ |

---

_LoyaltyCards Business Android Closed Testing — thank you for helping us reach general availability._
