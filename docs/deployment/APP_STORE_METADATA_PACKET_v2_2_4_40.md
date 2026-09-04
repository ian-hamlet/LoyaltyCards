# App Store Metadata Packet (v2.2.4+40)

**Status: 🟢 Submitted for App Store review 2026-09-04 (both apps), after Transporter upload and
in-parallel TestFlight testing.** Built via `build_both_apps_ios.sh`, both IPAs verified (valid
zip, correct 2.2.4/40 in `Info.plist`, correct bundle IDs). Branch: merged `feature/android-port`
→ `develop` (`767f641`), release branch `releases/v2.2.4-build40` cut from `develop`. Not yet
merged to `main` - held until both apps clear review, per this project's standard convention.

**First iOS build since v2.2.1+36** - builds 37, 38, and 39 were never built for iOS at all
(version-bumped in source only, for Android-only fixes built and tested exclusively via Play
Console/Android hardware - see `source/shared/lib/version.dart` and
`docs/project-management/ANDROID_PORT_PLAN.md`). Per the same convention used for v2.2.0+32 and
v2.2.1+36, "What's New" below covers everything user-visible back to the last **live** version,
v2.2.1+36 - not just the delta since +39.

No positioning changes this release - Subtitle, Promotional Text, Keywords, and Description are
unchanged from v2.2.1+36. Only "What's New" and the App Review Notes change, and only for the
Customer app - the Supplier app has no user-visible change at all since v2.2.1+36.

**Promotional Text clears on every new release** (confirmed by the developer as expected ASC
behavior, not a bug to chase) - always re-enter it from this packet rather than assuming it
carried forward, unlike every other field on this page.

Use this file as the single copy/paste source for App Store Connect listing fields.

---

## What actually changed since v2.2.1+36 (internal reference - not copy/paste content)

For full technical detail, see the `Build 37/38/39/40 Changes` entries in
`source/shared/lib/version.dart`, and `docs/project-management/ANDROID_PORT_PLAN.md`.

| Build | iOS user-visible? | Summary |
|---|---|---|
| 37 | **No** | Android-only: `MainActivity` needed `FlutterFragmentActivity` for biometric prompts to work at all on Android (`local_auth`'s `BiometricPrompt` requires it) - iOS has no `MainActivity.kt`/`FragmentActivity` concept, so no iOS code path touched. The Supplier app's added `on LocalAuthException` handler is also inert on iOS - only `local_auth_android` throws that type; iOS still throws (and still correctly handles) `PlatformException` exactly as before. |
| 38 | **No** | Android-only: the anti-fraud redemption device signal was hashing an OS-build tag instead of a real per-device value on Android specifically. iOS's `identifierForVendor` code path is untouched, byte-for-byte identical to what shipped in v2.2.1+36. |
| 39/40 | **Yes (minor)** | Customer app: a Secure Mode card that's complete but not yet redeemed previously showed two buttons doing the exact same thing - an inline "Scan Redemption" button and a floating "Scan Confirmation" button, both navigating to the identical scanner screen. Removed the redundant floating button; the inline one remains. Cosmetic/UX cleanup, not a functional bug - both buttons worked correctly before, this just removes a confusing duplicate. Supplier app: no change. |

Also: the rest of build 37-40's work (Android port, Play Store submission prep, this machine's
Xcode/openssl toolchain fix) has zero bearing on the iOS app itself or this submission.

---

## Shared Listing Values

- Release Version: 2.2.4
- Build: 40
- Primary Language: English (UK)
- Privacy Policy URL: https://loyaltycards-site.pages.dev/legal/privacy-policy.html
- Terms of Service URL: https://loyaltycards-site.pages.dev/legal/terms-of-service.html
- Support URL: https://loyaltycards-site.pages.dev/support/
- Accessibility Statement (not an App Store Connect field, linked from the site): https://loyaltycards-site.pages.dev/legal/accessibility-statement.html
- Support Contact Email: ian.hamlet@dotconnected.com
- Marketing URL: https://loyaltycards-site.pages.dev/user/about.html

**Status:** Unchanged from v2.2.1+36 - those URL fields were confirmed correct in ASC as part of
that release going live, so no re-entry expected to be needed this time. Worth a quick glance at
submission time regardless, since this hasn't been directly re-verified for this packet. Note the
Privacy Policy itself *was* lightly edited this cycle (dropped a stale "iOS local storage" claim
now that Android exists, and tightened the anti-fraud device signal wording - see
`docs/legal/PRIVACY_POLICY.md`) - the URL is unchanged, but if App Review or a user diffs the
content against a cached copy, that's why it moved.

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

*(unchanged from v2.2.1+36)*

### What's New in This Version
Minor fix: cleaned up a Secure Mode reward screen that could show two buttons doing the same
thing. Small under-the-hood reliability work elsewhere.

### Promotional Text (170 chars max)
Free companion app for LoyaltyCards Business. Scan a shop's code to collect stamps - no account, no cloud, nothing to breach. Runs fully offline, on your device only.

*(unchanged from v2.2.1+36)*

### Keywords (100 chars max)
loyalty,rewards,stamps,coffee,local business,qr code,privacy,offline,small business,punch card

*(unchanged from v2.2.1+36)*

### Description
*(unchanged from v2.2.1+36 - see that packet or the live App Store listing for full text)*

### App Review Notes (Customer)
This app is one side of a two-app system and is tested together with LoyaltyCards Business (the Business app issues cards; this app holds them). No login is required on either app, and no backend account exists - all features are offline-capable, since the two apps communicate only via QR code scanned directly between devices.

To review the full flow: install LoyaltyCards Business on a second device or the Simulator, create a test business in Express Mode (fastest to test - no time-limited QR codes involved), issue a card from the Business app, and scan it with this app. Secure Mode exercises the same flow but with cryptographically signed, time-limited QR codes generated per stamp from the Business app.

To review the Sharing feature: Settings → Sharing → tap either "Tell a Business" or "Tell a Friend" - both show a QR code and a "Share the Link" button that opens the standard iOS share sheet with a plain-text link. No account, camera permission, or network access is required for this feature.

**What changed in this build (v2.2.4+40), and how to test it:** complete a Secure Mode card fully (collect all required stamps), then open that card's detail screen. Previously this screen showed two buttons that both scanned a redemption confirmation code - a floating green button labeled "Scan Confirmation" and, directly below the QR code, an outlined button labeled "Scan Redemption." Only the inline "Scan Redemption" button remains now; the redundant floating one is gone. Both did the exact same thing before, so this is a cosmetic fix, not a functional change - the redemption flow itself works identically to v2.2.1+36.

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

*(unchanged from v2.2.1+36)*

### What's New in This Version
No customer-visible changes in this release - see the LoyaltyCards (customer) app's What's New
for what changed this cycle.

### Promotional Text (170 chars max)
A free pair of apps that help small shops run a simple digital stamp card - no fees, no accounts. Customers need the companion LoyaltyCards app on their own phone.

*(unchanged from v2.2.1+36)*

### Keywords (100 chars max)
loyalty program,small business,coffee shop,rewards,stamps,qr code,gdpr,no data,customer retention

*(unchanged from v2.2.1+36)*

### Description
*(unchanged from v2.2.1+36 - see that packet or the live App Store listing for full text)*

### App Review Notes (Supplier)
This app is the business side of a two-app system and is reviewed together with LoyaltyCards (customer app) - this app issues and manages cards, the customer app holds them. No login is required on either app, and no backend account exists - all features are offline-capable.

To review the full flow: create a test business (Express Mode is fastest to review - no time-limited QR codes involved), then install LoyaltyCards on a second device or the Simulator to scan the "issue card" and "add stamp" QR codes this app displays. Secure Mode exercises the same flow but generates a freshly signed, time-limited QR code per stamp instead of a static reusable one.

To review the Sharing feature: either tap the person icon in the Home screen's top bar, or go to Settings → Sharing → "Tell a Business" or "Tell a Friend" - both show a QR code and a "Share the Link" button that opens the standard iOS share sheet with a plain-text link. No account, camera permission, or network access is required for this feature.

**This build (v2.2.4+40) has no new customer-visible feature or behavior change on this app's side** - all real changes this cycle (biometric-auth fix, anti-fraud device-signal fix) are Android-only, with no iOS-observable effect (see the "What actually changed" table above for why). Functionally identical to v2.2.1+36 on iOS.

---

## Decisions (carried forward, unchanged from v2_0_0_19)

- [x] **Pricing:** both apps Free — confirmed by the developer.
- [x] **Copyright line:** `© 2026 Ian Hamlet`
- [x] **App Review contact phone:** 07968135909
- [x] **Age Rating questionnaire:** all "None", expected 4+ — confirmed entered in ASC 2026-08-15, unchanged.
- [x] **Release Date:** Manual release, both apps — reconfirm still set correctly in ASC before submitting.
