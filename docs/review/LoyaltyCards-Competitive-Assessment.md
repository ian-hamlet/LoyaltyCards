# LoyaltyCards — App Store Competitive Assessment

*Prepared 21 August 2026*

## Executive summary

LoyaltyCards' core customer experience — collect stamps, redeem a reward, scan a QR code at checkout — is a deliberately conventional pattern shared by every serious competitor in this space. That is correct: customers shouldn't have to learn a new mental model for a punch card.

The genuine differentiation is architectural, not experiential. LoyaltyCards is the only product found in this review that runs as a true peer-to-peer system between two native apps with no backend of any kind — not even for setup — and collects zero personal data, not even a phone number. Every comparable "privacy-first" or "QR-based" competitor either stores existing cards only (no business side), or runs on a cloud backend despite privacy-adjacent marketing.

**Recommendation:** lead App Store and marketing copy with the architecture claim ("no server, no data, no subscription — ever"), not with the stamp-card mechanic itself, since that mechanic is table stakes.

## Classes of loyalty-card solutions on the App Store

Five distinct classes emerged from reviewing the current App Store and small-business loyalty landscape.

| Class | Examples | Business model | Data model |
|---|---|---|---|
| **1. Card wallets** (barcode vaults) | Stocard, Kard, Offline Cards, SuperCards, Barcodes, OffPass | Free or one-time purchase | Local storage of existing cards. No way to issue a new program. |
| **2. Wallet-pass SaaS platforms** | Loopy Loyalty, Stamp Me, LoyaltyPass, FaveCard, Perkstar, StampClub | $12–$99+/month, few free tiers | Cloud backend issues & tracks passes; some device/PII capture |
| **3. Phone-number POS systems** | digiPunchCard, Punchable | Subscription | Business stores customer phone numbers in the cloud |
| **4. Enterprise / POS-integrated** | Punchh, Square Loyalty | Enterprise contracts | Full CRM, deep marketing data capture |
| **5. True P2P, serverless** (LoyaltyCards) | No direct competitor found in this class | Free | No backend at all. Zero personal data, not even a phone number. |

## Is LoyaltyCards copying a common model?

### What's conventional (by design)

- The stamp-card metaphor: collect N stamps, redeem a reward.
- QR-code-at-checkout as the scan-and-go interaction.
- A two-sided app pattern (business side issues/manages, customer side holds cards) — shared with most of Class 2.

*None of this should change — it's the expected UX and copying it is the right call.*

### What's genuinely novel

- **Zero backend, full stop** — not "we don't look at your data," but no server exists to breach, subpoena, or monetize.
- **Zero personal data collection** — stronger than Class 1's "local storage" claim, because LoyaltyCards also solves the two-sided issuance problem those apps don't attempt.
- **Selectable trust model per business** — Express (fast, trust-based, rate-limited) vs Secure (ECDSA-signed, hash-chained, time-limited QR). No competitor found lets the business choose the trust/speed trade-off; they pick one model for you.
- **Serverless disaster recovery** — print/email/file backup of a business's cryptographic keys and a 5-minute clone-to-second-device flow. Cloud competitors get this for free from their database; LoyaltyCards had to engineer it.
- **Free, permanently, by construction** — there's no server cost to recoup, unlike the $12–99+/month Class 2 platforms.

## Comparison against each competitor class

| Competitor class | Their model | How LoyaltyCards differs |
|---|---|---|
| **Class 1 — card wallets** (Stocard, Kard) | Store barcodes of cards that already exist. Single-sided app, no business side. | Actually issues new stamp programs. Two-sided (business + customer) app, not just storage. |
| **Class 2 — wallet-pass SaaS** (Loopy, Stamp Me) | Two-sided, but every pass is issued and tracked by a cloud backend. $12–99+/month. | No backend of any kind, not even for setup. Free. Optional cryptographic stamp signing. |
| **Class 3 — phone-number systems** (digiPunchCard) | No customer app, but the business stores customer phone numbers in the cloud. | Zero personal data collected — not even a phone number. Anonymous by design. |
| **Class 4 — enterprise** (Punchh, Square) | Deep POS integration, CRM, marketing automation, built for chains. | Not competing on scale — built for solo/independent shops at zero cost, zero data liability. |

## Trade-offs to be upfront about

- Class 2's core pitch — "lives in the Apple Wallet you already have, zero app download, native push reminders" — is objectively lower customer friction than installing a dedicated app. LoyaltyCards asks for an install on both sides (customer + business).
- No Apple/Google Wallet integration means no native lock-screen push reminders, which several competitors cite as a strong retention driver.
- The privacy/architecture story will resonate strongly with privacy-conscious individuals and GDPR-sensitive EU businesses — a real but likely niche segment — more than with mass-market consumers who typically optimize for convenience over data minimalism.
- No cloud backend also means no CRM/analytics/marketing-campaign features some businesses may actively want. This is already a deliberate, stated non-goal (see "Not Planned" in the app's About documentation) and should stay communicated clearly as a trade-off, not an oversight.

## Bottom line

The product itself is not a copy of a single competitor — it sits outside all four existing classes because of its architecture. The risk is in the pitch, not the build: if the App Store listing and marketing lead with "another loyalty stamp app," it reads as one of dozens of Class 2 clones. Leading with "no server, no data, no subscription — ever" and the Express/Secure trust-mode choice tells the real, differentiated story.
