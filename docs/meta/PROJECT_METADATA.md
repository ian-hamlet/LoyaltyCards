# Project Metadata

## Project Information
- **Working Name**: LoyaltyCards
- **Project Type**: Mobile Application Development (Two-App System)
- **Status**: v0.2.0 in TestFlight - Build 21
- **Created**: 2026-03-30
- **Last Updated**: 2026-04-18
- **Repository**: GitHub (ian-hamlet/LoyaltyCards)

## Development Approach
- **Methodology**: AI-Driven Development
- **Primary Tools**: GitHub Copilot, AI Assistants
- **Version Control**: Git/GitHub
- **Testing**: Automated unit tests (165 tests, 100% passing)

## Key Stakeholders
Pilot testing with select businesses

## Project Timeline

**Actual Progress (as of 2026-04-18):**
- ✅ **Phase 0:** Project Foundation (1 day) - Complete
- ✅ **Phase 1:** Customer App - Data Layer (2 days) - Complete
- ✅ **Phase 2:** Supplier App - Crypto & Security (3 days) - Complete
- ✅ **Phase 3:** Customer App - QR & P2P (2 days) - Complete
- ✅ **Phase 4:** Supplier App - Operations (2 days) - Complete
- ✅ **Phase 5:** UX Polish (2 days) - Complete
- ✅ **Phase 6:** Dual-Mode System (1 day) - Complete
- ✅ **Phase 7:** Retrospective Testing (1 day) - Complete
- 🔄 **Phase 8-10:** Final deployment preparation

**Total Duration:** 14 days (matching original estimate)

**Detailed Plan**: See [PROJECT_DEVELOPMENT_PLAN.md](00-Planning/PROJECT_DEVELOPMENT_PLAN.md)

## Technology Stack

### Confirmed Technologies
- **Framework**: Flutter 3.3.0+ (Dart) - Cross-platform mobile development
- **Architecture**: Peer-to-peer (P2P) with local storage, no backend required
- **Database**: SQLite (local device storage)
- **Cryptography**: ECDSA P-256 (pointycastle library)
- **Data Exchange**: QR codes (primary), NFC (future enhancement)
- **Secure Storage**: iOS Keychain / Android KeyStore (via flutter_secure_storage)
- **Platforms**: iOS (iPhone, iPad), Android (future)
- **Testing**: flutter_test, mockito, build_runner

### Key Dependencies
```yaml
# Production
sqflite: ^2.3.0              # Local database
flutter_secure_storage: ^9.2.2  # Secure key storage
pointycastle: ^4.0.0         # Cryptography (updated)
mobile_scanner: ^5.2.3       # QR scanning (updated)
qr_flutter: ^4.1.0           # QR generation
crypto: ^3.0.3               # Hashing
uuid: ^4.3.0                 # ID generation
local_auth: ^2.3.0           # Biometric authentication

# Testing
mockito: ^5.4.0              # Mocking framework
build_runner: ^2.4.0         # Code generation
test: ^1.24.0                # Testing framework
sqflite_common_ffi: ^2.3.0   # Desktop testing
```

### Development Environment
- **Primary**: macOS with Xcode 26.3
- **Flutter SDK**: 3.41.6
- **Dart**: 3.11.4
- **iOS Target**: 13.0+
- **Testing Devices**: iPhone, iPad, iOS Simulator

## Naming Strategy

### Application Names
- **Customer App**: LoyaltyCards
  - *Bundle ID*: com.loyaltycards.customer
  - *Tagline*: "Collect stamps, earn rewards"
  - *Target*: General consumers

- **Supplier App**: LoyaltyCards Business
  - *Bundle ID*: com.loyaltycards.supplier
  - *Tagline*: "Your digital loyalty program"
  - *Target*: Business owners and staff

### Branding
- Primary brand colors, logos, and visual identity to be defined
- Separate app store listings for each app

## Project Goals

### Primary Objectives
1. Create a **peer-to-peer digital loyalty card system** with zero backend costs
2. Enable **small businesses** to run loyalty programs without technical complexity
3. Provide **fast, secure stamp collection** through cryptographic signatures
4. Support **multi-device supplier operations** through configuration cloning
5. Maintain **maximum privacy** with minimal personal data collection

### Key Features
- Digital stamp cards replacing physical punch cards
- QR code-based peer-to-peer data exchange
- Cryptographically signed stamps (fraud prevention)
- Offline-first operation (no internet required)
- Multi-device business support (multiple registers/tablets)
- Zero entry card issuance (scan and go)

### Target Users
- **Customers**: Consumers who visit local businesses (coffee shops, restaurants, retail)
- **Suppliers**: Small business owners and staff managing loyalty programs

## Success Criteria

### Technical Success
- [ ] Both apps build and run on iOS devices
- [ ] P2P data exchange works reliably between devices
- [ ] Cryptographic signatures prevent stamp forgery
- [ ] Database persists data correctly across app restarts
- [ ] Multi-device configuration cloning functions
- [ ] All critical bugs resolved before launch

### User Experience Success
- [ ] Card pickup completes in < 10 seconds
- [ ] Stamp transaction completes in < 5 seconds
- [ ] UI is intuitive (no training required)
- [ ] Error messages are clear and actionable
- [ ] Apps work reliably offline

### Business Success
- [ ] Both apps submitted to Apple App Store
- [ ] TestFlight beta testing with 5+ users
- [ ] Positive feedback from initial users
- [ ] System scales to 10+ devices per business
- [ ] Zero operational costs (no backend infrastructure)

### Compliance Success
- [ ] GDPR compliant (minimal data collection)
- [ ] iOS security guidelines followed
- [ ] Cryptographic implementation secure
- [ ] User privacy maintained (P2P architecture)

## Key Documents

### Planning & Requirements
- [Requirements Index](00-Planning/Requirements/README.md) - 21 requirements documented
- [Development Plan](00-Planning/PROJECT_DEVELOPMENT_PLAN.md) - Detailed implementation roadmap
- [Requirements Discovery](00-Planning/Requirements/00-REQUIREMENTS_DISCOVERY.md) - Original discovery document

### Architecture & Design
- [Architecture Decisions](01-Design/Architecture/ARCHITECTURE_DECISIONS.md)
- [Flutter Framework Decision](01-Design/Architecture/DECISION_Flutter_Framework.md)
- [P2P Architecture Decision](01-Design/Architecture/DECISION_P2P_Architecture.md)

### Implementation
- [Flutter Setup Guide](03-Source/FLUTTER_SETUP_GUIDE.md)
- [Quick Start Guide](03-Source/QUICK_START.md)
- [Prototype README](03-Source/loyalty_cards_prototype/README.md)

---

**Last Updated**: 2026-04-03  
**Next Milestone**: Complete Phase 0 - Project Foundation (Day 1)
