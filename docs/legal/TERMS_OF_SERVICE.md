# Terms of Service

**LoyaltyCards**  
**Last Updated:** April 17, 2026

---

## 1. Acceptance of Terms

By downloading, installing, or using the LoyaltyCards application ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.

LoyaltyCards consists of two applications:
- **Customer App**: Digital wallet for collecting and managing loyalty card stamps
- **Supplier App**: Business tool for issuing cards and managing customer rewards

---

## 2. Description of Service

### 2.1 Customer App

The Customer App allows users to:
- Receive digital loyalty cards from participating businesses
- Collect stamps by scanning QR codes provided by businesses
- Track progress toward rewards
- Redeem completed cards for rewards at participating businesses
- View transaction history

### 2.2 Supplier App

The Supplier App allows business owners to:
- Configure and manage their loyalty program
- Issue digital loyalty cards to customers
- Award stamps to customers for purchases
- Validate and redeem completed loyalty cards
- View basic usage statistics

---

## 3. Privacy & Data Storage

### 3.1 Local-Only Data Storage

**Important:** LoyaltyCards operates on a **local-only** architecture. All data is stored exclusively on your device.

- **No cloud storage**: Your cards, stamps, and transactions are never uploaded to external servers
- **No account creation**: The App does not require registration or personal information
- **No data sharing**: Your loyalty card data is not shared with us or any third party
- **P2P communication**: Data exchange happens directly between customer and supplier devices via QR codes

### 3.2 Data You Control

**Customer App:**
- Loyalty cards you've collected
- Stamps and redemption history
- Transaction logs

**Supplier App:**
- Business configuration and branding
- Cryptographic keys (Secure Mode only)
- Usage statistics

### 3.3 Data Backup Responsibility

Because data is stored locally:
- **You are responsible** for backing up your device using iOS/Android backup features
- **Lost devices** = lost loyalty cards (Customer App) or business configuration (Supplier App)
- **Supplier App backup feature**: Businesses can create recovery QR codes for disaster recovery
- **Customer App**: No built-in backup; use device-level backups (iCloud, etc.)

---

## 4. User Responsibilities

### 4.1 Customer Responsibilities

**You agree to:**
- Use the App only for legitimate loyalty card collection
- Not attempt to forge, duplicate, or manipulate loyalty cards
- Not share completed cards with others for fraudulent redemption
- Verify card details before redeeming rewards
- Manage your device storage by deleting old/redeemed cards when needed

**You acknowledge:**
- Stamps and rewards are issued by individual businesses, not by LoyaltyCards
- Reward fulfillment is the sole responsibility of the participating business
- LoyaltyCards is not liable for business decisions regarding reward acceptance or denial

### 4.2 Supplier Responsibilities

**You agree to:**
- Provide accurate business information in your loyalty program configuration
- Honor valid loyalty cards issued by your business
- Securely store your recovery backup QR code (Secure Mode)
- Verify customer identity and card validity before redeeming rewards
- Comply with local laws regarding loyalty programs and customer data
- Manage your app's local storage by pruning old cards, transactions, and logs

**You acknowledge:**
- **Device Management:** It is your responsibility to manage storage on your device. Excessive accumulation of old cards, redeemed cards, and transaction logs may impact device performance. Regularly review and delete old data as needed.
- **No centralized tracking:** Without a central server, you cannot track customer behavior across devices
- Cryptographic keys (Secure Mode) are stored only on your device(s)
- Loss of private keys means inability to manage existing customer cards
- Multi-device setup requires careful management of key distribution

---

## 5. Operation Modes

The App offers two operation modes with different security profiles:

### 5.1 Simple Mode (Trust-Based)

**Characteristics:**
- Faster stamp collection (1 scan)
- No cryptographic verification
- Customer can self-redeem (trust-based)
- Suitable for low-value rewards

**Limitations:**
- Supplier must visually verify redemption date and stamp history
- Customer could theoretically manipulate stamps (fraud risk)
- No cryptographic proof of stamp authenticity

**Recommended For:** Coffee shops, small businesses, low-value rewards (<$10)

### 5.2 Secure Mode (Cryptographic)

**Characteristics:**
- Cryptographic signature on every stamp
- Two-step redemption process (supplier confirmation required)
- Hash chain integrity verification
- QR codes expire after 2-5 minutes

**Limitations:**
- Slower stamp collection (2 scans)
- Requires key management (backup/recovery)
- More complex for users

**Recommended For:** High-value rewards ($10+), compliance requirements, audit trails

**Choosing a Mode:**
- Once selected during setup, mode cannot be changed without resetting
- Resetting invalidates all existing customer cards
- Plan carefully based on your reward value and risk tolerance

---

## 6. Service Limitations

### 6.1 Device Storage Limits (V-006)

**Customer App:**
- All cards, stamps, and transactions are stored on your device
- Excessive accumulation of data may slow device performance
- **You are responsible** for managing storage by deleting old cards
- **Recommendation:** Delete redeemed cards older than 30 days

**Supplier App:**
- All issued cards and statistics are stored on your device
- **You are responsible** for managing storage and performance
- Accumulation of thousands of card records may impact app responsiveness
- **Recommendation:** Periodically export/archive old transaction data

### 6.2 Card Revocation Limitations (V-009)

**Important Limitation:** Due to the local-only, P2P architecture, **individual card revocation is not possible**.

**If you need to revoke cards:**
- You must reset your entire business configuration
- **All existing customer cards will become invalid**
- You will need to re-issue cards to legitimate customers
- **Use Case:** Business was compromised, mass fraud detected, security breach

**Alternatives:**
- For individual customer issues, handle ad-hoc (refuse redemption, offer replacement)
- For suspicious activity, verify customer identity before redemption
- In Simple Mode, rely on visual verification of stamp history

**Design Rationale:** Without a central server, there's no way to push revocation notices to customer devices. This is an accepted trade-off for privacy and offline-first operation.

### 6.3 Multi-Device Card Duplication (V-005)

**Customer App:**
- Cards are stored locally on each device
- Restoring device backups may result in duplicate cards on multiple devices
- **Detection:** Supplier app will warn if a card is redeemed from a different device
- **Supplier discretion:** Suppliers may choose to accept or reject cards showing device mismatch

**What This Means:**
- A customer with a card on two devices (e.g., old phone + new phone) may trigger warnings
- Legitimate scenarios: Device upgrade, backup restore, family device sharing
- Fraudulent scenarios: Card duplication for multiple redemptions

**Supplier Guidance:**
- Device mismatch warnings help identify potential fraud
- Verify customer identity and purchase history before accepting
- Use professional judgment; not all mismatches are fraud

---

## 7. Security & Fraud Prevention

### 7.1 Customer Obligations

**Do Not:**
- Screenshot QR codes for reuse (Secure Mode stamps expire in 2-5 minutes)
- Share your loyalty cards with others
- Attempt to manipulate device time to bypass rate limits
- Create duplicate cards across multiple devices for fraudulent redemption

**Consequences:**
- Businesses may refuse to honor stamps or rewards
- You may be banned from participating businesses
- Legal action may be taken for fraud

### 7.2 Supplier Obligations

**Best Practices:**
- Verify customer identity for high-value redemptions
- Check stamp history for suspicious patterns (multiple stamps in minutes, impossible dates)
- Review redemption dates to ensure they match today
- Investigate device mismatch warnings before accepting redemptions
- Keep your recovery backup QR code in a secure location (Secure Mode)
- Never share your private keys or recovery QR publicly

**Security Features:**
- **Simple Mode:** 5-second rate limiting, timestamp tracking, visual verification
- **Secure Mode:** Cryptographic signatures, QR expiration, hash chain validation
- **Both Modes:** Device mismatch detection, biometric protection for backup/clone features

---

## 8. Disclaimers

### 8.1 No Warranty

THE APP IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO:
- Merchantability
- Fitness for a particular purpose
- Accuracy or reliability
- Uninterrupted or error-free operation

### 8.2 No Liability

**LoyaltyCards is not liable for:**
- Loss of data due to device failure, loss, theft, or corruption
- Disputes between customers and businesses regarding rewards
- Fraudulent use of the App by customers or suppliers
- Business decisions to deny redemption or change reward terms
- Device storage limitations or performance degradation
- Technical issues preventing stamp collection or redemption

### 8.3 Third-Party Relationships

- LoyaltyCards is a software tool; we do not operate loyalty programs
- We are not a party to any customer-business relationship
- Businesses are solely responsible for honoring their loyalty programs
- Customers must resolve disputes with businesses directly

---

## 9. Acceptable Use

**You agree NOT to:**
- Use the App for illegal purposes
- Attempt to hack, reverse engineer, or exploit the App
- Create automated systems to collect stamps ("bots")
- Interfere with other users' ability to use the App
- Violate any applicable laws or regulations

**Violations may result in:**
- Removal from participating businesses
- Legal action
- Termination of your access to the App

---

## 10. Modifications to Terms

We reserve the right to modify these Terms at any time. Changes will be effective upon posting the updated Terms in the App or on our website.

**Your continued use of the App after changes constitutes acceptance of the new Terms.**

We recommend reviewing these Terms periodically.

---

## 11. Termination

### 11.1 By You

You may stop using the App at any time by deleting it from your device.

**Note:** Deleting the App will permanently delete all local data (cards, stamps, business configuration).

### 11.2 By Us

We reserve the right to discontinue the App at any time without notice.

---

## 12. Governing Law

These Terms are governed by the laws of **[Your Jurisdiction]**, without regard to conflict of law principles.

Any disputes shall be resolved in the courts of **[Your Jurisdiction]**.

---

## 13. Contact Information

For questions or concerns about these Terms of Service:

**Email:** [Your Support Email]  
**Website:** [Your Website]

---

## 14. Severability

If any provision of these Terms is found to be unenforceable or invalid, that provision will be limited or eliminated to the minimum extent necessary, and the remaining provisions will remain in full force and effect.

---

## 15. Entire Agreement

These Terms constitute the entire agreement between you and LoyaltyCards regarding the use of the App, superseding any prior agreements.

---

**By using LoyaltyCards, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.**
