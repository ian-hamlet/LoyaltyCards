# LoyaltyCards Source Code

This directory contains the Phase 0+ implementation of the LoyaltyCards P2P system.

## Project Structure

```
03-Source/
├── shared/                     # Shared Dart package (v0.2.0)
│   ├── lib/
│   │   ├── models/            # Data models (Card, Stamp, Business, Transaction)
│   │   ├── utils/             # Crypto, logging utilities
│   │   ├── constants/         # App constants and branding
│   │   └── shared.dart        # Main export
│   └── test/                  # 115 unit tests
│       ├── models/            # Model tests
│       ├── fixtures/          # Test data fixtures
│       └── qr_tokens_test.dart
│
├── customer_app/              # Customer Flutter app (v0.2.0)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/customer/
│   │   └── services/          # Repositories, validators, rate limiting
│   ├── pubspec.yaml
│   └── test/                  # 33 unit tests
│       └── services/          # Service tests with mocking
│
├── supplier_app/              # Supplier Flutter app (v0.2.0)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/supplier/
│   │   └── services/          # Key management, signing, backups
│   ├── pubspec.yaml
│   └── test/                  # 17 unit tests (95%+ crypto coverage)
│       └── services/          # KeyManager tests
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

**All tests (165 total):**
```bash
# Shared package (115 tests)
cd shared && flutter test

# Customer app (33 tests)
cd customer_app && flutter test

# Supplier app (17 tests)
cd supplier_app && flutter test
```

**Test Coverage:**
- Shared models & QR tokens: 115 tests (80%+ coverage)
- Customer services: 33 tests (rate limiting, validation, crypto)
- Supplier KeyManager: 17 tests (95%+ coverage - security critical)

**See:** [TESTING_STRATEGY.md](../TESTING_STRATEGY.md) for comprehensive test plan

## Development Status

- ✅ **v0.2.0 (Build 21)** - Dual-mode system deployed to TestFlight
  - Secure mode: Full ECDSA cryptography with stamp chain validation
  - Simple mode: QR-based workflow without cryptography
  - Face ID/Touch ID authentication
  - Backup/restore functionality
  - Comprehensive automated test suite (165 tests)
  
- ✅ **Phases 0-6:** Complete
  - Foundation, data layer, cryptography, P2P, UX polish, dual-mode
  
- 🔄 **Current:** Retrospective testing implementation
  - Unit tests for all critical components
  - Integration test framework
  - CI/CD preparation

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
