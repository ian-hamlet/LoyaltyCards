# LoyaltyCards v1.0.0 App Store Launch Plan

**Created:** April 22, 2026  
**Target Version:** v1.0.0 (First Public Release)  
**Current Version:** v0.3.0+1 (TestFlight)  
**Estimated Timeline:** 3-4 weeks  
**Status:** 📋 Planning Phase

---

## 🎯 Overview

This document provides a step-by-step action plan to launch LoyaltyCards v1.0.0 to the public App Store. Use this alongside the general [APP_STORE_SUBMISSION_CHECKLIST.md](APP_STORE_SUBMISSION_CHECKLIST.md) for complete coverage.

**Two Apps to Submit:**
1. **LoyaltyCards** (Customer App) - Free
2. **LoyaltyCards Business** (Supplier App) - Paid ($2.99 suggested)

---

## 📊 Progress Tracker

**Overall Progress:** 0% Complete

### Phase Completion
- [ ] Phase 1: Pre-Release Preparation (0/6)
- [ ] Phase 2: App Store Assets (0/4)
- [ ] Phase 3: Build & Upload (0/2)
- [ ] Phase 4: App Store Connect (0/4)
- [ ] Phase 5: Submit for Review (0/2)
- [ ] Phase 6: Review Process (0/2)
- [ ] Phase 7: Release Day (0/3)
- [ ] Phase 8: Post-Launch (0/2)

---

## 🚨 Critical Blockers (MUST RESOLVE FIRST)

These items will prevent submission - complete before starting other work:

### 1. Legal URLs 🔴 BLOCKER
**Status:** ❌ Not Started  
**Priority:** CRITICAL  
**Required for:** App Store Connect submission

**What's needed:**
- [ ] Privacy Policy URL (publicly accessible)
- [ ] Terms of Service URL (recommended)
- [ ] Support URL/Email (publicly accessible)

**Current Documents:**
- Source: [docs/legal/PRIVACY_POLICY.md](../legal/PRIVACY_POLICY.md)
- Source: [docs/legal/TERMS_OF_SERVICE.md](../legal/TERMS_OF_SERVICE.md)

**Action Required:** Host these documents publicly

**Option A: GitHub Pages (Recommended - Free & Fast)**
```bash
# 1. Create public GitHub Pages site
git checkout -b gh-pages
git push origin gh-pages

# 2. Enable in repo Settings → Pages → Source: gh-pages

# 3. Your URLs will be:
# https://ian-hamlet.github.io/LoyaltyCards/PRIVACY_POLICY.html
# https://ian-hamlet.github.io/LoyaltyCards/TERMS_OF_SERVICE.html
# https://ian-hamlet.github.io/LoyaltyCards/support.html
```

**Option B: Custom Domain (Professional)**
- Purchase domain (e.g., loyaltycards.app)
- Host on Netlify/Vercel/Cloudflare Pages (free)
- Custom URLs: https://loyaltycards.app/privacy

**Decision:** ________________ (GitHub Pages / Custom Domain)  
**Target Date:** ________________  
**URLs finalized:** ________________

---

### 2. Apple Developer Account 🟢 ASSUMED ACTIVE
**Status:** ✅ Active (TestFlight deployment confirms)  
**Annual Cost:** $99/year  
**Renewal Date:** ________________

---

### 3. Screenshots 🔴 BLOCKER
**Status:** ❌ Not Started  
**Priority:** CRITICAL  
**Quantity:** 30 total (15 per app × 2 apps)

**Required Sizes Per App:**
- 6.7" iPhone: 1290 x 2796 px (5 screenshots)
- 6.5" iPhone: 1242 x 2688 px (5 screenshots)
- 5.5" iPhone: 1242 x 2208 px (5 screenshots)

**Screenshots Needed - Customer App:**
1. Home screen with 2-3 active loyalty cards
2. Card detail showing progress (e.g., "3 of 5 stamps")
3. QR scanner ready to collect stamp
4. Redemption QR code displayed ("Ready to Redeem!")
5. Settings or transaction history screen

**Screenshots Needed - Supplier App:**
1. Business configuration screen
2. Issue card QR code displayed
3. Stamp issuance screen (with denomination picker)
4. Business analytics/statistics dashboard
5. Multi-device backup QR code

**Decision:**
- [ ] Use iPhone 14 Pro Max simulator
- [ ] Use physical device
- [ ] Hire designer (Fiverr/Upwork ~$50-100)

**Target Date:** ________________

---

### 4. Pricing Decision 🟡 NEEDS DECISION
**Status:** ⏳ Pending Decision  

**Customer App:** Free ✅  
**Supplier App:** $ __________ (Recommendations: $0.99, $1.99, $2.99, $4.99)

**Considerations:**
- Competitors charge $29-199/month subscriptions
- One-time purchase positions as "affordable alternative"
- $2.99 = "cup of coffee" pricing psychology
- Can change price later (requires new app version)

**Decision:** ________________  
**Decided By:** ________________

---

### 5. Marketing Copy 🟡 READY (Needs Review)
**Status:** ✅ Templates available in [APP_STORE_SUBMISSION_CHECKLIST.md](APP_STORE_SUBMISSION_CHECKLIST.md)  
**Action:** Review and customize if needed  
**Target Date:** ________________

---

## Phase 1: Pre-Release Preparation (Week 1)

**Duration:** 5-7 days  
**Goal:** Update code, host legal docs, prepare App Store Connect

### 1.1 Update Version Numbers ⏳

**Current Version:** v0.3.0+1  
**Target Version:** v1.0.0+100

**Files to Update:**
```
source/customer_app/pubspec.yaml
source/supplier_app/pubspec.yaml
source/shared/lib/version.dart
```

**Changes:**
```yaml
# In both pubspec.yaml files:
version: 1.0.0+100
```

**Checklist:**
- [ ] Update customer_app/pubspec.yaml to `1.0.0+100`
- [ ] Update supplier_app/pubspec.yaml to `1.0.0+100`
- [ ] Update source/shared/lib/version.dart release notes
- [ ] Document v1.0.0 changes in CHANGELOG.md
- [ ] Test builds locally after version change
- [ ] Commit changes to develop branch

**Command:**
```bash
cd /Users/ianhamlet/development/LoyaltyCards
# AI agent can help update these files
```

**Completion Date:** ________________

---

### 1.2 Host Legal Documents 🔴 BLOCKER

**See Critical Blocker #1 above for details**

**Steps:**
1. [ ] Choose hosting option (GitHub Pages recommended)
2. [ ] Convert Markdown to HTML
3. [ ] Upload to hosting
4. [ ] Test URLs from mobile browser
5. [ ] Save final URLs for App Store Connect

**URLs Finalized:**
- Privacy Policy: ________________________________
- Terms of Service: ________________________________
- Support: ________________________________

**Completion Date:** ________________

---

### 1.3 Create Release Branch

**Branch Name:** `releases/v1.0.0-production`

**Commands:**
```bash
git checkout main
git pull origin main
git checkout -b releases/v1.0.0-production
git push origin releases/v1.0.0-production
```

**Checklist:**
- [ ] Create branch from main
- [ ] Push to origin
- [ ] Document branch in docs/deployment/RELEASES.md
- [ ] Verify branch exists in GitHub

**Completion Date:** ________________

---

### 1.4 App Store Connect - Create Apps

**Go to:** https://appstoreconnect.apple.com → My Apps → + icon

#### Customer App Setup
- [ ] Click "New App"
- [ ] Platform: iOS
- [ ] Name: "LoyaltyCards" (or "LoyaltyCards - Digital Stamps")
- [ ] Primary Language: English (US)
- [ ] Bundle ID: `com.ianhamlet.loyaltycards.customerApp`
- [ ] SKU: `loyaltycards-customer-v1`
- [ ] User Access: Full Access

#### Supplier App Setup
- [ ] Click "New App"
- [ ] Platform: iOS
- [ ] Name: "LoyaltyCards Business"
- [ ] Primary Language: English (US)
- [ ] Bundle ID: `com.ianhamlet.loyaltycards.supplierApp`
- [ ] SKU: `loyaltycards-supplier-v1`
- [ ] User Access: Full Access

**Completion Date:** ________________

---

### 1.5 Set Pricing & Availability

**Customer App:**
- [ ] Pricing → Select "Free"
- [ ] Availability → All countries
- [ ] Release Date: Manual release (recommended for v1.0.0)

**Supplier App:**
- [ ] Pricing → Select price tier (e.g., $2.99 = Tier 3)
- [ ] Availability → All countries
- [ ] Release Date: Manual release

**Completion Date:** ________________

---

### 1.6 Complete App Privacy Questionnaire

**For Both Apps (identical settings):**

**Data Collection:** NO  
**Tracking:** NO

**Questionnaire Answers:**
- [ ] "Do you or your third-party partners collect data from this app?" → **NO**
- [ ] "Does this app use third-party advertising?" → **NO**
- [ ] "Does this app track users?" → **NO**

**Privacy Nutrition Label:**
```
Data Not Collected

The developer does not collect any data from this app.
```

**Rationale:** P2P architecture, no backend, no analytics, no user accounts

**Completion Date:** ________________

---

## Phase 2: App Store Assets Creation (Week 2)

**Duration:** 5-7 days  
**Goal:** Create screenshots, verify icons, prepare marketing copy

### 2.1 Screenshots - Customer App 📸

**Method:** Simulator screenshots or physical device

**Capture Process:**
```bash
# Open simulator
open -a Simulator

# Select device: iPhone 14 Pro Max (6.7")
# Run app: flutter run
# Navigate to each screen
# Cmd+S to save screenshot
```

**Required Screenshots (5 each for 3 sizes = 15 total):**

| # | Screen | Description | Status |
|---|--------|-------------|--------|
| 1 | Home/Wallet | 2-3 cards visible, various completion states | ☐ |
| 2 | Card Detail | Show 3/5 stamps collected | ☐ |
| 3 | QR Scanner | "Ready to scan" state, targeting square visible | ☐ |
| 4 | Redemption QR | Card showing "Ready to Redeem" with QR displayed | ☐ |
| 5 | Settings/History | Transaction log or settings screen | ☐ |

**Sizes:**
- [ ] 6.7" (1290 x 2796 px) - 5 screenshots
- [ ] 6.5" (1242 x 2688 px) - 5 screenshots
- [ ] 5.5" (1242 x 2208 px) - 5 screenshots

**Saved to:** `screenshots/customer_app/`

**Completion Date:** ________________

---

### 2.2 Screenshots - Supplier App 📸

**Required Screenshots (5 each for 3 sizes = 15 total):**

| # | Screen | Description | Status |
|---|--------|-------------|--------|
| 1 | Configuration | Business setup with name, color, icon | ☐ |
| 2 | Issue Card QR | Large QR code displayed for customer scanning | ☐ |
| 3 | Stamp Issuance | Denomination picker (1-5 stamps) visible | ☐ |
| 4 | Analytics | Statistics: cards issued, stamps given, redemptions | ☐ |
| 5 | Backup/Clone | Multi-device QR code or backup screen | ☐ |

**Sizes:**
- [ ] 6.7" (1290 x 2796 px) - 5 screenshots
- [ ] 6.5" (1242 x 2688 px) - 5 screenshots
- [ ] 5.5" (1242 x 2208 px) - 5 screenshots

**Saved to:** `screenshots/supplier_app/`

**Completion Date:** ________________

---

### 2.3 App Icons Verification

**Customer App Icon:**
- [ ] 1024x1024 PNG exists in `source/customer_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- [ ] No transparency
- [ ] No rounded corners in source file
- [ ] Visually distinct from Supplier app
- [ ] Test on home screen (device or simulator)

**Supplier App Icon:**
- [ ] 1024x1024 PNG exists in `source/supplier_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- [ ] No transparency
- [ ] No rounded corners
- [ ] Clearly indicates "Business" variant
- [ ] Test on home screen

**Completion Date:** ________________

---

### 2.4 Marketing Copy Review & Customization

**Source:** [APP_STORE_SUBMISSION_CHECKLIST.md](APP_STORE_SUBMISSION_CHECKLIST.md) lines 51-209

**Customer App:**
- [ ] Review app name (30 char limit): _________________________
- [ ] Review subtitle (30 char limit): _________________________
- [ ] Review promotional text (170 chars)
- [ ] Review full description (4000 chars)
- [ ] Review keywords (100 chars)
- [ ] Proofread for typos
- [ ] Save final copy to `marketing/customer_app_copy.txt`

**Supplier App:**
- [ ] Review app name (30 char limit): _________________________
- [ ] Review subtitle (30 char limit): _________________________
- [ ] Review promotional text (170 chars)
- [ ] Review full description (4000 chars)
- [ ] Review keywords (100 chars)
- [ ] Proofread for typos
- [ ] Save final copy to `marketing/supplier_app_copy.txt`

**Completion Date:** ________________

---

## Phase 3: Build & Upload (Week 3 - Day 1-2)

**Duration:** 1-2 days  
**Goal:** Create production IPA files and upload to App Store Connect

### 3.1 Create Production Builds

**Pre-Build Checks:**
- [ ] All code merged to `main` branch
- [ ] Version updated to 1.0.0+100 in both apps
- [ ] No debug print statements in code
- [ ] All tests passing (264 tests)
- [ ] Release branch created

**Build Commands:**
```bash
cd /Users/ianhamlet/development/LoyaltyCards/source

# Customer App
cd customer_app
flutter clean
flutter pub get
flutter pub upgrade
flutter build ipa --release

# Supplier App
cd ../supplier_app
flutter clean
flutter pub get
flutter pub upgrade
flutter build ipa --release
```

**Build Output Locations:**
- Customer: `source/customer_app/build/ios/ipa/customer_app.ipa`
- Supplier: `source/supplier_app/build/ios/ipa/supplier_app.ipa`

**Checklist:**
- [ ] Customer App builds successfully (no errors)
- [ ] Supplier App builds successfully (no errors)
- [ ] No deprecation warnings
- [ ] IPA files exist at expected locations
- [ ] Archive sizes reasonable (<50MB each)
- [ ] Verify version in IPA metadata: `1.0.0 (100)`

**Build Date:** ________________  
**Customer App Size:** ________ MB  
**Supplier App Size:** ________ MB

---

### 3.2 Upload to App Store Connect

**Tool:** Apple Transporter app (https://apps.apple.com/app/transporter/id1450874784)

**Upload Process:**
1. [ ] Install Transporter if not already installed
2. [ ] Sign in with Apple ID (same as App Store Connect)
3. [ ] Drag customer_app.ipa into Transporter
4. [ ] Click "Deliver"
5. [ ] Wait for upload completion (~5-15 min)
6. [ ] Repeat for supplier_app.ipa
7. [ ] Wait for "Processing Complete" emails

**Alternative - Command Line:**
```bash
xcrun altool --upload-app -f customer_app.ipa -t ios -u your@apple.com
xcrun altool --upload-app -f supplier_app.ipa -t ios -u your@apple.com
```

**Checklist:**
- [ ] Customer App uploaded successfully
- [ ] Supplier App uploaded successfully
- [ ] "Upload Successful" confirmation received
- [ ] Wait for processing complete emails (10-30 min)
- [ ] Builds appear in App Store Connect → TestFlight
- [ ] No processing errors or warnings

**Upload Date:** ________________  
**Processing Complete:** ________________

---

## Phase 4: App Store Connect Configuration (Week 3 - Day 3-5)

**Duration:** 2-3 hours per app  
**Goal:** Complete all metadata fields in App Store Connect

### 4.1 Customer App - Version 1.0 Configuration

**Navigate to:** App Store Connect → My Apps → LoyaltyCards → iOS App → 1.0 Prepare for Submission

#### Screenshots
- [ ] Upload 5 screenshots for 6.7" iPhone
- [ ] Upload 5 screenshots for 6.5" iPhone
- [ ] Upload 5 screenshots for 5.5" iPhone
- [ ] Preview screenshots in App Store Connect
- [ ] Verify screenshot order is correct

#### Promotional Text (Optional, 170 chars)
- [ ] Paste promotional text
- [ ] Verify character count
- [ ] Note: Can update without new app version

#### Description (4000 chars max)
- [ ] Paste full app description
- [ ] Verify character count
- [ ] Check formatting (line breaks preserved)
- [ ] Proofread one final time

#### Keywords (100 chars, comma-separated)
- [ ] Paste keywords
- [ ] Verify character count (including commas)
- [ ] No duplicates, no brand names

#### Support URL
- [ ] Enter support URL: ________________________________

#### Marketing URL (Optional)
- [ ] Enter marketing URL: ________________________________

#### Version (What's New) - 4000 chars max
```
Initial public release of LoyaltyCards!

Collect digital loyalty stamps from your favorite local businesses. Zero signup, complete privacy, works offline.

Features:
• Scan QR codes to collect stamps
• Manage multiple loyalty cards
• Redeem rewards when cards are complete
• Transaction history
• Works completely offline
• No personal data collection
```
- [ ] Paste what's new text
- [ ] Verify character count

#### Build Selection
- [ ] Click "+ Build" next to "Build"
- [ ] Select version 1.0.0 (100)
- [ ] Confirm selection

#### App Icon
- [ ] Upload 1024x1024 PNG icon
- [ ] Preview icon in App Store Connect

#### Age Rating
- [ ] Click "Edit" next to Age Rating
- [ ] Complete questionnaire (all "None" answers)
- [ ] Verify rating is "4+"
- [ ] Save

#### Copyright
- [ ] Enter: `© 2026 [Your Name or Company]`

**Completion Date:** ________________

---

### 4.2 Supplier App - Version 1.0 Configuration

**Navigate to:** App Store Connect → My Apps → LoyaltyCards Business → iOS App → 1.0 Prepare for Submission

#### Screenshots
- [ ] Upload 5 screenshots for 6.7" iPhone
- [ ] Upload 5 screenshots for 6.5" iPhone
- [ ] Upload 5 screenshots for 5.5" iPhone
- [ ] Preview and verify order

#### Promotional Text (170 chars)
- [ ] Paste promotional text
- [ ] Verify character count

#### Description (4000 chars)
- [ ] Paste full app description
- [ ] Verify formatting
- [ ] Proofread

#### Keywords (100 chars)
- [ ] Paste keywords
- [ ] Verify character count

#### Support URL
- [ ] Enter support URL (same as Customer App)

#### Marketing URL (Optional)
- [ ] Enter marketing URL

#### Version (What's New)
```
Initial public release of LoyaltyCards Business!

Run your loyalty program with zero monthly fees. Issue digital stamp cards to customers via QR codes.

Features:
• Configure your loyalty card program in 60 seconds
• Issue cards instantly via QR code
• Add stamps with a single scan
• Track redemptions and analytics
• Multi-device support (backup & clone)
• Simple or Secure mode (cryptographic signatures)
• Zero monthly fees - one-time purchase
```
- [ ] Paste what's new text

#### Build Selection
- [ ] Select version 1.0.0 (100)

#### App Icon
- [ ] Upload 1024x1024 PNG

#### Age Rating
- [ ] Complete questionnaire → 4+

#### Copyright
- [ ] Enter copyright notice

**Completion Date:** ________________

---

### 4.3 App Review Information (Both Apps)

**Customer App:**
- [ ] First Name: ________________________________
- [ ] Last Name: ________________________________
- [ ] Phone Number: ________________________________
- [ ] Email: ________________________________
- [ ] Demo Account: Not applicable (no accounts)

**Notes for Reviewer:**
```
TESTING INSTRUCTIONS:

This is a peer-to-peer (P2P) system - both apps work together via QR codes.

IMPORTANT: Install BOTH apps to test:
1. LoyaltyCards (this customer app)
2. LoyaltyCards Business (supplier app)

DEMO STEPS:

1. Open LoyaltyCards Business
   - Tap "Create New Business"
   - Name: "Test Coffee Shop"
   - Stamps required: 5
   - Mode: Simple Mode
   - Tap "Create Business"

2. Issue a card (Supplier → Customer)
   - In Supplier app: Tap "Issue Card"
   - QR code displays
   - In Customer app: Tap "Scan QR Code"
   - Scan the supplier's QR (or screenshot and scan)
   - Card appears in customer's wallet

3. Add stamps (Customer → Supplier)
   - In Customer app: Tap card, tap "Collect Stamp"
   - QR code displays
   - In Supplier app: Tap "Stamp Card"
   - Choose "3 stamps"
   - Tap "Generate Stamp QR"
   - Scan customer's QR
   - Stamps appear on card

4. Repeat step 3 until card has 5/5 stamps

5. Redeem card
   - In Customer app: Card shows "Ready to Redeem"
   - Tap "Show Redemption QR"
   - In Supplier app: Tap "Redeem Card"
   - Scan customer's redemption QR
   - Card marked complete, new card auto-created

NO INTERNET REQUIRED - All features work offline.
NO ACCOUNTS - No login, signup, or personal data collection.

Biometric auth (Face ID) only triggers on physical devices for sensitive operations (backup/restore in supplier app).

Please test both apps together. This is a two-sided marketplace (like Uber: riders + drivers).
```
- [ ] Paste testing instructions

**Supplier App:**
- [ ] First Name: (same as customer app)
- [ ] Last Name: (same as customer app)
- [ ] Phone Number: (same as customer app)
- [ ] Email: (same as customer app)

**Notes for Reviewer:**
```
See LoyaltyCards (customer app) for complete testing instructions.

Both apps work together via QR code scanning.

Additional Supplier Features to Test:

MULTI-DEVICE BACKUP:
- Settings → Create Recovery Backup
- Enter Face ID/passcode (physical device only)
- QR code displays
- Can scan this QR on another device to clone configuration

ANALYTICS:
- Main screen shows statistics
  - Cards issued today/this week/total
  - Unique cards stamped
  - Total stamps given
  - Total redemptions completed
```
- [ ] Paste testing instructions

**Completion Date:** ________________

---

### 4.4 Export Compliance (Both Apps)

**Question:** "Is your app designed to use cryptography or does it contain or incorporate cryptography?"

**Answer:** YES

**Follow-up:** "Does your app qualify for any of the exemptions provided in Category 5, Part 2?"

**Answer:** YES - Uses only standard encryption (ECDSA P-256, SHA-256)

**Explanation:**
```
This app uses industry-standard encryption algorithms:
- ECDSA P-256 for digital signatures (pointycastle package)
- SHA-256 for hashing (crypto package)

These are standard, non-proprietary algorithms available in iOS and widely used.
The app qualifies for encryption registration exemption under Category 5, Part 2.
```

**Checklist:**
- [ ] Customer App: Export compliance marked YES, exemption claimed
- [ ] Supplier App: Export compliance marked YES, exemption claimed
- [ ] No CCATS required (exempt under streamlined process)

**Completion Date:** ________________

---

## Phase 5: Submit for Review (Week 3 - Day 6-7)

**Duration:** 30-60 minutes  
**Goal:** Final checks and submission

### 5.1 Final Pre-Submission Testing

**Test on Physical Device:**
- [ ] Install Customer App v1.0.0 from TestFlight
- [ ] Install Supplier App v1.0.0 from TestFlight
- [ ] Complete full workflow:
  - [ ] Create business
  - [ ] Issue card
  - [ ] Add stamps (3 stamps)
  - [ ] Add more stamps (2 stamps)
  - [ ] Redeem card
  - [ ] Verify new card auto-created
- [ ] Test offline mode (airplane mode)
  - [ ] QR scanning works
  - [ ] Stamp issuance works
  - [ ] No crashes
- [ ] Test biometric auth (Supplier app backup)
  - [ ] Face ID prompts
  - [ ] Backup QR generates
- [ ] Check for any crashes or errors
- [ ] Verify no debug logging visible

**Final Content Review:**
- [ ] All URLs open in mobile browser
- [ ] Privacy policy displays correctly
- [ ] Terms of service displays correctly
- [ ] Support page/email is accessible
- [ ] Screenshots are high quality
- [ ] No typos in app descriptions
- [ ] App icons look good in App Store Connect preview

**Completion Date:** ________________

---

### 5.2 Submit Both Apps

**Submission Checklist:**

**Customer App:**
- [ ] All required fields complete (green checkmarks)
- [ ] Build selected
- [ ] Screenshots uploaded (all 3 sizes)
- [ ] App icon uploaded
- [ ] Privacy questionnaire complete
- [ ] Export compliance marked
- [ ] Review information complete
- [ ] Click "Submit for Review"
- [ ] Confirm submission in popup
- [ ] Status changes to "Waiting for Review"

**Supplier App:**
- [ ] All required fields complete
- [ ] Build selected
- [ ] Screenshots uploaded (all 3 sizes)
- [ ] App icon uploaded
- [ ] Privacy questionnaire complete
- [ ] Export compliance marked
- [ ] Review information complete
- [ ] Click "Submit for Review"
- [ ] Confirm submission
- [ ] Status changes to "Waiting for Review"

**Submission Date:** ________________  
**Time:** ________________

**Expected Timeline:**
- Review typically starts within 24-48 hours
- Review duration typically 24-48 hours
- Total: 2-4 days average

---

## Phase 6: Review Process (Week 4)

**Duration:** 1-3 days (Apple's timeline)  
**Goal:** Monitor review status and respond if needed

### 6.1 Monitor Review Status

**Daily Checks:**
- [ ] App Store Connect dashboard (morning)
- [ ] Email for App Review messages (throughout day)
- [ ] Phone available for Apple calls (rare but possible)

**Status Progression:**
1. **Waiting for Review** → Submitted, in queue
2. **In Review** → Reviewer is actively testing (24-48 hours)
3. **Pending Developer Release** → ✅ APPROVED! You control release timing
4. **Ready for Sale** → ✅ Live in App Store (if automatic release)
5. **Metadata Rejected** → Minor issues, fix and resubmit quickly
6. **Rejected** → Serious issues, requires code changes

**Response Time if Contacted:**
- Respond within 24 hours to App Review messages
- Check spam folder for Apple emails
- Keep phone on if Apple calls (they may have questions)

**Review Start Date:** ________________  
**Review Complete Date:** ________________  
**Final Status:** ________________

---

### 6.2 Potential Rejection Scenarios & Responses

Keep these responses ready in case of rejection:

#### Scenario 1: "App requires another app to function"

**Response Template:**
```
Thank you for your review.

LoyaltyCards is a two-sided marketplace system, similar to:
- Uber (riders + drivers)
- Airbnb (guests + hosts)  
- Square (consumer payment + merchant register)

The Customer app is for consumers collecting loyalty stamps.
The Business app is for merchants issuing stamps.

Each app functions independently for its target audience:
- Customer app: Manages loyalty cards, collects stamps, tracks redemptions
- Business app: Configures loyalty programs, issues cards, tracks analytics

This architecture is necessary for the two distinct user types: customers and businesses. Both apps provide complete functionality for their respective users.

Similar apps with two-sided marketplaces:
- Uber Driver + Uber
- DoorDash Driver + DoorDash
- Square Register + Cash App
```

---

#### Scenario 2: "No backend/login system"

**Response Template:**
```
Thank you for your feedback.

The lack of a backend server is a deliberate architectural choice for privacy and security:

ARCHITECTURE:
This is a peer-to-peer (P2P) system, similar to Apple AirDrop. Data is exchanged directly between devices via QR codes. No central server, no user accounts, no data collection.

PRIVACY BENEFITS:
- Zero personal data collection (no email, phone, name)
- No tracking or analytics
- Complete GDPR compliance (no data = no privacy issues)
- User data never leaves their device

SECURITY BENEFITS:
- No central database to hack
- No user credentials to steal
- Cryptographic signatures prevent fraud (Secure Mode)

TECHNICAL PRECEDENT:
Apps like Signal, Briar, and other P2P apps use similar architectures.

This is a feature, not a missing feature. Our privacy-first approach differentiates us from traditional loyalty systems that require extensive personal information.

Please let me know if you need additional technical documentation about the P2P architecture.
```

---

#### Scenario 3: "App crashes during testing"

**Response Template:**
```
Thank you for identifying the crash. Could you please provide:

1. Crash logs from App Store Connect
2. Device model and iOS version used for testing
3. Specific steps that trigger the crash

IMPORTANT NOTES:

Biometric Authentication:
- Face ID/Touch ID requires physical device with biometric hardware
- Simulator falls back to passcode entry
- Only used in Supplier app for backup/restore features

Tested Configuration:
We have tested extensively on:
- iPhone 12 Pro (iOS 15.0+)
- iPhone 14 Pro Max (iOS 16.0+)
- iPad Pro 12.9" (iOS 15.0+)
- All features work as expected

Please test on physical device if using Simulator.

With crash logs, we can fix the specific issue and resubmit within 24 hours.
```

---

#### Scenario 4: "Incomplete functionality"

**Response Template:**
```
Thank you for your review.

Could you please clarify which functionality appears incomplete?

All advertised features are fully implemented and tested:

CUSTOMER APP COMPLETE FEATURES:
✅ QR scanning (collect stamps)
✅ Wallet management (multiple cards)
✅ Redemption (show redemption QR)
✅ Transaction history
✅ Search/filter cards
✅ Settings

SUPPLIER APP COMPLETE FEATURES:
✅ Business configuration
✅ Issue card (QR generation)
✅ Stamp issuance (QR scanning)
✅ Card redemption (QR scanning)
✅ Analytics dashboard
✅ Multi-device backup/clone
✅ Settings

TESTING NOTE:
Both apps must be installed to test the complete flow (they work together via QR codes). Please see the testing instructions in App Review Information for step-by-step demo.

If there's a specific feature that appears incomplete, please let me know so I can demonstrate or fix it immediately.
```

---

#### Scenario 5: "Privacy concerns"

**Response Template:**
```
Thank you for reviewing privacy.

PRIVACY COMMITMENT:
This app collects ZERO user data. We take privacy extremely seriously.

DATA COLLECTION: NONE
- No email addresses
- No phone numbers
- No names
- No user accounts
- No analytics
- No tracking
- No third-party SDKs that collect data

DATA STORAGE: LOCAL ONLY
- All loyalty cards stored locally on user's device
- Nothing sent to servers (no servers exist)
- No cloud sync

PRIVACY DOCUMENTATION:
- Privacy Policy: [your URL]
- App Privacy Nutrition Label: "Data Not Collected"
- Privacy-first architecture documented in codebase

COMPLIANCE:
- GDPR compliant (no data = no compliance issues)
- CCPA compliant (no data collection)
- No parental consent required (no data collected)

We can provide technical documentation of our P2P architecture if needed.
```

---

## Phase 7: Release Day (Week 4+)

**Duration:** 30 minutes  
**Goal:** Release apps to public and monitor

### 7.1 Release Approved Apps

**When Status = "Pending Developer Release":**

**Option 1: Manual Release (Recommended)**
- [ ] Customer App → Version 1.0 → "Release This Version"
- [ ] Supplier App → Version 1.0 → "Release This Version"
- [ ] Confirm release
- [ ] Apps go live within 2-4 hours

**Option 2: Automatic Release**
- Apps released automatically upon approval
- No control over timing

**Release Date:** ________________  
**Release Time:** ________________

---

### 7.2 Verify Apps are Live

**Wait 2-4 hours after release, then check:**

**Customer App:**
- [ ] Search "LoyaltyCards" in App Store (on device)
- [ ] App appears in search results
- [ ] Can tap to view app page
- [ ] Price shows "Free"
- [ ] "Get" button works
- [ ] Can download and install
- [ ] Save App Store URL: ________________________________

**Supplier App:**
- [ ] Search "LoyaltyCards Business" in App Store
- [ ] App appears in search results
- [ ] Price shows correctly ($2.99 or your chosen price)
- [ ] "Buy" button works
- [ ] Save App Store URL: ________________________________

**Verification Date:** ________________

---

### 7.3 Initial Marketing

**Day 1 Actions:**
- [ ] Share Customer App link on social media
- [ ] Share Supplier App link on social media
- [ ] Email friends/family about launch
- [ ] Post in relevant communities (Reddit, Product Hunt)
- [ ] Reach out to pilot businesses (coffee shops)
- [ ] Monitor App Store Connect for downloads

**First 7 Days:**
- [ ] Respond to every review (positive or negative) within 24 hours
- [ ] Monitor crash reports in App Store Connect
- [ ] Check support email twice daily
- [ ] Track download numbers
- [ ] Screenshot positive reviews for marketing

**Marketing Links:**
- App Store - Customer: ________________________________
- App Store - Supplier: ________________________________
- Twitter/X Post: ________________________________
- Product Hunt: ________________________________

---

## Phase 8: Post-Launch Monitoring (Ongoing)

**Duration:** Ongoing  
**Goal:** Support users and plan updates

### 8.1 Daily Monitoring (Days 1-30)

**Every Morning:**
- [ ] Check App Store Connect for new reviews
- [ ] Check crash reports (Analytics → Crashes)
- [ ] Check support email
- [ ] Review download numbers

**Every Evening:**
- [ ] Respond to new reviews
- [ ] Update launch metrics spreadsheet

**Metrics to Track:**
```
Date | Customer DLs | Supplier DLs | Reviews (⭐) | Crashes | Support Emails
-----|-------------|--------------|--------------|---------|----------------
     |             |              |              |         |
```

**First Week Summary Date:** ________________  
**Total Customer Downloads:** ________________  
**Total Supplier Downloads:** ________________  
**Average Rating:** ________________  
**Crash-Free Rate:** ________________

---

### 8.2 Critical Issue Response Plan

**If Crash Rate > 1%:**
1. [ ] Download crash logs from App Store Connect
2. [ ] Reproduce crash locally
3. [ ] Fix bug immediately
4. [ ] Submit v1.0.1 hotfix within 24-48 hours

**If Negative Review Mentions Bug:**
1. [ ] Reproduce issue
2. [ ] Fix bug
3. [ ] Reply to review: "Thank you for reporting this. Fixed in v1.0.1, available soon!"
4. [ ] Submit update

**If Support Email Overload:**
1. [ ] Create FAQ document
2. [ ] Update support page with common issues
3. [ ] Consider in-app help or tutorial

---

## 📋 Master Checklist Summary

Use this as your daily checklist:

### Pre-Launch
- [ ] Version updated to 1.0.0+100
- [ ] Legal URLs live (privacy, terms, support)
- [ ] Screenshots captured (30 total)
- [ ] Marketing copy finalized
- [ ] Pricing decision made
- [ ] Release branch created

### App Store Connect
- [ ] Both apps created in ASC
- [ ] Pricing set
- [ ] Privacy questionnaires complete
- [ ] Export compliance marked
- [ ] Review information complete
- [ ] Builds uploaded
- [ ] Builds selected for submission

### Assets
- [ ] Customer screenshots uploaded (15)
- [ ] Supplier screenshots uploaded (15)
- [ ] Customer app icon uploaded
- [ ] Supplier app icon uploaded
- [ ] Descriptions pasted
- [ ] Keywords pasted

### Submission
- [ ] Final testing complete
- [ ] Customer app submitted
- [ ] Supplier app submitted
- [ ] Review monitoring active

### Post-Approval
- [ ] Apps released to public
- [ ] Verified live in App Store
- [ ] Initial marketing posted
- [ ] Daily monitoring active
- [ ] Support process active

---

## 📞 Emergency Contacts

**Apple Developer Support:**
- Phone: 1-800-633-2152 (US)
- Hours: 7am - 5pm PT, Monday-Friday
- Email via App Store Connect

**App Review Board (Expedited Review Request):**
- Only for critical issues
- https://developer.apple.com/contact/app-store/?topic=expedite

**Your Contact Info for Reference:**
- Phone: ________________________________
- Email: ________________________________
- Best time to reach: ________________________________

---

## 🎯 Success Criteria

**Launch Considered Successful When:**
- [ ] Both apps approved on first submission (or within 2 resubmissions)
- [ ] Both apps live in App Store
- [ ] Zero critical crashes (< 0.1% crash rate)
- [ ] Average rating ≥ 4.0 stars
- [ ] At least 10 downloads in first week
- [ ] At least 1 paying customer (Supplier app)
- [ ] Zero support emails unanswered > 24 hours

**Stretch Goals:**
- [ ] 100 downloads in first month
- [ ] 10 paying customers in first month
- [ ] Featured in App Store (unlikely but possible)
- [ ] 4.5+ star rating with 10+ reviews
- [ ] Media coverage or blog mentions

---

## 📚 Reference Documents

- [APP_STORE_SUBMISSION_CHECKLIST.md](APP_STORE_SUBMISSION_CHECKLIST.md) - General checklist
- [TESTFLIGHT_DEPLOYMENT_GUIDE.md](TESTFLIGHT_DEPLOYMENT_GUIDE.md) - TestFlight process
- [RELEASES.md](RELEASES.md) - Version history
- [docs/legal/PRIVACY_POLICY.md](../legal/PRIVACY_POLICY.md) - Privacy policy source
- [docs/legal/TERMS_OF_SERVICE.md](../legal/TERMS_OF_SERVICE.md) - Terms source
- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

---

## ✅ Next Steps

**This Week:**
1. Decide on legal URL hosting (GitHub Pages recommended)
2. Set Supplier app price
3. Begin screenshot capture

**Target Launch Date:** ________________

**Launch Readiness:** _____ % complete

---

**Document Version:** 1.0  
**Last Updated:** April 22, 2026  
**Maintained By:** Development Team  
**Status:** 📋 Active Planning Document

---

## 💡 Tips for Success

**Do:**
- ✅ Test on physical devices before submission
- ✅ Respond to App Review within 24 hours
- ✅ Submit both apps simultaneously
- ✅ Keep marketing copy clear and honest
- ✅ Proofread everything twice
- ✅ Monitor email/phone during review

**Don't:**
- ❌ Submit with test data visible in screenshots
- ❌ Promise features not yet implemented
- ❌ Use competitor app names in keywords
- ❌ Ignore reviewer feedback
- ❌ Rush without testing
- ❌ Submit on Friday (harder to fix issues over weekend)

**Best Practices:**
- Submit early in week (Monday-Wednesday) for faster review
- Be prepared to fix issues quickly
- Have contingency plan for rejection
- Stay calm during review process
- Celebrate small wins along the way

---

**Good luck with your v1.0.0 launch! 🚀**
