# About LoyaltyCards

**A Privacy-First Digital Loyalty Card System**

Version 0.1.0 (Build 78)  
Last Updated: April 13, 2026

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

5. **Disaster Recovery**
   - Backup business configuration
   - Restore to new device
   - Customer cards remain valid

---

## 🔮 Future Enhancements (Post-Pilot)

**Planned Features:**
- Stamp expiration (optional, configurable)
- Multi-location business support
- Push notifications (opt-in)
- Customer spending insights (anonymous)
- Business analytics dashboard
- Clone business to multiple devices
- Encrypted cloud backup

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
A: With backup: Restore to new device, all customer cards remain valid. Without backup: Must re-issue cards to customers.

**Q: Can I switch between modes?**  
A: Currently not supported. Choose mode during setup. Contact support to discuss migration.

**Q: Does it work without internet?**  
A: Yes! Complete offline functionality. Data never leaves your device.

**Q: How do you make money?**  
A: Pilot is free. Future: Optional premium features (advanced analytics, multi-location support).

**Q: Can customers cheat in Simple Mode?**  
A: Rate limiting (1 stamp/hour) prevents casual abuse. For high-value rewards, use Secure Mode.

---

**LoyaltyCards** - Convenient. Private. Local.

*Built with privacy, designed for simplicity.*
