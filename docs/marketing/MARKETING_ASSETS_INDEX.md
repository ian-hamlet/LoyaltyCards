# Marketing Assets Index

**Last Updated:** September 7, 2026 (added the Tier 2.5 "how it works" bridge for both audiences)
**Purpose:** Complete inventory of every marketing asset in the repo — printable, online, and social — organized by where it sits in the pathway from "never heard of this" to "using it day to day."
**Companion to:** [DOCUMENTATION_INDEX.md](../../DOCUMENTATION_INDEX.md) (this file is the marketing-specific equivalent, one level down).

---

## The pathway

Everything below exists to move a specific person through a specific gap. There are two audiences (a shop owner deciding whether to run this, and their customer deciding whether to scan a code) and four tiers of material for each:

| Tier | For the shop owner | For their customer |
|---|---|---|
| **1. Hook** — a few seconds | `get-the-app-business-flyer.html`, `get-the-app-business-handout-a5.html` (in person) | `get-the-app-customer-flyer.html` (in person) |
| **1.5. Preview** — before installing, online | &mdash; | `see-what-you-get.html` &mdash; "just scan and collect," linked from the flyer |
| **2. Decide** — a minute, skimmable | `is-it-right-for-your-shop.html` | &mdash; |
| **2.5. Understand** — the mechanics, before the deep guide | `how-it-works-business.html` | `get-the-app-customer-how-it-works.html` (in person, counter card) |
| **3. Do it** — full depth, only once they've said yes | `site/user/supplier-setup-guide.html`, `docs/user/USER_GUIDE.md` | (in-app "How It Works" screen) |

Originally there was Tier 1 and Tier 3 with nothing in between — a shop owner went from a QR code straight to a full setup guide with no way to weigh it up first, and a customer being migrated off a paper card had no explanation at all, printed or online. The gap closed in two passes: `is-it-right-for-your-shop.html` and `get-the-app-customer-how-it-works.html` first (Tier 2), then `how-it-works-business.html` and `see-what-you-get.html` (Tiers 2.5 and 1.5) once it was clear "decide" and "do it" were still one big jump apart, and customers browsing online before ever visiting a shop had no hook at all. See below for what to actually carry into a shop.

**What to carry in person:** a stack of `get-the-app-business-handout-a5.html` cut-outs (Tier 1) is the thing to hand over — its small second QR now points to `how-it-works-business.html` (Tier 2.5) rather than straight at the deep guide. If the owner wants to talk it through instead, `is-it-right-for-your-shop.html` (Tier 2) is the one-page version of the pitch, and its own CTA links onward to `how-it-works-business.html` too. Once they say yes, `get-the-app-customer-how-it-works.html` is what goes on their counter for customers. `see-what-you-get.html` isn't something to print or carry — it's the link from `get-the-app-customer-flyer.html` for someone deciding whether to install before they've ever been handed anything.

---

## 🖨️ Printable — Supplier-Facing (8 files)

**Location:** `marketing/supplier_app/` (source) — mirrored to `site/marketing/` for online viewing/printing, listed on the site's `Marketing Materials` section.

### [get-the-app-business-handout-a5.html](../../marketing/supplier_app/get-the-app-business-handout-a5.html)
**Tier:** 1 (hook). **Purpose:** Four wallet-card-sized cutouts per A4 sheet — QR to download, App Store badge, one-line pitch, a "what happens next" line, and a small second QR straight to `how-it-works-business.html`. This is the one to carry in person and hand out shop after shop.

### [get-the-app-business-flyer.html](../../marketing/supplier_app/get-the-app-business-flyer.html)
**Tier:** 1 (hook). **Purpose:** Poster-style single card, one large QR code, GDPR/no-fees facts. Meant to be displayed (pinned at a counter) rather than handed over — use once a business has already said yes and wants something on the wall, or as the online landing card.

### [is-it-right-for-your-shop.html](../../marketing/supplier_app/is-it-right-for-your-shop.html)
**Tier:** 2 (decide). **Purpose:** One-page, skimmable comparison table — Paper Cards vs. Paid Loyalty App vs. LoyaltyCards — across cost, setup effort, customer data, lock-in, hardware, and fraud protection, plus the honest iPhone-only caveat. Built to answer "should I bother?" in under a minute. Its own CTA now points to `how-it-works-business.html` rather than the deep setup guide.

### [how-it-works-business.html](../../marketing/supplier_app/how-it-works-business.html)
**Tier:** 2.5 (understand). **Purpose:** Four-step overview of running the business day to day — choose Express or Secure mode, set up the business, stamp customers, redeem rewards — with the mode decision itself deferred to the full setup guide rather than re-explained here. Sits between "should I bother" and "walk me through every option," linked from both `is-it-right-for-your-shop.html` and the handout's small QR.

### [get-the-app-business-personal-note-a5.html](../../marketing/supplier_app/get-the-app-business-personal-note-a5.html)
**Tier:** 1↔2 (hook with real depth). **Purpose:** One full page, first-person note explaining why the app exists, what it needs from the owner, and the iPhone-only caveat up front. Use when you've got a minute to actually talk to the owner, not just leave something behind.

### [get-the-app-business-personal-note-email.html](../../marketing/supplier_app/get-the-app-business-personal-note-email.html)
**Purpose:** Same note as the A5 version, formatted to print/save as a PDF for emailing rather than handing over physically.

### [get-the-app-business-personal-note-message.txt](../../marketing/supplier_app/get-the-app-business-personal-note-message.txt)
**Purpose:** Same note again, as plain text — paste straight into WhatsApp/SMS when there's no time or reason to print anything.

### [app-store-url.md](../../marketing/supplier_app/app-store-url.md)
**Purpose:** Reference doc — App Store URL, Apple ID, bundle ID, and shortened link (`apple.co/4hFWKsh`) for the Business app. Source of truth for any new asset that needs the link or QR.

---

## 🖨️ Printable — Customer-Facing (4 files)

**Location:** `marketing/customer_app/` (source) — mirrored to `site/marketing/`.

### [see-what-you-get.html](../../marketing/customer_app/see-what-you-get.html)
**Tier:** 1.5 (preview). **Purpose:** Online-first hook for someone deciding whether to install, not something to print or hand over — benefit-led ("Just Scan and Collect": all your cards on one phone, scan to collect, free rewards automatically tracked) rather than instructional. Linked directly from `get-the-app-customer-flyer.html`'s toolbar, and listed on the site.

### [get-the-app-customer-how-it-works.html](../../marketing/customer_app/get-the-app-customer-how-it-works.html)
**Tier:** 2.5 (understand). **Purpose:** Printable counter card, four numbered steps (Add a Card → Show It Each Visit → Watch It Fill Up → Redeem Your Reward) mirroring the app's own in-app "How It Works" screen, plus a QR to download. Built specifically for the moment a regular customer asks "how does this work?" while a shop is moving off paper cards — reassures them nothing about the reward itself changes. Different job from `see-what-you-get.html`: this one is for someone already standing at the till, not someone deciding online.

### [get-the-app-customer-flyer.html](../../marketing/customer_app/get-the-app-customer-flyer.html)
**Tier:** 1 (hook). **Purpose:** Generic checkout-display card — QR only, no "how it works" content. Works for any business already using LoyaltyCards, print and leave at the till. Toolbar links onward to `see-what-you-get.html`.

### [app-store-url.md](../../marketing/customer_app/app-store-url.md)
**Purpose:** Same reference doc as the supplier version, for the Customer Wallet app (`apple.co/4bYdQ0T`).

---

## 🌐 Online Marketing Site

**Location:** `site/` — the deployed marketing/docs site (Cloudflare Pages, `loyaltycards-site.pages.dev`).

### [site/index.html](../../site/index.html)
**Purpose:** Home page of the site — links to legal/support/guides plus every printable asset under "Marketing Materials." Update this whenever a new printable asset is added or removed.

### [site/marketing/](../../site/marketing/)
**Purpose:** Browser-viewable/printable mirror of everything in `marketing/supplier_app/` and `marketing/customer_app/` (HTML and `.txt` only — the social graphics below aren't published here). Each file is generated from its `marketing/` source with two changes: the relative link back to `site/user/` is shortened, and any "Source: ... in the LoyaltyCards repo" footer credit is dropped since it's redundant on the live site. Keep both copies in sync by hand when editing.

### [site/user/about.html](../../site/user/about.html), [site/user/user-guide.html](../../site/user/user-guide.html), [site/user/supplier-setup-guide.html](../../site/user/supplier-setup-guide.html)
**Tier:** 3 (do it). **Purpose:** The full-depth docs every Tier-1/2 asset eventually points to. Published from `docs/user/ABOUT_LOYALTYCARDS.md`, `docs/user/USER_GUIDE.md`, and `docs/user/SUPPLIER_SETUP_GUIDE.md` respectively.

---

## 📱 Social & Store Graphics (16 files)

**Location:** `marketing/supplier_app/`, `marketing/customer_app/`, `store_graphics/supplier_app/`, `store_graphics/customer_app/`. Not printable material — these are digital-only, sized for specific platforms.

- **Square Post — 1080×1080** (both apps) — Instagram/Facebook feed post.
- **Link Card Preview Image — 1200×628** (both apps) — the image shown when a link to the app is shared (Open Graph/Twitter card).
- **Portrait Banner Ad — 720×1280** (supplier app) / **Landscape Banner Ad — 1200×720** (customer app) — display ad creative.
- **`store_graphics/*/feature_graphic.png` — 1024×500** — Google Play feature graphic, prepared ahead of an Android release (see `docs/deployment/PLAY_STORE_METADATA_PACKET_v2_2_2_37.md` — drafted but not live; both apps are iPhone-only for now).
- **`store_graphics/*/app_icon_512.png`** — store-resolution app icon, both apps.
- **`marketing/*/qr-code.png`** — plain App Store QR code per app, used as the source image for every printable asset above.
- **`marketing/supplier_app/download-on-the-app-store-en-us/`** — Apple's official "Download on the App Store" badge, light/dark/pre-order variants (SVG), as issued by `tools.applemediaservices.com`.

## 📸 App Store Screenshots (26 files)

**Location:** `screenshots/customer_app/android/`, `screenshots/supplier_app/android/` — numbered, captioned sequences (13 per app) covering the full flow (wallet home → add card → scan → redeem, and business setup → issue card → Express/Secure stamping → redeem). Despite the folder name these were captured for App Store listing purposes, not a Play Store release. Regenerated via the seed scripts in `scripts/`.

---

## 📊 Strategy & Positioning (2 files)

**Location:** `docs/marketing/`

### [COMPETITIVE_ASSESSMENT_2026-08-21.md](COMPETITIVE_ASSESSMENT_2026-08-21.md)
**Purpose:** App Store competitive landscape review. Source for the "$12–$99+/month" paid-platform figure used in `is-it-right-for-your-shop.html`, and for the core positioning claim ("no server exists," not just "we don't look at your data") used across every asset above.

### [POSITIONING_UPDATE_PLAN_2026-08-21.md](POSITIONING_UPDATE_PLAN_2026-08-21.md)
**Purpose:** Applied plan for pushing App Store metadata (subtitle, keywords, description) toward the architecture claim over the convenience claim. Status: applied to `docs/deployment/APP_STORE_METADATA_PACKET_v2_2_0_30.md`, not yet re-entered in App Store Connect.

**Related, not duplicated here:** the live App Store listing copy itself lives in `docs/deployment/APP_STORE_METADATA_PACKET_*.md` (see `DOCUMENTATION_INDEX.md` → Deployment for the full version history) — check the highest version number there for what's currently live or queued for submission.

---

## Known gaps / not yet built

- No print-ready poster/table-talker sized for a fixed acrylic counter stand (everything above is A4/A5 paper).
- No Android-facing asset of any kind — deliberate, since neither app is released there yet (see the caveat baked into `is-it-right-for-your-shop.html` and the personal note). Revisit if the Play Store metadata packet ever goes live.
- `site/marketing/` is a hand-maintained mirror, not a build step — if this becomes error-prone, consider a small script to generate it from `marketing/` automatically.
