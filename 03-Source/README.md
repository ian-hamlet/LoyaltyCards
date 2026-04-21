# LoyaltyCards Source Code

This directory contains the Phase 0+ implementation of the LoyaltyCards P2P system.

## Project Structure

```
03-Source/
├── shared/                     # Shared Dart package (v0.3.0)
│   ├── lib/
│   │   ├── models/            # Data models (Card, Stamp, Business, Transaction)
│   │   ├── utils/             # Crypto, logging utilities
│   │   ├── constants/         # App constants and branding
│   │   ├── services/          # StampSigner cryptographic service
│   │   └── shared.dart        # Main export
│   └── test/                  # 13 unit tests (StampSigner)
│       ├── models/            # Model tests
│       ├── services/          # StampSigner cryptographic tests
│       └── qr_tokens_test.dart
│
├── customer_app/              # Customer Flutter app (v0.3.0)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/customer/
│   │   └── services/          # Repositories, validators, rate limiting
│   ├── pubspec.yaml
│   └── test/                  # 64 unit tests (62 pass consistently)
│       └── services/          # Service tests with mocking
│
├── supplier_app/              # Supplier Flutter app (v0.3.0)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/supplier/
│   │   └── services/          # Key management, signing, backups
│   ├── pubspec.yaml
│   └── test/                  # 30 unit tests (all passing)
│       └── services/          # KeyManager and StampSigner tests
│
└── loyalty_cards_prototype/   # Original prototype (preserved for reference)
```

## Running the Apps

### Customer App
```bash
cd customer_app
flutter run
```

### Supplier App
```bash
cd supplier_app
flutter run
```

## Running Tests

**All tests:**
```bash
# Shared package (13 tests - StampSigner)
cd shared && flutter test

# Customer app (64 tests - 62 pass consistently, 2 flaky)
cd customer_app && flutter test

# Supplier app (30 tests)
cd supplier_app && flutter test
```

**Test Status (v0.3.0):**
- Shared StampSigner: 13/13 tests passing ✅
- Customer services: 62/64 tests passing (2 flaky due to database locking)
- Supplier services: 30/30 tests passing ✅

**Known Test Issue:**
When running the complete customer_app test suite, 2 tests in `card_repository_validation_test.dart` occasionally fail with "readonly database" errors due to SQLite file locking race conditions. This is a test infrastructure issue only - production code is unaffected. Tests pass reliably when run individually.

See [KNOWN_ISSUES_AND_RISKS.md](../00-Planning/KNOWN_ISSUES_AND_RISKS.md#issue-1-database-locking-during-full-test-suite-execution) for details.

**Test Coverage:**
- Shared StampSigner cryptographic operations: 13 tests (95%+ coverage)
- Customer services: 64 tests (rate limiting, validation, crypto, database)
- Supplier services: 30 tests (KeyManager, StampSigner, database)

**See:** [TESTING_STRATEGY.md](../TESTING_STRATEGY.md) for comprehensive test plan

## Development Status

- ✅ **v0.3.0 (Build 46+)** - Enhanced UX with progressive disclosure patterns
  - Secure mode: Full ECDSA cryptography with stamp chain validation
  - Simple mode: Enhanced QR workflow with Save/Print/Share functionality
  - Progressive disclosure UI (ExpansionTile) for optional settings
  - Consistent slider patterns for discrete numeric values
  - Face ID/Touch ID authentication
  - Backup/restore functionality
  - Comprehensive automated test suite (107 tests, 92+ passing consistently)
  
- ✅ **Phases 0-6:** Complete
  - Foundation, data layer, cryptography, P2P, UX polish, dual-mode
  
- ✅ **Current:** Code review fixes and UX improvements
  - Database migration rollback safety
  - Enhanced simple supplier mode UX
  - Architectural review fixes implemented
  - iOS build stability improvements

## Quick Commands

```bash
# Analyze code
flutter analyze

# Get dependencies
flutter pub get

# Clean build
flutter clean

# Run tests
flutter test
```

## Dependencies

All projects use:
- Flutter SDK 3.41+
- Dart SDK 3.3.0+

See individual `pubspec.yaml` files for specific package dependencies.

## Documentation

- [Project Development Plan](../00-Planning/PROJECT_DEVELOPMENT_PLAN.md)
- [Phase 0 Completion](../00-Planning/PHASE_0_COMPLETION.md)
- [Quick Reference](../00-Planning/QUICK_REFERENCE.md)
- [Daily Progress Log](../00-Planning/DAILY_PROGRESS_LOG.md)
