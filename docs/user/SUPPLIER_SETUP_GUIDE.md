# Supplier Setup Guide - Operation Mode Selection

**For business owners setting up LoyaltyCards on their device**

Version 1.0.3+11  
Last Updated: July 21, 2026

---

## 📱 Initial Setup Overview

When you first open the LoyaltyCards Supplier App, you'll need to:

1. Create your business profile (name, stamps required, branding)
2. **Select your Operation Mode** - the most important decision
3. Create a backup (protects your customer data)

This guide helps you choose the right operation mode for your business.

---

## 🎯 Understanding the Two Operation Modes

LoyaltyCards supports two completely different approaches to loyalty cards. **Choose wisely - the mode cannot be changed without resetting your business.**

### **Express Mode** - Trust-Based, Speed-Focused

**Perfect for:** Coffee shops, cafes, bakeries, fast food, quick-service restaurants

**How it works:**
- You print QR codes and tape them to your register
- Customers scan codes themselves to add stamps
- QR codes never expire - print once, use forever
- No equipment needed at checkout

**Customer Journey:**
```
First Visit:     Customer scans "Get Card" QR → Card appears in app
Every Visit:     Customer scans "Add Stamp" QR → Stamp added
Complete:        Customer scans "Redeem" QR → Card resets
Time per visit:  ⚡ 2 seconds
```

**Best For:**
- ✅ Low-value rewards ($5-15 items like free coffee)
- ✅ High transaction volume (busy during peak hours)
- ✅ Regular customers who you trust
- ✅ Self-service environment
- ✅ Speed is critical (morning rush hours)

**Real-World Example - Joe's Coffee Shop:**
Joe runs a busy coffee shop. Every customer buys one drink per day. He prints two QR codes and tapes them to the register. Sarah walks in, scans once for her stamp (2 seconds), gets her coffee, and leaves. No interaction with Joe needed. She can earn stamps herself without waiting for staff.

**Advantages:**
- ⚡ **Super fast** - scan and go
- 📄 **Minimal tech** - just printed QR codes on paper
- 💰 **No equipment** - use what you have
- 🔄 **Self-service** - customers help themselves
- 🎯 **Frictionless** - no staff involvement needed

**Limitations:**
- ⚠️ Relies on customer honesty (no cryptographic prevention)
- ⚠️ Rate limiting (customers must wait between stamps - you set the cooldown, 5-60 seconds, 30 default)
- ⚠️ If a customer is determined to cheat, they could still scan repeatedly after each cooldown

**Fraud Prevention:**
You set a customer scan cooldown during setup (5-60 seconds, defaults to 30) that enforces a minimum wait between stamps per business. This prevents rapid-fire duplicate scanning but honest customers won't notice it during normal visits.

---

### **Secure Mode** - Cryptographically Validated, Fraud-Proof

**Perfect for:** Luxury goods, spas, salons, premium services, high-value rewards

**How it works:**
- You keep an iPad or phone at your checkout desk
- You control the stamping process - tap a button to generate a time-limited QR
- Each stamp is cryptographically signed with your private key
- QR codes expire after 2 minutes (can't be reused)
- You scan customer's card to redeem (complete control)

**Customer Journey:**
```
First Visit:     You tap "Issue Card" → QR appears on your screen
                 Customer scans → Card appears in app (2-5 stamps)
Every Visit:     You tap "Add Stamp" → Time-limited QR appears
                 Customer scans → Stamps added (cryptographically signed)
                 QR expires after 2 minutes
Complete:        Customer shows completed card → You scan to redeem
                 Card resets in customer's app
Time per visit:  ⏱️ 5-10 seconds
```

**Best For:**
- ✅ High-value rewards ($50-500+ items like spa services, designer goods)
- ✅ Luxury environment where fraud prevention is critical
- ✅ Lower transaction volume (customers visit once a month)
- ✅ You need complete control and tamper-proof records
- ✅ Premium customers who expect professional service

**Real-World Example - Maria's Luxury Spa:**
Maria runs a high-end spa. Massages cost $200. She can't afford fraud. She keeps an iPad at reception. When Lisa arrives for a $200 massage, Maria taps "Add Stamp" on the iPad. A time-limited QR code appears. Lisa scans it. The stamp is cryptographically signed - it can't be faked or copied. When Lisa completes her loyalty card after 5 visits ($1,000 spent), Maria scans Lisa's card to redeem, confident the record can't have been tampered with.

**Advantages:**
- 🔐 **Cryptographically secure** - stamps cannot be forged or faked
- 📊 **Basic lifetime counters** - Cards Issued/Stamped/Redeemed totals shown on your home screen (Secure Mode only; there's no detailed per-transaction log or export)
- ✅ **Tamper-proof** - hash chain detects any modification
- 🎫 **Complete control** - you decide when stamps are added and when cards are redeemed
- 📝 **Professional** - perfect for high-value or premium environment

**Limitations:**
- ⏱️ Slightly slower (5-10 seconds per transaction)
- 📱 Requires device at checkout (iPad/phone stays at desk)
- 🔄 QR codes expire (must refresh every 2 minutes, can't leave one on screen)
- 🔑 Key management (backup your encryption keys)

---

## 📊 Side-by-Side Comparison

| Factor | Express Mode | Secure Mode |
|--------|-------------|-------------|
| **Setup Time** | 5 minutes | 10 minutes |
| **Cost** | Nothing extra | Tablet/phone for checkout |
| **Speed** | ⚡ 2 seconds | ⏱️ 5-10 seconds |
| **QR Codes** | Printed, static | Dynamic, expire after 2 min |
| **Fraud Risk** | Low (configurable 5-60s rate limit) | Near zero (cryptographic) |
| **Control** | Customer self-service | You control everything |
| **Tamper Evidence** | None | Cryptographic signatures + hash chain |
| **Best Reward Value** | $5-15 | $50+ |
| **Customer Type** | Regulars you trust | Anyone, premium clients |
| **Complexity** | Simple | Moderate |

---

## 🎯 How to Decide

### Quick Decision Tree

```
Q1: What's the reward value?
├─ $5-20 → EXPRESS MODE is better
└─ $50+ → SECURE MODE is better

Q2: Do you need complete control?
├─ No, customers can help themselves → EXPRESS MODE
└─ Yes, I control everything → SECURE MODE

Q3: How many customers per day?
├─ 100+ (busy!) → EXPRESS MODE (speed matters)
└─ 5-20 (premium service) → SECURE MODE (control matters)

Q4: Can you dedicate a device?
├─ No → EXPRESS MODE
└─ Yes, iPad at register → SECURE MODE
```

### Decision Framework

**Choose EXPRESS MODE if:**
- Your rewards are low-value (coffee, $10 discount)
- You have high transaction volume (speed critical)
- Your customers are regulars you trust
- You want zero setup complexity
- You don't want equipment at checkout

**Choose SECURE MODE if:**
- Your rewards are high-value ($50+)
- You need complete fraud prevention
- You want tamper-proof, cryptographically signed records
- You can dedicate a device to the register
- You want professional control of the process

**Can't Decide?**
- Start with EXPRESS MODE (default)
- Monitor for any fraud attempts
- Switch to SECURE MODE later if needed

---

## 🔧 Changing Your Mode

**Important:** The operation mode cannot be changed after initial setup without doing a complete business reset (which deletes all customer data).

However, you can:
1. Create a second business with the other mode (if you have multiple payment programs)
2. Reset your business and start fresh with different mode (⚠️ loses all customer data)

**Recommendation:** Take 5 minutes now to read this guide and make the right choice the first time.

---

## 🔐 Security Notes for Both Modes

### Express Mode Security:
- **Rate Limiting:** you set a minimum wait between stamp scans during setup (5-60 seconds, defaults to 30) - prevents rapid duplicate fraud
- **Customer Trust:** Relies on honest behavior (works well for regular, loyal customers)
- **Physical Control:** Only your staff can issue new cards
- **Timestamp Tracking:** All stamps are timestamped for your records

### Secure Mode Security:
- **Cryptographic Signatures:** Each stamp is signed with your private key (cryptographically impossible to forge)
- **Hash Chain:** Stamps form a chain - any modification is detected
- **Time-Limited QR Codes:** Stamps expire after 2 minutes, can't be reused
- **Supplier Verification:** You control redemption with your device
- **Timestamped Records:** Every stamp is timestamped and hash-chained (not a browsable audit log in the app itself)
- **Key Backup:** Your private key is protected and backed up

**Both modes include:**
- ✅ Baseline rate limiting between stamp scans (Express Mode: you configure it, 5-60 seconds; Secure Mode: primarily protected by each QR's own 2-minute expiry)
- ✅ Timestamp tracking for all operations
- ✅ Customer data encrypted on your device
- ✅ No cloud storage or third-party servers

---

## 🔐 Face ID/Touch ID/Passcode Protection

**When Biometric Authentication is Required**

The following operations require Face ID, Touch ID, or device passcode authentication to protect your private cryptographic keys:

### 1. Viewing Recovery Backup QR Code
**Location:** Settings → Create Recovery Backup

**What happens:**
1. Tap "Create Recovery Backup"
2. **Authentication prompt appears** - "Authenticate with Face ID to securely access your business private keys"
3. Verify with:
   - ✅ Face ID (fastest, iPhone 12+)
   - ✅ Touch ID (iPad Air, iPad Pro)
   - ✅ Device Passcode (always available fallback)
4. After authentication, backup QR code is displayed

**Why authentication is required:**
- Backup QR contains your **private cryptographic keys** (especially in Secure Mode)
- These keys enable stamp forgery if leaked
- Authentication protects against unauthorized extraction

### 2. Creating Device Clone QR Code
**Location:** Settings → Clone to Another Device

**What happens:**
1. Tap "Clone to Another Device"
2. **Authentication prompt appears**
3. Verify with Face ID, Touch ID, or Passcode
4. Clone QR code generated (valid for 5 minutes)
5. Scan on new device to copy entire business configuration

**Why authentication is required:**
- Clone QR contains your **private cryptographic keys**
- Prevents unauthorized cloning of business identity
- Ensures only you can create device clones

### Biometric Method Selection

The app automatically uses the strongest method available on your device:

| Device Type | 1st Choice | 2nd Choice | 3rd Choice |
|-------------|-----------|-----------|-----------|
| iPhone 12+ | Face ID | - | Passcode |
| iPhone 11 | Face ID | - | Passcode |
| iPhone 10/X | Face ID | - | Passcode |
| iPad Pro | Touch ID | - | Passcode |
| iPad Air | Touch ID | - | Passcode |
| Older iPad | - | - | Passcode |

**Important:** Passcode is always available as fallback if user hasn't enrolled Face ID or Touch ID.

---

## 📱 App Store Compliance

**NSFaceIDUsageDescription in Info.plist:**
```
"Authenticate with Face ID to securely access your business private keys for backup and device cloning"
```

This message is shown when the app first requests Face ID permission. It explains why biometric authentication is needed.

**Implementation Details:**
- ✅ Required for App Store submission
- ✅ Complies with Apple's privacy and security guidelines
- ✅ Passcode fallback works on all devices
- ✅ Graceful handling if biometrics unavailable (uses passcode)

---

## 📋 After You Choose

### Next Steps (Same for Both Modes):

1. **Create Recovery Backup (CRITICAL)**
   - Go to Settings → Create Recovery Backup
   - **🔐 Face ID/Touch ID/Passcode authentication required** (Build 21+)
     - This authentication protects your private cryptographic keys
     - Passcode is always available as fallback if biometrics not enrolled
   - Print the backup QR code (save it securely)
   - Save a digital copy on your computer
   - **Important:** Backup QR contains your private keys - keep it safe

2. **Configure Your Business**
   - Set stamps required for free item (typically 5-20)
   - Choose your brand color
   - Select business category/icon

3. **Create QR Codes** (Express Mode only)
   - Print the QR codes provided by the app
   - Tape them to your register or counter
   - Keep backup printed copies

4. **Place Device** (Secure Mode only)
   - Position iPad/phone at checkout for easy tapping
   - Keep it plugged in or on wireless charging
   - Train staff on the tapping process

---

## ❓ Frequently Asked Questions

**Q: Can I change modes later?**  
A: No, not without resetting your business (deletes all customer data). Choose carefully now.

**Q: What if I'm not sure which mode?**  
A: Start with EXPRESS MODE - it's the default and works for 80% of businesses.

**Q: Is Secure Mode really unhackable?**  
A: Secure Mode uses ECDSA P-256 cryptography (same security as Bitcoin). Stamps cannot be forged, but always keep your backup secure.

**Q: Can customers cheat Express Mode?**  
A: The scan cooldown you set during setup (5-60 seconds, defaults to 30) makes mass fraud impractical. It's designed for honest customers in trust-based environments.

**Q: What if my reward value is between $20-50?**  
A: That's the sweet spot where either mode works. Choose based on your comfort level: Express for speed, Secure for control.

**Q: Can I use both modes?**  
A: Not on the same business. You'd need to create a second business profile for the other mode.

---

## 🆘 Need Help?

- **Read:** [About LoyaltyCards](./ABOUT_LOYALTYCARDS.md) for detailed system overview
- **Read:** [Security Model](../technical/SECURITY_MODEL.md) for technical details
- **Contact:** Support documentation in app (Settings → Help)

---

**Remember:** Your choice of operation mode shapes the entire experience for your customers and staff. Take a moment to choose the one that fits your business best.
