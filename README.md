# LoyaltyCards Application

**Status:** v0.3.0+1 - Production-Ready, Deployed to TestFlight  
**Last Updated:** 2026-04-22  
**Test Coverage:** 264 automated tests (100% passing)  
**Release Branch:** releases/v0.3.0-build01

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
cd source/customer_app
flutter run

# Supplier App
cd source/supplier_app
flutter run
```

### Running Tests

```bash
# All 264 tests (100% passing)
cd source/shared && flutter test       # 131 tests
cd source/customer_app && flutter test  # 87 tests
cd source/supplier_app && flutter test  # 46 tests
```

See [docs/quality/TESTING_STRATEGY.md](docs/quality/TESTING_STRATEGY.md) for comprehensive testing documentation.

## Documentation

**Complete Documentation Index:** [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) - Master navigation for all 69 docs

### User Documentation
- [docs/user/USER_GUIDE.md](docs/user/USER_GUIDE.md) - End-user guide for both apps
- [docs/user/ABOUT_LOYALTYCARDS.md](docs/user/ABOUT_LOYALTYCARDS.md) - About the app

### Development Documentation
- [docs/quality/TESTING_STRATEGY.md](docs/quality/TESTING_STRATEGY.md) - Testing approach and coverage
- [docs/quality/EXPERT_CODE_REVIEW_PRODUCTION_READINESS.md](docs/quality/EXPERT_CODE_REVIEW_PRODUCTION_READINESS.md) - Production readiness assessment
- [docs/technical/SECURITY_MODEL.md](docs/technical/SECURITY_MODEL.md) - Security architecture
- [docs/technical/DATABASE_SCHEMA.md](docs/technical/DATABASE_SCHEMA.md) - Database design
- [docs/development/](docs/development/) - AI prompts and development standards ⭐
- [source/README.md](source/README.md) - Source code structure

### Planning & Process
- [docs/project-management/NEXT_ACTIONS.md](docs/project-management/NEXT_ACTIONS.md) - Current status and roadmap
- [docs/meta/PROJECT_METADATA.md](docs/meta/PROJECT_METADATA.md) - Project information
- [CHANGELOG.md](CHANGELOG.md) - Version history and release notes
- [docs/deployment/RELEASES.md](docs/deployment/RELEASES.md) - Release branch documentation

## Project Structure

### Core Directories

```
LoyaltyCards/
├── docs/                     # All documentation (organized by category)
│   ├── development/          # AI prompts, code review templates, standards
│   ├── project-management/   # Requirements, planning, defects (24 requirements)
│   ├── technical/            # Architecture, database, security, dependencies
│   ├── deployment/           # TestFlight, App Store, operations
│   ├── legal/                # Privacy policy, terms, accessibility
│   ├── quality/              # Testing, code reviews, vulnerabilities
│   ├── user/                 # User guides and end-user documentation
│   └── meta/                 # Project metadata and documentation tracking
│
├── source/                   # All source code (see source/README.md)
│   ├── shared/               # Shared Dart package (131 tests)
│   ├── customer_app/         # Customer Flutter app (87 tests)
│   └── supplier_app/         # Supplier Flutter app (46 tests)
│
├── CHANGELOG.md              # Version history and release notes
├── DOCUMENTATION_INDEX.md    # Master navigation for all 69 docs
└── README.md                 # This file
```

### Key Documents

See [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) for complete navigation of all 69 documentation files organized in 8 categories.

## Current Status

**Version:** v0.3.0+1  
**Phase:** Production - TestFlight Testing  
**Status:** Production-ready, all critical security fixes deployed

### Completed Work
- ✅ Dual-mode system (Secure + Simple)
- ✅ Full P2P QR workflow
- ✅ Face ID / Touch ID authentication
- ✅ Backup/restore with encryption
- ✅ 264 automated unit tests (100% passing)
- ✅ All critical security vulnerabilities fixed (SEC-001, SEC-002, ERROR-001)
- ✅ TestFlight deployment (Build 23 production release)
- ✅ Comprehensive code review and production readiness assessment

### Test Coverage
- **Shared Package:** 80%+ (models, QR tokens, utilities, security)
- **Customer App:** 70%+ (services, validation, rate limiting, database)
- **Supplier App:** 95%+ (CRITICAL - cryptographic operations)

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
- All AI prompts documented in `docs/development/`
- Development standards in `docs/development/DEVELOPMENT_STANDARDS.md`
- Lessons learned in `docs/quality/LESSONS_LEARNED.md`

## Getting Started

1. **Clone the repository**
2. **Install Flutter** (see [source/FLUTTER_SETUP_GUIDE.md](source/FLUTTER_SETUP_GUIDE.md))
3. **Run the apps** (see Quick Start above)
4. **Run tests** to verify everything works
5. **Read the docs** in `07-Documentation/`
