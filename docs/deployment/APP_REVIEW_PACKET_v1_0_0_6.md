# App Review Packet (v1.0.0+6)

Use this file for App Store Connect Review Information, compliance prompts, and reviewer guidance.

---

## Reviewer Setup Summary

- Apps under review:
  - LoyaltyCards - Digital Stamps (Customer)
  - LoyaltyCards Business (Supplier)
- Architecture: Peer-to-peer via QR codes, offline-capable, no backend accounts
- Demo account required: No
- Internet required for core flow: No

---

## Reviewer Test Instructions

1. Install both apps: LoyaltyCards (customer) and LoyaltyCards Business (supplier).
2. Open LoyaltyCards Business and create a test business:
   - Name: Test Coffee Shop
   - Stamps required: 5
   - Mode: Simple Mode
3. In supplier app, open Issue Card and display the QR code.
4. In customer app, scan supplier QR and verify card appears.
5. In customer app, open card and show collect/redeem QR.
6. In supplier app, stamp card by scanning customer QR.
7. Repeat until complete and verify redemption flow.

Expected behavior:
- No login/signup prompts
- No backend credential requirement
- Flow works offline

---

## Biometric Note for Review

- Customer app: Face ID/Touch ID app lock is optional.
- Supplier app: Face ID/Touch ID/passcode required for sensitive private-key operations (backup/clone).
- On devices without biometrics, passcode fallback is available.

Recommended note in App Review Information:
Biometric authentication for private-key access can only be fully validated on physical devices. Simulator behavior may differ due to platform limitations.

---

## Export Compliance Suggested Answers

Question: Does your app use encryption?
- Answer: Yes

Question: Is encryption proprietary?
- Answer: No

Question: Is encryption limited to standard algorithms and platform security?
- Answer: Yes

Rationale:
- Uses standardized cryptography (ECDSA P-256 and SHA-256).
- No proprietary/enhanced/custom cryptographic algorithms.

---

## App Privacy (Data Collection) Suggested Answers

- Does this app collect user data: No
- Does this app track users across apps/sites: No
- Third-party advertising SDKs: No

Suggested label:
Data Not Collected

---

## Contact Information for Review

- Contact Name: Ian Hamlet
- Contact Email: ian.hamlet@dotConnected.com
- Contact Phone: (enter monitored number in App Store Connect)

---

## Fast Responses for Common Reviewer Questions

Question: Why are two apps required?
Answer: This is a two-sided loyalty system with separate customer and business workflows. Both apps are required to test end-to-end issuance, stamp collection, and redemption.

Question: Where is backend login?
Answer: There is no backend account system. This product is intentionally peer-to-peer and offline-capable.

Question: Why is biometric prompt shown?
Answer: Supplier app protects private-key backup/clone operations with device authentication for security.

---

## Copy/Paste Reviewer Response Templates

### Template A - Two-App Workflow Clarification

Thank you for the review.

LoyaltyCards is intentionally a two-app system:
- LoyaltyCards (customer app)
- LoyaltyCards Business (supplier app)

Both apps are required to validate end-to-end card issuance, stamp collection, and redemption. This is the expected product architecture.

### Template B - Offline / No Backend Clarification

Thank you for the review.

This product is designed as a peer-to-peer QR workflow and does not require user accounts or backend login. Core functionality works offline after installation.

### Template C - Biometric Behavior Clarification

Thank you for the review.

Biometric authentication is used only for sensitive private-key operations in the supplier app (backup/clone). On devices without enrolled biometrics, passcode fallback is supported.

### Template D - Re-Test Guidance

Please test the following quick path:
1. Configure supplier business in LoyaltyCards Business
2. Issue card QR and scan from LoyaltyCards
3. Stamp card from supplier app
4. Complete card and redeem

Expected result: full workflow completes without login/account requirements.
