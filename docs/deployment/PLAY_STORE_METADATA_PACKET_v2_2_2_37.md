# Play Store Metadata Packet (v2.2.2+37)

**Status: 🟡 DRAFT — Track 2 not yet started.** No Google Play Developer account exists yet
(that registration + the $25 fee is the developer's own action, not something that can be done
from here). This packet exists so every piece of *content* is ready to paste into Play Console
the moment the account and app listings exist, instead of writing it from scratch under time
pressure.

Adapted from `APP_STORE_METADATA_PACKET_v2_2_1_36.md`, refreshed to the current build in the
process (2.2.1+36 → 2.2.2+37 — see `source/shared/lib/version.dart` Build 37 for what changed:
the two Android biometric-auth bugs found and fixed during Android port testing). Play's fields
don't map 1:1 onto App Store Connect's — notably, Play has no separate "Subtitle"/"Promotional
Text"/"Keywords" fields (just one short description + one long description) and only a single
Category per app (no primary/secondary split).

Use this file as the single copy/paste source for Play Console's **Main store listing**, once it
exists.

---

## Shared Listing Values

- Release Version: 2.2.2
- Version Code (Play's build-number equivalent): 37
- Default Language: English (United Kingdom)
- Privacy Policy URL: https://loyaltycards-site.pages.dev/legal/privacy-policy.html
- Terms of Service URL: https://loyaltycards-site.pages.dev/legal/terms-of-service.html
- Support URL: https://loyaltycards-site.pages.dev/support/
- Accessibility Statement (not a Play Console field, linked from the site): https://loyaltycards-site.pages.dev/legal/accessibility-statement.html
- Support Contact Email: ian.hamlet@dotconnected.com
- Developer/Copyright: © 2026 Ian Hamlet
- Pricing: Free (both apps)
- Contains Ads: No
- In-app purchases: No

---

## Customer App (LoyaltyCards Customer Wallet)

### Basic Info
- App name (30 chars max): `LoyaltyCards Customer Wallet` (28 chars)
- Package name: `com.ianhamlet.loyaltycards.customer`
- Category: Lifestyle *(Play allows one category only — App Store's secondary "Shopping" has no
  Play equivalent slot; consider it as an optional Tag instead once Play Console's current tag
  list is visible)*

### Short Description (80 chars max)
```
Free loyalty stamp wallet. No account, no server, no data collected. Ever.
```
(74 chars)

### Full Description (4000 chars max)
```
LoyaltyCards is the free companion app for shops using LoyaltyCards Business. If a shop you visit uses it, you can collect digital stamp cards on your own phone instead of paper ones.

WHAT TO EXPECT

This isn't a directory or a marketplace - there's nothing to browse. You'll only use this app if a shop you already visit shows you a QR code and asks you to scan it.

HOW IT WORKS

1. A shop shows you a QR code
2. You scan it with LoyaltyCards
3. Collect a stamp each visit
4. Show your completed card to redeem your reward

WHY THIS ISN'T LIKE OTHER LOYALTY APPS

Most loyalty apps still run on a company's server somewhere - even the ones that don't ask you to sign up. LoyaltyCards doesn't have a server. Your stamp cards are created and updated only when your phone talks directly to the shop's device over a scanned QR code. There's no database to breach, no account to hack, and nothing about your visits to piece together - because none of it exists anywhere but your phone.

WHO IT'S FOR

Built with small, independent shops in mind - cafes, salons, and similar businesses that want to run a simple stamp card without paying for a loyalty platform or collecting your data to do it.

Some shops use Express Mode, where you self-serve and the shop simply checks your card before redeeming it. Others use Secure Mode, where each stamp is cryptographically signed and verified by the shop's device. You'll see both in your wallet - no setup needed either way.

PRIVACY

No signup, no email, no phone number, no account, no tracking. Nothing about you is collected or sent anywhere - your cards are stored only on your device and exchanged directly with the shop's device over a scanned QR code.

Run a shop and want to offer this? Get LoyaltyCards Business here: [Play Store link - add once the Business app listing is live]

Download LoyaltyCards and start collecting.
```

### App Access / Review Notes (internal, not a public listing field)
This app is one side of a two-app system and should be tested together with LoyaltyCards
Business (that app issues cards; this app holds them). No login is required on either app, and
no backend account exists - all features are offline-capable, since the two apps communicate
only via QR code scanned directly between devices.

To review the full flow: install LoyaltyCards Business on a second device or emulator, create a
test business in Express Mode (fastest to test - no time-limited QR codes involved), issue a card
from the Business app, and scan it with this app. Secure Mode exercises the same flow but with
cryptographically signed, time-limited QR codes generated per stamp from the Business app.

---

## Supplier App (LoyaltyCards Business)

### Basic Info
- App name (30 chars max): `LoyaltyCards Business` (21 chars)
- Package name: `com.ianhamlet.loyaltycards.supplier`
- Category: Business *(App Store's secondary "Productivity" has no Play equivalent slot; consider
  as an optional Tag)*

### Short Description (80 chars max)
```
Free digital stamp cards for shops. No fees, no accounts, no customer data.
```
(75 chars)

### Full Description (4000 chars max)
```
LoyaltyCards Business is a free way for small shops to run a digital stamp card, without the cost or complexity of a loyalty platform.

WHY LOYALTYCARDS BUSINESS?

- Free - no subscriptions, no fees, no hidden costs
- No customer data collected - nothing to store, nothing to protect
- Works offline - no internet connection required
- Use on multiple devices - registers, staff phones, whatever you already have

TWO APPS, ONE SYSTEM

This app is for the shop. Customers need the free companion app, LoyaltyCards, on their own phone to hold their cards - there's no shared server or account, each card is created and stamped directly between your device and theirs via QR code. Point your customers here to get it: [Play Store link - add once the Customer app listing is live]

CHOOSE YOUR MODE

- Express Mode: show one reusable QR code, customers self-serve in a couple of seconds, and you simply check the card before redeeming it. Best for quick, everyday visits.
- Secure Mode: generate a fresh, cryptographically signed QR code per stamp from your device. Slightly slower, but every stamp is verified. Best for higher-value rewards.

Both work fully offline. You can't switch modes later without a full reset, so choose based on what suits your shop.

MULTI-DEVICE SUPPORT

Back up your configuration with one QR scan and clone it to additional devices, all issuing stamps for the same program.

WHY NO BACKEND MATTERS

Most digital loyalty platforms store your customer list on their servers - which means their data breach becomes your data breach, and their pricing becomes your ongoing cost. LoyaltyCards Business has no server, so there's no customer database to protect, lose, or pay to maintain. If you're subject to GDPR or just don't want the liability, there's simply nothing to secure - because nothing customer-identifying is ever collected.

PRIVACY

No customer emails, phone numbers, or personal data collected - ever.

WHO IT'S FOR

Built with smaller, independent outlets in mind - cafes, salons, and similar shops that want to reward regular customers without paying for a loyalty platform.

Download LoyaltyCards Business and get started.
```

### App Access / Review Notes (internal, not a public listing field)
This app is the business side of a two-app system and should be reviewed together with
LoyaltyCards (customer app) - this app issues and manages cards, the customer app holds them. No
login is required on either app, and no backend account exists - all features are offline-capable.

To review the full flow: create a test business (Express Mode is fastest to review - no
time-limited QR codes involved), then install LoyaltyCards on a second device or emulator to
scan the "issue card" and "add stamp" QR codes this app displays. Secure Mode exercises the same
flow but generates a freshly signed, time-limited QR code per stamp instead of a static reusable
one.

---

## Graphic Assets (not yet produced)

Play Console requires image assets the App Store submission didn't need in the same form:

- [ ] **App icon** (512×512 PNG) - can be exported directly from the same 1024px branded source
      already used for `flutter_launcher_icons` (Phase 4 of the Android port)
- [ ] **Feature graphic** (1024×500 PNG/JPG) - a promotional banner, no direct App Store
      equivalent; needs actual design work, not just a resize
- [ ] **Phone screenshots** (min 2, max 8 per app, 16:9 or 9:16) - these can be captured for real
      from the emulator (`adb shell screencap` or Android Studio's screenshot tool) once there's a
      concrete list of which screens to capture; a good candidate list per app: wallet home (a
      couple of cards, one near-complete), card detail, QR scan/display, and (Supplier) the
      issue-card and stamp screens
- [ ] **Tablet screenshots** - optional, only needed if either app is listed as tablet-optimized

---

## Content Rating (IARC Questionnaire)

Play's content rating is a self-service questionnaire (IARC), completed per-app in Play Console -
there's no file to prep in advance the way App Store Connect's Age Rating fields can be, but
based on the actual app content the expected answers mirror the App Store's "all None" / 4+
outcome:

- Violence: None
- Sexual content: None
- Profanity: None
- Controlled substances: None
- Gambling: None (loyalty/reward stamps are not a game of chance and have no real-money value)
- User-generated content: None (a business's own name/branding is entered by that business for
  its own display, not shared publicly or between unrelated users)
- Shares user location: No
- Allows users to interact/communicate: No

Expected result: Everyone / 3+ (Play's rating scale doesn't map 1:1 to Apple's, but this is the
equivalent "no concerns" outcome).

---

## Data Safety Form

This is the field with the most legal weight and the most Play-specific nuance, so treat the
following as a **starting draft to review, not a final answer** - unlike everything else in this
file, get a second look at this section specifically before submitting, since Play's data safety
disclosure requirements are stricter/differently-scoped than what the Privacy Policy was written
for. Source of truth for what the app actually does: `docs/legal/PRIVACY_POLICY.md`.

**Does your app collect or share any of the required user data types?** Expected answer: **No**,
for both apps, on the basis that:
- No data is transmitted to the developer or to any server (there is no server)
- No data is shared with third parties
- All storage is local to the device (SQLite, iOS Keychain / Android Keystore)

**⚠️ One judgment call worth a deliberate decision, not just carrying the Privacy Policy's
existing framing forward as-is:** Secure Mode's anti-fraud device signal (a one-way-hashed
device identifier, sent device-to-device inside a redemption QR code - see "Anti-Fraud Device
Signal" in the Privacy Policy) *does* leave the user's device, even though it never reaches the
developer or a server. Play's Data Safety form asks about data collected/shared in a broader
sense than "sent to us" - its own guidance covers data shared with *other users* of the app too,
which is closer to what this signal actually does. Worth explicitly deciding whether to:
  (a) disclose it as a "Device or other IDs" data type shared with "other users" (accurate,
      cautious, but adds friction to an otherwise clean "no data collected" listing), or
  (b) treat it as out of scope on the basis that it's a one-way, non-reversible, ephemeral value
      that never identifies a specific device or person and isn't retained by anyone
This isn't a call to make automatically - it affects a legal disclosure and there isn't a single
obviously-correct answer from the app's code alone.

**Security practices section** (if data collection is disclosed at all, even minimally):
- Data encrypted in transit: N/A (no network transmission)
- Users can request data deletion: Yes (delete the app / Settings → Reset Business Configuration)
- Data is not sold to third parties: Confirmed

---

## Target Audience & Content

- Target age group: Not primarily child-directed (general/business utility tool - matches the
  App Store's "all None" Age Rating answers)
- App is a government app: No
- App is a COVID-19 contact tracing/status app: No
- Financial features: No real-money transactions, payments, or financial services - loyalty
  stamps have no cash value

---

## Decisions Needed Before Submission (not yet made)

- [ ] Register the Google Play Developer account ($25 one-time, developer's own action)
- [ ] Decide the Data Safety anti-fraud-signal disclosure question above
- [ ] Produce the feature graphic and phone screenshots (see "Graphic Assets" above)
- [ ] Confirm Play's current Category/Tag list still matches what's assumed here (Play's taxonomy
      changes occasionally - verify Lifestyle/Business are still the right top-level categories
      when the listing is actually being created)
