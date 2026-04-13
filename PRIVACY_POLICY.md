# Privacy Policy for LoyaltyCards

**Last Updated:** April 13, 2026  
**Effective Date:** April 13, 2026

---

## Overview

LoyaltyCards is committed to protecting your privacy. This Privacy Policy explains our data collection and usage practices for both the **LoyaltyCards** (customer) and **LoyaltyCards Business** (supplier) applications.

**The short version: We collect NO personal data. Everything stays on your device.**

---

## Data We DO NOT Collect

We do not collect, store, transmit, or process any of the following:

- ❌ Personal information (name, email, phone number, address)
- ❌ Account credentials (no accounts or login required)
- ❌ Payment information
- ❌ Location data
- ❌ Device identifiers
- ❌ Usage analytics
- ❌ Tracking or advertising data
- ❌ Browsing history
- ❌ Contacts or photos (except when you explicitly save backup QR codes)
- ❌ Any data about you or your usage

---

## How LoyaltyCards Works

### Local Storage Only

All data is stored **exclusively on your device** using iOS local storage:

- **Customer App:** Your loyalty cards and stamp history are stored in your device's local database (SQLite)
- **Supplier App:** Your business configuration and transaction history are stored in your device's local database (SQLite)

**Your data never leaves your device.** We have no servers, no cloud storage, and no data backends.

### Peer-to-Peer Architecture

LoyaltyCards uses a peer-to-peer (P2P) architecture:

- When you scan a QR code, the transaction happens directly between your device and the business's device
- No data is sent to our servers (we don't have servers)
- No internet connection is required for the app to function
- QR codes contain only the minimal data needed for the transaction (business ID, card ID, stamp count)

---

## Data You Create

The following data is created and stored **locally on your device only**:

### Customer App:
- Loyalty cards you've added by scanning QR codes
- Stamp counts for each business
- Transaction timestamps (when you received stamps)
- Business information (name, color, logo) from scanned QR codes

### Supplier App:
- Your business name and configuration
- Cryptographic keys for validating stamps (stored in iOS Keychain)
- Statistics (number of cards issued, redemptions)
- Transaction history (anonymous card IDs, timestamps)

**None of this data is transmitted to us or any third party.**

---

## Permissions We Request

### Camera Permission
- **Purpose:** Scan QR codes to add loyalty cards, issue stamps, and redeem rewards
- **When:** Both apps request camera access when you first try to scan a QR code
- **Data:** No camera images are stored or transmitted; we only read QR code data

### Photo Library Permission (Supplier App Only)
- **Purpose:** Save backup QR codes to your Photos app for safekeeping
- **When:** Only when you explicitly tap "Save to Photos" for a backup
- **Data:** Only saves QR code images you choose to save; no photos are read or transmitted

---

## What Happens to Your Data

### If You Delete the App:
- **Customer App:** All your loyalty cards and stamp history are permanently deleted from your device
- **Supplier App:** All business configuration and transaction history are permanently deleted from your device
- There is no way to recover this data (no cloud backup from us)

### If You Lose Your Device:
- **Customer:** Your loyalty cards are lost (like physical cards)
- **Supplier:** Your business configuration is lost UNLESS you created a backup QR code

### Backup Feature (Supplier App Only):
- Suppliers can create backup QR codes containing their business configuration
- These backups are created by YOU and stored where YOU choose:
  - Printed on paper
  - Saved to your Photos (local or iCloud)
  - Emailed to yourself
  - Saved to Files app
- We never receive or store your backups
- Backups contain your cryptographic keys - keep them secure

---

## Third-Party Services

**We use NO third-party services.** This means:

- No analytics (Google Analytics, Firebase, Mixpanel, etc.)
- No crash reporting (Crashlytics, Sentry, etc.)
- No advertising networks
- No authentication services (Auth0, Firebase Auth, etc.)
- No cloud storage (AWS, Google Cloud, iCloud from our side, etc.)
- No payment processors
- No customer support platforms

The only third-party code we use is:
- Flutter framework (Google - open source, no data collection)
- Open source libraries for QR codes, database, and cryptography (no data collection)

---

## Children's Privacy

LoyaltyCards does not collect any personal information from anyone, including children under 13. Since we collect no data, COPPA (Children's Online Privacy Protection Act) does not apply to our app.

---

## GDPR Compliance

LoyaltyCards is compliant with the General Data Protection Regulation (GDPR) by design:

- **Right to access:** We don't have your data
- **Right to rectification:** Not applicable
- **Right to erasure:** Delete the app
- **Right to data portability:** All data stays on your device
- **Right to object:** Not applicable (no processing)
- **Data protection by design:** No data collection by architecture

If you are in the EU, your data stays on your device and is never transmitted to us or any other party.

---

## California Privacy Rights (CCPA)

Under the California Consumer Privacy Act (CCPA), California residents have certain rights. However, LoyaltyCards:

- Does not "sell" personal information (we don't collect any)
- Does not "share" personal information (we don't have any)
- Does not use personal information for "targeted advertising" (no data, no ads)

---

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time. If we make material changes, we will:

1. Update the "Last Updated" date at the top of this policy
2. Notify users through the app (if technically feasible)
3. Post the updated policy at this same URL

Your continued use of LoyaltyCards after changes constitutes acceptance of the updated policy.

---

## Data Security

Since we collect no personal data and all data stays on your device:

- **Device Security:** Your data is protected by your device's security (passcode, Face ID, Touch ID)
- **Cryptographic Keys:** Supplier cryptographic keys are stored in iOS Keychain (encrypted by iOS)
- **Local Database:** iOS sandboxes app data (other apps cannot access it)
- **No Network Transmission:** No data leaves your device, so no network security risks

---

## Your Choices

### Customer App:
- **Don't want a loyalty card?** Don't scan the QR code
- **Want to delete a card?** Swipe left and tap Delete
- **Want to delete all your cards?** Delete the app

### Supplier App:
- **Don't want to use the app?** Don't set up a business
- **Want to delete your business?** Settings → Reset Business Configuration
- **Want to delete all data?** Delete the app

---

## Contact Information

If you have questions about this Privacy Policy or LoyaltyCards:

- **Email:** ian.hamlet@dotConnected.com
- **GitHub:** https://github.com/ian-hamlet/LoyaltyCards

Please note: Since we collect no data, we cannot help you recover lost data or access data from your device.

---

## Summary (TL;DR)

✅ **Zero data collection** - We collect nothing about you  
✅ **Local storage only** - Everything stays on your device  
✅ **No servers** - We have no cloud infrastructure  
✅ **No tracking** - We don't know you or what you do  
✅ **No accounts** - No signup, no login, no password  
✅ **Peer-to-peer** - Direct device-to-device transactions  
✅ **Privacy by design** - Impossible for us to access your data  

**Your privacy is guaranteed by our architecture, not just our policy.**

---

## Legal

This Privacy Policy constitutes a legal agreement between you and LoyaltyCards. By installing and using LoyaltyCards, you agree to this Privacy Policy.

LoyaltyCards is provided "as is" without warranty of any kind.

---

**LoyaltyCards** - Privacy-First Loyalty Cards

*No servers. No tracking. No personal data. Ever.*
