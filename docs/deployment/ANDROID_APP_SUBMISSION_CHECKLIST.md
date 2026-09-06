# Android (Google Play) Submission Checklist

**LoyaltyCards v2.2.4+40**
**Customer App:** LoyaltyCards Customer Wallet (`com.ianhamlet.loyaltycards.customer`)
**Supplier App:** LoyaltyCards Business (`com.ianhamlet.loyaltycards.supplier`)
**Target Release:** 🟡 **PAUSED 2026-09-06.** Both apps live on Google Play Internal testing,
real-device tested successfully (see `ANDROID_PORT_PLAN.md` Track 2). Work on the Play Console
listing itself is mid-flight (see status per item below) but **paused pending a decision on
recruiting Closed testing testers** - see the requirement below, discovered live while working
through the Customer app's submission tonight. iOS (same v2.2.4+40) is unaffected and already
**live on the App Store** - see `APP_STORE_SUBMISSION_CHECKLIST.md`.
**Last Updated:** September 6, 2026

---

## ⚠️ Closed Testing Requirement for Personal Developer Accounts (read this first)

**Correction to this document's own prior text:** an earlier version of this checklist said Play's
review is "largely automated and generally faster than Apple's, often hours not days." That was
wrong on both counts, discovered live tonight via Google's own Help Centre article ("App testing
requirements for new personal developer accounts") after the Play Console dashboard itself
surfaced a requirement neither this document nor the earlier planning conversation had accounted
for. Corrected here in full, since it changes the realistic release timeline materially.

**The actual requirement** (personal Google Play Console accounts created after 13 November 2026 -
this developer's account, registered 2026-09-04, is one): before **Production** access is even
available, you must run a **Closed testing** track (a separate track from Internal testing -
Internal testing does not count toward this) with:
- At least **12 testers** opted in
- **Continuously** opted in for the preceding **14 days** at the point you apply

Only after that can you **apply for production access** (Dashboard → "Apply for production"),
answering three sections (about the closed test, about the app, about production readiness).
Google then reviews the application - **"usually seven days or less, but can occasionally take
longer"** (Google's own wording) - not hours. If fewer than 12 testers are opted in, or tester
engagement looks weak, Google can require more testing time before reapplying.

**Realistic floor: roughly 3 weeks** from the day a closed test actually has 12 people properly
opted in - not "tomorrow," not "this week." This is a hard, unavoidable gate, not a technicality -
confirmed directly from Google's own policy documentation, not an assumption.

**Not yet resolved:** whether this gate applies once per developer account (clearing it with the
Customer app might exempt the Supplier app too) or separately per app. Google's article doesn't
say either way - check the Supplier app's own Dashboard for this once it's relevant, rather than
assuming.

**Do not attempt to shortcut the 12-tester number with fake accounts, bots, or a bulk-tester
service** - that is exactly the kind of activity this policy exists to catch, and risks the whole
developer account being suspended, not just this app.

**Current decision:** paused. Recruiting 12 genuine testers (friends, family, colleagues, or a
wider ask) needs to happen before this resumes - see `ANDROID_PORT_PLAN.md` for the live decision
once made.

---

## Pre-Submission Requirements

### Code & Build Preparation

- [x] **Final version incremented** across all three `pubspec.yaml` files + `source/shared/lib/version.dart` - `2.2.4+40`, confirmed in sync
- [x] **All code merged** - `feature/android-port` → `develop` (`767f641`), release branch `releases/v2.2.4-build40` cut from `develop`
- [x] **Release AABs built** via `source/build_both_apps_android.sh` for both apps, confirmed release-signed via `jarsigner -verify` (not the debug-signing fallback)
- [x] **All automated tests passing** - shared 216, customer_app 184 (+8 skipped), supplier_app 151 (+4 skipped)
- [x] **`flutter analyze` clean** on all three packages
- [x] **Critical bugs resolved** - the Android device-signal bug (Build 38) and a duplicate redemption button (Build 39/40) both fixed and shipped in v2.2.4+40

---

## Google Play Developer Account

- [x] **Account registered** - completed 2026-09-04
- [x] **Device-verification step** - resolved 2026-09-04: developer sourced and reset two real Android devices (Samsung Galaxy A14/A12)
- [x] **Both Play Console app listings created** - `com.ianhamlet.loyaltycards.customer` and `com.ianhamlet.loyaltycards.supplier`, 2026-09-04

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
      the single "Scan Redemption" button post-fix.

Note: this track does **not** count toward the Closed testing requirement above - it's a separate,
unrelated track kept for exactly what it's already been used for (real-hardware functional
verification), not for satisfying the 12-tester/14-day gate.

---

## Customer App - Live Play Console Progress (as of 2026-09-06, paused mid-flight)

Worked through live tonight via the Dashboard's "Changes not yet submitted for review" checklist.
Exact state, so this can resume without re-deriving anything:

- [x] **Content Rating** - questionnaire submitted and **completed** live 2026-09-06, 00:29.
      Result confirmed exactly as expected: Everyone/All ages/PEGI 3/USK: All ages/Rated 3+ across
      every region (Brazil, ESRB, PEGI, USK, IARC Generic, Russia, South Korea).
- [ ] **Target audience and content** - mid-wizard (5 steps: Target age → App details → Ads →
      Store presence → Summary). Decided: **check only "18 and over"** (leave every younger
      bracket unchecked - ticking any of them pulls the app into Google's Families Policy program,
      which conflicts with the Customer app's Data Safety disclosure). Leave the optional "Restrict
      users that Google has determined to be minors" checkbox **unchecked** - there's no reason to
      actively bar minors from an ordinary loyalty-stamp app; 18+ here is the conservative choice
      to avoid Families Policy machinery, not a genuine adults-only restriction. Not yet confirmed
      how far through the 5-step wizard this got before pausing - re-check on resume.
- [x] **Ads declaration** - confirmed already set to "No, my app does not contain ads" during the
      wizard's step 2.
- [ ] **Data safety** - mid-wizard (5 steps: Overview → Data collection and security → Data types
      → Data usage and handling → Preview). Step 2 answers decided live:
      - Encrypted in transit: **No** (this is a strict Yes/No on the real form, not "N/A" as
        earlier drafts of this document assumed - the device signal travels inside a QR code
        image, not a network protocol, so it isn't wrapped in transit-encryption at all)
      - Account creation methods: **"My app does not allow users to create an account"**
      - Can users log in with accounts created outside the app: **No**
      - Data deletion request mechanism: **Yes**, Delete data URL:
        `https://loyaltycards-site.pages.dev/legal/data-deletion.html` (page built and deployed
        to `main` 2026-09-06 specifically for this field - see `site/legal/data-deletion.html`)
      - Additional badges (Independent security review, UPI payments verified): **skip both**,
        not applicable
      - Not yet reached: **Data types** (step 3 - the actual Device ID disclosure: Collected No /
        Shared Yes / Purpose fraud prevention / not ephemeral / Required / not used for tracking),
        **Data usage and handling** (step 4), **Preview** (step 5) and final submit.
- [ ] **Health apps declaration** - discovered live, not previously tracked in this document.
      Decided: **No** - neither app does anything health-related (no fitness tracking, no medical
      data, no health records), same category of answer as the COVID-19 declaration.
- [ ] **Privacy policy URL** - needs entering and saving:
      `https://loyaltycards-site.pages.dev/legal/privacy-policy.html`
- [ ] **App category** (Store settings) - Lifestyle, not yet selected/saved
- [ ] **Main store listing** (short/full description, icon, feature graphic, screenshots) - not
      yet entered, see "Store Listing Content" and "Graphic Assets" below for the exact
      copy/assets

---

## Supplier App - Ready-to-Paste Answers (not yet started in Play Console)

Same walkthrough as the Customer app above, worked out in advance so this is pure data entry
whenever it's picked up. The Supplier app's answers are simpler throughout - no data type to
configure in Data Safety, and the account/login/deletion-mechanism answers are identical.

- **Content Rating:** identical answers to Customer (all None/No) → expected Everyone/3+
- **Target audience:** **18 and over only**, minors-restriction checkbox **unchecked** - same
  reasoning as Customer
- **Ads declaration:** **No, my app does not contain ads**
- **Data safety:**
  - Does the app collect/share any required user data type? **No** (it only ever *receives* the
    customer's device signal inbound via a scanned QR code and stores it locally for its own
    fraud check - never retransmits it anywhere, so nothing to disclose)
  - Account creation methods: **"My app does not allow users to create an account"**
  - Can users log in with accounts created outside the app: **No**
  - Data deletion request mechanism: **Yes**, Delete data URL:
    `https://loyaltycards-site.pages.dev/legal/data-deletion.html` (same shared page, already
    names both apps)
  - Advertising ID: **No**
- **Health apps declaration:** **No**
- **Privacy policy URL:** `https://loyaltycards-site.pages.dev/legal/privacy-policy.html`
- **App category** (Store settings): **Business**
- **Short description:**
  ```
  Free digital stamp cards for shops. No fees, no accounts, no customer data.
  ```
- **Full description:** see `PLAY_STORE_METADATA_PACKET_v2_2_2_37.md` → "Supplier App → Full Description"
- **Graphics:** `store_graphics/supplier_app/app_icon_512.png`, `store_graphics/supplier_app/feature_graphic.png`, 4-8 screenshots from `screenshots/supplier_app/android/`

**Check when this app's Dashboard is first opened:** whether the Closed testing requirement above
shows as already satisfied (if it's an account-level gate) or as its own separate 12-tester/14-day
requirement (if it's per-app) - not yet known which, per the note in the Closed Testing section
above.

---

## Store Listing Content (both apps)

Full copy-paste text lives in
[`PLAY_STORE_METADATA_PACKET_v2_2_2_37.md`](PLAY_STORE_METADATA_PACKET_v2_2_2_37.md) - still
accurate, no user-facing store copy has changed since.

**Customer App:**
- Short description: `Free loyalty stamp wallet. No account, no server, no data collected. Ever.`
- Full description: see metadata packet → "Customer App → Full Description"

Play has no separate Subtitle/Promotional Text/Keywords fields the way App Store Connect does -
everything beyond the short/full description is out of scope here.

---

## Graphic Assets

- [x] **App icon** (512×512 PNG) - `store_graphics/customer_app/app_icon_512.png`, `store_graphics/supplier_app/app_icon_512.png`, approved 2026-09-02
- [x] **Feature graphic** (1024×500 PNG) - `store_graphics/customer_app/feature_graphic.png`, `store_graphics/supplier_app/feature_graphic.png`, approved 2026-09-02
- [x] **Phone screenshots** - 13 per app, real captures, in `screenshots/customer_app/android/` and `screenshots/supplier_app/android/` - pick the strongest 4-8 per app for the actual listing rather than uploading all of them
- [ ] **Upload all of the above into Play Console's Main store listing page** - not yet done
- [ ] **Tablet screenshots** - optional, not currently planned

---

## Production Release (blocked - see Closed Testing Requirement above)

- [ ] Recruit 12 genuine testers and run Closed testing for 14 continuous days
- [ ] Complete "App content" above for both apps (independent of the testing gate, can continue in parallel)
- [ ] Complete the Main store listing for both apps
- [ ] **Apply for production access** (Dashboard → "Apply for production") once the 12/14 requirement is met - answer the three sections (about the closed test, about the app, about production readiness)
- [ ] Google review - typically ≤7 days per their own guidance, can be longer
- [ ] Release type: Manual (not staged rollout to start), matching the iOS convention
- [ ] Pricing: Free (both apps, no in-app purchases) - matches iOS

---

## Technical Requirements

- [x] **minSdk:** 24 (Android 7.0) - Flutter's own default, confirmed appropriate
- [x] **compileSdk:** 37 (bumped from 36 for `supplier_app` - `flutter_secure_storage` 11.0.0 requires it)
- [x] **Adaptive icon + display names** - real branded icons and `LoyaltyCards`/`LoyaltyCards Business` display names ship on Android
- [x] **Permissions reviewed** - `CAMERA` (`mobile_scanner`), `USE_BIOMETRIC`/`USE_FINGERPRINT` (`local_auth`), both contributed automatically via manifest merging - no storage permission needed
- [x] **Signing** - real release keystore + Gradle signing config for both apps, verified-signed release AAB built for each at v2.2.4+40

---

## Play-Specific Review Considerations

- **Closed testing gate for personal accounts** - see the dedicated section at the top of this
  document. The single biggest correction to earlier assumptions in this checklist.
- **Data Safety accuracy vs. actual behavior** - Play has been known to enforce this more
  literally than Apple's App Privacy label; this is the reason the anti-fraud device signal
  question got a real decision rather than a reflexive "no data collected" answer.
- **Permissions justification** - Play can request an explanation for any sensitive permission at
  review time even without a dedicated pre-submission form for it. Camera justification if asked:
  "scan QR codes to issue/collect/redeem loyalty stamps."
- **Target API level policy** - Play enforces a minimum `targetSdk` for new/updated apps on a
  rolling basis (typically the current or previous Android version) independent of `minSdk`;
  confirm the actual current requirement in Play Console at submission time, since this policy
  updates yearly and isn't something to hardcode here.
- **"Two apps that require each other" framing** - same mitigation as the iOS checklist's common
  rejection reasons: both listings' descriptions already link to the companion app and frame this
  as a two-sided system (shop + customer), not an incomplete single app.

---

## Quick Reference: Required URLs

1. **Privacy Policy:** https://loyaltycards-site.pages.dev/legal/privacy-policy.html
2. **Data deletion:** https://loyaltycards-site.pages.dev/legal/data-deletion.html
3. **Terms of Service:** https://loyaltycards-site.pages.dev/legal/terms-of-service.html (no
   dedicated Play Console field, same as App Store Connect - linked only from the app/site)
4. **Support:** https://loyaltycards-site.pages.dev/support/
5. **Accessibility Statement** (not a Play Console field, linked from the site):
   https://loyaltycards-site.pages.dev/legal/accessibility-statement.html

---

**Document Status:** 🟡 **PAUSED 2026-09-06** - both apps live on Internal testing and
real-device tested successfully, but the path to Production requires a Closed testing track with
12 testers opted in continuously for 14 days (a personal-developer-account requirement discovered
live tonight, not previously known), which hasn't started. The Customer app's App content
declarations are mid-flight (Content Rating done, Ads confirmed, Data Safety and Target audience
partway through, Health apps and Privacy policy URL not yet entered) - all decided answers are
recorded above so nothing needs re-deriving on resume. iOS (same v2.2.4+40) is unaffected and
already live on the App Store.
**Maintained by:** Development Team
**Last Updated:** September 6, 2026

---

**References:**
- [Play Console Help](https://support.google.com/googleplay/android-developer/)
- [Google Play Developer Program Policies](https://play.google.com/about/developer-content-policy/)
- `PLAY_STORE_METADATA_PACKET_v2_2_2_37.md` - full store listing copy and the Data Safety
  reasoning in detail
- `docs/project-management/ANDROID_PORT_PLAN.md` - Track 1/2 status and the full port history
- `APP_STORE_SUBMISSION_CHECKLIST.md` - the iOS equivalent this doc mirrors (already live)
