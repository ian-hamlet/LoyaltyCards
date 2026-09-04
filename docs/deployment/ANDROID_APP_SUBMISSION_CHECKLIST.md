# Android (Google Play) Submission Checklist

**LoyaltyCards v2.2.4+40**
**Customer App:** LoyaltyCards Customer Wallet (`com.ianhamlet.loyaltycards.customer`)
**Supplier App:** LoyaltyCards Business (`com.ianhamlet.loyaltycards.supplier`)
**Target Release:** 🟢 Both apps live on Google Play **Internal testing**, real-device tested
successfully on two Samsung Galaxy devices (A14/A12) - see `ANDROID_PORT_PLAN.md` Track 2.
**Everything remaining is a single Play Console page: Policy and programs → App content** (Content
rating, App content declarations, Data Safety) - all three sections' answers are already decided
below, nothing left to draft. Once that page is green for both apps, promote to Production.
**Last Updated:** September 4, 2026

**Status note:** iOS is at the same version line (v2.2.4+40, submitted for App Store review
2026-09-04, TestFlight testing in parallel - see `APP_STORE_SUBMISSION_CHECKLIST.md`). The two
platforms are **not** kept in lockstep by policy - each ships independently as its own
review/approval cycle completes.

Play Console's field set differs from App Store Connect's in ways that matter throughout this
checklist: **one description field (no separate Subtitle/Promotional Text/Keywords)**, **a single
Category (no primary/secondary split)**, a self-service **IARC content rating questionnaire**
instead of static Age Rating fields, a **Data Safety form** instead of the App Privacy "nutrition
label," an **Internal testing track** instead of TestFlight (no review gate at all for internal
testers), and an **.aab** (Android App Bundle) upload instead of an **.ipa**.

---

## Pre-Submission Requirements

### Code & Build Preparation

- [x] **Final version incremented** across all three `pubspec.yaml` files + `source/shared/lib/version.dart` - `2.2.4+40`, confirmed in sync
- [x] **All code merged** - `feature/android-port` → `develop` (`767f641`), release branch `releases/v2.2.4-build40` cut from `develop`. Not yet merged to `main` - held until both platforms clear their respective store reviews, per this project's standard convention.
- [x] **Release AABs built** via `source/build_both_apps_android.sh` for both apps, confirmed release-signed via `jarsigner -verify` (not the debug-signing fallback)
- [x] **All automated tests passing** - shared 216, customer_app 184 (+8 skipped), supplier_app 151 (+4 skipped)
- [x] **`flutter analyze` clean** on all three packages
- [x] **Critical bugs resolved** - the Android device-signal bug (Build 38) and a duplicate redemption button (Build 39/40) both fixed and shipped in v2.2.4+40. The device-signal fix's real-device confirmation is necessarily partial: there's no practical way to manually stage a genuine device-mismatch scenario through the app's own UI (see the discussion in `ANDROID_PORT_PLAN.md`), so it's verified by unit tests plus confirming the app functions correctly end-to-end on two distinct real devices - not by reproducing the original bug's exact failure mode.

---

## Google Play Developer Account

- [x] **Account registered** - completed 2026-09-04
- [x] **Device-verification step** - resolved 2026-09-04: developer sourced and reset two real Android devices (Samsung Galaxy A14/A12)
- [x] **Both Play Console app listings created** - `com.ianhamlet.loyaltycards.customer` and `com.ianhamlet.loyaltycards.supplier`, 2026-09-04

---

## App Setup - Basic Info

Both confirmed correct via successful Internal testing uploads under these exact identifiers:

#### Customer App: LoyaltyCards Customer Wallet
- [x] **App name:** `LoyaltyCards Customer Wallet`
- [x] **Package name:** `com.ianhamlet.loyaltycards.customer`
- [ ] **Category:** Lifestyle - not yet confirmed set in Play Console (not required for Internal testing; part of the Main store listing page, see below)
- [x] **Default language:** English (United Kingdom)

#### Supplier App: LoyaltyCards Business
- [x] **App name:** `LoyaltyCards Business`
- [x] **Package name:** `com.ianhamlet.loyaltycards.supplier`
- [ ] **Category:** Business - not yet confirmed set in Play Console, same as above
- [x] **Default language:** English (United Kingdom)

---

## Store Listing Content

Full copy-paste text lives in
[`PLAY_STORE_METADATA_PACKET_v2_2_2_37.md`](PLAY_STORE_METADATA_PACKET_v2_2_2_37.md) - still
accurate, no user-facing store copy has changed since. **Not yet entered into Play Console** -
Internal testing doesn't require the Main store listing page to be filled in, only App setup +
an uploaded release, which is why this is still outstanding despite testing already being
underway:

- [ ] **Short description** (80 chars max, both apps)
- [ ] **Full description** (4000 chars max, both apps)
- [ ] **App icon** (512×512 PNG) - see "Graphic Assets" below
- [ ] **Feature graphic** (1024×500 PNG) - see "Graphic Assets" below
- [ ] **Phone screenshots** - see "Graphic Assets" below
- [ ] **Category** (Lifestyle / Business - see above)
- [ ] **Privacy Policy URL:** https://loyaltycards-site.pages.dev/legal/privacy-policy.html (both apps)

Play has no separate Subtitle/Promotional Text/Keywords fields the way App Store Connect does -
everything beyond the short/full description above is out of scope here.

---

## Graphic Assets

- [x] **App icon** (512×512 PNG) - `store_graphics/customer_app/app_icon_512.png`, `store_graphics/supplier_app/app_icon_512.png`, approved 2026-09-02
- [x] **Feature graphic** (1024×500 PNG) - `store_graphics/customer_app/feature_graphic.png`, `store_graphics/supplier_app/feature_graphic.png`, approved 2026-09-02
- [x] **Phone screenshots** - 13 per app, real captures, in `screenshots/customer_app/android/` and `screenshots/supplier_app/android/` - pick the strongest 4-8 per app for the actual listing rather than uploading all of them
- [ ] **Upload all of the above into Play Console's Main store listing page** - not yet done
- [ ] **Tablet screenshots** - optional, not currently planned

---

## App Content (start here - one Play Console page covers all three sections below)

**Navigate to: Play Console → select an app → left sidebar → Policy and programs → App content.**
This single hub page lists Content rating, Target audience/Ads/Government app/COVID-19
app/Financial features, and Data safety, each as its own row with a "Start"/"Manage" button.
None of it was required for Internal testing, which is why it's the one thing still outstanding
despite both apps already being installed and tested on real hardware. Recommended order: content
rating first (quickest), then the small declarations, then Data Safety last (the one with actual
nuance). Do this for the Customer app first, then repeat for the Supplier app (its Data Safety
answer is simpler - "No" throughout).

### 1. Content Rating (IARC Questionnaire)

- [ ] Violence: None
- [ ] Sexual content: None
- [ ] Profanity: None
- [ ] Controlled substances: None
- [ ] Gambling: None (loyalty stamps are not a game of chance, no real-money value)
- [ ] User-generated content: None
- [ ] Shares location: No
- [ ] Allows user interaction/communication: No
- [ ] **Entered into Play Console's questionnaire** (both apps)

**Expected Rating:** Everyone / 3+ (Play's closest equivalent to Apple's 4+)

### 2. App Content Declarations

- [ ] **Target audience & content:** not primarily child-directed (general/business utility tool)
- [ ] **Government app:** No
- [ ] **COVID-19 app:** No (not a contact-tracing/status app)
- [ ] **Financial features:** No real-money transactions, payments, or financial services -
      loyalty stamps have no cash value
- [ ] **Ads declaration:** No ads in either app
- [ ] **Permissions declaration** - Play may ask for justification of sensitive runtime
      permissions at review time. Camera (`CAMERA`) is the only sensitive one either app
      requests (contributed automatically by `mobile_scanner`, confirmed via the actual merged
      manifest). Justification if asked: "scan QR codes to issue/collect/redeem loyalty stamps."

### 3. Data Safety Form

**Decided 2026-09-02**, updated 2026-09-04 to reflect the final v2.2.4+40 device-signal behavior -
full reasoning in the metadata packet's "Data Safety Form" section.

**Supplier App: No**
- [ ] **Does the app collect/share required user data types?** **No.** It only ever *receives*
      the customer's device signal inbound (scanned from a QR code) and stores it locally for
      its own fraud check - never retransmits it anywhere.

**Customer App: Yes - one data type**
- [ ] **Does the app collect/share required user data types?** **Yes**
- [ ] **Data type:** Device or other IDs
- [ ] **Collected:** No (nothing reaches the developer or any server)
- [ ] **Shared:** Yes (generated on-device, then transmitted to the supplier's device inside the
      redemption QR code - a different party than the developer, which is what triggers "shared"
      regardless of the value's nature)
- [ ] **Purpose:** Fraud prevention, security, and compliance
- [ ] **Processed ephemerally?** No (the identifier persists across sessions on the customer's
      device - only the single QR transmission of it is one-shot)
- [ ] **Required or optional:** Required (automatic as part of Secure Mode redemption, not a
      user-facing toggle)
- [ ] **Used for tracking:** No
- [ ] **Security practices:** data encrypted in transit - N/A (travels inside a QR code image,
      not a network protocol); users can request deletion - Yes (delete the app); data not sold
      to third parties - confirmed
- [ ] **Entered into Play Console** (both apps)

Note: this reads as a more disclosure-friendly answer than it would have pre-fix, not because the
checkbox changed (it doesn't - "shared" was already true either way), but because the value
itself is now honestly describable as "an app-generated identifier, not derived from your
device's hardware or OS" rather than a hash of one.

---

## Internal Testing Track - ✅ Complete for both apps

- [x] **Configured** for both apps, 2026-09-04
- [x] **Testers added**, opt-in confirmed on both Samsung devices
- [x] **First internal test AAB uploaded** - v2.2.4+40 for both apps (v2.2.4+39 was consumed by
      an abandoned draft release and could never be reused - Play permanently reserves a version
      code once uploaded to any track)
- [x] **Install confirmed** via the Play Store's tester opt-in flow on both real devices
- [x] **Functional test pass on real hardware, completed 2026-09-04**: full Express and Secure
      Mode issue/stamp/redeem cycles, biometric-gated Recovery Backup and Clone to Another Device
      with a real fingerprint/PIN, and the Secure Mode redemption screen confirmed showing only
      the single "Scan Redemption" button post-fix. One real bug (the duplicate button above) was
      found and fixed during this pass.

---

## Production Release

- [ ] **Complete "App content"** above for both apps (the actual remaining blocker)
- [ ] **Complete the Main store listing** (descriptions, category, graphics) for both apps
- [ ] **Promote from Internal testing to Production** once the above is done
- [ ] **Release type:** Manual (not staged rollout to start), matching the iOS convention of
      holding until ready rather than defaulting to automatic
- [ ] **Pricing:** Free (both apps, no in-app purchases) - matches iOS
- [ ] **Submit for Play review** - largely automated, typically hours rather than Apple's days

---

## Technical Requirements

- [x] **minSdk:** 24 (Android 7.0) - Flutter's own default, confirmed appropriate
- [x] **compileSdk:** 37 (bumped from 36 for `supplier_app` - `flutter_secure_storage` 11.0.0 requires it)
- [x] **Adaptive icon + display names** - real branded icons and `LoyaltyCards`/`LoyaltyCards Business` display names ship on Android
- [x] **Permissions reviewed** - `CAMERA` (`mobile_scanner`), `USE_BIOMETRIC`/`USE_FINGERPRINT` (`local_auth`), both contributed automatically via manifest merging - no storage permission needed
- [x] **Signing** - real release keystore + Gradle signing config for both apps, verified-signed release AAB built for each at v2.2.4+40

---

## Play-Specific Review Considerations

Play's review is largely automated and generally faster than Apple's human review (often hours,
not days), but a few areas get specific automated/policy scrutiny that don't map onto anything in
the iOS checklist:

- **Data Safety accuracy vs. actual behavior** - Play has been known to enforce this more
  literally than Apple's App Privacy label; this is the reason the anti-fraud device signal
  question above got a real decision rather than a reflexive "no data collected" answer.
- **Permissions justification** - Play can request an explanation for any sensitive permission at
  review time even without a dedicated pre-submission form for it; the Camera justification above
  covers this if asked.
- **Target API level policy** - Play enforces a minimum `targetSdk` for new/updated apps on a
  rolling basis (typically the current or previous Android version) independent of `minSdk`;
  confirm the actual current requirement in Play Console at submission time, since this policy
  updates yearly and isn't something to hardcode here.
- **"Two apps that require each other" framing** - same mitigation as the iOS checklist's common
  rejection reasons: both listings' descriptions already link to the companion app and frame this
  as a two-sided system (shop + customer), not an incomplete single app.

---

## Quick Reference: Required URLs

Same URLs as the iOS checklist - already hosted on Cloudflare Pages, directly reusable:

1. **Privacy Policy:** https://loyaltycards-site.pages.dev/legal/privacy-policy.html
2. **Terms of Service:** https://loyaltycards-site.pages.dev/legal/terms-of-service.html (no
   dedicated Play Console field either, same as App Store Connect - linked only from the app/site)
3. **Support:** https://loyaltycards-site.pages.dev/support/
4. **Accessibility Statement** (not a Play Console field, linked from the site):
   https://loyaltycards-site.pages.dev/legal/accessibility-statement.html

---

**Document Status:** 🟢 Both apps live on Internal testing, real-device tested successfully.
Everything remaining is the "App content" page (Content rating → App content declarations → Data
Safety, in that order) plus the Main store listing (descriptions/graphics/category), both purely
data-entry at this point - every answer needed is already decided above. Then promote to
Production and submit for Play review.
**Maintained by:** Development Team
**Last Updated:** September 4, 2026

---

**References:**
- [Play Console Help](https://support.google.com/googleplay/android-developer/)
- [Google Play Developer Program Policies](https://play.google.com/about/developer-content-policy/)
- `PLAY_STORE_METADATA_PACKET_v2_2_2_37.md` - full store listing copy and the Data Safety
  reasoning in detail
- `docs/project-management/ANDROID_PORT_PLAN.md` - Track 1/2 status and the full port history
- `APP_STORE_SUBMISSION_CHECKLIST.md` - the iOS equivalent this doc mirrors
