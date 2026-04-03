# LoyaltyCards Source Code

This directory contains the Phase 0+ implementation of the LoyaltyCards P2P system.

## Project Structure

```
03-Source/
├── shared/                     # Shared Dart package (v0.0.1)
│   └── lib/
│       ├── models/            # Data models (Card, Stamp, Business, Transaction)
│       ├── constants/         # App constants and branding
│       └── shared.dart        # Main export
│
├── customer_app/              # Customer Flutter app (v0.1.0)
│   ├── lib/
│   │   ├── main.dart
│   │   └── screens/customer/
│   └── pubspec.yaml
│
├── supplier_app/              # Supplier Flutter app (v0.1.0)
│   ├── lib/
│   │   ├── main.dart
│   │   └── screens/supplier/
│   └── pubspec.yaml
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

## Development Status

- ✅ **Phase 0: Foundation** - Complete (2026-04-03)
  - Three-project structure established
  - Shared models and constants defined
  - Both apps compile and ready to run
  
- ⬜ **Phase 1: Customer Data** - Not Started
  - Next: Implement SQLite database
  - Goal: Replace mock data with persistence

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
