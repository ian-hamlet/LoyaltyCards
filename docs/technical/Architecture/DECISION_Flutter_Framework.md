# Architecture Decision: Flutter as Mobile Framework

## Decision ID
ARCH-002

## Date
2026-03-30

## Status
✅ **ACCEPTED**

## Context

The LoyaltyCards application requires mobile applications for both customers and suppliers on iOS and Android platforms. We need to choose a mobile development framework that:
- Supports both iOS and Android from a single codebase
- Provides good QR code scanning capabilities
- Supports cryptographic operations for P2P security
- Has minimal learning curve for rapid prototyping
- Enables fast iteration and testing
- Has strong community support and libraries

## Decision

**We will use Flutter as the mobile development framework** for both customer and supplier applications.

## Rationale

### Why Flutter?

#### ✅ **Cross-Platform Efficiency**
- **Single codebase** for iOS and Android (REQ-003)
- Reduces development time by 50% vs native
- Consistent UI/UX across platforms
- Shared business logic and security code

#### ✅ **Excellent QR Code Support**
Required for REQ-009 (QR/Barcode Scanning):
- `qr_flutter` - Generate QR codes
- `mobile_scanner` - Fast, modern QR scanning
- `barcode_widget` - Barcode generation
- Well-maintained with good performance

#### ✅ **Strong Cryptography Libraries**
Required for REQ-020 (Security Requirements):
- `pointycastle` - Pure Dart crypto (ECDSA, RSA)
- `cryptography` - Modern crypto APIs
- `flutter_secure_storage` - Secure keychain/keystore access
- Native platform integration for hardware-backed keys

#### ✅ **Local Storage**
Required for REQ-015 (P2P Data Architecture):
- `sqflite` - SQLite database for local storage
- `hive` - Fast NoSQL alternative
- `shared_preferences` - Simple key-value storage
- Good performance on mobile devices

#### ✅ **Rapid Prototyping**
- Hot reload for instant UI changes
- Rich widget library
- Material Design and Cupertino (iOS) built-in
- Visual layout tools

#### ✅ **Cost-Effective**
Aligns with REQ-017 (Cost Minimization):
- Free and open-source
- No licensing fees
- Reduces development costs (single codebase)
- Large community = free resources

## Comparison with Alternatives

| Feature | Flutter | React Native | Native (iOS/Android) |
|---------|---------|--------------|---------------------|
| **Codebase** | Single (Dart) | Single (JavaScript) | Separate (Swift + Kotlin) |
| **Performance** | Near-native (compiled) | Good (JS bridge) | Native (best) |
| **QR Scanning** | Excellent libraries | Good libraries | Best (native APIs) |
| **Cryptography** | Good (`pointycastle`) | Good (`crypto`) | Best (native) |
| **Development Speed** | Fast | Fast | Slow (2x work) |
| **Learning Curve** | Medium (new language) | Low (JavaScript) | High (2 languages) |
| **Community** | Large, growing | Very large | Largest (separate) |
| **Hot Reload** | Yes | Yes | Limited |
| **Cost** | Free | Free | Free (but 2x dev time) |

### Why Not React Native?

React Native is also excellent, but Flutter edges ahead for this project:
- **Better performance** for QR scanning (compiled vs JS bridge)
- **More cohesive crypto** story (pure Dart implementation)
- **Simpler deployment** (fewer native module issues)
- **Better offline support** (no JS thread)

### Why Not Native?

Native development provides best performance but:
- **2x development time** (separate iOS and Android codebases)
- **2x maintenance burden**
- **Conflicts with REQ-017** (cost minimization)
- **Overkill** for this use case (Flutter performance is sufficient)

## Technical Stack

### Core Framework
- **Flutter SDK**: 3.19+ (latest stable)
- **Dart**: 3.3+
- **Target Platforms**: iOS 12+, Android 6.0+ (API 23+)

### Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # QR Code & Scanning
  qr_flutter: ^4.1.0              # Generate QR codes
  mobile_scanner: ^5.0.0          # Fast QR scanning
  
  # Cryptography
  pointycastle: ^3.7.3            # ECDSA signatures
  flutter_secure_storage: ^9.0.0 # Secure key storage
  crypto: ^3.0.3                  # Hashing (SHA-256)
  
  # Local Storage
  sqflite: ^2.3.0                 # SQLite database
  path_provider: ^2.1.0           # File system paths
  
  # State Management
  provider: ^6.1.0                # Simple state management
  
  # UI/UX
  cupertino_icons: ^1.0.6         # iOS-style icons
  google_fonts: ^6.1.0            # Custom fonts
  
  # Utilities
  uuid: ^4.3.0                    # Generate card GUIDs
  intl: ^0.19.0                   # Date/time formatting

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### Project Structure

```
loyalty_cards_flutter/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/                      # Data models
│   │   ├── card.dart                # Loyalty card model
│   │   ├── stamp.dart               # Stamp model
│   │   └── supplier.dart            # Supplier model
│   ├── services/                    # Business logic
│   │   ├── crypto_service.dart      # Cryptography
│   │   ├── database_service.dart    # SQLite operations
│   │   └── qr_service.dart          # QR generation/scanning
│   ├── screens/                     # UI screens
│   │   ├── customer/                # Customer app screens
│   │   │   ├── card_list.dart
│   │   │   ├── card_detail.dart
│   │   │   └── scan_supplier_qr.dart
│   │   └── supplier/                # Supplier app screens
│   │       ├── business_setup.dart
│   │       ├── stamp_card.dart
│   │       └── redeem_card.dart
│   ├── widgets/                     # Reusable widgets
│   │   ├── stamp_card_widget.dart
│   │   └── qr_display_widget.dart
│   └── utils/                       # Utilities
│       └── constants.dart
└── test/                            # Unit tests
```

## Implementation Phases

### Phase 1: Prototype/MVP (Current) 🎯
**Goal**: Test P2P interaction flows with mockups

- Basic Flutter project setup
- Mockup screens for key interactions:
  - Supplier onboarding
  - Customer card pickup
  - Stamp application
  - Redemption
- QR code generation (mockup data)
- QR code scanning (basic)
- Visual card design

**Deliverable**: Interactive prototype for UX validation
**Timeline**: 1-2 weeks

### Phase 2: Core Functionality
- Implement cryptographic signing/verification
- Implement local SQLite storage
- Complete P2P transaction flows
- Proper state management
- Error handling

**Timeline**: 3-4 weeks

### Phase 3: Polish & Testing
- Enhanced UI/UX
- Animations and feedback
- Comprehensive testing
- Performance optimization
- Accessibility

**Timeline**: 2-3 weeks

## Development Environment Setup

### Required Tools

1. **Flutter SDK**: [flutter.dev](https://flutter.dev)
2. **IDE**: VS Code (with Flutter extension) or Android Studio
3. **For iOS Development**:
   - macOS required
   - Xcode 14+
   - CocoaPods
4. **For Android Development**:
   - Android Studio
   - Android SDK
   - Java JDK 11+

### Testing Devices

- **Android**: Physical device or emulator (Android 6.0+)
- **iOS**: Physical device (requires Apple Developer account) or simulator

## Success Metrics

| Metric | Target | Notes |
|--------|--------|-------|
| **QR Scan Time** | <2 seconds | From camera open to decode |
| **Signature Speed** | <100ms | ECDSA sign/verify |
| **App Size** | <20MB | Download size (compressed) |
| **Startup Time** | <2 seconds | Cold start |
| **Frame Rate** | 60 FPS | UI smoothness |
| **Platform Support** | iOS 12+, Android 6+ | 95%+ device coverage |

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| **Learning curve (Dart)** | Use Flutter tutorials, prototyping phase for learning |
| **Camera permissions** | Clear permission requests, graceful handling |
| **Crypto performance** | Use `pointycastle`, profile on older devices |
| **QR scan reliability** | Use `mobile_scanner` (best performance), test in various lighting |
| **Platform-specific bugs** | Thorough testing on both iOS and Android |

## Alternatives Considered

### React Native
**Pros**: JavaScript ecosystem, large community, good libraries
**Cons**: JS bridge overhead, less cohesive crypto story, more native module issues
**Verdict**: Flutter provides better performance for QR scanning and crypto operations

### Native (Swift + Kotlin)
**Pros**: Best performance, full platform APIs, no framework overhead
**Cons**: 2x development time, 2x maintenance, conflicts with cost minimization
**Verdict**: Cross-platform framework more appropriate for this project scope

### Progressive Web App (PWA)
**Pros**: Web technologies, easy deployment, cross-platform
**Cons**: Limited camera access, no secure keystore, poor offline support, no P2P capabilities
**Verdict**: Not suitable for QR scanning and cryptographic requirements

## Related Documents

- [REQ-003: Mobile Platform Support](../../00-Planning/Requirements/REQ-003_Mobile_Platform_Support.md)
- [REQ-009: QR/Barcode Scanning](../../00-Planning/Requirements/REQ-009_QR_Barcode_Scanning.md)
- [REQ-015: Peer-to-Peer Data Architecture](../../00-Planning/Requirements/REQ-015_Backend_Data_Storage.md)
- [ARCH-001: P2P Architecture Decision](DECISION_P2P_Architecture.md)

## Approval

| Role | Name | Date | Status |
|------|------|------|--------|
| Tech Lead | [TBD] | 2026-03-30 | APPROVED |
| Mobile Developer | [TBD] | [Pending] | |

---

**Document Owner**: Development Team  
**Last Updated**: 2026-03-30  
**Next Review**: After Phase 1 prototype completion
