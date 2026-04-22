# Support Procedures

**LoyaltyCards v0.2.0**  
**Purpose:** User support guidelines and issue resolution  
**Last Updated:** April 18, 2026

---

## Overview

This document provides comprehensive support procedures for handling user inquiries, bug reports, and technical issues for both LoyaltyCards (Customer) and LoyaltyCards Business (Supplier) apps.

---

## Support Channels

### Primary Support
- **Email:** support@[yourdomain.com] (TBD)
- **Response Time:** 24-48 hours (business days)
- **Hours:** Monday-Friday, 9am-5pm [Your Timezone]

### Self-Service
- **User Guide:** [USER_GUIDE.md](07-Documentation/USER_GUIDE.md)
- **FAQ:** See Common Issues section below
- **In-App Help:** Settings → Help & Support

### App Store Reviews
- **Monitor:** Daily
- **Respond to:** All reviews (especially negative ones)
- **Response Time:** Within 7 days

---

## Issue Classification

### Priority Levels

| Priority | Definition | Response Time | Resolution Time | Examples |
|----------|------------|---------------|-----------------|----------|
| P0 - CRITICAL | App unusable, data loss, security breach | <1 hour | <24 hours | Crashes on launch, cannot redeem cards, private key exposed |
| P1 - HIGH | Core feature broken, major functionality impaired | <4 hours | <48 hours | QR scanning broken, cannot issue cards, stamps not saving |
| P2 - MEDIUM | Feature partially working, workaround available | <24 hours | 1 week | UI glitches, slow performance, minor bugs |
| P3 - LOW | Cosmetic issues, feature requests, documentation | <48 hours | Next release | Text typos, color issues, enhancement requests |

---

## Support Workflow

### Step 1: Initial Contact

**When user emails support:**

1. **Acknowledge Receipt** (within 4 hours)
   ```
   Subject: Re: [User's Subject] - Ticket #[ID]
   
   Hello [Name],
   
   Thank you for contacting LoyaltyCards support. We've received your inquiry 
   and assigned it ticket #[ID]. We're investigating and will respond within 
   [24-48] hours.
   
   In the meantime, please check our User Guide for common solutions:
   [Link to USER_GUIDE.md or website]
   
   Best regards,
   LoyaltyCards Support Team
   ```

2. **Gather Information** (use template below)

3. **Classify Priority** (P0-P3)

4. **Assign to Queue**
   - P0: Escalate immediately to development team
   - P1: Assign to senior support
   - P2/P3: Assign to general support queue

---

### Step 2: Information Gathering

**Support Request Template:**

Ask users to provide:

```
1. Which app are you using?
   [ ] LoyaltyCards (Customer)
   [ ] LoyaltyCards Business (Supplier)

2. Device information:
   - Device model: (e.g., iPhone 14 Pro, iPad Air)
   - iOS version: (Settings → General → About → Software Version)
   - App version: (Settings → About → Version)

3. What were you trying to do?
   [Description of intended action]

4. What happened instead?
   [Description of actual behavior]

5. When did this start happening?
   [ ] Just started
   [ ] After recent app update
   [ ] Has always happened

6. Can you reproduce it?
   [ ] Yes, every time
   [ ] Yes, sometimes
   [ ] No, happened once

7. Steps to reproduce (if known):
   1. [First step]
   2. [Second step]
   3. [etc.]

8. Screenshots or screen recordings (if available):
   [Attachment]
```

---

### Step 3: Diagnosis & Resolution

**Use troubleshooting guides below for common issues**

---

## Common Issues & Solutions

### Customer App Issues

#### ISSUE-C001: Cannot Scan QR Code

**Symptoms:**
- Camera doesn't open
- QR scanner shows black screen
- QR code doesn't scan

**Diagnosis:**
1. Check camera permissions
2. Check iOS version
3. Check QR code format

**Solutions:**

**Solution 1: Camera Permission Not Granted**
```
1. Go to iOS Settings → LoyaltyCards
2. Enable "Camera" permission
3. Return to app and try again
```

**Solution 2: Camera Hardware Issue**
```
1. Test camera in iOS Camera app
2. If camera works in Camera app but not LoyaltyCards:
   - Force quit LoyaltyCards (swipe up from app switcher)
   - Reopen app
3. If camera doesn't work anywhere:
   - Hardware issue, contact Apple Support
```

**Solution 3: QR Code Format Invalid**
```
1. Ask user for screenshot of QR code
2. Verify QR code is from LoyaltyCards Business app
3. If supplier generated QR from different system:
   - Explain LoyaltyCards only works with LoyaltyCards Business QR codes
   - Direct supplier to download LoyaltyCards Business
```

**User Response Template:**
```
Camera permission is required to scan QR codes. To enable:

1. Go to iPhone Settings
2. Scroll to "LoyaltyCards"
3. Tap "Camera"
4. Select "Allow"

Then return to LoyaltyCards and try scanning again.

If you've already enabled camera access and scanning still doesn't work, 
please try force-quitting the app (swipe up in app switcher) and reopening it.
```

---

#### ISSUE-C002: Cards Not Appearing After Scan

**Symptoms:**
- User scans QR code
- "Card added" message appears
- Card doesn't show on home screen

**Diagnosis:**
1. Database write failure
2. Card filtered out (redeemed cards hidden by default)
3. Sync delay

**Solutions:**

**Solution 1: Restart App**
```
1. Force quit LoyaltyCards
2. Reopen app
3. Check if card appears
```

**Solution 2: Check Filters**
```
1. Home screen → tap filter icon (if available)
2. Ensure "Show Redeemed Cards" is enabled
3. If card appears, it was redeemed
```

**Solution 3: Database Reset (Last Resort)**
```
⚠️ WARNING: This deletes all cards and stamps

1. Settings → Advanced → Clear All Data
2. Confirm deletion
3. Re-scan cards from suppliers
```

**User Response Template:**
```
If your card isn't appearing after scanning, try these steps:

1. Force quit the app (swipe up in app switcher)
2. Reopen LoyaltyCards
3. Check if the card appears now

If the card still doesn't appear, it may have been marked as redeemed. 
Check Settings → Show Redeemed Cards.

As a last resort, you can reset the app (this deletes all cards):
Settings → Advanced → Clear All Data

Then re-scan your active cards from the businesses.
```

---

#### ISSUE-C003: Stamps Not Adding to Card

**Symptoms:**
- User scans supplier's stamp QR code
- No stamps added to card
- Error message or no response

**Diagnosis:**
1. QR code expired (2-minute validity)
2. Signature verification failed (Secure Mode)
3. Rate limiting (5-second cooldown)
4. Wrong card selected

**Solutions:**

**Solution 1: QR Code Expired**
```
QR codes for stamps are valid for 2 minutes. Ask supplier to generate fresh QR.
```

**Solution 2: Rate Limiting**
```
Wait 5 seconds between stamp scans to prevent duplicate stamps.
```

**Solution 3: Signature Verification Failed (Secure Mode)**
```
Business may have changed configuration. Ask customer to:
1. Request new card from business
2. Delete old card (may have wrong public key)
3. Scan new card issuance QR
```

**User Response Template:**
```
Stamp QR codes are valid for 2 minutes to prevent fraud. If you're not scanning 
immediately after the business generates the QR code, it may have expired.

Please ask the business to generate a fresh stamp QR and scan it right away.

If you're scanning immediately and it still doesn't work, the business may have 
reconfigured their loyalty program. Ask them to issue you a new card.
```

---

#### ISSUE-C004: Cannot Redeem Card

**Symptoms:**
- Card shows "Ready to Redeem"
- Cannot generate redemption QR
- Supplier says QR is invalid

**Diagnosis:**
1. App version mismatch (customer vs supplier)
2. Business reconfigured (public key changed)
3. Network/timeout issue

**Solutions:**

**Solution 1: Update Both Apps**
```
Ensure both you and the business are running the latest version:
- Customer: LoyaltyCards [version]
- Supplier: LoyaltyCards Business [version]
```

**Solution 2: Redemption QR Expired**
```
Redemption QR codes are valid for 2 minutes. Generate fresh QR at counter.
```

**User Response Template:**
```
Redemption QR codes are time-limited for security. Please:

1. Wait until you're at the business counter
2. Tap "Show Redemption QR" in the app
3. Ask the business to scan it immediately

If the business says the QR is invalid, ensure both of you are using the 
latest app versions:
- You: LoyaltyCards (check Settings → About)
- Business: LoyaltyCards Business

Update from the App Store if needed.
```

---

### Supplier App Issues

#### ISSUE-S001: Cannot Create Business

**Symptoms:**
- "Create New Business" button does nothing
- App crashes when creating business
- Error message during business creation

**Diagnosis:**
1. iOS Keychain access denied
2. Device storage full
3. App bug

**Solutions:**

**Solution 1: iOS Keychain Access**
```
Business configuration requires secure storage access. Ensure:
1. Passcode is set on device (required for Keychain)
2. App not restricted in Screen Time settings
```

**Solution 2: Storage Full**
```
1. Check device storage: Settings → General → iPhone Storage
2. Free up at least 500MB
3. Try creating business again
```

**User Response Template:**
```
Business creation requires iOS Keychain access to securely store your private keys.

Please ensure:
1. Your device has a passcode set (required for Keychain)
2. LoyaltyCards Business is not restricted in Screen Time settings
3. You have at least 500MB of free storage

Then try creating your business again.

If the problem persists, try restarting your device and reopening the app.
```

---

#### ISSUE-S002: Biometric Authentication Failing

**Symptoms:**
- Face ID / Touch ID prompt appears
- Authentication fails repeatedly
- Cannot access backup/clone features

**Diagnosis:**
1. Face ID not enrolled
2. Face ID disabled for app
3. Too many failed attempts

**Solutions:**

**Solution 1: Face ID Not Enrolled**
```
1. Settings → Face ID & Passcode
2. Ensure Face ID is set up
3. If not, tap "Set Up Face ID"
```

**Solution 2: Face ID Disabled for App**
```
1. Settings → LoyaltyCards Business
2. Ensure app is not restricted
3. Check Settings → Screen Time → Content & Privacy
```

**Solution 3: Use Passcode Instead**
```
After 3 failed Face ID attempts, tap "Use Passcode" option
```

**User Response Template:**
```
Biometric authentication (Face ID/Touch ID) protects access to your private keys.

If authentication is failing:

1. Verify Face ID is enrolled:
   Settings → Face ID & Passcode → ensure Face ID is set up

2. If Face ID keeps failing, use your passcode instead:
   After 3 failures, tap "Use Passcode" button

3. If neither works, try restarting your device

Your private keys are safe - they're stored in iOS Keychain and can be recovered 
using your device passcode.
```

---

#### ISSUE-S003: Lost Business Configuration

**Symptoms:**
- App shows "No business configured"
- Business details disappeared
- After iOS update/device restore

**Diagnosis:**
1. App reinstalled (cleared database)
2. iOS backup not restored
3. Device replaced without backup

**Solutions:**

**Solution 1: Recovery Backup Available**
```
If you created a Recovery Backup QR:
1. Open LoyaltyCards Business
2. Tap "Import Business Configuration"
3. Scan your recovery backup QR code
4. Business configuration restored
```

**Solution 2: No Recovery Backup**
```
⚠️ Business configuration is NOT recoverable without backup

However, your private keys may still be in iOS Keychain. We need to:
1. Extract public key from Keychain
2. Recreate business configuration manually
3. Customers' existing cards will still work (same keys)

This requires development team assistance. Please contact support.
```

**User Response Template:**
```
If you've lost your business configuration, recovery depends on whether you 
created a backup:

WITH RECOVERY BACKUP:
1. Open LoyaltyCards Business
2. Tap "Import Business Configuration"
3. Scan your recovery backup QR code
4. Your business is restored!

WITHOUT RECOVERY BACKUP:
Your business configuration cannot be automatically restored. However, your 
private cryptographic keys may still be in your device's Keychain.

Please contact support@[domain] and we'll help you recover your business 
configuration manually.

PREVENTION: 
Always create a Recovery Backup after configuring your business:
Settings → Create Recovery Backup → Save QR code securely
```

---

#### ISSUE-S004: Multi-Device Clone Not Working

**Symptoms:**
- Clone QR doesn't scan on second device
- Second device shows "Invalid configuration"
- Biometric auth fails during clone

**Diagnosis:**
1. QR code expired
2. Second device not compatible
3. Network interruption

**Solutions:**

**Solution 1: Regenerate Clone QR**
```
Clone QR codes are time-sensitive:
1. On primary device: Settings → Clone Device
2. Authenticate with Face ID
3. Generate fresh QR code
4. Scan immediately on second device
```

**Solution 2: Check Device Compatibility**
```
Both devices must:
- Run iOS 13.0 or later
- Have LoyaltyCards Business installed (same version)
- Have sufficient storage
```

**User Response Template:**
```
To clone your business configuration to another device:

PRIMARY DEVICE (original):
1. Settings → Clone Device
2. Authenticate with Face ID/Passcode
3. QR code appears

SECONDARY DEVICE (new):
4. Install LoyaltyCards Business from App Store
5. Open app → Import Business Configuration
6. Scan the QR code from primary device

IMPORTANT:
- Scan within 2 minutes (QR expires for security)
- Both devices must have the same app version
- Ensure good lighting for QR scanning

If cloning fails, regenerate the QR on the primary device and try again.
```

---

## Data Recovery Procedures

### Customer App Data Loss

**Scenario:** User uninstalled app or got new device

**Recovery Options:**

1. **iOS Backup Restore**
   - If user has iCloud or iTunes backup
   - Restore device from backup
   - LoyaltyCards data included
   - Limitation: Only if backup was created before data loss

2. **Manual Re-Issuance**
   - No recovery possible without backup
   - User must visit businesses and request new cards
   - Transaction history lost permanently

**User Response Template:**
```
LoyaltyCards stores all data locally for privacy. This means:

✅ Your data is private (we don't have access to it)
❌ If you delete the app or switch devices, data cannot be recovered unless 
   you have an iOS backup

RECOVERY OPTIONS:

If you have an iOS/iCloud backup from before data loss:
1. Settings → General → Transfer or Reset iPhone
2. Erase All Content and Settings
3. Restore from iCloud/iTunes backup
4. Reinstall LoyaltyCards
5. Your cards will return

If you don't have a backup:
- Cards and stamps cannot be recovered
- Please visit businesses and request new cards
- Apologize for the inconvenience

PREVENTION:
Enable iCloud Backup to protect your data:
Settings → [Your Name] → iCloud → iCloud Backup → Enable
```

---

### Supplier App Data Loss

**Scenario:** Business lost configuration or private keys

**Recovery Options:**

1. **Recovery Backup QR**
   - If business created backup: Full recovery possible
   - Import QR on any device: Business restored

2. **iOS Keychain Recovery**
   - Private keys survive app uninstall (stored in Keychain)
   - Requires development team assistance to extract
   - Business config can be manually recreated with original keys

3. **No Recovery Possible**
   - If device lost/destroyed AND no backup QR AND no iOS backup
   - New business must be created (new keys)
   - Existing customer cards become invalid
   - Customers must request new cards

**User Response Template:**
```
Business configuration recovery depends on your backup:

WITH RECOVERY BACKUP QR:
✅ Full recovery possible
1. Install LoyaltyCards Business on any device
2. Import Business Configuration
3. Scan your recovery QR
4. Business fully restored!

WITHOUT RECOVERY BACKUP QR:
⚠️ Partial recovery may be possible

Your private keys are stored in iOS Keychain (separate from app data). 
If you're using the same device, we may be able to recover your keys.

Please contact support@[domain] immediately for assistance.

WORST CASE (device lost + no backup):
❌ Business configuration cannot be recovered
- You'll need to create a new business (new keys)
- Existing customer cards will become invalid
- Customers must scan new cards from your new configuration

PREVENTION:
ALWAYS create a Recovery Backup:
Settings → Create Recovery Backup → Save QR securely
- Print it
- Save photo to secure cloud storage
- Keep physical copy in safe
```

---

## Escalation Procedures

### When to Escalate

Escalate to development team when:
- P0 (CRITICAL) issue reported
- Security vulnerability discovered
- Data corruption affecting multiple users
- Bug not covered in troubleshooting guides
- Feature request from multiple users
- App Store crash rate spike

### Escalation Process

1. **Gather Complete Information**
   - Device details (model, iOS version, app version)
   - Steps to reproduce
   - Screenshots/screen recordings
   - User consent to share data

2. **Create GitHub Issue** (or your issue tracker)
   ```
   Title: [CUSTOMER/SUPPLIER] Brief description
   Labels: bug, priority-p0/p1/p2/p3
   
   **User Report:**
   [Copy user's description]
   
   **Device Info:**
   - Device: iPhone 14 Pro
   - iOS: 16.5
   - App Version: 0.2.0 Build 21
   
   **Steps to Reproduce:**
   1. [Step 1]
   2. [Step 2]
   
   **Expected Behavior:**
   [What should happen]
   
   **Actual Behavior:**
   [What actually happens]
   
   **Screenshots:**
   [Attachments]
   
   **Support Ticket:** #[ticket number]
   ```

3. **Notify Development Team**
   - P0: Immediate notification (Slack, email, phone)
   - P1: Within 4 hours
   - P2/P3: Next business day

4. **Update User**
   ```
   Thank you for reporting this issue. We've escalated it to our development 
   team for investigation (Ticket #[ID]). 
   
   We'll keep you updated on progress. Expected resolution: [timeframe]
   ```

---

## App Store Review Response

### Negative Review Response Template

```
Hi [Reviewer Name],

Thank you for your feedback. We're sorry to hear about [their issue].

[If issue is fixed:]
Great news! We've released version [X.X.X] that fixes this issue. Please update 
from the App Store and let us know if you have any further problems.

[If working on fix:]
We're actively working on a fix for this and expect to release an update within 
[timeframe]. We appreciate your patience.

[If need more info:]
We'd like to help resolve this. Could you please contact us at support@[domain] 
with more details about [specific question]?

[Always end with:]
We value your feedback and are committed to making LoyaltyCards the best 
loyalty card experience possible.

Best regards,
LoyaltyCards Team
```

---

## Support Metrics & Monitoring

### Daily Checks
- [ ] Check support email (every 4 hours during business hours)
- [ ] Monitor App Store reviews (both apps)
- [ ] Check App Store Connect crash reports
- [ ] Review open support tickets

### Weekly Analysis
- [ ] Support ticket volume (trending up/down?)
- [ ] Most common issues (top 5)
- [ ] Average resolution time
- [ ] Customer satisfaction rating
- [ ] App Store rating (current average)

### Monthly Reporting
- [ ] Total tickets opened/closed
- [ ] P0/P1 incidents
- [ ] Average response time
- [ ] Average resolution time
- [ ] FAQ updates needed
- [ ] Feature requests summary

---

## FAQ for Quick Reference

**Q: Do I need an account to use LoyaltyCards?**
A: No! LoyaltyCards is completely account-free. Just install and start scanning.

**Q: Can I use LoyaltyCards without internet?**
A: Yes! LoyaltyCards works 100% offline. All data is stored locally on your device.

**Q: Is my data synced across devices?**
A: No. For privacy, data stays on your device. If you get a new phone, you'll need to re-scan cards from businesses.

**Q: What happens if I delete the app?**
A: All your cards and stamps are deleted. Only restore if you have an iOS backup.

**Q: Why does the supplier app cost money?**
A: The supplier app is a one-time purchase with zero monthly fees (unlike other loyalty systems that charge $29-$199/month).

**Q: Can I export my cards?**
A: Not currently. Cards are tied to your device for security and privacy.

**Q: What's the difference between Simple and Secure mode?**
A: Simple = fast stamp collection (like physical cards). Secure = cryptographically verified stamps (fraud-proof).

**Q: Can suppliers see my personal information?**
A: No! Suppliers don't collect your name, email, phone, or any personal data.

---

## Support Resources

### Internal Documentation
- [User Guide](07-Documentation/USER_GUIDE.md)
- [Security Model](SECURITY_MODEL.md)
- [Vulnerabilities](VULNERABILITIES.md)
- [Defect Tracker](DEFECT_TRACKER.md)

### External Resources
- App Store Connect: https://appstoreconnect.apple.com
- TestFlight: https://testflight.apple.com

---

**Maintained by:** Development & Support Team  
**Last Updated:** April 18, 2026  
**Next Review:** Monthly or after major release
