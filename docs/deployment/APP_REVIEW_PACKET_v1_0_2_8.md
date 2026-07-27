# App Review Packet (v1.0.2+8)

Use this file for App Store Connect Review Information, compliance prompts, and reviewer guidance.

**Supersedes:** `APP_REVIEW_PACKET_v1_0_0_6.md` (that build was never actually submitted for review — this app has only ever been distributed via TestFlight beta). Content carried forward unchanged except version, contact email casing, and the addition of live Privacy/Support URLs.

---

## Reviewer Setup Summary

- Apps under review:
  - LoyaltyCards - Digital Stamps (Customer)
  - LoyaltyCards Business (Supplier)
- Architecture: Peer-to-peer via QR codes, offline-capable, no backend accounts
- Demo account required: No
- Internet required for core flow: No
- Privacy Policy: https://ian-hamlet.github.io/LoyaltyCards/legal/privacy-policy.html
- Support: https://ian-hamlet.github.io/LoyaltyCards/support/

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

**Updated 2026-07-25** — a role-based review (see
[docs/quality/REVIEW_ROLES.md](../quality/REVIEW_ROLES.md), App Store /
Platform Compliance section) found the previous "Data Not Collected" answer
below doesn't account for a hashed device identifier the customer app
transmits P2P during Secure Mode redemption (added by the V-005 anti-fraud
fix — see [docs/legal/PRIVACY_POLICY.md](../legal/PRIVACY_POLICY.md)'s
"Anti-Fraud Device Signal" section for the full description). Apple's data-
collection definition covers data transmitted to *any* party, not just to a
server, so this should be declared rather than answered "No."

- Does this app collect user data: **Yes** (customer app only — see below;
  supplier app remains "No")
- Data type to declare: **Device ID**
  - Linked to identity: **No**
  - Used for tracking: **No**
  - Purpose: **App Functionality** (fraud prevention — detecting the same
    loyalty card being redeemed from an unusual number of different
    devices)
- Does this app track users across apps/sites: No
- Third-party advertising SDKs: No

Suggested label:
~~Data Not Collected~~ **Data Not Linked to You** (customer app) /
**Data Not Collected** (supplier app, unchanged)

☐ **Not yet entered into App Store Connect** — the questionnaire there was
filled in before this finding (see submission checklist). Needs updating
before next submission of the customer app.

---

## Contact Information for Review

- Contact Name: Ian Hamlet
- Contact Email: ian.hamlet@dotconnected.com
- Contact Phone: 07968135909

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
