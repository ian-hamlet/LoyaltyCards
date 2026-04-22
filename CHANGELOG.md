# Changelog

All notable changes to the LoyaltyCards project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.3.0+1] - Build 23 (2026-04-21) - CURRENT

**Status:** ✅ Production - Deployed to TestFlight  
**Release Branch:** releases/v0.3.0-build01

### 🔒 CRITICAL Security Fixes

#### Fixed
- **SEC-001: Hardcoded HMAC Key Vulnerability** - CRITICAL
  - Replaced hardcoded HMAC key with HKDF key derivation from business private key
  - Each business now has unique HMAC key derived cryptographically
  - Prevents forgery of backup QR codes
  - File: `shared/lib/models/supplier_config_backup.dart`

- **SEC-002: Timing Attack Vulnerability** - HIGH
  - Implemented constant-time comparison for signature verification
  - XOR-based byte comparison prevents timing-based signature guessing
  - Protects against side-channel attacks
  - File: `shared/lib/models/supplier_config_backup.dart`

- **ERROR-001: Missing Error Handling** - CRITICAL
  - Added comprehensive error handling to TransactionRepository (all 11 methods)
  - Prevents app crashes on database errors
  - User-friendly error messages via TransactionException.getUserMessage()
  - File: `customer_app/lib/services/transaction_repository.dart`

### 📦 Package Updates

#### Updated
- `device_info_plus`: 11.5.0 → 13.1.0 (fixes Xcode 64-to-32 bit warnings)
- `local_auth`: 2.3.0 → 3.0.1 (breaking API changes handled)
- `share_plus`: 10.1.4 → 12.0.2 (enhanced sharing capabilities)
- `win32`: 5.15.0 → 6.0.1 (Windows compatibility)

#### Breaking Changes Handled
- `local_auth` 3.0.1: Removed `AuthenticationOptions` parameter, simplified authenticate() calls
- Updated both customer and supplier apps for API compatibility

### 🐛 Bug Fixes

#### Fixed
- **Multi-Stamp Token Generation Bug** - CRITICAL (Simple Mode)
  - QR codes now regenerate in real-time when slider or expiry changes
  - Prevents customers scanning outdated tokens
  - File: `supplier_app/lib/screens/supplier/supplier_stamp_card.dart`

- **Text Contrast Issue** - HIGH (Accessibility)
  - "Card Created" title in stamp history now readable on light blue background
  - Added `color: BrandColors.textPrimary` to title text
  - File: `customer_app/lib/screens/customer/customer_card_detail.dart`

### ✨ Features & Improvements

#### Added
- **QR Token Generator Error Handling** - HIGH
  - QRGenerationException with comprehensive error handling
  - All QR generation paths now properly handle failures
  - File: `customer_app/lib/services/qr_token_generator.dart`

- **Biometric Auth Structured Results** - HIGH
  - BiometricAuthResult with 6 specific status types
  - Eliminates silent failures in authentication flows
  - Files: `customer_app/lib/services/biometric_auth_service.dart`, `supplier_app/lib/services/biometric_auth_service.dart`

- **User-Friendly Error Messages** - HIGH
  - ErrorMessageMapper utility for translating technical errors
  - Consistent error presentation across both apps
  - File: `shared/lib/utils/error_handler.dart`

- **SharedPreferences Error Handling** - HIGH
  - Try-catch wrapping with UI state revert on failure
  - Prevents silent data loss
  - File: `customer_app/lib/screens/customer/customer_settings.dart`

#### Changed
- **UX Streamlining** - Removed "Save to Photos" option from backup workflows
  - Simplified to 3 options: Print, Share via Email, Save to Files
  - Reduces user confusion and maintenance burden
  - File: `supplier_app/lib/screens/supplier/recovery_backup_screen.dart`

- **Smart Routing Documentation** - Added comprehensive inline documentation
  - Explains auto-routing to correct business card
  - Documents auto-new-card creation on completion (not just overflow)
  - File: `customer_app/lib/screens/customer/qr_scanner_screen.dart`

### ✅ Testing

#### Added
- **TEST-001: BackupStorageService Tests** - 16 comprehensive tests
  - HKDF key derivation validation
  - Constant-time comparison verification
  - QR generation edge cases
  - File: `shared/test/services/backup_storage_service_test.dart`

- **TEST-002: Database Timeout Tests** - 17 comprehensive tests
  - 10-second timeout verification
  - Recovery mechanism validation
  - Both customer and supplier app coverage
  - Files: `customer_app/test/services/database_timeout_test.dart`, `supplier_app/test/services/database_timeout_test.dart`

#### Updated
- **Test Suite Expansion**: 165 → 264 tests (99 new tests added)
  - Customer App: 70 → 87 tests
  - Supplier App: 30 → 46 tests
  - Shared Package: 115 → 131 tests
- **Test Success Rate**: 100% (264/264 passing)

### 📚 Documentation

#### Added
- `EXPERT_CODE_REVIEW_PRODUCTION_READINESS.md` - Comprehensive production readiness assessment
- `EXPERT_ARCHITECTURAL_REVIEW.md` - Architecture review report
- `DOCUMENTATION_INDEX.md` - Master index of all project documentation
- `DOCUMENTATION_CLEANUP_SUMMARY.md` - Documentation consolidation record
- `LESSONS_LEARNED.md` - AI-driven development insights

#### Updated
- Major documentation reorganization into 8 logical categories
- 56 files moved from flat structure to organized folders
- All paths updated and cross-references maintained

#### Removed
- 12 outdated/duplicate documents consolidated

### 🗄️ Database

#### No Changes
- Customer App Database: v7 (stable)
- Supplier App Database: v5 (stable)

### 🔧 Technical Debt Addressed

- Removed obsolete `loyalty_cards_prototype` folder
- Suppressed Xcode warning for device_info_plus (64-to-32 bit conversion)
- Code review findings fully addressed (all CRITICAL and HIGH priority issues)

---

## [0.2.1+23] - Build 23 (2026-04-18)

**Status:** ✅ TestFlight Testing (Internal)  
**Note:** Version number remained 0.2.1+23 during bug fixes before incrementing to 0.3.0+1

### 🐛 Bug Fixes

#### Fixed
- Various minor bug fixes during pre-release testing
- UI/UX refinements based on internal feedback
- Stability improvements

---

## [0.2.0] - Build 21 (2026-04-18)

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
