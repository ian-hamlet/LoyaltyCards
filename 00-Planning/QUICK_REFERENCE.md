# LoyaltyCards - Quick Reference Guide

**Version:** 1.0 | **Updated:** 2026-04-12 | **Build:** 40

---

## 📱 Project Overview

**Two Mobile Apps:**
1. **LoyaltyCards** (Customer App) - For consumers collecting stamps
2. **LoyaltyCards Business** (Supplier App) - For businesses issuing cards

**Architecture:** Peer-to-peer, no backend, cryptographically signed transactions  
**Platform:** iOS (iPhone, iPad), Flutter/Dart  
**Timeline:** 14-22 working days

---

## 🎯 Testing Setup

| Device | Primary Role | Testing Use |
|--------|--------------|-------------|
| MacBook | Development | Coding, iOS Simulator |
| iPhone | Customer Device | Primary customer app testing |
| iPad | Supplier Device | Primary supplier app testing |
| Simulator | Both | Quick iteration testing |

**P2P Testing:** iPhone (customer) ↔ iPad (supplier)

---

## 📊 Development Phases

| Phase | Duration | Focus | Status |
|-------|----------|-------|--------|
| **0: Foundation** | 1 day | Project structure, shared library | ✅ Complete (2026-04-03) |
| **1: Customer Data** | 2-3 days | SQLite, repositories, persistence | ✅ Complete (2026-04-03) |
| **2: Supplier Crypto** | 3-4 days | Key generation, signing, security | ✅ Complete (2026-04-03) |
| **3: Customer QR/P2P** | 2-3 days | QR scanning, P2P exchange | ✅ Complete (2026-04-11) |
| **4: Supplier Ops** | 2-3 days | Card issuance, stamping, redemption | ✅ Complete (2026-04-11) |
| **5: Multi-Device** | 1-2 days | Config cloning, device support | ⬜ Not Started |
| **6: Polish** | 3-4 days | UI/UX, testing, deployment prep | ⬜ Not Started |

**Current Phase:** ✅ Phases 0-4 Complete + Additional Features - Ready for Pilot Testing  
**Total Time Spent:** ~30 hours  
**Automated Tests:** 17/17 passing ✅

---

## ✅ Quick Start Checklist

### Before You Begin
- [x] MacBook with Xcode installed
- [x] Flutter SDK 3.41+ installed
- [x] iOS Simulator working
- [x] iPhone available
- [x] iPad available
- [ ] **Apple Developer Account** ($99/year) - **NEEDED FOR PHASE 6**
- [ ] Git repository initialized

### Phase 0 Tasks (Day 1) ✅ COMPLETE
```bash
# All Phase 0 tasks completed on 2026-04-03
# See PHASE_0_COMPLETION.md for details

# Projects created:
# - /03-Source/shared/           (Shared library)
# - /03-Source/customer_app/     (Customer Flutter app)
# - /03-Source/supplier_app/     (Supplier Flutter app)

# To run apps:
cd ~/development/LoyaltyCards/03-Source/customer_app
flutter run

cd ~/development/LoyaltyCards/03-Source/supplier_app
flutter run
```

---

## 🔑 Key Workflows to Implement

### Customer Journey
1. **Scan Supplier QR** → Card Added
2. **Show Card QR** → Supplier Scans → Stamp Added
3. **Collect All Stamps** → Card Complete
4. **Show Redemption QR** → Supplier Scans → Reward + Reset

### Supplier Journey
1. **Complete Onboarding** → Generate Keys
2. **Show Issue Card QR** → Customer Scans
3. **Scan Customer Card** → Generate Stamp Token → Customer Scans
4. **Scan Completed Card** → Validate → Redeem

### Multi-Device
- **Export Config QR** (Device A) → Scan on Device B → Both Operational

---

## 📝 Daily Workflow

**Morning:**
1. Review current phase in [PROJECT_DEVELOPMENT_PLAN.md](PROJECT_DEVELOPMENT_PLAN.md)
2. Check tasks for today
3. Update [DAILY_PROGRESS_LOG.md](DAILY_PROGRESS_LOG.md) with date

**During Work:**
1. Complete 2-3 tasks
2. Test on iOS Simulator after each task
3. Test on iPhone/iPad at checkpoints
4. Mark tasks as complete in progress log

**End of Day:**
1. Update daily progress log
2. Commit code to git
3. Note any blockers or issues
4. Review tomorrow's tasks

---

## 🧪 Testing Checkpoints

### Phase 0 Checkpoint (Foundation) ✅ COMPLETE
```
✅ Created shared package
✅ Created customer app
✅ Created supplier app
✅ Both apps build and run
✅ Dependencies installed
```

### Phase 1 Checkpoint (Customer Data) ✅ COMPLETE
```
✅ Install customer app on iPhone Simulator
✅ Add test card (via code)
✅ Force quit app
✅ Reopen → card still present
✅ Delete card → removed from list
```

### Phase 2 Checkpoint (Supplier Crypto) ✅ COMPLETE
```
✅ Complete supplier onboarding
✅ Keys generated and stored
✅ Business config persists
✅ Signature creation working
✅ Signature verification working
```

### Phase 3 Checkpoint (P2P) ✅ COMPLETE
```
✅ iPad: Show card issue QR
✅ iPhone: Scan → card added
✅ iPhone: Show card QR
✅ iPad: Scan → generate stamp
✅ iPhone: Scan stamp → card updates
✅ Multi-stamp operations (1-7 stamps per scan)
✅ Overflow-to-new-card logic
```

### Phase 4 Checkpoint (Full E2E) ✅ COMPLETE
```
✅ Complete full stamp journey (0/10 → 10/10)
✅ Redeem completed card
✅ Cryptographically signed redemption
✅ Manual camera rotation controls
✅ Business logo selection
```

### Additional Features Checkpoint ✅ COMPLETE
```
✅ Landscape-optimized QR layouts
✅ Expandable instructions with visual badges
✅ Actual expiry times on all screens
✅ Compact card visuals for mobile screens
✅ Redemption analytics tracking
```

### Phase 5 Checkpoint (Multi-Device) ⬜ PENDING
```
□ iPad: Export config QR
□ iPhone: Import config
□ Simulator: Get card from iPad, stamp from iPhone
```

---

## 📦 Key Dependencies

```yaml
dependencies:
  sqflite: ^2.3.0                    # Database
  flutter_secure_storage: ^9.0.0      # Keychain
  pointycastle: ^3.7.3                # Crypto
  mobile_scanner: ^5.0.0              # QR scanning
  qr_flutter: ^4.1.0                  # QR generation
  crypto: ^3.0.3                      # Hashing
  uuid: ^4.3.0                        # IDs
```

---

## 🎯 Milestones

| Milestone | Target | Deliverable | Status |
|-----------|--------|-------------|--------|
| M1 | Day 1 | Projects created and building | ✅ Complete (2026-04-03) |
| M2 | Day 4 | Customer app persists data | ✅ Complete (2026-04-03) |
| M3 | Day 8 | Supplier crypto signing works | ✅ Complete (2026-04-03) |
| M4 | Day 11 | P2P exchange functional | ✅ Complete (2026-04-11) |
| M5 | Day 13 | Full stamp workflow complete | ✅ Complete (2026-04-11) |
| M6 | Day 15 | Multi-device tested | ⬜ Pending |
| M7 | Day 19 | Production ready | 🟦 In Progress (Pilot) |
| M8 | Day 22 | App Store submitted | ⬜ Pending |

**Note:** Milestones M1-M5 completed ahead of schedule. Build 40 ready for iPad pilot testing.

---

## 🆘 Common Issues & Solutions

**Issue:** Flutter not found  
**Fix:** Check PATH, restart terminal, verify `flutter doctor`

**Issue:** iOS simulator not launching  
**Fix:** `open -a Simulator`, check Xcode installation

**Issue:** Camera permissions denied  
**Fix:** Add NSCameraUsageDescription to Info.plist

**Issue:** Keychain access fails  
**Fix:** Enable device passcode/biometric, check entitlements

**Issue:** QR code too large  
**Fix:** Use chunked QR or file export fallback

**Issue:** Signature verification fails  
**Fix:** Check key format, verify ECDSA implementation

---

## 📚 Key Documents

| Document | Purpose |
|----------|---------|
| [PROJECT_DEVELOPMENT_PLAN.md](PROJECT_DEVELOPMENT_PLAN.md) | Complete phase-by-phase plan |
| [TEST_COMPLETION_REPORT.md](TEST_COMPLETION_REPORT.md) | Testing status and results |
| [DAILY_PROGRESS_LOG.md](DAILY_PROGRESS_LOG.md) | Daily work tracking |
| [PHASE_0_COMPLETION.md](PHASE_0_COMPLETION.md) | Phase 0 summary |
| [PHASE_1_COMPLETION.md](PHASE_1_COMPLETION.md) | Phase 1 summary |
| [PHASE_2_COMPLETION.md](PHASE_2_COMPLETION.md) | Phase 2 summary |
| [PROJECT_METADATA.md](../PROJECT_METADATA.md) | Project overview |
| [Requirements README](Requirements/README.md) | All 21 requirements |
| [REQ-021](Requirements/REQ-021_Multi_Device_Supplier_Support.md) | Multi-device feature |

---

## 🚀 Quick Commands

```bash
# Start Phase 0
cd ~/development/LoyaltyCards/03-Source
# Create projects (see checklist above)

# Run customer app on simulator
cd customer_app
flutter run

# Run supplier app on iPad
cd supplier_app
flutter run -d [iPad-device-id]

# Get device list
flutter devices

# Run tests
flutter test

# Check for issues
flutter doctor
```

---

## 📞 Need Help?

1. **Check the detailed plan:** [PROJECT_DEVELOPMENT_PLAN.md](PROJECT_DEVELOPMENT_PLAN.md)
2. **Review requirements:** [Requirements/](Requirements/)
3. **Consult architecture docs:** [../../01-Design/Architecture/](../../01-Design/Architecture/)
4. **Flutter issues:** `flutter doctor -v`

---

## 🎯 Next Actions (Priority Order)

### Immediate (This Week)
1. **Pilot Testing on iPads** - Test Build 40 in landscape mode on physical iPad devices
   - Validate QR scanning workflow end-to-end
   - Verify camera rotation controls work as expected
   - Test business logo selection and display
   - Confirm all expiry times display correctly
   - Check card visual fits on various screen sizes

2. **Performance Monitoring** - Track operation times during pilot
   - QR generation speed
   - Signature verification speed
   - Camera startup time
   - Overall UX responsiveness

### Short Term (Next 1-2 Weeks)
3. **Phase 5: Multi-Device Configuration**
   - Export business configuration to QR
   - Import configuration from QR on second device
   - Test multiple iPads with same business config

4. **Debug Log Cleanup**
   - Remove verbose console logs from production code
   - Keep error logging only
   - Reduce app size

### Medium Term (2-4 Weeks)
5. **Phase 6: Production Polish**
   - App icon design
   - Launch screen design
   - App Store listing preparation
   - Privacy policy and terms of service
   - TestFlight beta testing

6. **Additional Enhancements** (if time permits)
   - Push notifications for completed cards
   - Transaction history export
   - Analytics dashboard improvements
   - Accessibility improvements

---

## 📝 Current Build Features (Build 40)

**Core Functionality:**
- ✅ Multi-stamp card issuance (0-7 initial stamps)
- ✅ Multi-stamp operations (1-7 stamps per scan)
- ✅ Overflow-to-new-card logic
- ✅ Cryptographically signed stamps and redemptions
- ✅ Hash chain validation
- ✅ Redemption tracking and analytics

**UX Features:**
- ✅ Business logo selection (20 icons, 12 in UI)
- ✅ Manual camera rotation controls (90° and 180°)
- ✅ Landscape-optimized QR layouts (both apps)
- ✅ Expandable instructions with visual badges
- ✅ Actual expiry times ("expires 14:35" format)
- ✅ Compact card visuals for mobile screens
- ✅ Version display in UI (Build tracking)

**Technical:**
- ✅ Database v3 with logo support
- ✅ ECDSA P-256 cryptographic signatures
- ✅ < 100ms operation performance
- ✅ Secure storage for private keys
- ✅ SQLite persistence for all data

---

**Next Step:** Deploy Build 40 to iPads and begin pilot testing in landscape mode! 🎉

**Remember:** Update progress tracking daily, test frequently, commit often.
