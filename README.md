# LoyaltyCards Application

**Status:** v0.2.1 (Build 23) - Deployed to TestFlight  
**Last Updated:** 2026-04-18  
**Test Coverage:** 165 automated tests (100% passing)

## Project Overview

A peer-to-peer (P2P) digital loyalty card system that operates without a backend server. Customers collect stamps via QR codes, and suppliers issue stamps using cryptographic signatures. No personal data collection, no internet required after initial setup.

**Two Apps:**
- **Customer App** - Collect and manage loyalty cards
- **Supplier App** - Issue cards and add stamps to customer cards

**Key Features:**
- ✅ Dual-mode operation (Secure with ECDSA crypto, Simple without)
- ✅ QR code-based P2P data exchange
- ✅ Face ID / Touch ID authentication
- ✅ Offline-capable (no backend required)
- ✅ Encrypted backup/restore
- ✅ Zero personal data collection

## Quick Start

### Running the Apps

```bash
# Customer App
cd 03-Source/customer_app
flutter run

# Supplier App
cd 03-Source/supplier_app
flutter run
```

### Running Tests

```bash
# All 165 tests
cd 03-Source/shared && flutter test       # 115 tests
cd 03-Source/customer_app && flutter test  # 33 tests
cd 03-Source/supplier_app && flutter test  # 17 tests
```

See [TESTING_STRATEGY.md](TESTING_STRATEGY.md) for comprehensive testing documentation.

## Documentation

### User Documentation
- [USER_GUIDE.md](07-Documentation/USER_GUIDE.md) - End-user guide
- [ABOUT_LOYALTYCARDS.md](07-Documentation/ABOUT_LOYALTYCARDS.md) - About the app

### Development Documentation
- [TESTING_STRATEGY.md](TESTING_STRATEGY.md) - Testing approach and coverage
- [CODE_REVIEW_v0.2.0.md](CODE_REVIEW_v0.2.0.md) - Code quality review
- [SECURITY_MODEL.md](SECURITY_MODEL.md) - Security architecture
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Database design
- [03-Source/README.md](03-Source/README.md) - Source code structure

### Planning & Process
- [CURRENT_STATUS.md](00-Planning/CURRENT_STATUS.md) - Current development status
- [PROJECT_METADATA.md](PROJECT_METADATA.md) - Project information
- [RELEASES.md](RELEASES.md) - Release notes and changelog

## Project Structure

### Core Directories

```
LoyaltyCards/
├── 00-Planning/              # Requirements, user stories, project management
│   ├── Requirements/         # Business and functional requirements
│   ├── UserStories/          # User stories and acceptance criteria
│   └── *.md                  # Planning documents
│
├── 01-Design/                # Architecture and design documents
│   └── Architecture/         # System architecture decisions
│
├── 02-AI-Prompts/            # AI-driven development artifacts
│   └── *.md                  # Prompts and development standards
│
├── 03-Source/                # Source code (see 03-Source/README.md)
│   ├── shared/               # Shared Dart package (115 tests)
│   ├── customer_app/         # Customer Flutter app (33 tests)
│   ├── supplier_app/         # Supplier Flutter app (17 tests)
│   └── loyalty_cards_prototype/  # Original prototype
│
└── 07-Documentation/         # User guides and technical docs
    ├── USER_GUIDE.md
    └── Installation/
```

### Key Documents at Root

- **TESTING_STRATEGY.md** - Comprehensive testing approach
- **CODE_REVIEW_v0.2.0.md** - Code quality assessment
- **SECURITY_MODEL.md** - Security architecture
- **DATABASE_SCHEMA.md** - Data persistence design
- **PRIVACY_POLICY.md** - Privacy policy
- **RELEASES.md** - Version history and release notes

## Current Status

**Version:** v0.2.1 (Build 23)  
**Phase:** TestFlight Testing  
**Next:** Production feature flag review

### Completed Work
- ✅ Dual-mode system (Secure + Simple)
- ✅ Full P2P QR workflow
- ✅ Face ID / Touch ID authentication
- ✅ Backup/restore with encryption
- ✅ 165 automated unit tests (100% passing)
- ✅ TestFlight deployment (Build 23 with tester feature flags)

### Test Coverage
- **Shared Package:** 80%+ (models, QR tokens, utilities)
- **Customer App:** 70%+ (services, validation, rate limiting)
- **Supplier KeyManager:** 95%+ (CRITICAL - cryptographic operations)

## Technology Stack

- **Framework:** Flutter 3.3.0+
- **Language:** Dart
- **Database:** SQLite (sqflite)
- **Cryptography:** ECDSA P-256 (pointycastle)
- **QR Codes:** mobile_scanner, qr_flutter
- **Secure Storage:** flutter_secure_storage
- **Biometrics:** local_auth
- **Testing:** flutter_test, mockito

## Development Approach

This project uses AI-driven development with comprehensive documentation of the process:
- All AI prompts documented in `02-AI-Prompts/`
- Development standards in `02-AI-Prompts/DEVELOPMENT_STANDARDS.md`
- Lessons learned in `LESSONS_LEARNED.md`

## Getting Started

1. **Clone the repository**
2. **Install Flutter** (see [03-Source/FLUTTER_SETUP_GUIDE.md](03-Source/FLUTTER_SETUP_GUIDE.md))
3. **Run the apps** (see Quick Start above)
4. **Run tests** to verify everything works
5. **Read the docs** in `07-Documentation/`
