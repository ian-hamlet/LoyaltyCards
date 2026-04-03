# LoyaltyCards Development Plan
## Two-App Implementation Roadmap

**Document Version:** 1.0  
**Created:** 2026-04-03  
**Status:** Active  
**Owner:** Development Team

---

## Executive Summary

This document outlines the complete development plan for the LoyaltyCards P2P loyalty card system, structured as two separate applications:
- **Customer App** - For consumers collecting stamps and earning rewards
- **Supplier App** - For businesses issuing cards and managing loyalty programs

**Total Estimated Timeline:** 14-22 working days  
**Target Platforms:** iOS (iPhone, iPad), macOS (development/testing)  
**Architecture:** Peer-to-peer with local storage, no backend required

---

## Project Architecture

### Application Structure

```
LoyaltyCards/
├── 03-Source/
│   ├── shared/                        # Shared Dart package (40% of code)
│   │   ├── lib/
│   │   │   ├── models/                # Card, Stamp, Transaction, Business
│   │   │   ├── database/              # SQLite schema and migrations
│   │   │   ├── crypto/                # Signature verification
│   │   │   ├── utils/                 # QR parsing, validation, formatters
│   │   │   ├── constants/             # Brand colors, app constants
│   │   │   └── widgets/               # Reusable UI components
│   │   └── pubspec.yaml
│   │
│   ├── customer_app/                  # Customer Flutter App
│   │   ├── lib/
│   │   │   ├── screens/               # Customer screens
│   │   │   │   ├── home/              # Wallet view
│   │   │   │   ├── add_card/          # Scan supplier QR
│   │   │   │   ├── card_detail/       # View card, show QR for stamping
│   │   │   │   └── history/           # Transaction history
│   │   │   ├── services/              # Database, storage
│   │   │   └── main.dart
│   │   └── pubspec.yaml
│   │
│   └── supplier_app/                  # Supplier Flutter App
│       ├── lib/
│       │   ├── screens/               # Supplier screens
│       │   │   ├── onboarding/        # Business setup
│       │   │   ├── home/              # Dashboard
│       │   │   ├── issue_card/        # Show QR for customer pickup
│       │   │   ├── stamp_card/        # Scan customer card, add stamp
│       │   │   ├── redeem/            # Scan completed card
│       │   │   └── settings/          # Clone configuration, manage
│       │   ├── services/              # Key management, signing
│       │   └── main.dart
│       └── pubspec.yaml
```

---

## Testing Environment

### Available Devices

| Device | Use Case | Testing Role |
|--------|----------|--------------|
| **MacBook** | Development | Primary dev environment, iOS Simulator |
| **iPhone** | Production Testing | Customer app testing, real-world scenarios |
| **iPad** | Production Testing | Supplier app testing (larger screen), multi-device |
| **iOS Simulator** | Rapid Testing | Quick iteration, UI testing |

### Testing Strategy Per Phase

**Development Loop:**
1. Code on MacBook
2. Test on iOS Simulator (fast iteration)
3. Deploy to iPhone (customer experience)
4. Deploy to iPad (supplier experience)
5. Test P2P interaction: iPhone ↔ iPad

**Device Roles:**
- **iPhone = Customer Device** (primary)
- **iPad = Supplier Device** (primary)
- **Simulator = Both** (quick testing)

---

## Development Phases

### **PHASE 0: Project Foundation** ⚙️
**Duration:** 1 day  
**Status:** ⬜ Not Started

#### Objectives
- Set up three-project structure (shared, customer, supplier)
- Create shared library with core models
- Establish development workflow
- Configure git repository structure

#### Tasks

| # | Task | Estimated Time | Status | Notes |
|---|------|----------------|--------|-------|
| 0.1 | Create `shared` package | 2 hours | ⬜ | Core data models |
| 0.2 | Define data models (Card, Stamp, Business, Transaction) | 2 hours | ⬜ | Dart classes with JSON serialization |
| 0.3 | Create `customer_app` Flutter project | 1 hour | ⬜ | Initialize with shared dependency |
| 0.4 | Create `supplier_app` Flutter project | 1 hour | ⬜ | Initialize with shared dependency |
| 0.5 | Set up constants (colors, strings, config) | 1 hour | ⬜ | Shared branding |
| 0.6 | Add dependencies (sqflite, crypto, mobile_scanner, qr_flutter) | 1 hour | ⬜ | pubspec.yaml for all projects |

#### Acceptance Criteria
- [ ] Three projects created and building successfully
- [ ] Shared package importable in both apps
- [ ] All dependencies resolved
- [ ] Basic data models defined
- [ ] Both apps run on iOS Simulator

#### Testing Checkpoint
- Run `customer_app` on iPhone Simulator → shows blank home screen
- Run `supplier_app` on iPhone Simulator → shows blank home screen
- Verify hot reload works in both apps

---

### **PHASE 1: Customer App - Data Foundation** 📱
**Duration:** 2-3 days  
**Status:** ⬜ Not Started  
**Focus:** Customer app with real data persistence

#### Objectives
- Implement SQLite database for cards and stamps
- Build repository pattern for data access
- Create customer home screen with card list
- Replace all mock data with database queries

#### Tasks

| # | Task | Estimated Time | Status | Notes |
|---|------|----------------|--------|-------|
| 1.1 | Design SQLite schema (cards, stamps, transactions tables) | 2 hours | ⬜ | Migration v1 |
| 1.2 | Implement database helper (initialization, migrations) | 3 hours | ⬜ | sqflite wrapper |
| 1.3 | Create CardRepository (CRUD operations) | 3 hours | ⬜ | Add, get, update, delete cards |
| 1.4 | Create StampRepository (add stamps, get by card) | 2 hours | ⬜ | Link to cards |
| 1.5 | Update CustomerHome to load from database | 2 hours | ⬜ | Remove mock data |
| 1.6 | Implement card detail screen (database-driven) | 3 hours | ⬜ | Show real stamp data |
| 1.7 | Add card deletion functionality | 1 hour | ⬜ | Swipe to delete |
| 1.8 | Add empty state handling | 1 hour | ⬜ | No cards yet message |

#### Database Schema

```sql
-- cards table
CREATE TABLE cards (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL,
  business_name TEXT NOT NULL,
  business_public_key TEXT NOT NULL,
  stamps_required INTEGER NOT NULL,
  stamps_collected INTEGER NOT NULL,
  brand_color TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- stamps table
CREATE TABLE stamps (
  id TEXT PRIMARY KEY,
  card_id TEXT NOT NULL,
  stamp_number INTEGER NOT NULL,
  timestamp INTEGER NOT NULL,
  signature TEXT NOT NULL,
  previous_hash TEXT,
  FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
);

-- transactions table
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  card_id TEXT NOT NULL,
  type TEXT NOT NULL, -- 'pickup', 'stamp', 'redemption'
  timestamp INTEGER NOT NULL,
  business_name TEXT NOT NULL,
  details TEXT,
  FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
);

-- app_settings table
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

#### Acceptance Criteria
- [ ] Database created on first app launch
- [ ] Cards persist between app restarts
- [ ] Can add cards programmatically (manual test data)
- [ ] Card list displays from database
- [ ] Card detail shows accurate stamp count
- [ ] Can delete cards (removes from database)
- [ ] Empty state shows when no cards

#### Testing Checkpoint

**On iPhone:**
1. Install customer app
2. Add test card via code (temporary button)
3. Force quit app
4. Reopen app → card still present ✓
5. Tap card → see detail screen ✓
6. Delete card → removed from list ✓

**On iPad:**
1. Install same build
2. Verify independent database (no cards initially)

---

### **PHASE 2: Supplier App - Crypto & Business Setup** 🔐
**Duration:** 3-4 days  
**Status:** ⬜ Not Started  
**Focus:** Supplier app with cryptographic key management

#### Objectives
- Implement ECDSA key generation and storage
- Build secure business onboarding flow
- Create supplier database structure
- Implement stamp signing mechanism

#### Tasks

| # | Task | Estimated Time | Status | Notes |
|---|------|----------------|--------|-------|
| 2.1 | Research Flutter crypto libraries (pointycastle) | 1 hour | ⬜ | Choose ECDSA implementation |
| 2.2 | Implement KeyManager service (generate, store, retrieve) | 4 hours | ⬜ | Use flutter_secure_storage |
| 2.3 | Build supplier onboarding screen (business name, stamps) | 3 hours | ⬜ | First-launch wizard |
| 2.4 | Implement business configuration storage | 2 hours | ⬜ | SQLite with encryption |
| 2.5 | Create StampSigner service (sign stamp tokens) | 4 hours | ⬜ | ECDSA signing |
| 2.6 | Build supplier home dashboard | 2 hours | ⬜ | Show business info, action buttons |
| 2.7 | Implement business settings screen | 2 hours | ⬜ | Edit name, view public key |
| 2.8 | Add signature verification tests | 2 hours | ⬜ | Unit tests for crypto |

#### Key Management Architecture

```dart
// Key Manager Service
class KeyManager {
  // Generate new ECDSA key pair (P-256)
  Future<KeyPair> generateKeyPair();
  
  // Store private key securely (keychain/keystore)
  Future<void> storePrivateKey(String businessId, PrivateKey key);
  
  // Retrieve private key (requires biometric/passcode)
  Future<PrivateKey> getPrivateKey(String businessId);
  
  // Sign data with private key
  Future<String> signData(String data, PrivateKey key);
  
  // Verify signature with public key
  static bool verifySignature(String data, String signature, PublicKey key);
}

// Stamp Signing
class StampSigner {
  Future<StampToken> createStamp({
    required String cardId,
    required int stampNumber,
    required String previousHash,
  }) async {
    final data = '$cardId:$stampNumber:$timestamp:$previousHash';
    final signature = await keyManager.signData(data);
    return StampToken(
      cardId: cardId,
      stampNumber: stampNumber,
      timestamp: timestamp,
      signature: signature,
      previousHash: previousHash,
    );
  }
}
```

#### Acceptance Criteria
- [ ] Supplier onboarding generates unique key pair
- [ ] Private key stored securely in device keychain
- [ ] Business configuration persists after app restart
- [ ] Can generate signed stamp tokens
- [ ] Signature can be verified with public key
- [ ] Supplier home shows business name and info
- [ ] All crypto operations < 100ms

#### Testing Checkpoint

**On iPad (Supplier Device):**
1. Install supplier app
2. Complete onboarding (business name: "Test Coffee")
3. Force quit app
4. Reopen → business info persists ✓
5. Generate test stamp signature
6. Verify signature with public key ✓
7. Test biometric auth prompt (if available)

**Unit Tests:**
```bash
cd supplier_app
flutter test test/services/key_manager_test.dart
flutter test test/services/stamp_signer_test.dart
```

---

### **PHASE 3: Customer App - QR Scanning & P2P** 📲
**Duration:** 2-3 days  
**Status:** ⬜ Not Started  
**Focus:** QR code scanning and card pickup

#### Objectives
- Implement card pickup via QR code scanning
- Build stamp validation logic
- Create redemption flow
- Test P2P data exchange between devices

#### Tasks

| # | Task | Estimated Time | Status | Notes |
|---|------|----------------|--------|-------|
| 3.1 | Build QR scanner screen (camera integration) | 2 hours | ⬜ | Use mobile_scanner |
| 3.2 | Implement QR token parser (validate format) | 2 hours | ⬜ | JSON parsing with validation |
| 3.3 | Create card pickup flow (scan supplier QR) | 3 hours | ⬜ | Add card from scanned data |
| 3.4 | Build "Show QR for Stamp" screen | 2 hours | ⬜ | Display customer card QR |
| 3.5 | Implement stamp validation (signature check) | 3 hours | ⬜ | ECDSA verification |
| 3.6 | Create stamp receiving flow (scan supplier stamp token) | 3 hours | ⬜ | Update card, add stamp |
| 3.7 | Build redemption QR display | 1 hour | ⬜ | Show completed card QR |
| 3.8 | Add rate limiting (1 stamp/hour per business) | 2 hours | ⬜ | Prevent rapid stamping |

#### QR Token Formats

```json
// Card Issuance Token (Supplier → Customer)
{
  "type": "card_issue",
  "businessId": "uuid-v4",
  "businessName": "Joe's Coffee",
  "publicKey": "base64-encoded-public-key",
  "stampsRequired": 7,
  "brandColor": "#8B4513",
  "issuedAt": 1712160000,
  "signature": "supplier-signature"
}

// Customer Card QR (Customer → Supplier for stamping)
{
  "type": "card_stamp_request",
  "cardId": "uuid-v4",
  "businessId": "uuid-v4",
  "currentStamps": 3,
  "publicKey": "business-public-key",
  "timestamp": 1712160000
}

// Stamp Token (Supplier → Customer)
{
  "type": "stamp_token",
  "cardId": "uuid-v4",
  "stampNumber": 4,
  "timestamp": 1712160000,
  "previousHash": "sha256-hash",
  "signature": "supplier-signature"
}

// Redemption Request (Customer → Supplier)
{
  "type": "redemption_request",
  "cardId": "uuid-v4",
  "businessId": "uuid-v4",
  "stampsCollected": 7,
  "allStamps": [...],
  "timestamp": 1712160000
}
```

#### Acceptance Criteria
- [ ] QR scanner opens camera successfully
- [ ] Can parse and validate card issuance tokens
- [ ] Invalid QR codes show error message
- [ ] Card added to wallet after scanning
- [ ] Can display customer card QR for stamping
- [ ] Stamp signature validation works correctly
- [ ] Invalid stamps rejected with error
- [ ] Rate limiting prevents duplicate stamps
- [ ] Redemption QR displays correctly

#### Testing Checkpoint

**P2P Test Scenario 1: Card Pickup**

*Device Setup:*
- iPad: Supplier app
- iPhone: Customer app

*Steps:*
1. iPad: Complete supplier onboarding → "Test Coffee", 7 stamps
2. iPad: Tap "Issue Card" → display QR code
3. iPhone: Tap "Add Card" → scan iPad QR code
4. iPhone: Card appears in wallet ✓
5. Verify: Business name = "Test Coffee", 0/7 stamps ✓

**P2P Test Scenario 2: Add Stamp**

*Steps:*
1. iPhone: Open "Test Coffee" card → tap "Get Stamp"
2. iPhone: Display customer card QR
3. iPad: Tap "Stamp Card" → scan iPhone QR
4. iPad: Confirm stamp → display stamp token QR
5. iPhone: Scan iPad stamp token QR
6. iPhone: Card updates to 1/7 stamps ✓
7. Verify: Stamp has valid signature ✓
8. Try immediately stamping again → rejected (rate limit) ✓

---

### **PHASE 4: Supplier App - QR Generation & Operations** 🏪
**Duration:** 2-3 days  
**Status:** ⬜ Not Started  
**Focus:** Supplier operations and QR generation

#### Objectives
- Build card issuance QR generation
- Implement stamp token creation
- Create redemption processing
- Complete supplier workflow

#### Tasks

| # | Task | Estimated Time | Status | Notes |
|---|------|----------------|--------|-------|
| 4.1 | Build "Issue Card" screen with QR generation | 2 hours | ⬜ | Generate card issuance token |
| 4.2 | Create "Stamp Card" scanner screen | 2 hours | ⬜ | Scan customer card QR |
| 4.3 | Implement stamp token generation | 3 hours | ⬜ | Sign and create QR |
| 4.4 | Build stamp confirmation screen | 2 hours | ⬜ | Display stamp token QR |
| 4.5 | Create "Redeem Card" scanner | 2 hours | ⬜ | Scan completed card |
| 4.6 | Implement redemption validation | 2 hours | ⬜ | Verify all stamps valid |
| 4.7 | Build redemption confirmation flow | 2 hours | ⬜ | Generate reset token |
| 4.8 | Add transaction logging (optional) | 2 hours | ⬜ | Local history tracking |

#### Supplier Workflows

```dart
// Issue Card Workflow
class IssueCardScreen extends StatelessWidget {
  // 1. Generate card issuance token
  CardIssueToken generateToken() {
    return CardIssueToken(
      type: 'card_issue',
      businessId: business.id,
      businessName: business.name,
      publicKey: business.publicKey,
      stampsRequired: business.stampsRequired,
      brandColor: business.brandColor,
      issuedAt: DateTime.now(),
      signature: signToken(...),
    );
  }
  
  // 2. Display as QR code
  // 3. Customer scans → card added to their wallet
}

// Stamp Card Workflow
class StampCardScreen extends StatefulWidget {
  // 1. Scan customer card QR
  // 2. Parse and validate card data
  // 3. Check rate limiting (optional)
  // 4. Generate stamp token
  StampToken generateStamp(customerCard) {
    final stamp = StampToken(
      cardId: customerCard.cardId,
      stampNumber: customerCard.currentStamps + 1,
      timestamp: DateTime.now(),
      previousHash: calculateHash(lastStamp),
      signature: signStampData(...),
    );
    return stamp;
  }
  // 5. Display stamp token QR
  // 6. Customer scans → stamp added to card
}
```

#### Acceptance Criteria
- [ ] Can generate card issuance QR codes
- [ ] QR codes are scannable and valid
- [ ] Can scan customer card QR codes
- [ ] Stamp token generation includes valid signature
- [ ] Stamp token hash chain is correct
- [ ] Can scan and validate completed cards
- [ ] Redemption validates all stamp signatures
- [ ] Redemption generates reset token
- [ ] All workflows complete end-to-end

#### Testing Checkpoint

**Full E2E Test: Complete Stamp Card Journey**

*Devices:*
- iPad: Supplier app (Test Coffee, 3 stamps required)
- iPhone: Customer app (Maria)

*Complete Flow:*
1. iPad: Issue card → QR displayed
2. iPhone: Scan QR → "Test Coffee" card added (0/3)
3. iPhone: Show card QR → iPad scans → stamp 1 → iPhone scans token → 1/3 ✓
4. Wait 1 hour (or override rate limit for testing)
5. Repeat stamp process → 2/3 ✓
6. Repeat stamp process → 3/3 (COMPLETE) ✓
7. iPhone: Show redemption QR
8. iPad: Scan redemption QR → validate all stamps → confirm
9. iPad: Show reset token QR
10. iPhone: Scan reset token → card resets to 0/3 ✓

**Success Criteria:** All steps complete without errors

---

### **PHASE 5: Multi-Device Configuration Cloning** 🔄
**Duration:** 1-2 days  
**Status:** ⬜ Not Started  
**Focus:** Supplier app configuration export/import

#### Objectives
- Enable configuration export to QR code
- Implement configuration import and validation
- Test multi-device supplier scenario

#### Tasks

| # | Task | Estimated Time | Status | Notes |
|---|------|----------------|--------|-------|
| 5.1 | Build configuration export screen | 2 hours | ⬜ | Serialize business + keys |
| 5.2 | Implement QR generation for config | 2 hours | ⬜ | May need chunked QR (large data) |
| 5.3 | Create configuration import screen | 2 hours | ⬜ | Scan and validate |
| 5.4 | Add import validation logic | 2 hours | ⬜ | Check schema, expiry, signature |
| 5.5 | Implement secure key import | 2 hours | ⬜ | Store in keychain |
| 5.6 | Add warning dialogs (security notices) | 1 hour | ⬜ | Treat like physical key |
| 5.7 | Test configuration expiry (24 hours) | 1 hour | ⬜ | Reject expired configs |

#### Configuration Export Format

```json
{
  "version": 1,
  "type": "supplier_config",
  "businessId": "uuid-v4",
  "businessName": "Joe's Coffee",
  "stampsRequired": 7,
  "brandColor": "#8B4513",
  "privateKey": "base64-encrypted-private-key",
  "publicKey": "base64-public-key",
  "exportedAt": 1712160000,
  "expiresAt": 1712246400,
  "signature": "export-signature"
}
```

#### Acceptance Criteria
- [ ] Can export configuration from supplier device
- [ ] Export QR code displays correctly
- [ ] Can import configuration on new device
- [ ] Import validates all fields correctly
- [ ] Expired configurations rejected
- [ ] Both devices can issue cards with same business ID
- [ ] Both devices can stamp cards interchangeably
- [ ] Warning shown about security implications

#### Testing Checkpoint

**Multi-Device Supplier Test**

*Devices:*
- iPad (Device A): Primary supplier device
- iPhone (Device B): Secondary supplier device
- iPhone Simulator: Customer device

*Scenario:*
1. iPad: Set up "Maria's Bakery" (5 stamps) → generates keys
2. iPad: Tap "Clone Configuration" → display export QR
3. iPhone: Fresh supplier app install → "Import Configuration"
4. iPhone: Scan iPad QR → imports successfully ✓
5. Verify: iPhone shows "Maria's Bakery" with same business ID ✓

6. iPad (Device A): Issue card → show QR
7. Simulator: Scan card from Device A → added to wallet (0/5)
8. Simulator: Show card QR for stamp
9. iPhone (Device B): Stamp card → generate stamp token
10. Simulator: Scan stamp token from Device B → card updates (1/5) ✓

**Success:** Card issued by Device A can be stamped by Device B

---

### **PHASE 6: Polish, Testing & Deployment Prep** 🚀
**Duration:** 3-4 days  
**Status:** ⬜ Not Started  
**Focus:** Production readiness

#### Objectives
- Add comprehensive error handling
- Implement loading states and feedback
- Create transaction history views
- Prepare for App Store submission
- Conduct thorough testing

#### Tasks

| # | Task | Estimated Time | Status | Notes |
|---|------|----------------|--------|-------|
| 6.1 | Add loading indicators for all async operations | 2 hours | ⬜ | Spinners, progress bars |
| 6.2 | Implement error handling (network, QR, crypto) | 3 hours | ⬜ | Show user-friendly errors |
| 6.3 | Add haptic feedback for key actions | 1 hour | ⬜ | Stamp added, card complete |
| 6.4 | Build transaction history screen (customer) | 3 hours | ⬜ | Show all pickups/stamps |
| 6.5 | Create app icons (customer + supplier) | 2 hours | ⬜ | 1024x1024 + all sizes |
| 6.6 | Add launch screens (splash) | 1 hour | ⬜ | Branded loading |
| 6.7 | Implement onboarding tutorial (optional) | 3 hours | ⬜ | First-time user guide |
| 6.8 | Write unit tests for critical logic | 4 hours | ⬜ | Crypto, validation, DB |
| 6.9 | Conduct integration testing | 4 hours | ⬜ | Full user journeys |
| 6.10 | Performance optimization | 2 hours | ⬜ | Database queries, UI |
| 6.11 | Accessibility audit (VoiceOver, scaling) | 2 hours | ⬜ | iOS accessibility |
| 6.12 | Create App Store listings (text, screenshots) | 3 hours | ⬜ | Both apps |
| 6.13 | Set up Apple Developer provisioning profiles | 2 hours | ⬜ | Code signing |
| 6.14 | Build ad-hoc distribution for testing | 1 hour | ⬜ | Install on personal devices |

#### Testing Checklist

**Customer App:**
```
Functional Tests:
□ Add multiple cards from different businesses
□ View card details and progress
□ Collect stamps from different suppliers
□ Complete card and redeem
□ Delete cards
□ View transaction history
□ Rate limiting prevents duplicate stamps
□ Invalid QR codes handled gracefully
□ App works offline
□ Data persists after restart

UI/UX Tests:
□ Empty state displays correctly
□ Loading indicators show during operations
□ Error messages are clear and helpful
□ Cards display with correct branding
□ Progress circles animate smoothly
□ Navigation flows intuitively
□ VoiceOver describes all elements
□ Text scales with system settings
```

**Supplier App:**
```
Functional Tests:
□ Complete onboarding and generate keys
□ Keys stored securely (require biometric)
□ Issue cards to multiple customers
□ Stamp cards from different customers
□ Validate and redeem completed cards
□ Export configuration
□ Import configuration on second device
□ Both devices issue/stamp interchangeably
□ Signatures verify correctly
□ App works offline

UI/UX Tests:
□ Onboarding wizard is clear
□ QR codes display large and scannable
□ Camera permissions handled gracefully
□ Success feedback after operations
□ Business info displays correctly
□ Configuration export warnings clear
□ VoiceOver support
```

**P2P Integration Tests:**
```
□ Card issued by iPad, stamped by iPhone simulator
□ Card issued by iPhone, stamped by iPad
□ Multi-device supplier (iPad + iPhone) both stamp same card
□ Rate limiting enforced across devices
□ Signature validation rejects tampered stamps
□ Redemption validates all stamps in chain
□ Hash chain integrity maintained
```

#### Acceptance Criteria
- [ ] All functional tests pass on both apps
- [ ] No crashes during normal operations
- [ ] Error states handled gracefully
- [ ] Performance meets requirements (< 3s QR scans)
- [ ] Both apps ready for TestFlight
- [ ] App Store listings prepared
- [ ] Documentation complete

#### Testing Checkpoint

**Final Integration Test: Three-Device Scenario**

*Devices:*
- iPad: Supplier Device 1 ("Coffee Shop", Register 1)
- iPhone: Supplier Device 2 ("Coffee Shop", Register 2) [cloned config]
- iPhone Simulator: Customer Device (Alex)

*Complete Business Day Simulation:*

**Morning:**
1. Alex visits shop, Register 1 (iPad) issues card
2. Alex buys coffee, Register 1 stamps card (1/5)

**Afternoon:**
3. Alex returns, Register 2 (iPhone) stamps card (2/5)
4. Different customer visits, Register 2 issues new card

**Next Day:**
5. Alex visits again, Register 1 stamps card (3/5)

**Week Later:**
6. Alex completes card: stamps 4, 5 from Register 2
7. Alex redeems at Register 1
8. New card issued for next round

**Validation:**
✓ All stamps from both devices validate correctly  
✓ Rate limiting works across registers  
✓ Customer experience is seamless  
✓ No errors or crashes  
✓ Transaction history shows all actions  

---

## Progress Tracking

### Phase Status Legend
- ⬜ Not Started
- 🟦 In Progress
- ✅ Complete
- ⚠️ Blocked
- ❌ Failed/Skipped

### Overall Progress

| Phase | Status | Start Date | End Date | Duration | Completion % |
|-------|--------|------------|----------|----------|--------------|
| Phase 0: Foundation | ⬜ | - | - | - | 0% |
| Phase 1: Customer Data | ⬜ | - | - | - | 0% |
| Phase 2: Supplier Crypto | ⬜ | - | - | - | 0% |
| Phase 3: Customer QR/P2P | ⬜ | - | - | - | 0% |
| Phase 4: Supplier Operations | ⬜ | - | - | - | 0% |
| Phase 5: Multi-Device | ⬜ | - | - | - | 0% |
| Phase 6: Polish & Deploy | ⬜ | - | - | - | 0% |
| **TOTAL PROJECT** | ⬜ | - | - | - | **0%** |

---

## Milestones

| Milestone | Target Date | Status | Deliverable |
|-----------|-------------|--------|-------------|
| M1: Projects Created | Day 1 | ⬜ | Shared lib + both apps building |
| M2: Customer App MVP | Day 4 | ⬜ | Cards persist, can add/view/delete |
| M3: Supplier Keys Working | Day 8 | ⬜ | Crypto signing operational |
| M4: P2P Exchange Working | Day 11 | ⬜ | iPhone ↔ iPad card issuance works |
| M5: Full Stamp Workflow | Day 13 | ⬜ | Complete pickup → stamp → redeem flow |
| M6: Multi-Device Ready | Day 15 | ⬜ | Config cloning tested |
| M7: Production Ready | Day 19 | ⬜ | Both apps polished, TestFlight ready |
| M8: App Store Submission | Day 22 | ⬜ | Submitted to Apple for review |

---

## Risk Register

| Risk | Probability | Impact | Mitigation Strategy |
|------|-------------|--------|---------------------|
| iOS provisioning issues | Medium | High | Set up early in Phase 6, use development certificates |
| Crypto library compatibility | Low | High | Test pointycastle in Phase 0, have backup library |
| QR code size limits | Medium | Medium | Use chunked QR or file export as backup |
| Rate limiting bypass | Low | Medium | Implement on customer side, add timestamp validation |
| Device keychain issues | Low | High | Test flutter_secure_storage early, document limitations |
| Camera permissions denied | Medium | Low | Provide clear instructions, graceful fallback |
| Signature validation performance | Low | Medium | Profile early, optimize if > 100ms |

---

## Dependencies & Prerequisites

### Required Before Starting
- [x] MacBook with Xcode installed
- [x] Flutter SDK 3.41+ installed
- [x] iOS Simulator configured
- [x] iPhone available for testing
- [x] iPad available for testing
- [ ] Apple Developer Account ($99/year) - **NEEDED FOR PHASE 6**
- [ ] Git repository set up
- [ ] Development environment ready

### Technical Dependencies
- Flutter: >= 3.19.0
- Dart: >= 3.3.0
- iOS: >= 13.0
- Xcode: >= 14.0

### Package Dependencies (to be added)
```yaml
dependencies:
  sqflite: ^2.3.0              # Local database
  path_provider: ^2.1.0        # File system access
  flutter_secure_storage: ^9.0.0  # Keychain/Keystore
  pointycastle: ^3.7.3         # Cryptography (ECDSA)
  mobile_scanner: ^5.0.0       # QR code scanning
  qr_flutter: ^4.1.0           # QR code generation
  crypto: ^3.0.3               # Hashing utilities
  uuid: ^4.3.0                 # UUID generation
  intl: ^0.19.0                # Date formatting
  google_fonts: ^6.1.0         # Typography
```

---

## Definition of Done

A phase is considered complete when:

1. **All tasks** in the phase are marked complete
2. **Acceptance criteria** are all checked off
3. **Testing checkpoint** passes on all target devices
4. **Code is committed** to git with clear commit messages
5. **No critical bugs** remaining
6. **Documentation updated** if needed
7. **Progress tracking** updated in this document

---

## Next Steps

### To Begin Development:

1. **Review this plan** - Understand all phases and dependencies
2. **Set up Apple Developer Account** - Required for Phase 6 deployment
3. **Update progress tracking** - Mark Phase 0 as "In Progress" when starting
4. **Start Phase 0** - Create project structure
5. **Daily updates** - Update task status and dates as you progress

### Daily Workflow:

1. **Morning:** Review current phase tasks
2. **Work:** Complete 2-3 tasks, test on devices
3. **Test:** Run checkpoint tests after each task
4. **Update:** Mark completed tasks, update progress %
5. **Commit:** Push code to git with clear messages
6. **Document:** Note any issues or changes in this plan

---

## Document Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2026-04-03 | 1.0 | Initial plan created | Development Team |

---

**This is a living document. Update it as the project progresses, requirements change, or blockers are identified.**
