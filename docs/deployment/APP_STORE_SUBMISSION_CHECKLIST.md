# App Store Submission Checklist

**LoyaltyCards v0.2.0**  
**Customer App:** LoyaltyCards - Digital Stamps  
**Supplier App:** LoyaltyCards Business  
**Target Release:** TBD  
**Last Updated:** April 18, 2026

---

## Pre-Submission Requirements

### ✅ Code & Build Preparation

- [ ] **Final build number incremented** in pubspec.yaml (both apps)
- [ ] **Version number confirmed** (v0.2.0 for initial release)
- [ ] **All code merged to `main` branch**
- [ ] **Release branch created** `releases/v0.2.0-build{N}`
- [ ] **Archive builds completed**
  ```bash
  cd 03-Source/customer_app
  flutter clean && flutter pub get
  flutter build ipa --release
  
  cd ../supplier_app
  flutter clean && flutter pub get
  flutter build ipa --release
  ```
- [ ] **IPA files uploaded to App Store Connect** via Transporter
- [ ] **Build processing complete** in App Store Connect (10-15 min wait)
- [ ] **No build warnings or errors**
- [ ] **All compilation errors resolved**
- [ ] **TestFlight beta testing completed** (minimum 1 week)
- [ ] **Critical bugs resolved** (zero CRITICAL defects in DEFECT_TRACKER.md)

---

### 📱 App Store Connect - Basic Information

#### Customer App: LoyaltyCards - Digital Stamps

- [ ] **App Name:** LoyaltyCards - Digital Stamps (or "LoyaltyCards")
- [ ] **Bundle ID:** `com.ianhamlet.loyaltycards.customerApp`
- [ ] **SKU:** `loyaltycards-customer-001`
- [ ] **Primary Language:** English (US)
- [ ] **Primary Category:** Lifestyle
- [ ] **Secondary Category:** Shopping (optional)
- [ ] **Content Rights:** Confirm you own or have licensed all content

#### Supplier App: LoyaltyCards Business

- [ ] **App Name:** LoyaltyCards Business
- [ ] **Bundle ID:** `com.ianhamlet.loyaltycards.supplierApp`
- [ ] **SKU:** `loyaltycards-supplier-001`
- [ ] **Primary Language:** English (US)
- [ ] **Primary Category:** Business
- [ ] **Secondary Category:** Productivity (optional)
- [ ] **Content Rights:** Confirm you own or have licensed all content

---

### 📝 App Descriptions & Marketing

#### Customer App Description (Max 4000 characters)

**Subtitle (30 chars max):**
```
Collect stamps, earn rewards
```

**Promotional Text (170 chars, updatable without review):**
```
Digital loyalty cards for your favorite businesses. Collect stamps, earn rewards. No signup required. Fast, private, secure.
```

**Description:**
```
Transform your wallet with LoyaltyCards - the simplest way to collect stamps and earn rewards at your favorite local businesses.

WHY LOYALTYCARDS?

• Zero Signup - Scan a QR code and start collecting instantly
• Complete Privacy - No email, no phone number, no tracking
• Works Offline - No internet connection required
• Secure by Design - Cryptographically verified stamps prevent fraud
• Always Available - Your loyalty cards never leave home

HOW IT WORKS

1. Business shows you a QR code
2. You scan it with LoyaltyCards
3. Collect stamps each visit
4. Get your reward when complete

PERFECT FOR

• Coffee shops and cafes
• Restaurants and food trucks
• Retail stores and boutiques
• Salons and spas
• Any business offering loyalty rewards

PRIVACY FIRST

We don't collect your personal information. Period. No email, no phone number, no account creation, no tracking, no data sharing. Your loyalty cards stay on your device.

SIMPLE & SECURE MODES

Choose how you collect stamps:
• Simple Mode: Fast stamp collection (like physical cards)
• Secure Mode: Cryptographically verified stamps (fraud-proof)

SMALL BUSINESS FRIENDLY

Works perfectly with our companion app, LoyaltyCards Business, designed for small businesses who want to run loyalty programs without expensive systems or monthly fees.

Download LoyaltyCards today and start earning rewards!
```

**Keywords (100 chars max, comma-separated):**
```
loyalty,rewards,stamps,coffee,local business,qr code,privacy,offline,small business,punch card
```

---

#### Supplier App Description (Max 4000 characters)

**Subtitle (30 chars max):**
```
Digital loyalty card system
```

**Promotional Text (170 chars):**
```
Run your loyalty program with zero monthly fees. Issue digital stamp cards to customers. Works offline. No customer data collection. Perfect for small businesses.
```

**Description:**
```
Transform your customer loyalty program with LoyaltyCards Business - the zero-cost alternative to expensive loyalty systems.

WHY LOYALTYCARDS BUSINESS?

• $0 Monthly Fees - No subscriptions, no hidden costs
• No Customer Data Collection - Privacy-first design
• Works Offline - No internet connection required
• Multi-Device Support - Use on multiple iPads/iPhones
• No Customer App Required* - Customers use free LoyaltyCards app
• Setup in 60 Seconds - Start issuing cards immediately

PERFECT FOR

• Coffee shops and cafes
• Restaurants and food trucks
• Retail stores and boutiques
• Salons and spas
• Farmers markets and pop-ups
• Any small business wanting loyal customers

HOW IT WORKS

1. Configure your stamp card (business name, stamps required)
2. Show customers your QR code
3. They scan with LoyaltyCards app (free download)
4. Issue stamps each visit with one scan
5. Scan their redemption QR when card is complete

SIMPLE & SECURE MODES

• Simple Mode: Fast stamp issuance (trust-based, like physical cards)
• Secure Mode: Cryptographically signed stamps (fraud-proof digital signatures)

MULTI-DEVICE SUPPORT

Run your loyalty program across multiple devices:
• Backup your configuration with one QR scan
• Clone to new devices (registers, iPads, staff phones)
• All devices issue stamps for the same program

BUSINESS ANALYTICS

Track your loyalty program performance:
• Cards issued today/this week/all time
• Stamps given out
• Cards redeemed
• Simple dashboard, no complicated reports

PRIVACY FOCUSED

Unlike traditional loyalty systems, you don't collect customer emails, phone numbers, or personal information. Customers appreciate the privacy, you avoid GDPR complexity.

NO ONGOING COSTS

Other loyalty systems charge:
• $29-$199/month subscriptions
• Per-transaction fees
• Setup fees
• Customer data storage fees

LoyaltyCards Business: One-time app purchase, zero ongoing costs.

*Note: Customers need the free LoyaltyCards app to collect stamps.

Download LoyaltyCards Business and start building customer loyalty today!
```

**Keywords (100 chars max):**
```
loyalty program,small business,coffee shop,rewards,stamps,qr code,point of sale,customer retention
```

---

### 📸 Screenshots & App Previews

#### Customer App Screenshots (Required Sizes)

**6.7" Display (iPhone 14 Pro Max, 15 Pro Max)** - 1290 x 2796 pixels
- [ ] Screenshot 1: Home screen with active loyalty cards
- [ ] Screenshot 2: Card detail showing stamps collected
- [ ] Screenshot 3: QR scanner ready to collect stamp
- [ ] Screenshot 4: Redemption QR code displayed
- [ ] Screenshot 5: Transaction history

**6.5" Display (iPhone 14 Plus, 11 Pro Max)** - 1242 x 2688 pixels
- [ ] Same 5 screenshots as above

**5.5" Display (iPhone 8 Plus, 7 Plus)** - 1242 x 2208 pixels
- [ ] Same 5 screenshots as above

**12.9" iPad Pro (3rd gen+)** - 2048 x 2732 pixels (optional)
- [ ] Same screenshots optimized for iPad layout

#### Supplier App Screenshots (Required Sizes)

**6.7" Display** - 1290 x 2796 pixels
- [ ] Screenshot 1: Business configuration screen
- [ ] Screenshot 2: Issue card QR code
- [ ] Screenshot 3: Stamp issuance screen
- [ ] Screenshot 4: Business analytics dashboard
- [ ] Screenshot 5: Multi-device backup/clone

**6.5" Display** - 1242 x 2688 pixels
- [ ] Same 5 screenshots

**5.5" Display** - 1242 x 2208 pixels
- [ ] Same 5 screenshots

**12.9" iPad Pro** - 2048 x 2732 pixels (optional)
- [ ] Same screenshots optimized for iPad

---

### 🎨 App Icon

- [ ] **Icon files included** in Xcode asset catalog
- [ ] **All required sizes present** (20pt - 1024pt)
- [ ] **1024x1024 App Store icon** uploaded (PNG, no transparency)
- [ ] **Icon follows guidelines** (no iOS UI elements, no rounded corners in source)
- [ ] **Customer & Supplier icons visually distinct**

---

### 📋 App Information

#### Age Rating Questionnaire

- [ ] **Unrestricted Web Access:** No
- [ ] **Alcohol, Tobacco, Drugs:** None
- [ ] **Profanity or Crude Humor:** None
- [ ] **Sexual Content or Nudity:** None
- [ ] **Cartoon or Fantasy Violence:** None
- [ ] **Realistic Violence:** None
- [ ] **Medical/Treatment Information:** None
- [ ] **Gambling:** None (loyalty stamps not considered gambling)
- [ ] **Horror/Fear Themes:** None

**Expected Rating:** 4+ (all ages)

---

#### Privacy Policy

- [ ] **Privacy Policy URL:** [Required - must be publicly accessible]
  - Hosted at: TBD (e.g., https://loyaltycards.app/privacy)
  - File available: [PRIVACY_POLICY.md](PRIVACY_POLICY.md)
- [ ] **Privacy Policy content accurate**
- [ ] **No data collection statement** clearly stated
- [ ] **GDPR compliant** (privacy-first design)

---

#### Terms of Service

- [ ] **Terms of Service URL:** [Optional but recommended]
  - Hosted at: TBD (e.g., https://loyaltycards.app/terms)
  - File available: [TERMS_OF_SERVICE.md](TERMS_OF_SERVICE.md)
- [ ] **Terms cover both customer and supplier use**
- [ ] **Fraud prevention disclaimers included**

---

#### Support URL

- [ ] **Support URL:** [Required]
  - TBD (e.g., https://loyaltycards.app/support or support email)
- [ ] **Support contact method** confirmed and monitored

---

#### Marketing URL

- [ ] **Marketing URL:** [Optional]
  - TBD (e.g., https://loyaltycards.app)

---

### 🔐 Export Compliance

- [ ] **App uses encryption:** YES
  - ECDSA P-256 signatures (pointycastle)
  - SHA-256 hashing (crypto)
- [ ] **Encryption is:** Exempt (standardized encryption, no proprietary algorithms)
- [ ] **CCATS required:** NO (exempt under streamlined encryption)
- [ ] **Export Compliance documentation** reviewed

**Recommended Answer:**
- Uses standard encryption (AES, RSA, ECDSA)
- No proprietary encryption
- Qualifies for Encryption Registration exemption

---

### 📞 Contact Information

- [ ] **First Name:** [Your first name]
- [ ] **Last Name:** [Your last name]
- [ ] **Phone Number:** [Required, for Apple contact]
- [ ] **Email Address:** [Must be monitored]
- [ ] **Demo Account:** Not applicable (no backend/accounts)

---

### 💰 Pricing & Availability

#### Customer App
- [ ] **Price:** Free (with optional In-App Purchases: NO)
- [ ] **Availability:** All countries/regions
- [ ] **Release Date:** Automatic or manual release (choose one)

#### Supplier App
- [ ] **Price:** TBD ($0.99 - $4.99 suggested one-time purchase)
- [ ] **Availability:** All countries/regions
- [ ] **Release Date:** Automatic or manual release

---

### 🧪 App Review Information

#### Demo Instructions for Reviewers

**Customer App:**
```
HOW TO TEST:

1. Install both apps: "LoyaltyCards" (customer) and "LoyaltyCards Business" (supplier)

2. Configure Supplier App:
   - Open LoyaltyCards Business
   - Tap "Create New Business"
   - Business name: "Test Coffee Shop"
   - Stamps required: 5
   - Choose any color and icon
   - Mode: Simple Mode (easier testing)
   - Tap "Create Business"

3. Issue a Card to Customer:
   - In Supplier App, main screen shows "Issue Card" button
   - Tap "Issue Card"
   - Supplier app displays QR code
   - Switch to Customer app (LoyaltyCards)
   - Tap "Scan QR Code"
   - Scan the QR code from Supplier app (or screenshot and scan from Photos)
   - Card appears in Customer app

4. Add Stamps:
   - In Customer app, tap the card
   - Tap "Collect Stamp" button
   - Customer app displays QR code
   - Switch to Supplier app
   - Tap "Stamp Card" button
   - Choose "3 stamps" from picker
   - Tap "Generate Stamp QR"
   - Scan the customer's QR code with Supplier app
   - Stamps appear on customer's card

5. Redeem Card:
   - Repeat step 4 until card has 5/5 stamps
   - In Customer app, card shows "Ready to Redeem"
   - Tap card, tap "Show Redemption QR"
   - In Supplier app, tap "Redeem Card"
   - Scan customer's redemption QR
   - Card marked complete

NO NETWORK REQUIRED - All features work offline.
NO ACCOUNT REQUIRED - No login, signup, or personal information.
```

**Supplier App:**
```
See Customer App testing instructions above - both apps work together.

Additional Supplier Features:

MULTI-DEVICE BACKUP:
- Settings → Create Recovery Backup
- Displays QR code (biometric auth required on physical device)
- Can scan this QR on another device to clone configuration

ANALYTICS:
- Main screen shows statistics
  - Cards issued
  - Unique cards stamped
  - Total stamps given
  - Total redemptions
```

---

#### Contact Information for App Review

- [ ] **Phone Number:** [Monitored during review process]
- [ ] **Email Address:** [Checked daily during review]
- [ ] **Notes for Reviewers:**
```
This is a peer-to-peer (P2P) digital loyalty card system. No backend servers, no user accounts, no data collection.

Both apps (Customer and Supplier) work together via QR code scanning.

Biometric authentication (Face ID) only triggers on physical devices for sensitive operations. Simulator testing may show passcode fallback.

All features work offline. No internet connection required.

Please test both apps together following the demo instructions.
```

---

### ✅ Technical Requirements

- [ ] **iOS Minimum Version:** 13.0+ (confirmed in Info.plist)
- [ ] **Supported Devices:** iPhone, iPad
- [ ] **Supported Orientations:** Portrait (primary), landscape (supported)
- [ ] **App performs as expected** on all device sizes
- [ ] **No crashes during testing**
- [ ] **All UI elements accessible** (not cut off)
- [ ] **Loading states implemented** for all async operations
- [ ] **Error messages user-friendly** (not developer jargon)
- [ ] **Permissions requested with clear explanation:**
  - Camera (QR scanning): "Scan QR codes to collect stamps"
  - Face ID (Supplier only): "Authenticate to view private keys"
  - None required (all backup methods use standard iOS share sheet)

---

### 🔍 App Review Guidelines Compliance

#### Functionality
- [ ] **App is complete** (not a demo or trial)
- [ ] **App is functional** (no placeholder content)
- [ ] **No beta/test references** in UI or marketing text
- [ ] **Buttons and features work** as described

#### Performance
- [ ] **App doesn't crash** during normal use
- [ ] **No memory leaks** detected
- [ ] **Launch time < 3 seconds**
- [ ] **Smooth scrolling** on all supported devices

#### Business Model
- [ ] **Business model clear** (Customer: free, Supplier: paid)
- [ ] **No hidden costs** after purchase
- [ ] **No subscription** (one-time purchase only)

#### Design
- [ ] **Follows iOS design guidelines**
- [ ] **Native iOS look and feel**
- [ ] **Consistent UI throughout**
- [ ] **Dark mode support** (if applicable)

#### Legal
- [ ] **Privacy policy accurate** and accessible
- [ ] **Terms of service** available
- [ ] **No copyright infringement** (all content original or licensed)
- [ ] **Complies with export regulations**

---

### 📦 Pre-Submission Final Checks

- [ ] **Run full regression test** on physical device
- [ ] **Test on oldest supported iOS** (iOS 13.0)
- [ ] **Test on smallest screen** (iPhone SE)
- [ ] **Test on largest screen** (iPhone Pro Max)
- [ ] **Test on iPad** (if supported)
- [ ] **Verify all QR scanning scenarios** work
- [ ] **Verify biometric auth** works (physical device only)
- [ ] **Test offline functionality** (airplane mode)
- [ ] **Review all error messages** for clarity
- [ ] **Check all navigation flows**
- [ ] **Verify Settings screens** display correctly
- [ ] **Test backup/restore** (Supplier app)
- [ ] **Verify privacy policy link** works

---

### 🚀 Submission Process

1. [ ] **Upload build to App Store Connect** (via Transporter)
2. [ ] **Select build** for Customer app submission
3. [ ] **Select build** for Supplier app submission
4. [ ] **Complete all required fields** in App Store Connect
5. [ ] **Upload screenshots** for all required device sizes
6. [ ] **Submit for review** (both apps simultaneously recommended)
7. [ ] **Monitor review status** (typically 24-48 hours)
8. [ ] **Respond to App Review** if questions arise (24-hour response time)
9. [ ] **Release approved apps** (manual or automatic)

---

### 📊 Post-Submission

- [ ] **Monitor App Store Connect** for review updates
- [ ] **Check email** for App Review messages
- [ ] **Prepare response** for potential rejection reasons:
  - Incomplete features → Explain P2P architecture
  - Crashes → Fix and resubmit
  - Missing demo → Provide detailed instructions
  - Privacy concerns → Reference privacy-first design
- [ ] **Plan for Day 1 support** inquiries
- [ ] **Monitor crash reports** in App Store Connect
- [ ] **Track download statistics**
- [ ] **Collect user feedback** for next update

---

### 🔄 Common Rejection Reasons & Mitigations

**"App requires both apps to function"**
- Mitigation: Customer app description clearly states "Works with LoyaltyCards Business"
- Response: "This is a two-sided marketplace (customers + suppliers), similar to Uber (riders + drivers)"

**"No backend/server"**
- Mitigation: Explain P2P architecture in review notes
- Response: "Peer-to-peer architecture, similar to AirDrop. No backend required."

**"Incomplete functionality in simulator"**
- Mitigation: Note that biometric auth requires physical device
- Response: "Face ID authentication requires physical device. All other features testable in simulator."

**"Privacy concerns"**
- Mitigation: Reference VULNERABILITIES.md and privacy-first design
- Response: "Zero data collection. No user accounts, emails, phone numbers, or tracking. Complete privacy."

---

## Quick Reference: Required URLs

Before submission, host these documents publicly:

1. **Privacy Policy:** https://[yourdomain]/privacy
   - Source: [PRIVACY_POLICY.md](PRIVACY_POLICY.md)
2. **Terms of Service:** https://[yourdomain]/terms
   - Source: [TERMS_OF_SERVICE.md](TERMS_OF_SERVICE.md)
3. **Support:** https://[yourdomain]/support or support@[yourdomain]
4. **Marketing (optional):** https://[yourdomain]

---

**Document Status:** 🚧 Draft - Complete before first App Store submission  
**Maintained by:** Development Team  
**Last Updated:** April 18, 2026

---

**References:**
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Beta Testing Guide](https://developer.apple.com/testflight/)
