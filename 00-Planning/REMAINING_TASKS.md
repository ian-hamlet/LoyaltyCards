# Remaining Tasks to Pilot Deployment

**Document:** Focused Task List  
**Created:** April 12, 2026  
**Updated:** April 13, 2026  
**Current Build:** v0.1.0 (Build 75)  
**Status:** Dual-Mode Complete - Ready for Device Testing

---

## 🎯 Critical Path to Pilot (Estimated: 5-7 days)

### Phase 7: Dual-Mode Device Testing & Validation
**Duration:** 2-3 days  
**Priority:** 🔥 CRITICAL  
**Status:** Ready to Start

**Note:** Build 75 includes complete dual-mode implementation. Both Simple Mode (trust-based) and Secure Mode (crypto-validated) need comprehensive testing.

#### Day 1: Initial Device Testing
- [ ] **Morning: Deploy & Setup**
  - [ ] Build and deploy Build 75 to iPhone (customer app)
  - [ ] Build and deploy Build 75 to iPad (supplier app)
  - [ ] Create test businesses on iPad:
    - [ ] "Simple Coffee Shop" (Simple Mode, 10 stamps)
    - [ ] "Secure Boutique" (Secure Mode, 10 stamps)
  
- [ ] **Afternoon: Simple Mode Testing (Trust-Based)**
  - [ ] **Scenario 1: Basic Simple Flow**
    - [ ] Issue card with 0 stamps
    - [ ] Customer scans reusable stamp QR 5 times
    - [ ] Verify: 5 stamps added, rate limiting working (1 sec cooldown)
    - [ ] Add 5 more stamps (total 10)
    - [ ] Customer self-redeems (scans redemption QR)
    - [ ] Verify: New card auto-created with 0 stamps
  
  - [ ] **Scenario 2: Simple Pre-loaded Cards**
    - [ ] Issue card with 3 initial stamps
    - [ ] Customer scans reusable stamp QR 7 times
    - [ ] Verify: Card reaches 10 stamps
    - [ ] Self-redeem
    - [ ] Verify: New card created
  
- [ ] **Evening: Secure Mode Testing (Crypto-Validated)**
  - [ ] **Scenario 3: Basic Secure Flow**
    - [ ] Issue card with 2 initial stamps
    - [ ] Supplier generates time-limited stamp QR (Add Stamp button)
    - [ ] Customer scans QR (adds 4 stamps)
    - [ ] Verify: Hash chain validates, 6 total stamps
    - [ ] Issue 6 more stamps (total 12, overflow)
    - [ ] Verify: 10 stamps on complete card, 2 on new card
    - [ ] Supplier redeems complete card (scans customer QR)
    - [ ] Verify: New card continues with 2 stamps
  
  - [ ] **Scenario 4: Secure Overflow**
    - [ ] Card at 8/10 stamps
    - [ ] Add 5 stamps
    - [ ] Verify: 10 go to original, 3 overflow to new card
    - [ ] Redeem original card
    - [ ] Verify: New card has 3 stamps, hash chain valid

#### Day 2: Cross-Mode & Edge Case Testing
- [ ] **Cross-Mode Testing**
  - [ ] Multiple businesses in wallet (mix of simple and secure)
  - [ ] Switch between simple and secure cards
  - [ ] Verify: Simple cards don't show statistics
  - [ ] Verify: Secure cards show validation stats
  - [ ] Test search with 5+ cards (different modes)
  - [ ] Delete simple mode card
  - [ ] Delete secure mode card
  
- [ ] **Simple Mode Edge Cases**
  - [ ] Card with exactly stampsRequired stamps (self-redeem)
  - [ ] Rapid scanning (rate limiting working)
  - [ ] Scan same QR code immediately (should block for 1 second)
  - [ ] App backgrounded during simple stamp scan
  
- [ ] **Secure Mode Edge Cases**
  - [ ] Expired QR code (wait 2 minutes, try to scan)
  - [ ] Invalid QR code (scan random QR)
  - [ ] Hash chain validation failure detection
  - [ ] Multiple stamp operations in sequence
  - [ ] Card one away from complete, add 1 stamp
  
- [ ] **Error Scenarios (Both Modes)**
  - [ ] Invalid QR code format
  - [ ] Camera in different orientations
  - [ ] Low light conditions
  - [ ] QR code at extreme angles
  - [ ] Multiple cards from same business

#### Day 3: UX, Performance & Dual-Mode Validation
- [ ] **Dual-Mode UX Testing**
  - [ ] Simple mode: Verify reusable QR workflow is intuitive
  - [ ] Simple mode: Redemption QR clearly labeled
  - [ ] Secure mode: Time-limited QR refresh working
  - [ ] Secure mode: Statistics display useful
  - [ ] Both modes: Stamp history accurate
  - [ ] Both modes: Auto-create after redemption working
  - [ ] Navigation between modes smooth
  
- [ ] **General UX Testing**
  - [ ] All haptic feedback feels appropriate
  - [ ] All AppFeedback messages are clear
  - [ ] "How It Works" screens are helpful
  - [ ] Dialog buttons always visible
  - [ ] Search is responsive
  - [ ] Skeleton loaders display correctly
  - [ ] Instruction banners visible and helpful
  
- [ ] **Performance Testing**
  - [ ] 1-hour continuous use (no crashes)
  - [ ] 20+ card operations across both modes
  - [ ] Battery drain assessment
  - [ ] Camera responsiveness
  - [ ] App launch time
  - [ ] Simple mode: No noticeable validation delay
  - [ ] Secure mode: Crypto validation < 100ms
  
- [ ] **Final Dual-Mode Checklist**
  - [ ] No crashes encountered (either mode)
  - [ ] No confusing UI elements
  - [ ] Simple mode workflow is fast and frictionless
  - [ ] Secure mode workflow is clear and validated
  - [ ] All features work as expected
  - [ ] Ready for TestFlight upload

---

### Phase 8: TestFlight Preparation
**Duration:** 2-3 days  
**Priority:** 🔥 CRITICAL (after device testing)  
**Status:** Pending

#### Day 4: Apple Developer Setup
- [ ] **Apple Developer Program**
  - [ ] Enroll in Apple Developer Program ($99/year)
  - [ ] Wait for approval (usually 24-48 hours)
  
- [ ] **While Waiting: App Icons**
  - [ ] Design or commission supplier app icon
  - [ ] Design or commission customer app icon
  - [ ] Create all required sizes (1024x1024, smaller variants)
  - [ ] Add to Xcode projects

#### Day 5: App Store Connect Configuration
- [ ] **Bundle IDs**
  - [ ] Register com.loyaltycards.supplier
  - [ ] Register com.loyaltycards.customer
  
- [ ] **Certificates & Profiles**
  - [ ] Create iOS Distribution certificate
  - [ ] Create App Store provisioning profiles
  - [ ] Download and install in Xcode
  
- [ ] **App Store Connect**
  - [ ] Create supplier app listing
  - [ ] Create customer app listing
  - [ ] Configure TestFlight settings

#### Day 6: Build Upload & Testing
- [ ] **Archive Builds**
  - [ ] Archive supplier app (Product > Archive)
  - [ ] Archive customer app (Product > Archive)
  
- [ ] **Upload to App Store Connect**
  - [ ] Upload supplier app via Organizer
  - [ ] Upload customer app via Organizer
  - [ ] Wait for processing (10-30 minutes each)
  
- [ ] **TestFlight Configuration**
  - [ ] Add test information (privacy policy, etc.)
  - [ ] Create internal testing group
  - [ ] Add yourself as internal tester
  - [ ] Test installation from TestFlight
  
- [ ] **External Testing Group**
  - [ ] Create "Pilot Businesses" group
  - [ ] Create "Pilot Customers" group
  - [ ] Add test instructions
  - [ ] Configure feedback email

#### Day 7: Pilot Preparation
- [ ] **Documentation**
  - [ ] Create supplier app quick start guide (1 page)
  - [ ] Create customer app quick start guide (1 page)
  - [ ] Create troubleshooting FAQ
  - [ ] Prepare feedback survey
  
- [ ] **Pilot Business Recruitment**
  - [ ] Identify 2-3 friendly businesses
  - [ ] Confirm participation
  - [ ] Schedule onboarding calls
  - [ ] Send TestFlight invitations
  
- [ ] **Pilot Customer Recruitment**
  - [ ] Recruit 10-20 test customers
  - [ ] Send TestFlight invitations
  - [ ] Set expectations for feedback

---

### Phase 9: Pilot Launch
**Duration:** 2-4 weeks (active monitoring)  
**Priority:** 🔥 CRITICAL  
**Status:** Pending

#### Week 1: Launch & Onboarding
- [ ] **Day 1: Business Onboarding**
  - [ ] Video call with each business
  - [ ] Walk through supplier app setup
  - [ ] Configure their business (name, colors, stamps)
  - [ ] Test card issuance
  - [ ] Verify they understand all features
  
- [ ] **Day 2-3: Customer Onboarding**
  - [ ] Send welcome email with instructions
  - [ ] Customers download customer app
  - [ ] Customers visit businesses to get cards
  - [ ] Monitor for issues via support email
  
- [ ] **Day 4-7: Active Monitoring**
  - [ ] Daily check-ins with businesses
  - [ ] Respond to customer questions
  - [ ] Track metrics (cards issued, stamps, redemptions)
  - [ ] Fix critical bugs if found

#### Week 2-4: Iteration & Feedback
- [ ] **Daily Tasks**
  - [ ] Monitor support email
  - [ ] Check TestFlight crash reports
  - [ ] Review user feedback
  
- [ ] **Weekly Tasks**
  - [ ] Survey businesses on experience
  - [ ] Survey customers on experience
  - [ ] Analyze usage metrics
  - [ ] Plan improvements for next build
  
- [ ] **End of Pilot Review**
  - [ ] Compile all feedback
  - [ ] Assess success metrics
  - [ ] Decide: proceed to production or iterate

---

## 📋 Optional Tasks (Can Defer)

### Phase 7: Multi-Device Configuration
**Priority:** LOW (defer to post-pilot)  
**Duration:** 1-2 days

Only implement if pilot businesses specifically request multi-device support.

- [ ] Configuration export screen
- [ ] QR generation for config transfer
- [ ] Configuration import screen
- [ ] Testing with 2 devices

**Decision:** Wait for pilot feedback. Most businesses likely use single device.

---

### Code Cleanup (Nice to Have)
**Priority:** MEDIUM  
**Duration:** 4-6 hours

Can be done before TestFlight upload:

- [ ] Wrap all `print()` statements in `if (kDebugMode) { }`
- [ ] Run `flutter analyze` and fix warnings
- [ ] Remove commented-out code
- [ ] Add final doc comments to complex functions
- [ ] Verify no TODOs remain (or mark as "Post-Pilot")

---

## 🎯 Success Metrics

### Device Testing (Phase 6)
- ✅ Zero crashes in 1-hour session
- ✅ 100% QR scan success rate
- ✅ All haptics feel natural
- ✅ All features work as designed
- ✅ Performance is smooth

### Pilot (Phase 9)
- ✅ < 5% QR scan failure rate
- ✅ Zero data loss
- ✅ 80%+ user satisfaction
- ✅ All redemptions process correctly
- ✅ Positive business feedback
- ✅ 10+ successful end-to-end transactions

---

## ⏱️ Timeline Summary

| Phase | Duration | Start | End |
|-------|----------|-------|-----|
| **Phase 6: Device Testing** | 2-3 days | Apr 13 | Apr 15 |
| **Phase 8: TestFlight Prep** | 2-3 days | Apr 16 | Apr 18 |
| **Phase 9: Pilot Launch** | 2-4 weeks | Apr 19 | May 16 |

**Total Time to Pilot:** ~1 week of dev work + 2-4 weeks pilot runtime

---

## 🚦 Current Blockers

**None.** Build 46 is complete and ready for device testing.

**Next Action:** Deploy to iPhone + iPad and begin Phase 6 testing.

---

## 📞 Questions to Answer

Before starting pilot:

1. **Which businesses?** (Need 2-3 commitments)
2. **Which customers?** (Need 10-20 volunteers)
3. **Support channel?** (Email? Slack? Phone?)
4. **Pilot duration?** (2 weeks minimum, 4 weeks ideal)
5. **Success criteria?** (What defines "ready for production"?)

---

**Status:** All development complete. Ready to test on physical devices.  
**Confidence:** HIGH - Build 46 represents polished, pilot-ready software.  
**Risk Level:** LOW - Only remaining risk is device testing reveals unforeseen issues.

---

Last Updated: April 12, 2026, 10:30 PM
