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
│   └── test/                  # 70 unit tests (all passing)
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

# Customer app (70 tests - all passing)
cd customer_app && flutter test

# Supplier app (30 tests - all passing)
cd supplier_app && flutter test
```

**Test Status (v0.3.0):**
- Shared StampSigner: 13/13 tests passing ✅
- Customer services: 70/70 tests passing ✅ (database locking issue RESOLVED)
- Supplier services: 30/30 tests passing ✅

**Total: 113 tests, 100% passing**

**Test Coverage:**
- Shared StampSigner cryptographic operations: 13 tests (95%+ coverage)
- Customer services: 70 tests (rate limiting, validation, crypto, database, repositories)
- Supplier services: 30 tests (KeyManager, StampSigner, database migration)

**See:** [TESTING_STRATEGY.md](../TESTING_STRATEGY.md) for comprehensive test plan

## Development Status

- ✅ **v0.3.0 (Build 46+)** - Enhanced UX with progressive disclosure patterns
  - Secure mode: Full ECDSA cryptography with stamp chain validation
  - Simple mode: Enhanced QR workflow with Save/Print/Share functionality
  - Progressive disclosure UI (ExpansionTile) for optional settings
  - Consistent slider patterns for discrete numeric values
  - Face ID/Touch ID authentication
  - Backup/restore functionality
  - Comprehensive automated test suite (113 tests, 100% passing)
  
- ✅ **Phases 0-6:** Complete
  - Foundation, data layer, cryptography, P2P, UX polish, dual-mode
  
- ✅ **Current:** Code review fixes and test infrastructure improvements
  - Database migration rollback safety
  - Enhanced simple supplier mode UX
  - Architectural review fixes implemented
  - iOS build stability improvements
  - Database test locking issues resolved

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
