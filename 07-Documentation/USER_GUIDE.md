# LoyaltyCards User Guide

**Quick Start Guide for Businesses & Customers**

Version 0.1.0 (Build 83)  
Last Updated: April 13, 2026

---

## 👥 For Customers

### Getting Started (30 seconds)

1. **Download the Customer App**
   - Install from TestFlight (pilot phase)
   - No signup required - just open the app

2. **Get Your First Card**
   - Look for LoyaltyCards QR code at checkout
   - Open app → tap camera icon
   - Scan the "Get Loyalty Card" QR code
   - Card appears in your wallet instantly

3. **Collect Stamps**
   - Every visit, scan the business's QR code
   - Stamp added automatically
   - Track progress in app

4. **Redeem Your Reward**
   - When card is complete, show to staff
   - They'll scan your card or you scan redemption QR
   - New card created automatically

**That's it! No account, no email, no personal info needed.**

---

### Using the Customer App

#### Your Card Wallet

**Home Screen:**
- Shows all your loalty cards
- Sort by: Recent, Alphabetical, Progress
- Search: Find specific business
- Tap any card to see details

**Card Details:**
- Current stamps / required stamps
- Progress bar
- Stamp history (when you got each stamp)
- Business information
- "How It Works" help button

#### Adding Stamps

**Two Ways to Get Stamps:**

**1. Self-Service (Simple Mode businesses):**
- Scan the "Add Stamp" QR code at checkout
- Stamp added instantly to your phone
- Rate limited: 1 stamp per hour per business
- No staff interaction needed

**2. Staff-Assisted (Secure Mode businesses):**
- Staff generates QR code on their device
- Scan the temporary QR code
- Stamp validated and added
- QR expires after 1-2 minutes

**Tip:** You'll know which mode a business uses after your first scan. Simple mode = instant, Secure mode = validated.

#### Redeeming Rewards

**Simple Mode:**
- Scan the "Redeem" QR code at checkout
- Card resets immediately
- New card auto-created

**Secure Mode:**
- Show your completed card to staff
- Staff scans your card's QR code
- Validation happens on their device
- Card resets, new card created

#### Managing Cards

**Delete a Card:**
- Swipe left on card
- Tap "Delete"
- Card permanently removed

**Card Information:**
- Tap card to see full details
- View stamp history
- See business mode (Simple or Secure)

---

### Troubleshooting (Customer)

**"Can't scan QR code"**
- Ensure camera permission is granted
- Good lighting helps
- Hold phone steady for 1 second
- Try moving closer/farther

**"Stamp not added"**
- Simple mode: Wait 1 hour (rate limited)
- Secure mode: QR may have expired, ask staff for new one
- Check that you scanned business's QR, not your own

**"Lost my cards"**
- Cards stored locally on your device
- If phone is lost, cards are lost (like physical cards)
- No personal data exposed
- Reinstall app and start fresh

**"Card not redeeming"**
- Ensure card is complete (all stamps)
- In secure mode, staff must scan your card
- In simple mode, scan the "Redeem" QR code

---

## 🏪 For Businesses (Suppliers)

### Choosing Your Operation Mode

**IMPORTANT: Choose carefully - cannot change later without reset**

#### Simple Mode - Choose if:
✅ Low-value rewards ($5-15)  
✅ High transaction volume (speed matters)  
✅ Regular, trusted customers  
✅ Coffee shop, cafe, quick service  
✅ Want self-service stamping  
✅ Don't need detailed audit trail  

**Benefits:**
- ⚡ Fastest (2 seconds per transaction)
- 📄 Print QR codes once, use forever
- 💰 No equipment needed
- 🚀 Zero maintenance

**Trade-off:** Rate limiting only (1 stamp/hour per customer)

#### Secure Mode - Choose if:
✅ High-value rewards ($50+)  
✅ Need fraud prevention  
✅ Want complete audit trail  
✅ Luxury goods, services, spa  
✅ Lower transaction volume  
✅ Control redemption process  

**Benefits:**
- 🔐 Cryptographically secure
- 📊 Transaction statistics
- ✅ Tamper-proof validation
- 🎫 Supplier-controlled redemption

**Trade-off:** Requires device at checkout, slightly slower

---

### Initial Setup (5 minutes)

1. **Download Supplier App**
   - Install from TestFlight (pilot phase)
   - Open app on iPhone or iPad

2. **Create Business Profile**
   - Enter your business name
   - Choose number of stamps required (5-20)
   - Select brand color
   - Choose business icon

3. **⚠️ SELECT OPERATION MODE**
   - **Simple Mode** or **Secure Mode**
   - Read descriptions carefully
   - Cannot change without reset
   - When in doubt: Simple for low-value, Secure for high-value

4. **🔥 CRITICAL: Create Backup** (5 minutes)
   - Tap Settings → Create Recovery Backup
   - **Use at least 2 backup methods:**
     1. 🖨️ **Print** (HIGHLY RECOMMENDED)
        - Opens print dialog
        - Print and store in safe/locked drawer
        - This is your "master key"
     2. 📸 **Save to Photos**
        - Backs up to iCloud Photos
        - Easy to find, searchable
     3. 📧 **Email to Myself**
        - Accessible from any device
        - Search email for "LoyaltyCards Backup"
     4. 📁 **Save to Files**
        - Store in password manager or iCloud Drive
   
   **⚠️ WARNING:** Without backup, if you lose your device:
   - All customer cards become invalid
   - You must re-issue cards to every customer
   - Major business disruption
   
   **✅ WITH backup:**
   - Restore to new device
   - All customer cards remain valid
   - No customer impact

5. **Ready to Go!**
   - Home screen shows: Issue Card, Add Stamp, Redeem Card
   - Start by issuing test card to yourself

---

### Daily Operations

#### Simple Mode Workflow

**One-Time Setup:**
1. Tap "Issue Card" on home screen
2. QR code appears - this is your **permanent "Get Card" QR**
3. Print this QR code (or take screenshot)
4. Post at checkout: "Scan for Loyalty Card"

5. Tap "Add Stamp"
6. QR code appears - this is your **permanent "Add Stamp" QR**
7. Print this QR code
8. Post at checkout: "Scan to Add Stamp"

9. Tap "Redeem Card"
10. QR code appears - this is your **permanent "Redeem" QR**
11. Print this QR code
12. Post at checkout: "Scan to Redeem Reward"

**Daily Operations:**
- **Nothing!** Customers self-serve
- QR codes never expire
- Customers scan as needed
- You monitor redemptions

**Monitoring:**
- Home screen shows stats:
  - Cards issued
  - Active cards
  - Redemptions
- View history: Settings → View Activity (coming soon)

---

#### Secure Mode Workflow

**Each Transaction:**

**Issue New Card:**
1. Tap "Issue Card" button
2. Choose initial stamps (0-7)
3. QR code appears on screen (valid 1-2 minutes)
4. Customer scans with their phone
5. Card added to customer's wallet

**Add Stamps:**
1. During customer purchase, tap "Add Stamp"
2. Choose number of stamps (1-7)
3. Time-limited QR appears on screen
4. Customer scans QR with phone
5. Cryptographic validation happens automatically
6. Stamp added if valid

**Redeem Reward:**
1. Customer shows completed card (on their phone)
2. Tap "Redeem Card" on your device
3. Scan customer's card QR code
4. Validation happens automatically
5. If valid: Card redeemed, customer gets new card
6. If invalid: Error message, investigation needed

**Key Points:**
- QR codes expire (1-2 minutes) for security
- Tap "Refresh" if customer needs more time
- Statistics tracked: Settings → View Stats (coming soon)

---

### Business Settings

**Access:** Tap gear icon (⚙️) on home screen

**Settings Menu:**

1. **Business Information**
   - View business name
   - View brand color
   - View stamps required
   - View Business ID

2. **Backup & Recovery**
   - **Create Recovery Backup** ← CRITICAL - Do immediately
   - **Clone to Another Device** ← Set up multiple devices

3. **App Information**
   - View app version
   - Check for updates

4. **Danger Zone**
   - Reset Business Configuration
   - **⚠️ Use only if starting over**
   - All customer cards become invalid

---

### Understanding Your Backup

**What's in a backup:**
- Your business name and settings
- Your cryptographic keys (secure mode)
- Your Business ID (unique identifier)

**Why it's critical:**
- Your cryptographic key is your business identity
- Without it, you can't validate customer cards
- Backup = insurance against device loss

**How recovery works:**
1. Get replacement device
2. Install supplier app
3. Tap "Recover Existing Business"
4. Scan your backup QR code
5. Business restored with exact same identity
6. All existing customer cards still work!

**Backup storage options explained:**

| Method | Accessibility | Security | Recommendation |
|--------|--------------|----------|----------------|
| **Print** | Physical only | High (lock it up) | ⭐⭐⭐⭐⭐ Best |
| **Photos** | iCloud sync | Medium | ⭐⭐⭐⭐ Good |
| **Email** | Any device | Low (email insecure) | ⭐⭐⭐ Okay |
| **Files** | Cloud/local | Medium-High | ⭐⭐⭐⭐ Good |

**Best practice:** Use Print + Photos (redundancy)

---

### Permissions Required (iOS)

**Photo Library:**
- **When:** First time you tap "Save to Photos"
- **Prompt:** iOS asks for permission
- **Choose:** "Allow" or "Add Photos Only"
- **If Denied:** Can't save to Photos (use other 3 methods)
- **Re-enable:** Settings → Privacy → Photos → LoyaltyCards

**No other permissions required!**
- Email: Uses share sheet (no permission)
- Files: Uses share sheet (no permission)
- Print: System print dialog (no permission)

---

### Setting Up Additional Devices (Clone)

**Use Case:** You want the same business available on multiple devices (e.g., front desk + back office, or multiple checkout stations).

**How It Works:**
1. **Device A** (already configured): Settings → Clone to Another Device
2. Clone QR code appears with **5-minute countdown timer**
3. **Device B** (new/unconfigured): Open app → Tap "Clone from Another Device"
4. Scan QR code from Device A
5. Device B now has identical business configuration

**Result:**
- Both devices have same business identity
- Both can issue loyalty cards
- Both can add stamps
- Both can redeem cards
- Customer cards work on both devices
- Completely independent operation

**Important Notes:**
- ⏱️ Clone QR expires in **5 minutes** for security
- 🔐 Contains your private cryptographic keys
- ⚠️ Only use on devices you personally control
- 🔄 Can regenerate new clone QR anytime
- 📱 Can clone to unlimited devices
- 🔑 All devices share same Business ID

**Security:**
- Clone QR is time-limited (5 minutes)
- Prevents unauthorized cloning
- If QR expires, just generate a new one
- Never share clone QR publicly
- Store devices securely

**When to Use Clone vs Recovery:**

| Scenario | Use This |
|----------|----------|
| Lost/stolen device | **Recovery Backup** (restore) |
| Setting up second checkout | **Clone QR** (5-min) |
| New device same business | **Clone QR** (5-min) |
| Backup for safety | **Recovery Backup** (print/save) |
| Testing new device | **Clone QR** (5-min) |

**Step-by-Step Clone Process:**

**On Device A (Source):**
1. Open Supplier app
2. Tap Settings (⚙️)
3. Tap "Clone to Another Device"
4. QR code appears with countdown
5. Keep screen active while scanning

**On Device B (Target):**
1. Open Supplier app (should show onboarding)
2. Tap "Clone from Another Device" (green button)
3. Point camera at Device A's QR code
4. Wait for import to complete (5-10 seconds)
5. App navigates to home screen
6. Device B ready to use!

**Common Scenarios:**

**Scenario: Multiple Checkout Stations**
- Clone business to iPad at each station
- All stations issue/redeem independently
- Customer cards work at any station
- Statistics combine across all devices

**Scenario: Manager + Staff Device**
- Manager has primary device (with backup)
- Clone to staff device for daily use
- Both can perform all operations
- No "master" device - all equal

**Scenario: Temporary Pop-Up Location**
- Clone to temporary device
- Use for event/market
- Return device or wipe after event
- Original device unaffected

---

### Troubleshooting (Business)

**"Customer says stamp didn't work"**
- Simple mode: They may have scanned within 1 hour (rate limited)
- Secure mode: QR may have expired, generate new one
- Check their app shows your business

**"QR code won't scan"**
- Ensure good lighting
- QR code not too small (at least 2 inches)
- Printed clearly (not pixelated)
- Phone held steady

**"Lost my device"**
- **With backup:** Get new device, restore from backup QR ✅
- **Without backup:** Must reset and re-issue all cards ❌

**"Customer has invalid card"**
- Secure mode only: Signature validation failed
- Card may be from old business configuration
- Issue new card to customer

**"Want to change mode"**
- Not currently possible without reset
- Reset = all customer cards invalidated
- Plan for future: Wait for mode migration feature

**"Backup QR code not scanning"**
- Ensure printed clearly
- Try from phone screen (photo/email)
- Check QR code not damaged
- Contact support if persistent issue

**"Clone QR expired before I could scan"**
- Generate new clone QR (Settings → Clone to Another Device)
- 5-minute timer resets with each new QR
- Have both devices ready before generating
- If interrupted, just regenerate

**"Clone import failed"**
- Check QR hasn't expired (5-minute limit)
- Ensure good lighting for scan
- Try using QR frame and rotation controls
- Verify source device still configured
- Check target device has no existing business

---

## 🎓 Tips & Best Practices

### For Customers

✅ **DO:**
- Add cards as you discover businesses
- Check progress regularly
- Redeem promptly when complete
- Keep app updated

❌ **DON'T:**
- Try to scan same QR repeatedly (rate limited)
- Screenshot QR codes (they may expire)
- Share login (there is no login!)

### For Businesses

✅ **DO:**
- **Create backup immediately** (before issuing any cards)
- **Use multiple backup methods** (Print + Photos recommended)
- Test with personal device first
- Print clear, large QR codes (3-4 inches)
- Position QR codes at eye level
- Train staff on redemption process (secure mode)
- Update app regularly
- Clone to multiple devices if needed (front/back office)
- Keep clone QR secure during 5-minute window
- Test recovery process once to ensure backup works

❌ **DON'T:**
- Skip the backup step
- Rely on single backup method only
- Change mode without planning
- Delete QR codes (simple mode)
- Share backup QR code publicly
- Share clone QR with unauthorized people
- Leave clone QR displayed after setup complete
- Post backup/clone QR on social media

---

## 📊 Quick Reference

### Customer App - Main Actions

| Action | Location | Result |
|--------|----------|--------|
| Add Card | Camera icon → Scan | New card in wallet |
| View Cards | Home screen | All your cards |
| Card Details | Tap any card | Full card info |
| Add Stamp | Scan business QR | Stamp added |
| Redeem | Scan redeem QR or show card | Card resets |
| Delete Card | Swipe left | Card removed |

### Supplier App - Main Actions

| Action | Location | Result |
|--------|----------|--------|
| Issue Card | Home → Issue Card | QR for customer |
| Add Stamp | Home → Add Stamp | QR for customer |
| Redeem | Home → Redeem Card | Scan customer |
| Backup | Settings → Create Backup | Save business |
| View Stats | Home screen | Card counts |

---

## 🆘 Getting Help

**Documentation:**
- About LoyaltyCards: `/07-Documentation/ABOUT_LOYALTYCARDS.md`
- Testing Guide: `/03-Source/supplier_app/BACKUP_TESTING_GUIDE.md`

**Common Issues:**
- Review troubleshooting sections above
- Check app version is current
- Verify permissions granted

**Pilot Support:**
- Email support provided to pilot participants
- Include: App version, device type, screenshot of issue

---

## ✅ Onboarding Checklist

### For New Customers
- [ ] Download customer app
- [ ] Scan first business QR code
- [ ] See card appear in wallet
- [ ] Understand how to add stamps
- [ ] Know how to redeem

### For New Businesses
- [ ] Download supplier app
- [ ] Complete business setup
- [ ] **Choose operation mode carefully**
- [ ] **CREATE BACKUP** (2+ methods)
- [ ] Test issue card on personal device
- [ ] Test add stamp
- [ ] Test redemption
- [ ] Print QR codes (simple mode) OR
- [ ] Have device at checkout (secure mode)
- [ ] Train staff on process
- [ ] Launch to customers!

---

**Remember:**
- 🔒 Privacy first - no personal data
- 💾 Local storage only - everything on device
- 🔄 Offline capable - works without internet
- 🚀 Simple or Secure - choose what fits your business
- 💾 **BACKUP YOUR BUSINESS** - critical step!

---

**LoyaltyCards** - Making loyalty simple and private.

*Need help? Check the About document for detailed explanations.*
