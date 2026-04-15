# Quick Reference - Defect Correction Workflow

**Version:** v0.2.0 → v0.2.1  
**Purpose:** Fast reference for logging and fixing defects

---

## 🚀 Quick Start

### Found a Bug During Testing?

**1. Open:** [DEFECT_TRACKER.md](DEFECT_TRACKER.md)

**2. Add defect under "🧪 TESTING DEFECTS" section:**

```markdown
### TEST-XXX: [Short Description]
- **Source:** Testing - iPhone/iPad/Both
- **Status:** 📋 BACKLOG
- **Priority:** CRITICAL/HIGH/MEDIUM/LOW
- **Screen/Feature:** [Where it happens]
- **Description:** [What's wrong]
- **Reproduction Steps:**
  1. Do this
  2. Then this
  3. Bug happens
- **Expected:** [What should happen]
- **Actual:** [What actually happens]
- **Fix Required:** [Ideas for fixing]
- **Estimated Effort:** [Time guess]
- **Target Build:** Build 5/6/etc
```

**3. Update statistics at bottom**

**4. Save and commit:** `git add DEFECT_TRACKER.md && git commit -m "test: Add TEST-XXX defect" && git push`

---

## 🔧 Ready to Fix Bugs?

### Phase 1: Critical Fixes (Build 5)

**Must fix before wider testing:**
- CR-001: Public key encoding (30 min)
- CR-002: Debug logging cleanup (1-2 hrs)
- CR-005: Remove TODO (15 min)
- + Any CRITICAL testing defects

**Commands:**
```bash
# Fix the bugs in code
cd /Users/ianhamlet/development/LoyaltyCards

# 1. Update version
# Edit: 03-Source/shared/lib/version.dart
# Change to: v0.2.1 (Build 5)

# 2. Update both app versions
# Edit: 03-Source/customer_app/pubspec.yaml
# Edit: 03-Source/supplier_app/pubspec.yaml
# Change to: version: 0.2.1+5

# 3. Build both IPAs
cd 03-Source/customer_app
flutter clean && flutter build ipa --release

cd ../supplier_app
flutter clean && flutter build ipa --release

# 4. Upload via Transporter
# Open Transporter app
# Drag IPAs from build/ios/ipa/ folders

# 5. Commit and deploy
git add .
git commit -m "fix: Build 5 - Critical bug fixes (CR-001, CR-002, CR-005)"
git push origin develop
```

---

## 📋 Defect Priority Guide

**🔴 CRITICAL** - Fix immediately (Build 5)
- App crashes
- Data loss
- Security vulnerability
- Core feature completely broken
- Blocks all testing

**🟠 HIGH** - Fix soon (Build 6-10)
- Feature partially broken
- Significant UX problem
- Affects many users
- No workaround exists

**🟡 MEDIUM** - Fix next update (Build 10+)
- Feature works but awkward
- Affects some users
- Workaround exists
- Cosmetic but noticeable

**🔵 LOW** - Fix eventually (v0.3.0)
- Enhancement request
- Very minor cosmetic issue
- Affects very few users
- No impact on functionality

---

## 📊 Current Status (Update Me!)

**Current Build:** v0.2.0 (Build 4)  
**Next Build:** v0.2.1 (Build 5)  
**Status:** Testing in progress

**Defects Logged:**
- 🔴 Critical: 2
- 🟠 High: 5
- 🟡 Medium: 4
- 🔵 Low: 4
- **Total:** 15

**Defects Fixed:** 0  
**Defects In Progress:** 0  
**Defects Remaining:** 15

---

## 🎯 Build 5 Checklist

Before deploying Build 5:

- [ ] All CRITICAL defects fixed
- [ ] Version updated to v0.2.1 (Build 5)
- [ ] Both pubspec.yaml updated to 0.2.1+5
- [ ] Customer app IPA built
- [ ] Supplier app IPA built
- [ ] Both IPAs uploaded to App Store Connect
- [ ] Both processed successfully
- [ ] DEFECT_TRACKER.md updated with fixed items
- [ ] Changes committed to develop
- [ ] Release notes added
- [ ] Testers notified

---

## 💡 Tips

**When Testing:**
- Test on BOTH iPhone AND iPad
- Take screenshots of bugs
- Note exact steps to reproduce
- Check if workaround exists

**When Fixing:**
- Fix one bug at a time
- Test the fix immediately
- Update DEFECT_TRACKER.md status
- Increment build number
- Commit with defect ID in message

**When Deploying:**
- ALWAYS use: `flutter build ipa --release`
- Upload via Transporter (not Xcode!)
- Test on device before marking as fixed
- Update all documentation

---

## 🔗 Key Files

- [DEFECT_TRACKER.md](DEFECT_TRACKER.md) - Full defect list
- [TESTFLIGHT_TESTING_GUIDE.md](TESTFLIGHT_TESTING_GUIDE.md) - Testing procedures
- [CODE_REVIEW_v0.2.0.md](CODE_REVIEW_v0.2.0.md) - Code review findings
- [03-Source/shared/lib/version.dart](03-Source/shared/lib/version.dart) - Version string
- [03-Source/customer_app/pubspec.yaml](03-Source/customer_app/pubspec.yaml) - Customer version
- [03-Source/supplier_app/pubspec.yaml](03-Source/supplier_app/pubspec.yaml) - Supplier version

---

**Keep this handy while testing and fixing!**
