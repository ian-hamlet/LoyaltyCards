# LoyaltyCards Customer Wallet — Android Closed Testing Instructions

**For:** Google Play Closed Testing participants
**App:** LoyaltyCards (Customer Wallet)
**Testing window:** 14 continuous days — **[start date] to [end date]**
**Daily time needed:** roughly 5–10 minutes

---

## Why this test exists

Google requires at least **12 testers opted in continuously for 14 days**
before a personal developer account can apply for full Play Store release.
That's a fixed rule, not a judgement about how much there is to find in the
app — LoyaltyCards is deliberately simple (collect stamps, redeem a
reward), so this test is mostly about **accruing the required testing time
with real daily use**, not hunting for edge cases. You'll be repeating the
same routine every day for two weeks. That's expected — thank you for
bearing with the repetition.

If anything ever does look wrong, though, we absolutely want to hear about
it — see "Reporting Issues" below.

---

## How this fits together in real life

LoyaltyCards is two apps, not one:

- **LoyaltyCards Business** (the "Supplier" app) — installed by a shop.
  The shop owner sets up a stamp card (how many stamps, reward, branding),
  and the app produces QR codes: one for customers to add the shop's card
  to their wallet, and one for adding a stamp at each visit.
- **LoyaltyCards** (the "Customer Wallet" app — **what you're testing**) —
  installed by a shopper. They scan a shop's QR codes to add cards and
  collect stamps, and redeem a reward once a card is full.

Normally, testing the Customer Wallet properly would mean also running the
Business app on a second device to produce QR codes to scan. **This test
pack skips that step**: the QR codes in the provided PDF are pre-generated
exactly as the Business app would produce them, for six fictional test
shops. You only need the Customer Wallet app installed — scan the provided
codes as if a real shop had shown them to you at the till.

The one exception is **redeeming a reward**, which needs no QR code at
all in this mode — you just tap a button in the app once your card is
full, the same as a real shop visit.

---

## Before You Start (once, on day one)

1. Install **LoyaltyCards** from the Play Store closed-testing link:
   **[insert Play Console opt-in / install link here]**
2. Open the app once. No account, signup, or personal details are ever
   needed — that's by design, not something missing.
3. Have the **QR code test pack** (`express_test_pack.pdf`) open on a
   second screen, or printed. All six sheets are used every day.

---

## Daily Routine — repeat once per day, all 14 days

Every business is **Express Mode**, so every stamp scan works the same
way: no waiting on anyone else, just your phone and the printed/on-screen
QR code.

For **each of the six businesses** in the pack (Test Coffee, Green Grocer,
Riverside Deli, Sunny Bakery, Willow Spa, City Books):

1. **Add the card.** Open the scanner (camera icon) and scan that
   business's **Add Card** QR code. It appears in your wallet immediately.
   *(If you already have a card for this business from a previous day,
   scan it again anyway — a second card for the same business is expected
   with this daily routine and isn't a bug worth reporting.)*
2. **Collect stamps until the card overflows.** Scan the three **Add
   Stamp** QR codes in order — **+1**, then **+2**, then **+3** — waiting
   about **10 seconds** between each scan (the app enforces a short delay
   between stamps by design; scanning again too soon is expected to be
   briefly refused). Check the card after each scan.
   - Once the card shows as **complete**, scan **one more** Add Stamp
     code (any of the three). This pushes it past capacity — you should
     see a message that a new card was created for the extra stamp(s).
     That overflow behaviour is exactly what we're testing here.
   - If the card *isn't* complete yet after going through +1, +2, +3
     once, just repeat the same three scans again from +1 until it is,
     then do the one extra scan to overflow it.
3. **Redeem.** On the completed card (the one from *before* the overflow
   scan — not the freshly-created overflow one), tap **Redeem**. No QR
   code needed for this step. Confirm the card resets and a new card
   appears for next time.

Move to the next business and repeat. Six businesses, same three steps
each — that's the whole daily session.

---

## A Note on the Sort Feature (Build 41)

At some point during the 14-day window, you may receive a Play Store
update to a newer build that adds a **sort control** to the wallet's card
list — a small icon near the top of the screen (next to Help and
Settings) that lets you reorder your cards (Newest First, Oldest First,
Name A-Z, Name Z-A).

If you get that update:
- Install it as you normally would, then carry on with the same daily
  routine above — nothing else changes.
- Optionally, give the sort icon a try once after updating: tap it, pick
  a different order, and confirm the card list reorders as expected.
  This isn't part of the required daily routine, just worth a look if
  you have a moment.

---

## Reporting Issues

If anything crashes, looks wrong, or doesn't match these instructions,
email **ian.hamlet@dotconnected.com** with:

- Which business/step you were on
- What you expected vs. what happened
- A screenshot if possible

We aim to respond within 48 hours.

---

## Quick Daily Checklist

Print or screenshot this page for a fast reference each day.

| Business | Add Card | +1 → +2 → +3 (repeat until overflow) | Redeem |
|---|:---:|:---:|:---:|
| Test Coffee | ☐ | ☐ | ☐ |
| Green Grocer | ☐ | ☐ | ☐ |
| Riverside Deli | ☐ | ☐ | ☐ |
| Sunny Bakery | ☐ | ☐ | ☐ |
| Willow Spa | ☐ | ☐ | ☐ |
| City Books | ☐ | ☐ | ☐ |

---

_LoyaltyCards Android Closed Testing — thank you for helping us reach general availability._
