# Rollback Procedures

**LoyaltyCards v0.2.0**  
**Purpose:** Emergency procedures for reverting problematic releases  
**Last Updated:** April 18, 2026

---

## Overview

This document provides step-by-step procedures for rolling back LoyaltyCards applications when a critical issue is discovered after deployment to TestFlight or App Store. Given the P2P architecture with local data storage, rollback procedures must consider both app version and data schema compatibility.

---

## Quick Reference

| Scenario | Severity | Action | Timeline | User Impact |
|----------|----------|--------|----------|-------------|
| TestFlight crash | CRITICAL | Rollback TestFlight | 1 hour | Beta testers only |
| App Store crash | CRITICAL | Emergency hotfix | 24-48 hours | All users |
| Data corruption | CRITICAL | Rollback + migration | 24-48 hours | High |
| Security breach | CRITICAL | Emergency hotfix | Immediate | Critical |
| UI bug | MEDIUM | Fix in next release | 1-2 weeks | Low |
| Feature regression | MEDIUM | Rollback or hotfix | 24-48 hours | Medium |

---

## Rollback Decision Matrix

### When to Rollback

✅ **Rollback Immediately:**
- App crashes on launch for >50% of users
- Data loss or corruption affecting user cards/stamps
- Security vulnerability actively being exploited
- Critical functionality broken (QR scanning, card issuance)
- Database migration failed causing data loss

⚠️ **Rollback Recommended:**
- Feature completely non-functional
- Severe UX degradation (app unusable but doesn't crash)
- Database migration issues affecting <10% of users
- Privacy policy violation

❌ **Do NOT Rollback (Fix Forward Instead):**
- Minor UI bugs
- Cosmetic issues
- Non-critical features broken
- Performance degradation <30%
- Issues affecting <5% of users

---

## TestFlight Rollback Procedures

### Scenario 1: Critical Bug in Current TestFlight Build

**Example:** Build 21 deployed to TestFlight, crashes on card issuance

#### Immediate Actions (0-15 minutes)

1. **Stop TestFlight Distribution**
   ```
   - Log into App Store Connect
   - Navigate to TestFlight → Builds
   - Locate problematic build (Build 21)
   - Click "Expire Build" or disable distribution
   ```

2. **Notify Beta Testers**
   ```
   - TestFlight → "What to Test" section
   - Update message:
     "⚠️ Build 21 has a critical issue. Please do not update if you're still on Build 20. 
     We're working on a fix and will release Build 22 shortly."
   ```

3. **Assess Impact**
   - Check TestFlight crash reports
   - Review tester feedback
   - Determine if data was corrupted

#### Rollback Actions (15-60 minutes)

4. **Re-enable Previous Build**
   ```
   - TestFlight → Builds
   - Locate last stable build (Build 20)
   - Enable for testing
   - Update "What to Test" message:
     "Build 21 has been rolled back due to critical issues. 
     Please install Build 20 (known stable). Apologies for the inconvenience."
   ```

5. **Verify Previous Build**
   - Install Build 20 on test device
   - Verify critical flows work:
     - Card issuance
     - Stamp collection
     - Redemption
     - Database migration (if applicable)

#### Data Recovery (If Needed)

6. **Assess Data Damage**
   - If Build 21 corrupted database:
     - Customer app: Cards/stamps may be lost
     - Supplier app: Business config may be lost
   
7. **Recovery Options**
   - **Customer App:** Limited recovery (no cloud backup)
     - Users may need to request card re-issuance from suppliers
     - Transaction history lost
   - **Supplier App:** Recovery possible
     - Private keys in iOS Keychain (survives app uninstall)
     - Recreate business config with same keys
     - Historical analytics data lost

---

### Scenario 2: Database Migration Failure

**Example:** Build 21 migration v5 → v6 fails for some users

#### Detection
- Crash reports show SQLite errors
- Users report "Database error" messages
- Logs show migration exceptions

#### Immediate Response

1. **Assess Migration Failure Rate**
   - Check crash reports: How many users affected?
   - <5% of users: Fix forward with Build 22
   - >10% of users: Rollback to Build 20

2. **If Rollback Required:**
   ```
   Problem: Database v6 schema incompatible with Build 20 (expects v5)
   
   Solution: Cannot rollback database schema automatically
   
   User Impact: Users who upgraded to Build 21 cannot downgrade to Build 20 
                without losing data
   ```

3. **Mitigation Strategy:**
   - Release hotfix Build 22 with corrected migration
   - Build 22 includes migration v6 → v6 (idempotent)
   - Users stuck on failed v6 can upgrade to Build 22

#### Prevention
- Always test database migrations on fresh installs AND upgrades
- Include migration logging
- Test migration failure scenarios in development

---

## App Store Rollback Procedures

### Important Limitations

⚠️ **You cannot rollback an App Store release**

Once live, an App Store version cannot be replaced with an older version. Options:

1. **Remove from sale** (stops new downloads, existing users keep problematic version)
2. **Emergency hotfix** (submit new build with fix, expedited review)
3. **Version increment** (release new version fixing the issue)

### Scenario 3: Critical Bug After App Store Release

**Example:** v0.2.0 Build 21 released to App Store, crashes on iOS 13 devices

#### Hour 0-1: Assessment & Emergency Response

1. **Assess Severity**
   - Check App Store crash reports
   - Monitor support requests
   - Determine affected user percentage
   - Identify iOS version, device models, or conditions

2. **Decision: Remove from Sale?**
   - If crash rate >50%: **YES, remove immediately**
   - If security breach: **YES, remove immediately**
   - If data loss: **YES, remove immediately**
   - If <10% affected: **NO, fix and expedite review**

3. **If Removing from Sale:**
   ```
   - App Store Connect → App Store → Pricing and Availability
   - Set "Remove from Sale" temporarily
   - Prevents new downloads, doesn't affect existing users
   ```

#### Hour 1-4: Hotfix Development

4. **Create Hotfix Branch**
   ```bash
   git checkout releases/v0.2.0-build21
   git checkout -b hotfix/v0.2.0-build22
   ```

5. **Fix Critical Issue**
   - Minimal code changes (only fix the critical bug)
   - No new features
   - No refactoring
   - Test fix thoroughly on affected iOS version/device

6. **Increment Build Number**
   ```yaml
   # pubspec.yaml
   version: 0.2.0+22  # Build 22
   ```

7. **Build and Upload**
   ```bash
   flutter clean
   flutter pub get
   flutter build ipa --release
   # Upload via Transporter
   ```

#### Hour 4-6: Expedited Review Request

8. **Submit for Expedited Review**
   - App Store Connect → Build 22 → Submit for Review
   - Check "Request Expedited Review"
   - Reason: "Critical bug causing crashes for iOS 13 users"
   - Explain impact and fix clearly

9. **Expected Timeline:**
   - Normal review: 24-48 hours
   - Expedited review: 4-24 hours (not guaranteed)

#### Hour 6-48: Monitor & Support

10. **Monitor Review Status**
    - Check App Store Connect every 2-4 hours
    - Respond immediately to App Review questions

11. **Prepare Support Response**
    - Draft email template for affected users
    - Post status update (if you have website/social media)
    - Respond to support requests:
      ```
      "We've identified a critical issue affecting iOS 13 devices. 
      A fix (v0.2.0 Build 22) is currently in App Store review and 
      should be available within 24-48 hours. We apologize for the inconvenience."
      ```

12. **Upon Approval:**
    - Release Build 22 immediately
    - Make available for sale again (if removed)
    - Update app description/release notes if needed
    - Notify affected users

---

## Database Rollback Scenarios

### Understanding Database Version Compatibility

**Current Schema:**
- Customer App: v6 (Build 21)
- Supplier App: v4 (Build 21)

**Migration Path:**
```
Customer App:
v1 → v2 (is_redeemed) → v3 (logo_index) → v4 (mode) → v5 (redeemed_at) → v6 (device_id)

Supplier App:
v1 → v2 (redemptions table) → v3 (logo_index) → v4 (mode)
```

**Critical Rule:** SQLite schema version can only increase, never decrease

### Scenario 4: Rollback with Database Incompatibility

**Problem:** Build 21 (DB v6) deployed, must rollback to Build 20 (expects DB v5)

**Impact:**
- Users on Build 21 have database v6 schema
- Build 20 code expects v5, will attempt upgrade v6 → v5
- SQLite upgrade path only goes up (v5 → v6), not down (v6 → v5)

**Solutions:**

#### Option 1: Hotfix Build 20.1 (Recommended)
```dart
// Build 20.1 accepts both v5 and v6 databases
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) { /* v1 → v2 migration */ }
  if (oldVersion < 3) { /* v2 → v3 migration */ }
  if (oldVersion < 4) { /* v3 → v4 migration */ }
  if (oldVersion < 5) { /* v4 → v5 migration */ }
  // Don't migrate v5 → v6, accept v6 silently
  // New device_id columns nullable, safe to ignore
}

// Set database version to 5 but accept v6
const int databaseVersion = 5; // Don't increment
```

#### Option 2: Fix Forward with Build 22
- Release Build 22 with corrected code
- Users stay on Build 21 or upgrade to Build 22
- Never release Build 20 to users on Build 21

#### Option 3: Manual User Data Reset (Last Resort)
- Users uninstall app
- Reinstall previous version
- **Data loss:** All cards and stamps deleted
- Only for catastrophic scenarios

---

## Code Rollback Process

### Git Branch Strategy

```bash
# Current state: Build 21 problematic in develop branch
git log --oneline
# a1b2c3d Build 21 - V-005 security fixes (PROBLEMATIC)
# d4e5f6g Build 20 - TEST-010 UI fixes (LAST KNOWN GOOD)

# Option 1: Revert commits (preserves history)
git revert a1b2c3d
git commit -m "Revert Build 21 changes - critical bug"
git push origin develop

# Option 2: Create rollback branch from last good build
git checkout d4e5f6g
git checkout -b rollback/build20-stable
git push origin rollback/build20-stable

# Rebuild and redeploy Build 20 with new build number (Build 22)
# Edit pubspec.yaml: version: 0.2.0+22
```

### Release Branch Protection

```bash
# NEVER modify existing release branches
# releases/v0.2.0-build21 is READ-ONLY

# If you need a "rolled back" release:
git checkout releases/v0.2.0-build20
git checkout -b releases/v0.2.0-build22-rollback
# This creates Build 22 from Build 20 code
```

---

## Communication Templates

### Internal Team Notification

**Subject:** 🚨 CRITICAL: Build 21 Rollback Required

```
Team,

We've identified a critical issue in Build 21 (deployed to TestFlight 2 hours ago):
- Issue: [Brief description]
- Impact: [% of users affected, severity]
- Decision: Rolling back to Build 20

Actions:
- TestFlight: Build 21 disabled, Build 20 re-enabled
- Next Steps: Hotfix in progress, ETA Build 22 in 4 hours

Status updates in #engineering every 30 minutes.
```

### Beta Tester Notification

**TestFlight "What to Test" Update:**

```
⚠️ ROLLBACK NOTICE

Build 21 has been rolled back due to a critical issue with [feature].

ACTION REQUIRED:
- If you're on Build 21: Please uninstall and reinstall from TestFlight to get Build 20
- If you're on Build 20: Do not update to Build 21

We're working on a fix and will release Build 22 shortly.

Data Safety: [Cards and stamps are safe / Some data may be lost - instructions below]

Apologies for the inconvenience. Thank you for your patience.
```

### App Store User Communication

**Support Email Template:**

```
Subject: LoyaltyCards Update - Critical Fix Released

Dear LoyaltyCards User,

We've identified and fixed a critical issue in version 0.2.0 Build 21 that affected [description].

WHAT TO DO:
- Update to version 0.2.0 Build 22 from the App Store
- The update should install automatically within 24 hours

YOUR DATA:
- Cards and stamps: [Safe / May need re-issuance]
- Transaction history: [Preserved / Lost - details below]

We apologize for any inconvenience. If you experience any issues after updating, 
please contact support@[domain].

Thank you for your understanding.

The LoyaltyCards Team
```

---

## Testing Rollback Scenarios

### Pre-Release Rollback Simulation

Before each major release, test rollback procedures:

1. **Install Previous Build** (Build 20)
2. **Create Test Data** (cards, stamps, transactions)
3. **Upgrade to New Build** (Build 21)
4. **Verify Migration** successful
5. **Simulate Rollback:**
   - Uninstall Build 21
   - Install Build 20
   - Check if data survives (iOS backup dependent)
   - Note: Data may be lost without iCloud backup

6. **Test Hotfix Path:**
   - Install Build 21
   - Install Build 22 (hotfix)
   - Verify data preserved
   - Verify migration handled correctly

---

## Rollback Checklist

### Pre-Rollback

- [ ] **Severity confirmed** (meets rollback criteria)
- [ ] **Impact assessed** (% of users, data loss risk)
- [ ] **Alternative fixes evaluated** (can we fix forward faster?)
- [ ] **Team notified** (all stakeholders aware)
- [ ] **User communication prepared** (email templates, app messages)

### During Rollback

- [ ] **Previous build identified** (last known good version)
- [ ] **Previous build tested** (still functional)
- [ ] **Database compatibility checked** (can users downgrade?)
- [ ] **TestFlight/App Store updated** (old build re-enabled or new hotfix uploaded)
- [ ] **Users notified** (TestFlight message or support email)
- [ ] **Status monitored** (crash reports, support tickets)

### Post-Rollback

- [ ] **Root cause identified** (what caused the issue?)
- [ ] **Fix developed** (hotfix or next release)
- [ ] **Testing completed** (including rollback scenario)
- [ ] **Post-mortem scheduled** (learn from incident)
- [ ] **Documentation updated** (add to Known Issues, update test plan)
- [ ] **Prevention measures** (update CI/CD, add tests)

---

## Preventing Rollback Situations

### Pre-Release Checklist

1. **Comprehensive Testing**
   - All device sizes (iPhone SE to Pro Max)
   - All supported iOS versions (13.0+)
   - Database migrations (fresh install + upgrade path)
   - Offline functionality
   - Biometric authentication (physical device)

2. **Staged Rollout**
   - TestFlight internal testing (1-2 days)
   - TestFlight external beta (1 week)
   - Phased App Store release (10% → 50% → 100% over 7 days)

3. **Monitoring**
   - App Store Connect crash reports
   - Support email monitoring
   - TestFlight feedback review

4. **Automated Testing**
   - Unit tests for critical paths
   - Integration tests for database migrations
   - UI tests for core user flows

---

## Emergency Contacts

**Critical Issues (Crashes, Data Loss, Security):**
- Development Team: [Contact method]
- On-Call Engineer: [Contact method]
- Response Time: <1 hour

**Medium Issues (Feature Broken, UX Degradation):**
- Development Team: [Contact method]
- Response Time: <4 hours

**Low Issues (Minor Bugs, UI Glitches):**
- Bug tracker: [DEFECT_TRACKER.md](DEFECT_TRACKER.md)
- Response Time: Next business day

---

**References:**
- [TestFlight Deployment Guide](TESTFLIGHT_DEPLOYMENT_GUIDE.md)
- [Database Schema](DATABASE_SCHEMA.md)
- [Defect Tracker](DEFECT_TRACKER.md)
- [Changelog](CHANGELOG.md)

**Maintained by:** Development Team  
**Last Updated:** April 18, 2026
