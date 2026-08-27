# App Store Metadata Packet (v2.2.1+36)

**Status: 🔵 SUBMITTED — awaiting App Store review.** Built, uploaded to TestFlight, TestFlight-tested
(both apps), metadata entered into App Store Connect from this packet, and **submitted for App
Store review 2026-08-27** (both apps). `fix/ios-print-sharepdf-hang` merged to `develop`, `develop`
merged to `main`, and release branch `releases/v2.2.1-build36` cut, all 2026-08-27.

**First 2.2.1 build actually submitted for review** - +33, +34, and +35 were TestFlight-only
validation rounds on `feature/android-port`, never submitted. Per the same convention used for
v2.2.0+32 (which consolidated +30/+31 the same way), "What's New" below covers everything
user-visible back to the last **live** version, v2.2.0+32 - not just the delta since +35.

No positioning changes this release - Subtitle, Promotional Text, Keywords, and Description are
unchanged from v2.2.0+32. Only "What's New" and the App Review Notes change.

⚠️ **Re-enter Promotional Text in ASC anyway, don't just leave it alone.** Per
`APP_STORE_SUBMISSION_CHECKLIST.md`, this field has been found blank in ASC on two prior releases
(v2.0.3+23 and v2.1.1+29) despite being documented here as "unchanged" - it doesn't reliably
persist between submissions. Verify both apps' Promotional Text directly in ASC before submitting,
not just in this doc.

Use this file as the single copy/paste source for App Store Connect listing fields.

---

## What actually changed since v2.2.0+32 (internal reference - not copy/paste content)

For full technical detail, see the `Build 33/34/35/36 Changes` entries in
`source/shared/lib/version.dart`, and:
- `docs/quality/CODE_QUALITY_REFACTOR_2026-08-24.md` (build 33's controller extraction)
- `docs/technical/PACKAGE_UPDATE_MIGRATION_2026-08-26.md` (build 34's package/SPM migration)
- `docs/archive/project-management/CRASH-001-stamp-print-race-condition.md` (background on why
  build 36 moved off `Printing.layoutPdf`)

| Build | User-visible? | Summary |
|---|---|---|
| 33 | Yes (edge case) | Backup/print paths now correctly detect "not enough storage space" instead of showing a raw error message. Also a large internal code-quality refactor (no behavior change). |
| 34 | No | Package/toolchain migration (Swift Package Manager, dependency updates) ahead of Android work. No app-visible change. |
| 35 | Yes (edge case) | Business names with accented characters, Cyrillic, or Greek now render correctly in printed backup/audit-trail PDFs (previously could mis-render with the default font). |
| 36 | **Yes** | Supplier app's Print flow (Recovery Backup, Issue Card, Stamp Token, Audit Trail) now opens the **share sheet** instead of the direct print-preview panel - pick a printer/AirPrint from there. Fixes a native print-preview hang found via TestFlight testing; avoids the same underlying subsystem implicated in a prior App Review-flagged crash (CRASH-001). Customer app: no visible change. |

---

## Shared Listing Values

- Release Version: 2.2.1
- Build: 36
- Primary Language: English (UK)
- Privacy Policy URL: https://loyaltycards-site.pages.dev/legal/privacy-policy.html
- Terms of Service URL: https://loyaltycards-site.pages.dev/legal/terms-of-service.html
- Support URL: https://loyaltycards-site.pages.dev/support/
- Accessibility Statement (not an App Store Connect field, linked from the site): https://loyaltycards-site.pages.dev/legal/accessibility-statement.html
- Support Contact Email: ian.hamlet@dotconnected.com
- Marketing URL: https://loyaltycards-site.pages.dev/user/about.html

**Status:** Unchanged from v2.2.0+32 - those URL fields were confirmed corrected in ASC as part
of that release going live, so no re-entry expected to be needed this time. Worth a quick glance
at submission time regardless, since this hasn't been directly re-verified for this packet.

---

## Customer App (LoyaltyCards Customer Wallet)

### Basic Info
- App Name: LoyaltyCards Customer Wallet
- Bundle ID: com.ianhamlet.loyaltycards.customerApp
- SKU: loyaltycards-customer-2026
- Primary Category: Lifestyle
- Secondary Category: Shopping

### Subtitle (30 chars max)
No server. No data. Ever.

*(unchanged from v2.2.0+32)*

### What's New in This Version
Behind-the-scenes reliability improvements. No new customer-visible feature this release - the
changes are on the Supplier app side; see that app's What's New below.

### Promotional Text (170 chars max)
Free companion app for LoyaltyCards Business. Scan a shop's code to collect stamps - no account, no cloud, nothing to breach. Runs fully offline, on your device only.

*(unchanged from v2.2.0+32)*

### Keywords (100 chars max)
loyalty,rewards,stamps,coffee,local business,qr code,privacy,offline,small business,punch card

*(unchanged from v2.2.0+32)*

### Description
*(unchanged from v2.2.0+32 - see that packet or the live App Store listing for full text)*

### App Review Notes (Customer)
This app is one side of a two-app system and is tested together with LoyaltyCards Business (the Business app issues cards; this app holds them). No login is required on either app, and no backend account exists - all features are offline-capable, since the two apps communicate only via QR code scanned directly between devices.

To review the full flow: install LoyaltyCards Business on a second device or the Simulator, create a test business in Express Mode (fastest to test - no time-limited QR codes involved), issue a card from the Business app, and scan it with this app. Secure Mode exercises the same flow but with cryptographically signed, time-limited QR codes generated per stamp from the Business app.

To review the Sharing feature: Settings → Sharing → tap either "Tell a Business" or "Tell a Friend" - both show a QR code and a "Share the Link" button that opens the standard iOS share sheet with a plain-text link. No account, camera permission, or network access is required for this feature.

This build (v2.2.1+36) has no new customer-visible feature or behavior change on this app's side - see the Supplier App's App Review Notes below for what to test.

---

## Supplier App (LoyaltyCards Business)

### Basic Info
- App Name: LoyaltyCards Business
- Bundle ID: com.ianhamlet.loyaltycards.supplierApp
- SKU: loyaltycards-supplier-2026
- Primary Category: Business
- Secondary Category: Productivity

### Subtitle (30 chars max)
No server, no fees, no data

*(unchanged from v2.2.0+32)*

### What's New in This Version
Printing (backup QR codes, stamp/issue-card QR codes, and the audit trail) is now more reliable - it opens the share sheet, where you can print, save, or send the file as before. Business names with accented letters, Cyrillic, or Greek characters now print correctly. Fixed an error message shown when printing while your device is low on storage.

### Promotional Text (170 chars max)
A free pair of apps that help small shops run a simple digital stamp card - no fees, no accounts. Customers need the companion LoyaltyCards app on their own phone.

*(unchanged from v2.2.0+32)*

### Keywords (100 chars max)
loyalty program,small business,coffee shop,rewards,stamps,qr code,gdpr,no data,customer retention

*(unchanged from v2.2.0+32)*

### Description
*(unchanged from v2.2.0+32 - see that packet or the live App Store listing for full text)*

### App Review Notes (Supplier)
This app is the business side of a two-app system and is reviewed together with LoyaltyCards (customer app) - this app issues and manages cards, the customer app holds them. No login is required on either app, and no backend account exists - all features are offline-capable.

To review the full flow: create a test business (Express Mode is fastest to review - no time-limited QR codes involved), then install LoyaltyCards on a second device or the Simulator to scan the "issue card" and "add stamp" QR codes this app displays. Secure Mode exercises the same flow but generates a freshly signed, time-limited QR code per stamp instead of a static reusable one.

To review the Sharing feature: either tap the person icon in the Home screen's top bar, or go to Settings → Sharing → "Tell a Business" or "Tell a Friend" - both show a QR code and a "Share the Link" button that opens the standard iOS share sheet with a plain-text link. No account, camera permission, or network access is required for this feature.

**What changed in this build (v2.2.1+36), and how to test it:** tapping any Print action in this app - Settings → Recovery Backup → "Print Backup", the Stamp Setup / Issue Card screens' "Print" button, or Settings → Audit Trail → print icon - now opens the standard iOS **share sheet** instead of going directly to a print-preview screen. This is an intentional change, not a regression: choosing "Print" from the share sheet still opens print options and produces a printable PDF (a "Print to PDF"-style flow works even without a physical printer connected, so this is fully testable in the review environment). This avoids a native iOS print-preview subsystem that a prior App Review crash report was traced to; full technical background in `docs/archive/project-management/CRASH-001-stamp-print-race-condition.md` in the repository if useful, though isn't necessary to review this build. Business names containing accented Latin, Cyrillic, or Greek characters (e.g. "Café Münster") will now also render correctly in these PDFs - previously such characters could be missing or garbled.

---

## Decisions (carried forward, unchanged from v2_0_0_19)

- [x] **Pricing:** both apps Free — confirmed by the developer.
- [x] **Copyright line:** `© 2026 Ian Hamlet`
- [x] **App Review contact phone:** 07968135909
- [x] **Age Rating questionnaire:** all "None", expected 4+ — confirmed entered in ASC 2026-08-15.
- [x] **Release Date:** Manual release, both apps — reconfirm still set correctly in ASC before submitting.
