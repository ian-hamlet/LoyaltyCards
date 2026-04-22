# About LoyaltyCards

**A Privacy-First Digital Loyalty Card System**

Version 0.2.0 (Build 21)  
Last Updated: April 20, 2026

---

## What is LoyaltyCards?

LoyaltyCards is a **digital stamp card system** that replaces traditional paper punch cards while respecting your privacy. It consists of two apps working together:

- **Customer App** - Your digital wallet for loyalty cards
- **Supplier App** - Business tool for issuing and managing cards

**Core Philosophy:** Maximum convenience with minimal data collection.

---

## 🔒 Privacy & Data Protection

### Zero Personal Data Collection

**We don't collect ANY personal information:**
- ❌ No name required
- ❌ No email address
- ❌ No phone number
- ❌ No account creation
- ❌ No login credentials
- ❌ No tracking across businesses

**What we DO collect:**
- ✅ Anonymous loyalty card data (stamps, redemptions)
- ✅ Stored ONLY on your device
- ✅ Never sent to our servers (we don't have servers!)

### Complete Anonymity

**For Customers:**
- Open the app, get a card - that's it
- No signup, no forms, no questions
- Your identity remains completely private
- Even the business doesn't know who you are

**For Businesses:**
- Simple onboarding process
- Name your business, choose settings
- No payment required during pilot
- No subscription fees (pilot phase)

### Local Storage Only

**Everything stays on your device:**
- Customer cards stored in local database on phone
- Business data stored on supplier's device only
- **Peer-to-Peer (P2P) architecture** - devices communicate directly via QR codes
- **No cloud servers** - no data mining, no breaches, no third-party access
- **No internet required** - works completely offline

**GDPR Compliant by Design:**
- No personal data = no GDPR concerns
- Users control their data (it's on their device)
- Right to erasure: delete the app = data gone
- Data portability: backup/restore your own data

---

## 🎯 Two Operation Modes

LoyaltyCards offers two modes to fit different business needs:

### **Simple Mode** - Trust-Based (Coffee Shop Model)

**How it works:**
- Business displays **static QR codes** at checkout
- Customer scans QR code to add stamp
- QR codes **never expire** - print once, use forever
- Based on trust - customer could scan multiple times
- **Rate limited:** Customer can only get 1 stamp per hour per business (prevents abuse)

**Best for:**
- ✅ Coffee shops
- ✅ Cafes and bakeries
- ✅ Quick service restaurants
- ✅ High-trust environments
- ✅ Regular customers (locals who frequent the business)
- ✅ Low-value rewards ($5-10 free coffee)
- ✅ High transaction volume (speed matters)

**Advantages:**
- ⚡ **Super fast** - scan and go (2 seconds)
- 📄 **Low tech** - just printed QR codes
- 💰 **No equipment needed** - no tablet required
- 🔄 **Self-service** - customer stamps themselves
- 🎯 **Frictionless** - no supplier interaction needed

**Trade-offs:**
- ⚠️ Requires customer honesty (can't prevent determined fraud)
- ⚠️ 1-hour rate limit is enforced by customer app (not foolproof)

**Real-World Scenario:**

*"Joe's Coffee Shop" - Simple Mode*

**Setup:**
1. Joe prints two QR codes and tapes them to the register
2. One says "Get Loyalty Card" (issue card QR)
3. One says "Add Your Stamp" (stamp QR)

**Customer Experience:**
- First visit: Sarah scans "Get Loyalty Card" → card appears in app
- Sarah scans "Add Your Stamp" → gets first stamp
- Every visit: Sarah scans "Add Your Stamp" → gets stamp
- 10th visit: Sarah's card is complete
- Sarah scans "Redeem Your Reward" QR → card resets, new card created
- Total time per visit: **2 seconds**

**Why This Works:**
- Sarah is a regular who comes daily
- She values the free coffee
- She's honest and won't abuse the system
- Joe trusts his regulars
- Speed matters during morning rush

---

### **Secure Mode** - Cryptographically Validated (High-Value Model)

**How it works:**
- Business generates **time-limited QR codes** (valid 1-2 minutes)
- Customer scans QR code to add stamp
- Each stamp is **cryptographically signed** with business's private key
- Customer app validates signature using public key
- **Hash chain** ensures stamps can't be forged or replayed
- Supplier scans customer's QR code to redeem

**Best for:**
- ✅ High-value rewards ($50-500 items)
- ✅ Luxury goods stores
- ✅ Spas and salons
- ✅ Professional services
- ✅ Lower trust environments
- ✅ Infrequent transactions (once a month, etc.)
- ✅ Businesses needing audit trails

**Advantages:**
- 🔐 **Cryptographic security** - stamps can't be forged
- 📊 **Statistics tracking** - validation success rate
- ✅ **Tamper-proof** - hash chain detects modification
- 🎫 **Supplier-controlled redemption** - prevents fake redemptions
- 📝 **Audit trail** - complete history with timestamps

**Trade-offs:**
- ⏱️ Slightly slower (5-10 seconds per transaction)
- 📱 Requires supplier device (tablet/phone)
- 🔄 QR codes expire (must refresh every 1-2 minutes)

**Real-World Scenario:**

*"Maria's Luxury Spa" - Secure Mode*

**Setup:**
1. Maria sets up business on iPad with Secure Mode
2. iPad stays at reception desk

**Customer Experience:**
- First visit ($200 massage): 
  - Maria issues card on iPad → QR appears on screen
  - Customer Lisa scans with phone → card added to wallet (2 stamps)
  
- Every visit ($200 massage):
  - Maria taps "Add Stamp" on iPad → time-limited QR appears
  - Lisa scans QR → 2 stamps added (cryptographically signed)
  - QR expires after 2 minutes
  
- 10th stamp (5th visit):
  - Maria taps "Redeem Card" on iPad
  - Lisa opens her completed card → shows QR code
  - Maria scans Lisa's QR with iPad → validates signature chain
  - Card redeemed → Lisa gets free massage ($200 value)
  - New card auto-created with 0 stamps
  
**Why This Works:**
- High value rewards ($200) justify extra 10 seconds
- Cryptographic validation prevents fraud
- Lisa can't fake stamps or duplicate cards
- Maria has audit trail for accounting
- Lower volume (5 customers/day) means speed less critical

---

## 📱 How It Works - Technical Overview

### Peer-to-Peer Architecture

**No Cloud, No Backend, No Servers:**

```
Customer Phone ←--QR Codes--→ Supplier Device
     (SQLite DB)                  (SQLite DB)
```

**Simple Mode Flow:**
1. Supplier prints static QR codes
2. Customer scans "issue card" QR → card created on phone
3. Customer scans "add stamp" QR → stamp added to phone
4. When complete, customer scans "redeem" QR → card resets on phone
5. **No supplier interaction** needed (except redemption verification)

**Secure Mode Flow:**
1. Supplier generates time-limited QR on device
2. Customer scans QR → stamp data transferred
3. Customer app validates signature using supplier's public key
4. Invalid signature → rejected
5. Valid signature → stamp added, hash chain updated
6. Redemption: Supplier scans customer QR, validates entire chain

### Data Storage

**Customer App (SQLite on phone):**
- Business public keys
- Loyalty cards (business ID, stamps, creation date)
- Stamp history (timestamp, stamp count, card ID)
- Rate limiting data (last stamp time per business)

**Supplier App (SQLite on device):**
- Business configuration (name, branding, mode)
- Private key (cryptographic signing key)
- Public key (for customer validation)
- Issued card count
- Redemption count
- Transaction history (for secure mode)

**Data Size:**
- Typical customer: 5-10 cards = ~10KB
- Typical supplier: 1000s of cards = ~500KB

### Camera Rotation & Device Orientation

**The Challenge:**

Different devices (iPhone vs iPad) and different holding positions (portrait vs landscape) can result in the QR scanner camera appearing sideways or upside down. While it might seem simple to "just detect the device orientation and rotate automatically," this is actually quite difficult in Flutter:

**Why Auto-Rotation Is Hard:**
- **Flutter's Camera Abstractions:** Flutter's camera plugin abstracts away native camera APIs, making direct orientation detection unreliable
- **Gyroscope Data Mismatches:** Physical device sensors report orientation based on accelerometer/gyroscope, but this doesn't always match how the user is actually holding the device
- **Notched Screen Challenges:** Modern devices with notches, dynamic islands, and Face ID make traditional portrait/landscape detection less reliable
- **Device-Specific Quirks:** iPad and iPhone behave differently - what works for one device may not work for another
- **Platform Differences:** iOS and Android handle camera orientation differently, requiring platform-specific code
- **App Orientation Lock:** Apps may lock orientation (e.g., portrait-only), while camera needs different orientation
- **Multiple Correct Answers:** A tablet in landscape could be held with camera on left OR right - both are "correct" but need opposite rotations

**Our Pragmatic Solution:**

Instead of fighting these technical challenges, we implemented a **user-taught preference system**:

1. **Manual Rotation Buttons:**
   - Every QR scanner screen has two rotation buttons: **90°** and **180°**
   - Tap to rotate camera view instantly
   - Works reliably on all devices

2. **Persistent Preference:**
   - Your last rotation choice is **saved automatically**
   - Preference persists across app restarts
   - Shared across ALL camera screens in both apps
   - Set once, never need to adjust again (unless you change how you hold your device)

3. **Smart Defaults:**
   - Customer app: Defaults to 90° rotation (common iPhone portrait use)
   - Supplier import: Defaults to 0° (iPad landscape use)
   - Can be adjusted immediately if default doesn't match your device

**Benefits of This Approach:**
- ✅ **User in Control:** You teach the app your preference
- ✅ **100% Reliable:** No guessing, no sensor errors
- ✅ **Device-Agnostic:** Works perfectly on any iOS device
- ✅ **One-Time Setup:** Set rotation once, app remembers forever
- ✅ **Self-Correcting:** If you change how you hold your device, just tap rotation button again
- ✅ **Simple Implementation:** No complex sensor code, no platform-specific hacks
- ✅ **No Edge Cases:** Every orientation has an exact solution (0°, 90°, 180°, 270°)

**How It Works:**
1. Open any QR scanner (customer or supplier app)
2. If camera view is sideways/upside down, tap rotation button once or twice
3. Scan your QR code
4. Done! Next time you open ANY camera, your preferred rotation is already applied
5. Preference stored in SharedPreferences (iOS local storage)

**Technical Details:**
- Single shared preference key: `camera_rotation`
- Values: 0 (no rotation), 1 (90°), 2 (180°), 3 (270°)
- Updated automatically when rotation button tapped
- Loaded on every camera screen initialization
- Persists indefinitely (until app data cleared)

This approach solves the real-world user pain point (having to rotate camera every time) without attempting to solve the much harder problem (automatic device orientation detection). It's user-centric, reliable, and works perfectly across all devices.

---

## 🎨 Use Cases & Scenarios

### 1. Coffee Shop Chain (Simple Mode)

**Business:** Local coffee chain with 3 locations  
**Reward:** 10 coffees, get 1 free  
**Volume:** 500 customers/day across all locations

**Why Simple Mode:**
- Speed is critical during morning rush
- Low-value reward ($5 coffee)
- Regulars are trustworthy
- Rate limiting prevents abuse

**Implementation:**
- Each location prints same QR codes
- Customers can get stamps at any location
- Self-service stamping (no barista time needed)
- Fast throughput (no queue delays)

---

### 2. Boutique Clothing Store (Secure Mode)

**Business:** High-end fashion boutique  
**Reward:** $50 discount after 10 purchases  
**Volume:** 20-30 customers/day

**Why Secure Mode:**
- Higher value reward justifies security
- Lower volume allows for personal service
- Audit trail for accounting
- Prevents fraudulent redemptions

**Implementation:**
- iPad at checkout with supplier app
- Staff issues card and stamps during purchase
- Strong cryptographic validation
- Complete transaction history

---

### 3. University Campus Food Court (Mixed Mode)

**Scenario:** 8 food vendors, shared loyalty system  
**Each Vendor:** Choose their own mode

**Examples:**
- **Quick Bites (Simple):** Fast casual, $7 burgers
  - 10 meals = free meal
  - Simple mode for speed
  
- **Artisan Sushi (Secure):** Premium sushi, $25/meal
  - 8 meals = free meal ($25 value)
  - Secure mode for validation
  
- **Coffee Kiosk (Simple):** $4 lattes
  - 10 drinks = free drink
  - Simple mode, printed QR codes

**Customer Benefit:**
- One app, multiple vendor cards
- Each card independently tracked
- Choose vendors based on deals

---

### 4. Salon & Spa (Secure Mode)

**Business:** Hair salon with multiple services  
**Reward:** Variable stamps per service  
**Completion:** 10 stamps = $50 service free

**Service Values:**
- Haircut: 2 stamps
- Color: 3 stamps
- Massage: 2 stamps
- Facial: 2 stamps

**Why Secure Mode:**
- High-value services
- Variable stamping (supplier control)
- Appointment-based (not rush)
- Audit trail for staff performance

---

### 5. Community Co-op (Simple Mode)

**Business:** Local food co-op  
**Reward:** 20 visits = $20 credit  
**Community:** Trust-based membership

**Why Simple Mode:**
- Community values trust
- Members are invested in co-op
- Speed at checkout important
- No fraud history in 10 years

**Implementation:**
- QR codes at each checkout lane
- Self-stamping by members
- Monthly audit: redemptions vs inventory
- Works perfectly for cooperative culture

---

## 🔄 Comparing the Modes

| Feature | Simple Mode | Secure Mode |
|---------|-------------|-------------|
| **Speed** | ⚡ 2 seconds | ⏱️ 5-10 seconds |
| **Hardware** | 📄 Printed QR only | 📱 Tablet/phone required |
| **Security** | 🤝 Trust + rate limit | 🔐 Cryptographic |
| **Redemption** | Self-service | Supplier scans |
| **QR Expiry** | Never | 1-2 minutes |
| **Audit Trail** | Basic | Complete |
| **Best For** | Low-value, high-trust | High-value, any trust |
| **Fraud Prevention** | Rate limiting (1/hour) | Impossible to forge |
| **Offline** | ✅ Complete | ✅ Complete |

---

## 🌟 Key Benefits

### For Customers

1. **Privacy Preserved**
   - No personal data required
   - Anonymous loyalty cards
   - No tracking between businesses

2. **Simple & Fast**
   - No signup process
   - Scan and go
   - Works offline

3. **No Lost Cards**
   - Digital wallet always with you
   - Can't forget cards at home
   - Backup and restore available

4. **Multi-Business**
   - One app, unlimited cards
   - Easy switching between businesses
   - Search and organize your cards

### For Businesses

1. **Zero Cost** (Pilot Phase)
   - No monthly fees
   - No hardware required (simple mode)
   - No backend infrastructure

2. **Privacy Compliant**
   - No customer data liability
   - GDPR compliant by design
   - No data breach risk

3. **Flexible**
   - Choose your operation mode
   - Set your own reward levels
   - Control stamping amounts

4. **Insights** (Secure Mode)
   - Track redemption rates
   - View active cards
   - Transaction history

5. **Disaster Recovery & Multi-Device**
   - Backup business configuration (4 methods)
   - Restore to new device from backup QR
   - Clone to additional devices (5-minute expiry)
   - Customer cards remain valid across all devices
   - Multiple devices can issue/redeem for same business

---

## 💾 Backup & Recovery

### Business Configuration Protection

**CRITICAL:** Your business configuration contains cryptographic keys that validate all customer cards. Losing your device without a backup means **all customer cards become invalid**.

### Three Backup Methods

**1. 🖨️ Print Backup (HIGHLY RECOMMENDED)**
- Generates PDF with backup QR code
- Print and store in safe location
- No internet required to restore
- Cannot be hacked or lost to cloud breach
- Best practice: Print 2 copies, store separately

**2. 📧 Share via Email**
- Opens email with QR attachment
- Send to your own email address
- Access from any device with email
- Searchable: "LoyaltyCards Backup"
- Works with any email provider

**3. 📁 Save to Files**
- Saves to Files app / iCloud Drive
- Store in password manager (1Password, etc.)
- Organize with other business documents
- Cloud-synced if using iCloud Drive
- Can share with trusted backup location

### Recovery Backup vs Clone QR

**Recovery Backup (No Expiry):**
- For disaster recovery (lost/stolen/broken device)
- Never expires - valid forever
- Restores complete business configuration
- Use when: Device lost, needs replacement

**Clone QR (5-Minute Expiry):**
- For setting up additional devices
- Expires in 5 minutes for security
- Allows multiple devices for same business
- Use when: Front desk + back office needs access
- All devices share same business identity

### Multi-Device Support

**Setting Up Second Device:**
1. Device A (already configured): Settings → Clone to Another Device
2. Clone QR appears with countdown (5 minutes)
3. Device B (new): Open app → Clone from Another Device
4. Scan QR from Device A
5. Device B now has identical configuration

**Result:**
- Both devices can issue loyalty cards
- Both devices can add stamps
- Both devices can redeem cards
- Customer cards valid on both devices
- Same business ID and cryptographic keys
- Changes on one device don't affect the other

**Security:**
- Clone QR expires in 5 minutes
- Contains private cryptographic keys
- Only use on devices you control
- Regenerate new QR if setup takes longer

### Best Practices

✅ **DO THIS:**
- Create backup immediately after setup
- Use at least 2 backup methods
- Print and store physical copy
- Test restore process once
- Create new backup after any major changes
- Keep backup QR codes secure and private

❌ **DON'T DO THIS:**
- Skip backup creation
- Share backup QR publicly
- Store only digital backup
- Email backup to untrusted addresses
- Post backup QR on social media

---

## 🔮 Future Enhancements (Post-Pilot)

**Planned Features:**
- Stamp expiration (optional, configurable)
- Multi-location business support
- Push notifications (opt-in)
- Customer spending insights (anonymous)
- Business analytics dashboard
- Encrypted cloud backup (optional)

**Not Planned (Privacy Reasons):**
- Customer accounts or profiles
- Personal data collection
- Cross-business tracking
- Targeted advertising
- Data selling or sharing

---

## 💡 Philosophy

LoyaltyCards is built on three principles:

1. **Privacy First**
   - No personal data collection, ever
   - Local storage only
   - Users control their data

2. **Simplicity**
   - Zero friction for customers
   - Minimal setup for businesses
   - Works offline, always

3. **Trust & Flexibility**
   - Businesses choose their trust level
   - Simple mode for high-trust environments
   - Secure mode for validation when needed
   - Balance convenience with security

---

## 📞 Pilot Program

**Current Status:** Private pilot phase  
**Availability:** Invitation only  
**Platform:** iOS (iPhone & iPad)  
**Cost:** Free during pilot  
**Support:** Email support provided

**Interested in Participating?**
Contact us for pilot program details.

---

## ❓ Frequently Asked Questions

**Q: Is my data safe?**  
A: Yes! There's no data to steal - everything stays on your device. No cloud servers means no data breaches.

**Q: What if I lose my phone?**  
A: Customer cards are lost (like physical cards). No personal data is exposed. Simple reinstall the app and start fresh.

**Q: What if supplier loses their device?**  
A: With backup QR code: Scan the backup on new device, all customer cards remain valid, business fully restored in seconds. Without backup: All customer cards become invalid, must restart business from scratch.

**Q: Can I switch between modes?**  
A: Currently not supported. Choose mode during setup. Contact support to discuss migration.

**Q: Does it work without internet?**  
A: Yes! Complete offline functionality. Data never leaves your device.

**Q: Why is my camera sideways/upside down?**  
A: Different devices and holding positions result in different camera orientations. Use the rotation buttons (90° or 180°) on the camera screen to adjust. Your rotation preference is saved automatically - you only need to set it once and the app will remember it forever.

**Q: Why doesn't the camera auto-rotate to match my device?**  
A: Automatic camera rotation using device sensors (gyroscope/accelerometer) is extremely difficult in Flutter due to platform abstractions, device-specific quirks, and ambiguous orientations (e.g., tablet can be held with camera on left or right). Instead, we use manual rotation buttons with saved preferences - you teach the app your preference once, and it remembers. This is more reliable and works perfectly on all devices.

**Q: How do you make money?**  
A: Pilot is free. Future: Optional premium features (advanced analytics, multi-location support).

**Q: Can customers cheat in Simple Mode?**  
A: Rate limiting (1 stamp/hour) prevents casual abuse. For high-value rewards, use Secure Mode.

---

**LoyaltyCards** - Convenient. Private. Local.

*Built with privacy, designed for simplicity.*
