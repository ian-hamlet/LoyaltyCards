# LoyaltyCards Support

**Last Updated:** July 20, 2026

This page covers both apps in the LoyaltyCards system:

- **LoyaltyCards** — the customer wallet app
- **LoyaltyCards Business** — the supplier/business app

The two apps work together via QR codes. You'll typically need both installed on different devices (customer's phone + business's phone/iPad) to complete a full stamp-collect-redeem cycle.

---

## Contact Us

**Email:** ian.hamlet@dotconnected.com
**Response Time:** We aim to respond within 24-48 hours (business days, UK time)

Please include:
- Which app you're using (LoyaltyCards or LoyaltyCards Business)
- Your device model and iOS version (Settings → General → About)
- The app version (Settings → About)
- What you were trying to do and what happened instead

---

## Frequently Asked Questions

**Do I need an account to use LoyaltyCards?**
No. LoyaltyCards is completely account-free. Just install and start scanning QR codes.

**Can I use LoyaltyCards without an internet connection?**
Yes. LoyaltyCards works entirely offline. All data is stored locally on your device.

**Is my data synced across devices?**
No. For privacy, your data stays on your device only. If you get a new phone, you'll need to re-scan cards from businesses you visit.

**What happens if I delete the app?**
All your cards and stamps are permanently deleted from that device. There is no cloud backup. If you have an iOS device backup (iCloud/iTunes) from before deletion, restoring it will bring your data back.

**Why does LoyaltyCards Business cost money (if it does)?**
Check the current App Store listing for pricing — LoyaltyCards Business is offered without ongoing subscriptions or per-transaction fees, unlike many loyalty platforms.

**Can I export my cards?**
Not currently. Cards are tied to your device for security and privacy.

**What's the difference between Simple and Secure mode?**
Simple Mode is fast, trust-based stamp collection (like a physical punch card). Secure Mode adds cryptographic signatures to every stamp for fraud resistance, at the cost of an extra scanning step.

**Can businesses see my personal information?**
No. LoyaltyCards Business never collects your name, email, phone number, or any other personal data. See our [Privacy Policy](PRIVACY_POLICY.md) for details.

---

## Common Issues

### QR scanner won't open or won't scan

1. Go to iOS Settings → LoyaltyCards (or LoyaltyCards Business) → enable Camera permission.
2. Force-quit and reopen the app.
3. If the camera doesn't work in any app (including the built-in Camera app), this is a device hardware issue — contact Apple Support.

### A card doesn't appear after scanning

1. Force-quit and reopen the app.
2. Check whether "Hide Redeemed" is filtering it out — look for a filter control near the card list.
3. If it's still missing, please contact us with your device/app version and what the QR code was for.

### Stamps aren't being added after a scan

- Stamp QR codes are time-limited for security (roughly 2 minutes). Ask the business to generate a fresh one and scan immediately.
- There's a short cooldown between stamp scans (a few seconds) to prevent accidental duplicates — wait a moment and try again.
- If the business recently reconfigured their loyalty program, your existing card may need to be re-issued.

### Redemption QR is rejected as invalid

- Make sure both the customer and the business are on the latest version of their app (App Store → Updates).
- Redemption QR codes are time-limited — generate a fresh one right at the counter rather than in advance.

### I lost my cards / business configuration after losing or replacing my device

- **Customers:** Cards cannot be recovered unless you have an iOS device backup from before the loss. Otherwise, please visit the business again to get a new card.
- **Businesses:** If you created a Recovery Backup QR code, you can restore your full business configuration on any device via *Import Business Configuration*. Without a backup, please contact us — recovery may still be possible via data stored in the device's Keychain, but this is not guaranteed. We strongly recommend creating a Recovery Backup as soon as you set up your business (Settings → Create Recovery Backup).

### I want to reset the app back to a clean state

The in-app data-reset option is intentionally not available in the App Store release, to prevent accidental data loss. To fully reset: delete the app and reinstall it from the App Store. This permanently erases all local cards/business data on that device, so make sure you have a Recovery Backup first if you're using the Business app.

---

## Related Documents

- [Privacy Policy](PRIVACY_POLICY.md)
- [Terms of Service](TERMS_OF_SERVICE.md)
- [Accessibility Statement](ACCESSIBILITY_STATEMENT.md)

---

LoyaltyCards is provided without a guaranteed ongoing support SLA. We aim to respond promptly, but paper stamp cards remain a valid fallback for any business that prefers not to rely on the app.
