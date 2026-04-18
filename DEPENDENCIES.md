# Dependencies

**LoyaltyCards v0.2.0 Build 21**  
**Platform:** Flutter 3.3.0+, Dart 3.3.0+  
**Last Updated:** April 18, 2026

---

## Overview

This document lists all third-party dependencies used in the LoyaltyCards project, including their versions, licenses, and security considerations. All dependencies are managed via `pubspec.yaml` files and installed through pub.dev.

---

## Production Dependencies

### Core Framework

#### Flutter SDK
- **Package:** `flutter` (sdk: flutter)
- **Version:** 3.3.0+
- **License:** BSD 3-Clause
- **Purpose:** Core Flutter framework
- **Security:** Official Google framework, regularly updated
- **Website:** https://flutter.dev

---

### Database & Storage

#### sqflite
- **Package:** `sqflite`
- **Version:** ^2.3.0
- **License:** BSD 3-Clause
- **Purpose:** SQLite database for local data storage
- **Security Considerations:**
  - Well-maintained, popular package (20k+ likes on pub.dev)
  - No known security vulnerabilities
  - Data stored unencrypted in SQLite (relies on iOS device encryption)
- **Used By:** Customer App, Supplier App
- **Website:** https://pub.dev/packages/sqflite

#### path_provider
- **Package:** `path_provider`
- **Version:** ^2.1.0
- **License:** BSD 3-Clause
- **Purpose:** Platform-specific directory paths for database storage
- **Security:** Official Flutter plugin
- **Used By:** Customer App, Supplier App
- **Website:** https://pub.dev/packages/path_provider

#### path
- **Package:** `path`
- **Version:** ^1.9.0
- **License:** BSD 3-Clause
- **Purpose:** Path manipulation utilities
- **Security:** Official Dart package
- **Used By:** Customer App, Supplier App
- **Website:** https://pub.dev/packages/path

#### flutter_secure_storage
- **Package:** `flutter_secure_storage`
- **Version:** ^10.0.0
- **License:** BSD 3-Clause
- **Purpose:** Secure storage for private cryptographic keys (iOS Keychain)
- **Security Considerations:**
  - Uses iOS Keychain (hardware-backed when available)
  - Industry-standard secure storage solution
  - Private keys never stored in SQLite
- **Used By:** Supplier App (critical security component)
- **Website:** https://pub.dev/packages/flutter_secure_storage

#### shared_preferences
- **Package:** `shared_preferences`
- **Version:** ^2.3.3
- **License:** BSD 3-Clause
- **Purpose:** Simple key-value storage for user preferences
- **Security:** Non-sensitive data only (preferences, UI state)
- **Used By:** Customer App, Supplier App
- **Website:** https://pub.dev/packages/shared_preferences

---

### Cryptography & Security

#### crypto
- **Package:** `crypto`
- **Version:** ^3.0.3
- **License:** BSD 3-Clause
- **Purpose:** SHA-256 hashing for stamp chain integrity
- **Security:** Official Dart package, widely used
- **Used By:** Customer App, Supplier App, Shared package
- **Website:** https://pub.dev/packages/crypto

#### pointycastle
- **Package:** `pointycastle`
- **Version:** ^4.0.0
- **License:** MIT License
- **Purpose:** ECDSA P-256 cryptographic signatures for Secure Mode
- **Security Considerations:**
  - Pure Dart implementation of cryptographic primitives
  - Used for ECDSA signature generation and verification
  - Critical for Secure Mode card authenticity
  - Well-established in Flutter ecosystem
- **Used By:** Customer App, Supplier App, Shared package
- **Website:** https://pub.dev/packages/pointycastle

#### local_auth
- **Package:** `local_auth`
- **Version:** ^2.3.0
- **License:** BSD 3-Clause
- **Purpose:** Biometric authentication (Face ID, Touch ID, Passcode)
- **Security Considerations:**
  - Official Flutter plugin
  - Protects private key access (V-002 security fix)
  - Uses iOS LocalAuthentication framework
  - Required Info.plist permission: NSFaceIDUsageDescription
- **Used By:** Supplier App (critical security component)
- **Website:** https://pub.dev/packages/local_auth

---

### QR Code Generation & Scanning

#### qr_flutter
- **Package:** `qr_flutter`
- **Version:** ^4.1.0
- **License:** BSD 3-Clause
- **Purpose:** QR code generation for data exchange
- **Security:** Client-side generation, no network transmission
- **Used By:** Customer App, Supplier App
- **Website:** https://pub.dev/packages/qr_flutter

#### mobile_scanner
- **Package:** `mobile_scanner`
- **Version:** ^7.2.0
- **License:** BSD 3-Clause
- **Purpose:** QR code scanning via device camera
- **Security Considerations:**
  - No data sent to external services
  - Local processing only
  - Camera permission required in Info.plist
- **Used By:** Customer App, Supplier App
- **Website:** https://pub.dev/packages/mobile_scanner

---

### Device Information

#### device_info_plus
- **Package:** `device_info_plus`
- **Version:** ^11.2.0 (Customer), ^11.5.0 (Supplier - Build 21)
- **License:** BSD 3-Clause
- **Purpose:** Device identification for multi-device tracking (V-005)
- **Security Considerations:**
  - Uses iOS identifierForVendor (app-scoped, ephemeral)
  - No persistent device fingerprinting
  - Privacy-friendly device tracking
  - Required for V-005 duplication detection
- **Used By:** Customer App, Supplier App
- **Website:** https://pub.dev/packages/device_info_plus

---

### Utilities

#### uuid
- **Package:** `uuid`
- **Version:** ^4.3.0
- **License:** MIT License
- **Purpose:** Generate unique identifiers (cards, stamps, transactions)
- **Security:** Cryptographically random UUIDs (v4)
- **Used By:** Customer App, Supplier App, Shared package
- **Website:** https://pub.dev/packages/uuid

#### intl
- **Package:** `intl`
- **Version:** ^0.20.2
- **License:** BSD 3-Clause
- **Purpose:** Internationalization and date/time formatting
- **Security:** No security concerns (formatting only)
- **Used By:** Customer App, Supplier App
- **Website:** https://pub.dev/packages/intl

---

### UI & Presentation

#### cupertino_icons
- **Package:** `cupertino_icons`
- **Version:** ^1.0.6
- **License:** MIT License
- **Purpose:** iOS-style icons (Material Design alternative)
- **Security:** No security concerns (static assets)
- **Used By:** Customer App, Supplier App
- **Website:** https://pub.dev/packages/cupertino_icons

#### google_fonts
- **Package:** `google_fonts`
- **Version:** ^8.0.2
- **License:** Apache 2.0
- **Purpose:** Custom typography for branding
- **Security Considerations:**
  - Downloads fonts from Google Fonts API at runtime
  - Fonts cached locally after first download
  - Network permission required
- **Used By:** Customer App, Supplier App
- **Website:** https://pub.dev/packages/google_fonts

---

### Supplier App - Backup & Export Features

#### image_gallery_saver
- **Package:** `image_gallery_saver`
- **Version:** ^2.0.3
- **License:** Apache 2.0
- **Purpose:** Save backup QR codes to photo gallery
- **Security:** Requires photo library permission in Info.plist
- **Used By:** Supplier App
- **Website:** https://pub.dev/packages/image_gallery_saver

#### share_plus
- **Package:** `share_plus`
- **Version:** ^10.1.4
- **License:** BSD 3-Clause
- **Purpose:** Share backup QR via email/files (iOS share sheet)
- **Security:** Uses iOS native share dialog, user controls destination
- **Used By:** Supplier App
- **Website:** https://pub.dev/packages/share_plus

#### printing
- **Package:** `printing`
- **Version:** ^5.13.4
- **License:** Apache 2.0
- **Purpose:** Print backup QR codes via iOS print dialog
- **Security:** Uses iOS native print framework
- **Used By:** Supplier App
- **Website:** https://pub.dev/packages/printing

#### pdf
- **Package:** `pdf`
- **Version:** ^3.11.1
- **License:** Apache 2.0
- **Purpose:** Generate PDF documents for backup QR codes
- **Security:** Client-side PDF generation, no network transmission
- **Used By:** Supplier App
- **Website:** https://pub.dev/packages/pdf

---

## Development Dependencies

### flutter_test
- **Package:** `flutter_test` (sdk: flutter)
- **License:** BSD 3-Clause
- **Purpose:** Unit and widget testing framework
- **Used By:** All packages (dev only)

### flutter_lints
- **Package:** `flutter_lints`
- **Version:** ^6.0.0
- **License:** BSD 3-Clause
- **Purpose:** Recommended linting rules for Flutter projects
- **Used By:** All packages (dev only)

---

## Internal Shared Package

### shared
- **Package:** `shared` (path: ../shared)
- **Version:** Local package
- **License:** Proprietary (LoyaltyCards project)
- **Purpose:** Shared models, utilities, constants between Customer and Supplier apps
- **Dependencies:** crypto, pointycastle, uuid, intl
- **Contents:**
  - Data models (Card, Stamp, Business, Transaction, QR Tokens)
  - Cryptographic utilities
  - Constants and configuration
  - Logging utilities
  - Error handling
  - UI widgets

---

## License Compliance

### License Summary

| License | Packages | Commercial Use | Attribution Required |
|---------|----------|----------------|----------------------|
| BSD 3-Clause | 15 | ✅ Yes | ✅ Yes (source code) |
| MIT | 3 | ✅ Yes | ✅ Yes (source code) |
| Apache 2.0 | 4 | ✅ Yes | ✅ Yes (source code) |

### Attribution Requirements

All third-party licenses require attribution. Attribution is provided in:
1. **App Settings Screen:** "Licenses" section shows all dependencies
2. **Source Code:** Each dependency referenced in pubspec.yaml
3. **This Document:** Comprehensive dependency list with licenses

Flutter automatically generates a licenses page accessible via:
```dart
showLicensePage(context: context);
```

---

## Security Audit Summary

### High-Risk Dependencies (Require Monitoring)

1. **flutter_secure_storage (v10.0.0)**
   - Risk: Stores private cryptographic keys
   - Mitigation: Uses iOS Keychain (hardware-backed), industry standard
   - Update Policy: Monitor for security updates monthly

2. **pointycastle (v4.0.0)**
   - Risk: Cryptographic implementation
   - Mitigation: Well-established Dart crypto library
   - Update Policy: Monitor for security updates monthly

3. **local_auth (v2.3.0)**
   - Risk: Biometric authentication bypass could expose keys
   - Mitigation: Official Flutter plugin, uses iOS LocalAuthentication
   - Update Policy: Monitor for security updates monthly

### Medium-Risk Dependencies

4. **mobile_scanner (v7.2.0)**
   - Risk: Camera access, QR parsing vulnerabilities
   - Mitigation: No data transmission, local processing only
   - Update Policy: Update quarterly or when security advisories issued

5. **sqflite (v2.3.0)**
   - Risk: SQL injection, database corruption
   - Mitigation: Parameterized queries, foreign key constraints
   - Update Policy: Update quarterly

### Low-Risk Dependencies

All other dependencies pose minimal security risk and are updated as needed for bug fixes and feature improvements.

---

## Version Update Policy

### Critical Security Updates
- **Timeline:** Within 24-48 hours of advisory
- **Scope:** flutter_secure_storage, local_auth, pointycastle, crypto
- **Process:** Immediate testing and deployment

### Regular Updates
- **Timeline:** Monthly review
- **Scope:** All dependencies
- **Process:** Check pub.dev for updates, test in development, deploy in next build

### Breaking Changes
- **Timeline:** Planned upgrade cycles
- **Scope:** Major version bumps requiring code changes
- **Process:** Full regression testing before deployment

---

## Known Vulnerabilities

**Status:** ✅ No known vulnerabilities as of April 18, 2026

To check for vulnerabilities:
```bash
flutter pub outdated
dart pub audit (when available in Dart SDK)
```

Manual monitoring:
- https://pub.dev/packages/[package_name]/changelog
- GitHub security advisories for each package
- Flutter security announcements

---

## Third-Party Services

### Google Fonts API
- **Service:** https://fonts.googleapis.com
- **Purpose:** Download custom fonts at runtime
- **Data Shared:** Font name (no user data)
- **Privacy:** No user tracking, fonts cached locally
- **Fallback:** System fonts if network unavailable

### No Other External Services
- No analytics
- No crash reporting
- No advertising
- No backend API
- No cloud storage

---

## Dependency Installation

### Clean Install
```bash
cd 03-Source/customer_app && flutter pub get
cd ../supplier_app && flutter pub get
cd ../shared && flutter pub get
```

### Update Dependencies
```bash
flutter pub upgrade --major-versions  # Update to latest compatible
flutter pub outdated                  # Check for newer versions
```

### Verify Integrity
```bash
flutter pub deps  # Show dependency tree
flutter pub get   # Re-fetch and verify checksums
```

---

## References

- [Customer App pubspec.yaml](03-Source/customer_app/pubspec.yaml)
- [Supplier App pubspec.yaml](03-Source/supplier_app/pubspec.yaml)
- [Shared Package pubspec.yaml](03-Source/shared/pubspec.yaml)
- [Flutter Dependency Management](https://docs.flutter.dev/development/tools/pubspec)
- [pub.dev Package Repository](https://pub.dev)

**Maintained by:** Development Team  
**Last Updated:** April 18, 2026
