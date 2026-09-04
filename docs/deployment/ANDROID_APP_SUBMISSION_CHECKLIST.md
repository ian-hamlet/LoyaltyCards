# Android (Google Play) Submission Checklist

**LoyaltyCards v2.2.3+38**
**Customer App:** LoyaltyCards Customer Wallet (`com.ianhamlet.loyaltycards.customer`)
**Supplier App:** LoyaltyCards Business (`com.ianhamlet.loyaltycards.supplier`)
**Target Release:** 🔴 Not yet submitted - Track 2 (Play Console) work in progress, blocked on
Google Play Developer account registration (device-verification step - see below). Nothing in
this checklist has been entered into Play Console yet; it's a copy-paste/tick-through companion
to `PLAY_STORE_METADATA_PACKET_v2_2_2_37.md`, mirroring the pattern of
`APP_STORE_SUBMISSION_CHECKLIST.md` on the iOS side.
**Last Updated:** September 2, 2026

**Status note:** iOS is live (`APP_STORE_SUBMISSION_CHECKLIST.md`, currently v2.2.1+36 approved
and released). Android is a separate, later submission under the same version line - see
`docs/project-management/ANDROID_PORT_PLAN.md` for the full port history (Track 1: technical
port, complete; Track 2: this checklist, in progress). The two platforms are **not** kept on
identical version numbers by policy - each ships independently as its own review/approval cycle
completes, the same way the two iOS apps under one Apple account already do.

Play Console's field set differs from App Store Connect's in ways that matter throughout this
checklist: **one description field (no separate Subtitle/Promotional Text/Keywords)**, **a single
Category (no primary/secondary split)**, a self-service **IARC content rating questionnaire**
instead of static Age Rating fields, a **Data Safety form** instead of the App Privacy "nutrition
label," an **Internal testing track** instead of TestFlight (no review gate at all for internal
testers), and an **.aab** (Android App Bundle) upload instead of an **.ipa**.

---

## Pre-Submission Requirements

### Code & Build Preparation

- [x] **Final version incremented** across all three `pubspec.yaml` files + `source/shared/lib/version.dart` - `2.2.3+38`, confirmed in sync (customer_app, supplier_app, shared)
- [x] **Version number confirmed** - v2.2.3+38 (patch bump, not build-only - see version.dart Build 38: a real Android-only bug fix in the anti-fraud device signal, found while working this checklist's Data Safety section)
- [ ] **All code merged to `main` branch** - still on `feature/android-port`, not yet merged to `develop`/`main`
- [ ] **Release branch created** - not yet, follows the same convention as iOS releases once this branch is ready
- [ ] **Release AABs built** via `source/build_both_apps_android.sh` (added alongside this checklist - mirrors `build_both_apps_ios.sh`, outputs `<app>/build/app/outputs/bundle/release/app-release.aab` for both apps). Needs each app's `android/key.properties` present (machine-local, gitignored, points at the shared release keystore - see `ANDROID_PORT_PLAN.md` Phase 5) or the script warns and falls back to a debug-signed build Play Console will reject.
- [x] **Release AABs verified signed** - done once already during Phase 5 (2026-08-31, before this checklist existed): both apps' AABs confirmed signed with the real keystore (not the debug fallback) via `jarsigner -verify -verbose -certs`. Re-verify after the next real build, since the device-signal fix above hasn't been built into an AAB yet.
- [x] **All automated tests passing** - shared 216, customer_app 184 (+8 skipped), supplier_app 151 (+4 skipped) - re-confirmed 2026-09-02 after the device-signal fix
- [x] **`flutter analyze` clean** on all three packages - re-confirmed 2026-09-02
- [ ] **Critical bugs resolved** - the Android device-signal bug (see below) is fixed in code but **not yet re-verified on the Android emulator/real hardware** - do this before building the AAB for submission, not just relying on the unit tests

---

## Google Play Developer Account

- [ ] **Register the account** ($25 one-time fee, not recurring - contrast with Apple's $99/year) - **the developer's own action** (Google login + payment)
- [ ] **Device-verification step** - 🔴 **current blocker**, in progress as of 2026-09-02. Google's
      anti-fraud check for new developer accounts wants proof of an actual physical Android device
      tied to the account; the emulator used for all functional/screenshot work doesn't satisfy
      it. See the chat log / `ANDROID_PORT_PLAN.md` "Open Decisions / Risks" for the device
      sourcing discussion (recommendation: a used Google Pixel 4a/5a/6a-range phone - Play
      certified, has a fingerprint sensor and autofocus camera, cheap secondhand).
- [ ] Once registered: **create the two Play Console app listings** (one account, two listings -
      same pattern as the two App Store Connect listings under one Apple Developer account)

---

## App Setup - Basic Info

#### Customer App: LoyaltyCards Customer Wallet
- [ ] **App name** (30 chars max): `LoyaltyCards Customer Wallet` (28 chars)
- [ ] **Package name:** `com.ianhamlet.loyaltycards.customer` - fixed at first upload, cannot be
      changed later, double-check before the first AAB upload
- [ ] **Category:** Lifestyle (Play allows one category only - App Store's secondary "Shopping"
      has no Play slot; consider as an optional Tag once Play Console's current tag list is
      visible)
- [ ] **Default language:** English (United Kingdom)

#### Supplier App: LoyaltyCards Business
- [ ] **App name** (30 chars max): `LoyaltyCards Business` (21 chars)
- [ ] **Package name:** `com.ianhamlet.loyaltycards.supplier` - fixed at first upload
- [ ] **Category:** Business (App Store's secondary "Productivity" has no Play slot; consider as
      an optional Tag)
- [ ] **Default language:** English (United Kingdom)

---

## Store Listing Content

Full copy-paste text lives in
[`PLAY_STORE_METADATA_PACKET_v2_2_2_37.md`](PLAY_STORE_METADATA_PACKET_v2_2_2_37.md) - drafted
2026-08-31, still accurate (no user-facing copy changed by the device-signal fix). This section is
just the entry checklist against Play Console's actual fields:

- [ ] **Short description** (80 chars max, both apps) - entered
- [ ] **Full description** (4000 chars max, both apps) - entered
- [ ] **App icon** (512×512 PNG) - see "Graphic Assets" below
- [ ] **Feature graphic** (1024×500 PNG) - see "Graphic Assets" below
- [ ] **Phone screenshots** - see "Graphic Assets" below
- [ ] **Privacy Policy URL:** https://loyaltycards-site.pages.dev/legal/privacy-policy.html (both apps)

Play has no separate Subtitle/Promotional Text/Keywords fields the way App Store Connect does -
everything beyond the short/full description above is out of scope here.

---

## Graphic Assets

- [x] **App icon** (512×512 PNG) - exported 2026-09-02 directly from the same 1024px branded
      source already used for `flutter_launcher_icons`, via `sips`. Approved by the developer
      2026-09-02.
      `store_graphics/customer_app/app_icon_512.png`, `store_graphics/supplier_app/app_icon_512.png`
- [x] **Feature graphic** (1024×500 PNG) - drafted and approved 2026-09-02: branded gradient
      (matching each app's `adaptive_icon_background`), the existing app icon art, wordmark, and a
      short tagline pulled from the descriptions above.
      `store_graphics/customer_app/feature_graphic.png`, `store_graphics/supplier_app/feature_graphic.png`
- [x] **Phone screenshots** - captured 2026-09-02, real device screenshots off the Android
      emulator (`adb exec-out screencap`), not mockups. 13 per app in
      `screenshots/customer_app/android/` and `screenshots/supplier_app/android/`. Play's
      minimum is 2 per app - pick the strongest 4-8 per app for the actual listing rather than
      uploading all of them (same guidance as the metadata packet).
- [ ] **Upload all of the above into Play Console** - not yet done, account doesn't exist yet
- [ ] **Tablet screenshots** - optional, only needed if either app is listed as tablet-optimized (not currently planned - skip unless that changes)

---

## Content Rating (IARC Questionnaire)

Expected answers (mirrors the App Store's "all None"/4+ outcome - full detail and reasoning in
the metadata packet's "Content Rating" section):

- [ ] Violence: None
- [ ] Sexual content: None
- [ ] Profanity: None
- [ ] Controlled substances: None
- [ ] Gambling: None (loyalty stamps are not a game of chance, no real-money value)
- [ ] User-generated content: None
- [ ] Shares location: No
- [ ] Allows user interaction/communication: No
- [ ] **Entered into Play Console's actual questionnaire** (both apps) - self-service, in-console
      only, nothing submittable in advance

**Expected Rating:** Everyone / 3+ (Play's closest equivalent to Apple's 4+)

---

## Data Safety Form

**Decided 2026-09-02** - the two apps get different answers; full reasoning in the metadata
packet's "Data Safety Form" section. Summary for entering into Play Console:

#### Supplier App: No
- [ ] **Does the app collect/share required user data types?** **No.** It only ever *receives* the
      customer's device signal inbound (scanned from a QR code) and stores it locally for its own
      fraud check - never retransmits it anywhere. Never in question, unaffected by the device-
      signal fix.

#### Customer App: Yes - one data type
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
- [ ] **Security practices:** data encrypted in transit - N/A (no network transmission, travels
      inside a QR code image); users can request deletion - Yes (delete the app); data not sold to
      third parties - confirmed
- [ ] **Entered into Play Console** (both apps)

Note: this is a **more disclosure-friendly answer** than it would have been pre-fix, not because
the Play Console checkbox changed (it doesn't - "shared" was already true either way), but because
the value itself is now honestly describable as "an app-generated identifier, not derived from
your device's hardware or OS" rather than a hash of one.
- [ ] **Entered into Play Console** (both apps) - blocked on the decision above

---

## App Content Declarations

Play's "App content" section covers several standalone declarations that have no App Store
Connect equivalent in this shape:

- [ ] **Target audience & content:** not primarily child-directed (general/business utility tool)
- [ ] **Government app:** No
- [ ] **COVID-19 app:** No (not a contact-tracing/status app)
- [ ] **Financial features:** No real-money transactions, payments, or financial services -
      loyalty stamps have no cash value
- [ ] **Ads declaration:** No ads in either app
- [ ] **Permissions declaration form** - Play may ask for justification of sensitive runtime
      permissions during review. Camera (`CAMERA`) is the only sensitive one either app
      requests - contributed automatically by `mobile_scanner`, confirmed via the actual merged
      manifest during Android Phase 4 (see `ANDROID_PORT_PLAN.md`). Justification: "scan QR codes
      to issue/collect/redeem loyalty stamps" - matches the Play Store listing description
      already.

---

## Internal Testing Track

Play's equivalent of TestFlight - **no review gate at all** for internal testers, a meaningful
speed advantage over Apple's Beta App Review step:

- [ ] **Configure the Internal testing track** for both apps
- [ ] **Add internal testers** by email (the developer's own account/device at minimum)
- [ ] **Upload the first internal test AAB** for both apps - the Phase 5 release AABs exist
      already but need rebuilding first to pick up the Build 38 device-signal fix
- [ ] **Confirm install via the Play Console opt-in link** on the verification device once it
      exists
- [ ] **Internal test pass on real hardware** - covers what the emulator already confirmed
      functionally (issue/stamp/redeem, both modes, biometric-gated backup/clone, QR camera scan)
      plus specifically re-verifying the Build 38 device-signal fix, which has no emulator/unit
      coverage of its own yet

---

## Production Release

- [ ] **Promote from Internal testing to Production** once the above is verified
- [ ] **Release type:** Manual (not staged rollout to start) - matches the iOS convention of
      holding both apps' releases until both are ready, though Play's two listings under one
      account don't have the exact same cross-app timing risk App Store Connect's manual-release
      workaround was solving (each Play listing releases independently by default regardless)
- [ ] **Pricing:** Free (both apps, no in-app purchases) - matches iOS

---

## Technical Requirements

- [x] **minSdk:** 24 (Android 7.0, released 2016) - Flutter's own default
      (`flutter.minSdkVersion`), not a custom override; confirmed appropriate for 2026, see
      `ANDROID_PORT_PLAN.md` Phase 4
- [x] **compileSdk:** 37 (bumped from 36 for `supplier_app` - `flutter_secure_storage` 11.0.0
      requires it)
- [x] **Adaptive icon + display names** - real branded icons and `LoyaltyCards`/`LoyaltyCards
      Business` display names ship on Android (previously Flutter's literal placeholder icon and
      raw package-name labels) - see `ANDROID_PORT_PLAN.md` Phase 4
- [x] **Permissions reviewed** - `CAMERA` (`mobile_scanner`), `USE_BIOMETRIC`/`USE_FINGERPRINT`
      (`local_auth`), both contributed automatically via manifest merging, confirmed against the
      actual merged manifest, not just the source one - no storage permission needed (scoped,
      app-private storage only)
- [x] **Signing** - real release keystore + Gradle signing config for both apps, verified-signed
      release AAB built for each (Phase 5, 2026-08-31) - needs rebuilding to pick up Build 38

---

## Play-Specific Review Considerations

Play's review is largely automated and generally faster than Apple's human review (often hours,
not days), but a few areas get specific automated/policy scrutiny that don't map onto anything in
the iOS checklist:

- **Data Safety accuracy vs. actual behavior** - Play has been known to enforce this more
  literally than Apple's App Privacy label; this is the reason the anti-fraud device signal
  question above needs a real decision rather than a reflexive "no data collected" answer.
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

**Document Status:** 🔴 Draft, nothing yet entered into Play Console - blocked on Google Play
Developer account registration (device-verification step). Store listing text, graphics,
screenshots, and now the Data Safety answers (decided 2026-09-02) are all ready to paste in the
moment the account exists.
**Maintained by:** Development Team
**Last Updated:** September 2, 2026

---

**References:**
- [Play Console Help](https://support.google.com/googleplay/android-developer/)
- [Google Play Developer Program Policies](https://play.google.com/about/developer-content-policy/)
- `PLAY_STORE_METADATA_PACKET_v2_2_2_37.md` - full store listing copy and the Data Safety
  reasoning in detail
- `docs/project-management/ANDROID_PORT_PLAN.md` - Track 1/2 status and the full port history
- `APP_STORE_SUBMISSION_CHECKLIST.md` - the iOS equivalent this doc mirrors
