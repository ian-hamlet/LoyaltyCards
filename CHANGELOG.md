# Changelog

All notable changes to the LoyaltyCards project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.2.0] - Build 21 (2026-04-18) - CURRENT

**Status:** 🚧 In Development (feature/security-vulnerability-fixes → develop)

### 🔒 Security Enhancements

#### Added
- **V-002: Private Key Protection** - Biometric authentication now required for sensitive operations
  - Recovery backup QR display requires Face ID/Touch ID/Passcode authentication
  - Device clone QR display requires Face ID/Touch ID/Passcode authentication
  - New `BiometricAuthService` for unified authentication across supplier app
  - Added `local_auth` ^2.3.0 dependency for biometric authentication
  - Info.plist entries for Face ID usage descriptions in both apps

- **V-005: Multi-Device Duplication Detection** - Prevent card duplication across devices
  - Device ID tracking via `device_info_plus` ^11.5.0
  - Device ID captured during card issuance and stamping
  - Mismatch detection warns users when scanning cards from different devices
  - User-friendly warning dialog explains device binding
  - Database migration v5 → v6 adds `device_id` columns to cards and stamps tables

#### Changed
- Customer App now has optional Face ID lock feature for added privacy
- Supplier App requires authentication to access private cryptographic keys

#### Database Changes
- **Customer App Database:** v5 → v6
  - Added `device_id TEXT` column to `cards` table
  - Added `device_id TEXT` column to `stamps` table
- **Supplier App Database:** v4 (no changes this build)

#### Documentation
- Created VULNERABILITIES.md - Comprehensive security assessment
- Created TERMS_OF_SERVICE.md - Legal requirements for App Store
- Updated USER_GUIDE.md with biometric authentication instructions
- Updated BUILD_21_TESTING_GUIDE.md with security test scenarios

---

## [0.2.0] - Build 20 (2026-04-17)

### 🔒 Security
- Implemented V-002: Biometric authentication for private key access
- Added Face ID/Touch ID protection for recovery backup and device cloning

### 🐛 Bug Fixes
- **TEST-010: Redemption UI Below Fold** - Critical UX fix
  - Implemented Floating Action Button for "Scan Confirmation" - always visible
  - Compact QR layout saves ~35px vertical space
  - Smart collapse of stamp display saves ~100-120px
  - Removed duplicate stamp count text saves ~28-32px
  - Total vertical space recovered: ~163-187px
  - Resolves scrolling issues on smaller iPhone screens

---

## [0.2.0] - Build 18 (2026-04-16)

### 🐛 Bug Fixes
- **TEST-012: Camera Rotation** - Fixed camera orientation issues
  - Corrected rotation calculations in QR scanner
  - Improved camera flip functionality
  - Better handling of device orientation changes

---

## [0.2.0] - Build 17 (2026-04-16)

### 🐛 Bug Fixes
- Fixed 2 CRITICAL defects + 1 bonus enhancement
- Improved QR scanning reliability
- Enhanced stamp validation logic

---

## [0.2.0] - Build 16 (2026-04-16)

### 🐛 Bug Fixes
- Fixed 4 navigation and UI defects
- Improved user flow consistency

---

## [0.2.0] - Build 15 (2026-04-16)

**Status:** ✅ TestFlight Internal Testing

### 🚀 Features
- First TestFlight deployment for internal pilot testing
- Regression testing validation complete
- Core features stable for initial user feedback

---

## [0.2.0] - Build 4 (2026-04-14)

**Status:** ✅ TestFlight Pilot Deployment

### 🎨 Features
- Custom app icons for personalized branding
- Dual operation modes (Simple & Secure)
- Multi-device supplier support (backup & clone)
- QR-based stamp issuance and redemption
- Privacy-first P2P architecture

### 🏗️ Infrastructure
- SQLite local database
- Cryptographic signature validation (ECDSA P-256)
- Offline-capable operation
- iOS Keychain secure storage

---

## [0.1.0] - Build 46 and Earlier

### 🛠️ Development Phase
- Initial prototype development
- Core architecture implementation
- Database schema design
- Security model implementation
- Customer and Supplier app foundations

---

## Categories Reference

- **Added** - New features
- **Changed** - Changes to existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security-related changes

---

## Version History Quick Reference

| Version | Build | Date | Status | Key Focus |
|---------|-------|------|--------|-----------|
| 0.2.0 | 21 | 2026-04-18 | 🚧 Development | Security enhancements (V-002, V-005) |
| 0.2.0 | 20 | 2026-04-17 | ✅ Complete | Private key protection, UI fixes |
| 0.2.0 | 18 | 2026-04-16 | ✅ Complete | Camera rotation fixes |
| 0.2.0 | 17 | 2026-04-16 | ✅ Complete | Critical defect fixes |
| 0.2.0 | 16 | 2026-04-16 | ✅ Complete | Navigation fixes |
| 0.2.0 | 15 | 2026-04-16 | ✅ TestFlight | Internal pilot testing |
| 0.2.0 | 4  | 2026-04-14 | ✅ TestFlight | Initial pilot deployment |
| 0.1.0 | 46 | 2026-04-13 | ✅ Complete | Development phase |

---

**Maintained by:** Development Team  
**Last Updated:** April 18, 2026
